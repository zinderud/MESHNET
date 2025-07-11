# 3. WiFi Direct Clustering Implementasyonu

## 📋 Bu Aşamada Yapılacaklar

BitChat'teki WiFi Direct planını temel alarak, yüksek bant genişliği gerektiren veri transferi için WiFi Direct clustering implementasyonu geliştireceğiz.

### ✅ Tamamlanması Gerekenler:
1. **WiFi Direct peer discovery ve group formation**
2. **High-bandwidth data transfer (25-250 Mbps)**
3. **Cross-cluster bridging via Bluetooth**
4. **Load balancing ve bandwidth optimization**
5. **Automatic fallback to Bluetooth when WiFi fails**

## 🔧 BitChat WiFi Direct Plan Analysis

### **BitChat WiFi Direct Specifications**
```markdown
- Range: 100-200 meters (vs BLE's 10-30m)
- Speed: 250+ Mbps (vs BLE's 1-3 Mbps)
- Power: Higher consumption than BLE
- Platform Support: 
  - iOS: MultipeerConnectivity framework
  - Android: WiFi P2P API
  - macOS: Network.framework with Bonjour
```

### **Flutter WiFi Direct Implementation**

#### **1. WiFi Direct Manager**
```dart
// lib/services/wifi_direct_manager.dart
import 'package:flutter/foundation.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/wifi_peer.dart';
import '../models/message.dart';
import '../services/bluetooth_manager.dart';

class WiFiDirectManager extends ChangeNotifier {
  final BluetoothManager _bluetoothManager;
  
  // WiFi Direct state
  List<WiFiPeer> _discoveredPeers = [];
  List<WiFiPeer> _connectedPeers = [];
  WiFiPeer? _groupOwner;
  bool _isGroupOwner = false;
  bool _isScanning = false;
  String? _currentGroupName;
  
  // Network information
  final NetworkInfo _networkInfo = NetworkInfo();
  
  // Stream controllers
  StreamController<WiFiPeer> _peerController = StreamController.broadcast();
  StreamController<Message> _messageController = StreamController.broadcast();
  
  // Constructor
  WiFiDirectManager(this._bluetoothManager) {
    _initialize();
  }
  
  // Getters
  List<WiFiPeer> get discoveredPeers => _discoveredPeers;
  List<WiFiPeer> get connectedPeers => _connectedPeers;
  bool get isGroupOwner => _isGroupOwner;
  bool get isScanning => _isScanning;
  String? get currentGroupName => _currentGroupName;
  Stream<WiFiPeer> get peerStream => _peerController.stream;
  Stream<Message> get messageStream => _messageController.stream;
  
  // Initialize WiFi Direct
  Future<void> _initialize() async {
    await _requestPermissions();
    await _checkWiFiDirectSupport();
    
    // Listen to Bluetooth manager for coordination
    _bluetoothManager.messageStream.listen(_handleBluetoothMessage);
  }
  
  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.nearbyWifiDevices.request();
  }
  
  Future<void> _checkWiFiDirectSupport() async {
    try {
      final isSupported = await WiFiForIoTPlugin.isWiFiDirectSupported();
      if (!isSupported) {
        debugPrint('WiFi Direct not supported on this device');
        return;
      }
      
      debugPrint('WiFi Direct supported');
    } catch (e) {
      debugPrint('Error checking WiFi Direct support: $e');
    }
  }
  
  // Start WiFi Direct peer discovery
  Future<void> startDiscovery() async {
    if (_isScanning) return;
    
    _isScanning = true;
    notifyListeners();
    
    try {
      // Start WiFi Direct discovery
      await WiFiForIoTPlugin.startDiscovery();
      
      // Poll for discovered peers
      _startPeerDiscoveryPolling();
      
    } catch (e) {
      debugPrint('WiFi Direct discovery error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }
  
  void _startPeerDiscoveryPolling() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      
      _getPeers();
    });
  }
  
  Future<void> _getPeers() async {
    try {
      final peers = await WiFiForIoTPlugin.getPeers();
      
      for (final peerInfo in peers) {
        final peer = WiFiPeer.fromWiFiInfo(peerInfo);
        
        if (!_discoveredPeers.any((p) => p.id == peer.id)) {
          _discoveredPeers.add(peer);
          _peerController.add(peer);
          notifyListeners();
          
          // Automatically attempt connection to compatible peers
          if (_isCompatiblePeer(peer)) {
            _connectToPeer(peer);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting WiFi Direct peers: $e');
    }
  }
  
  bool _isCompatiblePeer(WiFiPeer peer) {
    // Check if peer has MESHNET identifier
    return peer.deviceName.toLowerCase().contains('meshnet');
  }
  
  Future<void> _connectToPeer(WiFiPeer peer) async {
    try {
      // Connect to WiFi Direct peer
      await WiFiForIoTPlugin.connectToPeer(peer.deviceAddress);
      
      // Wait for connection establishment
      await Future.delayed(Duration(seconds: 2));
      
      // Check if connection was successful
      final isConnected = await WiFiForIoTPlugin.isConnected();
      if (isConnected) {
        peer.isConnected = true;
        _connectedPeers.add(peer);
        
        // Determine group owner
        await _determineGroupOwner(peer);
        
        // Start high-bandwidth communication
        await _startHighBandwidthCommunication(peer);
        
        notifyListeners();
      }
      
    } catch (e) {
      debugPrint('Failed to connect to WiFi Direct peer ${peer.deviceName}: $e');
    }
  }
  
  Future<void> _determineGroupOwner(WiFiPeer peer) async {
    try {
      final groupInfo = await WiFiForIoTPlugin.getGroupInfo();
      
      if (groupInfo != null) {
        _isGroupOwner = groupInfo.isGroupOwner;
        _currentGroupName = groupInfo.groupName;
        
        if (_isGroupOwner) {
          _groupOwner = null; // We are the group owner
          debugPrint('We are the group owner');
        } else {
          _groupOwner = peer;
          debugPrint('${peer.deviceName} is the group owner');
        }
      }
    } catch (e) {
      debugPrint('Error determining group owner: $e');
    }
  }
  
  Future<void> _startHighBandwidthCommunication(WiFiPeer peer) async {
    try {
      // Get group network info
      final wifiIP = await _networkInfo.getWifiIP();
      final gateway = await _networkInfo.getWifiGatewayIP();
      
      debugPrint('WiFi Direct network - IP: $wifiIP, Gateway: $gateway');
      
      // Start TCP/UDP communication for high bandwidth data
      await _startTCPCommunication(peer, wifiIP, gateway);
      
    } catch (e) {
      debugPrint('Error starting high bandwidth communication: $e');
    }
  }
  
  Future<void> _startTCPCommunication(WiFiPeer peer, String? localIP, String? gateway) async {
    try {
      // Create TCP server if we are group owner
      if (_isGroupOwner) {
        await _startTCPServer();
      } else {
        // Connect to group owner's TCP server
        await _connectToTCPServer(gateway ?? '192.168.49.1');
      }
    } catch (e) {
      debugPrint('TCP communication error: $e');
    }
  }
  
  Future<void> _startTCPServer() async {
    try {
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
      debugPrint('TCP server started on port 8888');
      
      server.listen((socket) {
        debugPrint('New TCP connection: ${socket.remoteAddress}');
        _handleTCPConnection(socket);
      });
      
    } catch (e) {
      debugPrint('TCP server error: $e');
    }
  }
  
  Future<void> _connectToTCPServer(String serverIP) async {
    try {
      final socket = await Socket.connect(serverIP, 8888);
      debugPrint('Connected to TCP server: $serverIP');
      
      _handleTCPConnection(socket);
      
    } catch (e) {
      debugPrint('TCP client connection error: $e');
    }
  }
  
  void _handleTCPConnection(Socket socket) {
    // Handle high-bandwidth data transfer
    socket.listen(
      (data) {
        _handleHighBandwidthData(data);
      },
      onError: (error) {
        debugPrint('TCP connection error: $error');
      },
      onDone: () {
        debugPrint('TCP connection closed');
      },
    );
  }
  
  void _handleHighBandwidthData(Uint8List data) {
    try {
      // Parse high-bandwidth message
      final message = _parseHighBandwidthMessage(data);
      if (message != null) {
        _messageController.add(message);
        
        // Bridge to Bluetooth network if needed
        _bridgeToBluetoothNetwork(message);
      }
    } catch (e) {
      debugPrint('Error handling high bandwidth data: $e');
    }
  }
  
  Message? _parseHighBandwidthMessage(Uint8List data) {
    try {
      final jsonString = String.fromCharCodes(data);
      final json = jsonDecode(jsonString);
      
      return Message.fromJson(json);
    } catch (e) {
      debugPrint('Failed to parse high bandwidth message: $e');
      return null;
    }
  }
  
  void _bridgeToBluetoothNetwork(Message message) {
    // Bridge high-bandwidth WiFi Direct messages to Bluetooth mesh
    if (message.metadata?['bridge_to_bluetooth'] == true) {
      _bluetoothManager.sendMessage(message);
    }
  }
  
  void _handleBluetoothMessage(Message message) {
    // Handle messages from Bluetooth network
    if (message.metadata?['bridge_to_wifi'] == true) {
      // Forward to WiFi Direct network
      sendHighBandwidthMessage(message);
    }
  }
  
  // Send high-bandwidth message via WiFi Direct
  Future<void> sendHighBandwidthMessage(Message message) async {
    if (_connectedPeers.isEmpty) {
      debugPrint('No WiFi Direct peers connected');
      return;
    }
    
    final messageJson = jsonEncode(message.toJson());
    final messageData = Uint8List.fromList(messageJson.codeUnits);
    
    // Send via TCP to all connected peers
    for (final peer in _connectedPeers) {
      if (peer.tcpSocket != null) {
        try {
          peer.tcpSocket!.add(messageData);
          await peer.tcpSocket!.flush();
        } catch (e) {
          debugPrint('Failed to send high bandwidth message to ${peer.deviceName}: $e');
        }
      }
    }
  }
  
  // Create WiFi Direct group
  Future<void> createGroup(String groupName) async {
    try {
      await WiFiForIoTPlugin.createGroup(groupName);
      _isGroupOwner = true;
      _currentGroupName = groupName;
      
      // Start TCP server for group communication
      await _startTCPServer();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error creating WiFi Direct group: $e');
    }
  }
  
  // Join WiFi Direct group
  Future<void> joinGroup(WiFiPeer groupOwner) async {
    try {
      await _connectToPeer(groupOwner);
    } catch (e) {
      debugPrint('Error joining WiFi Direct group: $e');
    }
  }
  
  // Leave WiFi Direct group
  Future<void> leaveGroup() async {
    try {
      await WiFiForIoTPlugin.disconnect();
      
      _isGroupOwner = false;
      _groupOwner = null;
      _currentGroupName = null;
      _connectedPeers.clear();
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error leaving WiFi Direct group: $e');
    }
  }
  
  // Stop discovery
  Future<void> stopDiscovery() async {
    if (_isScanning) {
      try {
        await WiFiForIoTPlugin.stopDiscovery();
        _isScanning = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error stopping WiFi Direct discovery: $e');
      }
    }
  }
  
  // Cleanup
  @override
  void dispose() {
    stopDiscovery();
    leaveGroup();
    _peerController.close();
    _messageController.close();
    super.dispose();
  }
}
```

