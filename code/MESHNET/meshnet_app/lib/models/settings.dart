// lib/models/settings.dart - Settings Data Models
import 'package:meshnet_app/utils/constants.dart';

/// Application settings model
class AppSettings {
  // Network Settings
  final NetworkSettings network;
  
  // Emergency Settings
  final EmergencySettings emergency;
  
  // UI Settings
  final UISettings ui;
  
  // Security Settings
  final SecuritySettings security;
  
  // System Settings
  final SystemSettings system;

  const AppSettings({
    required this.network,
    required this.emergency,
    required this.ui,
    required this.security,
    required this.system,
  });

  /// Create default settings
  factory AppSettings.defaults() {
    return AppSettings(
      network: NetworkSettings.defaults(),
      emergency: EmergencySettings.defaults(),
      ui: UISettings.defaults(),
      security: SecuritySettings.defaults(),
      system: SystemSettings.defaults(),
    );
  }

  /// Create copy with updated values
  AppSettings copyWith({
    NetworkSettings? network,
    EmergencySettings? emergency,
    UISettings? ui,
    SecuritySettings? security,
    SystemSettings? system,
  }) {
    return AppSettings(
      network: network ?? this.network,
      emergency: emergency ?? this.emergency,
      ui: ui ?? this.ui,
      security: security ?? this.security,
      system: system ?? this.system,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'network': network.toJson(),
      'emergency': emergency.toJson(),
      'ui': ui.toJson(),
      'security': security.toJson(),
      'system': system.toJson(),
    };
  }

  /// Create from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      network: NetworkSettings.fromJson(json['network'] ?? {}),
      emergency: EmergencySettings.fromJson(json['emergency'] ?? {}),
      ui: UISettings.fromJson(json['ui'] ?? {}),
      security: SecuritySettings.fromJson(json['security'] ?? {}),
      system: SystemSettings.fromJson(json['system'] ?? {}),
    );
  }
}

/// Network-related settings
class NetworkSettings {
  // Bluetooth settings
  final bool bluetoothEnabled;
  final Duration bluetoothScanInterval;
  final Duration bluetoothConnectionTimeout;
  final int maxBluetoothConnections;
  
  // WiFi Direct settings
  final bool wifiDirectEnabled;
  final String wifiDirectGroupName;
  final int wifiDirectPort;
  final Duration wifiDirectTimeout;
  
  // SDR settings
  final bool sdrEnabled;
  final double sdrFrequency;
  final int sdrSampleRate;
  final double sdrBandwidth;
  final String sdrModulation;
  final double sdrTxPower;
  
  // Ham Radio settings
  final bool hamRadioEnabled;
  final String hamRadioCallSign;
  final double hamRadioFrequency;
  final int hamRadioBaud;
  final String hamRadioMode;
  
  // General network settings
  final int maxMessageSize;
  final Duration messageTimeout;
  final Duration heartbeatInterval;
  final Duration discoveryInterval;
  final int maxRetryAttempts;

  const NetworkSettings({
    required this.bluetoothEnabled,
    required this.bluetoothScanInterval,
    required this.bluetoothConnectionTimeout,
    required this.maxBluetoothConnections,
    required this.wifiDirectEnabled,
    required this.wifiDirectGroupName,
    required this.wifiDirectPort,
    required this.wifiDirectTimeout,
    required this.sdrEnabled,
    required this.sdrFrequency,
    required this.sdrSampleRate,
    required this.sdrBandwidth,
    required this.sdrModulation,
    required this.sdrTxPower,
    required this.hamRadioEnabled,
    required this.hamRadioCallSign,
    required this.hamRadioFrequency,
    required this.hamRadioBaud,
    required this.hamRadioMode,
    required this.maxMessageSize,
    required this.messageTimeout,
    required this.heartbeatInterval,
    required this.discoveryInterval,
    required this.maxRetryAttempts,
  });

