# 4. Şifreleme ve Güvenlik Implementasyonu (Reticulum Enhanced)

## 📋 Bu Aşamada Yapılacaklar

**Reticulum Network Stack**'inin olgun kriptografi mimarisini temel alarak, BitChat'in temel özelliklerini koruyarak güvenlik sistemini implementasyonu.

### ✅ Tamamlanması Gerekenler:
1. **Reticulum Identity System** (512-bit EC keysets)
2. **X25519 ECDH key exchange** (Reticulum standardında)
3. **AES-256-CBC encryption** (Reticulum token formatı)
4. **Ed25519 digital signatures** (Reticulum standardında)
5. **HKDF key derivation** (Reticulum standardında)
6. **Forward secrecy** (ephemeral key rotation)
7. **Identity-based addressing** (hash-based)

## 🔐 Reticulum Güvenlik Mimarisi

### **Reticulum'un Kriptografi Stack'i:**
```python
# Reticulum Identity sistemi
class Identity:
    CURVE = "Curve25519"
    KEYSIZE = 256*2  # 512-bit total (256-bit encryption + 256-bit signing)
    
    def __init__(self, create_keys=True):
        if create_keys:
            # X25519 key for encryption
            self.prv = X25519PrivateKey.generate()
            self.pub = self.prv.public_key()
            
            # Ed25519 key for signing  
            self.sig_prv = Ed25519PrivateKey.generate()
            self.sig_pub = self.sig_prv.public_key()
            
            # Generate identity hash (global address)
            self.hash = self.get_hash()
    
    def encrypt(self, plaintext, destination_identity):
        # Reticulum token encryption
        shared_secret = self.prv.exchange(destination_identity.pub)
        derived_key = HKDF(shared_secret, length=32, info=b"encryption")
        
        # AES-256-CBC with random IV
        cipher = AES(derived_key, CBC, os.urandom(16))
        return cipher.encrypt(plaintext)
    
    def sign(self, data):
        # Ed25519 signature
        return self.sig_prv.sign(data)
```

### **MESHNET Kriptografi Implementasyonu (Reticulum Based)**

