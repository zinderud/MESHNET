// lib/services/ham_radio_manager.dart - Ham Radio Protocols Manager
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Ham Radio protocols manager for APRS, Winlink, and digital modes
/// Supports APRS position reporting, Winlink email, FT8/JS8 modes
class HamRadioManager extends ChangeNotifier {
  static const String DEFAULT_APRS_FREQ = "144.390"; // MHz - APRS frequency
  static const String DEFAULT_WINLINK_FREQ = "14.109"; // MHz - Winlink Pactor
  static const String DEFAULT_FT8_FREQ = "14.074"; // MHz - FT8 frequency
  static const String DEFAULT_JS8_FREQ = "14.078"; // MHz - JS8Call frequency
  
  // Ham Radio Protocol types
  static const Map<String, HamProtocolInfo> SUPPORTED_PROTOCOLS = {
    'aprs': HamProtocolInfo(
      name: 'APRS',
      description: 'Automatic Packet Reporting System',
      frequency: 144.390,
      bandwidth: 1200, // 1200 baud
      icon: '📍',
      mode: 'FM',
      dataFormat: 'AX.25',
    ),
    'winlink': HamProtocolInfo(
      name: 'Winlink',
      description: 'Global Emergency Email Network',
      frequency: 14.109,
      bandwidth: 2400, // 2400 baud
      icon: '📧',
      mode: 'Pactor',
      dataFormat: 'B2F',
    ),
    'ft8': HamProtocolInfo(
      name: 'FT8',
      description: 'Weak Signal Digital Mode',
      frequency: 14.074,
      bandwidth: 50, // 50 Hz
      icon: '📶',
      mode: 'Digital',
      dataFormat: 'FT8',
    ),
    'js8': HamProtocolInfo(
      name: 'JS8Call',
      description: 'Keyboard-to-Keyboard Chat',
      frequency: 14.078,
      bandwidth: 50, // 50 Hz
      icon: '💬',
      mode: 'Digital',
      dataFormat: 'JS8',
    ),
    'psk31': HamProtocolInfo(
      name: 'PSK31',
      description: 'Phase Shift Keying',
      frequency: 14.070,
      bandwidth: 31.25, // 31.25 Hz
      icon: '📟',
      mode: 'Digital',
      dataFormat: 'PSK',
    ),
  };
  
  // Current state
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isTransmitting = false;
  bool _isReceiving = false;
  bool _isAPRSActive = false;
  bool _isWinlinkActive = false;
  
  String _activeProtocol = 'aprs';
  String _callSign = 'MESHNET';
  String _currentFrequency = DEFAULT_APRS_FREQ;
  
  // APRS Data
  final List<APRSMessage> _aprsMessages = [];
  final List<APRSStation> _nearbyStations = [];
  
  // Winlink Data
  final List<WinlinkMessage> _winlinkMessages = [];
  final List<WinlinkGateway> _availableGateways = [];
  
  // Digital Mode Data
  final List<DigitalMessage> _digitalMessages = [];
  final List<DigitalStation> _heardStations = [];
  
  // Ham Radio configuration
  String _maidenheadGrid = 'JN00AA';
  double _transmitPower = 5.0; // Watts
  String _antennaInfo = 'Dipole @ 10m';
  
  // Monitoring
  Timer? _aprsBeaconTimer;
  Timer? _monitoringTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isTransmitting => _isTransmitting;
  bool get isReceiving => _isReceiving;
  bool get isAPRSActive => _isAPRSActive;
  bool get isWinlinkActive => _isWinlinkActive;
  String get activeProtocol => _activeProtocol;
  String get callSign => _callSign;
  String get currentFrequency => _currentFrequency;
  String get maidenheadGrid => _maidenheadGrid;
  double get transmitPower => _transmitPower;
  String get antennaInfo => _antennaInfo;
  
  List<APRSMessage> get aprsMessages => List.unmodifiable(_aprsMessages);
  List<APRSStation> get nearbyStations => List.unmodifiable(_nearbyStations);
  List<WinlinkMessage> get winlinkMessages => List.unmodifiable(_winlinkMessages);
  List<WinlinkGateway> get availableGateways => List.unmodifiable(_availableGateways);
  List<DigitalMessage> get digitalMessages => List.unmodifiable(_digitalMessages);
  List<DigitalStation> get heardStations => List.unmodifiable(_heardStations);
  
