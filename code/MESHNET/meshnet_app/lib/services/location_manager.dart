// lib/services/location_manager.dart - GPS Konum Yöneticisi
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'emergency_manager.dart'; // EmergencyLocation için

/// GPS konum yöneticisi - acil durum koordinat paylaşımı
class LocationManager extends ChangeNotifier {
  static const double EMERGENCY_ACCURACY_THRESHOLD = 50.0; // 50 meter
  static const int LOCATION_UPDATE_INTERVAL = 30; // 30 saniye
  static const int EMERGENCY_UPDATE_INTERVAL = 10; // Acil durumda 10 saniye
  
  // Location state
  Position? _currentPosition;
  String? _currentAddress;
  bool _locationEnabled = false;
  bool _permissionGranted = false;
  bool _isTracking = false;
  bool _emergencyMode = false;
  
  // Location history for emergency breadcrumbs
  final List<LocationPoint> _locationHistory = [];
  Timer? _locationTimer;
  
  // Emergency location sharing
  final Map<String, EmergencyLocationShare> _emergencyShares = {};
  
  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get locationEnabled => _locationEnabled;
  bool get permissionGranted => _permissionGranted;
  bool get isTracking => _isTracking;
  bool get emergencyMode => _emergencyMode;
  List<LocationPoint> get locationHistory => List.unmodifiable(_locationHistory);
  Map<String, EmergencyLocationShare> get emergencyShares => Map.unmodifiable(_emergencyShares);
  
  // Emergency location getter
  EmergencyLocation? get currentLocation {
    if (_currentPosition == null) return null;
    
    return EmergencyLocation(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      address: _currentAddress ?? 'Unknown location',
      accuracy: _currentPosition!.accuracy,
      timestamp: _currentPosition!.timestamp,
    );
  }
  
  /// Initialize location services
  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        // Web platformunda basit initializasyon
        print('📍 Web platformu: Location services simülasyonu başlatılıyor...');
        _locationEnabled = true;
        _permissionGranted = true;
        
        // Demo konum verisi (web için)
        _currentPosition = Position(
          latitude: 39.9334,
          longitude: 32.8597,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
        _currentAddress = 'Ankara, Türkiye (Demo Konum)';
        
        notifyListeners();
        print('📍 Location Manager initialized successfully (Web Demo)');
        return true;
      }
      
