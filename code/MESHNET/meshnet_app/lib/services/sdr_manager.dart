// lib/services/sdr_manager.dart - Software Defined Radio Manager
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Software Defined Radio manager for long-range communication
/// Supports RTL-SDR, HackRF, and other SDR devices
class SDRManager extends ChangeNotifier {
  static const String DEFAULT_FREQUENCY = "433.92"; // MHz - ISM band
  static const String EMERGENCY_FREQUENCY = "446.00"; // MHz - PMR446
  static const int DEFAULT_SAMPLE_RATE = 2048000; // 2.048 MHz
  static const int DEFAULT_BANDWIDTH = 250000; // 250 kHz
  
  // SDR Device types
  static const Map<String, SDRDeviceInfo> SUPPORTED_DEVICES = {
    'rtl_sdr': SDRDeviceInfo(
      name: 'RTL-SDR',
      minFreq: 24.0,
      maxFreq: 1766.0,
      maxSampleRate: 3200000,
      icon: '📻',
      description: 'RTL2832U based USB dongle',
    ),
    'hackrf': SDRDeviceInfo(
      name: 'HackRF One',
      minFreq: 1.0,
      maxFreq: 6000.0,
      maxSampleRate: 20000000,
      icon: '📡',
      description: 'Half-duplex transceiver',
    ),
    'airspy': SDRDeviceInfo(
      name: 'Airspy',
      minFreq: 24.0,
      maxFreq: 1800.0,
      maxSampleRate: 10000000,
      icon: '📶',
      description: 'High-performance receiver',
    ),
    'limesdr': SDRDeviceInfo(
      name: 'LimeSDR',
      minFreq: 100.0,
      maxFreq: 3800.0,
      maxSampleRate: 61440000,
      icon: '🔬',
      description: 'Full-duplex transceiver',
    ),
  };
  
  // Current state
  bool _isConnected = false;
  bool _isTransmitting = false;
  bool _isReceiving = false;
  bool _isScanning = false;
  
  String _currentFrequency = DEFAULT_FREQUENCY;
  int _currentSampleRate = DEFAULT_SAMPLE_RATE;
  String _selectedDevice = 'rtl_sdr';
  
  // Connected devices
  final List<SDRDevice> _connectedDevices = [];
  final List<FrequencySpectrum> _spectrumData = [];
  final List<SDRMessage> _receivedMessages = [];
  final List<String> _emergencyFrequencies = [
    '446.00625', // PMR446 Ch1
    '446.01875', // PMR446 Ch2
    '146.520',   // 2m calling frequency
    '145.500',   // 2m emergency
    '433.500',   // 70cm emergency
  ];
  
  // Signal monitoring
  Timer? _scanTimer;
  Timer? _spectrumTimer;
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isTransmitting => _isTransmitting;
  bool get isReceiving => _isReceiving;
  bool get isScanning => _isScanning;
  String get currentFrequency => _currentFrequency;
  int get currentSampleRate => _currentSampleRate;
  String get selectedDevice => _selectedDevice;
  List<SDRDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  List<FrequencySpectrum> get spectrumData => List.unmodifiable(_spectrumData);
  List<SDRMessage> get receivedMessages => List.unmodifiable(_receivedMessages);
  List<String> get emergencyFrequencies => List.unmodifiable(_emergencyFrequencies);
  
  /// Initialize SDR manager
  Future<bool> initialize() async {
    try {
      print('🔧 Initializing SDR Manager...');
      
      // In web environment, simulate SDR devices
      if (kIsWeb) {
        await _simulateSDRDevices();
        print('🌐 Web simulation: SDR devices simulated');
      } else {
        // On native platforms, scan for real SDR devices
        await _scanForSDRDevices();
      }
      
      // Start spectrum monitoring
      _startSpectrumMonitoring();
      
      print('📡 SDR Manager initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing SDR Manager: $e');
      return false;
    }
  }
  
  /// Simulate SDR devices for web demo
  Future<void> _simulateSDRDevices() async {
    // Add demo RTL-SDR device
    final rtlDevice = SDRDevice(
      id: 'demo_rtl_001',
      name: 'RTL-SDR Demo',
      type: 'rtl_sdr',
      serialNumber: 'DEMO001',
      frequency: double.parse(DEFAULT_FREQUENCY),
      sampleRate: DEFAULT_SAMPLE_RATE,
      isConnected: true,
      signalStrength: -45.0,
    );
    
    // Add demo HackRF device  
    final hackrfDevice = SDRDevice(
      id: 'demo_hackrf_001',
      name: 'HackRF Demo',
      type: 'hackrf',
      serialNumber: 'DEMO002',
      frequency: double.parse(EMERGENCY_FREQUENCY),
      sampleRate: DEFAULT_SAMPLE_RATE,
      isConnected: false,
      signalStrength: -52.0,
    );
    
    _connectedDevices.addAll([rtlDevice, hackrfDevice]);
    _isConnected = _connectedDevices.any((device) => device.isConnected);
    
    // Simulate some spectrum data
    _generateDemoSpectrumData();
    
    notifyListeners();
  }
  
