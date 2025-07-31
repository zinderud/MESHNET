// test/models/mesh_channel_test.dart - Mesh Channel Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/channel.dart';

void main() {
  group('MeshChannel Tests', () {
    test('should create basic mesh channel', () {
      final now = DateTime.now();
      final channel = MeshChannel(
        channelId: 'channel123',
        name: 'Test Channel',
        type: ChannelType.public,
        ownerId: 'owner123',
        createdAt: now,
        lastActivity: now,
      );

      expect(channel.channelId, 'channel123');
      expect(channel.name, 'Test Channel');
      expect(channel.type, ChannelType.public);
      expect(channel.ownerId, 'owner123');
      expect(channel.createdAt, now);
      expect(channel.lastActivity, now);
      expect(channel.security, ChannelSecurity.basic);
      expect(channel.isActive, true);
      expect(channel.memberCount, 0);
      expect(channel.maxMembers, 100);
      expect(channel.isArchived, false);
      expect(channel.description, null);
      expect(channel.topic, null);
      expect(channel.tags, isEmpty);
      expect(channel.members, isEmpty);
      expect(channel.metadata, isEmpty);
    });

    test('should create channel with all properties', () {
      final now = DateTime.now();
      final members = {
        'owner123': UserRole.owner,
        'admin456': UserRole.admin,
        'user789': UserRole.member,
      };
      final metadata = {
        'priority': 'high',
        'region': 'north',
      };

      final channel = MeshChannel(
        channelId: 'full_channel',
        name: 'Full Featured Channel',
        description: 'A channel with all features',
        type: ChannelType.emergency,
        security: ChannelSecurity.military,
        ownerId: 'emergency_admin',
        createdAt: now,
        lastActivity: now,
        metadata: metadata,
        isActive: true,
        memberCount: 25,
        topic: 'Emergency Response Coordination',
        tags: ['emergency', 'rescue', 'medical'],
        members: members,
        maxMembers: 50,
        isArchived: false,
      );

      expect(channel.channelId, 'full_channel');
      expect(channel.name, 'Full Featured Channel');
      expect(channel.description, 'A channel with all features');
      expect(channel.type, ChannelType.emergency);
      expect(channel.security, ChannelSecurity.military);
      expect(channel.ownerId, 'emergency_admin');
      expect(channel.memberCount, 25);
      expect(channel.topic, 'Emergency Response Coordination');
      expect(channel.tags, ['emergency', 'rescue', 'medical']);
      expect(channel.members, members);
      expect(channel.maxMembers, 50);
      expect(channel.metadata, metadata);
    });

    test('should support different channel types', () {
      final channelTypes = [
        ChannelType.public,
        ChannelType.private,
        ChannelType.emergency,
        ChannelType.broadcast,
        ChannelType.direct,
        ChannelType.group,
        ChannelType.system,
      ];

      for (final channelType in channelTypes) {
        final channel = MeshChannel(
          channelId: 'test_${channelType.name}',
          name: 'Test ${channelType.name} Channel',
          type: channelType,
          ownerId: 'test_owner',
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
        );

        expect(channel.type, channelType);
      }
    });

    test('should support different security levels', () {
      final securityLevels = [
        ChannelSecurity.none,
        ChannelSecurity.basic,
        ChannelSecurity.enhanced,
        ChannelSecurity.military,
      ];

      for (final security in securityLevels) {
        final channel = MeshChannel(
          channelId: 'security_${security.name}',
          name: 'Security Test Channel',
          type: ChannelType.private,
          security: security,
          ownerId: 'security_admin',
          createdAt: DateTime.now(),
          lastActivity: DateTime.now(),
        );

        expect(channel.security, security);
      }
    });

    test('should support different user roles', () {
      final members = {
        'owner001': UserRole.owner,
        'admin001': UserRole.admin,
        'admin002': UserRole.admin,
        'mod001': UserRole.moderator,
        'user001': UserRole.member,
        'user002': UserRole.member,
        'readonly001': UserRole.readonly,
        'banned001': UserRole.banned,
      };

      final channel = MeshChannel(
        channelId: 'roles_test',
        name: 'Roles Test Channel',
        type: ChannelType.group,
        ownerId: 'owner001',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        members: members,
        memberCount: members.length,
      );

      expect(channel.members['owner001'], UserRole.owner);
      expect(channel.members['admin001'], UserRole.admin);
      expect(channel.members['mod001'], UserRole.moderator);
      expect(channel.members['user001'], UserRole.member);
      expect(channel.members['readonly001'], UserRole.readonly);
      expect(channel.members['banned001'], UserRole.banned);
    });

    test('should create copy with updated fields', () {
      final originalChannel = MeshChannel(
        channelId: 'original',
        name: 'Original Channel',
        type: ChannelType.public,
        ownerId: 'owner123',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        memberCount: 10,
        isActive: true,
      );

      final updatedChannel = originalChannel.copyWith(
        name: 'Updated Channel',
        type: ChannelType.private,
        memberCount: 15,
        isActive: false,
        topic: 'New Topic',
        tags: ['updated', 'modified'],
      );

      // Check updated fields
      expect(updatedChannel.name, 'Updated Channel');
      expect(updatedChannel.type, ChannelType.private);
      expect(updatedChannel.memberCount, 15);
      expect(updatedChannel.isActive, false);
      expect(updatedChannel.topic, 'New Topic');
      expect(updatedChannel.tags, ['updated', 'modified']);

      // Check unchanged fields
      expect(updatedChannel.channelId, originalChannel.channelId);
      expect(updatedChannel.ownerId, originalChannel.ownerId);
      expect(updatedChannel.createdAt, originalChannel.createdAt);
      expect(updatedChannel.lastActivity, originalChannel.lastActivity);
    });

    test('should handle emergency channels correctly', () {
      final emergencyChannel = MeshChannel(
        channelId: 'emergency_001',
        name: 'Emergency Response',
        description: 'Critical emergency coordination',
        type: ChannelType.emergency,
        security: ChannelSecurity.enhanced,
        ownerId: 'emergency_coordinator',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        topic: 'Building Fire - Floor 5',
        tags: ['fire', 'evacuation', 'urgent'],
        maxMembers: 200, // Large capacity for emergency
      );

      expect(emergencyChannel.type, ChannelType.emergency);
      expect(emergencyChannel.security, ChannelSecurity.enhanced);
      expect(emergencyChannel.maxMembers, 200);
      expect(emergencyChannel.tags.contains('fire'), true);
      expect(emergencyChannel.tags.contains('evacuation'), true);
    });

    test('should handle direct message channels', () {
      final directChannel = MeshChannel(
        channelId: 'dm_user1_user2',
        name: 'Direct: User1 & User2',
        type: ChannelType.direct,
        ownerId: 'user1',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        members: {
          'user1': UserRole.member,
          'user2': UserRole.member,
        },
        memberCount: 2,
        maxMembers: 2, // Only two users in direct message
      );

      expect(directChannel.type, ChannelType.direct);
      expect(directChannel.memberCount, 2);
      expect(directChannel.maxMembers, 2);
      expect(directChannel.members.length, 2);
      expect(directChannel.members.containsKey('user1'), true);
      expect(directChannel.members.containsKey('user2'), true);
    });

    test('should handle broadcast channels', () {
      final broadcastChannel = MeshChannel(
        channelId: 'broadcast_news',
        name: 'Network News',
        description: 'Official network announcements',
        type: ChannelType.broadcast,
        security: ChannelSecurity.basic,
        ownerId: 'network_admin',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        topic: 'Daily Network Status Update',
        maxMembers: 1000, // Large capacity for broadcasts
      );

      expect(broadcastChannel.type, ChannelType.broadcast);
      expect(broadcastChannel.maxMembers, 1000);
      expect(broadcastChannel.topic, 'Daily Network Status Update');
    });

    test('should handle channel archiving', () {
      final channel = MeshChannel(
        channelId: 'old_channel',
        name: 'Old Discussion',
        type: ChannelType.group,
        ownerId: 'admin',
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        lastActivity: DateTime.now().subtract(Duration(days: 30)),
        isActive: false,
        isArchived: true,
      );

      expect(channel.isActive, false);
      expect(channel.isArchived, true);
    });

    test('should manage channel tags correctly', () {
      final channel = MeshChannel(
        channelId: 'tagged_channel',
        name: 'Tagged Channel',
        type: ChannelType.public,
        ownerId: 'owner',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        tags: ['tech', 'development', 'flutter', 'meshnet'],
      );

      expect(channel.tags.length, 4);
      expect(channel.tags.contains('tech'), true);
      expect(channel.tags.contains('development'), true);
      expect(channel.tags.contains('flutter'), true);
      expect(channel.tags.contains('meshnet'), true);
      expect(channel.tags.contains('nonexistent'), false);
    });

    test('should handle member count validation', () {
      final smallChannel = MeshChannel(
        channelId: 'small_channel',
        name: 'Small Group',
        type: ChannelType.group,
        ownerId: 'owner',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        maxMembers: 5,
        memberCount: 3,
      );

      final largeChannel = MeshChannel(
        channelId: 'large_channel',
        name: 'Large Community',
        type: ChannelType.public,
        ownerId: 'admin',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        maxMembers: 500,
        memberCount: 150,
      );

      expect(smallChannel.maxMembers, 5);
      expect(smallChannel.memberCount, 3);
      expect(largeChannel.maxMembers, 500);
      expect(largeChannel.memberCount, 150);

      // Check if channel has capacity
      expect(smallChannel.memberCount < smallChannel.maxMembers, true);
      expect(largeChannel.memberCount < largeChannel.maxMembers, true);
    });

    test('should handle metadata correctly', () {
      final metadata = {
        'priority': 'high',
        'location': 'building_a',
        'department': 'engineering',
        'project': 'meshnet_development',
        'settings': {
          'notifications': true,
          'retention_days': 30,
        },
      };

      final channel = MeshChannel(
        channelId: 'metadata_channel',
        name: 'Metadata Test',
        type: ChannelType.private,
        ownerId: 'project_manager',
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        metadata: metadata,
      );

      expect(channel.metadata, metadata);
      expect(channel.metadata['priority'], 'high');
      expect(channel.metadata['location'], 'building_a');
      expect(channel.metadata['settings'], isA<Map>());
    });
  });
}
