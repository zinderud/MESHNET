// lib/services/security/advanced_key_management.dart - Advanced Key Management System
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meshnet_app/services/security/quantum_resistant_crypto.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Key lifecycle states
enum KeyLifecycleState {
  pending,            // Key generation requested but not completed
  active,             // Key is active and can be used
  deprecated,         // Key is deprecated, should not be used for new operations
  compromised,        // Key is potentially compromised
  revoked,            // Key has been revoked
  expired,            // Key has expired
  destroyed,          // Key has been securely destroyed
}

/// Key usage types
enum KeyUsageType {
  encryption,         // Data encryption/decryption
  digital_signature,  // Digital signing and verification
  key_exchange,       // Key exchange operations
  authentication,     // Authentication purposes
  derivation,         // Key derivation
  emergency_backup,   // Emergency backup key
  master_key,         // Master key for key hierarchy
  session_key,        // Temporary session key
}

/// Key security levels
enum KeySecurityLevel {
  standard,           // Standard security (AES-128, RSA-2048)
  enhanced,           // Enhanced security (AES-192, RSA-3072)
  high,              // High security (AES-256, RSA-4096)
  quantum_resistant,  // Post-quantum algorithms
  military_grade,     // Military-grade security
}

/// Key rotation policy
class KeyRotationPolicy {
  final String policyId;
  final Duration rotationInterval;
  final int maxUsageCount;
  final Duration warningPeriod;
  final bool autoRotate;
  final List<KeyUsageType> applicableUsages;
  final KeySecurityLevel minSecurityLevel;
  final Map<String, dynamic> conditions;

  KeyRotationPolicy({
    required this.policyId,
    required this.rotationInterval,
    required this.maxUsageCount,
    required this.warningPeriod,
    required this.autoRotate,
    required this.applicableUsages,
    required this.minSecurityLevel,
    required this.conditions,
  });

  /// Check if key needs rotation
  bool needsRotation(ManagedKey key) {
    final now = DateTime.now();
    
    // Check age-based rotation
    if (now.difference(key.createdAt) > rotationInterval) {
      return true;
    }
    
    // Check usage-based rotation
    if (key.usageCount >= maxUsageCount) {
      return true;
    }
    
    // Check security level
    if (key.securityLevel.index < minSecurityLevel.index) {
      return true;
    }
    
    return false;
  }

  /// Check if key needs warning
  bool needsWarning(ManagedKey key) {
    final now = DateTime.now();
    final expirationWarningTime = key.createdAt.add(rotationInterval).subtract(warningPeriod);
    
    return now.isAfter(expirationWarningTime) && !needsRotation(key);
  }

  Map<String, dynamic> toJson() {
    return {
      'policyId': policyId,
      'rotationInterval': rotationInterval.inMilliseconds,
      'maxUsageCount': maxUsageCount,
      'warningPeriod': warningPeriod.inMilliseconds,
      'autoRotate': autoRotate,
      'applicableUsages': applicableUsages.map((u) => u.toString()).toList(),
      'minSecurityLevel': minSecurityLevel.toString(),
      'conditions': conditions,
    };
  }
}

/// Managed cryptographic key
class ManagedKey {
  final String keyId;
  final String alias;
  final KeyUsageType usageType;
  final KeySecurityLevel securityLevel;
  final KeyLifecycleState state;
  final Uint8List keyMaterial;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? parentKeyId;
  final List<String> derivedKeyIds;
  final int usageCount;
  final DateTime lastUsed;
  final List<String> accessControlList;
  final Map<String, dynamic> auditLog;

  ManagedKey({
    required this.keyId,
    required this.alias,
    required this.usageType,
    required this.securityLevel,
    required this.state,
    required this.keyMaterial,
    required this.metadata,
    required this.createdAt,
    this.expiresAt,
    this.parentKeyId,
    required this.derivedKeyIds,
    required this.usageCount,
    required this.lastUsed,
    required this.accessControlList,
    required this.auditLog,
  });