  factory NetworkSettings.defaults() {
    return NetworkSettings(
      bluetoothEnabled: true,
      bluetoothScanInterval: NetworkConstants.defaultScanInterval,
      bluetoothConnectionTimeout: NetworkConstants.defaultConnectionTimeout,
      maxBluetoothConnections: NetworkConstants.defaultMaxConnections,
      wifiDirectEnabled: true,
      wifiDirectGroupName: NetworkConstants.defaultGroupName,
      wifiDirectPort: NetworkConstants.defaultPort,
      wifiDirectTimeout: NetworkConstants.defaultTimeout,
      sdrEnabled: false,
      sdrFrequency: NetworkConstants.defaultSDRFrequency,
      sdrSampleRate: NetworkConstants.defaultSampleRate,
      sdrBandwidth: NetworkConstants.defaultBandwidth,
      sdrModulation: NetworkConstants.defaultModulation,
      sdrTxPower: NetworkConstants.defaultTxPower,
      hamRadioEnabled: false,
      hamRadioCallSign: NetworkConstants.defaultCallSign,
      hamRadioFrequency: NetworkConstants.defaultHamFrequency,
      hamRadioBaud: NetworkConstants.defaultBaud,
      hamRadioMode: NetworkConstants.defaultHamMode,
      maxMessageSize: NetworkConstants.defaultMaxMessageSize,
      messageTimeout: NetworkConstants.defaultMessageTimeout,
      heartbeatInterval: NetworkConstants.defaultHeartbeatInterval,
      discoveryInterval: NetworkConstants.defaultDiscoveryInterval,
      maxRetryAttempts: NetworkConstants.defaultMaxRetries,
    );
  }

  NetworkSettings copyWith({
    bool? bluetoothEnabled,
    Duration? bluetoothScanInterval,
    Duration? bluetoothConnectionTimeout,
    int? maxBluetoothConnections,
    bool? wifiDirectEnabled,
    String? wifiDirectGroupName,
    int? wifiDirectPort,
    Duration? wifiDirectTimeout,
    bool? sdrEnabled,
    double? sdrFrequency,
    int? sdrSampleRate,
    double? sdrBandwidth,
    String? sdrModulation,
    double? sdrTxPower,
    bool? hamRadioEnabled,
    String? hamRadioCallSign,
    double? hamRadioFrequency,
    int? hamRadioBaud,
    String? hamRadioMode,
    int? maxMessageSize,
    Duration? messageTimeout,
    Duration? heartbeatInterval,
    Duration? discoveryInterval,
    int? maxRetryAttempts,
  }) {
    return NetworkSettings(
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      bluetoothScanInterval: bluetoothScanInterval ?? this.bluetoothScanInterval,
      bluetoothConnectionTimeout: bluetoothConnectionTimeout ?? this.bluetoothConnectionTimeout,
      maxBluetoothConnections: maxBluetoothConnections ?? this.maxBluetoothConnections,
      wifiDirectEnabled: wifiDirectEnabled ?? this.wifiDirectEnabled,
      wifiDirectGroupName: wifiDirectGroupName ?? this.wifiDirectGroupName,
      wifiDirectPort: wifiDirectPort ?? this.wifiDirectPort,
      wifiDirectTimeout: wifiDirectTimeout ?? this.wifiDirectTimeout,
      sdrEnabled: sdrEnabled ?? this.sdrEnabled,
      sdrFrequency: sdrFrequency ?? this.sdrFrequency,
      sdrSampleRate: sdrSampleRate ?? this.sdrSampleRate,
      sdrBandwidth: sdrBandwidth ?? this.sdrBandwidth,
      sdrModulation: sdrModulation ?? this.sdrModulation,
      sdrTxPower: sdrTxPower ?? this.sdrTxPower,
      hamRadioEnabled: hamRadioEnabled ?? this.hamRadioEnabled,
      hamRadioCallSign: hamRadioCallSign ?? this.hamRadioCallSign,
      hamRadioFrequency: hamRadioFrequency ?? this.hamRadioFrequency,
      hamRadioBaud: hamRadioBaud ?? this.hamRadioBaud,
      hamRadioMode: hamRadioMode ?? this.hamRadioMode,
      maxMessageSize: maxMessageSize ?? this.maxMessageSize,
      messageTimeout: messageTimeout ?? this.messageTimeout,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      discoveryInterval: discoveryInterval ?? this.discoveryInterval,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bluetoothEnabled': bluetoothEnabled,
      'bluetoothScanInterval': bluetoothScanInterval.inMilliseconds,
      'bluetoothConnectionTimeout': bluetoothConnectionTimeout.inMilliseconds,
      'maxBluetoothConnections': maxBluetoothConnections,
      'wifiDirectEnabled': wifiDirectEnabled,
      'wifiDirectGroupName': wifiDirectGroupName,
      'wifiDirectPort': wifiDirectPort,
      'wifiDirectTimeout': wifiDirectTimeout.inMilliseconds,
      'sdrEnabled': sdrEnabled,
      'sdrFrequency': sdrFrequency,
      'sdrSampleRate': sdrSampleRate,
      'sdrBandwidth': sdrBandwidth,
      'sdrModulation': sdrModulation,
      'sdrTxPower': sdrTxPower,
      'hamRadioEnabled': hamRadioEnabled,
      'hamRadioCallSign': hamRadioCallSign,
      'hamRadioFrequency': hamRadioFrequency,
      'hamRadioBaud': hamRadioBaud,
      'hamRadioMode': hamRadioMode,
      'maxMessageSize': maxMessageSize,
      'messageTimeout': messageTimeout.inMilliseconds,
      'heartbeatInterval': heartbeatInterval.inMilliseconds,
      'discoveryInterval': discoveryInterval.inMilliseconds,
      'maxRetryAttempts': maxRetryAttempts,
    };
  }