#### **2. WiFi Peer Model**
```dart
// lib/models/wifi_peer.dart
import 'dart:io';

class WiFiPeer {
  final String id;
  final String deviceName;
  final String deviceAddress;
  final bool isGroupOwner;
  final int status;
  bool isConnected;
  Socket? tcpSocket;
  DateTime lastSeen;
  
  WiFiPeer({
    required this.id,
    required this.deviceName,
    required this.deviceAddress,
    required this.isGroupOwner,
    required this.status,
    this.isConnected = false,
    this.tcpSocket,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();
  
  // Create from WiFi info
  factory WiFiPeer.fromWiFiInfo(Map<String, dynamic> wifiInfo) {
    return WiFiPeer(
      id: wifiInfo['deviceAddress'] ?? '',
      deviceName: wifiInfo['deviceName'] ?? 'Unknown',
      deviceAddress: wifiInfo['deviceAddress'] ?? '',
      isGroupOwner: wifiInfo['isGroupOwner'] ?? false,
      status: wifiInfo['status'] ?? 0,
    );
  }
  
  // Connection quality based on status
  String get statusText {
    switch (status) {
      case 0: return 'Connected';
      case 1: return 'Invited';
      case 2: return 'Failed';
      case 3: return 'Available';
      case 4: return 'Unavailable';
      default: return 'Unknown';
    }
  }
  
  bool get isAvailable => status == 3;
  bool get isInvited => status == 1;
  bool get isFailed => status == 2;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WiFiPeer && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'WiFiPeer(name: $deviceName, address: $deviceAddress, status: $statusText)';
  }
}
```

