// lib/services/emergency_detection_service.dart - Advanced Emergency Detection
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'emergency_manager.dart';
import 'location_manager.dart';

/// Advanced emergency detection service
class EmergencyDetectionService extends ChangeNotifier {
  // Detection thresholds
  static const double MOVEMENT_THRESHOLD = 50.0; // meters
  static const double SPEED_THRESHOLD = 120.0; // km/h (potential crash)
  static const Duration INACTIVITY_THRESHOLD = Duration(hours: 12);
  static const Duration PANIC_TIMEOUT = Duration(seconds: 10);
  
  // Sensor monitoring
  bool _isMonitoring = false;
  Timer? _detectionTimer;
  Timer? _panicTimer;
  
  // Location tracking
  LocationManager? _locationManager;
  List<EmergencyLocation> _locationHistory = [];
  DateTime? _lastMovement;
  double _lastSpeed = 0.0;
  
  // Emergency triggers
  bool _panicButtonPressed = false;
  int _panicButtonCount = 0;
  DateTime? _lastPanicPress;
  
  // Device sensors (simulated for web)
  bool _isShakeDetectionActive = false;
  double _lastAcceleration = 0.0;
  
  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get panicButtonPressed => _panicButtonPressed;
  List<EmergencyLocation> get locationHistory => List.unmodifiable(_locationHistory);
  
  /// Initialize emergency detection
  Future<bool> initialize({LocationManager? locationManager}) async {
    try {
      print('🚨 Initializing Emergency Detection Service...');
      
      _locationManager = locationManager;
      
      // Start monitoring if location manager available
      if (_locationManager != null) {
        _startLocationMonitoring();
      }
      
      // Initialize device sensors
      await _initializeSensors();
      
      print('🚨 Emergency Detection Service initialized');
      return true;
    } catch (e) {
      print('❌ Error initializing Emergency Detection: $e');
      return false;
    }
  }
  
