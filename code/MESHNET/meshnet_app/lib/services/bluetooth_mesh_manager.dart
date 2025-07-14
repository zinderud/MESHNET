import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

class BluetoothMeshManager extends ChangeNotifier {
  static const String MESHNET_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String MESHNET_TX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String MESHNET_RX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  final List<BluetoothDevice> _discoveredDevices = [];
  final List<BluetoothDevice> _connectedDevices = [];
  final Map<String, BluetoothCharacteristic> _txCharacteristics = {};
  final Map<String, BluetoothCharacteristic> _rxCharacteristics = {};
  
  StreamSubscription<List<BluetoothDevice>>? _scanSubscription;
  bool _isScanning = false;
  bool _isInitialized = false;
  
  // Mesh network properties
  String _nodeId = '';
  final Map<String, MeshNode> _meshNodes = {};
  final List<MeshMessage> _messageQueue = [];
  final Set<String> _processedMessages = {};

  List<BluetoothDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  List<BluetoothDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;
  String get nodeId => _nodeId;
  List<MeshNode> get meshNodes => _meshNodes.values.toList();

  Future<bool> initialize() async {
    try {
      // Check permissions
      if (!await _requestPermissions()) {
        print('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        print('Bluetooth not supported by this device');
        return false;
      }

      // Generate unique node ID
      _nodeId = _generateNodeId();
      
      // Start advertising service
      await _startAdvertising();
      
      _isInitialized = true;
      notifyListeners();
      
      print('Bluetooth Mesh Manager initialized with Node ID: $_nodeId');
      return true;
    } catch (e) {
      print('Error initializing Bluetooth Mesh Manager: $e');
      return false;
    }
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    return permissions.values.every((status) => status.isGranted);
  }

  String _generateNodeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('MESHNET_$timestamp');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  Future<void> _startAdvertising() async {
    try {
      // Start advertising as MESHNET device
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 4),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print('Error starting advertising: $e');
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      _isScanning = true;
      notifyListeners();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final device = result.device;
          if (_isMeshNetDevice(result) && !_discoveredDevices.contains(device)) {
            _discoveredDevices.add(device);
            _connectToDevice(device);
          }
        }
        notifyListeners();
      });

      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

    } catch (e) {
      print('Error starting scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  bool _isMeshNetDevice(ScanResult result) {
    // Check if device advertises MESHNET service
    return result.advertisementData.serviceUuids.contains(MESHNET_SERVICE_UUID) ||
           result.device.platformName.toLowerCase().contains('meshnet');
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: Duration(seconds: 10));
      _connectedDevices.add(device);
      
      // Discover services and characteristics
      await _setupDeviceCharacteristics(device);
      
      // Add to mesh network
      _addMeshNode(device);
      
      notifyListeners();
      print('Connected to device: ${device.platformName}');
    } catch (e) {
      print('Error connecting to device ${device.platformName}: $e');
    }
  }

  Future<void> _setupDeviceCharacteristics(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == MESHNET_SERVICE_UUID.toUpperCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase();
            
            if (charUuid == MESHNET_TX_CHAR_UUID.toUpperCase()) {
              _txCharacteristics[device.remoteId.toString()] = characteristic;
            } else if (charUuid == MESHNET_RX_CHAR_UUID.toUpperCase()) {
              _rxCharacteristics[device.remoteId.toString()] = characteristic;
              
              // Setup notifications for incoming messages
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) {
                _handleIncomingMessage(device, value);
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error setting up characteristics for ${device.platformName}: $e');
    }
  }

  void _addMeshNode(BluetoothDevice device) {
    final node = MeshNode(
      id: device.remoteId.toString(),
      name: device.platformName,
      device: device,
      lastSeen: DateTime.now(),
    );
    _meshNodes[node.id] = node;
  }

  void _handleIncomingMessage(BluetoothDevice device, List<int> data) {
    try {
      final message = MeshMessage.fromBytes(Uint8List.fromList(data));
      
      // Prevent processing the same message multiple times
      if (_processedMessages.contains(message.messageId)) {
        return;
      }
      _processedMessages.add(message.messageId);
      
      // Update node last seen time
      if (_meshNodes.containsKey(device.remoteId.toString())) {
        _meshNodes[device.remoteId.toString()]!.lastSeen = DateTime.now();
      }
      
      // If message is for this node, process it
      if (message.targetNodeId == _nodeId || message.targetNodeId == 'broadcast') {
        _processMessage(message);
      }
      
      // Forward message to other nodes if TTL > 0
      if (message.ttl > 0) {
        _forwardMessage(message, device.remoteId.toString());
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

  Future<void> _forwardMessage(MeshMessage message, String excludeNodeId) async {
    final forwardedMessage = message.copyWith(
      ttl: message.ttl - 1,
      forwardedBy: _nodeId,
    );
    
    for (BluetoothDevice device in _connectedDevices) {
      if (device.remoteId.toString() != excludeNodeId) {
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
    for (BluetoothDevice device in _connectedDevices) {
      await _sendMessageToDevice(device, message);
    }
  }

  Future<void> _sendMessageToDevice(BluetoothDevice device, MeshMessage message) async {
    try {
      final characteristic = _txCharacteristics[device.remoteId.toString()];
      if (characteristic != null) {
        final data = message.toBytes();
        await characteristic.write(data, withoutResponse: true);
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
    
    for (BluetoothDevice device in _connectedDevices) {
      try {
        await device.disconnect();
      } catch (e) {
        print('Error disconnecting from ${device.platformName}: $e');
      }
    }
    
    _connectedDevices.clear();
    _discoveredDevices.clear();
    _meshNodes.clear();
    _txCharacteristics.clear();
    _rxCharacteristics.clear();
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
  final BluetoothDevice device;
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
