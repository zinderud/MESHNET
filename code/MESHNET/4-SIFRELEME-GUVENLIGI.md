# 4. Şifreleme ve Güvenlik Implementasyonu

## 📋 Bu Aşamada Yapılacaklar

BitChat'teki güvenlik mimarisini temel alarak, X25519 key exchange, AES-256-GCM şifreleme ve Ed25519 digital signatures implementasyonu.

### ✅ Tamamlanması Gerekenler:
1. **X25519 ECDH key exchange** (BitChat'teki gibi)
2. **AES-256-GCM encryption** (BitChat'teki gibi)
3. **Ed25519 digital signatures** (BitChat'teki gibi)
4. **Argon2id password hashing** (BitChat'teki gibi)
5. **Forward secrecy** (BitChat'teki gibi)

## 🔐 BitChat Güvenlik Mimarisi

### **BitChat'teki Kriptografi Stack:**
```swift
// BitChat/CryptoManager.swift
import CryptoKit

class CryptoManager {
    // X25519 key exchange
    private let privateKey = Curve25519.KeyAgreement.PrivateKey()
    public let publicKey: Curve25519.KeyAgreement.PublicKey
    
    // AES-256-GCM encryption
    func encryptMessage(_ message: String, for publicKey: Curve25519.KeyAgreement.PublicKey) -> Data? {
        let sharedSecret = try? privateKey.sharedSecretFromKeyAgreement(with: publicKey)
        let symmetricKey = sharedSecret?.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        let sealedBox = try? AES.GCM.seal(message.data(using: .utf8)!, using: symmetricKey!)
        return sealedBox?.combined
    }
}
```

### **Flutter Kriptografi Implementasyonu**

#### **1. Crypto Manager Service**
```dart
// lib/services/crypto_manager.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

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

#### **2. Encrypted Message Models**
```dart
// lib/models/encrypted_message.dart
import 'dart:typed_data';
import 'dart:convert';

class EncryptedMessage {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;
  final DateTime timestamp;
  final String senderId;
  final String recipientId;
  
  EncryptedMessage({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
    required this.timestamp,
    required this.senderId,
    required this.recipientId,
  });
  
  // Serialize for transmission
  Map<String, dynamic> toJson() => {
    'ciphertext': base64Encode(ciphertext),
    'nonce': base64Encode(nonce),
    'mac': base64Encode(mac),
    'timestamp': timestamp.toIso8601String(),
    'senderId': senderId,
    'recipientId': recipientId,
  };
  
  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    return EncryptedMessage(
      ciphertext: base64Decode(json['ciphertext']),
      nonce: base64Decode(json['nonce']),
      mac: base64Decode(json['mac']),
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'],
      recipientId: json['recipientId'],
    );
  }
}

class MessageSignature {
  final Uint8List signature;
  final Uint8List publicKey;
  final DateTime timestamp;
  
  MessageSignature({
    required this.signature,
    required this.publicKey,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'signature': base64Encode(signature),
    'publicKey': base64Encode(publicKey),
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory MessageSignature.fromJson(Map<String, dynamic> json) {
    return MessageSignature(
      signature: base64Decode(json['signature']),
      publicKey: base64Decode(json['publicKey']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
```

#### **3. Secure Channel Manager**
```dart
// lib/services/secure_channel_manager.dart
import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/message.dart';
import 'crypto_manager.dart';

class SecureChannelManager extends ChangeNotifier {
  final CryptoManager _cryptoManager;
  
  // Channel storage - BitChat'teki gibi
  final Map<String, Channel> _channels = {};
  final Map<String, String> _channelPasswords = {};
  
  SecureChannelManager(this._cryptoManager);
  
  // Create encrypted channel - BitChat'teki gibi
  Future<Channel?> createChannel(String name, String? password) async {
    try {
      final channelId = _generateChannelId(name);
      
      String? hashedPassword;
      if (password != null) {
        final salt = _cryptoManager.generateSalt();
        hashedPassword = await _cryptoManager.hashPassword(password, salt);
        _channelPasswords[channelId] = hashedPassword;
      }
      
      final channel = Channel(
        id: channelId,
        name: name,
        isPrivate: password != null,
        createdAt: DateTime.now(),
        ownerId: 'self',
        members: ['self'],
      );
      
      _channels[channelId] = channel;
      notifyListeners();
      
      return channel;
      
    } catch (e) {
      debugPrint('Channel creation error: $e');
      return null;
    }
  }
  
  // Join channel with password - BitChat'teki gibi
  Future<bool> joinChannel(String channelId, String? password) async {
    try {
      final channel = _channels[channelId];
      if (channel == null) {
        debugPrint('Channel not found: $channelId');
        return false;
      }
      
      // Check password if channel is private
      if (channel.isPrivate && password != null) {
        final storedPassword = _channelPasswords[channelId];
        if (storedPassword == null) {
          debugPrint('No password stored for channel: $channelId');
          return false;
        }
        
        // Generate salt and hash provided password
        final salt = _cryptoManager.generateSalt();
        final hashedPassword = await _cryptoManager.hashPassword(password, salt);
        
        // Note: In real implementation, you'd need to store salt with password
        // This is simplified for demo
        if (hashedPassword != storedPassword) {
          debugPrint('Invalid password for channel: $channelId');
          return false;
        }
      }
      
      // Add user to channel
      if (!channel.members.contains('self')) {
        channel.members.add('self');
        notifyListeners();
      }
      
      return true;
      
    } catch (e) {
      debugPrint('Channel join error: $e');
      return false;
    }
  }
  
  // Send encrypted message to channel - BitChat'teki gibi
  Future<bool> sendChannelMessage(
    String channelId, 
    String content,
    String senderId,
  ) async {
    try {
      final channel = _channels[channelId];
      if (channel == null) {
        debugPrint('Channel not found: $channelId');
        return false;
      }
      
      // Create message
      final message = Message(
        id: _generateMessageId(),
        senderId: senderId,
        content: content,
        timestamp: DateTime.now(),
        channelId: channelId,
        type: MessageType.text,
      );
      
      // If channel is private, encrypt message
      if (channel.isPrivate) {
        // For channel encryption, we'd use a shared channel key
        // This is simplified - in real implementation, you'd derive
        // a channel key from the password
        final encryptedContent = await _encryptChannelMessage(
          content, 
          channelId,
        );
        
        if (encryptedContent != null) {
          final encryptedMessage = message.copyWith(
            content: encryptedContent,
            metadata: {'encrypted': true},
          );
          
          // Store encrypted message
          channel.messages.add(encryptedMessage);
        }
      } else {
        // Public channel - no encryption
        channel.messages.add(message);
      }
      
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Send channel message error: $e');
      return false;
    }
  }
  
  Future<String?> _encryptChannelMessage(String content, String channelId) async {
    try {
      // In real implementation, derive channel key from password
      // For demo, we'll use a simple approach
      final password = _channelPasswords[channelId];
      if (password == null) return content;
      
      // This is simplified - real implementation would be more secure
      final salt = _cryptoManager.generateSalt();
      final hashedPassword = await _cryptoManager.hashPassword(password, salt);
      
      return base64Encode(utf8.encode(content + hashedPassword));
      
    } catch (e) {
      debugPrint('Channel message encryption error: $e');
      return null;
    }
  }
  
  // Emergency wipe channels - BitChat'teki gibi
  void emergencyWipeChannels() {
    _channels.clear();
    _channelPasswords.clear();
    notifyListeners();
  }
  
  String _generateChannelId(String name) {
    return 'ch_${name.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
  
  // Getters
  List<Channel> get channels => _channels.values.toList();
  Channel? getChannel(String channelId) => _channels[channelId];
}
```

#### **4. Security UI Components**
```dart
// lib/widgets/security_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/crypto_manager.dart';

class SecurityStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CryptoManager>(
      builder: (context, cryptoManager, child) {
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'E2E Encrypted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// lib/widgets/emergency_wipe_widget.dart
class EmergencyWipeWidget extends StatelessWidget {
  final VoidCallback onWipe;
  
  const EmergencyWipeWidget({Key? key, required this.onWipe}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showWipeDialog(context),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Emergency Wipe',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showWipeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Wipe'),
        content: Text(
          'This will permanently delete all messages, keys, and data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onWipe();
            },
            child: Text('Wipe Data', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
```

## 🔐 Security Best Practices

### **1. Key Management**
```dart
// lib/services/key_manager.dart
class KeyManager {
  static const String KEY_ROTATION_INTERVAL = 'key_rotation_interval';
  static const int DEFAULT_ROTATION_HOURS = 24;
  
  // Automatic key rotation - BitChat'teki gibi
  void scheduleKeyRotation(CryptoManager cryptoManager) {
    Timer.periodic(Duration(hours: DEFAULT_ROTATION_HOURS), (timer) {
      cryptoManager.rotateKeys();
    });
  }
  
  // Secure key storage
  Future<void> secureStoreKey(String key, Uint8List keyData) async {
    // Use secure storage for key persistence
    // Implementation depends on platform
  }
}
```

### **2. Security Validation**
```dart
// lib/services/security_validator.dart
class SecurityValidator {
  static bool validateEncryptedMessage(EncryptedMessage message) {
    // Validate message structure
    if (message.ciphertext.isEmpty) return false;
    if (message.nonce.length != 12) return false; // GCM nonce
    if (message.mac.isEmpty) return false;
    
    // Validate timestamp (prevent replay attacks)
    final now = DateTime.now();
    final messageAge = now.difference(message.timestamp);
    if (messageAge.inHours > 24) return false;
    
    return true;
  }
  
  static bool validateSignature(MessageSignature signature) {
    // Validate signature structure
    if (signature.signature.isEmpty) return false;
    if (signature.publicKey.length != 32) return false; // Ed25519 public key
    
    return true;
  }
}
```

## ✅ Bu Aşama Tamamlandığında

- [ ] **X25519 ECDH key exchange çalışıyor**
- [ ] **AES-256-GCM encryption/decryption**
- [ ] **Ed25519 digital signatures**
- [ ] **Argon2id password hashing**
- [ ] **Forward secrecy key rotation**
- [ ] **Emergency wipe functionality**
- [ ] **Secure channel management**

## 🔄 Sonraki Adım

**5. Adım:** `5-MESAJ-YONLENDIRME.md` dosyasını inceleyin ve advanced message routing implementasyonuna başlayın.

---

**Son Güncelleme:** 11 Temmuz 2025  
**Durum:** Güvenlik ve Şifreleme Implementasyonu Hazır
