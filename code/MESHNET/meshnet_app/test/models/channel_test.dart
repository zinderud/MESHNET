// test/models/channel_test.dart - Channel Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/channel.dart';

void main() {
  group('ChannelType Tests', () {
    test('should have all channel types', () {
      expect(ChannelType.values.length, 4);
      expect(ChannelType.values, contains(ChannelType.public));
      expect(ChannelType.values, contains(ChannelType.private));
      expect(ChannelType.values, contains(ChannelType.emergency));
      expect(ChannelType.values, contains(ChannelType.broadcast));
    });
  });

  group('ChannelSecurity Tests', () {
    test('should have all security levels', () {
      expect(ChannelSecurity.values.length, 4);
      expect(ChannelSecurity.values, contains(ChannelSecurity.open));
      expect(ChannelSecurity.values, contains(ChannelSecurity.encrypted));
      expect(ChannelSecurity.values, contains(ChannelSecurity.verified));
      expect(ChannelSecurity.values, contains(ChannelSecurity.secure));
    });
  });

  group('UserRole Tests', () {
    test('should have all user roles', () {
      expect(UserRole.values.length, 4);
      expect(UserRole.values, contains(UserRole.member));
      expect(UserRole.values, contains(UserRole.moderator));
      expect(UserRole.values, contains(UserRole.admin));
      expect(UserRole.values, contains(UserRole.owner));
    });

    test('should have correct permission hierarchy', () {
      // Owner has highest permissions
      expect(UserRole.owner.index, 3);
      expect(UserRole.admin.index, 2);
      expect(UserRole.moderator.index, 1);
      expect(UserRole.member.index, 0); // Lowest permissions
    });
  });

  group('ChannelPermissions Tests', () {
    late ChannelPermissions defaultPermissions;
    late ChannelPermissions restrictedPermissions;

    setUp(() {
      defaultPermissions = ChannelPermissions();
      restrictedPermissions = ChannelPermissions(
        canSendMessages: false,
        canSendFiles: false,
        canInviteUsers: false,
        canKickUsers: false,
        canBanUsers: false,
        canDeleteMessages: false,
        canEditChannel: false,
        canManageRoles: false,
      );
    });

    test('should have default permissions', () {
      expect(defaultPermissions.canSendMessages, true);
      expect(defaultPermissions.canSendFiles, true);
      expect(defaultPermissions.canInviteUsers, false);
      expect(defaultPermissions.canKickUsers, false);
      expect(defaultPermissions.canBanUsers, false);
      expect(defaultPermissions.canDeleteMessages, false);
      expect(defaultPermissions.canEditChannel, false);
      expect(defaultPermissions.canManageRoles, false);
    });

    test('should copy with updated permissions', () {
      final updatedPermissions = defaultPermissions.copyWith(
        canInviteUsers: true,
        canDeleteMessages: true,
      );

      expect(updatedPermissions.canSendMessages, true); // Unchanged
      expect(updatedPermissions.canSendFiles, true); // Unchanged
      expect(updatedPermissions.canInviteUsers, true); // Changed
      expect(updatedPermissions.canDeleteMessages, true); // Changed
      expect(updatedPermissions.canKickUsers, false); // Unchanged
    });

    test('should serialize to JSON correctly', () {
      final json = defaultPermissions.toJson();

      expect(json['canSendMessages'], true);
      expect(json['canSendFiles'], true);
      expect(json['canInviteUsers'], false);
      expect(json['canKickUsers'], false);
      expect(json['canBanUsers'], false);
      expect(json['canDeleteMessages'], false);
      expect(json['canEditChannel'], false);
      expect(json['canManageRoles'], false);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'canSendMessages': false,
        'canSendFiles': true,
        'canInviteUsers': true,
        'canKickUsers': false,
        'canBanUsers': true,
        'canDeleteMessages': true,
        'canEditChannel': false,
        'canManageRoles': true,
      };

      final permissions = ChannelPermissions.fromJson(json);

      expect(permissions.canSendMessages, false);
      expect(permissions.canSendFiles, true);
      expect(permissions.canInviteUsers, true);
      expect(permissions.canKickUsers, false);
      expect(permissions.canBanUsers, true);
      expect(permissions.canDeleteMessages, true);
      expect(permissions.canEditChannel, false);
      expect(permissions.canManageRoles, true);
    });
  });

  group('ChannelInvitation Tests', () {
    late ChannelInvitation testInvitation;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testInvitation = ChannelInvitation(
        id: 'invitation_123',
        channelId: 'channel_456',
        inviterId: 'inviter_789',
        inviteeId: 'invitee_012',
        createdAt: testTimestamp,
      );
    });

    test('should create invitation with required fields', () {
      expect(testInvitation.id, 'invitation_123');
      expect(testInvitation.channelId, 'channel_456');
      expect(testInvitation.inviterId, 'inviter_789');
      expect(testInvitation.inviteeId, 'invitee_012');
      expect(testInvitation.createdAt, testTimestamp);
    });

    test('should have default values for optional fields', () {
      expect(testInvitation.expiresAt, isNull);
      expect(testInvitation.message, isNull);
      expect(testInvitation.acceptedAt, isNull);
      expect(testInvitation.rejectedAt, isNull);
    });

    test('should detect expired invitations', () {
      final expiredInvitation = ChannelInvitation(
        id: 'expired_123',
        channelId: 'channel_456',
        inviterId: 'inviter_789',
        inviteeId: 'invitee_012',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().subtract(Duration(hours: 1)), // Already expired
      );

      final validInvitation = ChannelInvitation(
        id: 'valid_123',
        channelId: 'channel_456',
        inviterId: 'inviter_789',
        inviteeId: 'invitee_012',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)), // Not expired
      );

      expect(expiredInvitation.isExpired, true);
      expect(validInvitation.isExpired, false);
      expect(testInvitation.isExpired, false); // No expiry time
    });

    test('should detect pending invitations', () {
      final pendingInvitation = testInvitation;
      
      final acceptedInvitation = testInvitation.copyWith(
        acceptedAt: DateTime.now(),
      );
      
      final rejectedInvitation = testInvitation.copyWith(
        rejectedAt: DateTime.now(),
      );

      expect(pendingInvitation.isPending, true);
      expect(acceptedInvitation.isPending, false);
      expect(rejectedInvitation.isPending, false);
    });

    test('should accept invitation correctly', () {
      final acceptTime = DateTime.now();
      testInvitation.accept(acceptTime);

      expect(testInvitation.acceptedAt, acceptTime);
      expect(testInvitation.rejectedAt, isNull);
      expect(testInvitation.isPending, false);
    });

    test('should reject invitation correctly', () {
      final rejectTime = DateTime.now();
      testInvitation.reject(rejectTime);

      expect(testInvitation.rejectedAt, rejectTime);
      expect(testInvitation.acceptedAt, isNull);
      expect(testInvitation.isPending, false);
    });

    test('should copy invitation with updated fields', () {
      final updatedInvitation = testInvitation.copyWith(
        message: 'Join our emergency channel',
        expiresAt: DateTime.now().add(Duration(days: 1)),
      );

      expect(updatedInvitation.id, testInvitation.id); // Unchanged
      expect(updatedInvitation.channelId, testInvitation.channelId); // Unchanged
      expect(updatedInvitation.message, 'Join our emergency channel'); // Changed
      expect(updatedInvitation.expiresAt, isNotNull); // Changed
    });

    test('should serialize to JSON correctly', () {
      final json = testInvitation.toJson();

      expect(json['id'], 'invitation_123');
      expect(json['channelId'], 'channel_456');
      expect(json['inviterId'], 'inviter_789');
      expect(json['inviteeId'], 'invitee_012');
      expect(json['createdAt'], testTimestamp.millisecondsSinceEpoch);
      expect(json['expiresAt'], isNull);
      expect(json['message'], isNull);
      expect(json['acceptedAt'], isNull);
      expect(json['rejectedAt'], isNull);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'json_invitation_456',
        'channelId': 'json_channel_789',
        'inviterId': 'json_inviter_012',
        'inviteeId': 'json_invitee_345',
        'createdAt': testTimestamp.millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch,
        'message': 'Please join our channel',
        'acceptedAt': null,
        'rejectedAt': null,
      };

      final invitation = ChannelInvitation.fromJson(json);

      expect(invitation.id, 'json_invitation_456');
      expect(invitation.channelId, 'json_channel_789');
      expect(invitation.inviterId, 'json_inviter_012');
      expect(invitation.inviteeId, 'json_invitee_345');
      expect(invitation.message, 'Please join our channel');
      expect(invitation.expiresAt, isNotNull);
      expect(invitation.acceptedAt, isNull);
      expect(invitation.rejectedAt, isNull);
    });
  });

  group('MeshChannel Tests', () {
    late MeshChannel testChannel;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testChannel = MeshChannel(
        id: 'test_channel_123',
        name: 'Test Channel',
        description: 'A test channel for unit tests',
        type: ChannelType.public,
        security: ChannelSecurity.encrypted,
        ownerId: 'owner_123',
        createdAt: testTimestamp,
      );
    });

    test('should create channel with required fields', () {
      expect(testChannel.id, 'test_channel_123');
      expect(testChannel.name, 'Test Channel');
      expect(testChannel.description, 'A test channel for unit tests');
      expect(testChannel.type, ChannelType.public);
      expect(testChannel.security, ChannelSecurity.encrypted);
      expect(testChannel.ownerId, 'owner_123');
      expect(testChannel.createdAt, testTimestamp);
    });

    test('should have default values for optional fields', () {
      expect(testChannel.members, isEmpty);
      expect(testChannel.memberRoles, isEmpty);
      expect(testChannel.permissions, isEmpty);
      expect(testChannel.maxMembers, isNull);
      expect(testChannel.isActive, true);
      expect(testChannel.lastActivity, isNull);
      expect(testChannel.metadata, isEmpty);
    });

    test('should get member count correctly', () {
      expect(testChannel.memberCount, 0);

      final channelWithMembers = testChannel.copyWith(
        members: ['member1', 'member2', 'member3'],
      );

      expect(channelWithMembers.memberCount, 3);
    });

    test('should check if user is member', () {
      final channelWithMembers = testChannel.copyWith(
        members: ['member1', 'member2', 'member3'],
      );

      expect(channelWithMembers.isMember('member1'), true);
      expect(channelWithMembers.isMember('member4'), false);
      expect(channelWithMembers.isMember('owner_123'), false); // Owner not in members list
    });

    test('should check if user is owner', () {
      expect(testChannel.isOwner('owner_123'), true);
      expect(testChannel.isOwner('member1'), false);
    });

    test('should get user role correctly', () {
      final channelWithRoles = testChannel.copyWith(
        members: ['member1', 'member2', 'admin1'],
        memberRoles: {
          'member1': UserRole.member,
          'member2': UserRole.moderator,
          'admin1': UserRole.admin,
        },
      );

      expect(channelWithRoles.getUserRole('owner_123'), UserRole.owner);
      expect(channelWithRoles.getUserRole('member1'), UserRole.member);
      expect(channelWithRoles.getUserRole('member2'), UserRole.moderator);
      expect(channelWithRoles.getUserRole('admin1'), UserRole.admin);
      expect(channelWithRoles.getUserRole('nonmember'), isNull);
    });

    test('should get user permissions correctly', () {
      final defaultPermissions = ChannelPermissions();
      final modPermissions = ChannelPermissions(
        canInviteUsers: true,
        canDeleteMessages: true,
      );

      final channelWithPermissions = testChannel.copyWith(
        members: ['member1', 'mod1'],
        memberRoles: {
          'member1': UserRole.member,
          'mod1': UserRole.moderator,
        },
        permissions: {
          UserRole.member: defaultPermissions,
          UserRole.moderator: modPermissions,
        },
      );

      final memberPerms = channelWithPermissions.getUserPermissions('member1');
      final modPerms = channelWithPermissions.getUserPermissions('mod1');
      final ownerPerms = channelWithPermissions.getUserPermissions('owner_123');

      expect(memberPerms?.canInviteUsers, false);
      expect(modPerms?.canInviteUsers, true);
      expect(modPerms?.canDeleteMessages, true);
      expect(ownerPerms, isNotNull); // Owner gets full permissions
    });

    test('should check if channel is full', () {
      final channelWithLimit = testChannel.copyWith(
        maxMembers: 3,
        members: ['member1', 'member2'],
      );

      final fullChannel = testChannel.copyWith(
        maxMembers: 2,
        members: ['member1', 'member2'],
      );

      expect(channelWithLimit.isFull, false);
      expect(fullChannel.isFull, true);
      expect(testChannel.isFull, false); // No limit
    });

    test('should add member correctly', () {
      expect(testChannel.members, isEmpty);

      testChannel.addMember('new_member', UserRole.member);

      expect(testChannel.members, contains('new_member'));
      expect(testChannel.memberRoles['new_member'], UserRole.member);
    });

    test('should not add duplicate member', () {
      testChannel.addMember('member1', UserRole.member);
      expect(testChannel.members.length, 1);

      testChannel.addMember('member1', UserRole.moderator); // Try to add again
      expect(testChannel.members.length, 1); // Should not increase
      expect(testChannel.memberRoles['member1'], UserRole.member); // Role unchanged
    });

    test('should remove member correctly', () {
      testChannel.addMember('member1', UserRole.member);
      testChannel.addMember('member2', UserRole.moderator);
      expect(testChannel.members.length, 2);

      testChannel.removeMember('member1');

      expect(testChannel.members, isNot(contains('member1')));
      expect(testChannel.members, contains('member2'));
      expect(testChannel.memberRoles.containsKey('member1'), false);
      expect(testChannel.memberRoles.containsKey('member2'), true);
    });

    test('should not remove owner', () {
      testChannel.addMember('member1', UserRole.member);
      expect(testChannel.members.length, 1);

      testChannel.removeMember('owner_123'); // Try to remove owner

      expect(testChannel.ownerId, 'owner_123'); // Owner unchanged
      expect(testChannel.members.length, 1); // Members unchanged
    });

    test('should update member role correctly', () {
      testChannel.addMember('member1', UserRole.member);
      expect(testChannel.memberRoles['member1'], UserRole.member);

      testChannel.updateMemberRole('member1', UserRole.moderator);
      expect(testChannel.memberRoles['member1'], UserRole.moderator);
    });

    test('should not update role for non-member', () {
      final originalRoles = Map.from(testChannel.memberRoles);

      testChannel.updateMemberRole('nonmember', UserRole.admin);

      expect(testChannel.memberRoles, equals(originalRoles)); // No change
    });

    test('should update last activity correctly', () {
      expect(testChannel.lastActivity, isNull);

      final activityTime = DateTime.now();
      testChannel.updateLastActivity(activityTime);

      expect(testChannel.lastActivity, activityTime);
    });

    test('should copy channel with updated fields', () {
      final updatedChannel = testChannel.copyWith(
        name: 'Updated Channel',
        description: 'Updated description',
        isActive: false,
        maxMembers: 50,
      );

      expect(updatedChannel.id, testChannel.id); // Unchanged
      expect(updatedChannel.ownerId, testChannel.ownerId); // Unchanged
      expect(updatedChannel.name, 'Updated Channel'); // Changed
      expect(updatedChannel.description, 'Updated description'); // Changed
      expect(updatedChannel.isActive, false); // Changed
      expect(updatedChannel.maxMembers, 50); // Changed
    });

    test('should serialize to JSON correctly', () {
      testChannel.addMember('member1', UserRole.member);
      testChannel.addMember('mod1', UserRole.moderator);

      final json = testChannel.toJson();

      expect(json['id'], 'test_channel_123');
      expect(json['name'], 'Test Channel');
      expect(json['description'], 'A test channel for unit tests');
      expect(json['type'], 'public');
      expect(json['security'], 'encrypted');
      expect(json['ownerId'], 'owner_123');
      expect(json['createdAt'], testTimestamp.millisecondsSinceEpoch);
      expect(json['members'], ['member1', 'mod1']);
      expect(json['memberRoles'], {
        'member1': 'member',
        'mod1': 'moderator',
      });
      expect(json['isActive'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'json_channel_456',
        'name': 'JSON Channel',
        'description': 'Channel from JSON',
        'type': 'private',
        'security': 'secure',
        'ownerId': 'json_owner_789',
        'createdAt': testTimestamp.millisecondsSinceEpoch,
        'members': ['json_member1', 'json_member2'],
        'memberRoles': {
          'json_member1': 'member',
          'json_member2': 'admin',
        },
        'maxMembers': 100,
        'isActive': false,
        'metadata': {'category': 'emergency'},
      };

      final channel = MeshChannel.fromJson(json);

      expect(channel.id, 'json_channel_456');
      expect(channel.name, 'JSON Channel');
      expect(channel.description, 'Channel from JSON');
      expect(channel.type, ChannelType.private);
      expect(channel.security, ChannelSecurity.secure);
      expect(channel.ownerId, 'json_owner_789');
      expect(channel.members, ['json_member1', 'json_member2']);
      expect(channel.memberRoles['json_member1'], UserRole.member);
      expect(channel.memberRoles['json_member2'], UserRole.admin);
      expect(channel.maxMembers, 100);
      expect(channel.isActive, false);
      expect(channel.metadata, {'category': 'emergency'});
    });

    test('should implement equality correctly', () {
      final channel1 = MeshChannel(
        id: 'same_id',
        name: 'Channel 1',
        description: 'Description 1',
        type: ChannelType.public,
        security: ChannelSecurity.open,
        ownerId: 'owner1',
        createdAt: DateTime.now(),
      );

      final channel2 = MeshChannel(
        id: 'same_id',
        name: 'Channel 2', // Different name
        description: 'Description 2', // Different description
        type: ChannelType.private, // Different type
        security: ChannelSecurity.secure, // Different security
        ownerId: 'owner2', // Different owner
        createdAt: DateTime.now(),
      );

      final channel3 = MeshChannel(
        id: 'different_id',
        name: 'Channel 1',
        description: 'Description 1',
        type: ChannelType.public,
        security: ChannelSecurity.open,
        ownerId: 'owner1',
        createdAt: DateTime.now(),
      );

      expect(channel1, equals(channel2)); // Same ID
      expect(channel1, isNot(equals(channel3))); // Different ID
      expect(channel1.hashCode, equals(channel2.hashCode)); // Same hash
    });
  });
}