#### **3. Hybrid Protocol Manager**
```dart
// lib/services/hybrid_protocol_manager.dart
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/wifi_peer.dart';
import 'bluetooth_manager.dart';
import 'wifi_direct_manager.dart';

class HybridProtocolManager extends ChangeNotifier {
  final BluetoothManager _bluetoothManager;
  final WiFiDirectManager _wifiDirectManager;
  
  // Protocol selection criteria
  static const int LARGE_MESSAGE_THRESHOLD = 1024; // 1KB
  static const int HIGH_BANDWIDTH_THRESHOLD = 1024 * 10; // 10KB
  
  HybridProtocolManager(this._bluetoothManager, this._wifiDirectManager) {
    _initialize();
  }
  
  void _initialize() {
    // Listen to both protocol managers
    _bluetoothManager.messageStream.listen(_handleBluetoothMessage);
    _wifiDirectManager.messageStream.listen(_handleWiFiDirectMessage);
  }
  
  // Intelligent protocol selection
  Future<void> sendMessage(Message message) async {
    final messageSize = message.content.length;
    final urgency = message.type;
    
    // Determine best protocol based on message characteristics
    final protocol = _selectOptimalProtocol(message, messageSize);
    
    switch (protocol) {
      case Protocol.bluetooth:
        await _sendViaBluetooth(message);
        break;
      case Protocol.wifiDirect:
        await _sendViaWiFiDirect(message);
        break;
      case Protocol.hybrid:
        await _sendViaHybrid(message);
        break;
    }
  }
  
  Protocol _selectOptimalProtocol(Message message, int messageSize) {
    // Emergency messages: use all available protocols
    if (message.type == MessageType.emergency) {
      return Protocol.hybrid;
    }
    
    // Large messages: prefer WiFi Direct
    if (messageSize > HIGH_BANDWIDTH_THRESHOLD) {
      return _wifiDirectManager.connectedPeers.isNotEmpty 
          ? Protocol.wifiDirect 
          : Protocol.bluetooth;
    }
    
    // Medium messages: use WiFi Direct if available
    if (messageSize > LARGE_MESSAGE_THRESHOLD) {
      return _wifiDirectManager.connectedPeers.isNotEmpty
          ? Protocol.wifiDirect
          : Protocol.bluetooth;
    }
    
    // Small messages: use Bluetooth (lower power)
    return Protocol.bluetooth;
  }
  
  Future<void> _sendViaBluetooth(Message message) async {
    await _bluetoothManager.sendMessage(message);
  }
  
  Future<void> _sendViaWiFiDirect(Message message) async {
    if (_wifiDirectManager.connectedPeers.isEmpty) {
      // Fallback to Bluetooth
      await _sendViaBluetooth(message);
      return;
    }
    
    await _wifiDirectManager.sendHighBandwidthMessage(message);
  }
  
  Future<void> _sendViaHybrid(Message message) async {
    // Send via both protocols for maximum reliability
    await _sendViaBluetooth(message);
    
    if (_wifiDirectManager.connectedPeers.isNotEmpty) {
      await _sendViaWiFiDirect(message);
    }
  }
  
  void _handleBluetoothMessage(Message message) {
    // Check if message should be bridged to WiFi Direct
    if (_shouldBridgeToWiFi(message)) {
      final bridgedMessage = message.copyWith(
        metadata: {...message.metadata ?? {}, 'bridged_from': 'bluetooth'},
      );
      _wifiDirectManager.sendHighBandwidthMessage(bridgedMessage);
    }
    
    // Notify listeners
    notifyListeners();
  }
  
  void _handleWiFiDirectMessage(Message message) {
    // Check if message should be bridged to Bluetooth
    if (_shouldBridgeToBluetooth(message)) {
      final bridgedMessage = message.copyWith(
        metadata: {...message.metadata ?? {}, 'bridged_from': 'wifi_direct'},
      );
      _bluetoothManager.sendMessage(bridgedMessage);
    }
    
    // Notify listeners
    notifyListeners();
  }
  
  bool _shouldBridgeToWiFi(Message message) {
    // Bridge large messages to WiFi Direct network
    return message.content.length > LARGE_MESSAGE_THRESHOLD &&
           _wifiDirectManager.connectedPeers.isNotEmpty &&
           message.metadata?['bridged_from'] != 'wifi_direct';
  }
  
  bool _shouldBridgeToBluetooth(Message message) {
    // Bridge all messages to Bluetooth for wider reach
    return message.metadata?['bridged_from'] != 'bluetooth' &&
           _bluetoothManager.connectedPeers.isNotEmpty;
  }
  
  // Network statistics
  NetworkStats getNetworkStats() {
    return NetworkStats(
      bluetoothPeers: _bluetoothManager.connectedPeers.length,
      wifiDirectPeers: _wifiDirectManager.connectedPeers.length,
      totalPeers: _bluetoothManager.connectedPeers.length + 
                  _wifiDirectManager.connectedPeers.length,
      bluetoothRange: _estimateBluetoothRange(),
      wifiDirectRange: _estimateWiFiDirectRange(),
    );
  }
  
  double _estimateBluetoothRange() {
    // Estimate range based on connected peers and signal strength
    return 100.0; // meters
  }
  
  double _estimateWiFiDirectRange() {
    // Estimate range based on connected peers and signal strength
    return 200.0; // meters
  }
}

enum Protocol {
  bluetooth,
  wifiDirect,
  hybrid,
}

class NetworkStats {
  final int bluetoothPeers;
  final int wifiDirectPeers;
  final int totalPeers;
  final double bluetoothRange;
  final double wifiDirectRange;
  
  NetworkStats({
    required this.bluetoothPeers,
    required this.wifiDirectPeers,
    required this.totalPeers,
    required this.bluetoothRange,
    required this.wifiDirectRange,
  });
}
```

