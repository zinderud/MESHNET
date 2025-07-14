// lib/services/mesh_network_manager.dart - BitChat'teki MeshNetworkManager.swift'ten çevrildi
import 'package:flutter/foundation.dart';
import '../models/peer.dart';
import '../models/message.dart';
import '../models/channel.dart';

class MeshNetworkManager extends ChangeNotifier {
  // BitChat'teki routing table ve message cache
  Map<String, RouteInfo> _routingTable = {};
  Map<String, Message> _messageCache = {};
  List<Channel> _channels = [];
  String? _currentChannelId;
  String _currentUserId = '';
  
  // Getters
  Map<String, RouteInfo> get routingTable => _routingTable;
  List<Channel> get channels => _channels;
  Channel? get currentChannel => _currentChannelId != null 
      ? _channels.firstWhere((c) => c.id == _currentChannelId, orElse: () => null as Channel)
      : null;
  String get currentUserId => _currentUserId;
  
  // Initialize mesh network
  void initialize(String userId) {
    _currentUserId = userId;
    
    // Create default public channel - BitChat'teki genel sohbet
    final publicChannel = Channel(
      id: 'public',
      name: '#general',
      ownerId: 'system',
      members: [userId],
      createdAt: DateTime.now(),
      isPasswordProtected: false,
      messageRetention: false,
    );
    
    _channels.add(publicChannel);
    _currentChannelId = 'public';
    notifyListeners();
  }
  
  // BitChat'teki routing logic - Dijkstra's algorithm for shortest path
  List<String> findRoute(String targetPeerId) {
    if (_routingTable.containsKey(targetPeerId)) {
      return _routingTable[targetPeerId]!.path;
    }
    
    // Dijkstra's algorithm implementation
    return _calculateShortestPath(targetPeerId);
  }
  
  List<String> _calculateShortestPath(String target) {
    // Simple implementation - BitChat'teki gibi
    // Gerçek implementasyon Dijkstra's algorithm kullanır
    
    final visited = <String>{};
    final distances = <String, int>{};
    final previous = <String, String?>{};
    final unvisited = <String>[];
    
    // Initialize distances
    for (final peerId in _routingTable.keys) {
      distances[peerId] = peerId == _currentUserId ? 0 : 999999;
      unvisited.add(peerId);
    }
    
    while (unvisited.isNotEmpty) {
      // Find unvisited node with minimum distance
      String? currentNode;
      int minDistance = 999999;
      
      for (final node in unvisited) {
        if (distances[node]! < minDistance) {
          minDistance = distances[node]!;
          currentNode = node;
        }
      }
      
      if (currentNode == null) break;
      
      unvisited.remove(currentNode);
      visited.add(currentNode);
      
      if (currentNode == target) {
        // Reconstruct path
        final path = <String>[];
        String? current = target;
        
        while (current != null) {
          path.insert(0, current);
          current = previous[current];
        }
        
        return path;
      }
      
      // Update distances to neighbors
      // This would use actual network topology in real implementation
    }
    
    return []; // No path found
  }
  
  // BitChat'teki message routing
  Future<void> routeMessage(Message message) async {
    final route = findRoute(message.senderId);
    
    if (route.isNotEmpty) {
      await _forwardMessage(message, route);
    } else {
      // Store for later forwarding
      storeMessage(message);
    }
  }
  
  Future<void> _forwardMessage(Message message, List<String> route) async {
    // Implementation would forward message through the route
    debugPrint('MESHNET: Forwarding message through route: ${route.join(' -> ')}');
    
    // Add to current channel if it's a channel message
    if (_currentChannelId != null) {
      await addMessageToChannel(message, _currentChannelId!);
    }
  }
  
  // BitChat'teki store & forward functionality
  void storeMessage(Message message) {
    _messageCache[message.id] = message;
    
    // Cleanup old messages (keep last 1000)
    if (_messageCache.length > 1000) {
      final oldestKey = _messageCache.keys.first;
      _messageCache.remove(oldestKey);
    }
    
    debugPrint('MESHNET: Stored message ${message.id} for later forwarding');
  }
  
  void forwardStoredMessages(String peerId) {
    for (final message in _messageCache.values) {
      if (!message.routePath.contains(peerId)) {
        // Forward message to newly connected peer
        _forwardMessage(message, [peerId]);
      }
    }
    debugPrint('MESHNET: Forwarded stored messages to $peerId');
  }
  
  // Channel management - BitChat'teki channel functionality
  Future<bool> joinChannel(String channelName, {String? password}) async {
    // Find or create channel
    Channel? channel = _channels.firstWhere(
      (c) => c.name == channelName,
      orElse: () => null as Channel,
    );
    
    if (channel == null) {
      // Create new channel
      channel = Channel(
        id: 'channel_${DateTime.now().millisecondsSinceEpoch}',
        name: channelName,
        password: password,
        ownerId: _currentUserId,
        members: [_currentUserId],
        createdAt: DateTime.now(),
        isPasswordProtected: password != null,
        messageRetention: false,
      );
      _channels.add(channel);
    } else {
      // Check if user can join
      if (!channel.canUserJoin(_currentUserId, password)) {
        return false;
      }
      
      // Add user to channel
      final updatedChannel = channel.addMember(_currentUserId);
      final channelIndex = _channels.indexWhere((c) => c.id == channel!.id);
      _channels[channelIndex] = updatedChannel;
    }
    
    _currentChannelId = channel.id;
    notifyListeners();
    
    debugPrint('MESHNET: Joined channel $channelName');
    return true;
  }
  
  Future<void> leaveChannel(String channelId) async {
    final channelIndex = _channels.indexWhere((c) => c.id == channelId);
    if (channelIndex != -1) {
      final channel = _channels[channelIndex];
      final updatedChannel = channel.removeMember(_currentUserId);
      _channels[channelIndex] = updatedChannel;
      
      // Switch to public channel if leaving current channel
      if (_currentChannelId == channelId) {
        _currentChannelId = 'public';
      }
      
      notifyListeners();
      debugPrint('MESHNET: Left channel ${channel.name}');
    }
  }
  
  Future<void> addMessageToChannel(Message message, String channelId) async {
    final channelIndex = _channels.indexWhere((c) => c.id == channelId);
    if (channelIndex != -1) {
      final channel = _channels[channelIndex];
      final updatedChannel = channel.addMessage(message);
      _channels[channelIndex] = updatedChannel;
      notifyListeners();
    }
  }
  
  // Route table management
  void updateRouteInfo(String peerId, RouteInfo routeInfo) {
    _routingTable[peerId] = routeInfo;
    debugPrint('MESHNET: Updated route to $peerId: ${routeInfo.path.join(' -> ')}');
  }
  
  void removeRoute(String peerId) {
    _routingTable.remove(peerId);
    debugPrint('MESHNET: Removed route to $peerId');
  }
  
  // Network topology updates
  void updateNetworkTopology(List<Peer> peers) {
    // Update routing table based on discovered peers
    for (final peer in peers) {
      if (peer.isOnline() && !_routingTable.containsKey(peer.id)) {
        final routeInfo = RouteInfo(
          path: [_currentUserId, peer.id],
          hopCount: 1,
          reliability: 1.0,
          lastUsed: DateTime.now(),
        );
        updateRouteInfo(peer.id, routeInfo);
      }
    }
    
    // Remove routes for offline peers
    _routingTable.removeWhere((peerId, route) {
      final peer = peers.firstWhere(
        (p) => p.id == peerId,
        orElse: () => null as Peer,
      );
      return peer == null || !peer.isOnline();
    });
  }
}