#### **1. Identity Manager Service**
```dart
// lib/services/identity_manager.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

class MESHNETIdentity {
  // Reticulum standardında 512-bit identity
  static const int KEYSIZE = 256 * 2; // bits
  static const int HASHLENGTH = 256; // bits
  
  // X25519 encryption keys
  late final SimpleKeyPair _encryptionKeyPair;
  late final SimplePublicKey _encryptionPublicKey;
  
  // Ed25519 signing keys  
  late final SimpleKeyPair _signingKeyPair;
  late final SimplePublicKey _signingPublicKey;
  
  // Identity hash (global address)
  late final Uint8List _identityHash;
  
  // Algorithms - Reticulum standardında
  final _x25519 = X25519();
  final _ed25519 = Ed25519();
  final _aes = AesCbc.with256bits(macAlgorithm: Hmac.sha256());
  final _hkdf = Hkdf(hmac: Hmac(Sha256()));
  
  // Initialize identity - Reticulum pattern
  Future<void> initialize({bool createKeys = true}) async {
    if (createKeys) {
      // Generate X25519 encryption key pair
      _encryptionKeyPair = await _x25519.newKeyPair();
      _encryptionPublicKey = await _encryptionKeyPair.extractPublicKey();
      
      // Generate Ed25519 signing key pair
      _signingKeyPair = await _ed25519.newKeyPair();
      _signingPublicKey = await _signingKeyPair.extractPublicKey();
      
      // Generate identity hash (Reticulum addressing)
      _identityHash = await _generateIdentityHash();
      
      debugPrint('Identity Hash: ${_hashToHex(_identityHash)}');
    }
  }
  
  // Generate Reticulum-style identity hash
  Future<Uint8List> _generateIdentityHash() async {
    final encPubBytes = await _encryptionPublicKey.extractBytes();
    final sigPubBytes = await _signingPublicKey.extractBytes();
    
    // Combine both public keys
    final combined = Uint8List.fromList([...encPubBytes, ...sigPubBytes]);
    
    // SHA-256 hash for addressing
    final hash = await Sha256().hash(combined);
    return Uint8List.fromList(hash.bytes.take(HASHLENGTH ~/ 8).toList());
  }
  
  // Get identity hash for addressing
  Uint8List getHash() => _identityHash;
  
  // Get public keys for sharing
  Future<Map<String, Uint8List>> getPublicKeys() async {
    return {
      'encryption': Uint8List.fromList(await _encryptionPublicKey.extractBytes()),
      'signing': Uint8List.fromList(await _signingPublicKey.extractBytes()),
    };
  }
  
  // Encrypt data for destination identity (Reticulum token format)
  Future<ReticulumToken?> encrypt(
    Uint8List plaintext, 
    Map<String, Uint8List> destinationPublicKeys
  ) async {
    try {
      // Recreate destination's encryption public key
      final destEncKey = SimplePublicKey(
        destinationPublicKeys['encryption']!,
        type: KeyPairType.x25519,
      );
      
      // ECDH key exchange
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: _encryptionKeyPair,
        remotePublicKey: destEncKey,
      );
      
      // HKDF key derivation (Reticulum standard)
      final derivedKey = await _hkdf.deriveKey(
        secretKey: sharedSecret,
        info: utf8.encode('encryption'),
        outputLength: 32, // 256-bit
      );
      
      // Generate random IV
      final iv = Uint8List.fromList(List.generate(16, (_) => 
          DateTime.now().millisecondsSinceEpoch % 256));
      
      // AES-256-CBC encryption (Reticulum format)
      final secretBox = await _aes.encrypt(
        plaintext,
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
  Future<Uint8List?> decrypt(
    ReticulumToken token,
    Map<String, Uint8List> senderPublicKeys,
  ) async {
    try {
      // Recreate sender's encryption public key
      final senderEncKey = SimplePublicKey(
        senderPublicKeys['encryption']!,
        type: KeyPairType.x25519,
      );
      
      // ECDH key exchange
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: _encryptionKeyPair,
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
      
      return Uint8List.fromList(plaintext);
      
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }
  
  // Sign data with Ed25519 (Reticulum standard)
  Future<ReticulumSignature?> sign(Uint8List data) async {
    try {
      final signature = await _ed25519.sign(
        data,
        keyPair: _signingKeyPair,
      );
      
      return ReticulumSignature(
        signature: Uint8List.fromList(signature.bytes),
        publicKey: Uint8List.fromList(await _signingPublicKey.extractBytes()),
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('Signing error: $e');
      return null;
    }
  }
  
  // Verify Ed25519 signature
  Future<bool> verify(
    Uint8List data,
    ReticulumSignature signature,
  ) async {
    try {
      final senderSigningKey = SimplePublicKey(
        signature.publicKey,
        type: KeyPairType.ed25519,
      );
      
      final sig = Signature(
        signature.signature,
        publicKey: senderSigningKey,
      );
      
      return await _ed25519.verify(data, signature: sig);
      
    } catch (e) {
      debugPrint('Verification error: $e');
      return false;
    }
  }
  
  String _hashToHex(Uint8List hash) {
    return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }
}

class CryptoManager {
  // BitChat'teki gibi X25519 key pair
  late final SimpleKeyPair _keyPair;
  late final SimplePublicKey _publicKey;
  
  // Algorithms - BitChat'teki gibi
  final _x25519 = X25519();
  final _aesGcm = AesGcm.with256bits();
  final _ed25519 = Ed25519();
  final _argon2id = Argon2id();
  
  // Key storage
  final Map<String, SimplePublicKey> _peerPublicKeys = {};
  final Map<String, SecretKey> _sharedSecrets = {};
  
  // Initialize crypto manager
  Future<void> initialize() async {
    // Generate X25519 key pair - BitChat'teki gibi
    _keyPair = await _x25519.newKeyPair();
    _publicKey = await _keyPair.extractPublicKey();
    
    debugPrint('Crypto Manager initialized');
    debugPrint('Public Key: ${await _publicKey.extractBytes()}');
  }
  
  // Get our public key for sharing
  Future<Uint8List> getPublicKey() async {
    final bytes = await _publicKey.extractBytes();
    return Uint8List.fromList(bytes);
  }
  
  // Add peer's public key - BitChat'teki peer key management
  Future<void> addPeerPublicKey(String peerId, Uint8List publicKeyBytes) async {
    try {
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.x25519,
      );
      
      _peerPublicKeys[peerId] = publicKey;
      
      // Generate shared secret - BitChat'teki ECDH
      final sharedSecret = await _x25519.sharedSecretKey(
        keyPair: _keyPair,
        remotePublicKey: publicKey,
      );
      
      _sharedSecrets[peerId] = sharedSecret;
      
      debugPrint('Added peer public key for: $peerId');
    } catch (e) {
      debugPrint('Error adding peer public key: $e');
    }
  }
  
  // Encrypt message for specific peer - BitChat'teki gibi
  Future<EncryptedMessage?> encryptMessage(
    String message, 
    String peerId
  ) async {
    try {
      final sharedSecret = _sharedSecrets[peerId];
      if (sharedSecret == null) {
        debugPrint('No shared secret for peer: $peerId');
        return null;
      }
      
      // Convert message to bytes
      final messageBytes = utf8.encode(message);
      
      // Encrypt with AES-GCM - BitChat'teki gibi
      final secretBox = await _aesGcm.encrypt(
        messageBytes,
        secretKey: sharedSecret,
      );
      
      // Create encrypted message
      final encryptedMessage = EncryptedMessage(
        ciphertext: secretBox.cipherText,
        nonce: secretBox.nonce,
        mac: secretBox.mac.bytes,
        timestamp: DateTime.now(),
        senderId: 'self',
        recipientId: peerId,
      );
      
      return encryptedMessage;
      
    } catch (e) {
      debugPrint('Encryption error: $e');
      return null;
    }
  }
  
  // Decrypt message from peer - BitChat'teki gibi
  Future<String?> decryptMessage(
    EncryptedMessage encryptedMessage,
    String senderId,
  ) async {
    try {
      final sharedSecret = _sharedSecrets[senderId];
      if (sharedSecret == null) {
        debugPrint('No shared secret for sender: $senderId');
        return null;
      }
      
      // Reconstruct SecretBox
      final secretBox = SecretBox(
        encryptedMessage.ciphertext,
        nonce: encryptedMessage.nonce,
        mac: Mac(encryptedMessage.mac),
      );
      
      // Decrypt with AES-GCM
      final decryptedBytes = await _aesGcm.decrypt(
        secretBox,
        secretKey: sharedSecret,
      );
      
      return utf8.decode(decryptedBytes);
      
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }
  
  // Sign message with Ed25519 - BitChat'teki gibi
  Future<MessageSignature?> signMessage(String message) async {
    try {
      // Generate Ed25519 signing key pair
      final signingKeyPair = await _ed25519.newKeyPair();
      final messageBytes = utf8.encode(message);
      
      // Sign message
      final signature = await _ed25519.sign(
        messageBytes,
        keyPair: signingKeyPair,
      );
      
      final publicKey = await signingKeyPair.extractPublicKey();
      
      return MessageSignature(
        signature: signature.bytes,
        publicKey: await publicKey.extractBytes(),
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      debugPrint('Signing error: $e');
      return null;
    }
  }
  
  // Verify message signature - BitChat'teki gibi
  Future<bool> verifySignature(
    String message,
    MessageSignature signature,
  ) async {
    try {
      final publicKey = SimplePublicKey(
        signature.publicKey,
        type: KeyPairType.ed25519,
      );
      
      final messageBytes = utf8.encode(message);
      final signatureObj = Signature(
        signature.signature,
        publicKey: publicKey,
      );
      
      return await _ed25519.verify(
        messageBytes,
        signature: signatureObj,
      );
      
    } catch (e) {
      debugPrint('Signature verification error: $e');
      return false;
    }
  }
  
  // Hash password for channel access - BitChat'teki gibi
  Future<String> hashPassword(String password, String salt) async {
    try {
      final saltBytes = utf8.encode(salt);
      final passwordBytes = utf8.encode(password);
      
      final hash = await _argon2id.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: saltBytes,
        outputLength: 32,
      );
      
      final hashBytes = await hash.extractBytes();
      return base64Encode(hashBytes);
      
    } catch (e) {
      debugPrint('Password hashing error: $e');
      return '';
    }
  }
  
  // Generate random salt
  String generateSalt() {
    final random = SecureRandom.fast();
    final saltBytes = random.nextBytes(16);
    return base64Encode(saltBytes);
  }
  
  // Forward secrecy - BitChat'teki gibi
  Future<void> rotateKeys() async {
    try {
      // Generate new key pair
      final newKeyPair = await _x25519.newKeyPair();
      
      // Update current key pair
      _keyPair = newKeyPair;
      _publicKey = await newKeyPair.extractPublicKey();
      
      // Clear old shared secrets
      _sharedSecrets.clear();
      
      debugPrint('Keys rotated for forward secrecy');
    } catch (e) {
      debugPrint('Key rotation error: $e');
    }
  }
  
  // Emergency wipe - BitChat'teki gibi
  void emergencyWipe() {
    _peerPublicKeys.clear();
    _sharedSecrets.clear();
    
    debugPrint('Emergency wipe completed');
  }
}
```