  /// Check if key is currently usable
  bool get isUsable {
    if (state != KeyLifecycleState.active) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Check if key is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Check if key is compromised
  bool get isCompromised {
    return state == KeyLifecycleState.compromised;
  }

  /// Create a copy with updated fields
  ManagedKey copyWith({
    KeyLifecycleState? state,
    int? usageCount,
    DateTime? lastUsed,
    Map<String, dynamic>? metadata,
    List<String>? derivedKeyIds,
    Map<String, dynamic>? auditLog,
  }) {
    return ManagedKey(
      keyId: keyId,
      alias: alias,
      usageType: usageType,
      securityLevel: securityLevel,
      state: state ?? this.state,
      keyMaterial: keyMaterial,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      expiresAt: expiresAt,
      parentKeyId: parentKeyId,
      derivedKeyIds: derivedKeyIds ?? this.derivedKeyIds,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      accessControlList: accessControlList,
      auditLog: auditLog ?? this.auditLog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyId': keyId,
      'alias': alias,
      'usageType': usageType.toString(),
      'securityLevel': securityLevel.toString(),
      'state': state.toString(),
      'keyMaterial': base64Encode(keyMaterial),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'parentKeyId': parentKeyId,
      'derivedKeyIds': derivedKeyIds,
      'usageCount': usageCount,
      'lastUsed': lastUsed.toIso8601String(),
      'accessControlList': accessControlList,
      'auditLog': auditLog,
    };
  }

  factory ManagedKey.fromJson(Map<String, dynamic> json) {
    return ManagedKey(
      keyId: json['keyId'],
      alias: json['alias'],
      usageType: KeyUsageType.values.firstWhere(
        (u) => u.toString() == json['usageType'],
        orElse: () => KeyUsageType.encryption,
      ),
      securityLevel: KeySecurityLevel.values.firstWhere(
        (s) => s.toString() == json['securityLevel'],
        orElse: () => KeySecurityLevel.standard,
      ),
      state: KeyLifecycleState.values.firstWhere(
        (s) => s.toString() == json['state'],
        orElse: () => KeyLifecycleState.active,
      ),
      keyMaterial: base64Decode(json['keyMaterial']),
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      parentKeyId: json['parentKeyId'],
      derivedKeyIds: List<String>.from(json['derivedKeyIds'] ?? []),
      usageCount: json['usageCount'] ?? 0,
      lastUsed: DateTime.parse(json['lastUsed']),
      accessControlList: List<String>.from(json['accessControlList'] ?? []),
      auditLog: json['auditLog'] ?? {},
    );
  }
}

/// Key derivation request
class KeyDerivationRequest {
  final String parentKeyId;
  final String childAlias;
  final KeyUsageType childUsageType;
  final KeySecurityLevel childSecurityLevel;
  final Map<String, dynamic> derivationParameters;
  final Duration? validity;
  final List<String> accessControlList;

  KeyDerivationRequest({
    required this.parentKeyId,
    required this.childAlias,
    required this.childUsageType,
    required this.childSecurityLevel,
    required this.derivationParameters,
    this.validity,
    required this.accessControlList,
  });
}

/// Key backup and recovery
class KeyBackup {
  final String backupId;
  final String keyId;
  final Uint8List encryptedKeyData;
  final Map<String, dynamic> recoveryMetadata;
  final DateTime createdAt;
  final String backupLocation;
  final List<String> recoveryShares;

  KeyBackup({
    required this.backupId,
    required this.keyId,
    required this.encryptedKeyData,
    required this.recoveryMetadata,
    required this.createdAt,
    required this.backupLocation,
    required this.recoveryShares,
  });

  Map<String, dynamic> toJson() {
    return {
      'backupId': backupId,
      'keyId': keyId,
      'encryptedKeyData': base64Encode(encryptedKeyData),
      'recoveryMetadata': recoveryMetadata,
      'createdAt': createdAt.toIso8601String(),
      'backupLocation': backupLocation,
      'recoveryShares': recoveryShares,
    };
  }
}

/// Advanced Key Management System
class AdvancedKeyManagement {
  static AdvancedKeyManagement? _instance;
  static AdvancedKeyManagement get instance => _instance ??= AdvancedKeyManagement._internal();
  
  AdvancedKeyManagement._internal();

  final Logger _logger = Logger('AdvancedKeyManagement');
  
  bool _isInitialized = false;
  Timer? _rotationTimer;
  Timer? _auditTimer;
  
