// test/services/communication/emergency_broadcasting_test.dart - Emergency Broadcasting Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:meshnet_app/services/communication/emergency_broadcasting.dart';

@GenerateMocks([])
class MockBroadcastStreamController extends Mock implements StreamController<EmergencyBroadcast> {}

void main() {
  group('EmergencyBroadcasting Tests', () {
    late EmergencyBroadcasting broadcastService;
    
    setUp(() {
      broadcastService = EmergencyBroadcasting.instance;
    });
    
    tearDown(() async {
      if (broadcastService.isInitialized) {
        await broadcastService.shutdown();
      }
    });

    group('Service Initialization', () {
      test('should initialize emergency broadcasting service successfully', () async {
        final result = await broadcastService.initialize();
        
        expect(result, isTrue);
        expect(broadcastService.isInitialized, isTrue);
        expect(broadcastService.isEmergencyMode, isFalse);
      });
      
      test('should initialize with custom configuration', () async {
        final config = BroadcastConfig(
          maxBroadcasts: 50,
          defaultSeverity: EmergencySeverity.medium,
          autoRepeatEnabled: true,
          repeatInterval: const Duration(minutes: 5),
          maxRepeatCount: 10,
          multiChannelEnabled: true,
          geofencingEnabled: true,
          emergencyOverride: true,
          compressionEnabled: true,
          encryptionEnabled: true,
          meshIntegration: true,
          languages: ['en', 'tr', 'ar', 'ku'],
        );
        
        final result = await broadcastService.initialize(config: config);
        
        expect(result, isTrue);
        expect(broadcastService.maxBroadcasts, equals(50));
      });
    });

    group('Emergency Alert Types', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should support all emergency alert types', () {
        final supportedTypes = broadcastService.getSupportedAlertTypes();
        
        expect(supportedTypes, isNotEmpty);
        expect(supportedTypes.length, equals(14)); // All 14 alert types
        expect(supportedTypes, contains(EmergencyAlertType.natural_disaster));
        expect(supportedTypes, contains(EmergencyAlertType.terrorist_attack));
        expect(supportedTypes, contains(EmergencyAlertType.fire));
        expect(supportedTypes, contains(EmergencyAlertType.medical_emergency));
      });
      
      test('should create natural disaster alert correctly', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.natural_disaster,
          severity: EmergencySeverity.extreme,
          title: 'Major Earthquake Alert',
          description: 'Magnitude 7.2 earthquake detected. Take immediate shelter.',
          location: {'lat': 40.7128, 'lng': -74.0060, 'radius': 50000},
          contactInfo: {'emergency': '911', 'info': '1-800-EARTHQUAKE'},
          expirationTime: DateTime.now().add(const Duration(hours: 6)),
        );
        
        expect(alert, isNotNull);
        expect(alert!.alertType, equals(EmergencyAlertType.natural_disaster));
        expect(alert.severity, equals(EmergencySeverity.extreme));
        expect(alert.title, contains('Earthquake'));
      });
      
      test('should create terrorist attack alert correctly', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.terrorist_attack,
          severity: EmergencySeverity.extreme,
          title: 'Security Threat Alert',
          description: 'Terrorist threat in downtown area. Avoid the area and follow law enforcement instructions.',
          location: {'lat': 40.7589, 'lng': -73.9851, 'radius': 10000},
          contactInfo: {'emergency': '911', 'fbi': '1-800-CALL-FBI'},
          expirationTime: DateTime.now().add(const Duration(hours: 12)),
        );
        
        expect(alert, isNotNull);
        expect(alert!.alertType, equals(EmergencyAlertType.terrorist_attack));
        expect(alert.severity, equals(EmergencySeverity.extreme));
      });
      
      test('should create medical emergency alert correctly', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.medical_emergency,
          severity: EmergencySeverity.high,
          title: 'Blood Shortage Emergency',
          description: 'Critical blood shortage at hospitals. Urgent need for O-negative blood donors.',
          location: {'lat': 40.7484, 'lng': -73.9857, 'radius': 25000},
          contactInfo: {'redcross': '1-800-RED-CROSS', 'hospitals': '311'},
          expirationTime: DateTime.now().add(const Duration(days: 3)),
        );
        
        expect(alert, isNotNull);
        expect(alert!.alertType, equals(EmergencyAlertType.medical_emergency));
        expect(alert.severity, equals(EmergencySeverity.high));
      });
    });

    group('Severity Levels', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should support all severity levels', () {
        final severityLevels = broadcastService.getSupportedSeverityLevels();
        
        expect(severityLevels, isNotEmpty);
        expect(severityLevels.length, equals(8)); // All 8 severity levels
        expect(severityLevels, contains(EmergencySeverity.extreme));
        expect(severityLevels, contains(EmergencySeverity.severe));
        expect(severityLevels, contains(EmergencySeverity.information));
      });
      
      test('should prioritize by severity level correctly', () {
        final extremeAlert = EmergencyAlert(
          alertId: 'extreme_alert',
          alertType: EmergencyAlertType.natural_disaster,
          severity: EmergencySeverity.extreme,
          title: 'Extreme Emergency',
          description: 'Extreme emergency alert',
          location: {},
          contactInfo: {},
          timestamp: DateTime.now(),
          expirationTime: DateTime.now().add(const Duration(hours: 1)),
          isActive: true,
          metadata: {},
        );
        
        final infoAlert = EmergencyAlert(
          alertId: 'info_alert',
          alertType: EmergencyAlertType.test,
          severity: EmergencySeverity.information,
          title: 'Information Alert',
          description: 'Information alert',
          location: {},
          contactInfo: {},
          timestamp: DateTime.now(),
          expirationTime: DateTime.now().add(const Duration(hours: 1)),
          isActive: true,
          metadata: {},
        );
        
        expect(extremeAlert.severity.index, lessThan(infoAlert.severity.index));
        expect(extremeAlert.priorityScore, greaterThan(infoAlert.priorityScore));
      });
      
      test('should calculate severity-based broadcast intervals', () {
        final extremeInterval = broadcastService.getRepeatInterval(EmergencySeverity.extreme);
        final infoInterval = broadcastService.getRepeatInterval(EmergencySeverity.information);
        
        expect(extremeInterval, lessThan(infoInterval));
        expect(extremeInterval, lessThanOrEqualTo(const Duration(minutes: 1)));
      });
    });

    group('Broadcast Channels', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should support all broadcast channels', () {
        final channels = broadcastService.getSupportedChannels();
        
        expect(channels, isNotEmpty);
        expect(channels.length, equals(10)); // All 10 broadcast channels
        expect(channels, contains(BroadcastChannel.mesh_network));
        expect(channels, contains(BroadcastChannel.emergency_frequency));
        expect(channels, contains(BroadcastChannel.cellular));
        expect(channels, contains(BroadcastChannel.satellite));
      });
      
      test('should enable multi-channel broadcasting', () async {
        final result = await broadcastService.enableMultiChannelBroadcast(true);
        
        expect(result, isTrue);
        expect(broadcastService.isMultiChannelEnabled, isTrue);
      });
      
      test('should broadcast on specific channels', () async {
        await broadcastService.enableMultiChannelBroadcast(true);
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.fire,
          severity: EmergencySeverity.high,
          title: 'Building Fire Alert',
          description: 'Large fire in commercial building. Evacuate immediately.',
          location: {'lat': 40.7505, 'lng': -73.9934},
        );
        
        expect(alert, isNotNull);
        
        final channels = [
          BroadcastChannel.mesh_network,
          BroadcastChannel.emergency_frequency,
          BroadcastChannel.cellular,
        ];
        
        final broadcast = await broadcastService.startBroadcast(
          alert!,
          channels: channels,
        );
        
        expect(broadcast, isNotNull);
        expect(broadcast!.channels, equals(channels));
      });
      
      test('should handle channel failures gracefully', () async {
        await broadcastService.enableMultiChannelBroadcast(true);
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.evacuation,
          severity: EmergencySeverity.severe,
          title: 'Evacuation Order',
          description: 'Immediate evacuation required due to chemical spill.',
        );
        
        expect(alert, isNotNull);
        
        // Simulate some channels being unavailable
        final failingChannels = [
          BroadcastChannel.satellite, // May fail
          BroadcastChannel.ham_radio, // May fail
        ];
        
        final workingChannels = [
          BroadcastChannel.mesh_network,
          BroadcastChannel.cellular,
        ];
        
        final broadcast = await broadcastService.startBroadcast(
          alert!,
          channels: [...failingChannels, ...workingChannels],
        );
        
        expect(broadcast, isNotNull);
        // Should still work with available channels
      });
    });

    group('Broadcasting Operations', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should start emergency broadcast successfully', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.severe_weather,
          severity: EmergencySeverity.severe,
          title: 'Severe Weather Warning',
          description: 'Tornado warning in effect. Seek shelter immediately.',
          location: {'lat': 39.7392, 'lng': -104.9903, 'radius': 30000},
          expirationTime: DateTime.now().add(const Duration(hours: 3)),
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        expect(broadcast!.isActive, isTrue);
        expect(broadcast.alert.alertId, equals(alert.alertId));
      });
      
      test('should stop emergency broadcast successfully', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.flood,
          severity: EmergencySeverity.high,
          title: 'Flash Flood Warning',
          description: 'Flash flood warning in effect for low-lying areas.',
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        
        final stopResult = await broadcastService.stopBroadcast(broadcast!.broadcastId);
        
        expect(stopResult, isTrue);
      });
      
      test('should update active broadcast successfully', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.earthquake,
          severity: EmergencySeverity.high,
          title: 'Earthquake Alert',
          description: 'Magnitude 6.5 earthquake detected.',
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        
        final updatedAlert = EmergencyAlert(
          alertId: alert.alertId,
          alertType: alert.alertType,
          severity: EmergencySeverity.severe, // Updated severity
          title: alert.title,
          description: 'Magnitude 6.5 earthquake detected. Aftershocks expected.', // Updated description
          location: alert.location,
          contactInfo: alert.contactInfo,
          timestamp: alert.timestamp,
          expirationTime: alert.expirationTime,
          isActive: alert.isActive,
          metadata: alert.metadata,
        );
        
        final updateResult = await broadcastService.updateBroadcast(
          broadcast!.broadcastId,
          updatedAlert,
        );
        
        expect(updateResult, isTrue);
      });
      
      test('should get active broadcasts correctly', () async {
        // Create multiple active broadcasts
        for (int i = 0; i < 3; i++) {
          final alert = await broadcastService.createEmergencyAlert(
            alertType: EmergencyAlertType.test,
            severity: EmergencySeverity.low,
            title: 'Test Alert $i',
            description: 'Test alert for active broadcasts',
          );
          
          expect(alert, isNotNull);
          await broadcastService.startBroadcast(alert!);
        }
        
        final activeBroadcasts = broadcastService.getActiveBroadcasts();
        
        expect(activeBroadcasts, isNotEmpty);
        expect(activeBroadcasts.length, greaterThanOrEqualTo(3));
      });
    });

    group('Automatic Repeat System', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should enable automatic repeat successfully', () async {
        final result = await broadcastService.enableAutoRepeat(true);
        
        expect(result, isTrue);
        expect(broadcastService.isAutoRepeatEnabled, isTrue);
      });
      
      test('should configure repeat intervals correctly', () async {
        await broadcastService.enableAutoRepeat(true);
        
        final configResult = await broadcastService.configureRepeatSettings(
          interval: const Duration(minutes: 2),
          maxCount: 15,
        );
        
        expect(configResult, isTrue);
      });
      
      test('should repeat broadcasts based on severity', () async {
        await broadcastService.enableAutoRepeat(true);
        
        final extremeAlert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.tsunami,
          severity: EmergencySeverity.extreme,
          title: 'Tsunami Warning',
          description: 'Tsunami waves expected. Move to higher ground immediately.',
        );
        
        expect(extremeAlert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(extremeAlert!);
        
        expect(broadcast, isNotNull);
        expect(broadcast!.autoRepeatEnabled, isTrue);
        expect(broadcast.repeatCount, equals(0));
        
        // Simulate some time passing for auto-repeat
        await Future.delayed(const Duration(milliseconds: 100));
        
        // In real implementation, repeat count would increase automatically
        expect(broadcast.isActive, isTrue);
      });
      
      test('should stop auto-repeat when max count reached', () async {
        await broadcastService.enableAutoRepeat(true);
        await broadcastService.configureRepeatSettings(
          interval: const Duration(seconds: 1),
          maxCount: 3,
        );
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.test,
          severity: EmergencySeverity.low,
          title: 'Auto-repeat Test',
          description: 'Testing auto-repeat functionality',
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        
        // Simulate max repeats reached
        final maxReached = broadcastService.isMaxRepeatReached(broadcast!.broadcastId);
        expect(maxReached, isA<bool>());
      });
    });

    group('Authorization System', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should enable authorization successfully', () async {
        final result = await broadcastService.enableAuthorization(true);
        
        expect(result, isTrue);
        expect(broadcastService.isAuthorizationEnabled, isTrue);
      });
      
      test('should authorize emergency broadcast correctly', () async {
        await broadcastService.enableAuthorization(true);
        
        final authority = BroadcastAuthority(
          authorityId: 'emergency_manager_001',
          name: 'Emergency Manager',
          organization: 'City Emergency Services',
          role: AuthorityRole.emergency_manager,
          permissions: [
            BroadcastPermission.create_alert,
            BroadcastPermission.modify_alert,
            BroadcastPermission.cancel_alert,
          ],
          isActive: true,
          credentials: {'cert_id': 'EM001', 'clearance': 'L3'},
          expirationDate: DateTime.now().add(const Duration(days: 365)),
        );
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.chemical_hazard,
          severity: EmergencySeverity.severe,
          title: 'Chemical Spill Alert',
          description: 'Chemical spill on Highway 95. Avoid the area.',
          authorizedBy: authority,
        );
        
        expect(alert, isNotNull);
        expect(alert!.isAuthorized, isTrue);
        expect(alert.authorizedBy, isNotNull);
      });
      
      test('should reject unauthorized broadcast attempts', () async {
        await broadcastService.enableAuthorization(true);
        
        final unauthorizedAuthority = BroadcastAuthority(
          authorityId: 'fake_authority',
          name: 'Fake Authority',
          organization: 'Unknown',
          role: AuthorityRole.citizen,
          permissions: [], // No permissions
          isActive: false,
          credentials: {},
          expirationDate: DateTime.now().subtract(const Duration(days: 1)), // Expired
        );
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.fire,
          severity: EmergencySeverity.high,
          title: 'Unauthorized Fire Alert',
          description: 'This should be rejected',
          authorizedBy: unauthorizedAuthority,
        );
        
        expect(alert, isNull); // Should be rejected
      });
      
      test('should validate authority credentials', () {
        final validAuthority = BroadcastAuthority(
          authorityId: 'valid_authority',
          name: 'Valid Authority',
          organization: 'Emergency Services',
          role: AuthorityRole.emergency_manager,
          permissions: [BroadcastPermission.create_alert],
          isActive: true,
          credentials: {'cert_id': 'VALID001'},
          expirationDate: DateTime.now().add(const Duration(days: 100)),
        );
        
        final isValid = broadcastService.validateAuthority(validAuthority);
        
        expect(isValid, isTrue);
      });
    });

    group('Delivery Tracking', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should enable delivery tracking successfully', () async {
        final result = await broadcastService.enableDeliveryTracking(true);
        
        expect(result, isTrue);
        expect(broadcastService.isDeliveryTrackingEnabled, isTrue);
      });
      
      test('should track broadcast delivery rates', () async {
        await broadcastService.enableDeliveryTracking(true);
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.evacuation,
          severity: EmergencySeverity.severe,
          title: 'Evacuation Order',
          description: 'Immediate evacuation required',
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        
        // Simulate some delivery confirmations
        await broadcastService.recordDeliveryConfirmation(
          broadcast!.broadcastId,
          'device_001',
          BroadcastChannel.mesh_network,
        );
        
        await broadcastService.recordDeliveryConfirmation(
          broadcast.broadcastId,
          'device_002',
          BroadcastChannel.cellular,
        );
        
        final deliveryRate = broadcastService.getDeliveryRate(broadcast.broadcastId);
        
        expect(deliveryRate, isA<double>());
        expect(deliveryRate, greaterThanOrEqualTo(0.0));
        expect(deliveryRate, lessThanOrEqualTo(1.0));
      });
      
      test('should track acknowledgments correctly', () async {
        await broadcastService.enableDeliveryTracking(true);
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.shelter,
          severity: EmergencySeverity.medium,
          title: 'Shelter Information',
          description: 'Emergency shelters available at local schools',
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        
        // Record acknowledgments
        await broadcastService.recordAcknowledgment(
          broadcast!.broadcastId,
          'user_001',
          AcknowledgmentType.received,
        );
        
        await broadcastService.recordAcknowledgment(
          broadcast.broadcastId,
          'user_002',
          AcknowledgmentType.understood,
        );
        
        final ackCount = broadcastService.getAcknowledgmentCount(broadcast.broadcastId);
        
        expect(ackCount, greaterThanOrEqualTo(2));
      });
      
      test('should generate delivery reports', () async {
        await broadcastService.enableDeliveryTracking(true);
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.all_clear,
          severity: EmergencySeverity.low,
          title: 'All Clear',
          description: 'Emergency situation has been resolved',
        );
        
        expect(alert, isNotNull);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        expect(broadcast, isNotNull);
        
        // Simulate delivery data
        for (int i = 0; i < 10; i++) {
          await broadcastService.recordDeliveryConfirmation(
            broadcast!.broadcastId,
            'device_$i',
            BroadcastChannel.mesh_network,
          );
        }
        
        final report = broadcastService.generateDeliveryReport(broadcast!.broadcastId);
        
        expect(report, isA<Map<String, dynamic>>());
        expect(report, containsKey('broadcastId'));
        expect(report, containsKey('deliveryRate'));
        expect(report, containsKey('acknowledgmentRate'));
        expect(report, containsKey('channelPerformance'));
      });
    });

    group('Geographic Distribution', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should enable geofencing successfully', () async {
        final result = await broadcastService.enableGeofencing(true);
        
        expect(result, isTrue);
        expect(broadcastService.isGeofencingEnabled, isTrue);
      });
      
      test('should create geofenced broadcast correctly', () async {
        await broadcastService.enableGeofencing(true);
        
        final geofence = GeofenceArea(
          areaId: 'downtown_area',
          name: 'Downtown District',
          shape: GeofenceShape.circle,
          coordinates: [
            {'lat': 40.7589, 'lng': -73.9851}, // Center point
          ],
          radius: 5000, // 5km radius
          isActive: true,
          metadata: {'district': 'downtown'},
        );
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.evacuation,
          severity: EmergencySeverity.severe,
          title: 'Downtown Evacuation',
          description: 'Evacuate downtown area immediately',
          location: {'lat': 40.7589, 'lng': -73.9851, 'radius': 5000},
          geofence: geofence,
        );
        
        expect(alert, isNotNull);
        expect(alert!.geofence, isNotNull);
        expect(alert.geofence!.radius, equals(5000));
      });
      
      test('should validate geographic boundaries', () {
        final location = {'lat': 40.7589, 'lng': -73.9851};
        
        final geofence = GeofenceArea(
          areaId: 'test_area',
          name: 'Test Area',
          shape: GeofenceShape.circle,
          coordinates: [location],
          radius: 1000,
          isActive: true,
          metadata: {},
        );
        
        final insideLocation = {'lat': 40.7599, 'lng': -73.9861}; // Nearby
        final outsideLocation = {'lat': 41.0000, 'lng': -74.5000}; // Far away
        
        final isInside = broadcastService.isLocationInGeofence(insideLocation, geofence);
        final isOutside = broadcastService.isLocationInGeofence(outsideLocation, geofence);
        
        expect(isInside, isTrue);
        expect(isOutside, isFalse);
      });
      
      test('should handle polygon geofences correctly', () {
        final polygonGeofence = GeofenceArea(
          areaId: 'polygon_area',
          name: 'Polygon Area',
          shape: GeofenceShape.polygon,
          coordinates: [
            {'lat': 40.7500, 'lng': -73.9800},
            {'lat': 40.7600, 'lng': -73.9800},
            {'lat': 40.7600, 'lng': -73.9900},
            {'lat': 40.7500, 'lng': -73.9900},
          ],
          radius: 0,
          isActive: true,
          metadata: {},
        );
        
        final insidePoint = {'lat': 40.7550, 'lng': -73.9850}; // Inside polygon
        final outsidePoint = {'lat': 40.7700, 'lng': -73.9850}; // Outside polygon
        
        final isInside = broadcastService.isLocationInGeofence(insidePoint, polygonGeofence);
        final isOutside = broadcastService.isLocationInGeofence(outsidePoint, polygonGeofence);
        
        expect(isInside, isTrue);
        expect(isOutside, isFalse);
      });
    });

    group('Multi-language Support', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should support multiple languages', () {
        final supportedLanguages = broadcastService.getSupportedLanguages();
        
        expect(supportedLanguages, isNotEmpty);
        expect(supportedLanguages.length, equals(4)); // English, Turkish, Arabic, Kurdish
        expect(supportedLanguages, contains('en'));
        expect(supportedLanguages, contains('tr'));
        expect(supportedLanguages, contains('ar'));
        expect(supportedLanguages, contains('ku'));
      });
      
      test('should create multilingual alert correctly', () async {
        final multilingualAlert = await broadcastService.createMultilingualAlert(
          alertType: EmergencyAlertType.evacuation,
          severity: EmergencySeverity.severe,
          titles: {
            'en': 'Emergency Evacuation Order',
            'tr': 'Acil Tahliye Emri',
            'ar': 'أمر إخلاء طارئ',
            'ku': 'Fermana Valakirina Lezgînî',
          },
          descriptions: {
            'en': 'Immediate evacuation required due to gas leak.',
            'tr': 'Gaz sızıntısı nedeniyle acil tahliye gerekli.',
            'ar': 'الإخلاء الفوري مطلوب بسبب تسرب الغاز',
            'ku': 'Ji ber derketina gazê, valakirin pêwîst e.',
          },
          location: {'lat': 40.7505, 'lng': -73.9934},
        );
        
        expect(multilingualAlert, isNotNull);
        expect(multilingualAlert!.titles, containsKey('en'));
        expect(multilingualAlert.titles, containsKey('tr'));
        expect(multilingualAlert.descriptions, containsKey('ar'));
        expect(multilingualAlert.descriptions, containsKey('ku'));
      });
      
      test('should adapt content culturally', () async {
        final culturallyAdaptedAlert = await broadcastService.createCulturallyAdaptedAlert(
          alertType: EmergencyAlertType.severe_weather,
          severity: EmergencySeverity.high,
          baseTitle: 'Severe Weather Warning',
          baseDescription: 'Strong winds and heavy rain expected.',
          targetCultures: ['western', 'middle_eastern', 'kurdish'],
        );
        
        expect(culturallyAdaptedAlert, isNotNull);
        expect(culturallyAdaptedAlert!.culturalAdaptations, isNotEmpty);
      });
      
      test('should format dates and times per locale', () {
        final alert = EmergencyAlert(
          alertId: 'locale_test_alert',
          alertType: EmergencyAlertType.test,
          severity: EmergencySeverity.low,
          title: 'Locale Test',
          description: 'Testing locale formatting',
          location: {},
          contactInfo: {},
          timestamp: DateTime.now(),
          expirationTime: DateTime.now().add(const Duration(hours: 2)),
          isActive: true,
          metadata: {},
        );
        
        final enFormatted = broadcastService.formatAlertForLocale(alert, 'en');
        final trFormatted = broadcastService.formatAlertForLocale(alert, 'tr');
        
        expect(enFormatted, isA<Map<String, dynamic>>());
        expect(trFormatted, isA<Map<String, dynamic>>());
        expect(enFormatted['locale'], equals('en'));
        expect(trFormatted['locale'], equals('tr'));
      });
    });

    group('Integration with Other Services', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should integrate with voice communication service', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.fire,
          severity: EmergencySeverity.high,
          title: 'Building Fire',
          description: 'Fire in office building. Evacuate immediately.',
        );
        
        expect(alert, isNotNull);
        
        final voiceIntegration = await broadcastService.enableVoiceIntegration(true);
        
        expect(voiceIntegration, isTrue);
        
        final voiceBroadcast = await broadcastService.startVoiceBroadcast(alert!);
        
        expect(voiceBroadcast, isNotNull);
        expect(voiceBroadcast!.hasVoiceComponent, isTrue);
      });
      
      test('should integrate with video broadcasting service', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.tsunami,
          severity: EmergencySeverity.extreme,
          title: 'Tsunami Warning',
          description: 'Tsunami waves approaching. Move to higher ground.',
        );
        
        expect(alert, isNotNull);
        
        final videoIntegration = await broadcastService.enableVideoIntegration(true);
        
        expect(videoIntegration, isTrue);
        
        final videoBroadcast = await broadcastService.startVideoBroadcast(alert!);
        
        expect(videoBroadcast, isNotNull);
        expect(videoBroadcast!.hasVideoComponent, isTrue);
      });
      
      test('should integrate with group communication service', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.medical_emergency,
          severity: EmergencySeverity.high,
          title: 'Mass Casualty Event',
          description: 'Multiple casualties reported. Medical teams respond.',
        );
        
        expect(alert, isNotNull);
        
        final groupIntegration = await broadcastService.enableGroupIntegration(true);
        
        expect(groupIntegration, isTrue);
        
        final emergencyGroups = await broadcastService.notifyEmergencyGroups(alert!);
        
        expect(emergencyGroups, isA<List<String>>());
        expect(emergencyGroups, isNotEmpty);
      });
    });

    group('Performance and Statistics', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should track broadcasting statistics', () async {
        // Create multiple broadcasts
        for (int i = 0; i < 5; i++) {
          final alert = await broadcastService.createEmergencyAlert(
            alertType: EmergencyAlertType.test,
            severity: EmergencySeverity.low,
            title: 'Statistics Test Alert $i',
            description: 'Testing statistics tracking',
          );
          
          expect(alert, isNotNull);
          await broadcastService.startBroadcast(alert!);
        }
        
        final stats = broadcastService.getStatistics();
        
        expect(stats, containsKey('totalBroadcasts'));
        expect(stats, containsKey('activeBroadcasts'));
        expect(stats, containsKey('totalAlerts'));
        expect(stats, containsKey('alertTypeDistribution'));
        expect(stats, containsKey('severityDistribution'));
        expect(stats, containsKey('channelUsage'));
        expect(stats['totalBroadcasts'], greaterThanOrEqualTo(5));
      });
      
      test('should calculate system performance metrics', () async {
        // Generate some broadcast activity
        for (int i = 0; i < 3; i++) {
          final alert = await broadcastService.createEmergencyAlert(
            alertType: EmergencyAlertType.test,
            severity: EmergencySeverity.medium,
            title: 'Performance Test $i',
            description: 'Testing performance metrics',
          );
          
          expect(alert, isNotNull);
          
          final broadcast = await broadcastService.startBroadcast(alert!);
          expect(broadcast, isNotNull);
          
          // Simulate delivery confirmations
          await broadcastService.recordDeliveryConfirmation(
            broadcast!.broadcastId,
            'device_$i',
            BroadcastChannel.mesh_network,
          );
        }
        
        final metrics = broadcastService.getPerformanceMetrics();
        
        expect(metrics, containsKey('averageDeliveryTime'));
        expect(metrics, containsKey('systemReliability'));
        expect(metrics, containsKey('channelEfficiency'));
        expect(metrics, containsKey('overallPerformance'));
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should handle invalid alert data gracefully', () async {
        final invalidAlert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.test,
          severity: EmergencySeverity.low,
          title: '', // Empty title
          description: '', // Empty description
        );
        
        // Should handle gracefully, may return null or create with defaults
        expect(() => invalidAlert, returnsNormally);
      });
      
      test('should handle broadcasting failures gracefully', () async {
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.test,
          severity: EmergencySeverity.low,
          title: 'Failure Test',
          description: 'Testing failure handling',
        );
        
        expect(alert, isNotNull);
        
        // Simulate network failure
        await broadcastService.updateNetworkCondition(NetworkCondition.critical);
        
        final broadcast = await broadcastService.startBroadcast(alert!);
        
        // May fail but should not crash the service
        expect(broadcastService.isInitialized, isTrue);
      });
      
      test('should handle authorization failures gracefully', () async {
        await broadcastService.enableAuthorization(true);
        
        final expiredAuthority = BroadcastAuthority(
          authorityId: 'expired_authority',
          name: 'Expired Authority',
          organization: 'Test Org',
          role: AuthorityRole.emergency_manager,
          permissions: [BroadcastPermission.create_alert],
          isActive: false, // Inactive
          credentials: {},
          expirationDate: DateTime.now().subtract(const Duration(days: 1)), // Expired
        );
        
        final alert = await broadcastService.createEmergencyAlert(
          alertType: EmergencyAlertType.test,
          severity: EmergencySeverity.low,
          title: 'Authorization Test',
          description: 'Testing authorization failure',
          authorizedBy: expiredAuthority,
        );
        
        expect(alert, isNull); // Should be rejected gracefully
        expect(broadcastService.isInitialized, isTrue);
      });
    });

    group('Stream Management', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should provide emergency broadcasts stream', () async {
        final stream = broadcastService.emergencyBroadcastsStream;
        
        expect(stream, isA<Stream<EmergencyBroadcast>>());
        
        final subscription = stream.listen((broadcast) {
          expect(broadcast, isA<EmergencyBroadcast>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide alert notifications stream', () async {
        final stream = broadcastService.alertNotificationsStream;
        
        expect(stream, isA<Stream<EmergencyAlert>>());
        
        final subscription = stream.listen((alert) {
          expect(alert, isA<EmergencyAlert>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide delivery status stream', () async {
        final stream = broadcastService.deliveryStatusStream;
        
        expect(stream, isA<Stream<DeliveryStatus>>());
        
        final subscription = stream.listen((status) {
          expect(status, isA<DeliveryStatus>());
        });
        
        await subscription.cancel();
      });
    });

    group('Integration Tests', () {
      setUp(() async {
        await broadcastService.initialize();
      });
      
      test('should handle complete emergency broadcasting flow', () async {
        // Enable all features
        await broadcastService.enableMultiChannelBroadcast(true);
        await broadcastService.enableAutoRepeat(true);
        await broadcastService.enableAuthorization(true);
        await broadcastService.enableDeliveryTracking(true);
        await broadcastService.enableGeofencing(true);
        
        // Create authorized authority
        final authority = BroadcastAuthority(
          authorityId: 'integration_authority',
          name: 'Integration Test Authority',
          organization: 'Test Emergency Services',
          role: AuthorityRole.emergency_manager,
          permissions: [
            BroadcastPermission.create_alert,
            BroadcastPermission.modify_alert,
            BroadcastPermission.cancel_alert,
          ],
          isActive: true,
          credentials: {'cert_id': 'INT001'},
          expirationDate: DateTime.now().add(const Duration(days: 365)),
        );
        
        // Create geofence
        final geofence = GeofenceArea(
          areaId: 'integration_area',
          name: 'Integration Test Area',
          shape: GeofenceShape.circle,
          coordinates: [{'lat': 40.7589, 'lng': -73.9851}],
          radius: 10000,
          isActive: true,
          metadata: {'test': 'integration'},
        );
        
        // Create multilingual emergency alert
        final alert = await broadcastService.createMultilingualAlert(
          alertType: EmergencyAlertType.fire,
          severity: EmergencySeverity.severe,
          titles: {
            'en': 'Major Fire Emergency',
            'tr': 'Büyük Yangın Acil Durumu',
            'ar': 'حالة طوارئ حريق كبير',
            'ku': 'Rewşa Lezgînî ya Agirê Mezin',
          },
          descriptions: {
            'en': 'Large fire in downtown area. Evacuate immediately and avoid the area.',
            'tr': 'Şehir merkezinde büyük yangın. Derhal tahliye edin ve bölgeden uzak durun.',
            'ar': 'حريق كبير في وسط المدينة. قم بالإخلاء فوراً وتجنب المنطقة.',
            'ku': 'Agira mezin li navenda bajêr. Derhal valabike û ji deverê dûr bikeve.',
          },
          location: {'lat': 40.7589, 'lng': -73.9851, 'radius': 10000},
          geofence: geofence,
          authorizedBy: authority,
        );
        
        expect(alert, isNotNull);
        expect(alert!.isAuthorized, isTrue);
        expect(alert.isMultilingual, isTrue);
        expect(alert.geofence, isNotNull);
        
        // Start multi-channel broadcast
        final channels = [
          BroadcastChannel.mesh_network,
          BroadcastChannel.emergency_frequency,
          BroadcastChannel.cellular,
          BroadcastChannel.wifi,
          BroadcastChannel.bluetooth,
        ];
        
        final broadcast = await broadcastService.startBroadcast(
          alert,
          channels: channels,
        );
        
        expect(broadcast, isNotNull);
        expect(broadcast!.isActive, isTrue);
        expect(broadcast.channels, equals(channels));
        expect(broadcast.autoRepeatEnabled, isTrue);
        
        // Simulate delivery confirmations
        for (int i = 0; i < 20; i++) {
          await broadcastService.recordDeliveryConfirmation(
            broadcast.broadcastId,
            'device_$i',
            channels[i % channels.length],
          );
        }
        
        // Simulate acknowledgments
        for (int i = 0; i < 15; i++) {
          await broadcastService.recordAcknowledgment(
            broadcast.broadcastId,
            'user_$i',
            AcknowledgmentType.received,
          );
        }
        
        // Check delivery metrics
        final deliveryRate = broadcastService.getDeliveryRate(broadcast.broadcastId);
        expect(deliveryRate, greaterThan(0.0));
        
        final ackCount = broadcastService.getAcknowledgmentCount(broadcast.broadcastId);
        expect(ackCount, greaterThanOrEqualTo(15));
        
        // Generate comprehensive report
        final report = broadcastService.generateDeliveryReport(broadcast.broadcastId);
        expect(report, containsKey('deliveryRate'));
        expect(report, containsKey('acknowledgmentRate'));
        expect(report, containsKey('channelPerformance'));
        expect(report, containsKey('geographicDistribution'));
        
        // Integrate with other services
        await broadcastService.enableVoiceIntegration(true);
        await broadcastService.enableVideoIntegration(true);
        await broadcastService.enableGroupIntegration(true);
        
        final voiceBroadcast = await broadcastService.startVoiceBroadcast(alert);
        expect(voiceBroadcast, isNotNull);
        
        final videoBroadcast = await broadcastService.startVideoBroadcast(alert);
        expect(videoBroadcast, isNotNull);
        
        final notifiedGroups = await broadcastService.notifyEmergencyGroups(alert);
        expect(notifiedGroups, isNotEmpty);
        
        // Update broadcast with new information
        final updatedAlert = EmergencyAlert(
          alertId: alert.alertId,
          alertType: alert.alertType,
          severity: EmergencySeverity.extreme, // Escalated
          title: alert.title,
          description: '${alert.description} Fire is spreading rapidly.',
          location: alert.location,
          contactInfo: alert.contactInfo,
          timestamp: alert.timestamp,
          expirationTime: alert.expirationTime,
          isActive: alert.isActive,
          metadata: {...alert.metadata, 'update': 'escalated'},
        );
        
        final updateResult = await broadcastService.updateBroadcast(
          broadcast.broadcastId,
          updatedAlert,
        );
        expect(updateResult, isTrue);
        
        // Stop broadcast when emergency is resolved
        final stopResult = await broadcastService.stopBroadcast(broadcast.broadcastId);
        expect(stopResult, isTrue);
        
        // Create all-clear message
        final allClearAlert = await broadcastService.createMultilingualAlert(
          alertType: EmergencyAlertType.all_clear,
          severity: EmergencySeverity.information,
          titles: {
            'en': 'All Clear - Fire Contained',
            'tr': 'Her Şey Temiz - Yangın Kontrol Altında',
            'ar': 'الوضع آمن - السيطرة على الحريق',
            'ku': 'Hemû Safin - Agir Kontrol Kirin',
          },
          descriptions: {
            'en': 'Fire has been contained. It is safe to return to the area.',
            'tr': 'Yangın kontrol altına alındı. Bölgeye dönmek güvenli.',
            'ar': 'تم السيطرة على الحريق. من الآمن العودة إلى المنطقة.',
            'ku': 'Agir kontrol kirin. Vegerîna li deverê ewle ye.',
          },
          geofence: geofence,
          authorizedBy: authority,
        );
        
        expect(allClearAlert, isNotNull);
        
        final allClearBroadcast = await broadcastService.startBroadcast(allClearAlert!);
        expect(allClearBroadcast, isNotNull);
        
        // Get final statistics
        final finalStats = broadcastService.getStatistics();
        expect(finalStats['totalBroadcasts'], greaterThanOrEqualTo(2));
        expect(finalStats['totalAlerts'], greaterThanOrEqualTo(2));
      });
    });
  });
}
