// lib/services/emergency_manager.dart - Emergency Management System
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'bluetooth_mesh_manager.dart';
import 'location_manager.dart';
import 'wifi_direct_manager.dart';
import 'sdr_manager.dart';
import 'ham_radio_manager.dart';
import 'emergency_detection_service.dart';
import 'priority_message_service.dart';
import 'emergency_wipe_service.dart';

/// Emergency Management System
/// Coordinates all communication protocols for emergency situations
class EmergencyManager extends ChangeNotifier {
  // Emergency severity levels
  static const Map<EmergencyLevel, EmergencyLevelInfo> EMERGENCY_LEVELS = {
    EmergencyLevel.info: EmergencyLevelInfo(
      name: 'Bilgi',
      color: 0xFF2196F3,
      priority: 1,
      icon: 'ℹ️',
      autoActivate: false,
    ),
    EmergencyLevel.warning: EmergencyLevelInfo(
      name: 'Uyarı',
      color: 0xFFFF9800,
      priority: 2,
      icon: '⚠️',
      autoActivate: false,
    ),
    EmergencyLevel.alert: EmergencyLevelInfo(
      name: 'Alarm',
      color: 0xFFFF5722,
      priority: 3,
      icon: '🚨',
      autoActivate: true,
    ),
    EmergencyLevel.critical: EmergencyLevelInfo(
      name: 'Kritik',
      color: 0xFFF44336,
      priority: 4,
      icon: '🆘',
      autoActivate: true,
    ),
    EmergencyLevel.disaster: EmergencyLevelInfo(
      name: 'Felaket',
      color: 0xFF9C27B0,
      priority: 5,
      icon: '💀',
      autoActivate: true,
    ),
  };

  // Emergency types
  static const Map<EmergencyType, EmergencyTypeInfo> EMERGENCY_TYPES = {
    EmergencyType.medical: EmergencyTypeInfo(
      name: 'Tıbbi Acil Durum',
      icon: '🏥',
      description: 'Sağlık acil durumu',
      requiredProtocols: ['bluetooth', 'gps', 'ham_radio'],
    ),
    EmergencyType.fire: EmergencyTypeInfo(
      name: 'Yangın',
      icon: '🔥',
      description: 'Yangın acil durumu',
      requiredProtocols: ['wifi_direct', 'sdr', 'gps'],
    ),
    EmergencyType.earthquake: EmergencyTypeInfo(
      name: 'Deprem',
      icon: '🌍',
      description: 'Doğal afet - Deprem',
      requiredProtocols: ['ham_radio', 'sdr', 'gps'],
    ),
    EmergencyType.flood: EmergencyTypeInfo(
      name: 'Sel',
      icon: '🌊',
      description: 'Doğal afet - Sel',
      requiredProtocols: ['bluetooth', 'wifi_direct', 'gps'],
    ),
    EmergencyType.accident: EmergencyTypeInfo(
      name: 'Kaza',
      icon: '🚗',
      description: 'Trafik kazası',
      requiredProtocols: ['bluetooth', 'gps'],
    ),
    EmergencyType.security: EmergencyTypeInfo(
      name: 'Güvenlik',
      icon: '🚨',
      description: 'Güvenlik acil durumu',
      requiredProtocols: ['bluetooth', 'wifi_direct', 'sdr'],
    ),
    EmergencyType.infrastructure: EmergencyTypeInfo(
      name: 'Altyapı',
      icon: '⚡',
      description: 'Altyapı arızası',
      requiredProtocols: ['ham_radio', 'sdr'],
    ),
    EmergencyType.communication: EmergencyTypeInfo(
      name: 'İletişim',
      icon: '📡',
      description: 'İletişim kesintisi',
      requiredProtocols: ['ham_radio', 'sdr', 'wifi_direct'],
    ),
  };

  // Managers
  BluetoothMeshManager? _bluetoothManager;
  LocationManager? _locationManager;
  WiFiDirectManager? _wifiDirectManager;
  SDRManager? _sdrManager;
  HamRadioManager? _hamRadioManager;
  