#### **4. Enhanced Chat Screen with Protocol Selection**
```dart
// lib/screens/enhanced_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hybrid_protocol_manager.dart';
import '../services/bluetooth_manager.dart';
import '../services/wifi_direct_manager.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/protocol_status_widget.dart';

class EnhancedChatScreen extends StatefulWidget {
  @override
  _EnhancedChatScreenState createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initializeManagers();
  }
  
  void _initializeManagers() {
    final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    final wifiDirectManager = Provider.of<WiFiDirectManager>(context, listen: false);
    
    bluetoothManager.initialize();
    bluetoothManager.startScanning();
    
    wifiDirectManager.startDiscovery();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MESHNET - Hybrid'),
        actions: [
          IconButton(
            icon: Icon(Icons.network_wifi),
            onPressed: _showWiFiDirectOptions,
          ),
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: _showBluetoothOptions,
          ),
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _showNetworkStats,
          ),
        ],
      ),
      body: Column(
        children: [
          ProtocolStatusWidget(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  Widget _buildMessageList() {
    return Consumer<HybridProtocolManager>(
      builder: (context, hybridManager, child) {
        // Combine messages from both protocols
        final bluetoothMessages = context.watch<BluetoothManager>().getCachedMessages();
        final wifiMessages = context.watch<WiFiDirectManager>().getCachedMessages();
        
        final allMessages = [...bluetoothMessages, ...wifiMessages];
        allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        return ListView.builder(
          controller: _scrollController,
          itemCount: allMessages.length,
          itemBuilder: (context, index) {
            final message = allMessages[index];
            return MessageBubble(
              message: message,
              showProtocolInfo: true,
            );
          },
        );
      },
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          SizedBox(width: 8),
          PopupMenuButton<MessageType>(
            icon: Icon(Icons.send),
            onSelected: (type) => _sendMessage(_messageController.text, type),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: MessageType.text,
                child: Text('Normal Message'),
              ),
              PopupMenuItem(
                value: MessageType.emergency,
                child: Text('Emergency Message'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _sendMessage(String content, [MessageType type = MessageType.text]) {
    if (content.trim().isEmpty) return;
    
    final hybridManager = Provider.of<HybridProtocolManager>(context, listen: false);
    final bluetoothManager = Provider.of<BluetoothManager>(context, listen: false);
    
    final message = Message(
      id: Message._generateMessageId(),
      senderId: bluetoothManager._getDeviceId(),
      content: content,
      timestamp: DateTime.now(),
      type: type,
    );
    
    hybridManager.sendMessage(message);
    _messageController.clear();
    
    // Scroll to bottom
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  void _showWiFiDirectOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildWiFiDirectOptions(),
    );
  }
  
  Widget _buildWiFiDirectOptions() {
    return Consumer<WiFiDirectManager>(
      builder: (context, wifiManager, child) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('WiFi Direct Options', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              if (!wifiManager.isGroupOwner) ...[
                ElevatedButton(
                  onPressed: () => wifiManager.createGroup('MESHNET_Group'),
                  child: Text('Create Group'),
                ),
                SizedBox(height: 8),
              ],
              if (wifiManager.isGroupOwner) ...[
                Text('Group: ${wifiManager.currentGroupName}'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => wifiManager.leaveGroup(),
                  child: Text('Leave Group'),
                ),
              ],
              SizedBox(height: 16),
              Text('Discovered Peers:'),
              ...wifiManager.discoveredPeers.map((peer) => ListTile(
                title: Text(peer.deviceName),
                subtitle: Text(peer.statusText),
                trailing: peer.isAvailable 
                    ? IconButton(
                        icon: Icon(Icons.connect_without_contact),
                        onPressed: () => wifiManager.joinGroup(peer),
                      )
                    : null,
              )),
            ],
          ),
        );
      },
    );
  }
  
  void _showBluetoothOptions() {
    // Show Bluetooth specific options
  }
  
  void _showNetworkStats() {
    showDialog(
      context: context,
      builder: (context) => _buildNetworkStatsDialog(),
    );
  }
  
  Widget _buildNetworkStatsDialog() {
    return Consumer<HybridProtocolManager>(
      builder: (context, hybridManager, child) {
        final stats = hybridManager.getNetworkStats();
        
        return AlertDialog(
          title: Text('Network Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bluetooth Peers: ${stats.bluetoothPeers}'),
              Text('WiFi Direct Peers: ${stats.wifiDirectPeers}'),
              Text('Total Peers: ${stats.totalPeers}'),
              SizedBox(height: 8),
              Text('Estimated Range:'),
              Text('  Bluetooth: ${stats.bluetoothRange.toInt()}m'),
              Text('  WiFi Direct: ${stats.wifiDirectRange.toInt()}m'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
```

