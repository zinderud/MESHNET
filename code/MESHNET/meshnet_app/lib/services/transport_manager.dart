// lib/services/transport_manager.dart
// Reticulum-style transport layer with routing
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/packet_model.dart';
import '../models/interface_model.dart';
import 'interface_manager.dart';
import 'identity_manager.dart';

class TransportManager extends ChangeNotifier {
  final InterfaceManager _interfaceManager;
  final IdentityManager _identityManager;
  
  // Routing table: destination_hash -> route_info
  final Map<String, RouteInfo> _routingTable = {};
  
  // Packet recall buffer (for deduplication)
  final Queue<String> _packetRecall = Queue();
  static const int MAX_RECALL_SIZE = 1000;
  
  // Announce table: stores known destinations
  final Map<String, AnnounceInfo> _announceTable = {};
  
  // Pending path requests
  final Map<String, PathRequest> _pendingRequests = {};
  
  // Transport statistics
  int _packetsForwarded = 0;
  int _packetsDropped = 0;
  int _duplicatesFiltered = 0;
  
  TransportManager(this._interfaceManager, this._identityManager) {
    _initialize();
  }
  
  void _initialize() {
    // Register for packet callbacks
    _interfaceManager.addPacketCallback(_handleIncomingPacket);
    
    // Start periodic maintenance
    Timer.periodic(Duration(minutes: 1), _performMaintenance);
    
    debugPrint('Transport manager initialized');
  }
  
  // Handle incoming packet (Reticulum transport logic)
  void _handleIncomingPacket(PacketModel packet, String fromInterface) {
    final packetHash = packet.calculateHash();
    
    // Check for duplicate packets
    if (_packetRecall.contains(packetHash)) {
      _duplicatesFiltered++;
      debugPrint('Duplicate packet filtered: ${packet.destinationHash}');
      return;
    }
    
    // Add to recall buffer
    _addToRecall(packetHash);
    
    // Handle different packet types
    switch (packet.type) {
      case PacketType.announce:
        _handleAnnounce(packet, fromInterface);
        break;
      case PacketType.data:
        _handleDataPacket(packet, fromInterface);
        break;
      case PacketType.pathRequest:
        _handlePathRequest(packet, fromInterface);
        break;
      case PacketType.pathReply:
        _handlePathReply(packet, fromInterface);
        break;
      case PacketType.emergency:
        _handleEmergencyPacket(packet, fromInterface);
        break;
      default:
        debugPrint('Unknown packet type: ${packet.type}');
    }
  }
  
  // Handle announce packet (destination discovery)
  void _handleAnnounce(PacketModel packet, String fromInterface) {
    try {
      // Parse announce data
      final announceData = _parseAnnounceData(packet.data);
      if (announceData == null) return;
      
      final destinationHash = announceData['destination_hash'] as String;
      
      // Update announce table
      _announceTable[destinationHash] = AnnounceInfo(
        destinationHash: destinationHash,
        publicKeys: announceData['public_keys'] as Map<String, String>,
        appName: announceData['app_name'] as String,
        aspects: List<String>.from(announceData['aspects'] ?? []),
        timestamp: DateTime.now(),
        hopCount: packet.hopCount,
        fromInterface: fromInterface,
      );
      
      // Update routing table
      _routingTable[destinationHash] = RouteInfo(
        destinationHash: destinationHash,
        nextHop: packet.sourceHash,
        interfaceId: fromInterface,
        hopCount: packet.hopCount + 1,
        timestamp: DateTime.now(),
      );
      
      debugPrint('Announce processed: $destinationHash via $fromInterface');
      
      // Rebroadcast if hop count allows
      if (packet.shouldForward()) {
        _rebroadcastPacket(packet, fromInterface);
      }
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error handling announce: $e');
    }
  }
  
  // Handle data packet
  void _handleDataPacket(PacketModel packet, String fromInterface) {
    final myHash = _identityManager.identityHashHex;
    
    // Check if packet is for us
    if (packet.destinationHash == myHash) {
      debugPrint('Received data packet for local destination');
      _deliverLocalPacket(packet);
      return;
    }
    
    // Check if it's a broadcast
    if (packet.destinationHash == 'emergency_broadcast') {
      debugPrint('Received emergency broadcast');
      _deliverLocalPacket(packet);
      // Also forward emergency broadcasts
    }
    
    // Forward packet if possible
    if (packet.shouldForward()) {
      _forwardPacket(packet, fromInterface);
    }
  }
  
