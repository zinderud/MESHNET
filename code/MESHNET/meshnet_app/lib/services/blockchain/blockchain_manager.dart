// lib/services/blockchain/blockchain_manager.dart - Blockchain Manager Service
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:meshnet_app/services/blockchain/blockchain_core.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Blockchain manager for emergency mesh network operations
class BlockchainManager {
  static BlockchainManager? _instance;
  static BlockchainManager get instance => _instance ??= BlockchainManager._internal();
  
  BlockchainManager._internal();

  final Logger _logger = Logger('BlockchainManager');
  Blockchain? _blockchain;
  Timer? _miningTimer;
  Timer? _syncTimer;
  String? _nodePublicKey;
  
  // Blockchain configuration
  static const Duration _miningInterval = Duration(seconds: 30);
  static const Duration _syncInterval = Duration(minutes: 5);
  static const int _maxPendingTransactions = 100;

  bool get isInitialized => _blockchain != null;
  Blockchain? get blockchain => _blockchain;
  String? get nodePublicKey => _nodePublicKey;

  /// Initialize blockchain with node identity
  Future<bool> initialize() async {
    try {
      // Logging disabled;
      
      // Generate or load node public key
      _nodePublicKey = await _getOrCreateNodePublicKey();
      
      // Initialize blockchain
      _blockchain = Blockchain(nodePublicKey: _nodePublicKey!);
      
      // Try to load existing blockchain
      await _loadBlockchain();
      
      // Start background services
      _startMiningTimer();
      _startSyncTimer();
      
      // Logging disabled;
      return true;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Shutdown blockchain manager
  Future<void> shutdown() async {
    // Logging disabled;
    
    _miningTimer?.cancel();
    _syncTimer?.cancel();
    
    if (_blockchain != null) {
      await _saveBlockchain();
    }
    
    _blockchain = null;
    _nodePublicKey = null;
    
    // Logging disabled;
  }

  /// Add emergency message transaction
  Future<bool> addEmergencyMessage({
    required String message,
    required String senderAddress,
    required Map<String, dynamic> location,
    int priority = 1,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final transaction = Transaction.create(
        type: TransactionType.emergency,
        fromAddress: senderAddress,
        toAddress: 'broadcast',
        data: {
          'message': message,
          'location': location,
          'priority': priority,
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'emergency_alert',
        },
      );

      return _blockchain!.addTransaction(transaction);
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Add chat message transaction
  Future<bool> addChatMessage({
    required String message,
    required String senderAddress,
    required String recipientAddress,
    String? replyToId,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final transaction = Transaction.create(
        type: TransactionType.message,
        fromAddress: senderAddress,
        toAddress: recipientAddress,
        data: {
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'replyToId': replyToId,
          'type': 'chat_message',
        },
      );

      return _blockchain!.addTransaction(transaction);
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Add peer discovery transaction
  Future<bool> addPeerDiscovery({
    required String peerAddress,
    required Map<String, dynamic> peerInfo,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final transaction = Transaction.create(
        type: TransactionType.peerDiscovery,
        fromAddress: _nodePublicKey!,
        toAddress: 'network',
        data: {
          'peerAddress': peerAddress,
          'peerInfo': peerInfo,
          'timestamp': DateTime.now().toIso8601String(),
          'discoveredBy': _nodePublicKey,
        },
      );

      return _blockchain!.addTransaction(transaction);
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Update trust score for a peer
  Future<bool> updateTrustScore({
    required String peerAddress,
    required double scoreChange,
    required String reason,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final transaction = Transaction.create(
        type: TransactionType.trustScore,
        fromAddress: _nodePublicKey!,
        toAddress: peerAddress,
        data: {
          'scoreChange': scoreChange,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
          'evaluatedBy': _nodePublicKey,
        },
      );

      return _blockchain!.addTransaction(transaction);
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Share resources with network
  Future<bool> shareResource({
    required String resourceType,
    required Map<String, dynamic> resourceData,
    required String recipientAddress,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final transaction = Transaction.create(
        type: TransactionType.resourceShare,
        fromAddress: _nodePublicKey!,
        toAddress: recipientAddress,
        data: {
          'resourceType': resourceType,
          'resourceData': resourceData,
          'timestamp': DateTime.now().toIso8601String(),
          'sharedBy': _nodePublicKey,
        },
      );

      return _blockchain!.addTransaction(transaction);
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Coordinate emergency response
  Future<bool> coordinateResponse({
    required String emergencyId,
    required Map<String, dynamic> coordinationData,
  }) async {
    if (!isInitialized) {
      // Logging disabled;
      return false;
    }

    try {
      final transaction = Transaction.create(
        type: TransactionType.coordination,
        fromAddress: _nodePublicKey!,
        toAddress: 'emergency_network',
        data: {
          'emergencyId': emergencyId,
          'coordinationData': coordinationData,
          'timestamp': DateTime.now().toIso8601String(),
          'coordinator': _nodePublicKey,
        },
      );

      return _blockchain!.addTransaction(transaction);
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Get emergency messages from blockchain
  List<Map<String, dynamic>> getEmergencyMessages({int? limit}) {
    if (!isInitialized) return [];

    final emergencyMessages = <Map<String, dynamic>>[];

    for (final block in _blockchain!.chain.reversed) {
      for (final transaction in block.transactions.reversed) {
        if (transaction.type == TransactionType.emergency) {
          emergencyMessages.add({
            'id': transaction.id,
            'message': transaction.data['message'],
            'location': transaction.data['location'],
            'priority': transaction.data['priority'],
            'timestamp': transaction.timestamp,
            'senderAddress': transaction.fromAddress,
            'blockIndex': block.index,
          });
          
          if (limit != null && emergencyMessages.length >= limit) {
            return emergencyMessages;
          }
        }
      }
    }

    return emergencyMessages;
  }

  /// Get chat messages between two addresses
  List<Map<String, dynamic>> getChatMessages({
    required String address1,
    required String address2,
    int? limit,
  }) {
    if (!isInitialized) return [];

    final chatMessages = <Map<String, dynamic>>[];

    for (final block in _blockchain!.chain.reversed) {
      for (final transaction in block.transactions.reversed) {
        if (transaction.type == TransactionType.message) {
          final isRelevant = (transaction.fromAddress == address1 && transaction.toAddress == address2) ||
                            (transaction.fromAddress == address2 && transaction.toAddress == address1);
          
          if (isRelevant) {
            chatMessages.add({
              'id': transaction.id,
              'message': transaction.data['message'],
              'timestamp': transaction.timestamp,
              'senderAddress': transaction.fromAddress,
              'recipientAddress': transaction.toAddress,
              'replyToId': transaction.data['replyToId'],
              'blockIndex': block.index,
            });
            
            if (limit != null && chatMessages.length >= limit) {
              return chatMessages;
            }
          }
        }
      }
    }

    return chatMessages;
  }

  /// Get trust score for a peer
  double getTrustScore(String peerAddress) {
    if (!isInitialized) return 0.0;

    double trustScore = 0.0;

    for (final block in _blockchain!.chain) {
      for (final transaction in block.transactions) {
        if (transaction.type == TransactionType.trustScore && 
            transaction.toAddress == peerAddress) {
          trustScore += transaction.data['scoreChange']?.toDouble() ?? 0.0;
        }
      }
    }

    return trustScore;
  }

  /// Get blockchain statistics
  Map<String, dynamic> getStatistics() {
    if (!isInitialized) {
      return {
        'initialized': false,
      };
    }

    final transactionCounts = <TransactionType, int>{};
    int totalTransactions = 0;

    for (final block in _blockchain!.chain) {
      for (final transaction in block.transactions) {
        transactionCounts[transaction.type] = 
            (transactionCounts[transaction.type] ?? 0) + 1;
        totalTransactions++;
      }
    }

    return {
      'initialized': true,
      'blockCount': _blockchain!.length,
      'totalTransactions': totalTransactions,
      'pendingTransactions': _blockchain!.pendingTransactions.length,
      'transactionsByType': transactionCounts.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'nodeBalance': _blockchain!.getBalance(_nodePublicKey!),
      'isChainValid': _blockchain!.isChainValid(),
      'latestBlockHash': _blockchain!.latestBlock.hash,
      'nodePublicKey': _nodePublicKey,
    };
  }

  /// Force mine pending transactions
  Future<bool> forceMine() async {
    if (!isInitialized) return false;

    try {
      final block = _blockchain!.minePendingTransactions();
      if (block != null) {
        await _saveBlockchain();
        // Logging disabled;
        return true;
      }
      return false;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Get or create node public key
  Future<String> _getOrCreateNodePublicKey() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/node_key.txt');
      
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        // Generate new node key
        final random = Random.secure();
        final bytes = List<int>.generate(32, (i) => random.nextInt(256));
        final nodeKey = base64.encode(bytes);
        
        await file.writeAsString(nodeKey);
        // Logging disabled;
        return nodeKey;
      }
    } catch (e) {
      // Logging disabled;
      // Fallback to random key
      final random = Random.secure();
      final bytes = List<int>.generate(32, (i) => random.nextInt(256));
      return base64.encode(bytes);
    }
  }

  /// Load blockchain from storage
  Future<void> _loadBlockchain() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/blockchain.json');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        
        if (_blockchain!.import(data)) {
          // Logging disabled;
        } else {
          // Logging disabled;
        }
      } else {
        // Logging disabled;
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  /// Save blockchain to storage
  Future<void> _saveBlockchain() async {
    if (!isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/blockchain.json');
      
      final data = _blockchain!.export();
      await file.writeAsString(jsonEncode(data));
      
      // Logging disabled;
    } catch (e) {
      // Logging disabled;
    }
  }

  /// Start automatic mining timer
  void _startMiningTimer() {
    _miningTimer = Timer.periodic(_miningInterval, (timer) async {
      if (_blockchain!.pendingTransactions.isNotEmpty) {
        // Logging disabled;
        final block = _blockchain!.minePendingTransactions();
        if (block != null) {
          await _saveBlockchain();
        }
      }
    });
  }

  /// Start blockchain sync timer
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) async {
      // In a real implementation, this would sync with other nodes
      // For now, just validate and save
      if (_blockchain!.isChainValid()) {
        await _saveBlockchain();
      } else {
        // Logging disabled;
      }
    });
  }
}
