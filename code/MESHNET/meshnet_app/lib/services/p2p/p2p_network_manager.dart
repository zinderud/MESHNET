// lib/services/p2p/p2p_network_manager.dart - P2P Network Manager
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meshnet_app/services/p2p/mesh_network_core.dart';
import 'package:meshnet_app/services/blockchain/blockchain_manager.dart';
import 'package:meshnet_app/utils/logger.dart';

/// P2P Network Manager for emergency mesh communication
class P2PNetworkManager {
  static P2PNetworkManager? _instance;
  static P2PNetworkManager get instance => _instance ??= P2PNetworkManager._internal();
  
  P2PNetworkManager._internal();

  final Logger _logger = Logger('P2PNetworkManager');
  MeshNetworkCore? _meshCore;
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _nodeSubscription;
  
  final StreamController<Map<String, dynamic>> _emergencyController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _chatController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<MeshNode> _peerController = 
      StreamController<MeshNode>.broadcast();

  bool get isInitialized => _meshCore != null;
  List<MeshNode> get connectedPeers => _meshCore?.connectedNodes ?? [];
  List<MeshNode> get trustedPeers => _meshCore?.trustedNodes ?? [];
  Stream<Map<String, dynamic>> get emergencyStream => _emergencyController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  Stream<MeshNode> get peerStream => _peerController.stream;