  factory NetworkSettings.fromJson(Map<String, dynamic> json) {
    return NetworkSettings(
      bluetoothEnabled: json['bluetoothEnabled'] ?? true,
      bluetoothScanInterval: Duration(milliseconds: json['bluetoothScanInterval'] ?? 30000),
      bluetoothConnectionTimeout: Duration(milliseconds: json['bluetoothConnectionTimeout'] ?? 10000),
      maxBluetoothConnections: json['maxBluetoothConnections'] ?? 8,
      wifiDirectEnabled: json['wifiDirectEnabled'] ?? true,
      wifiDirectGroupName: json['wifiDirectGroupName'] ?? 'MESHNET',
      wifiDirectPort: json['wifiDirectPort'] ?? 8080,
      wifiDirectTimeout: Duration(milliseconds: json['wifiDirectTimeout'] ?? 15000),
      sdrEnabled: json['sdrEnabled'] ?? false,
      sdrFrequency: json['sdrFrequency']?.toDouble() ?? 433000000.0,
      sdrSampleRate: json['sdrSampleRate'] ?? 2048000,
      sdrBandwidth: json['sdrBandwidth']?.toDouble() ?? 1000000.0,
      sdrModulation: json['sdrModulation'] ?? 'FSK',
      sdrTxPower: json['sdrTxPower']?.toDouble() ?? 10.0,
      hamRadioEnabled: json['hamRadioEnabled'] ?? false,
      hamRadioCallSign: json['hamRadioCallSign'] ?? 'N0CALL',
      hamRadioFrequency: json['hamRadioFrequency']?.toDouble() ?? 145500000.0,
      hamRadioBaud: json['hamRadioBaud'] ?? 1200,
      hamRadioMode: json['hamRadioMode'] ?? 'PACKET',
      maxMessageSize: json['maxMessageSize'] ?? 8192,
      messageTimeout: Duration(milliseconds: json['messageTimeout'] ?? 30000),
      heartbeatInterval: Duration(milliseconds: json['heartbeatInterval'] ?? 60000),
      discoveryInterval: Duration(milliseconds: json['discoveryInterval'] ?? 30000),
      maxRetryAttempts: json['maxRetryAttempts'] ?? 3,
    );
  }
}

/// Emergency-related settings
class EmergencySettings {
  final bool emergencyModeEnabled;
  final Duration emergencyTimeout;
  final Duration emergencyBroadcastInterval;
  final double maxEmergencyRange;
  final List<String> preferredServices;
  final bool autoEmergencyBroadcast;
  final bool locationSharingEnabled;
  final int emergencyPriority;

  const EmergencySettings({
    required this.emergencyModeEnabled,
    required this.emergencyTimeout,
    required this.emergencyBroadcastInterval,
    required this.maxEmergencyRange,
    required this.preferredServices,
    required this.autoEmergencyBroadcast,
    required this.locationSharingEnabled,
    required this.emergencyPriority,
  });

  factory EmergencySettings.defaults() {
    return EmergencySettings(
      emergencyModeEnabled: true,
      emergencyTimeout: EmergencyConstants.defaultTimeout,
      emergencyBroadcastInterval: EmergencyConstants.defaultBroadcastInterval,
      maxEmergencyRange: EmergencyConstants.defaultMaxRange,
      preferredServices: EmergencyConstants.defaultServices,
      autoEmergencyBroadcast: true,
      locationSharingEnabled: true,
      emergencyPriority: EmergencyConstants.defaultPriority,
    );
  }

  EmergencySettings copyWith({
    bool? emergencyModeEnabled,
    Duration? emergencyTimeout,
    Duration? emergencyBroadcastInterval,
    double? maxEmergencyRange,
    List<String>? preferredServices,
    bool? autoEmergencyBroadcast,
    bool? locationSharingEnabled,
    int? emergencyPriority,
  }) {
    return EmergencySettings(
      emergencyModeEnabled: emergencyModeEnabled ?? this.emergencyModeEnabled,
      emergencyTimeout: emergencyTimeout ?? this.emergencyTimeout,
      emergencyBroadcastInterval: emergencyBroadcastInterval ?? this.emergencyBroadcastInterval,
      maxEmergencyRange: maxEmergencyRange ?? this.maxEmergencyRange,
      preferredServices: preferredServices ?? this.preferredServices,
      autoEmergencyBroadcast: autoEmergencyBroadcast ?? this.autoEmergencyBroadcast,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      emergencyPriority: emergencyPriority ?? this.emergencyPriority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emergencyModeEnabled': emergencyModeEnabled,
      'emergencyTimeout': emergencyTimeout.inMilliseconds,
      'emergencyBroadcastInterval': emergencyBroadcastInterval.inMilliseconds,
      'maxEmergencyRange': maxEmergencyRange,
      'preferredServices': preferredServices,
      'autoEmergencyBroadcast': autoEmergencyBroadcast,
      'locationSharingEnabled': locationSharingEnabled,
      'emergencyPriority': emergencyPriority,
    };
  }

