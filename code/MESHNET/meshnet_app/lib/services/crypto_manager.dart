// lib/services/crypto_manager.dart
// Reticulum-style cryptography implementation
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class CryptoManager extends ChangeNotifier {
  // Reticulum token constants
  static const int TOKEN_OVERHEAD = 48; // bytes
  static const int IV_SIZE = 16; // bytes
  static const int MAC_SIZE = 32; // bytes
  
  // Algorithms - Reticulum standardında
  final _x25519 = X25519();
  final _aes = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
  final _hkdf = Hkdf(hmac: Hmac(Sha256()));
  
  // Peer public keys storage
  final Map<String, Map<String, Uint8List>> _peerPublicKeys = {};
  
  // Add peer's public key - Reticulum peer management
  void addPeerPublicKey(String peerId, Map<String, Uint8List> publicKeys) {
    _peerPublicKeys[peerId] = publicKeys;
    debugPrint('Added public keys for peer: $peerId');
    notifyListeners();
  }
  
  // Encrypt data for destination identity (Reticulum token format)
  Future<ReticulumToken?> encrypt(
    String plaintext, 
    String peerId,
    SimpleKeyPair senderKeyPair,
  ) async {
    final peerKeys = _peerPublicKeys[peerId];
    if (peerKeys == null) {
      debugPrint('No public keys found for peer: $peerId');
      return null;
    }
    
    try {
      // Recreate destination's encryption public key
      final destEncKey = SimplePublicKey(
        peerKeys['encryption']!,
        type: KeyPairType.x25519,
      );
      
      // ECDH key exchange
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: senderKeyPair,
        remotePublicKey: destEncKey,
      );
      
      // HKDF key derivation (Reticulum standard)
      final derivedKey = await _hkdf.deriveKey(
        secretKey: sharedSecret,
        info: utf8.encode('encryption'),
        outputLength: 32, // 256-bit
      );
      
      // Generate random IV
      final random = Random.secure();
      final iv = Uint8List.fromList(
        List.generate(IV_SIZE, (_) => random.nextInt(256))
      );
      
      // Convert plaintext to bytes
      final plaintextBytes = utf8.encode(plaintext);
      
      // AES-256-CBC encryption (Reticulum format)
      final secretBox = await _aes.encrypt(
        plaintextBytes,
        secretKey: derivedKey,
        nonce: iv,
      );
      
      return ReticulumToken(
        ciphertext: Uint8List.fromList(secretBox.cipherText),
        iv: iv,
        mac: Uint8List.fromList(secretBox.mac.bytes),
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('Encryption error: $e');
      return null;
    }
  }
  
  // Decrypt Reticulum token
  Future<String?> decrypt(
    ReticulumToken token,
    String senderId,
    SimpleKeyPair receiverKeyPair,
  ) async {
    final senderKeys = _peerPublicKeys[senderId];
    if (senderKeys == null) {
      debugPrint('No public keys found for sender: $senderId');
      return null;
    }
    
    try {
      // Recreate sender's encryption public key
      final senderEncKey = SimplePublicKey(
        senderKeys['encryption']!,
        type: KeyPairType.x25519,
      );
      
      // ECDH key exchange
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: receiverKeyPair,
        remotePublicKey: senderEncKey,
      );
      
      // HKDF key derivation
      final derivedKey = await _hkdf.deriveKey(
        secretKey: sharedSecret,
        info: utf8.encode('encryption'),
        outputLength: 32,
      );
      
      // Create SecretBox for decryption
      final secretBox = SecretBox(
        token.ciphertext,
        nonce: token.iv,
        mac: Mac(token.mac),
      );
      
      // AES-256-CBC decryption
      final plaintext = await _aes.decrypt(
        secretBox,
        secretKey: derivedKey,
      );
      
      return utf8.decode(plaintext);
      
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }
  
  // Generate secure random bytes
  Uint8List generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256))
    );
  }
  
  // Hash data with SHA-256
  Uint8List hashData(Uint8List data) {
    final digest = sha256.convert(data);
    return Uint8List.fromList(digest.bytes);
  }
  
  // Emergency wipe
  void emergencyWipe() {
    _peerPublicKeys.clear();
    debugPrint('Crypto manager emergency wipe completed');
    notifyListeners();
  }
}

// Reticulum Token Model
class ReticulumToken {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List mac;
  final DateTime timestamp;
  
  ReticulumToken({
    required this.ciphertext,
    required this.iv,
    required this.mac,
    required this.timestamp,
  });
  
  // Serialize for transmission (Reticulum format)
  Map<String, dynamic> toJson() => {
    'c': base64Encode(ciphertext), // ciphertext
    'i': base64Encode(iv),         // initialization vector
    'm': base64Encode(mac),        // message authentication code
    't': timestamp.millisecondsSinceEpoch, // timestamp
  };
  
  factory ReticulumToken.fromJson(Map<String, dynamic> json) {
    return ReticulumToken(
      ciphertext: base64Decode(json['c']),
      iv: base64Decode(json['i']),
      mac: base64Decode(json['m']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['t']),
    );
  }
  
  // Get total token size
  int get totalSize => ciphertext.length + CryptoManager.TOKEN_OVERHEAD;
  
  // Validate token format
  bool get isValid {
    return iv.length == CryptoManager.IV_SIZE && 
           mac.length == CryptoManager.MAC_SIZE && 
           ciphertext.isNotEmpty;
  }
}