#### **2. Reticulum Token Models**
```dart
// lib/models/reticulum_token.dart
import 'dart:typed_data';
import 'dart:convert';

class ReticulumToken {
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List mac;
  final DateTime timestamp;
  
  // Reticulum token overhead constants
  static const int TOKEN_OVERHEAD = 48; // bytes
  static const int IV_SIZE = 16; // bytes
  static const int MAC_SIZE = 32; // bytes
  
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
  int get totalSize => ciphertext.length + TOKEN_OVERHEAD;
  
  // Validate token format
  bool get isValid {
    return iv.length == IV_SIZE && 
           mac.length == MAC_SIZE && 
           ciphertext.isNotEmpty;
  }
}

class ReticulumSignature {
  final Uint8List signature;
  final Uint8List publicKey;
  final DateTime timestamp;
  
  ReticulumSignature({
    required this.signature,
    required this.publicKey,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    's': base64Encode(signature),
    'p': base64Encode(publicKey),
    't': timestamp.toIso8601String(),
  };
  
  factory ReticulumSignature.fromJson(Map<String, dynamic> json) {
    return ReticulumSignature(
      signature: base64Decode(json['s']),
      publicKey: base64Decode(json['p']),
      timestamp: DateTime.parse(json['t']),
    );
  }
}
```

