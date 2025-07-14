// lib/models/interface_model.dart
// Reticulum-style interface abstraction
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'packet_model.dart';

// Interface types (expandable for new protocols)
enum InterfaceType {
  bluetooth,
  wifiDirect,
  serial,
  tcp,
  udp,
  rtlsdr,
  hackrf,
  rnode,
  i2p,
  custom,
}

// Abstract interface class (Reticulum pattern)
abstract class MeshInterface {
  final String id;
  final String name;
  final InterfaceType type;
  final Map<String, dynamic> config;
  
  bool _isActive = false;
  bool _canBroadcast = true;
  
  // Packet callback
  Function(PacketModel)? onPacketReceived;
  
  MeshInterface({
    required this.id,
    required this.name,
    required this.type,
    this.config = const {},
  });
  
  // Getters
  bool get isActive => _isActive;
  bool get canBroadcast => _canBroadcast;
  
  // Abstract methods (must be implemented by concrete interfaces)
  Future<bool> initialize();
  Future<bool> sendPacket(PacketModel packet);
  Future<void> cleanup();
  
  // Common interface functionality
  void setActive(bool active) {
    _isActive = active;
  }
  
  void setBroadcastCapability(bool canBroadcast) {
    _canBroadcast = canBroadcast;
  }
  
  // Handle received data
  void handleReceivedData(Uint8List data, {Map<String, dynamic>? metadata}) {
    try {
      final packet = PacketModel.fromBytes(data, metadata: metadata);
      onPacketReceived?.call(packet);
    } catch (e) {
      debugPrint('Error parsing received data on $name: $e');
    }
  }
  
  @override
  String toString() => '$name ($type) - Active: $isActive';
}

// Bluetooth LE Interface (BitChat compatible)
class BluetoothInterface extends MeshInterface {
  BluetoothInterface() : super(
    id: 'bluetooth_le',
    name: 'Bluetooth LE',
    type: InterfaceType.bluetooth,
  );
  
  @override
  Future<bool> initialize() async {
    try {
      // Initialize Bluetooth LE
      // Implementation from bluetooth_manager.dart
      debugPrint('Initializing Bluetooth LE interface');
      setActive(true);
      return true;
    } catch (e) {
      debugPrint('Bluetooth LE initialization failed: $e');
      return false;
    }
  }
  
  @override
  Future<bool> sendPacket(PacketModel packet) async {
    if (!isActive) return false;
    
    try {
      // Send via Bluetooth LE
      // Implementation would use BluetoothManager
      debugPrint('Sending packet via Bluetooth LE: ${packet.destinationHash}');
      return true;
    } catch (e) {
      debugPrint('Bluetooth LE send error: $e');
      return false;
    }
  }
  
  @override
  Future<void> cleanup() async {
    setActive(false);
    debugPrint('Bluetooth LE interface cleaned up');
  }
}

// WiFi Direct Interface (BitChat compatible)
class WiFiDirectInterface extends MeshInterface {
  WiFiDirectInterface() : super(
    id: 'wifi_direct',
    name: 'WiFi Direct',
    type: InterfaceType.wifiDirect,
  );
  
  @override
  Future<bool> initialize() async {
    try {
      debugPrint('Initializing WiFi Direct interface');
      setActive(true);
      return true;
    } catch (e) {
      debugPrint('WiFi Direct initialization failed: $e');
      return false;
    }
  }
  
  @override
  Future<bool> sendPacket(PacketModel packet) async {
    if (!isActive) return false;
    
    try {
      debugPrint('Sending packet via WiFi Direct: ${packet.destinationHash}');
      return true;
    } catch (e) {
      debugPrint('WiFi Direct send error: $e');
      return false;
    }
  }
  
  @override
  Future<void> cleanup() async {
    setActive(false);
    debugPrint('WiFi Direct interface cleaned up');
  }
}

// RTL-SDR Interface (MESHNET specific, receive-only)
class RTLSDRInterface extends MeshInterface {
  RTLSDRInterface() : super(
    id: 'rtl_sdr',
    name: 'RTL-SDR',
    type: InterfaceType.rtlsdr,
  );
  
  @override
  Future<bool> initialize() async {
    try {
      debugPrint('Initializing RTL-SDR interface');
      setBroadcastCapability(false); // Receive-only
      setActive(true);
      return true;
    } catch (e) {
      debugPrint('RTL-SDR initialization failed: $e');
      return false;
    }
  }
  
  @override
  Future<bool> sendPacket(PacketModel packet) async {
    // RTL-SDR is receive-only
    debugPrint('RTL-SDR cannot send packets (receive-only)');
    return false;
  }
  
  @override
  Future<void> cleanup() async {
    setActive(false);
    debugPrint('RTL-SDR interface cleaned up');
  }
}

// HackRF Interface (MESHNET specific, TX/RX)
class HackRFInterface extends MeshInterface {
  HackRFInterface() : super(
    id: 'hackrf_one',
    name: 'HackRF One',
    type: InterfaceType.hackrf,
  );
  
  @override
  Future<bool> initialize() async {
    try {
      debugPrint('Initializing HackRF One interface');
      setActive(true);
      return true;
    } catch (e) {
      debugPrint('HackRF One initialization failed: $e');
      return false;
    }
  }
  
  @override
  Future<bool> sendPacket(PacketModel packet) async {
    if (!isActive) return false;
    
    try {
      debugPrint('Sending packet via HackRF One: ${packet.destinationHash}');
      // Implementation would use HackRFManager
      return true;
    } catch (e) {
      debugPrint('HackRF One send error: $e');
      return false;
    }
  }
  
  @override
  Future<void> cleanup() async {
    setActive(false);
    debugPrint('HackRF One interface cleaned up');
  }
}

// TCP Interface (Reticulum standard)
class TCPInterface extends MeshInterface {
  final String host;
  final int port;
  
  TCPInterface({
    required this.host,
    required this.port,
  }) : super(
    id: 'tcp_${host}_$port',
    name: 'TCP $host:$port',
    type: InterfaceType.tcp,
    config: {'host': host, 'port': port},
  );
  
  @override
  Future<bool> initialize() async {
    try {
      debugPrint('Initializing TCP interface: $host:$port');
      setActive(true);
      return true;
    } catch (e) {
      debugPrint('TCP interface initialization failed: $e');
      return false;
    }
  }
  
  @override
  Future<bool> sendPacket(PacketModel packet) async {
    if (!isActive) return false;
    
    try {
      debugPrint('Sending packet via TCP: ${packet.destinationHash}');
      return true;
    } catch (e) {
      debugPrint('TCP send error: $e');
      return false;
    }
  }
  
  @override
  Future<void> cleanup() async {
    setActive(false);
    debugPrint('TCP interface cleaned up');
  }
}