#### **5. Protocol Status Widget**
```dart
// lib/widgets/protocol_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../services/wifi_direct_manager.dart';

class ProtocolStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.purple.shade900],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBluetoothStatus(),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildWiFiDirectStatus(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBluetoothStatus() {
    return Consumer<BluetoothManager>(
      builder: (context, bluetoothManager, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth,
                  color: bluetoothManager.connectedPeers.isNotEmpty 
                      ? Colors.green 
                      : Colors.grey,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'BLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '${bluetoothManager.connectedPeers.length} peers',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildWiFiDirectStatus() {
    return Consumer<WiFiDirectManager>(
      builder: (context, wifiManager, child) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi,
                  color: wifiManager.connectedPeers.isNotEmpty 
                      ? Colors.green 
                      : Colors.grey,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'WiFi Direct',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '${wifiManager.connectedPeers.length} peers',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
```

## 📊 Load Balancing & Optimization

### **1. Bandwidth Optimization**
```dart
// lib/services/bandwidth_optimizer.dart
class BandwidthOptimizer {
  static const int BLUETOOTH_MAX_THROUGHPUT = 2000; // 2 kbps
  static const int WIFI_DIRECT_MAX_THROUGHPUT = 250000; // 250 kbps
  
  static Future<void> optimizeMessageTransmission(
    Message message,
    List<Peer> bluetoothPeers,
    List<WiFiPeer> wifiPeers,
  ) async {
    final messageSize = message.content.length;
    
    // Calculate optimal split between protocols
    if (messageSize > BLUETOOTH_MAX_THROUGHPUT && wifiPeers.isNotEmpty) {
      // Send large messages via WiFi Direct
      await _sendViaWiFiDirect(message, wifiPeers);
    } else if (bluetoothPeers.isNotEmpty) {
      // Send small messages via Bluetooth
      await _sendViaBluetooth(message, bluetoothPeers);
    }
  }
  
  static Future<void> _sendViaWiFiDirect(Message message, List<WiFiPeer> peers) async {
    // Implementation
  }
  
  static Future<void> _sendViaBluetooth(Message message, List<Peer> peers) async {
    // Implementation
  }
}
```

## ✅ Bu Aşama Tamamlandığında

- [ ] **WiFi Direct peer discovery ve group formation**
- [ ] **High-bandwidth TCP data transfer**
- [ ] **Automatic protocol selection**
- [ ] **Cross-protocol bridging**
- [ ] **Load balancing ve bandwidth optimization**
- [ ] **Fallback mechanisms**
- [ ] **Network statistics monitoring**

## 🔄 Sonraki Adım

**4. Adım:** `4-SIFRELEME-GUVENLIGI.md` dosyasını inceleyin ve end-to-end encryption implementasyonuna başlayın.

---

**Son Güncelleme:** 11 Temmuz 2025  
**Durum:** WiFi Direct Clustering Implementasyonu Hazır