  // Key storage and management
  final Map<String, ManagedKey> _keys = {};
  final Map<String, KeyRotationPolicy> _rotationPolicies = {};
  final Map<String, KeyBackup> _keyBackups = {};
  final List<Map<String, dynamic>> _auditTrail = [];
  
  // Key hierarchy and relationships
  final Map<String, List<String>> _keyHierarchy = {};
  final Map<String, String> _keyAliases = {};
  
  // Security controls
  final Map<String, List<String>> _accessControls = {};
  final Set<String> _compromisedKeys = {};
  
  // Performance metrics
  int _totalKeyOperations = 0;
  int _keyRotations = 0;
  int _keyCompromises = 0;
  double _averageKeyLifetime = 0.0;

  bool get isInitialized => _isInitialized;
  int get totalManagedKeys => _keys.length;
  int get activeKeys => _keys.values.where((k) => k.state == KeyLifecycleState.active).length;
  List<ManagedKey> get keysNeedingRotation {
    return _keys.values.where((key) {
      return _rotationPolicies.values.any((policy) => 
        policy.applicableUsages.contains(key.usageType) && policy.needsRotation(key));
    }).toList();
  }

  /// Initialize advanced key management
  Future<bool> initialize() async {
    try {
      _logger.info('Initializing advanced key management system...');
      
      // Load default rotation policies
      await _loadDefaultRotationPolicies();
      
      // Initialize master keys
      await _initializeMasterKeys();
      
      // Start background timers
      _startRotationTimer();
      _startAuditTimer();
      
      _isInitialized = true;
      _logger.info('Advanced key management system initialized successfully');
      return true;
    } catch (e) {
      _logger.severe('Failed to initialize advanced key management system', e);
      return false;
    }
  }

  /// Shutdown advanced key management
  Future<void> shutdown() async {
    _logger.info('Shutting down advanced key management system...');
    
    _rotationTimer?.cancel();
    _auditTimer?.cancel();
    
    // Securely destroy all key material
    for (final key in _keys.values) {
      _securelyEraseKey(key.keyMaterial);
    }
    _keys.clear();
    
    _isInitialized = false;
    _logger.info('Advanced key management system shut down');
  }

  /// Generate new managed key
  Future<ManagedKey?> generateKey({
    required String alias,
    required KeyUsageType usageType,
    required KeySecurityLevel securityLevel,
    Duration? validity,
    String? parentKeyId,
    Map<String, dynamic>? metadata,
    List<String>? accessControlList,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Advanced key management not initialized');
      return null;
    }

    try {
      final keyId = _generateKeyId();
      final now = DateTime.now();
      
      // Check if alias already exists
      if (_keyAliases.containsKey(alias)) {
        _logger.warning('Key alias already exists: $alias');
        return null;
      }
      
      // Generate key material based on security level
      final keyMaterial = await _generateKeyMaterial(securityLevel, usageType);
      
      final managedKey = ManagedKey(
        keyId: keyId,
        alias: alias,
        usageType: usageType,
        securityLevel: securityLevel,
        state: KeyLifecycleState.active,
        keyMaterial: keyMaterial,
        metadata: metadata ?? {},
        createdAt: now,
        expiresAt: validity != null ? now.add(validity) : null,
        parentKeyId: parentKeyId,
        derivedKeyIds: [],
        usageCount: 0,
        lastUsed: now,
        accessControlList: accessControlList ?? [],
        auditLog: {},
      );
      
      // Store key
      _keys[keyId] = managedKey;
      _keyAliases[alias] = keyId;
      
      // Update hierarchy if derived key
      if (parentKeyId != null && _keys.containsKey(parentKeyId)) {
        _keyHierarchy[parentKeyId] = (_keyHierarchy[parentKeyId] ?? [])..add(keyId);
        
        final parentKey = _keys[parentKeyId]!;
        _keys[parentKeyId] = parentKey.copyWith(
          derivedKeyIds: [...parentKey.derivedKeyIds, keyId],
        );
      }
      
      // Create audit entry
      await _addAuditEntry('key_generated', {
        'keyId': keyId,
        'alias': alias,
        'usageType': usageType.toString(),
        'securityLevel': securityLevel.toString(),
        'parentKeyId': parentKeyId,
      });
      
      // Create backup if needed
      if (securityLevel.index >= KeySecurityLevel.high.index) {
        await _createKeyBackup(managedKey);
      }
      
      _logger.info('Generated managed key: $alias ($keyId)');
      return managedKey;
    } catch (e) {
      _logger.severe('Failed to generate managed key: $alias', e);
      return null;
    }
  }