  // Emergency services
  EmergencyDetectionService? _detectionService;
  PriorityMessageService? _priorityMessageService;
  EmergencyWipeService? _wipeService;

  // Emergency state
  bool _isEmergencyMode = false;
  bool _isBeaconActive = false;
  bool _isAutoMode = false;
  EmergencyLevel _currentLevel = EmergencyLevel.info;
  EmergencyType _currentType = EmergencyType.medical;
  
  // Emergency data
  final List<EmergencyEvent> _emergencyEvents = [];
  final List<EmergencyMessage> _emergencyMessages = [];
  final Map<String, EmergencyBeacon> _activeBeacons = {};
  
  // Timers
  Timer? _beaconTimer;
  Timer? _monitoringTimer;
  Timer? _escalationTimer;
  
  // Emergency contacts
  final List<EmergencyContact> _emergencyContacts = [];
  
  // Configuration
  Duration _beaconInterval = Duration(minutes: 5);
  Duration _escalationTimeout = Duration(minutes: 15);
  bool _enableAutoEscalation = true;
  bool _enableMultiProtocol = true;
  
  // Getters
  bool get isEmergencyMode => _isEmergencyMode;
  bool get isBeaconActive => _isBeaconActive;
  bool get isAutoMode => _isAutoMode;
  EmergencyLevel get currentLevel => _currentLevel;
  EmergencyType get currentType => _currentType;
  List<EmergencyEvent> get emergencyEvents => List.unmodifiable(_emergencyEvents);
  List<EmergencyMessage> get emergencyMessages => List.unmodifiable(_emergencyMessages);
  Map<String, EmergencyBeacon> get activeBeacons => Map.unmodifiable(_activeBeacons);
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);
  Duration get beaconInterval => _beaconInterval;
  bool get enableAutoEscalation => _enableAutoEscalation;
  bool get enableMultiProtocol => _enableMultiProtocol;
  
  // Emergency service getters
  EmergencyDetectionService? get detectionService => _detectionService;
  PriorityMessageService? get priorityMessageService => _priorityMessageService;
  EmergencyWipeService? get wipeService => _wipeService;

  /// Initialize Emergency Manager
  Future<bool> initialize({
    BluetoothMeshManager? bluetoothManager,
    LocationManager? locationManager,
    WiFiDirectManager? wifiDirectManager,
    SDRManager? sdrManager,
    HamRadioManager? hamRadioManager,
  }) async {
    try {
      print('🚨 Initializing Emergency Manager...');
      
      // Store manager references if provided
      if (bluetoothManager != null) _bluetoothManager = bluetoothManager;
      if (locationManager != null) _locationManager = locationManager;
      if (wifiDirectManager != null) _wifiDirectManager = wifiDirectManager;
      if (sdrManager != null) _sdrManager = sdrManager;
      if (hamRadioManager != null) _hamRadioManager = hamRadioManager;
      
      // Initialize emergency services
      await _initializeEmergencyServices();
      
      // Initialize default emergency contacts
      _initializeDefaultContacts();
      
      // Start emergency monitoring
      _startEmergencyMonitoring();
      
      print('🚨 Emergency Manager initialized successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error initializing Emergency Manager: $e');
      return false;
    }
  }
  
  /// Set manager references for coordination
  void setManagers({
    BluetoothMeshManager? bluetoothManager,
    LocationManager? locationManager,
    WiFiDirectManager? wifiManager,
    SDRManager? sdrManager,
    HamRadioManager? hamRadioManager,
  }) {
    if (bluetoothManager != null) _bluetoothManager = bluetoothManager;
    if (locationManager != null) _locationManager = locationManager;
    if (wifiManager != null) _wifiDirectManager = wifiManager;
    if (sdrManager != null) _sdrManager = sdrManager;
    if (hamRadioManager != null) _hamRadioManager = hamRadioManager;
    
    print('🔗 Emergency Manager connected to ${[
      if (_bluetoothManager != null) 'Bluetooth',
      if (_locationManager != null) 'GPS',
      if (_wifiDirectManager != null) 'WiFi',
      if (_sdrManager != null) 'SDR',
      if (_hamRadioManager != null) 'Ham Radio',
    ].join(', ')} managers');
    
    notifyListeners();
  }

  /// Initialize emergency services
  Future<void> _initializeEmergencyServices() async {
    try {
      // Initialize emergency detection service
      _detectionService = EmergencyDetectionService();
      await _detectionService!.initialize(locationManager: _locationManager);
      
      // Initialize priority message service
      _priorityMessageService = PriorityMessageService();
      await _priorityMessageService!.initialize();
      
      // Add message processors
      _priorityMessageService!.addProcessor(BluetoothMessageProcessor());
      _priorityMessageService!.addProcessor(WiFiDirectMessageProcessor());
      _priorityMessageService!.addProcessor(SDRMessageProcessor());
      _priorityMessageService!.addProcessor(HamRadioMessageProcessor());
      
      // Initialize emergency wipe service
      _wipeService = EmergencyWipeService();
      await _wipeService!.initialize();
      
      print('🚨 Emergency services initialized');
    } catch (e) {
      print('❌ Error initializing emergency services: $e');
    }
  }

  /// Initialize default emergency contacts
  void _initializeDefaultContacts() {
    _emergencyContacts.addAll([
      EmergencyContact(
        id: 'emergency_112',
        name: '112 Acil Çağrı',
        type: ContactType.official,
        protocols: ['ham_radio', 'sdr'],
        frequency: '446.00625',
        callSign: 'EMRGNCY112',
        isActive: true,
      ),
      EmergencyContact(
        id: 'fire_department',
        name: 'İtfaiye',
        type: ContactType.fire,
        protocols: ['bluetooth', 'wifi_direct'],
        callSign: 'FIRE-DEPT',
        isActive: true,
      ),
      EmergencyContact(
        id: 'medical_emergency',
        name: 'Sağlık Ekipleri',
        type: ContactType.medical,
        protocols: ['ham_radio', 'bluetooth'],
        frequency: '145.500',
        callSign: 'MEDICAL-1',
        isActive: true,
      ),
      EmergencyContact(
        id: 'search_rescue',
        name: 'Arama Kurtarma',
        type: ContactType.rescue,
        protocols: ['sdr', 'ham_radio'],
        frequency: '433.500',
        callSign: 'SAR-TEAM',
        isActive: true,
      ),
    ]);
  }

  /// Start emergency monitoring
  void _startEmergencyMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _monitorEmergencyConditions();
    });
  }

  /// Monitor for automatic emergency activation
  void _monitorEmergencyConditions() {
    if (!_isAutoMode) return;

    // Check for automatic emergency triggers
    _checkLocationBasedEmergencies();
    _checkCommunicationFailures();
    _checkEnvironmentalConditions();
  }

  /// Check for location-based emergencies
  void _checkLocationBasedEmergencies() {
    if (_locationManager == null) return;

    // Simulate emergency detection based on location changes
    // In real implementation, this would analyze GPS data, accelerometer, etc.
    final now = DateTime.now();
    if (now.second % 120 == 0) { // Every 2 minutes for demo
      _triggerLocationBasedEmergency();
    }
  }

  /// Trigger location-based emergency
  void _triggerLocationBasedEmergency() {
    final event = EmergencyEvent(
      id: _generateEventId(),
      type: EmergencyType.accident,
      level: EmergencyLevel.alert,
      timestamp: DateTime.now(),
      location: EmergencyLocation(
        latitude: 41.714775,
        longitude: -72.727260,
        accuracy: 5.0,
        address: 'Demo Location - Auto Emergency',
      ),
      description: 'Otomatik acil durum tespiti: Anormal hareket algılandı',
      isAutoTriggered: true,
    );

    _addEmergencyEvent(event);
    
    if (_enableAutoEscalation) {
      activateEmergencyMode(event.type, event.level);
    }
  }

  /// Check for communication failures
  void _checkCommunicationFailures() {
    // Monitor communication protocol health
    bool hasConnection = false;
    
    if (_bluetoothManager?.isConnected == true) hasConnection = true;
    if (_wifiDirectManager?.isConnected == true) hasConnection = true;
    if (_sdrManager?.isConnected == true) hasConnection = true;
    if (_hamRadioManager?.isConnected == true) hasConnection = true;

    // If all communications fail, trigger emergency
    if (!hasConnection && DateTime.now().minute % 30 == 0) {
      final event = EmergencyEvent(
        id: _generateEventId(),
        type: EmergencyType.communication,
        level: EmergencyLevel.warning,
        timestamp: DateTime.now(),
        description: 'İletişim protokolleri kesintiye uğradı',
        isAutoTriggered: true,
      );

      _addEmergencyEvent(event);
    }
  }

  /// Check environmental conditions
  void _checkEnvironmentalConditions() {
    // Simulate environmental emergency detection
    // In real implementation, this would connect to sensors
    final now = DateTime.now();
    if (now.hour == 12 && now.minute == 0 && now.second < 5) { // Demo trigger
      _triggerEnvironmentalEmergency();
    }
  }

  /// Trigger environmental emergency
  void _triggerEnvironmentalEmergency() {
    final event = EmergencyEvent(
      id: _generateEventId(),
      type: EmergencyType.earthquake,
      level: EmergencyLevel.critical,
      timestamp: DateTime.now(),
      location: EmergencyLocation(
        latitude: 41.714775,
        longitude: -72.727260,
        accuracy: 10.0,
        address: 'Demo Bölge - Çevresel Acil Durum',
      ),
      description: 'Çevresel sensörler anormal veri bildirdi',
      isAutoTriggered: true,
    );

    _addEmergencyEvent(event);
    
    if (_enableAutoEscalation) {
      activateEmergencyMode(event.type, event.level);
    }
  }

  /// Activate emergency mode
  Future<void> activateEmergencyMode(EmergencyType type, EmergencyLevel level) async {
    _isEmergencyMode = true;
    _currentType = type;
    _currentLevel = level;

    print('🚨 Emergency mode activated: ${EMERGENCY_TYPES[type]?.name} - ${EMERGENCY_LEVELS[level]?.name}');

    // Start emergency beacon
    await startEmergencyBeacon();

    // Activate required protocols
    await _activateRequiredProtocols();

    // Send emergency alerts
    await _sendEmergencyAlerts();

    // Start escalation timer if auto-escalation is enabled
    if (_enableAutoEscalation) {
      _startEscalationTimer();
    }

    notifyListeners();
  }

  /// Start emergency beacon
  Future<void> startEmergencyBeacon() async {
    if (_isBeaconActive) return;

    _isBeaconActive = true;
    
    print('📡 Starting emergency beacon...');

    _beaconTimer = Timer.periodic(_beaconInterval, (timer) async {
      await _broadcastEmergencyBeacon();
    });

    // Immediate first broadcast
    await _broadcastEmergencyBeacon();

    notifyListeners();
  }

  /// Broadcast emergency beacon
  Future<void> _broadcastEmergencyBeacon() async {
    final beaconData = EmergencyBeacon(
      id: _generateBeaconId(),
      type: _currentType,
      level: _currentLevel,
      timestamp: DateTime.now(),
      location: await _getCurrentLocation(),
      protocols: _getActiveProtocols(),
      message: _generateBeaconMessage(),
    );

    _activeBeacons[beaconData.id] = beaconData;

    // Broadcast via all available protocols
    if (_enableMultiProtocol) {
      await _broadcastViaAllProtocols(beaconData);
    } else {
      await _broadcastViaPrimaryProtocol(beaconData);
    }

    // Clean old beacons
    _cleanOldBeacons();

    notifyListeners();
  }

  /// Broadcast via all available protocols
  Future<void> _broadcastViaAllProtocols(EmergencyBeacon beacon) async {
    final message = beacon.toMessageString();

    // Bluetooth Mesh
    if (_bluetoothManager?.isConnected == true) {
      await _bluetoothManager?.sendMessage(message);
    }

    // WiFi Direct
    if (_wifiDirectManager?.isConnected == true) {
      await _wifiDirectManager?.broadcastMessage(message);
    }

    // SDR
    if (_sdrManager?.isConnected == true) {
      await _sdrManager?.transmitMessage(message, frequency: 446.00625);
    }

    // Ham Radio (APRS)
    if (_hamRadioManager?.isConnected == true) {
      await _hamRadioManager?.sendAPRSMessage('EMERGENCY', message);
    }
  }

  /// Broadcast via primary protocol
  Future<void> _broadcastViaPrimaryProtocol(EmergencyBeacon beacon) async {
    final requiredProtocols = EMERGENCY_TYPES[_currentType]?.requiredProtocols ?? [];
    
    for (String protocol in requiredProtocols) {
      switch (protocol) {
        case 'bluetooth':
          if (_bluetoothManager?.isConnected == true) {
            await _bluetoothManager?.sendMessage(beacon.toMessageString());
            return;
          }
          break;
        case 'wifi_direct':
          if (_wifiDirectManager?.isConnected == true) {
            await _wifiDirectManager?.broadcastMessage(beacon.toMessageString());
            return;
          }
          break;
        case 'sdr':
          if (_sdrManager?.isConnected == true) {
            await _sdrManager?.transmitMessage(beacon.toMessageString());
            return;
          }
          break;
        case 'ham_radio':
          if (_hamRadioManager?.isConnected == true) {
            await _hamRadioManager?.sendAPRSMessage('EMERGENCY', beacon.toMessageString());
            return;
          }
          break;
      }
    }
  }

  /// Activate required protocols for emergency type
  Future<void> _activateRequiredProtocols() async {
    final requiredProtocols = EMERGENCY_TYPES[_currentType]?.requiredProtocols ?? [];

    for (String protocol in requiredProtocols) {
      switch (protocol) {
        case 'bluetooth':
          await _bluetoothManager?.initialize();
          break;
        case 'wifi_direct':
          await _wifiDirectManager?.initialize();
          break;
        case 'sdr':
          await _sdrManager?.initialize();
          break;
        case 'ham_radio':
          await _hamRadioManager?.initialize();
          break;
        case 'gps':
          await _locationManager?.initialize();
          break;
      }
    }
  }

  /// Send emergency alerts to contacts
  Future<void> _sendEmergencyAlerts() async {
    final relevantContacts = _emergencyContacts.where((contact) {
      return contact.isActive && 
             contact.type.toString().contains(_currentType.toString().split('.').last);
    });

    for (var contact in relevantContacts) {
      await _sendEmergencyAlert(contact);
    }
  }

  /// Send emergency alert to specific contact
  Future<void> _sendEmergencyAlert(EmergencyContact contact) async {
    final alertMessage = EmergencyMessage(
      id: _generateMessageId(),
      type: _currentType,
      level: _currentLevel,
      timestamp: DateTime.now(),
      from: 'MESHNET-EMERGENCY',
      to: contact.callSign,
      content: _generateAlertMessage(contact),
      protocols: contact.protocols,
    );

    _emergencyMessages.add(alertMessage);

    // Send via contact's preferred protocols
    for (String protocol in contact.protocols) {
      await _sendViaProtocol(protocol, alertMessage, contact);
    }
  }

  /// Send message via specific protocol
  Future<void> _sendViaProtocol(String protocol, EmergencyMessage message, EmergencyContact contact) async {
    switch (protocol) {
      case 'bluetooth':
        await _bluetoothManager?.sendMessage(message.content);
        break;
      case 'wifi_direct':
        await _wifiDirectManager?.broadcastMessage(message.content);
        break;
      case 'sdr':
        final freq = double.tryParse(contact.frequency ?? '446.00625') ?? 446.00625;
        await _sdrManager?.transmitMessage(message.content, frequency: freq);
        break;
      case 'ham_radio':
        await _hamRadioManager?.sendAPRSMessage(contact.callSign, message.content);
        break;
    }
  }

  /// Generate beacon message
  String _generateBeaconMessage() {
    final typeInfo = EMERGENCY_TYPES[_currentType];
    final levelInfo = EMERGENCY_LEVELS[_currentLevel];
    
    return '🚨 MESHNET EMERGENCY BEACON 🚨\n'
           'Type: ${typeInfo?.icon} ${typeInfo?.name}\n'
           'Level: ${levelInfo?.icon} ${levelInfo?.name}\n'
           'Time: ${DateTime.now().toIso8601String()}\n'
           'Status: ACTIVE';
  }

  /// Generate alert message for contact
  String _generateAlertMessage(EmergencyContact contact) {
    final typeInfo = EMERGENCY_TYPES[_currentType];
    final levelInfo = EMERGENCY_LEVELS[_currentLevel];
    
    return '🚨 MESHNET EMERGENCY ALERT\n'
           'To: ${contact.name}\n'
           'Emergency: ${typeInfo?.icon} ${typeInfo?.name}\n'
           'Severity: ${levelInfo?.icon} ${levelInfo?.name}\n'
           'Immediate response required\n'
           'Timestamp: ${DateTime.now().toIso8601String()}';
  }

  /// Start escalation timer
  void _startEscalationTimer() {
    _escalationTimer = Timer(_escalationTimeout, () {
      _escalateEmergency();
    });
  }

  /// Escalate emergency level
  void _escalateEmergency() {
    final currentPriority = EMERGENCY_LEVELS[_currentLevel]?.priority ?? 1;
    
    // Find next level
    EmergencyLevel? nextLevel;
    for (var level in EMERGENCY_LEVELS.keys) {
      final levelPriority = EMERGENCY_LEVELS[level]?.priority ?? 1;
      if (levelPriority == currentPriority + 1) {
        nextLevel = level;
        break;
      }
    }

    if (nextLevel != null) {
      _currentLevel = nextLevel;
      print('🚨 Emergency escalated to: ${EMERGENCY_LEVELS[nextLevel]?.name}');
      
      // Restart escalation timer for next level
      if (_currentLevel != EmergencyLevel.disaster) {
        _startEscalationTimer();
      }
      
      notifyListeners();
    }
  }

  /// Deactivate emergency mode
  Future<void> deactivateEmergencyMode() async {
    _isEmergencyMode = false;
    _isBeaconActive = false;
    _currentLevel = EmergencyLevel.info;

    _beaconTimer?.cancel();
    _escalationTimer?.cancel();

    _activeBeacons.clear();

    print('✅ Emergency mode deactivated');
    notifyListeners();
  }

  /// Add emergency event
  void _addEmergencyEvent(EmergencyEvent event) {
    _emergencyEvents.insert(0, event);
    
    // Keep only last 100 events
    if (_emergencyEvents.length > 100) {
      _emergencyEvents.removeRange(100, _emergencyEvents.length);
    }
    
    notifyListeners();
  }

  /// Get current location
  Future<EmergencyLocation?> _getCurrentLocation() async {
    if (_locationManager == null) return null;

    // In real implementation, get actual GPS coordinates
    return EmergencyLocation(
      latitude: 41.714775,
      longitude: -72.727260,
      accuracy: 5.0,
      address: 'Current Emergency Location',
    );
  }

  /// Get active protocols
  List<String> _getActiveProtocols() {
    List<String> active = [];
    
    if (_bluetoothManager?.isConnected == true) active.add('bluetooth');
    if (_wifiDirectManager?.isConnected == true) active.add('wifi_direct');
    if (_sdrManager?.isConnected == true) active.add('sdr');
    if (_hamRadioManager?.isConnected == true) active.add('ham_radio');
    
    return active;
  }

  /// Clean old beacons
  void _cleanOldBeacons() {
    final cutoff = DateTime.now().subtract(Duration(hours: 1));
    _activeBeacons.removeWhere((key, beacon) => beacon.timestamp.isBefore(cutoff));
  }

  /// Generate unique IDs
  String _generateEventId() => 'EVENT_${DateTime.now().millisecondsSinceEpoch}';
  String _generateBeaconId() => 'BEACON_${DateTime.now().millisecondsSinceEpoch}';
  String _generateMessageId() => 'MSG_${DateTime.now().millisecondsSinceEpoch}';

  /// Configuration setters
  void setBeaconInterval(Duration interval) {
    _beaconInterval = interval;
    notifyListeners();
  }

  void setAutoEscalation(bool enabled) {
    _enableAutoEscalation = enabled;
    notifyListeners();
  }

  void setMultiProtocol(bool enabled) {
    _enableMultiProtocol = enabled;
    notifyListeners();
  }

  void setAutoMode(bool enabled) {
    _isAutoMode = enabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _beaconTimer?.cancel();
    _monitoringTimer?.cancel();
    _escalationTimer?.cancel();
    super.dispose();
  }
}