  /// Scan for real SDR devices (native platforms)
  Future<void> _scanForSDRDevices() async {
    // This would integrate with native SDR libraries
    // For now, we'll simulate the process
    print('🔍 Scanning for SDR devices...');
    
    // TODO: Implement native SDR device detection
    // - RTL-SDR via librtlsdr
    // - HackRF via libhackrf  
    // - Other SDR devices via SoapySDR
    
    await Future.delayed(Duration(seconds: 2));
    print('📱 No real SDR devices found (demo mode)');
  }
  
  /// Generate demo spectrum data
  void _generateDemoSpectrumData() {
    _spectrumData.clear();
    
    final baseFreq = double.parse(_currentFrequency);
    final span = 2.0; // 2 MHz span
    
    for (int i = 0; i < 512; i++) {
      final freq = baseFreq - span/2 + (span * i / 512);
      var power = -80.0 + (20 * (0.5 + 0.5 * math.sin(i * 0.1))); // Base noise
      
      // Add some signal peaks
      if ((freq - baseFreq).abs() < 0.01) {
        power += 30; // Strong signal at center frequency
      }
      if ((freq - (baseFreq + 0.5)).abs() < 0.005) {
        power += 15; // Weaker signal offset
      }
      
      _spectrumData.add(FrequencySpectrum(
        frequency: freq,
        power: power,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  /// Start spectrum monitoring
  void _startSpectrumMonitoring() {
    _spectrumTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isConnected) {
        _generateDemoSpectrumData();
        notifyListeners();
      }
    });
  }
  
  /// Connect to SDR device
  Future<bool> connectToDevice(String deviceId) async {
    try {
      final device = _connectedDevices.firstWhere((d) => d.id == deviceId);
      
      print('🔗 Connecting to ${device.name}...');
      
      // Simulate connection process
      await Future.delayed(Duration(seconds: 1));
      
      device.isConnected = true;
      _isConnected = true;
      _selectedDevice = device.type;
      
      print('✅ Connected to ${device.name}');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Failed to connect to device: $e');
      return false;
    }
  }
  
  /// Disconnect from SDR device
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      final device = _connectedDevices.firstWhere((d) => d.id == deviceId);
      device.isConnected = false;
      
      _isConnected = _connectedDevices.any((d) => d.isConnected);
      
      print('🔌 Disconnected from ${device.name}');
      notifyListeners();
    } catch (e) {
      print('❌ Error disconnecting device: $e');
    }
  }
  
  /// Set frequency
  Future<void> setFrequency(double frequencyMHz) async {
    try {
      _currentFrequency = frequencyMHz.toStringAsFixed(6);
      
      // Update connected devices
      for (var device in _connectedDevices.where((d) => d.isConnected)) {
        device.frequency = frequencyMHz;
      }
      
      // Regenerate spectrum data for new frequency
      _generateDemoSpectrumData();
      
      print('📻 Frequency set to ${_currentFrequency} MHz');
      notifyListeners();
    } catch (e) {
      print('❌ Error setting frequency: $e');
    }
  }
  
  /// Start frequency scanning
  Future<void> startFrequencyScanning(double startFreq, double endFreq, double stepSize) async {
    if (_isScanning) return;
    
    _isScanning = true;
    print('🔍 Starting frequency scan: ${startFreq} - ${endFreq} MHz');
    
    _scanTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      
      // Simulate scanning through frequencies
      final currentFreq = startFreq + ((DateTime.now().millisecondsSinceEpoch / 1000) % (endFreq - startFreq));
      await setFrequency(currentFreq);
      
      // Simulate finding signals
      if (DateTime.now().millisecond % 3000 < 100) {
        _simulateReceivedSignal();
      }
    });
    
    notifyListeners();
  }
  
  /// Stop frequency scanning
  void stopFrequencyScanning() {
    _isScanning = false;
    _scanTimer?.cancel();
    print('⏹️ Frequency scanning stopped');
    notifyListeners();
  }
  
  /// Transmit message via SDR
  Future<bool> transmitMessage(String message, {double? frequency, String? modulation}) async {
    try {
      if (!_isConnected) {
        throw Exception('No SDR device connected');
      }
      
      _isTransmitting = true;
      notifyListeners();
      
      final txFreq = frequency ?? double.parse(_currentFrequency);
      
      print('📤 Transmitting on ${txFreq} MHz: $message');
      
      // Simulate transmission time
      await Future.delayed(Duration(seconds: 2));
      
      // Log transmitted message
      final sdrMessage = SDRMessage(
        id: _generateMessageId(),
        content: message,
        frequency: txFreq,
        timestamp: DateTime.now(),
        direction: SDRMessageDirection.transmitted,
        modulation: modulation ?? 'FM',
        signalStrength: -20.0, // Strong signal when transmitting
      );
      
      _receivedMessages.insert(0, sdrMessage);
      
      _isTransmitting = false;
      print('✅ Message transmitted successfully');
      notifyListeners();
      
      return true;
    } catch (e) {
      _isTransmitting = false;
      print('❌ Transmission failed: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Simulate received signal
  void _simulateReceivedSignal() {
    final messages = [
      'CQ CQ DE EMERGENCY STATION',
      'MESHNET-001 CALLING MESHNET-002',
      'Emergency traffic on this frequency',
      'Weather alert broadcast',
      'Repeater identification',
    ];
    
    final message = messages[DateTime.now().millisecond % messages.length];
    
    final sdrMessage = SDRMessage(
      id: _generateMessageId(),
      content: message,
      frequency: double.parse(_currentFrequency),
      timestamp: DateTime.now(),
      direction: SDRMessageDirection.received,
      modulation: 'FM',
      signalStrength: -45.0 + (10 * (0.5 - DateTime.now().millisecond / 1000.0)),
    );
    
    _receivedMessages.insert(0, sdrMessage);
    
    // Keep only last 50 messages
    if (_receivedMessages.length > 50) {
      _receivedMessages.removeRange(50, _receivedMessages.length);
    }
    
    notifyListeners();
  }
  
  /// Monitor emergency frequencies
  Future<void> startEmergencyMonitoring() async {
    print('🚨 Starting emergency frequency monitoring');
    
    for (String freq in _emergencyFrequencies) {
      // In a real implementation, this would set up multiple receivers
      print('👂 Monitoring emergency frequency: $freq MHz');
    }
    
    // Simulate emergency signals
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (_isConnected && DateTime.now().second % 30 == 0) {
        final emergencyFreq = _emergencyFrequencies[DateTime.now().minute % _emergencyFrequencies.length];
        
        final emergencyMessage = SDRMessage(
          id: _generateMessageId(),
          content: '🚨 EMERGENCY ALERT: Test emergency broadcast',
          frequency: double.parse(emergencyFreq),
          timestamp: DateTime.now(),
          direction: SDRMessageDirection.received,
          modulation: 'FM',
          signalStrength: -35.0,
          isEmergency: true,
        );
        
        _receivedMessages.insert(0, emergencyMessage);
        notifyListeners();
      }
    });
  }
  
  /// Generate message ID
  String _generateMessageId() {
    return 'SDR_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 1000}';
  }
  
  /// Get device info
  SDRDeviceInfo? getDeviceInfo(String deviceType) {
    return SUPPORTED_DEVICES[deviceType];
  }
  
  /// Check if frequency is in emergency band
  bool isEmergencyFrequency(double frequency) {
    return _emergencyFrequencies.any((freq) {
      final emergencyFreq = double.parse(freq);
      return (frequency - emergencyFreq).abs() < 0.01; // Within 10 kHz
    });
  }
  
  @override
  void dispose() {
    _scanTimer?.cancel();
    _spectrumTimer?.cancel();
    
    // Disconnect all devices
    for (var device in _connectedDevices) {
      device.isConnected = false;
    }
    
    super.dispose();
  }
}