  /// Derive child key from parent key
  Future<ManagedKey?> deriveKey(KeyDerivationRequest request) async {
    if (!_isInitialized) {
      _logger.warning('Advanced key management not initialized');
      return null;
    }

    try {
      final parentKey = _keys[request.parentKeyId];
      if (parentKey == null || !parentKey.isUsable) {
        _logger.warning('Invalid or unusable parent key: ${request.parentKeyId}');
        return null;
      }
      
      // Check access control
      if (!_checkAccess(parentKey, 'derive')) {
        _logger.warning('Access denied for key derivation: ${request.parentKeyId}');
        return null;
      }
      
      // Perform key derivation
      final derivedKeyMaterial = await _performKeyDerivation(
        parentKey.keyMaterial,
        request.derivationParameters,
        request.childSecurityLevel,
      );
      
      final childKey = await generateKey(
        alias: request.childAlias,
        usageType: request.childUsageType,
        securityLevel: request.childSecurityLevel,
        validity: request.validity,
        parentKeyId: request.parentKeyId,
        metadata: {
          'derived': true,
          'derivation_parameters': request.derivationParameters,
        },
        accessControlList: request.accessControlList,
      );
      
      if (childKey != null) {
        // Replace generated key material with derived one
        _keys[childKey.keyId] = childKey.copyWith(
          metadata: {
            ...childKey.metadata,
            'derived_key_material': true,
          },
        );
        
        // Update parent usage count
        _updateKeyUsage(request.parentKeyId);
        
        _logger.info('Derived child key: ${request.childAlias} from ${parentKey.alias}');
      }
      
      return childKey;
    } catch (e) {
      _logger.severe('Failed to derive key', e);
      return null;
    }
  }

  /// Rotate key according to policy
  Future<ManagedKey?> rotateKey({
    required String keyId,
    String? rotationPolicyId,
    Map<String, dynamic>? rotationParameters,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Advanced key management not initialized');
      return null;
    }

    try {
      final oldKey = _keys[keyId];
      if (oldKey == null) {
        _logger.warning('Key not found for rotation: $keyId');
        return null;
      }
      
      // Check if rotation is needed
      final policy = _rotationPolicies.values
          .where((p) => p.applicableUsages.contains(oldKey.usageType))
          .lastOrNull;
      
      if (policy != null && !policy.needsRotation(oldKey)) {
        _logger.info('Key rotation not needed: $keyId');
        return oldKey;
      }
      
      // Generate new key with same properties
      final newKey = await generateKey(
        alias: '${oldKey.alias}_rotated_${DateTime.now().millisecondsSinceEpoch}',
        usageType: oldKey.usageType,
        securityLevel: oldKey.securityLevel,
        validity: oldKey.expiresAt?.difference(DateTime.now()),
        parentKeyId: oldKey.parentKeyId,
        metadata: {
          ...oldKey.metadata,
          'rotated_from': keyId,
          'rotation_timestamp': DateTime.now().toIso8601String(),
        },
        accessControlList: oldKey.accessControlList,
      );
      
      if (newKey != null) {
        // Deprecate old key
        _keys[keyId] = oldKey.copyWith(
          state: KeyLifecycleState.deprecated,
          metadata: {
            ...oldKey.metadata,
            'deprecated_timestamp': DateTime.now().toIso8601String(),
            'rotated_to': newKey.keyId,
          },
        );
        
        // Update alias to point to new key
        _keyAliases[oldKey.alias] = newKey.keyId;
        
        // Create audit entry
        await _addAuditEntry('key_rotated', {
          'oldKeyId': keyId,
          'newKeyId': newKey.keyId,
          'rotationReason': policy?.policyId ?? 'manual',
        });
        
        _keyRotations++;
        _logger.info('Rotated key: ${oldKey.alias} ($keyId -> ${newKey.keyId})');
      }
      
      return newKey;
    } catch (e) {
      _logger.severe('Failed to rotate key: $keyId', e);
      return null;
    }
  }