/// Emergency event
class EmergencyEvent {
  final String id;
  final EmergencyType type;
  final EmergencyLevel level;
  final DateTime timestamp;
  final EmergencyLocation? location;
  final String description;
  final bool isAutoTriggered;

  EmergencyEvent({
    required this.id,
    required this.type,
    required this.level,
    required this.timestamp,
    this.location,
    required this.description,
    this.isAutoTriggered = false,
  });
}

/// Emergency beacon
class EmergencyBeacon {
  final String id;
  final EmergencyType type;
  final EmergencyLevel level;
  final DateTime timestamp;
  final EmergencyLocation? location;
  final List<String> protocols;
  final String message;

  EmergencyBeacon({
    required this.id,
    required this.type,
    required this.level,
    required this.timestamp,
    this.location,
    required this.protocols,
    required this.message,
  });

  String toMessageString() {
    return 'EMERGENCY_BEACON:$id:${type.toString().split('.').last}:'
           '${level.toString().split('.').last}:${timestamp.toIso8601String()}:'
           '${location?.latitude ?? 0}:${location?.longitude ?? 0}:$message';
  }
}

/// Emergency message
class EmergencyMessage {
  final String id;
  final EmergencyType type;
  final EmergencyLevel level;
  final DateTime timestamp;
  final String from;
  final String to;
  final String content;
  final List<String> protocols;

