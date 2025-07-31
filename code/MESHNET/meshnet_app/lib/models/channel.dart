// lib/models/channel.dart - MESHNET Channel/Group Models

/// Enum for channel types
enum ChannelType {
  public,      // Public channel, anyone can join
  private,     // Private channel, invite only
  emergency,   // Emergency channel, high priority
  broadcast,   // One-way broadcast channel
  direct,      // Direct message channel between two users
  group,       // Group chat channel
  system,      // System/admin channel
}

/// Enum for channel security levels
enum ChannelSecurity {
  none,        // No encryption
  basic,       // Basic encryption
  enhanced,    // Enhanced encryption with key rotation
  military,    // Military-grade encryption
}

/// Enum for user roles in channels
enum UserRole {
  owner,       // Channel owner, full permissions
  admin,       // Administrator, most permissions
  moderator,   // Moderator, limited permissions
  member,      // Regular member
  readonly,    // Read-only access
  banned,      // Banned from channel
}

/// Model representing a communication channel in MESHNET
class MeshChannel {
  final String channelId;
  final String name;
  final String? description;
  final ChannelType type;
  final ChannelSecurity security;
  final String ownerId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  
  bool isActive;
  int memberCount;
  DateTime lastActivity;
  String? topic;
  List<String> tags;
  Map<String, UserRole> members;
  int maxMembers;
  bool isArchived;

  MeshChannel({
    required this.channelId,
    required this.name,
    this.description,
    required this.type,
    this.security = ChannelSecurity.basic,
    required this.ownerId,
    required this.createdAt,
    this.metadata = const {},
    this.isActive = true,
    this.memberCount = 0,
    required this.lastActivity,
    this.topic,
    this.tags = const [],
    this.members = const {},
    this.maxMembers = 100,
    this.isArchived = false,
  });

  /// Create a copy with updated fields
  MeshChannel copyWith({
    String? channelId,
    String? name,
    String? description,
    ChannelType? type,
    ChannelSecurity? security,
    String? ownerId,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    bool? isActive,
    int? memberCount,
    DateTime? lastActivity,
    String? topic,
    List<String>? tags,
    Map<String, UserRole>? members,
    int? maxMembers,
    bool? isArchived,
  }) {
    return MeshChannel(
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      security: security ?? this.security,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      lastActivity: lastActivity ?? this.lastActivity,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      members: members ?? this.members,
      maxMembers: maxMembers ?? this.maxMembers,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Check if channel is emergency type
  bool get isEmergency => type == ChannelType.emergency;

  /// Check if channel is encrypted
  bool get isEncrypted => security != ChannelSecurity.none;

  /// Check if channel is full
  bool get isFull => memberCount >= maxMembers;

  /// Check if user is owner
  bool isOwner(String userId) => ownerId == userId;

  /// Check if user is admin or owner
  bool isAdminOrOwner(String userId) {
    final role = members[userId];
    return ownerId == userId || role == UserRole.admin;
  }

  /// Check if user can write to channel
  bool canUserWrite(String userId) {
    final role = members[userId];
    return role != null && 
           role != UserRole.readonly && 
           role != UserRole.banned &&
           !isArchived;
  }

  /// Get channel type icon
  String get typeIcon {
    switch (type) {
      case ChannelType.public:
        return '🌐';
      case ChannelType.private:
        return '🔒';
      case ChannelType.emergency:
        return '🚨';
      case ChannelType.broadcast:
        return '📢';
      case ChannelType.direct:
        return '💬';
      case ChannelType.group:
        return '👥';
      case ChannelType.system:
        return '⚙️';
    }
  }

  /// Get security level icon
  String get securityIcon {
    switch (security) {
      case ChannelSecurity.none:
        return '🔓';
      case ChannelSecurity.basic:
        return '🔐';
      case ChannelSecurity.enhanced:
        return '🔒';
      case ChannelSecurity.military:
        return '🛡️';
    }
  }

  /// Get formatted member count
  String get memberCountText {
    if (memberCount == 1) return '1 member';
    return '$memberCount members';
  }

  /// Get time since last activity
  String get lastActivityText {
    final diff = DateTime.now().difference(lastActivity);
    if (diff.inMinutes < 1) return 'Active now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'name': name,
      'description': description,
      'type': type.name,
      'security': security.name,
      'ownerId': ownerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
      'isActive': isActive,
      'memberCount': memberCount,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'topic': topic,
      'tags': tags,
      'members': members.map((k, v) => MapEntry(k, v.name)),
      'maxMembers': maxMembers,
      'isArchived': isArchived,
    };
  }

  /// Create from JSON
  factory MeshChannel.fromJson(Map<String, dynamic> json) {
    return MeshChannel(
      channelId: json['channelId'],
      name: json['name'],
      description: json['description'],
      type: ChannelType.values.firstWhere((e) => e.name == json['type']),
      security: ChannelSecurity.values.firstWhere((e) => e.name == json['security']),
      ownerId: json['ownerId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isActive: json['isActive'] ?? true,
      memberCount: json['memberCount'] ?? 0,
      lastActivity: DateTime.fromMillisecondsSinceEpoch(json['lastActivity']),
      topic: json['topic'],
      tags: List<String>.from(json['tags'] ?? []),
      members: (json['members'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, UserRole.values.firstWhere((role) => role.name == v))
      ) ?? {},
      maxMembers: json['maxMembers'] ?? 100,
      isArchived: json['isArchived'] ?? false,
    );
  }

  @override
  String toString() {
    return 'MeshChannel(id: $channelId, name: $name, type: $type, members: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeshChannel && other.channelId == channelId;
  }

  @override
  int get hashCode => channelId.hashCode;
}

/// Model for channel invitations
class ChannelInvitation {
  final String invitationId;
  final String channelId;
  final String fromUserId;
  final String toUserId;
  final UserRole proposedRole;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? message;
  
  InvitationStatus status;

  ChannelInvitation({
    required this.invitationId,
    required this.channelId,
    required this.fromUserId,
    required this.toUserId,
    required this.proposedRole,
    required this.createdAt,
    required this.expiresAt,
    this.message,
    this.status = InvitationStatus.pending,
  });

  /// Check if invitation has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if invitation is still valid
  bool get isValid => status == InvitationStatus.pending && !isExpired;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'channelId': channelId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'proposedRole': proposedRole.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'message': message,
      'status': status.name,
    };
  }

