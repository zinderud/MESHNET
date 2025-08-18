// lib/services/communication/group_communication.dart - Group Communication
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:meshnet_app/services/communication/real_time_voice_communication.dart';
import 'package:meshnet_app/services/communication/video_calling_streaming.dart';
import 'package:meshnet_app/services/communication/file_transfer_sharing.dart';
import 'package:meshnet_app/services/security/quantum_resistant_crypto.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Group types
enum GroupType {
  emergency_response,     // Emergency response team
  disaster_coordination,  // Disaster coordination group
  rescue_operation,       // Rescue operation team
  medical_team,          // Medical response team
  communication_hub,     // Communication hub group
  public_safety,         // Public safety group
  community_support,     // Community support group
  technical_support,     // Technical support team
  logistics_team,        // Logistics coordination
  general_chat,          // General chat group
}

/// Group roles
enum GroupRole {
  coordinator,           // Group coordinator
  emergency_lead,        // Emergency response leader
  medical_lead,          // Medical team leader
  communication_lead,    // Communication coordinator
  technical_lead,        // Technical coordinator
  logistics_lead,        // Logistics coordinator
  responder,            // Active responder
  observer,             // Observer (read-only)
  volunteer,            // Volunteer member
  civilian,             // Civilian member
}

/// Group priority levels
enum GroupPriority {
  emergency_critical,    // Emergency critical priority
  emergency_high,        // Emergency high priority
  emergency_normal,      // Emergency normal priority
  operational_high,      // Operational high priority
  operational_normal,    // Operational normal priority
  informational,         // Informational priority
  community,             // Community priority
}

/// Group communication modes
enum GroupCommMode {
  text_only,             // Text messages only
  voice_enabled,         // Voice communication enabled
  video_enabled,         // Video communication enabled
  multimedia,            // Full multimedia support
  emergency_broadcast,   // Emergency broadcast mode
  coordination_mode,     // Coordination mode
  discussion_mode,       // Discussion mode
  briefing_mode,         // Briefing mode
}

/// Group message types
enum GroupMessageType {
  text_message,          // Regular text message
  voice_message,         // Voice message
  emergency_alert,       // Emergency alert
  status_update,         // Status update
  location_share,        // Location sharing
  file_share,           // File sharing
  coordination_update,   // Coordination update
  medical_report,        // Medical report
  situation_report,      // Situation report
  resource_request,      // Resource request
  assignment_task,       // Task assignment
  acknowledgment,        // Message acknowledgment
}

/// Group states
enum GroupState {
  inactive,              // Group inactive
  active,                // Group active
  emergency_active,      // Emergency active mode
  coordination_mode,     // Coordination mode
  briefing_active,       // Briefing in progress
  operation_active,      // Operation active
  standby,              // Standby mode
  disbanded,            // Group disbanded
}

/// Group message
class GroupMessage {
  final String messageId;
  final String groupId;
  final String senderId;
  final String senderName;
  final GroupRole senderRole;
  final GroupMessageType messageType;
  final String content;
  final DateTime timestamp;
  final GroupPriority priority;
  final List<String> mentions;
  final Map<String, dynamic> metadata;
  final bool isEmergency;
  final bool requiresAcknowledgment;
  final List<String> acknowledgedBy;
  final Map<String, dynamic> attachments;

  GroupMessage({
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.messageType,
    required this.content,
    required this.timestamp,
    required this.priority,
    required this.mentions,
    required this.metadata,
    required this.isEmergency,
    required this.requiresAcknowledgment,
    required this.acknowledgedBy,
    required this.attachments,
  });

  bool get isAcknowledged => acknowledgedBy.isNotEmpty;
  bool get hasMentions => mentions.isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole.toString(),
      'messageType': messageType.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority.toString(),
      'mentions': mentions,
      'metadata': metadata,
      'isEmergency': isEmergency,
      'requiresAcknowledgment': requiresAcknowledgment,
      'acknowledgedBy': acknowledgedBy,
      'attachments': attachments,
    };
  }
}

/// Group member
class GroupMember {
  final String memberId;
  final String memberName;
  final GroupRole role;
  final DateTime joinedAt;
  final bool isOnline;
  final bool isActive;
  final DateTime lastSeen;
  final Map<String, dynamic> status;
  final List<String> capabilities;
  final Map<String, dynamic> location;
  final Map<String, dynamic> metadata;

  GroupMember({
    required this.memberId,
    required this.memberName,
    required this.role,
    required this.joinedAt,
    required this.isOnline,
    required this.isActive,
    required this.lastSeen,
    required this.status,
    required this.capabilities,
    required this.location,
    required this.metadata,
  });

  bool get isCoordinator => role == GroupRole.coordinator;
  bool get isLead => [
    GroupRole.emergency_lead,
    GroupRole.medical_lead,
    GroupRole.communication_lead,
    GroupRole.technical_lead,
    GroupRole.logistics_lead,
  ].contains(role);

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'role': role.toString(),
      'joinedAt': joinedAt.toIso8601String(),
      'isOnline': isOnline,
      'isActive': isActive,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status,
      'capabilities': capabilities,
      'location': location,
      'metadata': metadata,
    };
  }
}