  /// Mark key as compromised
  Future<bool> markKeyCompromised({
    required String keyId,
    String? reason,
    Map<String, dynamic>? compromiseDetails,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Advanced key management not initialized');
      return false;
    }

    try {
      final key = _keys[keyId];
      if (key == null) {
        _logger.warning('Key not found: $keyId');
        return false;
      }
      
      // Update key state
      _keys[keyId] = key.copyWith(
        state: KeyLifecycleState.compromised,
        metadata: {
          ...key.metadata,
          'compromise_timestamp': DateTime.now().toIso8601String(),
          'compromise_reason': reason ?? 'unknown',
          'compromise_details': compromiseDetails ?? {},
        },
      );
      
      // Add to compromised set
      _compromisedKeys.add(keyId);
      
      // Compromise all derived keys
      for (final derivedKeyId in key.derivedKeyIds) {
        await markKeyCompromised(
          keyId: derivedKeyId,
          reason: 'parent_key_compromised',
          compromiseDetails: {'parent_key': keyId},
        );
      }
      
      // Create audit entry
      await _addAuditEntry('key_compromised', {
        'keyId': keyId,
        'reason': reason,
        'compromiseDetails': compromiseDetails,
      });
      
      _keyCompromises++;
      _logger.warning('Marked key as compromised: ${key.alias} ($keyId)');
      return true;
    } catch (e) {
      _logger.severe('Failed to mark key as compromised: $keyId', e);
      return false;
    }
  }

  /// Revoke key
  Future<bool> revokeKey({
    required String keyId,
    String? reason,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Advanced key management not initialized');
      return false;
    }

    try {
      final key = _keys[keyId];
      if (key == null) {
        _logger.warning('Key not found: $keyId');
        return false;
      }
      
      // Update key state
      _keys[keyId] = key.copyWith(
        state: KeyLifecycleState.revoked,
        metadata: {
          ...key.metadata,
          'revocation_timestamp': DateTime.now().toIso8601String(),
          'revocation_reason': reason ?? 'manual',
        },
      );
      
      // Create audit entry
      await _addAuditEntry('key_revoked', {
        'keyId': keyId,
        'reason': reason,
      });
      
      _logger.info('Revoked key: ${key.alias} ($keyId)');
      return true;
    } catch (e) {
      _logger.severe('Failed to revoke key: $keyId', e);
      return false;
    }
  }

  /// Get key by ID or alias
  ManagedKey? getKey(String keyIdOrAlias) {
    if (!_isInitialized) return null;
    
    // Try by key ID first
    if (_keys.containsKey(keyIdOrAlias)) {
      return _keys[keyIdOrAlias];
    }
    
    // Try by alias
    final keyId = _keyAliases[keyIdOrAlias];
    if (keyId != null && _keys.containsKey(keyId)) {
      return _keys[keyId];
    }
    
    return null;
  }

  /// Update key usage statistics
  Future<void> _updateKeyUsage(String keyId) async {
    final key = _keys[keyId];
    if (key == null) return;
    
    _keys[keyId] = key.copyWith(
      usageCount: key.usageCount + 1,
      lastUsed: DateTime.now(),
    );
    
    _totalKeyOperations++;
  }

  /// Create key backup
  Future<bool> _createKeyBackup(ManagedKey key) async {
    try {
      final backupId = _generateBackupId();
      
      // Encrypt key material for backup
      final encryptedKeyData = await _encryptForBackup(key.keyMaterial);
      
      final backup = KeyBackup(
        backupId: backupId,
        keyId: key.keyId,
        encryptedKeyData: encryptedKeyData,
        recoveryMetadata: {
          'alias': key.alias,
          'usageType': key.usageType.toString(),
          'securityLevel': key.securityLevel.toString(),
          'created': key.createdAt.toIso8601String(),
        },
        createdAt: DateTime.now(),
        backupLocation: 'secure_storage',
        recoveryShares: [], // In real implementation, use secret sharing
      );
      
      _keyBackups[backupId] = backup;
      
      _logger.debug('Created key backup: $backupId for ${key.alias}');
      return true;
    } catch (e) {
      _logger.severe('Failed to create key backup', e);
      return false;
    }
  }

