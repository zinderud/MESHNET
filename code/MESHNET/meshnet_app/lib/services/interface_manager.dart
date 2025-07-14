// lib/services/interface_manager.dart
// Reticulum-style modular interface system
import 'dart:async';
import 'package:flutter/foundation.dart';

// Interface models
import '../models/interface_model.dart';
import '../models/packet_model.dart';

class InterfaceManager extends ChangeNotifier {
  // Active interfaces map
  final Map<String, MeshInterface> _interfaces = {};
  
  // Interface statistics
  final Map<String, InterfaceStats> _interfaceStats = {};
  
  // Packet callbacks
  final List<Function(PacketModel, String)> _packetCallbacks = [];
  
  // Getters
  List<MeshInterface> get activeInterfaces => _interfaces.values.toList();
  Map<String, InterfaceStats> get interfaceStats => Map.from(_interfaceStats);
  
  // Add interface (Reticulum pattern)
  Future<bool> addInterface(MeshInterface interface) async {
    try {
      await interface.initialize();
      
      _interfaces[interface.id] = interface;
      _interfaceStats[interface.id] = InterfaceStats();
      
      // Set up packet handling
      interface.onPacketReceived = (packet) => _handleReceivedPacket(packet, interface.id);
      
      debugPrint('Interface added: ${interface.name} (${interface.type})');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Failed to add interface ${interface.name}: $e');
      return false;
    }
  }
  
  // Remove interface
  Future<void> removeInterface(String interfaceId) async {
    final interface = _interfaces[interfaceId];
    if (interface != null) {
      await interface.cleanup();
      _interfaces.remove(interfaceId);
      _interfaceStats.remove(interfaceId);
      
      debugPrint('Interface removed: ${interface.name}');
      notifyListeners();
    }
  }
  
  // Send packet via specific interface
  Future<bool> sendPacket(PacketModel packet, String interfaceId) async {
    final interface = _interfaces[interfaceId];
    if (interface == null || !interface.isActive) {
      debugPrint('Interface $interfaceId not available');
      return false;
    }
    
    try {
      final success = await interface.sendPacket(packet);
      
      // Update statistics
      final stats = _interfaceStats[interfaceId]!;
      if (success) {
        stats.packetsSent++;
        stats.bytesSent += packet.data.length;
      } else {
        stats.sendErrors++;
      }
      
      return success;
    } catch (e) {
      debugPrint('Send packet error on $interfaceId: $e');
      _interfaceStats[interfaceId]!.sendErrors++;
      return false;
    }
  }
  
  // Broadcast packet on all active interfaces
  Future<List<bool>> broadcastPacket(PacketModel packet) async {
    final results = <bool>[];
    
    for (final interface in _interfaces.values) {
      if (interface.isActive && interface.canBroadcast) {
        final result = await sendPacket(packet, interface.id);
        results.add(result);
      }
    }
    
    return results;
  }
  
  // Find best interface for destination
  String? findBestInterface(String destinationHash, {InterfaceType? preferredType}) {
    // Simple implementation - can be enhanced with Reticulum routing logic
    final availableInterfaces = _interfaces.values
        .where((i) => i.isActive)
        .toList();
    
    if (availableInterfaces.isEmpty) return null;
    
    // Prefer specific interface type if requested
    if (preferredType != null) {
      final preferred = availableInterfaces
          .where((i) => i.type == preferredType)
          .toList();
      if (preferred.isNotEmpty) {
        return preferred.first.id;
      }
    }
    
    // Return first active interface as fallback
    return availableInterfaces.first.id;
  }
  
  // Handle received packet
  void _handleReceivedPacket(PacketModel packet, String interfaceId) {
    // Update statistics
    final stats = _interfaceStats[interfaceId]!;
    stats.packetsReceived++;
    stats.bytesReceived += packet.data.length;
    
    // Call registered callbacks
    for (final callback in _packetCallbacks) {
      try {
        callback(packet, interfaceId);
      } catch (e) {
        debugPrint('Packet callback error: $e');
      }
    }
  }
  
  // Register packet callback
  void addPacketCallback(Function(PacketModel, String) callback) {
    _packetCallbacks.add(callback);
  }
  
  // Remove packet callback
  void removePacketCallback(Function(PacketModel, String) callback) {
    _packetCallbacks.remove(callback);
  }
  
  // Get interface by ID
  MeshInterface? getInterface(String interfaceId) {
    return _interfaces[interfaceId];
  }
  
  // Get interfaces by type
  List<MeshInterface> getInterfacesByType(InterfaceType type) {
    return _interfaces.values
        .where((i) => i.type == type)
        .toList();
  }
  
  // Emergency shutdown - close all interfaces
  Future<void> emergencyShutdown() async {
    debugPrint('Emergency interface shutdown initiated');
    
    for (final interface in _interfaces.values) {
      try {
        await interface.cleanup();
      } catch (e) {
        debugPrint('Error shutting down interface ${interface.name}: $e');
      }
    }
    
    _interfaces.clear();
    _interfaceStats.clear();
    _packetCallbacks.clear();
    
    notifyListeners();
  }
}

// Interface statistics
class InterfaceStats {
  int packetsSent = 0;
  int packetsReceived = 0;
  int bytesSent = 0;
  int bytesReceived = 0;
  int sendErrors = 0;
  int receiveErrors = 0;
  DateTime lastActivity = DateTime.now();
  
  double get packetSuccessRate {
    final total = packetsSent + sendErrors;
    return total > 0 ? packetsSent / total : 0.0;
  }
  
  Map<String, dynamic> toJson() => {
    'packets_sent': packetsSent,
    'packets_received': packetsReceived,
    'bytes_sent': bytesSent,
    'bytes_received': bytesReceived,
    'send_errors': sendErrors,
    'receive_errors': receiveErrors,
    'success_rate': packetSuccessRate,
    'last_activity': lastActivity.toIso8601String(),
  };
}
