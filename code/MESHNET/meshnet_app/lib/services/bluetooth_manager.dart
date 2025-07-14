// lib/services/bluetooth_manager.dart - BitChat'teki BluetoothManager.swift'ten çevrildi
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/peer.dart';
import '../models/message.dart';

class BluetoothManager extends ChangeNotifier {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<Peer> _discoveredPeers = [];
  List<BluetoothConnection> _activeConnections = [];
  bool _isScanning = false;
  
  // BitChat'teki CBCentralManager + CBPeripheralManager functionality
  List<Peer> get discoveredPeers => _discoveredPeers;
  bool get isScanning => _isScanning;
  List<BluetoothConnection> get activeConnections => _activeConnections;
  
  // BitChat'teki startScanning() fonksiyonu
  Future<void> startScanning() async {
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      notifyListeners();
      
      _bluetooth.startDiscovery().listen((deviceDiscovery) {
        final device = deviceDiscovery.device;
        
        // BitChat'teki peer discovery logic
        if (!_discoveredPeers.any((p) => p.id == device.address)) {
          final peer = Peer(
            id: device.address,
            name: device.name ?? 'Unknown Device',
            lastSeen: DateTime.now(),
            signalStrength: deviceDiscovery.rssi?.toDouble() ?? -1.0,
            supportedProtocols: ['bluetooth_le'],
            status: PeerStatus.discovered,
          );
          
          _discoveredPeers.add(peer);
          notifyListeners();
          
          debugPrint('MESHNET: Discovered peer ${peer.name} (${peer.id})');
        }
      });
    } catch (e) {
      debugPrint('MESHNET: Bluetooth scanning error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }
  
  // BitChat'teki stopScanning() fonksiyonu
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    try {
      await _bluetooth.cancelDiscovery();
      _isScanning = false;
      notifyListeners();
      debugPrint('MESHNET: Bluetooth scanning stopped');
    } catch (e) {
      debugPrint('MESHNET: Error stopping scan: $e');
    }
  }
  
  // BitChat'teki connection establishment
  Future<bool> connectToPeer(Peer peer) async {
    try {
      final device = BluetoothDevice.fromMap({
        'address': peer.id,
        'name': peer.name,
        'type': 1, // Classic bluetooth
      });
      
      final connection = await BluetoothConnection.toAddress(peer.id);
      _activeConnections.add(connection);
      
      // Update peer status
      final peerIndex = _discoveredPeers.indexWhere((p) => p.id == peer.id);
      if (peerIndex != -1) {
        _discoveredPeers[peerIndex] = Peer(
          id: peer.id,
          name: peer.name,
          lastSeen: DateTime.now(),
          signalStrength: peer.signalStrength,
          supportedProtocols: peer.supportedProtocols,
          status: PeerStatus.connected,
        );
      }
      
      // Set up message listener
      _setupMessageListener(connection, peer);
      
      notifyListeners();
      debugPrint('MESHNET: Connected to peer ${peer.name}');
      return true;
    } catch (e) {
      debugPrint('MESHNET: Connection failed to ${peer.name}: $e');
      return false;
    }
  }
  
  // BitChat'teki message listener setup
  void _setupMessageListener(BluetoothConnection connection, Peer peer) {
    connection.input!.listen((data) {
      try {
        final messageString = String.fromCharCodes(data);
        final messageJson = Map<String, dynamic>.from(
          Uri.splitQueryString(messageString)
        );
        final message = Message.fromJson(messageJson);
        
        // Forward to mesh network manager
        debugPrint('MESHNET: Received message from ${peer.name}: ${message.content}');
        
        // Notify listeners about received message
        notifyListeners();
      } catch (e) {
        debugPrint('MESHNET: Error parsing message: $e');
      }
    });
  }
  
  // BitChat'teki sendMessage() fonksiyonu
  Future<void> sendMessage(Message message, Peer targetPeer) async {
    try {
      final connection = _activeConnections.firstWhere(
        (conn) => conn.address == targetPeer.id,
      );
      
      final messageString = Uri(queryParameters: message.toJson()).query;
      connection.output.add(messageString.codeUnits);
      await connection.output.allSent;
      
      debugPrint('MESHNET: Sent message to ${targetPeer.name}');
    } catch (e) {
      debugPrint('MESHNET: Failed to send message to ${targetPeer.name}: $e');
    }
  }
  
  // BitChat'teki broadcastMessage() fonksiyonu
  Future<void> broadcastMessage(Message message) async {
    for (final connection in _activeConnections) {
      try {
        final messageString = Uri(queryParameters: message.toJson()).query;
        connection.output.add(messageString.codeUnits);
        await connection.output.allSent;
      } catch (e) {
        debugPrint('MESHNET: Failed to broadcast message: $e');
      }
    }
    debugPrint('MESHNET: Broadcasted message to ${_activeConnections.length} peers');
  }
  
  // Cleanup
  void dispose() {
    stopScanning();
    for (final connection in _activeConnections) {
      connection.dispose();
    }
    super.dispose();
  }
}
