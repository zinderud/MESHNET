// lib/services/blockchain/blockchain_core.dart - Blockchain Core Infrastructure
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Blockchain transaction types for emergency mesh network
enum TransactionType {
  message,
  emergency,
  peerDiscovery,
  trustScore,
  resourceShare,
  coordination,
}

/// Digital signature algorithm types
enum SignatureAlgorithm {
  ed25519,
  secp256k1,
  rsa2048,
}

/// Block class representing a single block in the blockchain
class Block {
  final int index;
  final DateTime timestamp;
  final String previousHash;
  final String merkleRoot;
  final List<Transaction> transactions;
  final int nonce;
  final String hash;
  final String minerPublicKey;
  final Uint8List minerSignature;

  Block({
    required this.index,
    required this.timestamp,
    required this.previousHash,
    required this.merkleRoot,
    required this.transactions,
    required this.nonce,
    required this.hash,
    required this.minerPublicKey,
    required this.minerSignature,
  });

  /// Create a new block from transactions
  factory Block.create({
    required int index,
    required String previousHash,
    required List<Transaction> transactions,
    required String minerPublicKey,
  }) {
    final timestamp = DateTime.now();
    final merkleRoot = _calculateMerkleRoot(transactions);
    
    // Simple proof-of-work (difficulty = 2 for emergency scenarios)
    int nonce = 0;
    String hash;
    do {
      nonce++;
      hash = _calculateHash(index, timestamp, previousHash, merkleRoot, nonce);
    } while (!hash.startsWith('00')); // Difficulty: 2 leading zeros
    
    // Create signature (simplified - in real implementation use proper crypto)
    final blockData = '$index$timestamp$previousHash$merkleRoot$nonce$hash';
    final signature = Uint8List.fromList(sha256.convert(utf8.encode(blockData)).bytes);
    
    return Block(
      index: index,
      timestamp: timestamp,
      previousHash: previousHash,
      merkleRoot: merkleRoot,
      transactions: transactions,
      nonce: nonce,
      hash: hash,
      minerPublicKey: minerPublicKey,
      minerSignature: signature,
    );
  }

  /// Verify block integrity
  bool verify() {
    // Verify hash
    final expectedHash = _calculateHash(index, timestamp, previousHash, merkleRoot, nonce);
    if (expectedHash != hash) return false;
    
    // Verify proof of work
    if (!hash.startsWith('00')) return false;
    
    // Verify merkle root
    final expectedMerkleRoot = _calculateMerkleRoot(transactions);
    if (expectedMerkleRoot != merkleRoot) return false;
    
    // Verify all transactions
    for (final transaction in transactions) {
      if (!transaction.verify()) return false;
    }
    
    return true;
  }

  static String _calculateHash(int index, DateTime timestamp, String previousHash, String merkleRoot, int nonce) {
    final data = '$index${timestamp.millisecondsSinceEpoch}$previousHash$merkleRoot$nonce';
    return sha256.convert(utf8.encode(data)).toString();
  }

  static String _calculateMerkleRoot(List<Transaction> transactions) {
    if (transactions.isEmpty) return '';
    
    List<String> hashes = transactions.map((t) => t.hash).toList();
    
    while (hashes.length > 1) {
      final newHashes = <String>[];
      for (int i = 0; i < hashes.length; i += 2) {
        final left = hashes[i];
        final right = i + 1 < hashes.length ? hashes[i + 1] : left;
        final combined = sha256.convert(utf8.encode(left + right)).toString();
        newHashes.add(combined);
      }
      hashes = newHashes;
    }
    
    return hashes.first;
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'timestamp': timestamp.toIso8601String(),
      'previousHash': previousHash,
      'merkleRoot': merkleRoot,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'nonce': nonce,
      'hash': hash,
      'minerPublicKey': minerPublicKey,
      'minerSignature': base64.encode(minerSignature),
    };
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      index: json['index'],
      timestamp: DateTime.parse(json['timestamp']),
      previousHash: json['previousHash'],
      merkleRoot: json['merkleRoot'],
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
      nonce: json['nonce'],
      hash: json['hash'],
      minerPublicKey: json['minerPublicKey'],
      minerSignature: base64.decode(json['minerSignature']),
    );
  }
}

