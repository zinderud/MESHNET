// lib/services/identity_manager.dart
// Reticulum Identity pattern implementation
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class IdentityManager extends ChangeNotifier {
  // Reticulum standardında 512-bit identity
  static const int KEYSIZE = 256 * 2; // bits
  static const int HASHLENGTH = 256; // bits
  static const String CURVE = "Curve25519";
  
  // X25519 encryption keys
  SimpleKeyPair? _encryptionKeyPair;
  SimplePublicKey? _encryptionPublicKey;
  
  // Ed25519 signing keys  
  SimpleKeyPair? _signingKeyPair;
  SimplePublicKey? _signingPublicKey;
  
  // Identity hash (global address)
  Uint8List? _identityHash;
  
  // Algorithms - Reticulum standardında
  final _x25519 = X25519();
  final _ed25519 = Ed25519();
  
  // Getters
  bool get isInitialized => _identityHash != null;
  Uint8List? get identityHash => _identityHash;
  String get identityHashHex => _identityHash != null 
      ? _identityHash!.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')
      : '';
  
  // Initialize identity - Reticulum pattern
  Future<bool> initialize({bool createKeys = true}) async {
    try {
      if (createKeys) {
        debugPrint('Generating new MESHNET identity...');
        
        // Generate X25519 encryption key pair
        _encryptionKeyPair = await _x25519.newKeyPair();
        _encryptionPublicKey = await _encryptionKeyPair!.extractPublicKey();
        
        // Generate Ed25519 signing key pair
        _signingKeyPair = await _ed25519.newKeyPair();
        _signingPublicKey = await _signingKeyPair!.extractPublicKey();
        
        // Generate identity hash (Reticulum addressing)
        _identityHash = await _generateIdentityHash();
        
        debugPrint('Identity initialized: $identityHashHex');
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Identity initialization error: $e');
      return false;
    }
  }
  
  // Generate Reticulum-style identity hash
  Future<Uint8List> _generateIdentityHash() async {
    final encPubBytes = await _encryptionPublicKey!.extractBytes();
    final sigPubBytes = await _signingPublicKey!.extractBytes();
    
    // Combine both public keys
    final combined = Uint8List.fromList([...encPubBytes, ...sigPubBytes]);
    
    // SHA-256 hash for addressing
    final digest = sha256.convert(combined);
    return Uint8List.fromList(digest.bytes.take(HASHLENGTH ~/ 8).toList());
  }
  
  // Get public keys for sharing
  Future<Map<String, Uint8List>?> getPublicKeys() async {
    if (!isInitialized) return null;
    
    return {
      'encryption': Uint8List.fromList(await _encryptionPublicKey!.extractBytes()),
      'signing': Uint8List.fromList(await _signingPublicKey!.extractBytes()),
      'identity_hash': _identityHash!,
    };
  }
  
  // Sign data with Ed25519 (Reticulum standard)
  Future<Uint8List?> sign(Uint8List data) async {
    if (!isInitialized) return null;
    
    try {
      final signature = await _ed25519.sign(
        data,
        keyPair: _signingKeyPair!,
      );
      
      return Uint8List.fromList(signature.bytes);
    } catch (e) {
      debugPrint('Signing error: $e');
      return null;
    }
  }
  
  // Verify Ed25519 signature
  Future<bool> verify(
    Uint8List data,
    Uint8List signature,
    Uint8List publicKey,
  ) async {
    try {
      final sigPublicKey = SimplePublicKey(
        publicKey,
        type: KeyPairType.ed25519,
      );
      
      final sig = Signature(
        signature,
        publicKey: sigPublicKey,
      );
      
      return await _ed25519.verify(data, signature: sig);
    } catch (e) {
      debugPrint('Verification error: $e');
      return false;
    }
  }
  
  // Emergency wipe - BitChat compatibility
  void emergencyWipe() {
    _encryptionKeyPair = null;
    _encryptionPublicKey = null;
    _signingKeyPair = null;
    _signingPublicKey = null;
    _identityHash = null;
    
    debugPrint('Emergency wipe completed');
    notifyListeners();
  }
}