  factory EmergencySettings.fromJson(Map<String, dynamic> json) {
    return EmergencySettings(
      emergencyModeEnabled: json['emergencyModeEnabled'] ?? true,
      emergencyTimeout: Duration(milliseconds: json['emergencyTimeout'] ?? 86400000),
      emergencyBroadcastInterval: Duration(milliseconds: json['emergencyBroadcastInterval'] ?? 30000),
      maxEmergencyRange: json['maxEmergencyRange']?.toDouble() ?? 10000.0,
      preferredServices: List<String>.from(json['preferredServices'] ?? ['ambulance', 'fire', 'police']),
      autoEmergencyBroadcast: json['autoEmergencyBroadcast'] ?? true,
      locationSharingEnabled: json['locationSharingEnabled'] ?? true,
      emergencyPriority: json['emergencyPriority'] ?? 1,
    );
  }
}

/// UI-related settings
class UISettings {
  final bool darkMode;
  final double fontSize;
  final String language;
  final bool animationsEnabled;
  final Duration animationDuration;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final int themeColor;
  
  // Additional UI settings for enhanced functionality
  final bool showAvatars;
  final String messageBubbleStyle;
  final bool enableAnimations;
  final double animationSpeed;
  final bool hapticFeedback;
  final bool soundEffects;
  final String layoutDensity;
  final bool compactMode;
  final bool showNavigationLabels;
  final String tabBarPosition;
  final bool highContrastMode;
  final bool largeTextMode;
  final bool screenReaderSupport;
  final bool reduceMotion;
  final bool developerMode;
  final bool showDebugInfo;
  final bool showPerformanceMetrics;

  const UISettings({
    required this.darkMode,
    required this.fontSize,
    required this.language,
    required this.animationsEnabled,
    required this.animationDuration,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    required this.themeColor,
    this.showAvatars = true,
    this.messageBubbleStyle = 'modern',
    this.enableAnimations = true,
    this.animationSpeed = 1.0,
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.layoutDensity = 'comfortable',
    this.compactMode = false,
    this.showNavigationLabels = true,
    this.tabBarPosition = 'bottom',
    this.highContrastMode = false,
    this.largeTextMode = false,
    this.screenReaderSupport = false,
    this.reduceMotion = false,
    this.developerMode = false,
    this.showDebugInfo = false,
    this.showPerformanceMetrics = false,
  });

  factory UISettings.defaults() {
    return UISettings(
      darkMode: false,
      fontSize: UIConstants.defaultFontSize,
      language: UIConstants.defaultLanguage,
      animationsEnabled: true,
      animationDuration: UIConstants.defaultAnimationDuration,
      soundEnabled: true,
      vibrationEnabled: true,
      notificationsEnabled: true,
      themeColor: UIConstants.defaultPrimaryColor,
    );
  }