#### **3. Reticulum Destination System**
```dart
// lib/services/destination_manager.dart
import '../models/message.dart';
import 'identity_manager.dart';

class ReticulumDestination {
  final MESHNETIdentity identity;
  final String appName;
  final String aspectOne;
  final String aspectTwo;
  final DestinationType type;
  final DestinationDirection direction;
  
  // Reticulum destination hash (truncated)
  late final Uint8List destinationHash;
  
  ReticulumDestination({
    required this.identity,
    required this.appName,
    required this.aspectOne,
    required this.aspectTwo,
    required this.type,
    required this.direction,
  }) {
    destinationHash = _generateDestinationHash();
  }
  
  Uint8List _generateDestinationHash() {
    // Reticulum destination hashing
    final identityHash = identity.getHash();
    final nameData = utf8.encode('$appName.$aspectOne.$aspectTwo');
    
    // Combine identity hash with name data
    final combined = Uint8List.fromList([...identityHash, ...nameData]);
    
    // SHA-256 and truncate to 80 bits (10 bytes) for destination hash
    final hash = Sha256().hash(combined);
    return Uint8List.fromList(hash.bytes.take(10).toList());
  }
  
  // Create announce packet (Reticulum format)
  Future<AnnouncePacket> createAnnounce() async {
    final publicKeys = await identity.getPublicKeys();
    
    return AnnouncePacket(
      destinationHash: destinationHash,
      identityHash: identity.getHash(),
      publicKeys: publicKeys,
      timestamp: DateTime.now(),
    );
  }
  
  // Encrypt message for this destination
  Future<ReticulumToken?> encryptMessage(Message message) async {
    final messageData = utf8.encode(jsonEncode(message.toJson()));
    final publicKeys = await identity.getPublicKeys();
    
    return await identity.encrypt(
      Uint8List.fromList(messageData),
      publicKeys,
    );
  }
}

enum DestinationType { single, group, plain }
enum DestinationDirection { incoming, outgoing }

class AnnouncePacket {
  final Uint8List destinationHash;
  final Uint8List identityHash;
  final Map<String, Uint8List> publicKeys;
  final DateTime timestamp;
  
  AnnouncePacket({
    required this.destinationHash,
    required this.identityHash,
    required this.publicKeys,
    required this.timestamp,
  });
}
```

#### **4. Forward Secrecy Implementation**
```dart
// lib/services/forward_secrecy_manager.dart
class ForwardSecrecyManager {
  final MESHNETIdentity _identity;
  final Map<String, EphemeralSession> _sessions = {};
  
  // Reticulum ratchet constants
  static const Duration RATCHET_EXPIRY = Duration(days: 30);
  static const int MAX_MISSED_RATCHETS = 8;
  
  ForwardSecrecyManager(this._identity);
  
  // Create ephemeral session (Reticulum ratchet)
  Future<EphemeralSession> createSession(String peerId) async {
    final sessionKey = await _x25519.newKeyPair();
    final session = EphemeralSession(
      peerId: peerId,
      sessionKey: sessionKey,
      created: DateTime.now(),
      ratchetCount: 0,
    );
    
    _sessions[peerId] = session;
    return session;
  }
  
  // Rotate session keys (forward secrecy)
  Future<void> rotateSession(String peerId) async {
    final session = _sessions[peerId];
    if (session != null) {
      // Generate new ephemeral key
      final newSessionKey = await _x25519.newKeyPair();
      
      session.sessionKey = newSessionKey;
      session.ratchetCount++;
      session.lastRatchet = DateTime.now();
      
      debugPrint('Rotated ratchet for $peerId (count: ${session.ratchetCount})');
    }
  }
  
  // Clean up expired sessions
  void cleanupExpiredSessions() {
    final now = DateTime.now();
    _sessions.removeWhere((peerId, session) {
      final expired = now.difference(session.created) > RATCHET_EXPIRY;
      if (expired) {
        debugPrint('Cleaned up expired session for $peerId');
      }
      return expired;
    });
  }
}

class EphemeralSession {
  final String peerId;
  SimpleKeyPair sessionKey;
  final DateTime created;
  int ratchetCount;
  DateTime? lastRatchet;
  
  EphemeralSession({
    required this.peerId,
    required this.sessionKey,
    required this.created,
    required this.ratchetCount,
    this.lastRatchet,
  });
}
```