/// Transaction class for blockchain operations
class Transaction {
  final String id;
  final TransactionType type;
  final String fromAddress;
  final String toAddress;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final double fee;
  final String hash;
  final Uint8List signature;
  final SignatureAlgorithm signatureAlgorithm;

  Transaction({
    required this.id,
    required this.type,
    required this.fromAddress,
    required this.toAddress,
    required this.data,
    required this.timestamp,
    required this.fee,
    required this.hash,
    required this.signature,
    required this.signatureAlgorithm,
  });

  /// Create a new transaction
  factory Transaction.create({
    required TransactionType type,
    required String fromAddress,
    required String toAddress,
    required Map<String, dynamic> data,
    double fee = 0.0,
    SignatureAlgorithm signatureAlgorithm = SignatureAlgorithm.ed25519,
  }) {
    final id = _generateTransactionId();
    final timestamp = DateTime.now();
    final hash = _calculateTransactionHash(id, type, fromAddress, toAddress, data, timestamp, fee);
    
    // Create signature (simplified - in real implementation use proper crypto)
    final transactionData = '$id${type.toString()}$fromAddress$toAddress${jsonEncode(data)}$timestamp$fee';
    final signature = Uint8List.fromList(sha256.convert(utf8.encode(transactionData)).bytes);
    
    return Transaction(
      id: id,
      type: type,
      fromAddress: fromAddress,
      toAddress: toAddress,
      data: data,
      timestamp: timestamp,
      fee: fee,
      hash: hash,
      signature: signature,
      signatureAlgorithm: signatureAlgorithm,
    );
  }

  /// Verify transaction signature and integrity
  bool verify() {
    // Verify hash
    final expectedHash = _calculateTransactionHash(id, type, fromAddress, toAddress, data, timestamp, fee);
    if (expectedHash != hash) return false;
    
    // In real implementation, verify signature with public key cryptography
    // For now, just check signature exists
    return signature.isNotEmpty;
  }

  static String _generateTransactionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  static String _calculateTransactionHash(
    String id,
    TransactionType type,
    String fromAddress,
    String toAddress,
    Map<String, dynamic> data,
    DateTime timestamp,
    double fee,
  ) {
    final transactionData = '$id${type.toString()}$fromAddress$toAddress${jsonEncode(data)}${timestamp.millisecondsSinceEpoch}$fee';
    return sha256.convert(utf8.encode(transactionData)).toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'fee': fee,
      'hash': hash,
      'signature': base64.encode(signature),
      'signatureAlgorithm': signatureAlgorithm.toString(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      fromAddress: json['fromAddress'],
      toAddress: json['toAddress'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      fee: json['fee']?.toDouble() ?? 0.0,
      hash: json['hash'],
      signature: base64.decode(json['signature']),
      signatureAlgorithm: SignatureAlgorithm.values.firstWhere(
        (e) => e.toString() == json['signatureAlgorithm'],
        orElse: () => SignatureAlgorithm.ed25519,
      ),
    );
  }
}

/// Blockchain class managing the entire chain
class Blockchain {
  final Logger _logger = Logger('Blockchain');
  final List<Block> _chain = [];
  final List<Transaction> _pendingTransactions = [];
  final double _miningReward = 1.0;
  final String _nodePublicKey;

  Blockchain({required String nodePublicKey}) : _nodePublicKey = nodePublicKey {
    _createGenesisBlock();
  }

  List<Block> get chain => List.unmodifiable(_chain);
  List<Transaction> get pendingTransactions => List.unmodifiable(_pendingTransactions);
  int get length => _chain.length;
  Block get latestBlock => _chain.last;

  /// Create the genesis block
  void _createGenesisBlock() {
    final genesisTransaction = Transaction.create(
      type: TransactionType.message,
      fromAddress: 'genesis',
      toAddress: 'genesis',
      data: {
        'message': 'Emergency Mesh Network Genesis Block',
        'network_id': 'meshnet_emergency',
        'version': '1.0.0',
      },
    );

    final genesisBlock = Block.create(
      index: 0,
      previousHash: '0',
      transactions: [genesisTransaction],
      minerPublicKey: _nodePublicKey,
    );

    _chain.add(genesisBlock);
    _logger.info('Genesis block created: ${genesisBlock.hash}');
  }