  /// Create from JSON
  factory ChannelInvitation.fromJson(Map<String, dynamic> json) {
    return ChannelInvitation(
      invitationId: json['invitationId'],
      channelId: json['channelId'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      proposedRole: UserRole.values.firstWhere((e) => e.name == json['proposedRole']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt']),
      message: json['message'],
      status: InvitationStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}

/// Enum for invitation status
enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled,
}

/// Model for channel permissions
class ChannelPermissions {
  final bool canRead;
  final bool canWrite;
  final bool canInvite;
  final bool canKick;
  final bool canBan;
  final bool canChangeSettings;
  final bool canDeleteMessages;
  final bool canManageRoles;

  const ChannelPermissions({
    this.canRead = true,
    this.canWrite = true,
    this.canInvite = false,
    this.canKick = false,
    this.canBan = false,
    this.canChangeSettings = false,
    this.canDeleteMessages = false,
    this.canManageRoles = false,
  });

  /// Get permissions for a user role
  factory ChannelPermissions.forRole(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return const ChannelPermissions(
          canRead: true,
          canWrite: true,
          canInvite: true,
          canKick: true,
          canBan: true,
          canChangeSettings: true,
          canDeleteMessages: true,
          canManageRoles: true,
        );
      case UserRole.admin:
        return const ChannelPermissions(
          canRead: true,
          canWrite: true,
          canInvite: true,
          canKick: true,
          canBan: true,
          canChangeSettings: false,
          canDeleteMessages: true,
          canManageRoles: false,
        );
      case UserRole.moderator:
        return const ChannelPermissions(
          canRead: true,
          canWrite: true,
          canInvite: true,
          canKick: true,
          canBan: false,
          canChangeSettings: false,
          canDeleteMessages: true,
          canManageRoles: false,
        );
      case UserRole.member:
        return const ChannelPermissions(
          canRead: true,
          canWrite: true,
          canInvite: false,
          canKick: false,
          canBan: false,
          canChangeSettings: false,
          canDeleteMessages: false,
          canManageRoles: false,
        );
      case UserRole.readonly:
        return const ChannelPermissions(
          canRead: true,
          canWrite: false,
          canInvite: false,
          canKick: false,
          canBan: false,
          canChangeSettings: false,
          canDeleteMessages: false,
          canManageRoles: false,
        );
      case UserRole.banned:
        return const ChannelPermissions(
          canRead: false,
          canWrite: false,
          canInvite: false,
          canKick: false,
          canBan: false,
          canChangeSettings: false,
          canDeleteMessages: false,
          canManageRoles: false,
        );
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'canRead': canRead,
      'canWrite': canWrite,
      'canInvite': canInvite,
      'canKick': canKick,
      'canBan': canBan,
      'canChangeSettings': canChangeSettings,
      'canDeleteMessages': canDeleteMessages,
      'canManageRoles': canManageRoles,
    };
  }

  /// Create from JSON
  factory ChannelPermissions.fromJson(Map<String, dynamic> json) {
    return ChannelPermissions(
      canRead: json['canRead'] ?? true,
      canWrite: json['canWrite'] ?? true,
      canInvite: json['canInvite'] ?? false,
      canKick: json['canKick'] ?? false,
      canBan: json['canBan'] ?? false,
      canChangeSettings: json['canChangeSettings'] ?? false,
      canDeleteMessages: json['canDeleteMessages'] ?? false,
      canManageRoles: json['canManageRoles'] ?? false,
    );
  }
}