  EmergencyMessage({
    required this.id,
    required this.type,
    required this.level,
    required this.timestamp,
    required this.from,
    required this.to,
    required this.content,
    required this.protocols,
  });
}

/// Emergency contact
class EmergencyContact {
  final String id;
  final String name;
  final ContactType type;
  final List<String> protocols;
  final String? frequency;
  final String callSign;
  final bool isActive;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.type,
    required this.protocols,
    this.frequency,
    required this.callSign,
    required this.isActive,
  });
}

/// Emergency location
class EmergencyLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
  final DateTime timestamp;

  EmergencyLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory EmergencyLocation.fromJson(Map<String, dynamic> json) {
    return EmergencyLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Emergency level info
class EmergencyLevelInfo {
  final String name;
  final int color;
  final int priority;
  final String icon;
  final bool autoActivate;

  const EmergencyLevelInfo({
    required this.name,
    required this.color,
    required this.priority,
    required this.icon,
    required this.autoActivate,
  });
}

/// Emergency type info
class EmergencyTypeInfo {
  final String name;
  final String icon;
  final String description;
  final List<String> requiredProtocols;

  const EmergencyTypeInfo({
    required this.name,
    required this.icon,
    required this.description,
    required this.requiredProtocols,
  });
}

/// Emergency enums
enum EmergencyLevel {
  info,
  warning,
  alert,
  critical,
  disaster,
}

enum EmergencyType {
  medical,
  fire,
  earthquake,
  flood,
  accident,
  security,
  infrastructure,
  communication,
}

enum ContactType {
  official,
  medical,
  fire,
  rescue,
  police,
  family,
  friend,
}