/// Communication group
class CommunicationGroup {
  final String groupId;
  final String groupName;
  final String description;
  final GroupType groupType;
  final GroupPriority priority;
  final GroupCommMode communicationMode;
  final GroupState state;
  final String coordinatorId;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> permissions;
  final bool isEmergencyGroup;
  final bool isPrivate;
  final int maxMembers;

  CommunicationGroup({
    required this.groupId,
    required this.groupName,
    required this.description,
    required this.groupType,
    required this.priority,
    required this.communicationMode,
    required this.state,
    required this.coordinatorId,
    required this.members,
    required this.createdAt,
    this.lastActivity,
    required this.settings,
    required this.permissions,
    required this.isEmergencyGroup,
    required this.isPrivate,
    required this.maxMembers,
  });

  int get memberCount => members.length;
  int get onlineMemberCount => members.where((m) => m.isOnline).length;
  int get activeMemberCount => members.where((m) => m.isActive).length;
  bool get isActive => state != GroupState.inactive && state != GroupState.disbanded;
  bool get isFull => members.length >= maxMembers;

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'description': description,
      'groupType': groupType.toString(),
      'priority': priority.toString(),
      'communicationMode': communicationMode.toString(),
      'state': state.toString(),
      'coordinatorId': coordinatorId,
      'members': members.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'settings': settings,
      'permissions': permissions,
      'isEmergencyGroup': isEmergencyGroup,
      'isPrivate': isPrivate,
      'maxMembers': maxMembers,
      'memberCount': memberCount,
      'onlineMemberCount': onlineMemberCount,
      'activeMemberCount': activeMemberCount,
    };
  }
}

/// Group session
class GroupSession {
  final String sessionId;
  final String groupId;
  final String sessionName;
  final GroupCommMode sessionType;
  final String initiatorId;
  final List<String> participants;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final Map<String, dynamic> sessionData;

  GroupSession({
    required this.sessionId,
    required this.groupId,
    required this.sessionName,
    required this.sessionType,
    required this.initiatorId,
    required this.participants,
    required this.startTime,
    this.endTime,
    required this.isActive,
    required this.sessionData,
  });

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'groupId': groupId,
      'sessionName': sessionName,
      'sessionType': sessionType.toString(),
      'initiatorId': initiatorId,
      'participants': participants,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive,
      'duration': duration.inMinutes,
      'sessionData': sessionData,
    };
  }
}

/// Group statistics
class GroupStatistics {
  final String groupId;
  final int totalMessages;
  final int emergencyMessages;
  final int voiceMessages;
  final int fileShares;
  final double activityScore;
  final Map<GroupRole, int> roleDistribution;
  final Map<GroupMessageType, int> messageTypeDistribution;
  final Duration averageResponseTime;
  final double participationRate;

  GroupStatistics({
    required this.groupId,
    required this.totalMessages,
    required this.emergencyMessages,
    required this.voiceMessages,
    required this.fileShares,
    required this.activityScore,
    required this.roleDistribution,
    required this.messageTypeDistribution,
    required this.averageResponseTime,
    required this.participationRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'totalMessages': totalMessages,
      'emergencyMessages': emergencyMessages,
      'voiceMessages': voiceMessages,
      'fileShares': fileShares,
      'activityScore': activityScore,
      'roleDistribution': roleDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'messageTypeDistribution': messageTypeDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'averageResponseTime': averageResponseTime.inSeconds,
      'participationRate': participationRate,
    };
  }
}

/// Group Communication Service
class GroupCommunication {
  static GroupCommunication? _instance;
  static GroupCommunication get instance => _instance ??= GroupCommunication._internal();
  
  GroupCommunication._internal();

  final Logger _logger = Logger('GroupCommunication');
  
  bool _isInitialized = false;
  Timer? _activityTimer;
  Timer? _statusTimer;
  Timer? _cleanupTimer;
  
  // Group management
  final Map<String, CommunicationGroup> _groups = {};
  final Map<String, List<GroupMessage>> _groupMessages = {};
  final Map<String, GroupSession> _activeSessions = {};
  final Map<String, GroupStatistics> _groupStatistics = {};
  final Map<String, DateTime> _memberLastActivity = {};
  
  // Current user state
  String? _currentUserId;
  String? _currentUserName;
  final Map<String, GroupRole> _userRoles = {};
  final Set<String> _joinedGroups = {};
  
  // Communication integrations
  RealTimeVoiceCommunication? _voiceService;
  VideoCallingStreaming? _videoService;
  FileTransferSharing? _fileService;
  
  // Performance tracking
  int _totalGroupsCreated = 0;
  int _totalMessages = 0;
  int _emergencyMessages = 0;
  double _averageGroupSize = 0.0;
  
  // Streaming controllers
  final StreamController<GroupMessage> _messageController = 
      StreamController<GroupMessage>.broadcast();
  final StreamController<CommunicationGroup> _groupStateController = 
      StreamController<CommunicationGroup>.broadcast();
  final StreamController<GroupMember> _memberStatusController = 
      StreamController<GroupMember>.broadcast();