/// SDR Device information
class SDRDeviceInfo {
  final String name;
  final double minFreq; // MHz
  final double maxFreq; // MHz
  final int maxSampleRate;
  final String icon;
  final String description;
  
  const SDRDeviceInfo({
    required this.name,
    required this.minFreq,
    required this.maxFreq,
    required this.maxSampleRate,
    required this.icon,
    required this.description,
  });
}

/// SDR Device
class SDRDevice {
  final String id;
  final String name;
  final String type;
  final String serialNumber;
  double frequency;
  int sampleRate;
  bool isConnected;
  double signalStrength;
  
  SDRDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.serialNumber,
    required this.frequency,
    required this.sampleRate,
    required this.isConnected,
    required this.signalStrength,
  });
  
  /// Get device info
  SDRDeviceInfo? get deviceInfo => SDRManager.SUPPORTED_DEVICES[type];
  
  /// Get signal quality
  String get signalQuality {
    if (signalStrength > -30) return 'Mükemmel';
    if (signalStrength > -50) return 'İyi';
    if (signalStrength > -70) return 'Orta';
    return 'Zayıf';
  }
}

/// Frequency spectrum data point
class FrequencySpectrum {
  final double frequency; // MHz
  final double power; // dBm
  final DateTime timestamp;
  
  FrequencySpectrum({
    required this.frequency,
    required this.power,
    required this.timestamp,
  });
}

/// SDR Message
class SDRMessage {
  final String id;
  final String content;
  final double frequency;
  final DateTime timestamp;
  final SDRMessageDirection direction;
  final String modulation;
  final double signalStrength;
  final bool isEmergency;
  
  SDRMessage({
    required this.id,
    required this.content,
    required this.frequency,
    required this.timestamp,
    required this.direction,
    required this.modulation,
    required this.signalStrength,
    this.isEmergency = false,
  });
  
  /// Get formatted timestamp
  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
  
  /// Get direction icon
  String get directionIcon {
    switch (direction) {
      case SDRMessageDirection.received:
        return '📥';
      case SDRMessageDirection.transmitted:
        return '📤';
    }
  }
}

/// SDR Message direction
enum SDRMessageDirection {
  received,
  transmitted,
}