  /// Start emergency monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Start detection timer
    _detectionTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _performDetectionChecks();
    });
    
    // Enable shake detection
    _isShakeDetectionActive = true;
    
    print('🔍 Emergency monitoring started');
    notifyListeners();
  }
  
  /// Stop emergency monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _detectionTimer?.cancel();
    _panicTimer?.cancel();
    _isShakeDetectionActive = false;
    
    print('🔍 Emergency monitoring stopped');
    notifyListeners();
  }
  
  /// Trigger panic button
  void triggerPanicButton() {
    final now = DateTime.now();
    
    // Check for rapid button presses
    if (_lastPanicPress != null && 
        now.difference(_lastPanicPress!).inSeconds < 2) {
      _panicButtonCount++;
    } else {
      _panicButtonCount = 1;
    }
    
    _lastPanicPress = now;
    
    // Triple press triggers immediate emergency
    if (_panicButtonCount >= 3) {
      _triggerEmergency(
        type: EmergencyType.medical,
        level: EmergencyLevel.alert,
        description: 'Panic button activated (triple press)',
        isAutoTriggered: false,
      );
      _panicButtonCount = 0;
      return;
    }
    
    // Single/double press starts countdown
    if (!_panicButtonPressed) {
      _panicButtonPressed = true;
      
      _panicTimer = Timer(PANIC_TIMEOUT, () {
        if (_panicButtonPressed) {
          _triggerEmergency(
            type: EmergencyType.medical,
            level: EmergencyLevel.warning,
            description: 'Panic button activated (timeout)',
            isAutoTriggered: false,
          );
        }
      });
      
      print('🚨 Panic button activated - ${PANIC_TIMEOUT.inSeconds}s to cancel');
      notifyListeners();
    }
  }
  
  /// Cancel panic button
  void cancelPanicButton() {
    if (_panicButtonPressed) {
      _panicButtonPressed = false;
      _panicTimer?.cancel();
      
      print('✅ Panic button cancelled');
      notifyListeners();
    }
  }
  
  /// Simulate device shake (for testing)
  void simulateShake() {
    if (_isShakeDetectionActive) {
      _onShakeDetected();
    }
  }
  
  /// Initialize device sensors
  Future<void> _initializeSensors() async {
    if (kIsWeb) {
      // Web simulation
      print('📱 Sensors initialized (web simulation)');
      return;
    }
    
    // Native platform sensor initialization would go here
    try {
      // Accelerometer, gyroscope setup
      print('📱 Device sensors initialized');
    } catch (e) {
      print('⚠️ Sensor initialization failed: $e');
    }
  }
  
  /// Start location monitoring
  void _startLocationMonitoring() {
    if (_locationManager == null) return;
    
    // Listen to location updates
    _locationManager!.addListener(() {
      if (_locationManager!.currentLocation != null) {
        _onLocationUpdate(_locationManager!.currentLocation!);
      }
    });
  }
  
  /// Handle location updates
  void _onLocationUpdate(EmergencyLocation location) {
    _locationHistory.add(location);
    
    // Keep only last 100 locations
    if (_locationHistory.length > 100) {
      _locationHistory.removeAt(0);
    }
    
    // Check for unusual movement patterns
    _checkMovementPatterns(location);
    
    // Update last movement time
    if (_isSignificantMovement(location)) {
      _lastMovement = DateTime.now();
    }
  }
  
  /// Check if movement is significant
  bool _isSignificantMovement(EmergencyLocation location) {
    if (_locationHistory.length < 2) return false;
    
    final previous = _locationHistory[_locationHistory.length - 2];
    final distance = _calculateDistance(
      previous.latitude, previous.longitude,
      location.latitude, location.longitude,
    );
    
    return distance > MOVEMENT_THRESHOLD;
  }
  
  /// Check movement patterns for anomalies
  void _checkMovementPatterns(EmergencyLocation location) {
    if (_locationHistory.length < 3) return;
    
    // Calculate current speed
    final previous = _locationHistory[_locationHistory.length - 2];
    final distance = _calculateDistance(
      previous.latitude, previous.longitude,
      location.latitude, location.longitude,
    );
    
    final timeDiff = location.timestamp.difference(previous.timestamp).inSeconds;
    if (timeDiff > 0) {
      final speed = (distance / timeDiff) * 3.6; // km/h
      _lastSpeed = speed;
      
      // Detect potential crash (sudden stop from high speed)
      if (_lastSpeed > SPEED_THRESHOLD && speed < 10) {
        _triggerEmergency(
          type: EmergencyType.accident,
          level: EmergencyLevel.critical,
          description: 'Potential vehicle crash detected (sudden deceleration)',
          isAutoTriggered: true,
        );
      }
    }
  }
  
  /// Perform regular detection checks
  void _performDetectionChecks() {
    // Check for prolonged inactivity
    _checkInactivity();
    
    // Check for geographic anomalies
    _checkGeographicAnomalies();
    
    // Check for communication loss
    _checkCommunicationStatus();
  }
  
  /// Check for prolonged inactivity
  void _checkInactivity() {
    if (_lastMovement == null) return;
    
    final inactiveDuration = DateTime.now().difference(_lastMovement!);
    
    if (inactiveDuration > INACTIVITY_THRESHOLD) {
      _triggerEmergency(
        type: EmergencyType.medical,
        level: EmergencyLevel.warning,
        description: 'Prolonged inactivity detected (${inactiveDuration.inHours}h)',
        isAutoTriggered: true,
      );
    }
  }
  
  /// Check for geographic anomalies
  void _checkGeographicAnomalies() {
    if (_locationHistory.length < 10) return;
    
    // Check if user is in known dangerous area
    final currentLocation = _locationHistory.last;
    
    // Simulate dangerous area check
    if (_isInDangerousArea(currentLocation)) {
      _triggerEmergency(
        type: EmergencyType.security,
        level: EmergencyLevel.warning,
        description: 'Entered high-risk area',
        isAutoTriggered: true,
      );
    }
  }
  
  /// Check communication status
  void _checkCommunicationStatus() {
    // This would check if device has been offline for too long
    // For now, simulate based on location updates
    
    if (_locationHistory.isEmpty) return;
    
    final lastUpdate = _locationHistory.last.timestamp;
    final timeSinceUpdate = DateTime.now().difference(lastUpdate);
    
    if (timeSinceUpdate > Duration(hours: 6)) {
      _triggerEmergency(
        type: EmergencyType.communication,
        level: EmergencyLevel.info,
        description: 'Extended communication loss detected',
        isAutoTriggered: true,
      );
    }
  }
  
  /// Handle shake detection
  void _onShakeDetected() {
    print('📱 Shake detected - potential emergency signal');
    
    // Multiple shakes within short time = emergency
    _triggerEmergency(
      type: EmergencyType.medical,
      level: EmergencyLevel.alert,
      description: 'Emergency shake pattern detected',
      isAutoTriggered: true,
    );
  }
  
  /// Check if location is in dangerous area
  bool _isInDangerousArea(EmergencyLocation location) {
    // Simulate dangerous area detection
    // In real implementation, this would check against:
    // - Crime statistics
    // - Natural disaster zones
    // - Political instability areas
    // - User-defined danger zones
    
    return false; // Placeholder
  }
  
  /// Trigger emergency event
  void _triggerEmergency({
    required EmergencyType type,
    required EmergencyLevel level,
    required String description,
    required bool isAutoTriggered,
  }) {
    print('🚨 EMERGENCY DETECTED: $description');
    
    // This would notify the EmergencyManager
    // For now, just notify listeners
    notifyListeners();
    
    // In real implementation:
    // emergencyManager.activateEmergencyMode(type, level, description: description);
  }
  
  /// Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
        math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}

/// Emergency detection result
class DetectionResult {
  final EmergencyType type;
  final EmergencyLevel level;
  final String description;
  final double confidence;
  final Map<String, dynamic> metadata;

  DetectionResult({
    required this.type,
    required this.level,
    required this.description,
    required this.confidence,
    this.metadata = const {},
  });
}
