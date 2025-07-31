// lib/models/message.dart - MESHNET Message Models
import 'dart:convert';

/// Enum for message types in the MESHNET system
enum MessageType {
  chat,
  emergency,
  location,
  discovery,
  file,
  system,
  broadcast,
  unicast,
  multicast,
}

/// Enum for message priority levels
enum MessagePriority {
  emergency,  // Highest priority - immediate delivery
  urgent,     // High priority - fast delivery
  high,       // Important - prioritized delivery
  normal,     // Standard - normal delivery
  low,        // Low priority - background delivery
}

/// Enum for message status
enum MessageStatus {
  draft,
  sending,
  sent,
  delivered,
  failed,
  received,
  read,
}

/// Main message model for MESHNET communication
class MeshMessage {
  final String id;
  final String sourceNodeId;
  final String? targetNodeId; // null for broadcast
  final MessageType type;
  final MessagePriority priority;
  final String content;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final DateTime? expiryTime;
  final bool encrypted;
  final String? signature;
  
  MessageStatus status;
  int retryCount;
  List<String> routePath; // Nodes this message has passed through
  
  MeshMessage({
    required this.id,
    required this.sourceNodeId,
    this.targetNodeId,
    required this.type,
    this.priority = MessagePriority.normal,
    required this.content,
    this.metadata,
    required this.timestamp,
    this.expiryTime,
    this.encrypted = false,
    this.signature,
    this.status = MessageStatus.draft,
    this.retryCount = 0,
    this.routePath = const [],
  });

  /// Create a copy with updated fields
  MeshMessage copyWith({
    String? id,
    String? sourceNodeId,
    String? targetNodeId,
    MessageType? type,
    MessagePriority? priority,
    String? content,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    DateTime? expiryTime,
    bool? encrypted,
    String? signature,
    MessageStatus? status,
    int? retryCount,
    List<String>? routePath,
  }) {
    return MeshMessage(
      id: id ?? this.id,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      expiryTime: expiryTime ?? this.expiryTime,
      encrypted: encrypted ?? this.encrypted,
      signature: signature ?? this.signature,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      routePath: routePath ?? this.routePath,
    );
  }