  bool get isInitialized => _isInitialized;
  int get activeGroups => _groups.values.where((g) => g.isActive).length;
  int get joinedGroupsCount => _joinedGroups.length;
  Stream<GroupMessage> get messageStream => _messageController.stream;
  Stream<CommunicationGroup> get groupStateStream => _groupStateController.stream;
  Stream<GroupMember> get memberStatusStream => _memberStatusController.stream;

  /// Initialize group communication system
  Future<bool> initialize({
    required String userId,
    required String userName,
    RealTimeVoiceCommunication? voiceService,
    VideoCallingStreaming? videoService,
    FileTransferSharing? fileService,
  }) async {
    try {
      _logger.info('Initializing Group Communication system...');
      
      _currentUserId = userId;
      _currentUserName = userName;
      _voiceService = voiceService;
      _videoService = videoService;
      _fileService = fileService;
      
      // Start monitoring timers
      _startActivityMonitoring();
      _startStatusUpdates();
      _startCleanupTasks();
      
      _isInitialized = true;
      _logger.info('Group Communication system initialized successfully');
      return true;
    } catch (e) {
      _logger.severe('Failed to initialize group communication system', e);
      return false;
    }
  }

  /// Shutdown group communication system
  Future<void> shutdown() async {
    _logger.info('Shutting down Group Communication system...');
    
    // Leave all groups
    for (final groupId in _joinedGroups.toList()) {
      await leaveGroup(groupId);
    }
    
    // End all active sessions
    for (final session in _activeSessions.values) {
      await endGroupSession(session.sessionId);
    }
    
    // Cancel timers
    _activityTimer?.cancel();
    _statusTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Close controllers
    await _messageController.close();
    await _groupStateController.close();
    await _memberStatusController.close();
    
    _isInitialized = false;
    _logger.info('Group Communication system shut down');
  }

  /// Create group
  Future<String?> createGroup({
    required String groupName,
    required String description,
    required GroupType groupType,
    GroupPriority priority = GroupPriority.operational_normal,
    GroupCommMode communicationMode = GroupCommMode.multimedia,
    bool isEmergencyGroup = false,
    bool isPrivate = false,
    int maxMembers = 50,
    Map<String, dynamic>? settings,
  }) async {
    if (!_isInitialized || _currentUserId == null) {
      _logger.warning('Group communication system not initialized');
      return null;
    }

    try {
      final groupId = _generateGroupId();
      
      // Create coordinator member
      final coordinator = GroupMember(
        memberId: _currentUserId!,
        memberName: _currentUserName!,
        role: GroupRole.coordinator,
        joinedAt: DateTime.now(),
        isOnline: true,
        isActive: true,
        lastSeen: DateTime.now(),
        status: {'status': 'active'},
        capabilities: ['text', 'voice', 'video', 'file'],
        location: {},
        metadata: {},
      );
      
      final group = CommunicationGroup(
        groupId: groupId,
        groupName: groupName,
        description: description,
        groupType: groupType,
        priority: priority,
        communicationMode: communicationMode,
        state: GroupState.active,
        coordinatorId: _currentUserId!,
        members: [coordinator],
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
        settings: settings ?? _getDefaultGroupSettings(),
        permissions: _getDefaultPermissions(),
        isEmergencyGroup: isEmergencyGroup,
        isPrivate: isPrivate,
        maxMembers: maxMembers,
      );
      
      _groups[groupId] = group;
      _groupMessages[groupId] = [];
      _userRoles[groupId] = GroupRole.coordinator;
      _joinedGroups.add(groupId);
      
      // Initialize group statistics
      _groupStatistics[groupId] = GroupStatistics(
        groupId: groupId,
        totalMessages: 0,
        emergencyMessages: 0,
        voiceMessages: 0,
        fileShares: 0,
        activityScore: 0.0,
        roleDistribution: {GroupRole.coordinator: 1},
        messageTypeDistribution: {},
        averageResponseTime: Duration.zero,
        participationRate: 1.0,
      );
      
      _totalGroupsCreated++;
      _groupStateController.add(group);
      
      _logger.info('Created group: $groupId ($groupName)');
      return groupId;
    } catch (e) {
      _logger.severe('Failed to create group: $groupName', e);
      return null;
    }
  }