  /// Initialize Ham Radio manager
  Future<bool> initialize() async {
    try {
      print('📻 Initializing Ham Radio Manager...');
      
      // In web environment, simulate protocols
      if (kIsWeb) {
        await _simulateHamRadioProtocols();
        print('🌐 Web simulation: Ham Radio protocols simulated');
      } else {
        // On native platforms, connect to real hardware
        await _initializeHamRadioHardware();
      }
      
      // Start monitoring
      _startProtocolMonitoring();
      
      _isInitialized = true;
      print('📻 Ham Radio Manager initialized successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error initializing Ham Radio Manager: $e');
      return false;
    }
  }
  
  /// Simulate Ham Radio protocols for web demo
  Future<void> _simulateHamRadioProtocols() async {
    // Simulate APRS stations
    _addDemoAPRSStations();
    
    // Simulate Winlink gateways
    _addDemoWinlinkGateways();
    
    // Simulate digital mode activity
    _addDemoDigitalActivity();
    
    _isConnected = true;
  }
  
  /// Initialize real Ham Radio hardware (native platforms)
  Future<void> _initializeHamRadioHardware() async {
    // This would integrate with radio hardware
    print('🔧 Connecting to Ham Radio hardware...');
    
    // TODO: Implement hardware integration
    // - CAT control for frequency/mode
    // - Audio interface for digital modes
    // - PTT control for transmission
    // - RIGCTLD integration
    
    await Future.delayed(Duration(seconds: 2));
    print('📱 No Ham Radio hardware found (demo mode)');
  }
  
  /// Add demo APRS stations
  void _addDemoAPRSStations() {
    final demoStations = [
      APRSStation(
        callSign: 'W1AW-1',
        latitude: 41.714775,
        longitude: -72.727260,
        comment: 'ARRL Headquarters',
        lastHeard: DateTime.now().subtract(Duration(minutes: 5)),
        distance: 12.5,
        bearing: 45,
        symbol: '/k', // School symbol
      ),
      APRSStation(
        callSign: 'N0CALL-9',
        latitude: 41.720000,
        longitude: -72.730000,
        comment: 'Mobile station',
        lastHeard: DateTime.now().subtract(Duration(minutes: 2)),
        distance: 3.2,
        bearing: 120,
        symbol: '/>', // Car symbol
      ),
      APRSStation(
        callSign: 'KC1ABC-7',
        latitude: 41.710000,
        longitude: -72.720000,
        comment: 'Weather station',
        lastHeard: DateTime.now().subtract(Duration(minutes: 1)),
        distance: 1.8,
        bearing: 270,
        symbol: '/_', // Weather symbol
      ),
    ];
    
    _nearbyStations.addAll(demoStations);
    
    // Add corresponding APRS messages
    for (var station in demoStations) {
      _aprsMessages.add(APRSMessage(
        id: _generateMessageId(),
        fromCall: station.callSign,
        toCall: 'APRS',
        message: '>${_callSign} Hello from ${station.callSign}!',
        timestamp: station.lastHeard,
        messageType: APRSMessageType.position,
        latitude: station.latitude,
        longitude: station.longitude,
      ));
    }
  }
  