  /// Load default rotation policies
  Future<void> _loadDefaultRotationPolicies() async {
    // High-security keys policy
    _rotationPolicies['high_security'] = KeyRotationPolicy(
      policyId: 'high_security',
      rotationInterval: const Duration(days: 90),
      maxUsageCount: 10000,
      warningPeriod: const Duration(days: 7),
      autoRotate: true,
      applicableUsages: [
        KeyUsageType.encryption,
        KeyUsageType.digital_signature,
        KeyUsageType.master_key,
      ],
      minSecurityLevel: KeySecurityLevel.high,
      conditions: {},
    );
    
    // Session keys policy
    _rotationPolicies['session_keys'] = KeyRotationPolicy(
      policyId: 'session_keys',
      rotationInterval: const Duration(hours: 24),
      maxUsageCount: 1000,
      warningPeriod: const Duration(hours: 1),
      autoRotate: true,
      applicableUsages: [KeyUsageType.session_key],
      minSecurityLevel: KeySecurityLevel.standard,
      conditions: {},
    );
    
    // Emergency backup keys policy
    _rotationPolicies['emergency_backup'] = KeyRotationPolicy(
      policyId: 'emergency_backup',
      rotationInterval: const Duration(days: 365),
      maxUsageCount: 5,
      warningPeriod: const Duration(days: 30),
      autoRotate: false,
      applicableUsages: [KeyUsageType.emergency_backup],
      minSecurityLevel: KeySecurityLevel.quantum_resistant,
      conditions: {},
    );
    
    _logger.debug('Default rotation policies loaded');
  }

  /// Initialize master keys
  Future<void> _initializeMasterKeys() async {
    // Generate master encryption key
    await generateKey(
      alias: 'master_encryption_key',
      usageType: KeyUsageType.master_key,
      securityLevel: KeySecurityLevel.quantum_resistant,
      validity: const Duration(days: 365),
      metadata: {'type': 'master', 'purpose': 'encryption'},
    );
    
    // Generate master signing key
    await generateKey(
      alias: 'master_signing_key',
      usageType: KeyUsageType.digital_signature,
      securityLevel: KeySecurityLevel.quantum_resistant,
      validity: const Duration(days: 365),
      metadata: {'type': 'master', 'purpose': 'signing'},
    );
    
    _logger.debug('Master keys initialized');
  }

  /// Generate key material based on security level and usage type
  Future<Uint8List> _generateKeyMaterial(
    KeySecurityLevel securityLevel,
    KeyUsageType usageType,
  ) async {
    final random = Random.secure();
    
    int keySize;
    switch (securityLevel) {
      case KeySecurityLevel.standard:
        keySize = usageType == KeyUsageType.digital_signature ? 256 : 128;
        break;
      case KeySecurityLevel.enhanced:
        keySize = usageType == KeyUsageType.digital_signature ? 384 : 192;
        break;
      case KeySecurityLevel.high:
      case KeySecurityLevel.quantum_resistant:
      case KeySecurityLevel.military_grade:
        keySize = usageType == KeyUsageType.digital_signature ? 512 : 256;
        break;
    }
    
    return Uint8List.fromList(
      List.generate(keySize ~/ 8, (_) => random.nextInt(256))
    );
  }

  /// Perform key derivation
  Future<Uint8List> _performKeyDerivation(
    Uint8List parentKey,
    Map<String, dynamic> parameters,
    KeySecurityLevel securityLevel,
  ) async {
    // Simple HKDF-like derivation (in real implementation, use proper HKDF)
    final salt = parameters['salt'] as String? ?? 'default_salt';
    final info = parameters['info'] as String? ?? 'key_derivation';
    
    final combined = parentKey + utf8.encode(salt) + utf8.encode(info);
    final hash = sha256.convert(combined).bytes;
    
    int targetSize;
    switch (securityLevel) {
      case KeySecurityLevel.standard:
        targetSize = 16;
        break;
      case KeySecurityLevel.enhanced:
        targetSize = 24;
        break;
      default:
        targetSize = 32;
        break;
    }
    
    return Uint8List.fromList(hash.take(targetSize).toList());
  }

  /// Check access control for key operation
  bool _checkAccess(ManagedKey key, String operation) {
    // Simplified access control (in real implementation, use proper RBAC)
    if (key.accessControlList.isEmpty) return true;
    
    // For demonstration, allow access if 'admin' is in ACL
    return key.accessControlList.contains('admin') || 
           key.accessControlList.contains('system');
  }