  UISettings copyWith({
    bool? darkMode,
    double? fontSize,
    String? language,
    bool? animationsEnabled,
    Duration? animationDuration,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    int? themeColor,
    bool? showAvatars,
    String? messageBubbleStyle,
    bool? enableAnimations,
    double? animationSpeed,
    bool? hapticFeedback,
    bool? soundEffects,
    String? layoutDensity,
    bool? compactMode,
    bool? showNavigationLabels,
    String? tabBarPosition,
    bool? highContrastMode,
    bool? largeTextMode,
    bool? screenReaderSupport,
    bool? reduceMotion,
    bool? developerMode,
    bool? showDebugInfo,
    bool? showPerformanceMetrics,
  }) {
    return UISettings(
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      animationDuration: animationDuration ?? this.animationDuration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeColor: themeColor ?? this.themeColor,
      showAvatars: showAvatars ?? this.showAvatars,
      messageBubbleStyle: messageBubbleStyle ?? this.messageBubbleStyle,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      layoutDensity: layoutDensity ?? this.layoutDensity,
      compactMode: compactMode ?? this.compactMode,
      showNavigationLabels: showNavigationLabels ?? this.showNavigationLabels,
      tabBarPosition: tabBarPosition ?? this.tabBarPosition,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      largeTextMode: largeTextMode ?? this.largeTextMode,
      screenReaderSupport: screenReaderSupport ?? this.screenReaderSupport,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      developerMode: developerMode ?? this.developerMode,
      showDebugInfo: showDebugInfo ?? this.showDebugInfo,
      showPerformanceMetrics: showPerformanceMetrics ?? this.showPerformanceMetrics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'fontSize': fontSize,
      'language': language,
      'animationsEnabled': animationsEnabled,
      'animationDuration': animationDuration.inMilliseconds,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'notificationsEnabled': notificationsEnabled,
      'themeColor': themeColor,
      'showAvatars': showAvatars,
      'messageBubbleStyle': messageBubbleStyle,
      'enableAnimations': enableAnimations,
      'animationSpeed': animationSpeed,
      'hapticFeedback': hapticFeedback,
      'soundEffects': soundEffects,
      'layoutDensity': layoutDensity,
      'compactMode': compactMode,
      'showNavigationLabels': showNavigationLabels,
      'tabBarPosition': tabBarPosition,
      'highContrastMode': highContrastMode,
      'largeTextMode': largeTextMode,
      'screenReaderSupport': screenReaderSupport,
      'reduceMotion': reduceMotion,
      'developerMode': developerMode,
      'showDebugInfo': showDebugInfo,
      'showPerformanceMetrics': showPerformanceMetrics,
    };
  }

  factory UISettings.fromJson(Map<String, dynamic> json) {
    return UISettings(
      darkMode: json['darkMode'] ?? false,
      fontSize: json['fontSize']?.toDouble() ?? 14.0,
      language: json['language'] ?? 'en',
      animationsEnabled: json['animationsEnabled'] ?? true,
      animationDuration: Duration(milliseconds: json['animationDuration'] ?? 300),
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeColor: json['themeColor'] ?? 0xFF2196F3,
      showAvatars: json['showAvatars'] ?? true,
      messageBubbleStyle: json['messageBubbleStyle'] ?? 'modern',
      enableAnimations: json['enableAnimations'] ?? true,
      animationSpeed: json['animationSpeed']?.toDouble() ?? 1.0,
      hapticFeedback: json['hapticFeedback'] ?? true,
      soundEffects: json['soundEffects'] ?? true,
      layoutDensity: json['layoutDensity'] ?? 'comfortable',
      compactMode: json['compactMode'] ?? false,
      showNavigationLabels: json['showNavigationLabels'] ?? true,
      tabBarPosition: json['tabBarPosition'] ?? 'bottom',
      highContrastMode: json['highContrastMode'] ?? false,
      largeTextMode: json['largeTextMode'] ?? false,
      screenReaderSupport: json['screenReaderSupport'] ?? false,
      reduceMotion: json['reduceMotion'] ?? false,
      developerMode: json['developerMode'] ?? false,
      showDebugInfo: json['showDebugInfo'] ?? false,
      showPerformanceMetrics: json['showPerformanceMetrics'] ?? false,
    );
  }
}

/// Security-related settings
class SecuritySettings {
  final bool encryptionEnabled;
  final String encryptionAlgorithm;
  final int keySize;
  final bool autoKeyRotation;
  final Duration keyRotationInterval;
  final bool requireAuthentication;
  final Duration sessionTimeout;
  final int maxLoginAttempts;
  final bool trustScoreEnabled;
  final double minTrustScore;
  
  // Additional security settings
  final String authenticationMethod;
  final bool signMessages;
  final bool verifySignatures;
  final String signatureAlgorithm;
  final bool secureProtocolsOnly;
  final bool firewallEnabled;
  final bool intrusionDetection;
  final List<String> trustedPeers;
  final bool anonymousMode;
  final bool hideMetadata;
  final Duration dataRetentionPeriod;
  final bool autoDeleteMessages;

  const SecuritySettings({
    required this.encryptionEnabled,
    required this.encryptionAlgorithm,
    required this.keySize,
    required this.autoKeyRotation,
    required this.keyRotationInterval,
    required this.requireAuthentication,
    required this.sessionTimeout,
    required this.maxLoginAttempts,
    required this.trustScoreEnabled,
    required this.minTrustScore,
    this.authenticationMethod = 'passphrase',
    this.signMessages = true,
    this.verifySignatures = true,
    this.signatureAlgorithm = 'Ed25519',
    this.secureProtocolsOnly = true,
    this.firewallEnabled = true,
    this.intrusionDetection = true,
    this.trustedPeers = const [],
    this.anonymousMode = false,
    this.hideMetadata = false,
    this.dataRetentionPeriod = const Duration(days: 30),
    this.autoDeleteMessages = false,
  });