  /// Add a new transaction to pending pool
  bool addTransaction(Transaction transaction) {
    if (!transaction.verify()) {
      _logger.warning('Invalid transaction rejected: ${transaction.id}');
      return false;
    }

    _pendingTransactions.add(transaction);
    _logger.info('Transaction added to pool: ${transaction.id}');
    return true;
  }

  /// Mine pending transactions into a new block
  Block? minePendingTransactions() {
    if (_pendingTransactions.isEmpty) {
      _logger.info('No pending transactions to mine');
      return null;
    }

    // Add mining reward transaction
    final rewardTransaction = Transaction.create(
      type: TransactionType.resourceShare,
      fromAddress: 'network',
      toAddress: _nodePublicKey,
      data: {
        'reward': _miningReward,
        'reason': 'block_mining',
      },
    );

    final transactionsToMine = [..._pendingTransactions, rewardTransaction];
    
    final newBlock = Block.create(
      index: _chain.length,
      previousHash: latestBlock.hash,
      transactions: transactionsToMine,
      minerPublicKey: _nodePublicKey,
    );

    if (newBlock.verify()) {
      _chain.add(newBlock);
      _pendingTransactions.clear();
      _logger.info('Block mined successfully: ${newBlock.hash}');
      return newBlock;
    } else {
      _logger.severe('Failed to verify mined block');
      return null;
    }
  }

  /// Validate the entire blockchain
  bool isChainValid() {
    for (int i = 1; i < _chain.length; i++) {
      final currentBlock = _chain[i];
      final previousBlock = _chain[i - 1];

      // Verify current block
      if (!currentBlock.verify()) {
        _logger.severe('Invalid block at index $i: ${currentBlock.hash}');
        return false;
      }

      // Verify chain linkage
      if (currentBlock.previousHash != previousBlock.hash) {
        _logger.severe('Chain broken at index $i');
        return false;
      }
    }

    _logger.info('Blockchain validation successful');
    return true;
  }

  /// Get balance for an address
  double getBalance(String address) {
    double balance = 0.0;

    for (final block in _chain) {
      for (final transaction in block.transactions) {
        if (transaction.fromAddress == address) {
          balance -= transaction.fee;
          if (transaction.type == TransactionType.resourceShare &&
              transaction.data['amount'] != null) {
            balance -= transaction.data['amount'].toDouble();
          }
        }
        if (transaction.toAddress == address) {
          if (transaction.type == TransactionType.resourceShare) {
            if (transaction.data['reward'] != null) {
              balance += transaction.data['reward'].toDouble();
            }
            if (transaction.data['amount'] != null) {
              balance += transaction.data['amount'].toDouble();
            }
          }
        }
      }
    }

    return balance;
  }

  /// Get all transactions for an address
  List<Transaction> getTransactionsForAddress(String address) {
    final transactions = <Transaction>[];

    for (final block in _chain) {
      for (final transaction in block.transactions) {
        if (transaction.fromAddress == address || transaction.toAddress == address) {
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  /// Export blockchain data
  Map<String, dynamic> export() {
    return {
      'chain': _chain.map((block) => block.toJson()).toList(),
      'pendingTransactions': _pendingTransactions.map((tx) => tx.toJson()).toList(),
      'nodePublicKey': _nodePublicKey,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Import blockchain data
  bool import(Map<String, dynamic> data) {
    try {
      final chainData = data['chain'] as List;
      final pendingData = data['pendingTransactions'] as List;

      final importedChain = chainData.map((blockJson) => Block.fromJson(blockJson)).toList();
      final importedPending = pendingData.map((txJson) => Transaction.fromJson(txJson)).toList();

      // Validate imported chain
      final tempBlockchain = Blockchain(nodePublicKey: _nodePublicKey);
      tempBlockchain._chain.clear();
      tempBlockchain._chain.addAll(importedChain);

      if (!tempBlockchain.isChainValid()) {
        _logger.severe('Imported blockchain is invalid');
        return false;
      }

      // Replace current chain
      _chain.clear();
      _chain.addAll(importedChain);
      _pendingTransactions.clear();
      _pendingTransactions.addAll(importedPending);

      _logger.info('Blockchain imported successfully');
      return true;
    } catch (e) {
      _logger.severe('Failed to import blockchain', e);
      return false;
    }
  }
}