  // Handle path request (route discovery)
  void _handlePathRequest(PacketModel packet, String fromInterface) {
    // Check if we know the destination
    final destinationHash = packet.destinationHash;
    
    if (_routingTable.containsKey(destinationHash)) {
      // Send path reply
      _sendPathReply(packet, fromInterface);
    } else {
      // Rebroadcast path request
      if (packet.shouldForward()) {
        _rebroadcastPacket(packet, fromInterface);
      }
    }
  }
  
  // Handle path reply
  void _handlePathReply(PacketModel packet, String fromInterface) {
    // Update routing table with new path information
    final pathInfo = _parsePathReplyData(packet.data);
    if (pathInfo != null) {
      final destinationHash = pathInfo['destination_hash'] as String;
      
      _routingTable[destinationHash] = RouteInfo(
        destinationHash: destinationHash,
        nextHop: packet.sourceHash,
        interfaceId: fromInterface,
        hopCount: packet.hopCount + 1,
        timestamp: DateTime.now(),
      );
      
      debugPrint('Path reply processed: $destinationHash via $fromInterface');
      notifyListeners();
    }
  }
  
  // Handle emergency packet (high priority)
  void _handleEmergencyPacket(PacketModel packet, String fromInterface) {
    debugPrint('Emergency packet received from $fromInterface');
    
    // Always deliver emergency packets locally
    _deliverLocalPacket(packet);
    
    // Always forward emergency packets (with higher priority)
    if (packet.shouldForward()) {
      _forwardPacket(packet, fromInterface, priority: PacketPriority.emergency);
    }
  }
  
  // Send packet to destination
  Future<bool> sendPacket(PacketModel packet, {PacketPriority priority = PacketPriority.normal}) async {
    final destinationHash = packet.destinationHash;
    
    // Check if destination is known
    final route = _routingTable[destinationHash];
    
    if (route != null) {
      // Send via known route
      return await _interfaceManager.sendPacket(packet, route.interfaceId);
    } else {
      // Broadcast on all interfaces (discovery)
      final results = await _interfaceManager.broadcastPacket(packet);
      return results.any((success) => success);
    }
  }
  
  // Announce local destination
  Future<bool> announceDestination(
    String destinationHash,
    Map<String, String> publicKeys,
    String appName,
    List<String> aspects,
  ) async {
    final announcePacket = PacketModel.announce(
      destinationHash: destinationHash,
      publicKeys: publicKeys.map((k, v) => MapEntry(k, _base64ToBytes(v))),
      appName: appName,
      aspects: aspects,
    );
    
    return await sendPacket(announcePacket);
  }
  
  // Request path to destination
  Future<bool> requestPath(String destinationHash) async {
    final pathRequestPacket = PacketModel(
      destinationHash: destinationHash,
      sourceHash: _identityManager.identityHashHex,
      type: PacketType.pathRequest,
      data: Uint8List.fromList([]),
    );
    
    return await sendPacket(pathRequestPacket);
  }
  
  // Forward packet to next hop
  Future<void> _forwardPacket(PacketModel packet, String excludeInterface, {PacketPriority priority = PacketPriority.normal}) async {
    final route = _routingTable[packet.destinationHash];
    
    if (route != null && route.interfaceId != excludeInterface) {
      // Forward via specific route
      final forwardedPacket = packet.incrementHops();
      await _interfaceManager.sendPacket(forwardedPacket, route.interfaceId);
      _packetsForwarded++;
    } else {
      // Broadcast on other interfaces
      final interfaces = _interfaceManager.activeInterfaces
          .where((i) => i.id != excludeInterface)
          .toList();
      
      for (final interface in interfaces) {
        final forwardedPacket = packet.incrementHops();
        await _interfaceManager.sendPacket(forwardedPacket, interface.id);
      }
      _packetsForwarded++;
    }
  }
  
  // Rebroadcast packet (for announces, path requests)
  Future<void> _rebroadcastPacket(PacketModel packet, String excludeInterface) async {
    final interfaces = _interfaceManager.activeInterfaces
        .where((i) => i.id != excludeInterface && i.canBroadcast)
        .toList();
    
    for (final interface in interfaces) {
      final rebroadcastPacket = packet.incrementHops();
      await _interfaceManager.sendPacket(rebroadcastPacket, interface.id);
    }
  }
  