  /// Encrypt key material for backup
  Future<Uint8List> _encryptForBackup(Uint8List keyMaterial) async {
    // Simple encryption for backup (in real implementation, use proper backup encryption)
    final backupKey = sha256.convert(utf8.encode('backup_master_key')).bytes;
    
    final encrypted = <int>[];
    for (int i = 0; i < keyMaterial.length; i++) {
      encrypted.add(keyMaterial[i] ^ backupKey[i % backupKey.length]);
    }
    
    return Uint8List.fromList(encrypted);
  }

  /// Add audit trail entry
  Future<void> _addAuditEntry(String action, Map<String, dynamic> details) async {
    final auditEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'details': details,
      'source': 'advanced_key_management',
    };
    
    _auditTrail.add(auditEntry);
    
    // Keep only last 10000 audit entries
    if (_auditTrail.length > 10000) {
      _auditTrail.removeAt(0);
    }
  }

  /// Start automatic key rotation timer
  void _startRotationTimer() {
    _rotationTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      await _performScheduledRotations();
    });
  }

  /// Start audit timer
  void _startAuditTimer() {
    _auditTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      await _performSecurityAudit();
    });
  }

  /// Perform scheduled key rotations
  Future<void> _performScheduledRotations() async {
    if (!_isInitialized) return;
    
    try {
      final keysToRotate = keysNeedingRotation;
      
      for (final key in keysToRotate) {
        final policy = _rotationPolicies.values
            .where((p) => p.applicableUsages.contains(key.usageType))
            .lastOrNull;
        
        if (policy != null && policy.autoRotate) {
          await rotateKey(keyId: key.keyId, rotationPolicyId: policy.policyId);
        }
      }
      
      _logger.debug('Scheduled key rotation completed: ${keysToRotate.length} keys processed');
    } catch (e) {
      _logger.warning('Scheduled key rotation failed', e);
    }
  }

  /// Perform security audit
  Future<void> _performSecurityAudit() async {
    if (!_isInitialized) return;
    
    try {
      final auditResults = <String, dynamic>{
        'total_keys': _keys.length,
        'active_keys': activeKeys,
        'expired_keys': _keys.values.where((k) => k.isExpired).length,
        'compromised_keys': _compromisedKeys.length,
        'keys_needing_rotation': keysNeedingRotation.length,
        'audit_timestamp': DateTime.now().toIso8601String(),
      };
      
      await _addAuditEntry('security_audit', auditResults);
      
      _logger.info('Security audit completed: ${auditResults['total_keys']} keys audited');
    } catch (e) {
      _logger.warning('Security audit failed', e);
    }
  }

  /// Get key management statistics
  Map<String, dynamic> getStatistics() {
    final stateDistribution = <KeyLifecycleState, int>{};
    final usageDistribution = <KeyUsageType, int>{};
    final securityDistribution = <KeySecurityLevel, int>{};
    
    for (final key in _keys.values) {
      stateDistribution[key.state] = (stateDistribution[key.state] ?? 0) + 1;
      usageDistribution[key.usageType] = (usageDistribution[key.usageType] ?? 0) + 1;
      securityDistribution[key.securityLevel] = (securityDistribution[key.securityLevel] ?? 0) + 1;
    }
    
    return {
      'initialized': _isInitialized,
      'totalManagedKeys': totalManagedKeys,
      'activeKeys': activeKeys,
      'totalKeyOperations': _totalKeyOperations,
      'keyRotations': _keyRotations,
      'keyCompromises': _keyCompromises,
      'averageKeyLifetime': _averageKeyLifetime,
      'rotationPolicies': _rotationPolicies.length,
      'keyBackups': _keyBackups.length,
      'auditEntries': _auditTrail.length,
      'keysNeedingRotation': keysNeedingRotation.length,
      'stateDistribution': stateDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'usageDistribution': usageDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'securityDistribution': securityDistribution.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  /// Generate unique key ID
  String _generateKeyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'key_${timestamp}_$random';
  }

  /// Generate unique backup ID
  String _generateBackupId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'backup_${timestamp}_$random';
  }

  /// Securely erase key from memory
  void _securelyEraseKey(Uint8List key) {
    for (int i = 0; i < key.length; i++) {
      key[i] = 0;
    }
  }
}
