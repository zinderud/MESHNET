import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';  // Web'de çalışmaz
// import 'package:permission_handler/permission_handler.dart'; // Web'de çalışmaz
import 'package:crypto/crypto.dart';

// Web uyumlu mock Bluetooth Device sınıfı
class MockBluetoothDevice {
  final String platformName;
  final String remoteId;
  
  MockBluetoothDevice({required this.platformName, required this.remoteId});
}

class BluetoothMeshManager extends ChangeNotifier {
  static const String MESHNET_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String MESHNET_TX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String MESHNET_RX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  final List<MockBluetoothDevice> _discoveredDevices = [];
  final List<MockBluetoothDevice> _connectedDevices = [];
  
  bool _isScanning = false;
  bool _isInitialized = false;
  
  // Mesh network properties
  String _nodeId = '';
  final Map<String, MeshNode> _meshNodes = {};
  final List<MeshMessage> _messageQueue = [];
  final Set<String> _processedMessages = {};

  List<MockBluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<MockBluetoothDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  String get nodeId => _nodeId;
  List<MeshNode> get meshNodes => _meshNodes.values.toList();

  Future<bool> initialize() async {
    try {
      // Web platformunda Bluetooth izinleri otomatik kabul
      if (kIsWeb) {
        print('Web platformu: Bluetooth simülasyonu başlatılıyor...');
      }

      // Generate unique node ID
      _nodeId = _generateNodeId();
      
      _isInitialized = true;
      notifyListeners();
      
      print('Bluetooth Mesh Manager initialized with Node ID: $_nodeId');
      
      // Web'de demo cihazlar ekle
      if (kIsWeb) {
        _addDemoDevices();
      }
      
      return true;
    } catch (e) {
      print('Error initializing Bluetooth Mesh Manager: $e');
      return false;
    }
  }

  void _addDemoDevices() {
    // Demo cihazları ekle
    Timer(Duration(seconds: 2), () {
      final demoDevices = [
        MockBluetoothDevice(platformName: 'MESHNET-Android-001', remoteId: 'demo001'),
        MockBluetoothDevice(platformName: 'MESHNET-iPhone-002', remoteId: 'demo002'),
      ];
      
      _discoveredDevices.addAll(demoDevices);
      notifyListeners();
      
      // 3 saniye sonra bağlan
      Timer(Duration(seconds: 3), () {
        _connectedDevices.addAll(demoDevices);
        for (var device in demoDevices) {
          _addMeshNode(device);
        }
        notifyListeners();
      });
    });
  }

  String _generateNodeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('MESHNET_$timestamp');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    _isScanning = true;
    notifyListeners();