      // Check if location services are enabled
      _locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_locationEnabled) {
        print('⚠️ Location services are disabled');
        return false;
      }
      
      // Check and request permissions
      await _checkAndRequestPermissions();
      
      if (_permissionGranted) {
        // Get initial position
        await _getCurrentLocation();
        print('📍 Location Manager initialized successfully');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error initializing Location Manager: $e');
      return false;
    }
  }
  
  /// Check and request location permissions
  Future<void> _checkAndRequestPermissions() async {
    try {
      if (kIsWeb) {
        // Web'de permission check'i farklı çalışır
        _permissionGranted = true;
        notifyListeners();
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      _permissionGranted = permission == LocationPermission.whileInUse ||
                          permission == LocationPermission.always;
      
      // For emergency features, request "always" permission
      if (permission == LocationPermission.whileInUse) {
        // Show dialog explaining why "always" permission is needed for emergency features
        print('ℹ️ Consider enabling "Always Allow" for emergency features');
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error checking permissions: $e');
      _permissionGranted = false;
    }
  }
  
  /// Get current location
  Future<Position?> _getCurrentLocation() async {
    try {
      if (!_permissionGranted || !_locationEnabled) return null;
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      await _updateAddress(position);
      
      // Add to history
      _addLocationToHistory(position);
      
      notifyListeners();
      return position;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }
  
  /// Update address from coordinates
  Future<void> _updateAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = _formatAddress(placemark);
      }
    } catch (e) {
      print('⚠️ Error getting address: $e');
      _currentAddress = 'Koordinat: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }
  
  /// Format address from placemark
  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }
    
    return addressParts.join(', ');
  }
  
  /// Add location to history
  void _addLocationToHistory(Position position) {
    final locationPoint = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: DateTime.now(),
      isEmergency: _emergencyMode,
    );
    
    _locationHistory.add(locationPoint);
    
    // Keep only last 100 points to save memory
    if (_locationHistory.length > 100) {
      _locationHistory.removeAt(0);
    }
  }
  
  /// Start location tracking
  Future<void> startTracking({bool emergencyMode = false}) async {
    if (_isTracking) return;
    
    _emergencyMode = emergencyMode;
    _isTracking = true;
    
    final interval = emergencyMode ? EMERGENCY_UPDATE_INTERVAL : LOCATION_UPDATE_INTERVAL;
    
    _locationTimer = Timer.periodic(Duration(seconds: interval), (timer) async {
      await _getCurrentLocation();
    });
    
    print('📍 Location tracking started (${emergencyMode ? 'EMERGENCY' : 'NORMAL'} mode)');
    notifyListeners();
  }
  
  /// Stop location tracking
  void stopTracking() {
    _locationTimer?.cancel();
    _isTracking = false;
    _emergencyMode = false;
    
    print('📍 Location tracking stopped');
    notifyListeners();
  }
  
  /// Share emergency location with mesh network
  Future<EmergencyLocationShare> shareEmergencyLocation({
    required String emergencyType,
    String? message,
    Map<String, dynamic>? additionalData,
  }) async {
    // Get current location with high accuracy
    await _getCurrentLocation();
    
    if (_currentPosition == null) {
      throw Exception('Current location not available');
    }
    
    final emergencyShare = EmergencyLocationShare(
      id: _generateEmergencyId(),
      position: _currentPosition!,
      emergencyType: emergencyType,
      message: message ?? 'Acil durum konumu paylaşıldı',
      address: _currentAddress,
      timestamp: DateTime.now(),
      additionalData: additionalData ?? {},
    );
    
    _emergencyShares[emergencyShare.id] = emergencyShare;
    
    // Start emergency tracking if not already started
    if (!_isTracking || !_emergencyMode) {
      await startTracking(emergencyMode: true);
    }
    
    print('🚨 Emergency location shared: ${emergencyShare.id}');
    notifyListeners();
    
    return emergencyShare;
  }
  
  /// Process received emergency location from mesh network
  void receiveEmergencyLocation(Map<String, dynamic> data) {
    try {
      final emergencyShare = EmergencyLocationShare.fromJson(data);
      _emergencyShares[emergencyShare.id] = emergencyShare;
      
      print('📥 Received emergency location: ${emergencyShare.emergencyType} from ${emergencyShare.id}');
      notifyListeners();
    } catch (e) {
      print('❌ Error processing received emergency location: $e');
    }
  }
  
  /// Calculate distance between two positions
  double calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }
  
  /// Get nearby emergency locations
  List<EmergencyLocationShare> getNearbyEmergencies(double radiusInMeters) {
    if (_currentPosition == null) return [];
    
    return _emergencyShares.values.where((emergency) {
      final distance = calculateDistance(_currentPosition!, emergency.position);
      return distance <= radiusInMeters;
    }).toList();
  }
  
  /// Generate emergency ID
  String _generateEmergencyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'EMERGENCY_${timestamp}_$random';
  }
  
  /// Clear old emergency shares (older than 24 hours)
  void clearOldEmergencyShares() {
    final cutoffTime = DateTime.now().subtract(Duration(hours: 24));
    _emergencyShares.removeWhere((key, emergency) {
      return emergency.timestamp.isBefore(cutoffTime);
    });
    notifyListeners();
  }
  
  /// Get location breadcrumb trail
  List<LocationPoint> getLocationTrail({Duration? timeRange}) {
    if (timeRange == null) return _locationHistory;
    
    final cutoffTime = DateTime.now().subtract(timeRange);
    return _locationHistory.where((point) {
      return point.timestamp.isAfter(cutoffTime);
    }).toList();
  }
  
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Location point for history tracking
class LocationPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isEmergency;
  
  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.isEmergency = false,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isEmergency': isEmergency,
    };
  }
  
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy'].toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isEmergency: json['isEmergency'] ?? false,
    );
  }
}

/// Emergency location sharing data
class EmergencyLocationShare {
  final String id;
  final Position position;
  final String emergencyType;
  final String message;
  final String? address;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;
  
  EmergencyLocationShare({
    required this.id,
    required this.position,
    required this.emergencyType,
    required this.message,
    this.address,
    required this.timestamp,
    this.additionalData = const {},
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'emergencyType': emergencyType,
      'message': message,
      'address': address,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'additionalData': additionalData,
    };
  }
  
  factory EmergencyLocationShare.fromJson(Map<String, dynamic> json) {
    final position = Position(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      accuracy: json['accuracy']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble() ?? 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    
    return EmergencyLocationShare(
      id: json['id'],
      position: position,
      emergencyType: json['emergencyType'],
      message: json['message'],
      address: json['address'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
    );
  }
  
  /// Get emergency type emoji
  String get emergencyIcon {
    switch (emergencyType.toLowerCase()) {
      case 'medical':
        return '🚑';
      case 'fire':
        return '🚒';
      case 'police':
        return '🚓';
      case 'natural_disaster':
        return '🌪️';
      case 'accident':
        return '🚗';
      case 'missing_person':
        return '🔍';
      case 'general':
      default:
        return '🚨';
    }
  }
  
  /// Get formatted distance from current position
  String getDistanceText(Position? currentPosition) {
    if (currentPosition == null) return 'Mesafe bilinmiyor';
    
    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      position.latitude,
      position.longitude,
    );
    
    if (distance < 1000) {
      return '${distance.round()}m uzaklıkta';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km uzaklıkta';
    }
  }
  
  /// Get formatted time
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}