  // Deliver packet to local handlers
  void _deliverLocalPacket(PacketModel packet) {
    // Emit packet for local handling
    _localPacketController.add(packet);
  }
  
  // Send path reply
  Future<void> _sendPathReply(PacketModel originalRequest, String fromInterface) async {
    final replyData = {
      'destination_hash': originalRequest.destinationHash,
      'path_found': true,
      'hop_count': originalRequest.hopCount,
    };
    
    final pathReplyPacket = PacketModel(
      destinationHash: originalRequest.sourceHash ?? '',
      sourceHash: _identityManager.identityHashHex,
      type: PacketType.pathReply,
      data: Uint8List.fromList(_stringToBytes(replyData.toString())),
    );
    
    await _interfaceManager.sendPacket(pathReplyPacket, fromInterface);
  }
  
  // Maintenance tasks
  void _performMaintenance(Timer timer) {
    _cleanupExpiredRoutes();
    _cleanupRecallBuffer();
    _cleanupPendingRequests();
  }
  
  // Cleanup expired routes
  void _cleanupExpiredRoutes() {
    final now = DateTime.now();
    _routingTable.removeWhere((key, route) {
      final expired = now.difference(route.timestamp).inMinutes > 30;
      if (expired) {
        debugPrint('Removing expired route: $key');
      }
      return expired;
    });
  }
  
  // Cleanup recall buffer
  void _cleanupRecallBuffer() {
    while (_packetRecall.length > MAX_RECALL_SIZE) {
      _packetRecall.removeFirst();
    }
  }
  
  // Cleanup pending requests
  void _cleanupPendingRequests() {
    final now = DateTime.now();
    _pendingRequests.removeWhere((key, request) {
      final expired = now.difference(request.timestamp).inMinutes > 5;
      return expired;
    });
  }
  
  // Add packet hash to recall buffer
  void _addToRecall(String packetHash) {
    _packetRecall.add(packetHash);
    if (_packetRecall.length > MAX_RECALL_SIZE) {
      _packetRecall.removeFirst();
    }
  }
  
  // Stream for local packet delivery
  final StreamController<PacketModel> _localPacketController = StreamController.broadcast();
  Stream<PacketModel> get localPacketStream => _localPacketController.stream;
  
  // Helper methods
  Map<String, dynamic>? _parseAnnounceData(Uint8List data) {
    try {
      final jsonString = String.fromCharCodes(data);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing announce data: $e');
      return null;
    }
  }
  
  Map<String, dynamic>? _parsePathReplyData(Uint8List data) {
    try {
      final jsonString = String.fromCharCodes(data);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing path reply data: $e');
      return null;
    }
  }
  
  Uint8List _base64ToBytes(String base64) {
    return Uint8List.fromList(base64Decode(base64));
  }
  
  List<int> _stringToBytes(String str) {
    return utf8.encode(str);
  }
  
  // Getters
  Map<String, RouteInfo> get routingTable => Map.from(_routingTable);
  Map<String, AnnounceInfo> get announceTable => Map.from(_announceTable);
  int get packetsForwarded => _packetsForwarded;
  int get packetsDropped => _packetsDropped;
  int get duplicatesFiltered => _duplicatesFiltered;
  
  @override
  void dispose() {
    _localPacketController.close();
    super.dispose();
  }
}

// Route information
class RouteInfo {
  final String destinationHash;
  final String? nextHop;
  final String interfaceId;
  final int hopCount;
  final DateTime timestamp;
  
  RouteInfo({
    required this.destinationHash,
    this.nextHop,
    required this.interfaceId,
    required this.hopCount,
    required this.timestamp,
  });
}

// Announce information
class AnnounceInfo {
  final String destinationHash;
  final Map<String, String> publicKeys;
  final String appName;
  final List<String> aspects;
  final DateTime timestamp;
  final int hopCount;
  final String fromInterface;
  
  AnnounceInfo({
    required this.destinationHash,
    required this.publicKeys,
    required this.appName,
    required this.aspects,
    required this.timestamp,
    required this.hopCount,
    required this.fromInterface,
  });
}

// Path request tracking
class PathRequest {
  final String destinationHash;
  final String requesterId;
  final DateTime timestamp;
  
  PathRequest({
    required this.destinationHash,
    required this.requesterId,
    required this.timestamp,
  });
}
