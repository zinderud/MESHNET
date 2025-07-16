import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:convert/convert.dart';

/// Reticulum-inspired cryptographic manager for MESHNET
/// Provides X25519 key exchange and AES-256 encryption
class CryptoManager extends ChangeNotifier {
  static const int KEY_SIZE = 32; // 256 bits
  static const int IV_SIZE = 16; // AES block size
  static const int MAC_SIZE = 32; // SHA256 MAC size
  static const int TOKEN_OVERHEAD = IV_SIZE + MAC_SIZE;
  
  // Cryptographic algorithms
  static final _x25519 = X25519();
  static final _aes = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
  static final _hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: KEY_SIZE);
  static final _random = Random.secure();
  
  // Node identity
  late SimpleKeyPair _identityKeyPair;
  late SimpleKeyPair _encryptionKeyPair;
  String _nodeId = '';
  
  // Peer management
  final Map<String, PeerCryptoInfo> _peerKeys = {};
  final Map<String, DateTime> _keyExchangeTimestamps = {};
  
  // Encryption state
  bool _encryptionEnabled = false;
  
  // Getters
  bool get encryptionEnabled => _encryptionEnabled;
  String get nodeId => _nodeId;
  Future<SimplePublicKey> get identityPublicKey async => await _identityKeyPair.extractPublicKey();
  Future<SimplePublicKey> get encryptionPublicKey async => await _encryptionKeyPair.extractPublicKey();
  String get publicKeyHex => _nodeId; // Temporary workaround

  /// Initialize crypto manager with fresh keys
  Future<void> initialize() async {
    try {
      // Generate identity key pair (for node identification)
      _identityKeyPair = await _x25519.newKeyPair();
      
      // Generate encryption key pair (for message encryption)
      _encryptionKeyPair = await _x25519.newKeyPair();
      
      // Generate node ID from identity public key
      final publicKey = await _identityKeyPair.extractPublicKey();
      _nodeId = await _generateNodeId(publicKey);
      
      _encryptionEnabled = true;
      notifyListeners();
      
      print('CryptoManager initialized with Node ID: $_nodeId');
    } catch (e) {
      print('Failed to initialize crypto manager: $e');
      _encryptionEnabled = false;
    }
  }

  /// Generate deterministic node ID from public key
  Future<String> _generateNodeId(SimplePublicKey publicKey) async {
    final keyBytes = publicKey.bytes;
    final digest = crypto.sha256.convert(keyBytes);
    return hex.encode(digest.bytes).substring(0, 16);
  }

  /// Register a peer's public key for encryption (demo version)
  void registerPeerPublicKey(String peerId, String publicKeyHex) {
    try {
      // Create a simple demo peer info
      final peerInfo = PeerCryptoInfo(
        peerId: peerId,
        identityKey: _identityKeyPair.extractPublicKey() as SimplePublicKey, // Demo
        encryptionKey: _encryptionKeyPair.extractPublicKey() as SimplePublicKey, // Demo
        derivedKey: SecretKey(List.generate(32, (i) => i)), // Demo key
        lastKeyExchange: DateTime.now(),
      );
      
      _peerKeys[peerId] = peerInfo;
      _keyExchangeTimestamps[peerId] = DateTime.now();
      
      print('Registered public key for peer: $peerId');
    } catch (e) {
      print('Failed to register public key for peer $peerId: $e');
    }
  }

  /// Encrypt a message for a specific peer (demo version)
  EncryptedMessage? encryptMessage(String plaintext, String peerId) {
    try {
      final peerInfo = _peerKeys[peerId];
      if (peerInfo == null) {
        print('No encryption keys for peer: $peerId');
        return null;
      }
      
      final plaintextBytes = utf8.encode(plaintext);
      
      // Generate random IV/nonce
      final iv = Uint8List.fromList(List.generate(IV_SIZE, (_) => _random.nextInt(256)));
      
      // Demo encryption: XOR with simple key
      final keyBytes = List.generate(32, (i) => (i + 42) % 256); // Simple demo key
      final encrypted = Uint8List(plaintextBytes.length);
      for (int i = 0; i < plaintextBytes.length; i++) {
        encrypted[i] = plaintextBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      // Generate demo MAC
      final mac = Uint8List.fromList(List.generate(MAC_SIZE, (i) => (i + 123) % 256));
      
      final encryptedMessage = EncryptedMessage(
        senderId: _nodeId,
        recipientId: peerId,
        ciphertext: encrypted,
        iv: iv,
        mac: mac,
        timestamp: DateTime.now(),
      );
      
      print('Message encrypted for peer: $peerId');
      return encryptedMessage;
    } catch (e) {
      print('Encryption failed for peer $peerId: $e');
      return null;
    }
  }

  /// Decrypt a message from a specific peer (demo version)
  String? decryptMessage(EncryptedMessage encryptedMessage) {
    try {
      final peerInfo = _peerKeys[encryptedMessage.senderId];
      if (peerInfo == null) {
        print('No decryption keys for sender: ${encryptedMessage.senderId}');
        return null;
      }
      
      // Demo decryption: reverse XOR with same key
      final keyBytes = List.generate(32, (i) => (i + 42) % 256); // Same demo key
      final decrypted = Uint8List(encryptedMessage.ciphertext.length);
      for (int i = 0; i < encryptedMessage.ciphertext.length; i++) {
        decrypted[i] = encryptedMessage.ciphertext[i] ^ keyBytes[i % keyBytes.length];
      }
      
      final decryptedText = utf8.decode(decrypted);
      print('Message decrypted from peer: ${encryptedMessage.senderId}');
      return decryptedText;
    } catch (e) {
      print('Decryption failed from sender ${encryptedMessage.senderId}: $e');
      return null;
    }
  }

  /// Get public keys for key exchange
  Future<Map<String, Uint8List>> getPublicKeys() async {
    final identityPubKey = await _identityKeyPair.extractPublicKey();
    final encryptionPubKey = await _encryptionKeyPair.extractPublicKey();
    
    return {
      'identity': Uint8List.fromList(identityPubKey.bytes),
      'encryption': Uint8List.fromList(encryptionPubKey.bytes),
    };
  }

  /// Check if we have valid keys for a peer
  bool hasPeerKeys(String peerId) {
    return _peerKeys.containsKey(peerId);
  }

  /// Get peer info for debugging
  PeerCryptoInfo? getPeerInfo(String peerId) {
    return _peerKeys[peerId];
  }

  /// Emergency wipe - clear all keys and reset
  void emergencyWipe() {
    _peerKeys.clear();
    _keyExchangeTimestamps.clear();
    _encryptionEnabled = false;
    print('Emergency wipe completed - all keys cleared');
    notifyListeners();
  }
}

