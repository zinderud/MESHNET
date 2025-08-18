// test/services/communication/group_communication_test.dart - Group Communication Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:typed_data';
import 'dart:async';

import 'package:meshnet_app/services/communication/group_communication.dart';

@GenerateMocks([])
class MockGroupStreamController extends Mock implements StreamController<GroupMessage> {}

void main() {
  group('GroupCommunication Tests', () {
    late GroupCommunication groupService;
    
    setUp(() {
      groupService = GroupCommunication.instance;
    });
    
    tearDown(() async {
      if (groupService.isInitialized) {
        await groupService.shutdown();
      }
    });

    group('Service Initialization', () {
      test('should initialize group communication service successfully', () async {
        final result = await groupService.initialize();
        
        expect(result, isTrue);
        expect(groupService.isInitialized, isTrue);
        expect(groupService.maxGroupSize, equals(100));
      });
      
      test('should initialize with custom configuration', () async {
        final config = GroupConfig(
          maxGroupSize: 50,
          maxGroups: 20,
          enableEncryption: true,
          enableMeshIntegration: true,
          defaultRole: GroupRole.member,
          messageRetention: const Duration(days: 30),
          syncInterval: const Duration(seconds: 30),
          emergencyMode: false,
          compressionEnabled: true,
          priorityQueuing: true,
          offlineSupport: true,
        );
        
        final result = await groupService.initialize(config: config);
        
        expect(result, isTrue);
        expect(groupService.maxGroupSize, equals(50));
      });
    });

    group('Group Management', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should create communication group successfully', () async {
        final group = await groupService.createGroup(
          name: 'Test Group',
          description: 'Test group for unit testing',
          groupType: GroupType.coordination,
          isPrivate: false,
        );
        
        expect(group, isNotNull);
        expect(group!.name, equals('Test Group'));
        expect(group.groupType, equals(GroupType.coordination));
        expect(group.isActive, isTrue);
      });
      
      test('should join existing group successfully', () async {
        final group = await groupService.createGroup(
          name: 'Join Test Group',
          description: 'Group for join testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        final joinResult = await groupService.joinGroup(
          group!.groupId,
          userId: 'test_user_123',
        );
        
        expect(joinResult, isTrue);
      });
      
      test('should leave group successfully', () async {
        final group = await groupService.createGroup(
          name: 'Leave Test Group',
          description: 'Group for leave testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'test_user_leave');
        
        final leaveResult = await groupService.leaveGroup(
          group.groupId,
          userId: 'test_user_leave',
        );
        
        expect(leaveResult, isTrue);
      });
      
      test('should delete group successfully', () async {
        final group = await groupService.createGroup(
          name: 'Delete Test Group',
          description: 'Group for delete testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        final deleteResult = await groupService.deleteGroup(group!.groupId);
        
        expect(deleteResult, isTrue);
      });
      
      test('should get group information correctly', () async {
        final group = await groupService.createGroup(
          name: 'Info Test Group',
          description: 'Group for info testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        final groupInfo = await groupService.getGroupInfo(group!.groupId);
        
        expect(groupInfo, isNotNull);
        expect(groupInfo!.name, equals('Info Test Group'));
        expect(groupInfo.groupType, equals(GroupType.coordination));
      });
    });

    group('Group Types and Roles', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should support all group types', () {
        final supportedTypes = groupService.getSupportedGroupTypes();
        
        expect(supportedTypes, isNotEmpty);
        expect(supportedTypes.length, equals(10)); // All 10 group types
        expect(supportedTypes, contains(GroupType.emergency_response));
        expect(supportedTypes, contains(GroupType.medical_team));
        expect(supportedTypes, contains(GroupType.coordination));
      });
      
      test('should create emergency response group with correct permissions', () async {
        final emergencyGroup = await groupService.createGroup(
          name: 'Emergency Response Team',
          description: 'Emergency response coordination',
          groupType: GroupType.emergency_response,
          isPrivate: true,
        );
        
        expect(emergencyGroup, isNotNull);
        expect(emergencyGroup!.groupType, equals(GroupType.emergency_response));
        expect(emergencyGroup.isPrivate, isTrue);
        expect(emergencyGroup.priority, equals(GroupPriority.emergency));
      });
      
      test('should assign and modify member roles correctly', () async {
        final group = await groupService.createGroup(
          name: 'Role Test Group',
          description: 'Group for role testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'role_test_user');
        
        final assignResult = await groupService.assignRole(
          group.groupId,
          'role_test_user',
          GroupRole.moderator,
        );
        
        expect(assignResult, isTrue);
        
        final member = await groupService.getGroupMember(group.groupId, 'role_test_user');
        expect(member, isNotNull);
        expect(member!.role, equals(GroupRole.moderator));
      });
      
      test('should validate role permissions correctly', () {
        final canCreateGroup = groupService.hasPermission(GroupRole.admin, GroupPermission.create_group);
        final canSendMessage = groupService.hasPermission(GroupRole.member, GroupPermission.send_message);
        final canManageMembers = groupService.hasPermission(GroupRole.member, GroupPermission.manage_members);
        
        expect(canCreateGroup, isTrue);
        expect(canSendMessage, isTrue);
        expect(canManageMembers, isFalse); // Members cannot manage other members
      });
    });

    group('Message Handling', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should send group message successfully', () async {
        final group = await groupService.createGroup(
          name: 'Message Test Group',
          description: 'Group for message testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'message_sender');
        
        final message = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'message_sender',
          content: 'Test message content',
          messageType: GroupMessageType.text,
        );
        
        expect(message, isNotNull);
        expect(message!.content, equals('Test message content'));
        expect(message.messageType, equals(GroupMessageType.text));
      });
      
      test('should send multimedia message successfully', () async {
        final group = await groupService.createGroup(
          name: 'Multimedia Test Group',
          description: 'Group for multimedia testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'multimedia_sender');
        
        final mediaData = Uint8List.fromList([1, 2, 3, 4, 5]);
        
        final message = await groupService.sendMultimediaMessage(
          groupId: group.groupId,
          senderId: 'multimedia_sender',
          mediaType: MediaType.image,
          mediaData: mediaData,
          caption: 'Test image',
        );
        
        expect(message, isNotNull);
        expect(message!.messageType, equals(GroupMessageType.multimedia));
        expect(message.mediaData, isNotNull);
      });
      
      test('should send emergency alert successfully', () async {
        final emergencyGroup = await groupService.createGroup(
          name: 'Emergency Alert Group',
          description: 'Group for emergency alerts',
          groupType: GroupType.emergency_response,
        );
        
        expect(emergencyGroup, isNotNull);
        
        await groupService.joinGroup(emergencyGroup!.groupId, userId: 'emergency_sender');
        
        final alert = EmergencyAlert(
          alertId: 'test_alert_123',
          alertType: EmergencyAlertType.medical,
          severity: EmergencySeverity.critical,
          title: 'Medical Emergency',
          description: 'Medical assistance required immediately',
          location: {'lat': 40.7128, 'lng': -74.0060},
          contactInfo: {'phone': '+1234567890'},
          timestamp: DateTime.now(),
          expirationTime: DateTime.now().add(const Duration(hours: 2)),
          isActive: true,
          metadata: {'patient_age': '35', 'symptoms': 'chest_pain'},
        );
        
        final message = await groupService.sendEmergencyAlert(
          groupId: emergencyGroup.groupId,
          senderId: 'emergency_sender',
          alert: alert,
        );
        
        expect(message, isNotNull);
        expect(message!.messageType, equals(GroupMessageType.emergency_alert));
        expect(message.priority, equals(MessagePriority.emergency));
      });
      
      test('should receive group messages correctly', () async {
        final group = await groupService.createGroup(
          name: 'Receive Test Group',
          description: 'Group for receive testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'message_receiver');
        
        final messages = await groupService.getGroupMessages(
          group.groupId,
          limit: 10,
        );
        
        expect(messages, isA<List<GroupMessage>>());
      });
      
      test('should handle message reactions correctly', () async {
        final group = await groupService.createGroup(
          name: 'Reaction Test Group',
          description: 'Group for reaction testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'reactor_user');
        
        final message = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'reactor_user',
          content: 'React to this message',
          messageType: GroupMessageType.text,
        );
        
        expect(message, isNotNull);
        
        final reactionResult = await groupService.addReaction(
          message!.messageId,
          'reactor_user',
          '👍',
        );
        
        expect(reactionResult, isTrue);
      });
    });

    group('Multimedia Sessions', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should start group voice session successfully', () async {
        final group = await groupService.createGroup(
          name: 'Voice Session Group',
          description: 'Group for voice session testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'voice_user');
        
        final session = await groupService.startVoiceSession(
          groupId: group.groupId,
          initiatorId: 'voice_user',
        );
        
        expect(session, isNotNull);
        expect(session!.sessionType, equals(SessionType.voice));
        expect(session.isActive, isTrue);
      });
      
      test('should start group video session successfully', () async {
        final group = await groupService.createGroup(
          name: 'Video Session Group',
          description: 'Group for video session testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'video_user');
        
        final session = await groupService.startVideoSession(
          groupId: group.groupId,
          initiatorId: 'video_user',
        );
        
        expect(session, isNotNull);
        expect(session!.sessionType, equals(SessionType.video));
        expect(session.isActive, isTrue);
      });
      
      test('should join multimedia session successfully', () async {
        final group = await groupService.createGroup(
          name: 'Join Session Group',
          description: 'Group for join session testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'session_initiator');
        await groupService.joinGroup(group.groupId, userId: 'session_joiner');
        
        final session = await groupService.startVoiceSession(
          groupId: group.groupId,
          initiatorId: 'session_initiator',
        );
        
        expect(session, isNotNull);
        
        final joinResult = await groupService.joinSession(
          session!.sessionId,
          'session_joiner',
        );
        
        expect(joinResult, isTrue);
      });
      
      test('should leave multimedia session successfully', () async {
        final group = await groupService.createGroup(
          name: 'Leave Session Group',
          description: 'Group for leave session testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'session_leaver');
        
        final session = await groupService.startVoiceSession(
          groupId: group.groupId,
          initiatorId: 'session_leaver',
        );
        
        expect(session, isNotNull);
        
        final leaveResult = await groupService.leaveSession(
          session!.sessionId,
          'session_leaver',
        );
        
        expect(leaveResult, isTrue);
      });
    });

    group('Emergency Coordination', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should activate emergency mode successfully', () async {
        final result = await groupService.activateEmergencyMode();
        
        expect(result, isTrue);
        expect(groupService.isEmergencyMode, isTrue);
      });
      
      test('should create emergency response team automatically', () async {
        await groupService.activateEmergencyMode();
        
        final emergencyTeam = await groupService.createEmergencyResponseTeam(
          incidentId: 'test_incident_123',
          incidentType: EmergencyIncidentType.fire,
          location: {'lat': 40.7128, 'lng': -74.0060},
          severity: EmergencySeverity.high,
        );
        
        expect(emergencyTeam, isNotNull);
        expect(emergencyTeam!.groupType, equals(GroupType.emergency_response));
        expect(emergencyTeam.priority, equals(GroupPriority.emergency));
      });
      
      test('should coordinate emergency response correctly', () async {
        await groupService.activateEmergencyMode();
        
        final incident = EmergencyIncident(
          incidentId: 'coordination_test_incident',
          incidentType: EmergencyIncidentType.medical,
          severity: EmergencySeverity.critical,
          location: {'lat': 40.7128, 'lng': -74.0060},
          description: 'Medical emergency requiring immediate response',
          reportedBy: 'citizen_reporter',
          timestamp: DateTime.now(),
          status: IncidentStatus.active,
          responseTeams: [],
          estimatedResponse: const Duration(minutes: 8),
          metadata: {'patient_count': '1', 'injuries': 'severe'},
        );
        
        final coordination = await groupService.coordinateEmergencyResponse(incident);
        
        expect(coordination, isTrue);
      });
      
      test('should assign emergency response teams correctly', () async {
        await groupService.activateEmergencyMode();
        
        final medicalTeam = await groupService.createGroup(
          name: 'Medical Response Team Alpha',
          description: 'Primary medical response team',
          groupType: GroupType.medical_team,
        );
        
        final fireTeam = await groupService.createGroup(
          name: 'Fire Response Team Bravo',
          description: 'Fire suppression team',
          groupType: GroupType.fire_rescue,
        );
        
        expect(medicalTeam, isNotNull);
        expect(fireTeam, isNotNull);
        
        final assignResult = await groupService.assignResponseTeam(
          'test_incident_assign',
          [medicalTeam!.groupId, fireTeam!.groupId],
        );
        
        expect(assignResult, isTrue);
      });
      
      test('should prioritize emergency messages correctly', () async {
        await groupService.activateEmergencyMode();
        
        final emergencyGroup = await groupService.createGroup(
          name: 'Priority Test Emergency Group',
          description: 'Group for priority testing',
          groupType: GroupType.emergency_response,
        );
        
        expect(emergencyGroup, isNotNull);
        
        await groupService.joinGroup(emergencyGroup!.groupId, userId: 'priority_sender');
        
        final emergencyMessage = await groupService.sendMessage(
          groupId: emergencyGroup.groupId,
          senderId: 'priority_sender',
          content: 'Emergency priority message',
          messageType: GroupMessageType.text,
          priority: MessagePriority.emergency,
        );
        
        final normalMessage = await groupService.sendMessage(
          groupId: emergencyGroup.groupId,
          senderId: 'priority_sender',
          content: 'Normal priority message',
          messageType: GroupMessageType.text,
          priority: MessagePriority.normal,
        );
        
        expect(emergencyMessage, isNotNull);
        expect(normalMessage, isNotNull);
        expect(emergencyMessage!.priority.index, lessThan(normalMessage!.priority.index));
      });
    });

    group('Real-time Synchronization', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should enable real-time sync successfully', () async {
        final result = await groupService.enableRealTimeSync(true);
        
        expect(result, isTrue);
        expect(groupService.isRealTimeSyncEnabled, isTrue);
      });
      
      test('should sync group state across devices', () async {
        await groupService.enableRealTimeSync(true);
        
        final group = await groupService.createGroup(
          name: 'Sync Test Group',
          description: 'Group for sync testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        final syncResult = await groupService.syncGroupState(group!.groupId);
        
        expect(syncResult, isTrue);
      });
      
      test('should handle sync conflicts correctly', () async {
        await groupService.enableRealTimeSync(true);
        
        final group = await groupService.createGroup(
          name: 'Conflict Test Group',
          description: 'Group for conflict testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        // Simulate concurrent modifications
        final message1 = await groupService.sendMessage(
          groupId: group!.groupId,
          senderId: 'user1',
          content: 'Message from user 1',
          messageType: GroupMessageType.text,
        );
        
        final message2 = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'user2',
          content: 'Message from user 2',
          messageType: GroupMessageType.text,
        );
        
        expect(message1, isNotNull);
        expect(message2, isNotNull);
        
        // Both messages should be preserved (no conflicts for different senders)
        final messages = await groupService.getGroupMessages(group.groupId);
        expect(messages.length, greaterThanOrEqualTo(2));
      });
    });

    group('Mesh Integration', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should enable mesh integration successfully', () async {
        final result = await groupService.enableMeshIntegration(true);
        
        expect(result, isTrue);
        expect(groupService.isMeshEnabled, isTrue);
      });
      
      test('should route group messages through mesh network', () async {
        await groupService.enableMeshIntegration(true);
        
        final group = await groupService.createGroup(
          name: 'Mesh Test Group',
          description: 'Group for mesh testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'mesh_sender');
        
        final message = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'mesh_sender',
          content: 'Message via mesh network',
          messageType: GroupMessageType.text,
        );
        
        expect(message, isNotNull);
        expect(message!.isMeshRouted, isTrue);
      });
      
      test('should handle mesh network partitioning', () async {
        await groupService.enableMeshIntegration(true);
        
        final group = await groupService.createGroup(
          name: 'Partition Test Group',
          description: 'Group for partition testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        // Simulate network partition
        await groupService.updateNetworkCondition(NetworkCondition.critical);
        
        final offlineMessage = await groupService.sendMessage(
          groupId: group!.groupId,
          senderId: 'offline_sender',
          content: 'Offline message',
          messageType: GroupMessageType.text,
        );
        
        // Message should be queued for later delivery
        expect(offlineMessage, isNotNull);
        expect(offlineMessage!.deliveryStatus, equals(DeliveryStatus.pending));
      });
    });

    group('Security and Encryption', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should enable group encryption successfully', () async {
        final result = await groupService.enableEncryption(true);
        
        expect(result, isTrue);
        expect(groupService.isEncryptionEnabled, isTrue);
      });
      
      test('should encrypt group messages correctly', () async {
        await groupService.enableEncryption(true);
        
        final group = await groupService.createGroup(
          name: 'Encrypted Group',
          description: 'Group with encryption',
          groupType: GroupType.private,
          isPrivate: true,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'encrypted_sender');
        
        final message = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'encrypted_sender',
          content: 'Encrypted message content',
          messageType: GroupMessageType.text,
        );
        
        expect(message, isNotNull);
        expect(message!.isEncrypted, isTrue);
      });
      
      test('should manage group encryption keys correctly', () async {
        await groupService.enableEncryption(true);
        
        final group = await groupService.createGroup(
          name: 'Key Management Group',
          description: 'Group for key management testing',
          groupType: GroupType.private,
          isPrivate: true,
        );
        
        expect(group, isNotNull);
        
        final keyGenerated = await groupService.generateGroupKey(group!.groupId);
        expect(keyGenerated, isTrue);
        
        final keyRotated = await groupService.rotateGroupKey(group.groupId);
        expect(keyRotated, isTrue);
      });
    });

    group('Performance and Statistics', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should track group statistics', () async {
        // Create multiple groups and messages
        for (int i = 0; i < 5; i++) {
          final group = await groupService.createGroup(
            name: 'Stats Group $i',
            description: 'Group for statistics testing',
            groupType: GroupType.general,
          );
          
          expect(group, isNotNull);
          
          await groupService.joinGroup(group!.groupId, userId: 'stats_user_$i');
          
          await groupService.sendMessage(
            groupId: group.groupId,
            senderId: 'stats_user_$i',
            content: 'Statistics test message $i',
            messageType: GroupMessageType.text,
          );
        }
        
        final stats = groupService.getStatistics();
        
        expect(stats, containsKey('totalGroups'));
        expect(stats, containsKey('activeGroups'));
        expect(stats, containsKey('totalMembers'));
        expect(stats, containsKey('totalMessages'));
        expect(stats, containsKey('emergencyGroups'));
        expect(stats['totalGroups'], greaterThanOrEqualTo(5));
      });
      
      test('should calculate group activity metrics', () async {
        final group = await groupService.createGroup(
          name: 'Activity Metrics Group',
          description: 'Group for activity metrics testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'activity_user');
        
        // Generate some activity
        for (int i = 0; i < 10; i++) {
          await groupService.sendMessage(
            groupId: group.groupId,
            senderId: 'activity_user',
            content: 'Activity message $i',
            messageType: GroupMessageType.text,
          );
        }
        
        final metrics = groupService.getGroupMetrics(group.groupId);
        
        expect(metrics, containsKey('messageCount'));
        expect(metrics, containsKey('memberCount'));
        expect(metrics, containsKey('activityLevel'));
        expect(metrics, containsKey('lastActivity'));
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should handle invalid group ID gracefully', () async {
        final result = await groupService.joinGroup('invalid_group_id', userId: 'test_user');
        
        expect(result, isFalse);
      });
      
      test('should handle duplicate group creation gracefully', () async {
        final group1 = await groupService.createGroup(
          name: 'Duplicate Test Group',
          description: 'First group',
          groupType: GroupType.general,
        );
        
        final group2 = await groupService.createGroup(
          name: 'Duplicate Test Group',
          description: 'Second group with same name',
          groupType: GroupType.general,
        );
        
        expect(group1, isNotNull);
        expect(group2, isNotNull);
        expect(group1!.groupId, isNot(equals(group2!.groupId))); // Should create different groups
      });
      
      test('should handle network disconnection gracefully', () async {
        final group = await groupService.createGroup(
          name: 'Network Test Group',
          description: 'Group for network testing',
          groupType: GroupType.general,
        );
        
        expect(group, isNotNull);
        
        await groupService.joinGroup(group!.groupId, userId: 'network_user');
        
        // Simulate network disconnection
        await groupService.updateNetworkCondition(NetworkCondition.critical);
        
        final message = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'network_user',
          content: 'Message during network issue',
          messageType: GroupMessageType.text,
        );
        
        // Message may be queued or fail, but service should remain stable
        expect(groupService.isInitialized, isTrue);
      });
      
      test('should handle permission violations gracefully', () async {
        final privateGroup = await groupService.createGroup(
          name: 'Private Test Group',
          description: 'Private group for permission testing',
          groupType: GroupType.private,
          isPrivate: true,
        );
        
        expect(privateGroup, isNotNull);
        
        // Try to join without permission
        final joinResult = await groupService.joinGroup(
          privateGroup!.groupId,
          userId: 'unauthorized_user',
        );
        
        expect(joinResult, isFalse);
      });
    });

    group('Stream Management', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should provide group messages stream', () async {
        final stream = groupService.groupMessagesStream;
        
        expect(stream, isA<Stream<GroupMessage>>());
        
        final subscription = stream.listen((message) {
          expect(message, isA<GroupMessage>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide group events stream', () async {
        final stream = groupService.groupEventsStream;
        
        expect(stream, isA<Stream<GroupEvent>>());
        
        final subscription = stream.listen((event) {
          expect(event, isA<GroupEvent>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide emergency alerts stream', () async {
        final stream = groupService.emergencyAlertsStream;
        
        expect(stream, isA<Stream<EmergencyAlert>>());
        
        final subscription = stream.listen((alert) {
          expect(alert, isA<EmergencyAlert>());
        });
        
        await subscription.cancel();
      });
    });

    group('Integration Tests', () {
      setUp(() async {
        await groupService.initialize();
      });
      
      test('should handle complete group communication flow', () async {
        // Create group
        final group = await groupService.createGroup(
          name: 'Integration Test Group',
          description: 'Complete flow testing',
          groupType: GroupType.coordination,
        );
        
        expect(group, isNotNull);
        
        // Add members
        final users = ['user1', 'user2', 'user3'];
        for (final user in users) {
          final joinResult = await groupService.joinGroup(group!.groupId, userId: user);
          expect(joinResult, isTrue);
        }
        
        // Assign roles
        await groupService.assignRole(group!.groupId, 'user1', GroupRole.moderator);
        
        // Send messages
        final textMessage = await groupService.sendMessage(
          groupId: group.groupId,
          senderId: 'user1',
          content: 'Welcome to the integration test group!',
          messageType: GroupMessageType.text,
        );
        
        expect(textMessage, isNotNull);
        
        // Send multimedia message
        final mediaData = Uint8List.fromList(List.generate(1024, (i) => i % 256));
        final multimediaMessage = await groupService.sendMultimediaMessage(
          groupId: group.groupId,
          senderId: 'user2',
          mediaType: MediaType.image,
          mediaData: mediaData,
          caption: 'Integration test image',
        );
        
        expect(multimediaMessage, isNotNull);
        
        // Start multimedia session
        final session = await groupService.startVoiceSession(
          groupId: group.groupId,
          initiatorId: 'user1',
        );
        
        expect(session, isNotNull);
        
        // Join session
        final joinSessionResult = await groupService.joinSession(session!.sessionId, 'user2');
        expect(joinSessionResult, isTrue);
        
        // End session
        final endSessionResult = await groupService.endSession(session.sessionId);
        expect(endSessionResult, isTrue);
        
        // Get group statistics
        final stats = groupService.getGroupMetrics(group.groupId);
        expect(stats['memberCount'], equals(users.length));
        expect(stats['messageCount'], greaterThanOrEqualTo(2));
      });
      
      test('should handle emergency response coordination scenario', () async {
        // Activate emergency mode
        await groupService.activateEmergencyMode();
        expect(groupService.isEmergencyMode, isTrue);
        
        // Create emergency incident
        final incident = EmergencyIncident(
          incidentId: 'integration_emergency_incident',
          incidentType: EmergencyIncidentType.fire,
          severity: EmergencySeverity.high,
          location: {'lat': 40.7128, 'lng': -74.0060},
          description: 'Large fire in downtown area',
          reportedBy: 'fire_spotter',
          timestamp: DateTime.now(),
          status: IncidentStatus.active,
          responseTeams: [],
          estimatedResponse: const Duration(minutes: 12),
          metadata: {'building_type': 'commercial', 'floors': '5'},
        );
        
        // Create emergency response teams
        final fireTeam = await groupService.createEmergencyResponseTeam(
          incidentId: incident.incidentId,
          incidentType: EmergencyIncidentType.fire,
          location: incident.location,
          severity: incident.severity,
        );
        
        expect(fireTeam, isNotNull);
        
        // Add team members
        final teamMembers = ['fire_chief', 'fire_captain', 'paramedic1', 'paramedic2'];
        for (final member in teamMembers) {
          await groupService.joinGroup(fireTeam!.groupId, userId: member);
        }
        
        // Assign roles
        await groupService.assignRole(fireTeam!.groupId, 'fire_chief', GroupRole.admin);
        await groupService.assignRole(fireTeam.groupId, 'fire_captain', GroupRole.moderator);
        
        // Send emergency alert
        final alert = EmergencyAlert(
          alertId: 'integration_fire_alert',
          alertType: EmergencyAlertType.fire,
          severity: EmergencySeverity.high,
          title: 'Commercial Building Fire',
          description: 'Active fire in 5-story commercial building. Immediate response required.',
          location: incident.location,
          contactInfo: {'dispatch': '+1-911-FIRE'},
          timestamp: DateTime.now(),
          expirationTime: DateTime.now().add(const Duration(hours: 4)),
          isActive: true,
          metadata: incident.metadata,
        );
        
        final alertMessage = await groupService.sendEmergencyAlert(
          groupId: fireTeam.groupId,
          senderId: 'fire_chief',
          alert: alert,
        );
        
        expect(alertMessage, isNotNull);
        expect(alertMessage!.priority, equals(MessagePriority.emergency));
        
        // Coordinate response
        final coordinationResult = await groupService.coordinateEmergencyResponse(incident);
        expect(coordinationResult, isTrue);
        
        // Start coordination voice session
        final coordinationSession = await groupService.startVoiceSession(
          groupId: fireTeam.groupId,
          initiatorId: 'fire_chief',
        );
        
        expect(coordinationSession, isNotNull);
        
        // All team members join coordination
        for (final member in teamMembers.skip(1)) {
          final joinResult = await groupService.joinSession(coordinationSession!.sessionId, member);
          expect(joinResult, isTrue);
        }
        
        // Send status updates
        final statusUpdate = await groupService.sendMessage(
          groupId: fireTeam.groupId,
          senderId: 'fire_captain',
          content: 'Fire suppression in progress. Building evacuated.',
          messageType: GroupMessageType.text,
          priority: MessagePriority.high,
        );
        
        expect(statusUpdate, isNotNull);
        
        // Cleanup
        await groupService.endSession(coordinationSession!.sessionId);
        await groupService.deactivateEmergencyMode();
        
        expect(groupService.isEmergencyMode, isFalse);
      });
    });
  });
}