  factory SecuritySettings.defaults() {
    return SecuritySettings(
      encryptionEnabled: true,
      encryptionAlgorithm: SecurityConstants.defaultEncryptionAlgorithm,
      keySize: SecurityConstants.defaultKeySize,
      autoKeyRotation: true,
      keyRotationInterval: SecurityConstants.defaultKeyRotationInterval,
      requireAuthentication: true,
      sessionTimeout: SecurityConstants.defaultSessionTimeout,
      maxLoginAttempts: SecurityConstants.defaultMaxLoginAttempts,
      trustScoreEnabled: true,
      minTrustScore: SecurityConstants.defaultMinTrustScore,
    );
  }

  SecuritySettings copyWith({
    bool? encryptionEnabled,
    String? encryptionAlgorithm,
    int? keySize,
    bool? autoKeyRotation,
    Duration? keyRotationInterval,
    bool? requireAuthentication,
    Duration? sessionTimeout,
    int? maxLoginAttempts,
    bool? trustScoreEnabled,
    double? minTrustScore,
    String? authenticationMethod,
    bool? signMessages,
    bool? verifySignatures,
    String? signatureAlgorithm,
    bool? secureProtocolsOnly,
    bool? firewallEnabled,
    bool? intrusionDetection,
    List<String>? trustedPeers,
    bool? anonymousMode,
    bool? hideMetadata,
    Duration? dataRetentionPeriod,
    bool? autoDeleteMessages,
  }) {
    return SecuritySettings(
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
      encryptionAlgorithm: encryptionAlgorithm ?? this.encryptionAlgorithm,
      keySize: keySize ?? this.keySize,
      autoKeyRotation: autoKeyRotation ?? this.autoKeyRotation,
      keyRotationInterval: keyRotationInterval ?? this.keyRotationInterval,
      requireAuthentication: requireAuthentication ?? this.requireAuthentication,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      maxLoginAttempts: maxLoginAttempts ?? this.maxLoginAttempts,
      trustScoreEnabled: trustScoreEnabled ?? this.trustScoreEnabled,
      minTrustScore: minTrustScore ?? this.minTrustScore,
      authenticationMethod: authenticationMethod ?? this.authenticationMethod,
      signMessages: signMessages ?? this.signMessages,
      verifySignatures: verifySignatures ?? this.verifySignatures,
      signatureAlgorithm: signatureAlgorithm ?? this.signatureAlgorithm,
      secureProtocolsOnly: secureProtocolsOnly ?? this.secureProtocolsOnly,
      firewallEnabled: firewallEnabled ?? this.firewallEnabled,
      intrusionDetection: intrusionDetection ?? this.intrusionDetection,
      trustedPeers: trustedPeers ?? this.trustedPeers,
      anonymousMode: anonymousMode ?? this.anonymousMode,
      hideMetadata: hideMetadata ?? this.hideMetadata,
      dataRetentionPeriod: dataRetentionPeriod ?? this.dataRetentionPeriod,
      autoDeleteMessages: autoDeleteMessages ?? this.autoDeleteMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encryptionEnabled': encryptionEnabled,
      'encryptionAlgorithm': encryptionAlgorithm,
      'keySize': keySize,
      'autoKeyRotation': autoKeyRotation,
      'keyRotationInterval': keyRotationInterval.inMilliseconds,
      'requireAuthentication': requireAuthentication,
      'sessionTimeout': sessionTimeout.inMilliseconds,
      'maxLoginAttempts': maxLoginAttempts,
      'trustScoreEnabled': trustScoreEnabled,
      'minTrustScore': minTrustScore,
      'authenticationMethod': authenticationMethod,
      'signMessages': signMessages,
      'verifySignatures': verifySignatures,
      'signatureAlgorithm': signatureAlgorithm,
      'secureProtocolsOnly': secureProtocolsOnly,
      'firewallEnabled': firewallEnabled,
      'intrusionDetection': intrusionDetection,
      'trustedPeers': trustedPeers,
      'anonymousMode': anonymousMode,
      'hideMetadata': hideMetadata,
      'dataRetentionPeriod': dataRetentionPeriod.inMilliseconds,
      'autoDeleteMessages': autoDeleteMessages,
    };
  }

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      encryptionEnabled: json['encryptionEnabled'] ?? true,
      encryptionAlgorithm: json['encryptionAlgorithm'] ?? 'AES-256-GCM',
      keySize: json['keySize'] ?? 256,
      autoKeyRotation: json['autoKeyRotation'] ?? true,
      keyRotationInterval: Duration(milliseconds: json['keyRotationInterval'] ?? 86400000),
      requireAuthentication: json['requireAuthentication'] ?? true,
      sessionTimeout: Duration(milliseconds: json['sessionTimeout'] ?? 1800000),
      maxLoginAttempts: json['maxLoginAttempts'] ?? 3,
      trustScoreEnabled: json['trustScoreEnabled'] ?? true,
      minTrustScore: json['minTrustScore']?.toDouble() ?? 0.5,
      authenticationMethod: json['authenticationMethod'] ?? 'passphrase',
      signMessages: json['signMessages'] ?? true,
      verifySignatures: json['verifySignatures'] ?? true,
      signatureAlgorithm: json['signatureAlgorithm'] ?? 'Ed25519',
      secureProtocolsOnly: json['secureProtocolsOnly'] ?? true,
      firewallEnabled: json['firewallEnabled'] ?? true,
      intrusionDetection: json['intrusionDetection'] ?? true,
      trustedPeers: List<String>.from(json['trustedPeers'] ?? []),
      anonymousMode: json['anonymousMode'] ?? false,
      hideMetadata: json['hideMetadata'] ?? false,
      dataRetentionPeriod: Duration(milliseconds: json['dataRetentionPeriod'] ?? 2592000000),
      autoDeleteMessages: json['autoDeleteMessages'] ?? false,
    );
  }
}