  /// Add demo Winlink gateways
  void _addDemoWinlinkGateways() {
    final demoGateways = [
      WinlinkGateway(
        callSign: 'W1AW-10',
        frequency: 14.109,
        mode: 'Pactor',
        region: 'North America',
        distance: 45.0,
        bearing: 90,
        isActive: true,
        lastHeard: DateTime.now().subtract(Duration(minutes: 10)),
      ),
      WinlinkGateway(
        callSign: 'VE7RCG-10',
        frequency: 14.111,
        mode: 'Pactor',
        region: 'North America',
        distance: 67.0,
        bearing: 315,
        isActive: true,
        lastHeard: DateTime.now().subtract(Duration(minutes: 15)),
      ),
      WinlinkGateway(
        callSign: 'LA2PLA-10',
        frequency: 14.113,
        mode: 'Pactor',
        region: 'Europe',
        distance: 125.0,
        bearing: 45,
        isActive: false,
        lastHeard: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ];
    
    _availableGateways.addAll(demoGateways);
  }
  
  /// Add demo digital mode activity
  void _addDemoDigitalActivity() {
    final digitalStations = [
      DigitalStation(
        callSign: 'FT8BOT',
        frequency: 14.074,
        mode: 'FT8',
        grid: 'JN76TO',
        snr: -12,
        distance: 850.0,
        lastHeard: DateTime.now().subtract(Duration(seconds: 30)),
      ),
      DigitalStation(
        callSign: 'JS8AUTO',
        frequency: 14.078,
        mode: 'JS8',
        grid: 'EM35',
        snr: -8,
        distance: 1250.0,
        lastHeard: DateTime.now().subtract(Duration(minutes: 1)),
      ),
      DigitalStation(
        callSign: 'PSK31DX',
        frequency: 14.070,
        mode: 'PSK31',
        grid: 'JO65',
        snr: 5,
        distance: 650.0,
        lastHeard: DateTime.now().subtract(Duration(minutes: 3)),
      ),
    ];
    
    _heardStations.addAll(digitalStations);
    
    // Add corresponding digital messages
    for (var station in digitalStations) {
      _digitalMessages.add(DigitalMessage(
        id: _generateMessageId(),
        fromCall: station.callSign,
        content: _generateDigitalContent(station.mode),
        mode: station.mode,
        frequency: station.frequency,
        snr: station.snr,
        timestamp: station.lastHeard,
      ));
    }
  }
  
  /// Generate demo digital mode content
  String _generateDigitalContent(String mode) {
    switch (mode) {
      case 'FT8':
        return 'CQ TEST ${_callSign} JN00';
      case 'JS8':
        return '${_callSign}: QRT 73';
      case 'PSK31':
        return 'CQ CQ de ${_callSign} ${_callSign} pse k';
      default:
        return 'Test message from $mode';
    }
  }
  
  /// Start protocol monitoring
  void _startProtocolMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_isConnected) {
        _simulateProtocolActivity();
        notifyListeners();
      }
    });
  }
  
  /// Simulate ongoing protocol activity
  void _simulateProtocolActivity() {
    // Simulate new APRS position reports
    if (_isAPRSActive && DateTime.now().second % 45 == 0) {
      _simulateNewAPRSMessage();
    }
    
    // Simulate digital mode reception
    if (DateTime.now().second % 30 == 0) {
      _simulateDigitalReception();
    }
    
    // Update station distances (simulate movement)
    _updateStationPositions();
  }
  
  /// Simulate new APRS message reception
  void _simulateNewAPRSMessage() {
    final newMessage = APRSMessage(
      id: _generateMessageId(),
      fromCall: 'MOBILE-${DateTime.now().minute % 10}',
      toCall: 'APRS',
      message: '>Emergency traffic on frequency',
      timestamp: DateTime.now(),
      messageType: APRSMessageType.message,
      latitude: 41.715 + (DateTime.now().millisecond % 100) / 10000,
      longitude: -72.728 + (DateTime.now().millisecond % 100) / 10000,
    );
    
    _aprsMessages.insert(0, newMessage);
    
    // Keep only last 50 messages
    if (_aprsMessages.length > 50) {
      _aprsMessages.removeRange(50, _aprsMessages.length);
    }
  }
  
  /// Simulate digital mode reception
  void _simulateDigitalReception() {
    if (_heardStations.isNotEmpty) {
      final station = _heardStations[DateTime.now().minute % _heardStations.length];
      
      final digitalMessage = DigitalMessage(
        id: _generateMessageId(),
        fromCall: station.callSign,
        content: _generateDigitalContent(station.mode),
        mode: station.mode,
        frequency: station.frequency,
        snr: station.snr + (DateTime.now().second % 10 - 5),
        timestamp: DateTime.now(),
      );
      
      _digitalMessages.insert(0, digitalMessage);
      
      // Keep only last 30 messages
      if (_digitalMessages.length > 30) {
        _digitalMessages.removeRange(30, _digitalMessages.length);
      }
    }
  }
  
  /// Update station positions (simulate movement)
  void _updateStationPositions() {
    for (var station in _nearbyStations) {
      if (station.callSign.contains('MOBILE') || station.callSign.contains('-9')) {
        // Update mobile stations
        station.distance += (DateTime.now().second % 5 - 2) * 0.1;
        station.bearing = (station.bearing + DateTime.now().second % 3) % 360;
        station.lastHeard = DateTime.now();
      }
    }
  }
  
  /// Set active protocol
  Future<void> setActiveProtocol(String protocol) async {
    if (SUPPORTED_PROTOCOLS.containsKey(protocol)) {
      _activeProtocol = protocol;
      final protocolInfo = SUPPORTED_PROTOCOLS[protocol]!;
      _currentFrequency = protocolInfo.frequency.toStringAsFixed(3);
      
      print('📻 Switched to ${protocolInfo.name} on ${_currentFrequency} MHz');
      notifyListeners();
    }
  }
  
  /// Start APRS beacon
  Future<void> startAPRSBeacon({required double latitude, required double longitude, String? comment}) async {
    if (!_isConnected) return;
    
    _isAPRSActive = true;
    
    // Create APRS position report
    final aprsMessage = APRSMessage(
      id: _generateMessageId(),
      fromCall: _callSign,
      toCall: 'APRS',
      message: _formatAPRSPosition(latitude, longitude, comment ?? 'MESHNET Emergency Station'),
      timestamp: DateTime.now(),
      messageType: APRSMessageType.position,
      latitude: latitude,
      longitude: longitude,
    );
    
    _aprsMessages.insert(0, aprsMessage);
    
    // Start periodic beacon (every 10 minutes)
    _aprsBeaconTimer = Timer.periodic(Duration(minutes: 10), (timer) {
      if (_isAPRSActive) {
        final beaconMessage = APRSMessage(
          id: _generateMessageId(),
          fromCall: _callSign,
          toCall: 'APRS',
          message: _formatAPRSPosition(latitude, longitude, comment ?? 'MESHNET Beacon'),
          timestamp: DateTime.now(),
          messageType: APRSMessageType.position,
          latitude: latitude,
          longitude: longitude,
        );
        
        _aprsMessages.insert(0, beaconMessage);
        notifyListeners();
      }
    });
    
    print('📍 APRS beacon started at ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}');
    notifyListeners();
  }
  
  /// Stop APRS beacon
  void stopAPRSBeacon() {
    _isAPRSActive = false;
    _aprsBeaconTimer?.cancel();
    print('📍 APRS beacon stopped');
    notifyListeners();
  }
  
  /// Send APRS message
  Future<bool> sendAPRSMessage(String toCall, String message) async {
    if (!_isConnected) return false;
    
    try {
      _isTransmitting = true;
      notifyListeners();
      
      final aprsMessage = APRSMessage(
        id: _generateMessageId(),
        fromCall: _callSign,
        toCall: toCall,
        message: message,
        timestamp: DateTime.now(),
        messageType: APRSMessageType.message,
      );
      
      // Simulate transmission delay
      await Future.delayed(Duration(seconds: 2));
      
      _aprsMessages.insert(0, aprsMessage);
      
      _isTransmitting = false;
      print('📤 APRS message sent to $toCall: $message');
      notifyListeners();
      
      return true;
    } catch (e) {
      _isTransmitting = false;
      print('❌ Failed to send APRS message: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Send Winlink email
  Future<bool> sendWinlinkEmail(String to, String subject, String body) async {
    if (!_isConnected) return false;
    
    try {
      _isTransmitting = true;
      notifyListeners();
      
      final winlinkMessage = WinlinkMessage(
        id: _generateMessageId(),
        from: '${_callSign}@winlink.org',
        to: to,
        subject: subject,
        body: body,
        timestamp: DateTime.now(),
        direction: MessageDirection.sent,
        gateway: _availableGateways.isNotEmpty ? _availableGateways.first.callSign : 'AUTO',
      );
      
      // Simulate transmission delay
      await Future.delayed(Duration(seconds: 5));
      
      _winlinkMessages.insert(0, winlinkMessage);
      
      _isTransmitting = false;
      print('📧 Winlink email sent to $to: $subject');
      notifyListeners();
      
      return true;
    } catch (e) {
      _isTransmitting = false;
      print('❌ Failed to send Winlink email: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Format APRS position report
  String _formatAPRSPosition(double latitude, double longitude, String comment) {
    // Convert to APRS format (simplified)
    final latDeg = latitude.abs().floor();
    final latMin = (latitude.abs() - latDeg) * 60;
    final latDir = latitude >= 0 ? 'N' : 'S';
    
    final lonDeg = longitude.abs().floor();
    final lonMin = (longitude.abs() - lonDeg) * 60;
    final lonDir = longitude >= 0 ? 'E' : 'W';
    
    return '=${latDeg.toString().padLeft(2, '0')}${latMin.toStringAsFixed(2).padLeft(5, '0')}$latDir/'
           '${lonDeg.toString().padLeft(3, '0')}${lonMin.toStringAsFixed(2).padLeft(5, '0')}${lonDir}> $comment';
  }
  
  /// Generate message ID
  String _generateMessageId() {
    return 'HAM_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }
  
  /// Set call sign
  void setCallSign(String callSign) {
    _callSign = callSign.toUpperCase();
    print('📻 Call sign set to $_callSign');
    notifyListeners();
  }
  
  /// Set Maidenhead grid locator
  void setMaidenheadGrid(String grid) {
    _maidenheadGrid = grid.toUpperCase();
    print('📍 Grid locator set to $_maidenheadGrid');
    notifyListeners();
  }
  
  /// Set transmit power
  void setTransmitPower(double watts) {
    _transmitPower = watts;
    print('🔋 Transmit power set to ${_transmitPower}W');
    notifyListeners();
  }
  
  /// Get protocol info
  HamProtocolInfo? getProtocolInfo(String protocol) {
    return SUPPORTED_PROTOCOLS[protocol];
  }
  
  @override
  void dispose() {
    _aprsBeaconTimer?.cancel();
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

/// Ham Radio protocol information
class HamProtocolInfo {
  final String name;
  final String description;
  final double frequency;
  final double bandwidth;
  final String icon;
  final String mode;
  final String dataFormat;
  
  const HamProtocolInfo({
    required this.name,
    required this.description,
    required this.frequency,
    required this.bandwidth,
    required this.icon,
    required this.mode,
    required this.dataFormat,
  });
}

/// APRS Message
class APRSMessage {
  final String id;
  final String fromCall;
  final String toCall;
  final String message;
  final DateTime timestamp;
  final APRSMessageType messageType;
  final double? latitude;
  final double? longitude;
  
  APRSMessage({
    required this.id,
    required this.fromCall,
    required this.toCall,
    required this.message,
    required this.timestamp,
    required this.messageType,
    this.latitude,
    this.longitude,
  });
  
  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// APRS Station
class APRSStation {
  final String callSign;
  double latitude;
  double longitude;
  final String comment;
  DateTime lastHeard;
  double distance;
  int bearing;
  final String symbol;
  
  APRSStation({
    required this.callSign,
    required this.latitude,
    required this.longitude,
    required this.comment,
    required this.lastHeard,
    required this.distance,
    required this.bearing,
    required this.symbol,
  });
}

/// Winlink Message
class WinlinkMessage {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime timestamp;
  final MessageDirection direction;
  final String gateway;
  
  WinlinkMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.timestamp,
    required this.direction,
    required this.gateway,
  });
  
  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Winlink Gateway
class WinlinkGateway {
  final String callSign;
  final double frequency;
  final String mode;
  final String region;
  final double distance;
  final int bearing;
  final bool isActive;
  final DateTime lastHeard;
  
  WinlinkGateway({
    required this.callSign,
    required this.frequency,
    required this.mode,
    required this.region,
    required this.distance,
    required this.bearing,
    required this.isActive,
    required this.lastHeard,
  });
}

/// Digital Message
class DigitalMessage {
  final String id;
  final String fromCall;
  final String content;
  final String mode;
  final double frequency;
  final int snr;
  final DateTime timestamp;
  
  DigitalMessage({
    required this.id,
    required this.fromCall,
    required this.content,
    required this.mode,
    required this.frequency,
    required this.snr,
    required this.timestamp,
  });
  
  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Digital Station
class DigitalStation {
  final String callSign;
  final double frequency;
  final String mode;
  final String grid;
  int snr;
  final double distance;
  DateTime lastHeard;
  
  DigitalStation({
    required this.callSign,
    required this.frequency,
    required this.mode,
    required this.grid,
    required this.snr,
    required this.distance,
    required this.lastHeard,
  });
}

/// Message enums
enum APRSMessageType {
  position,
  message,
  weather,
  status,
}

enum MessageDirection {
  sent,
  received,
}