    if (kIsWeb) {
      print('Web platformu: Cihaz taraması simülasyonu başlatıldı');
      // Web'de 5 saniye sonra taramayı durdur
      Timer(Duration(seconds: 5), () {
        _isScanning = false;
        notifyListeners();
      });
    } else {
      // Gerçek Bluetooth tarama kodu burada olacak
      Timer(Duration(seconds: 10), () {
        _isScanning = false;
        notifyListeners();
      });
    }
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    notifyListeners();
  }

  void _addMeshNode(MockBluetoothDevice device) {
    final node = MeshNode(
      id: device.remoteId,
      name: device.platformName,
      device: device,
      lastSeen: DateTime.now(),
    );
    _meshNodes[node.id] = node;
  }

  void _handleIncomingMessage(MockBluetoothDevice device, List<int> data) {
    try {
      final message = MeshMessage.fromBytes(Uint8List.fromList(data));
      
      // Prevent processing the same message multiple times
      if (_processedMessages.contains(message.messageId)) {
        return;
      }
      _processedMessages.add(message.messageId);
      
      // Update node last seen time
      if (_meshNodes.containsKey(device.remoteId)) {
        _meshNodes[device.remoteId]!.lastSeen = DateTime.now();
      }
      
      // If message is for this node, process it
      if (message.targetNodeId == _nodeId || message.targetNodeId == 'broadcast') {
        _processMessage(message);
      }
      
      // Forward message to other nodes if TTL > 0
      if (message.ttl > 0) {
        _forwardMessage(message, device.remoteId);
      }
      
    } catch (e) {
      print('Error handling incoming message: $e');
    }
  }

  void _processMessage(MeshMessage message) {
    // Process message based on type
    switch (message.type) {
      case MeshMessageType.chat:
        _handleChatMessage(message);
        break;
      case MeshMessageType.discovery:
        _handleDiscoveryMessage(message);
        break;
      case MeshMessageType.emergency:
        _handleEmergencyMessage(message);
        break;
      case MeshMessageType.file:
        _handleFileMessage(message);
        break;
    }
  }

  void _handleChatMessage(MeshMessage message) {
    // Notify UI about new chat message
    print('Chat message from ${message.sourceNodeId}: ${message.payload}');
    notifyListeners();
  }

  void _handleDiscoveryMessage(MeshMessage message) {
    // Handle network discovery
    print('Discovery message from ${message.sourceNodeId}');
  }

  void _handleEmergencyMessage(MeshMessage message) {
    // Handle emergency message with priority
    print('EMERGENCY message from ${message.sourceNodeId}: ${message.payload}');
    notifyListeners();
  }

  void _handleFileMessage(MeshMessage message) {
    // Handle file transfer message
    print('File message from ${message.sourceNodeId}: ${message.payload}');
    notifyListeners();
  }

  Future<void> _forwardMessage(MeshMessage message, String excludeNodeId) async {
    final forwardedMessage = message.copyWith(
      ttl: message.ttl - 1,
      forwardedBy: _nodeId,
    );
    
    for (MockBluetoothDevice device in _connectedDevices) {
      if (device.remoteId != excludeNodeId) {
        await _sendMessageToDevice(device, forwardedMessage);
      }
    }
  }

  Future<void> sendChatMessage(String content, {String? targetNodeId}) async {
    final message = MeshMessage(
      messageId: _generateMessageId(),
      sourceNodeId: _nodeId,
      targetNodeId: targetNodeId ?? 'broadcast',
      type: MeshMessageType.chat,
      payload: content,
      timestamp: DateTime.now(),
      ttl: 5, // Max 5 hops
    );
    
    await _broadcastMessage(message);
    
    // Web'de demo mesaj gönder
    if (kIsWeb && _connectedDevices.isNotEmpty) {
      _simulateIncomingMessage(content);
    }
  }

  void _simulateIncomingMessage(String originalContent) {
    // 2-5 saniye sonra demo cevap mesajı
    Timer(Duration(seconds: 2 + (DateTime.now().millisecond % 3)), () {
      final responses = [
        'Mesaj alındı: "$originalContent"',
        'Roger that! 👍',
        'Bağlantı test edildi ✅',
        'MESHNET çalışıyor 🔗',
        'Acil durum ağı aktif 🚨',
      ];
      
      final response = responses[DateTime.now().millisecond % responses.length];
      final demoMessage = List<int>.from(utf8.encode(jsonEncode({
        'messageId': _generateMessageId(),
        'sourceNodeId': 'demo001',
        'targetNodeId': _nodeId,
        'type': MeshMessageType.chat.index,
        'payload': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': 5,
      })));
      
      if (_connectedDevices.isNotEmpty) {
        _handleIncomingMessage(_connectedDevices.first, demoMessage);
      }
    });
  }

  Future<void> sendEmergencyMessage(String content, Map<String, dynamic>? location) async {
    final payload = {
      'message': content,
      'location': location,
      'emergency': true,
    };
    
    final message = MeshMessage(
      messageId: _generateMessageId(),
      sourceNodeId: _nodeId,
      targetNodeId: 'broadcast',
      type: MeshMessageType.emergency,
      payload: jsonEncode(payload),
      timestamp: DateTime.now(),
      ttl: 10, // Emergency messages get more hops
    );
    
    await _broadcastMessage(message);
  }

  Future<void> _broadcastMessage(MeshMessage message) async {
    for (MockBluetoothDevice device in _connectedDevices) {
      await _sendMessageToDevice(device, message);
    }
  }

  Future<void> _sendMessageToDevice(MockBluetoothDevice device, MeshMessage message) async {
    try {
      if (kIsWeb) {
        // Web'de konsola log yaz
        print('Sending message to ${device.platformName}: ${message.payload}');
      } else {
        // Gerçek Bluetooth gönderimi burada olacak
        final data = message.toBytes();
        print('Would send ${data.length} bytes to ${device.platformName}');
      }
    } catch (e) {
      print('Error sending message to ${device.platformName}: $e');
    }
  }

  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + '_' + _nodeId.substring(0, 8);
  }

  Future<void> disconnect() async {
    await stopScanning();
    
    _connectedDevices.clear();
    _discoveredDevices.clear();
    _meshNodes.clear();
    _processedMessages.clear();
    
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

class MeshNode {
  final String id;
  final String name;
  final MockBluetoothDevice device;
  DateTime lastSeen;
  int hopCount;

  MeshNode({
    required this.id,
    required this.name,
    required this.device,
    required this.lastSeen,
    this.hopCount = 1,
  });
}

enum MeshMessageType { chat, discovery, emergency, file }

class MeshMessage {
  final String messageId;
  final String sourceNodeId;
  final String targetNodeId;
  final MeshMessageType type;
  final String payload;
  final DateTime timestamp;
  final int ttl;
  final String? forwardedBy;

  MeshMessage({
    required this.messageId,
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.type,
    required this.payload,
    required this.timestamp,
    required this.ttl,
    this.forwardedBy,
  });

  MeshMessage copyWith({
    String? messageId,
    String? sourceNodeId,
    String? targetNodeId,
    MeshMessageType? type,
    String? payload,
    DateTime? timestamp,
    int? ttl,
    String? forwardedBy,
  }) {
    return MeshMessage(
      messageId: messageId ?? this.messageId,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      ttl: ttl ?? this.ttl,
      forwardedBy: forwardedBy ?? this.forwardedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'sourceNodeId': sourceNodeId,
      'targetNodeId': targetNodeId,
      'type': type.index,
      'payload': payload,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'ttl': ttl,
      'forwardedBy': forwardedBy,
    };
  }

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      messageId: json['messageId'],
      sourceNodeId: json['sourceNodeId'],
      targetNodeId: json['targetNodeId'],
      type: MeshMessageType.values[json['type']],
      payload: json['payload'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      ttl: json['ttl'],
      forwardedBy: json['forwardedBy'],
    );
  }

  Uint8List toBytes() {
    final jsonString = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  factory MeshMessage.fromBytes(Uint8List bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString);
    return MeshMessage.fromJson(json);
  }
}