/// System-related settings
class SystemSettings {
  final bool debugMode;
  final String logLevel;
  final bool crashReporting;
  final bool analyticsEnabled;
  final bool autoUpdate;
  final Duration cacheTimeout;
  final int maxCacheSize;
  final bool lowPowerMode;
  final String dataDirectory;
  
  // Additional system settings
  final String performanceMode;
  final double cpuUsageLimit;
  final double memoryUsageLimit;
  final bool backgroundProcessing;
  final bool autoSleepMode;
  final String storageLocation;
  final int maxStorageSize;
  final bool autoCleanup;
  final Duration cleanupInterval;
  final bool enableLogging;
  final int maxLogFileSize;
  final bool usageAnalytics;
  final bool autoUpdates;
  final Duration updateCheckFrequency;
  final bool betaUpdates;
  final bool autoBackup;
  final Duration backupFrequency;
  final String backupLocation;

  const SystemSettings({
    required this.debugMode,
    required this.logLevel,
    required this.crashReporting,
    required this.analyticsEnabled,
    required this.autoUpdate,
    required this.cacheTimeout,
    required this.maxCacheSize,
    required this.lowPowerMode,
    required this.dataDirectory,
    this.performanceMode = 'balanced',
    this.cpuUsageLimit = 80.0,
    this.memoryUsageLimit = 512.0,
    this.backgroundProcessing = true,
    this.autoSleepMode = false,
    this.storageLocation = 'internal',
    this.maxStorageSize = 1024,
    this.autoCleanup = true,
    this.cleanupInterval = const Duration(days: 7),
    this.enableLogging = true,
    this.maxLogFileSize = 10,
    this.usageAnalytics = false,
    this.autoUpdates = true,
    this.updateCheckFrequency = const Duration(days: 1),
    this.betaUpdates = false,
    this.autoBackup = false,
    this.backupFrequency = const Duration(days: 7),
    this.backupLocation = 'local',
  });

  factory SystemSettings.defaults() {
    return SystemSettings(
      debugMode: false,
      logLevel: 'INFO',
      crashReporting: true,
      analyticsEnabled: false,
      autoUpdate: true,
      cacheTimeout: Duration(hours: 24),
      maxCacheSize: 100 * 1024 * 1024, // 100MB
      lowPowerMode: false,
      dataDirectory: '/data/meshnet',
    );
  }