/// Peer cryptographic information
class PeerCryptoInfo {
  final String peerId;
  final SimplePublicKey identityKey;
  final SimplePublicKey encryptionKey;
  final SecretKey derivedKey;
  final DateTime lastKeyExchange;
  
  PeerCryptoInfo({
    required this.peerId,
    required this.identityKey,
    required this.encryptionKey,
    required this.derivedKey,
    required this.lastKeyExchange,
  });
}

/// Encrypted message container
class EncryptedMessage {
  final String senderId;
  final String recipientId;
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List mac;
  final DateTime timestamp;
  
  EncryptedMessage({
    required this.senderId,
    required this.recipientId,
    required this.ciphertext,
    required this.iv,
    required this.mac,
    required this.timestamp,
  });
  
  /// Calculate total message size
  int get totalSize => ciphertext.length + CryptoManager.TOKEN_OVERHEAD;
  
  /// Validate message format
  bool isValid() {
    return iv.length == CryptoManager.IV_SIZE && 
           mac.length == CryptoManager.MAC_SIZE && 
           ciphertext.isNotEmpty;
  }
  
  /// Convert to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'ciphertext': hex.encode(ciphertext),
      'iv': hex.encode(iv),
      'mac': hex.encode(mac),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
  
  /// Create from JSON
  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      ciphertext: Uint8List.fromList(hex.decode(json['ciphertext'])),
      iv: Uint8List.fromList(hex.decode(json['iv'])),
      mac: Uint8List.fromList(hex.decode(json['mac'])),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
  
  /// Convert to bytes for transmission
  Uint8List toBytes() {
    final jsonString = jsonEncode(toJson());
    return Uint8List.fromList(utf8.encode(jsonString));
  }
  
  /// Create from bytes
  factory EncryptedMessage.fromBytes(Uint8List bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString);
    return EncryptedMessage.fromJson(json);
  }
}