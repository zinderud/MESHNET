// test/models/emergency_message_test.dart - Emergency Message Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/message.dart';

void main() {
  group('EmergencyMessage Tests', () {
    test('should create emergency message with all required fields', () {
      final locationData = {
        'latitude': 41.0082,
        'longitude': 28.9784,
        'accuracy': 10.0,
        'altitude': 39.0,
      };

      final emergencyMessage = EmergencyMessage(
        id: 'emergency123',
        sourceNodeId: 'rescue_node_1',
        content: 'Fire emergency at building',
        emergencyType: 'fire',
        severity: 'high',
        locationData: locationData,
        requiredServices: ['fire_department', 'ambulance'],
      );

      expect(emergencyMessage.id, 'emergency123');
      expect(emergencyMessage.sourceNodeId, 'rescue_node_1');
      expect(emergencyMessage.targetNodeId, null); // Always broadcast
      expect(emergencyMessage.type, MessageType.emergency);
      expect(emergencyMessage.priority, MessagePriority.emergency);
      expect(emergencyMessage.content, 'Fire emergency at building');
      expect(emergencyMessage.emergencyType, 'fire');
      expect(emergencyMessage.severity, 'high');
      expect(emergencyMessage.locationData, locationData);
      expect(emergencyMessage.requiredServices, ['fire_department', 'ambulance']);
      expect(emergencyMessage.encrypted, false); // Emergency messages not encrypted
      expect(emergencyMessage.isBroadcast, true);
    });

    test('should have proper default values', () {
      final locationData = {'latitude': 0.0, 'longitude': 0.0};

      final emergencyMessage = EmergencyMessage(
        id: 'emergency_default',
        sourceNodeId: 'node1',
        content: 'Medical emergency',
        emergencyType: 'medical',
        severity: 'critical',
        locationData: locationData,
      );

      expect(emergencyMessage.requiredServices, isEmpty);
      expect(emergencyMessage.priority, MessagePriority.emergency);
      expect(emergencyMessage.encrypted, false);
      expect(emergencyMessage.expiryTime, isNotNull);
      
      // Should expire in 24 hours
      final expectedExpiry = DateTime.now().add(Duration(hours: 24));
      final actualExpiry = emergencyMessage.expiryTime!;
      final timeDifference = expectedExpiry.difference(actualExpiry).abs();
      expect(timeDifference.inMinutes, lessThan(1)); // Allow 1 minute tolerance
    });

    test('should serialize to JSON correctly', () {
      final locationData = {
        'latitude': 40.7128,
        'longitude': -74.0060,
        'address': 'New York, NY',
      };

      final emergencyMessage = EmergencyMessage(
        id: 'emergency_json',
        sourceNodeId: 'emergency_node',
        content: 'Earthquake detected',
        emergencyType: 'earthquake',
        severity: 'extreme',
        locationData: locationData,
        requiredServices: ['search_and_rescue', 'medical', 'engineering'],
      );

      final json = emergencyMessage.toJson();

      expect(json['id'], 'emergency_json');
      expect(json['sourceNodeId'], 'emergency_node');
      expect(json['targetNodeId'], null);
      expect(json['type'], 'emergency');
      expect(json['priority'], 'emergency');
      expect(json['content'], 'Earthquake detected');
      expect(json['emergencyType'], 'earthquake');
      expect(json['severity'], 'extreme');
      expect(json['locationData'], locationData);
      expect(json['requiredServices'], ['search_and_rescue', 'medical', 'engineering']);
      expect(json['encrypted'], false);
    });

    test('should deserialize from JSON correctly', () {
      final locationData = {
        'latitude': 35.6762,
        'longitude': 139.6503,
        'city': 'Tokyo',
      };

      final json = {
        'id': 'emergency_from_json',
        'sourceNodeId': 'tokyo_sensor',
        'targetNodeId': null,
        'type': 'emergency',
        'priority': 'emergency',
        'content': 'Tsunami warning',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiryTime': DateTime.now().add(Duration(hours: 12)).millisecondsSinceEpoch,
        'encrypted': false,
        'status': 'draft',
        'retryCount': 0,
        'routePath': <String>[],
        'emergencyType': 'tsunami',
        'severity': 'extreme',
        'locationData': locationData,
        'requiredServices': ['evacuation', 'coast_guard'],
      };

      final emergencyMessage = EmergencyMessage.fromJson(json);

      expect(emergencyMessage.id, 'emergency_from_json');
      expect(emergencyMessage.sourceNodeId, 'tokyo_sensor');
      expect(emergencyMessage.content, 'Tsunami warning');
      expect(emergencyMessage.emergencyType, 'tsunami');
      expect(emergencyMessage.severity, 'extreme');
      expect(emergencyMessage.locationData, locationData);
      expect(emergencyMessage.requiredServices, ['evacuation', 'coast_guard']);
    });

    test('should handle empty required services in JSON', () {
      final json = {
        'id': 'emergency_minimal',
        'sourceNodeId': 'node1',
        'type': 'emergency',
        'priority': 'emergency',
        'content': 'Minor incident',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'draft',
        'retryCount': 0,
        'routePath': <String>[],
        'emergencyType': 'other',
        'severity': 'low',
        'locationData': {'latitude': 0.0, 'longitude': 0.0},
        // No requiredServices field
      };

      final emergencyMessage = EmergencyMessage.fromJson(json);

      expect(emergencyMessage.requiredServices, isEmpty);
    });

    test('should create different emergency types', () {
      final locationData = {'latitude': 0.0, 'longitude': 0.0};

      final fireEmergency = EmergencyMessage(
        id: 'fire_001',
        sourceNodeId: 'fire_detector',
        content: 'Fire alarm activated',
        emergencyType: 'fire',
        severity: 'high',
        locationData: locationData,
        requiredServices: ['fire_department'],
      );

      final medicalEmergency = EmergencyMessage(
        id: 'medical_001',
        sourceNodeId: 'health_monitor',
        content: 'Cardiac emergency',
        emergencyType: 'medical',
        severity: 'critical',
        locationData: locationData,
        requiredServices: ['ambulance', 'hospital'],
      );

      final naturalDisaster = EmergencyMessage(
        id: 'natural_001',
        sourceNodeId: 'weather_station',
        content: 'Severe storm approaching',
        emergencyType: 'natural_disaster',
        severity: 'extreme',
        locationData: locationData,
        requiredServices: ['evacuation', 'emergency_management'],
      );

      expect(fireEmergency.emergencyType, 'fire');
      expect(medicalEmergency.emergencyType, 'medical');
      expect(naturalDisaster.emergencyType, 'natural_disaster');

      // All should have emergency priority
      expect(fireEmergency.priority, MessagePriority.emergency);
      expect(medicalEmergency.priority, MessagePriority.emergency);
      expect(naturalDisaster.priority, MessagePriority.emergency);
    });
  });
}