  SystemSettings copyWith({
    bool? debugMode,
    String? logLevel,
    bool? crashReporting,
    bool? analyticsEnabled,
    bool? autoUpdate,
    Duration? cacheTimeout,
    int? maxCacheSize,
    bool? lowPowerMode,
    String? dataDirectory,
    String? performanceMode,
    double? cpuUsageLimit,
    double? memoryUsageLimit,
    bool? backgroundProcessing,
    bool? autoSleepMode,
    String? storageLocation,
    int? maxStorageSize,
    bool? autoCleanup,
    Duration? cleanupInterval,
    bool? enableLogging,
    int? maxLogFileSize,
    bool? usageAnalytics,
    bool? autoUpdates,
    Duration? updateCheckFrequency,
    bool? betaUpdates,
    bool? autoBackup,
    Duration? backupFrequency,
    String? backupLocation,
  }) {
    return SystemSettings(
      debugMode: debugMode ?? this.debugMode,
      logLevel: logLevel ?? this.logLevel,
      crashReporting: crashReporting ?? this.crashReporting,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      cacheTimeout: cacheTimeout ?? this.cacheTimeout,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      lowPowerMode: lowPowerMode ?? this.lowPowerMode,
      dataDirectory: dataDirectory ?? this.dataDirectory,
      performanceMode: performanceMode ?? this.performanceMode,
      cpuUsageLimit: cpuUsageLimit ?? this.cpuUsageLimit,
      memoryUsageLimit: memoryUsageLimit ?? this.memoryUsageLimit,
      backgroundProcessing: backgroundProcessing ?? this.backgroundProcessing,
      autoSleepMode: autoSleepMode ?? this.autoSleepMode,
      storageLocation: storageLocation ?? this.storageLocation,
      maxStorageSize: maxStorageSize ?? this.maxStorageSize,
      autoCleanup: autoCleanup ?? this.autoCleanup,
      cleanupInterval: cleanupInterval ?? this.cleanupInterval,
      enableLogging: enableLogging ?? this.enableLogging,
      maxLogFileSize: maxLogFileSize ?? this.maxLogFileSize,
      usageAnalytics: usageAnalytics ?? this.usageAnalytics,
      autoUpdates: autoUpdates ?? this.autoUpdates,
      updateCheckFrequency: updateCheckFrequency ?? this.updateCheckFrequency,
      betaUpdates: betaUpdates ?? this.betaUpdates,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupLocation: backupLocation ?? this.backupLocation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debugMode': debugMode,
      'logLevel': logLevel,
      'crashReporting': crashReporting,
      'analyticsEnabled': analyticsEnabled,
      'autoUpdate': autoUpdate,
      'cacheTimeout': cacheTimeout.inMilliseconds,
      'maxCacheSize': maxCacheSize,
      'lowPowerMode': lowPowerMode,
      'dataDirectory': dataDirectory,
      'performanceMode': performanceMode,
      'cpuUsageLimit': cpuUsageLimit,
      'memoryUsageLimit': memoryUsageLimit,
      'backgroundProcessing': backgroundProcessing,
      'autoSleepMode': autoSleepMode,
      'storageLocation': storageLocation,
      'maxStorageSize': maxStorageSize,
      'autoCleanup': autoCleanup,
      'cleanupInterval': cleanupInterval.inMilliseconds,
      'enableLogging': enableLogging,
      'maxLogFileSize': maxLogFileSize,
      'usageAnalytics': usageAnalytics,
      'autoUpdates': autoUpdates,
      'updateCheckFrequency': updateCheckFrequency.inMilliseconds,
      'betaUpdates': betaUpdates,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency.inMilliseconds,
      'backupLocation': backupLocation,
    };
  }

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      debugMode: json['debugMode'] ?? false,
      logLevel: json['logLevel'] ?? 'INFO',
      crashReporting: json['crashReporting'] ?? true,
      analyticsEnabled: json['analyticsEnabled'] ?? false,
      autoUpdate: json['autoUpdate'] ?? true,
      cacheTimeout: Duration(milliseconds: json['cacheTimeout'] ?? 86400000),
      maxCacheSize: json['maxCacheSize'] ?? (100 * 1024 * 1024),
      lowPowerMode: json['lowPowerMode'] ?? false,
      dataDirectory: json['dataDirectory'] ?? '/data/meshnet',
      performanceMode: json['performanceMode'] ?? 'balanced',
      cpuUsageLimit: json['cpuUsageLimit']?.toDouble() ?? 80.0,
      memoryUsageLimit: json['memoryUsageLimit']?.toDouble() ?? 512.0,
      backgroundProcessing: json['backgroundProcessing'] ?? true,
      autoSleepMode: json['autoSleepMode'] ?? false,
      storageLocation: json['storageLocation'] ?? 'internal',
      maxStorageSize: json['maxStorageSize'] ?? 1024,
      autoCleanup: json['autoCleanup'] ?? true,
      cleanupInterval: Duration(milliseconds: json['cleanupInterval'] ?? 604800000),
      enableLogging: json['enableLogging'] ?? true,
      maxLogFileSize: json['maxLogFileSize'] ?? 10,
      usageAnalytics: json['usageAnalytics'] ?? false,
      autoUpdates: json['autoUpdates'] ?? true,
      updateCheckFrequency: Duration(milliseconds: json['updateCheckFrequency'] ?? 86400000),
      betaUpdates: json['betaUpdates'] ?? false,
      autoBackup: json['autoBackup'] ?? false,
      backupFrequency: Duration(milliseconds: json['backupFrequency'] ?? 604800000),
      backupLocation: json['backupLocation'] ?? 'local',
    );
  }
}