  /// Join group
  Future<bool> joinGroup({
    required String groupId,
    String? inviteCode,
    GroupRole requestedRole = GroupRole.responder,
  }) async {
    if (!_isInitialized || _currentUserId == null) {
      _logger.warning('Group communication system not initialized');
      return false;
    }

    try {
      final group = _groups[groupId];
      if (group == null) {
        _logger.warning('Group not found: $groupId');
        return false;
      }
      
      if (group.isFull) {
        _logger.warning('Group is full: $groupId');
        return false;
      }
      
      // Check if already a member
      if (_joinedGroups.contains(groupId)) {
        _logger.warning('Already a member of group: $groupId');
        return true;
      }
      
      // Validate invite code for private groups
      if (group.isPrivate && !_validateInviteCode(groupId, inviteCode)) {
        _logger.warning('Invalid invite code for private group: $groupId');
        return false;
      }
      
      // Create member
      final member = GroupMember(
        memberId: _currentUserId!,
        memberName: _currentUserName!,
        role: requestedRole,
        joinedAt: DateTime.now(),
        isOnline: true,
        isActive: true,
        lastSeen: DateTime.now(),
        status: {'status': 'active'},
        capabilities: ['text', 'voice', 'video', 'file'],
        location: {},
        metadata: {},
      );
      
      // Add to group
      final updatedMembers = [...group.members, member];
      final updatedGroup = CommunicationGroup(
        groupId: group.groupId,
        groupName: group.groupName,
        description: group.description,
        groupType: group.groupType,
        priority: group.priority,
        communicationMode: group.communicationMode,
        state: group.state,
        coordinatorId: group.coordinatorId,
        members: updatedMembers,
        createdAt: group.createdAt,
        lastActivity: DateTime.now(),
        settings: group.settings,
        permissions: group.permissions,
        isEmergencyGroup: group.isEmergencyGroup,
        isPrivate: group.isPrivate,
        maxMembers: group.maxMembers,
      );
      
      _groups[groupId] = updatedGroup;
      _userRoles[groupId] = requestedRole;
      _joinedGroups.add(groupId);
      
      // Send join notification
      await _sendJoinNotification(groupId, member);
      
      _groupStateController.add(updatedGroup);
      
      _logger.info('Joined group: $groupId as ${requestedRole.toString()}');
      return true;
    } catch (e) {
      _logger.severe('Failed to join group: $groupId', e);
      return false;
    }
  }

  /// Leave group
  Future<bool> leaveGroup(String groupId) async {
    if (!_isInitialized || _currentUserId == null) {
      return false;
    }

    try {
      final group = _groups[groupId];
      if (group == null || !_joinedGroups.contains(groupId)) {
        return false;
      }
      
      // Remove member from group
      final updatedMembers = group.members.where((m) => m.memberId != _currentUserId).toList();
      
      // Handle coordinator leaving
      String newCoordinatorId = group.coordinatorId;
      if (group.coordinatorId == _currentUserId && updatedMembers.isNotEmpty) {
        // Transfer coordination to first lead or any member
        final newCoordinator = updatedMembers.firstWhere(
          (m) => m.isLead,
          orElse: () => updatedMembers.first,
        );
        newCoordinatorId = newCoordinator.memberId;
      }
      
      final updatedGroup = CommunicationGroup(
        groupId: group.groupId,
        groupName: group.groupName,
        description: group.description,
        groupType: group.groupType,
        priority: group.priority,
        communicationMode: group.communicationMode,
        state: updatedMembers.isEmpty ? GroupState.disbanded : group.state,
        coordinatorId: newCoordinatorId,
        members: updatedMembers,
        createdAt: group.createdAt,
        lastActivity: DateTime.now(),
        settings: group.settings,
        permissions: group.permissions,
        isEmergencyGroup: group.isEmergencyGroup,
        isPrivate: group.isPrivate,
        maxMembers: group.maxMembers,
      );
      
      if (updatedMembers.isEmpty) {
        // Disband empty group
        _groups.remove(groupId);
        _groupMessages.remove(groupId);
        _groupStatistics.remove(groupId);
      } else {
        _groups[groupId] = updatedGroup;
      }
      
      _userRoles.remove(groupId);
      _joinedGroups.remove(groupId);
      
      // Send leave notification
      await _sendLeaveNotification(groupId, _currentUserId!);
      
      _logger.info('Left group: $groupId');
      return true;
    } catch (e) {
      _logger.severe('Failed to leave group: $groupId', e);
      return false;
    }
  }

  /// Send group message
  Future<bool> sendGroupMessage({
    required String groupId,
    required String content,
    GroupMessageType messageType = GroupMessageType.text_message,
    GroupPriority priority = GroupPriority.operational_normal,
    List<String> mentions = const [],
    bool requiresAcknowledgment = false,
    Map<String, dynamic> attachments = const {},
  }) async {
    if (!_isInitialized || _currentUserId == null) {
      _logger.warning('Group communication system not initialized');
      return false;
    }

    try {
      final group = _groups[groupId];
      if (group == null || !_joinedGroups.contains(groupId)) {
        _logger.warning('Not a member of group: $groupId');
        return false;
      }
      
      final userRole = _userRoles[groupId] ?? GroupRole.civilian;
      
      final message = GroupMessage(
        messageId: _generateMessageId(),
        groupId: groupId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        senderRole: userRole,
        messageType: messageType,
        content: content,
        timestamp: DateTime.now(),
        priority: priority,
        mentions: mentions,
        metadata: {
          'groupType': group.groupType.toString(),
          'messageLength': content.length,
        },
        isEmergency: priority == GroupPriority.emergency_critical || 
                     priority == GroupPriority.emergency_high ||
                     messageType == GroupMessageType.emergency_alert,
        requiresAcknowledgment: requiresAcknowledgment,
        acknowledgedBy: [],
        attachments: attachments,
      );
      
      // Add to group messages
      _groupMessages[groupId] ??= [];
      _groupMessages[groupId]!.add(message);
      
      // Update group activity
      await _updateGroupActivity(groupId);
      
      // Update statistics
      await _updateMessageStatistics(groupId, message);
      
      // Send to group members
      await _distributeGroupMessage(message);
      
      _totalMessages++;
      if (message.isEmergency) {
        _emergencyMessages++;
      }
      
      _messageController.add(message);
      
      _logger.info('Sent group message: ${message.messageId} to $groupId');
      return true;
    } catch (e) {
      _logger.severe('Failed to send group message to $groupId', e);
      return false;
    }
  }