  /// Initialize P2P network manager
  Future<bool> initialize() async {
    try {
      // Logging disabled;
      
      // Get node identity from blockchain manager
      if (!BlockchainManager.instance.isInitialized) {
        await BlockchainManager.instance.initialize();
      }
      
      final nodeId = BlockchainManager.instance.nodePublicKey!;
      final publicKey = nodeId; // Using same key for simplicity
      
      // Initialize mesh network core
      _meshCore = MeshNetworkCore(nodeId: nodeId, publicKey: publicKey);
      await _meshCore!.initialize();
      
      // Set up message listeners
      _setupMessageListeners();
      
      // Logging disabled;
      return true;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Shutdown P2P network manager
  Future<void> shutdown() async {
    // Logging disabled;
    
    await _messageSubscription?.cancel();
    await _nodeSubscription?.cancel();
    
    await _meshCore?.shutdown();
    _meshCore = null;
    
    await _emergencyController.close();
    await _chatController.close();
    await _peerController.close();
    
    // Logging disabled;
  }

  /// Send emergency alert to mesh network
  Future<bool> sendEmergencyAlert({
    required String message,
    required Map<String, dynamic> location,
    int priority = 1,
    bool broadcast = true,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final meshMessage = MeshMessage.create(
        type: MeshMessageType.emergency,
        sourceNodeId: _meshCore!.nodeId,
        destinationNodeId: broadcast ? 'broadcast' : 'emergency_responders',
        payload: {
          'type': 'emergency_alert',
          'message': message,
          'location': location,
          'priority': priority,
          'timestamp': DateTime.now().toIso8601String(),
          'senderId': _meshCore!.nodeId,
          'alertId': _generateAlertId(),
        },
        priority: priority,
        requiresAck: !broadcast,
      );

      final success = await _meshCore!.sendMessage(meshMessage);
      
      if (success) {
        // Also add to blockchain
        await BlockchainManager.instance.addEmergencyMessage(
          message: message,
          senderAddress: _meshCore!.nodeId,
          location: location,
          priority: priority,
        );
        
        // Logging disabled;
      }
      
      return success;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Send chat message to specific peer
  Future<bool> sendChatMessage({
    required String recipientId,
    required String message,
    String? replyToId,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final meshMessage = MeshMessage.create(
        type: MeshMessageType.data,
        sourceNodeId: _meshCore!.nodeId,
        destinationNodeId: recipientId,
        payload: {
          'type': 'chat_message',
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'senderId': _meshCore!.nodeId,
          'replyToId': replyToId,
          'messageId': _generateMessageId(),
        },
        requiresAck: true,
      );

      final success = await _meshCore!.sendMessage(meshMessage);
      
      if (success) {
        // Also add to blockchain
        await BlockchainManager.instance.addChatMessage(
          message: message,
          senderAddress: _meshCore!.nodeId,
          recipientAddress: recipientId,
          replyToId: replyToId,
        );
        
        // Logging disabled;
      }
      
      return success;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Broadcast coordination message
  Future<bool> sendCoordinationMessage({
    required String emergencyId,
    required Map<String, dynamic> coordinationData,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final meshMessage = MeshMessage.create(
        type: MeshMessageType.coordination,
        sourceNodeId: _meshCore!.nodeId,
        destinationNodeId: 'broadcast',
        payload: {
          'type': 'coordination',
          'emergencyId': emergencyId,
          'coordinationData': coordinationData,
          'timestamp': DateTime.now().toIso8601String(),
          'coordinatorId': _meshCore!.nodeId,
        },
        priority: 2,
      );

      final success = await _meshCore!.sendMessage(meshMessage);
      
      if (success) {
        // Also add to blockchain
        await BlockchainManager.instance.coordinateResponse(
          emergencyId: emergencyId,
          coordinationData: coordinationData,
        );
        
        // Logging disabled;
      }
      
      return success;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Share blockchain data with peer
  Future<bool> shareBlockchainData({
    required String peerId,
    bool shareFullChain = false,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      Map<String, dynamic> blockchainData;
      
      if (shareFullChain) {
        blockchainData = BlockchainManager.instance.blockchain!.export();
      } else {
        // Share only recent blocks
        final recentBlocks = BlockchainManager.instance.blockchain!.chain
            .skip(BlockchainManager.instance.blockchain!.length - 10)
            .map((block) => block.toJson())
            .toList();
        
        blockchainData = {
          'recentBlocks': recentBlocks,
          'chainLength': BlockchainManager.instance.blockchain!.length,
          'latestHash': BlockchainManager.instance.blockchain!.latestBlock.hash,
        };
      }

      final meshMessage = MeshMessage.create(
        type: MeshMessageType.blockchain,
        sourceNodeId: _meshCore!.nodeId,
        destinationNodeId: peerId,
        payload: {
          'type': 'blockchain_data',
          'data': blockchainData,
          'fullChain': shareFullChain,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final success = await _meshCore!.sendMessage(meshMessage);
      
      if (success) {
        // Logging disabled;
      }
      
      return success;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Request blockchain sync from peer
  Future<bool> requestBlockchainSync(String peerId) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final currentStats = BlockchainManager.instance.getStatistics();
      
      final meshMessage = MeshMessage.create(
        type: MeshMessageType.blockchain,
        sourceNodeId: _meshCore!.nodeId,
        destinationNodeId: peerId,
        payload: {
          'type': 'blockchain_sync_request',
          'currentChainLength': currentStats['blockCount'],
          'currentLatestHash': currentStats['latestBlockHash'],
          'timestamp': DateTime.now().toIso8601String(),
        },
        requiresAck: true,
      );

      final success = await _meshCore!.sendMessage(meshMessage);
      
      if (success) {
        // Logging disabled;
      }
      
      return success;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Discover peers in emergency scenarios
  Future<bool> emergencyPeerDiscovery() async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final discoveryMessage = MeshMessage.create(
        type: MeshMessageType.discovery,
        sourceNodeId: _meshCore!.nodeId,
        destinationNodeId: 'broadcast',
        payload: {
          'type': 'emergency_discovery',
          'nodeId': _meshCore!.nodeId,
          'capabilities': {
            'emergency_response': true,
            'medical_support': false,
            'technical_support': true,
            'coordination': true,
          },
          'resources': {
            'battery_level': 0.8,
            'network_strength': 0.9,
            'storage_available': true,
          },
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: 1,
      );

      final success = await _meshCore!.sendMessage(discoveryMessage);
      
      if (success) {
        // Logging disabled;
      }
      
      return success;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Update trust score for a peer
  Future<bool> updatePeerTrustScore({
    required String peerId,
    required double scoreChange,
    required String reason,
  }) async {
    try {
      // Update in blockchain
      await BlockchainManager.instance.updateTrustScore(
        peerAddress: peerId,
        scoreChange: scoreChange,
        reason: reason,
      );
      
      // Logging disabled;
      return true;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    if (!isInitialized) {
      return {'initialized': false};
    }

    final meshStats = _meshCore!.getNetworkStatistics();
    final blockchainStats = BlockchainManager.instance.getStatistics();

    return {
      'initialized': true,
      'mesh': meshStats,
      'blockchain': blockchainStats,
      'emergency_alerts_sent': _getEmergencyAlertCount(),
      'chat_messages_sent': _getChatMessageCount(),
      'coordination_messages_sent': _getCoordinationMessageCount(),
    };
  }

  /// Set up message listeners
  void _setupMessageListeners() {
    _messageSubscription = _meshCore!.messageStream.listen((message) async {
      await _handleIncomingMessage(message);
    });

    _nodeSubscription = _meshCore!.nodeStream.listen((node) {
      _peerController.add(node);
      // Logging disabled;
    });
  }

  /// Handle incoming mesh message
  Future<void> _handleIncomingMessage(MeshMessage message) async {
    try {
      switch (message.type) {
        case MeshMessageType.emergency:
          await _handleEmergencyMessage(message);
          break;
        case MeshMessageType.data:
          await _handleDataMessage(message);
          break;
        case MeshMessageType.coordination:
          await _handleCoordinationMessage(message);
          break;
        case MeshMessageType.blockchain:
          await _handleBlockchainMessage(message);
          break;
        case MeshMessageType.discovery:
          await _handleDiscoveryMessage(message);
          break;
        default:
          // Logging disabled;
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  /// Handle emergency message
  Future<void> _handleEmergencyMessage(MeshMessage message) async {
    final payload = message.payload;
    
    _emergencyController.add({
      'id': message.messageId,
      'type': 'emergency_alert',
      'message': payload['message'],
      'location': payload['location'],
      'priority': payload['priority'],
      'timestamp': DateTime.parse(payload['timestamp']),
      'senderId': payload['senderId'],
      'alertId': payload['alertId'],
    });
    
    // Update trust score for emergency reporter
    await updatePeerTrustScore(
      peerId: message.sourceNodeId,
      scoreChange: 1.0,
      reason: 'emergency_report',
    );
    
    // Logging disabled;
  }

  /// Handle data message (chat)
  Future<void> _handleDataMessage(MeshMessage message) async {
    final payload = message.payload;
    
    if (payload['type'] == 'chat_message') {
      _chatController.add({
        'id': payload['messageId'],
        'message': payload['message'],
        'timestamp': DateTime.parse(payload['timestamp']),
        'senderId': payload['senderId'],
        'replyToId': payload['replyToId'],
      });
      
      // Logging disabled;
    }
  }

  /// Handle coordination message
  Future<void> _handleCoordinationMessage(MeshMessage message) async {
    final payload = message.payload;
    
    _emergencyController.add({
      'id': message.messageId,
      'type': 'coordination',
      'emergencyId': payload['emergencyId'],
      'coordinationData': payload['coordinationData'],
      'timestamp': DateTime.parse(payload['timestamp']),
      'coordinatorId': payload['coordinatorId'],
    });
    
    // Logging disabled;
  }

  /// Handle blockchain message
  Future<void> _handleBlockchainMessage(MeshMessage message) async {
    final payload = message.payload;
    
    if (payload['type'] == 'blockchain_sync_request') {
      // Send blockchain data in response
      await shareBlockchainData(peerId: message.sourceNodeId, shareFullChain: true);
    } else if (payload['type'] == 'blockchain_data') {
      // Process received blockchain data
      if (payload['fullChain'] == true) {
        final success = BlockchainManager.instance.blockchain!.import(payload['data']);
        if (success) {
          // Logging disabled;
        }
      } else {
        // Logging disabled;
      }
    }
  }

  /// Handle discovery message
  Future<void> _handleDiscoveryMessage(MeshMessage message) async {
    final payload = message.payload;
    
    if (payload['type'] == 'emergency_discovery') {
      // Add peer discovery to blockchain
      await BlockchainManager.instance.addPeerDiscovery(
        peerAddress: payload['nodeId'],
        peerInfo: {
          'capabilities': payload['capabilities'],
          'resources': payload['resources'],
          'discoveredAt': payload['timestamp'],
        },
      );
    }
    
    // Logging disabled;
  }

  /// Generate alert ID
  String _generateAlertId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${_meshCore!.nodeId.substring(0, 8)}';
  }

  /// Generate message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_meshCore!.nodeId.substring(0, 8)}';
  }

  /// Get emergency alert count from blockchain
  int _getEmergencyAlertCount() {
    final messages = BlockchainManager.instance.getEmergencyMessages();
    return messages.length;
  }

  /// Get chat message count from blockchain
  int _getChatMessageCount() {
    if (!BlockchainManager.instance.isInitialized) return 0;
    
    final transactions = BlockchainManager.instance.blockchain!
        .getTransactionsForAddress(_meshCore!.nodeId);
    
    return transactions.where((tx) => tx.type == TransactionType.message).length;
  }

  /// Get coordination message count
  int _getCoordinationMessageCount() {
    if (!BlockchainManager.instance.isInitialized) return 0;
    
    final transactions = BlockchainManager.instance.blockchain!
        .getTransactionsForAddress(_meshCore!.nodeId);
    
    return transactions.where((tx) => tx.type == TransactionType.coordination).length;
  }
}