  /// Check if message has expired
  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }

  /// Check if message is broadcast
  bool get isBroadcast => targetNodeId == null;

  /// Get message size in bytes
  int get sizeInBytes {
    return utf8.encode(jsonEncode(toJson())).length;
  }

  /// Convert to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceNodeId': sourceNodeId,
      'targetNodeId': targetNodeId,
      'type': type.name,
      'priority': priority.name,
      'content': content,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'expiryTime': expiryTime?.millisecondsSinceEpoch,
      'encrypted': encrypted,
      'signature': signature,
      'status': status.name,
      'retryCount': retryCount,
      'routePath': routePath,
    };
  }

  /// Create from JSON
  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'],
      sourceNodeId: json['sourceNodeId'],
      targetNodeId: json['targetNodeId'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      priority: MessagePriority.values.firstWhere((e) => e.name == json['priority']),
      content: json['content'],
      metadata: json['metadata']?.cast<String, dynamic>(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      expiryTime: json['expiryTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['expiryTime']) 
          : null,
      encrypted: json['encrypted'] ?? false,
      signature: json['signature'],
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      retryCount: json['retryCount'] ?? 0,
      routePath: List<String>.from(json['routePath'] ?? []),
    );
  }

  @override
  String toString() {
    return 'MeshMessage(id: $id, type: $type, from: $sourceNodeId, to: $targetNodeId, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeshMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Chat message model extending MeshMessage
class ChatMessage extends MeshMessage {
  final bool isSystem;
  final bool isError;
  final String? replyToId;

  ChatMessage({
    required String id,
    required String sourceNodeId,
    String? targetNodeId,
    required String content,
    DateTime? timestamp,
    this.isSystem = false,
    this.isError = false,
    this.replyToId,
    MessagePriority priority = MessagePriority.normal,
    bool encrypted = false,
  }) : super(
          id: id,
          sourceNodeId: sourceNodeId,
          targetNodeId: targetNodeId,
          type: MessageType.chat,
          priority: priority,
          content: content,
          timestamp: timestamp ?? DateTime.now(),
          encrypted: encrypted,
        );

  /// Create system message
  factory ChatMessage.system(String content, {bool isError = false}) {
    return ChatMessage(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      sourceNodeId: 'SYSTEM',
      content: content,
      isSystem: true,
      isError: isError,
      priority: isError ? MessagePriority.urgent : MessagePriority.normal,
    );
  }

  /// Create reply message
  factory ChatMessage.reply({
    required String id,
    required String sourceNodeId,
    required String targetNodeId,
    required String content,
    required String replyToId,
    MessagePriority priority = MessagePriority.normal,
  }) {
    return ChatMessage(
      id: id,
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
      content: content,
      replyToId: replyToId,
      priority: priority,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'isSystem': isSystem,
      'isError': isError,
      'replyToId': replyToId,
    });
    return json;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final baseMessage = MeshMessage.fromJson(json);
    return ChatMessage(
      id: baseMessage.id,
      sourceNodeId: baseMessage.sourceNodeId,
      targetNodeId: baseMessage.targetNodeId,
      content: baseMessage.content,
      timestamp: baseMessage.timestamp,
      isSystem: json['isSystem'] ?? false,
      isError: json['isError'] ?? false,
      replyToId: json['replyToId'],
      priority: baseMessage.priority,
      encrypted: baseMessage.encrypted,
    );
  }
}

/// Emergency message model
class EmergencyMessage extends MeshMessage {
  final String emergencyType;
  final String severity;
  final Map<String, dynamic> locationData;
  final List<String> requiredServices;

  EmergencyMessage({
    required String id,
    required String sourceNodeId,
    required String content,
    required this.emergencyType,
    required this.severity,
    required this.locationData,
    this.requiredServices = const [],
    DateTime? timestamp,
    DateTime? expiryTime,
  }) : super(
          id: id,
          sourceNodeId: sourceNodeId,
          targetNodeId: null, // Emergency messages are always broadcast
          type: MessageType.emergency,
          priority: MessagePriority.emergency,
          content: content,
          timestamp: timestamp ?? DateTime.now(),
          expiryTime: expiryTime ?? DateTime.now().add(Duration(hours: 24)),
          encrypted: false, // Emergency messages should not be encrypted for wider reach
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'emergencyType': emergencyType,
      'severity': severity,
      'locationData': locationData,
      'requiredServices': requiredServices,
    });
    return json;
  }

  factory EmergencyMessage.fromJson(Map<String, dynamic> json) {
    final baseMessage = MeshMessage.fromJson(json);
    return EmergencyMessage(
      id: baseMessage.id,
      sourceNodeId: baseMessage.sourceNodeId,
      content: baseMessage.content,
      emergencyType: json['emergencyType'],
      severity: json['severity'],
      locationData: Map<String, dynamic>.from(json['locationData']),
      requiredServices: List<String>.from(json['requiredServices'] ?? []),
      timestamp: baseMessage.timestamp,
      expiryTime: baseMessage.expiryTime,
    );
  }
}

/// File message model
class FileMessage extends MeshMessage {
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String fileHash;
  final List<int>? fileData; // For small files
  final String? fileUrl; // For large files

  FileMessage({
    required String id,
    required String sourceNodeId,
    String? targetNodeId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.fileHash,
    this.fileData,
    this.fileUrl,
    DateTime? timestamp,
    MessagePriority priority = MessagePriority.normal,
  }) : super(
          id: id,
          sourceNodeId: sourceNodeId,
          targetNodeId: targetNodeId,
          type: MessageType.file,
          priority: priority,
          content: 'File: $fileName ($fileSize bytes)',
          timestamp: timestamp ?? DateTime.now(),
          encrypted: true, // Files are encrypted by default
        );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'fileHash': fileHash,
      'fileData': fileData,
      'fileUrl': fileUrl,
    });
    return json;
  }

  factory FileMessage.fromJson(Map<String, dynamic> json) {
    final baseMessage = MeshMessage.fromJson(json);
    return FileMessage(
      id: baseMessage.id,
      sourceNodeId: baseMessage.sourceNodeId,
      targetNodeId: baseMessage.targetNodeId,
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      fileHash: json['fileHash'],
      fileData: json['fileData']?.cast<int>(),
      fileUrl: json['fileUrl'],
      timestamp: baseMessage.timestamp,
      priority: baseMessage.priority,
    );
  }
}