  /// Send emergency alert
  Future<bool> sendEmergencyAlert({
    required String groupId,
    required String alertMessage,
    required String emergencyType,
    Map<String, dynamic>? location,
    bool requiresImmedateResponse = true,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Group communication system not initialized');
      return false;
    }

    try {
      final attachments = <String, dynamic>{
        'emergencyType': emergencyType,
        'location': location ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'requiresResponse': requiresImmedateResponse,
      };
      
      return await sendGroupMessage(
        groupId: groupId,
        content: alertMessage,
        messageType: GroupMessageType.emergency_alert,
        priority: GroupPriority.emergency_critical,
        requiresAcknowledgment: requiresImmedateResponse,
        attachments: attachments,
      );
    } catch (e) {
      _logger.severe('Failed to send emergency alert to $groupId', e);
      return false;
    }
  }

  /// Acknowledge message
  Future<bool> acknowledgeMessage(String messageId) async {
    if (!_isInitialized || _currentUserId == null) {
      return false;
    }

    try {
      // Find message in all groups
      for (final groupId in _joinedGroups) {
        final messages = _groupMessages[groupId] ?? [];
        final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
        
        if (messageIndex != -1) {
          final message = messages[messageIndex];
          if (!message.acknowledgedBy.contains(_currentUserId)) {
            final updatedAcknowledgedBy = [...message.acknowledgedBy, _currentUserId!];
            
            final updatedMessage = GroupMessage(
              messageId: message.messageId,
              groupId: message.groupId,
              senderId: message.senderId,
              senderName: message.senderName,
              senderRole: message.senderRole,
              messageType: message.messageType,
              content: message.content,
              timestamp: message.timestamp,
              priority: message.priority,
              mentions: message.mentions,
              metadata: message.metadata,
              isEmergency: message.isEmergency,
              requiresAcknowledgment: message.requiresAcknowledgment,
              acknowledgedBy: updatedAcknowledgedBy,
              attachments: message.attachments,
            );
            
            messages[messageIndex] = updatedMessage;
            
            // Send acknowledgment notification
            await _sendAcknowledgmentNotification(message.senderId, messageId);
            
            _logger.info('Acknowledged message: $messageId');
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      _logger.severe('Failed to acknowledge message: $messageId', e);
      return false;
    }
  }

  /// Start group voice session
  Future<String?> startGroupVoiceSession({
    required String groupId,
    String? sessionName,
  }) async {
    if (!_isInitialized || _voiceService == null) {
      _logger.warning('Voice service not available');
      return null;
    }

    try {
      final group = _groups[groupId];
      if (group == null || !_joinedGroups.contains(groupId)) {
        return null;
      }
      
      final sessionId = _generateSessionId();
      
      // Get active members
      final activeMembers = group.members.where((m) => m.isOnline).map((m) => m.memberId).toList();
      
      final session = GroupSession(
        sessionId: sessionId,
        groupId: groupId,
        sessionName: sessionName ?? 'Group Voice Session',
        sessionType: GroupCommMode.voice_enabled,
        initiatorId: _currentUserId!,
        participants: activeMembers,
        startTime: DateTime.now(),
        isActive: true,
        sessionData: {'type': 'voice'},
      );
      
      _activeSessions[sessionId] = session;
      
      // Notify group members
      await _notifyGroupSession(groupId, session);
      
      _logger.info('Started group voice session: $sessionId for $groupId');
      return sessionId;
    } catch (e) {
      _logger.severe('Failed to start group voice session for $groupId', e);
      return null;
    }
  }

  /// Start group video session
  Future<String?> startGroupVideoSession({
    required String groupId,
    String? sessionName,
  }) async {
    if (!_isInitialized || _videoService == null) {
      _logger.warning('Video service not available');
      return null;
    }

    try {
      final group = _groups[groupId];
      if (group == null || !_joinedGroups.contains(groupId)) {
        return null;
      }
      
      final sessionId = _generateSessionId();
      
      // Get active members
      final activeMembers = group.members.where((m) => m.isOnline).map((m) => m.memberId).toList();
      
      final session = GroupSession(
        sessionId: sessionId,
        groupId: groupId,
        sessionName: sessionName ?? 'Group Video Session',
        sessionType: GroupCommMode.video_enabled,
        initiatorId: _currentUserId!,
        participants: activeMembers,
        startTime: DateTime.now(),
        isActive: true,
        sessionData: {'type': 'video'},
      );
      
      _activeSessions[sessionId] = session;
      
      // Notify group members
      await _notifyGroupSession(groupId, session);
      
      _logger.info('Started group video session: $sessionId for $groupId');
      return sessionId;
    } catch (e) {
      _logger.severe('Failed to start group video session for $groupId', e);
      return null;
    }
  }

  /// Share file to group
  Future<bool> shareFileToGroup({
    required String groupId,
    required String filePath,
    String? description,
  }) async {
    if (!_isInitialized || _fileService == null) {
      _logger.warning('File service not available');
      return false;
    }

    try {
      final group = _groups[groupId];
      if (group == null || !_joinedGroups.contains(groupId)) {
        return false;
      }
      
      // Get active members as recipients
      final recipients = group.members.where((m) => m.isOnline && m.memberId != _currentUserId).map((m) => m.memberId).toList();
      
      final transferId = await _fileService!.sendFile(
        filePath: filePath,
        recipients: recipients,
        priority: group.isEmergencyGroup 
            ? FilePriority.emergency_high 
            : FilePriority.normal,
        isEmergencyFile: group.isEmergencyGroup,
      );
      
      if (transferId != null) {
        // Send file share message
        await sendGroupMessage(
          groupId: groupId,
          content: description ?? 'Shared file: ${filePath.split('/').last}',
          messageType: GroupMessageType.file_share,
          attachments: {
            'transferId': transferId,
            'filePath': filePath,
            'fileName': filePath.split('/').last,
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.severe('Failed to share file to group $groupId', e);
      return false;
    }
  }

  /// End group session
  Future<bool> endGroupSession(String sessionId) async {
    try {
      final session = _activeSessions[sessionId];
      if (session == null) {
        return false;
      }
      
      final endedSession = GroupSession(
        sessionId: session.sessionId,
        groupId: session.groupId,
        sessionName: session.sessionName,
        sessionType: session.sessionType,
        initiatorId: session.initiatorId,
        participants: session.participants,
        startTime: session.startTime,
        endTime: DateTime.now(),
        isActive: false,
        sessionData: session.sessionData,
      );
      
      _activeSessions.remove(sessionId);
      
      // Notify participants
      await _notifySessionEnded(endedSession);
      
      _logger.info('Ended group session: $sessionId');
      return true;
    } catch (e) {
      _logger.severe('Failed to end group session: $sessionId', e);
      return false;
    }
  }

  /// Update member status
  Future<bool> updateMemberStatus({
    required String groupId,
    required Map<String, dynamic> status,
    Map<String, dynamic>? location,
  }) async {
    if (!_isInitialized || _currentUserId == null) {
      return false;
    }

    try {
      final group = _groups[groupId];
      if (group == null || !_joinedGroups.contains(groupId)) {
        return false;
      }
      
      final memberIndex = group.members.indexWhere((m) => m.memberId == _currentUserId);
      if (memberIndex == -1) {
        return false;
      }
      
      final member = group.members[memberIndex];
      final updatedMember = GroupMember(
        memberId: member.memberId,
        memberName: member.memberName,
        role: member.role,
        joinedAt: member.joinedAt,
        isOnline: member.isOnline,
        isActive: member.isActive,
        lastSeen: DateTime.now(),
        status: status,
        capabilities: member.capabilities,
        location: location ?? member.location,
        metadata: member.metadata,
      );
      
      final updatedMembers = [...group.members];
      updatedMembers[memberIndex] = updatedMember;
      
      final updatedGroup = CommunicationGroup(
        groupId: group.groupId,
        groupName: group.groupName,
        description: group.description,
        groupType: group.groupType,
        priority: group.priority,
        communicationMode: group.communicationMode,
        state: group.state,
        coordinatorId: group.coordinatorId,
        members: updatedMembers,
        createdAt: group.createdAt,
        lastActivity: group.lastActivity,
        settings: group.settings,
        permissions: group.permissions,
        isEmergencyGroup: group.isEmergencyGroup,
        isPrivate: group.isPrivate,
        maxMembers: group.maxMembers,
      );
      
      _groups[groupId] = updatedGroup;
      _memberLastActivity[_currentUserId!] = DateTime.now();
      
      _memberStatusController.add(updatedMember);
      
      return true;
    } catch (e) {
      _logger.severe('Failed to update member status for $groupId', e);
      return false;
    }
  }

  /// Get group
  CommunicationGroup? getGroup(String groupId) {
    return _groups[groupId];
  }

  /// Get group messages
  List<GroupMessage> getGroupMessages(String groupId, {int? limit}) {
    final messages = _groupMessages[groupId] ?? [];
    if (limit != null && limit < messages.length) {
      return messages.sublist(messages.length - limit);
    }
    return List.from(messages);
  }

  /// Get joined groups
  List<CommunicationGroup> getJoinedGroups() {
    return _joinedGroups.map((id) => _groups[id]).where((g) => g != null).cast<CommunicationGroup>().toList();
  }

  /// Get group statistics
  GroupStatistics? getGroupStatistics(String groupId) {
    return _groupStatistics[groupId];
  }

  /// Get active sessions
  List<GroupSession> getActiveSessions() {
    return _activeSessions.values.toList();
  }

  /// Get system statistics
  Map<String, dynamic> getStatistics() {
    final typeDistribution = <GroupType, int>{};
    final priorityDistribution = <GroupPriority, int>{};
    final commModeDistribution = <GroupCommMode, int>{};
    
    for (final group in _groups.values) {
      typeDistribution[group.groupType] = (typeDistribution[group.groupType] ?? 0) + 1;
      priorityDistribution[group.priority] = (priorityDistribution[group.priority] ?? 0) + 1;
      commModeDistribution[group.communicationMode] = (commModeDistribution[group.communicationMode] ?? 0) + 1;
    }
    
    _averageGroupSize = _groups.values.isNotEmpty 
        ? _groups.values.map((g) => g.memberCount).reduce((a, b) => a + b) / _groups.length 
        : 0.0;
    
    return {
      'initialized': _isInitialized,
      'totalGroups': _groups.length,
      'activeGroups': activeGroups,
      'joinedGroups': joinedGroupsCount,
      'totalGroupsCreated': _totalGroupsCreated,
      'totalMessages': _totalMessages,
      'emergencyMessages': _emergencyMessages,
      'averageGroupSize': _averageGroupSize,
      'activeSessions': _activeSessions.length,
      'typeDistribution': typeDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'priorityDistribution': priorityDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'commModeDistribution': commModeDistribution.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  /// Private helper methods
  Map<String, dynamic> _getDefaultGroupSettings() {
    return {
      'messageHistory': true,
      'fileSharing': true,
      'voiceCalls': true,
      'videoCalls': true,
      'memberInvites': true,
      'publicJoin': false,
      'moderationEnabled': true,
      'emergencyOverride': true,
    };
  }

  Map<String, dynamic> _getDefaultPermissions() {
    return {
      'sendMessages': [GroupRole.coordinator, GroupRole.emergency_lead, GroupRole.responder],
      'inviteMembers': [GroupRole.coordinator, GroupRole.emergency_lead],
      'removeMembers': [GroupRole.coordinator],
      'changeSettings': [GroupRole.coordinator],
      'sendEmergencyAlerts': [GroupRole.coordinator, GroupRole.emergency_lead],
      'startVoiceSessions': [GroupRole.coordinator, GroupRole.emergency_lead, GroupRole.communication_lead],
      'startVideoSessions': [GroupRole.coordinator, GroupRole.emergency_lead, GroupRole.communication_lead],
    };
  }

  bool _validateInviteCode(String groupId, String? inviteCode) {
    // Simple invite code validation
    return inviteCode != null && inviteCode.isNotEmpty;
  }

  Future<void> _sendJoinNotification(String groupId, GroupMember member) async {
    await sendGroupMessage(
      groupId: groupId,
      content: '${member.memberName} joined the group as ${member.role.toString().split('.').last}',
      messageType: GroupMessageType.status_update,
      priority: GroupPriority.informational,
    );
  }

  Future<void> _sendLeaveNotification(String groupId, String memberId) async {
    final member = _groups[groupId]?.members.firstWhere((m) => m.memberId == memberId);
    if (member != null) {
      await sendGroupMessage(
        groupId: groupId,
        content: '${member.memberName} left the group',
        messageType: GroupMessageType.status_update,
        priority: GroupPriority.informational,
      );
    }
  }

  Future<void> _sendAcknowledgmentNotification(String senderId, String messageId) async {
    _logger.debug('Sent acknowledgment notification for message $messageId to $senderId');
  }

  Future<void> _distributeGroupMessage(GroupMessage message) async {
    // Distribute message to all group members through mesh network
    final group = _groups[message.groupId];
    if (group != null) {
      for (final member in group.members) {
        if (member.memberId != message.senderId && member.isOnline) {
          await _sendMessageToMember(member.memberId, message);
        }
      }
    }
  }

  Future<void> _sendMessageToMember(String memberId, GroupMessage message) async {
    // Send message to specific member through mesh network
    _logger.debug('Sent message ${message.messageId} to member $memberId');
  }

  Future<void> _notifyGroupSession(String groupId, GroupSession session) async {
    await sendGroupMessage(
      groupId: groupId,
      content: 'Started ${session.sessionType.toString().split('.').last} session: ${session.sessionName}',
      messageType: GroupMessageType.status_update,
      priority: GroupPriority.operational_high,
      attachments: {'sessionId': session.sessionId},
    );
  }

  Future<void> _notifySessionEnded(GroupSession session) async {
    await sendGroupMessage(
      groupId: session.groupId,
      content: 'Ended session: ${session.sessionName} (Duration: ${session.duration.inMinutes} minutes)',
      messageType: GroupMessageType.status_update,
      priority: GroupPriority.informational,
    );
  }

  Future<void> _updateGroupActivity(String groupId) async {
    final group = _groups[groupId];
    if (group != null) {
      final updatedGroup = CommunicationGroup(
        groupId: group.groupId,
        groupName: group.groupName,
        description: group.description,
        groupType: group.groupType,
        priority: group.priority,
        communicationMode: group.communicationMode,
        state: group.state,
        coordinatorId: group.coordinatorId,
        members: group.members,
        createdAt: group.createdAt,
        lastActivity: DateTime.now(),
        settings: group.settings,
        permissions: group.permissions,
        isEmergencyGroup: group.isEmergencyGroup,
        isPrivate: group.isPrivate,
        maxMembers: group.maxMembers,
      );
      
      _groups[groupId] = updatedGroup;
    }
  }

  Future<void> _updateMessageStatistics(String groupId, GroupMessage message) async {
    final stats = _groupStatistics[groupId];
    if (stats != null) {
      final messageTypeCount = Map<GroupMessageType, int>.from(stats.messageTypeDistribution);
      messageTypeCount[message.messageType] = (messageTypeCount[message.messageType] ?? 0) + 1;
      
      final updatedStats = GroupStatistics(
        groupId: stats.groupId,
        totalMessages: stats.totalMessages + 1,
        emergencyMessages: message.isEmergency ? stats.emergencyMessages + 1 : stats.emergencyMessages,
        voiceMessages: message.messageType == GroupMessageType.voice_message ? stats.voiceMessages + 1 : stats.voiceMessages,
        fileShares: message.messageType == GroupMessageType.file_share ? stats.fileShares + 1 : stats.fileShares,
        activityScore: (stats.activityScore + 1.0) / 2, // Simple activity scoring
        roleDistribution: stats.roleDistribution,
        messageTypeDistribution: messageTypeCount,
        averageResponseTime: stats.averageResponseTime,
        participationRate: stats.participationRate,
      );
      
      _groupStatistics[groupId] = updatedStats;
    }
  }

  void _startActivityMonitoring() {
    _activityTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _updateMemberActivityStatus();
    });
  }

  void _startStatusUpdates() {
    _statusTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _broadcastStatusUpdates();
    });
  }

  void _startCleanupTasks() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _cleanupInactiveGroups();
    });
  }

  Future<void> _updateMemberActivityStatus() async {
    final now = DateTime.now();
    for (final groupId in _joinedGroups) {
      final group = _groups[groupId];
      if (group != null) {
        bool groupUpdated = false;
        final updatedMembers = <GroupMember>[];
        
        for (final member in group.members) {
          final lastActivity = _memberLastActivity[member.memberId] ?? member.lastSeen;
          final isOnline = now.difference(lastActivity).inMinutes < 5;
          final isActive = now.difference(lastActivity).inMinutes < 30;
          
          if (member.isOnline != isOnline || member.isActive != isActive) {
            groupUpdated = true;
            final updatedMember = GroupMember(
              memberId: member.memberId,
              memberName: member.memberName,
              role: member.role,
              joinedAt: member.joinedAt,
              isOnline: isOnline,
              isActive: isActive,
              lastSeen: member.lastSeen,
              status: member.status,
              capabilities: member.capabilities,
              location: member.location,
              metadata: member.metadata,
            );
            updatedMembers.add(updatedMember);
          } else {
            updatedMembers.add(member);
          }
        }
        
        if (groupUpdated) {
          final updatedGroup = CommunicationGroup(
            groupId: group.groupId,
            groupName: group.groupName,
            description: group.description,
            groupType: group.groupType,
            priority: group.priority,
            communicationMode: group.communicationMode,
            state: group.state,
            coordinatorId: group.coordinatorId,
            members: updatedMembers,
            createdAt: group.createdAt,
            lastActivity: group.lastActivity,
            settings: group.settings,
            permissions: group.permissions,
            isEmergencyGroup: group.isEmergencyGroup,
            isPrivate: group.isPrivate,
            maxMembers: group.maxMembers,
          );
          
          _groups[groupId] = updatedGroup;
          _groupStateController.add(updatedGroup);
        }
      }
    }
  }

  Future<void> _broadcastStatusUpdates() async {
    if (_currentUserId != null) {
      _memberLastActivity[_currentUserId!] = DateTime.now();
      
      for (final groupId in _joinedGroups) {
        await updateMemberStatus(
          groupId: groupId,
          status: {'status': 'active', 'lastUpdate': DateTime.now().toIso8601String()},
        );
      }
    }
  }

  Future<void> _cleanupInactiveGroups() async {
    final now = DateTime.now();
    final inactiveGroups = <String>[];
    
    for (final group in _groups.values) {
      if (group.lastActivity != null) {
        final inactiveDuration = now.difference(group.lastActivity!);
        if (inactiveDuration.inDays > 30 && group.activeMemberCount == 0) {
          inactiveGroups.add(group.groupId);
        }
      }
    }
    
    for (final groupId in inactiveGroups) {
      _groups.remove(groupId);
      _groupMessages.remove(groupId);
      _groupStatistics.remove(groupId);
      _logger.info('Cleaned up inactive group: $groupId');
    }
  }

  String _generateGroupId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'group_${timestamp}_$random';
  }

  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'msg_${timestamp}_$random';
  }

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'session_${timestamp}_$random';
  }
}
