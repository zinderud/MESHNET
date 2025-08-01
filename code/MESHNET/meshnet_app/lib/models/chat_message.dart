// lib/models/chat_message.dart - Chat Message Model
import 'dart:typed_data';

enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  location,
  emergency,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? channelId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final String? replyToId;
  final Map<String, dynamic>? metadata;
  final Uint8List? attachmentData;
  final String? attachmentMimeType;
  final int? attachmentSize;
  final bool isEncrypted;
  final String? encryptionKey;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.channelId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sending,
    required this.timestamp,
    this.editedAt,
    this.replyToId,
    this.metadata,
    this.attachmentData,
    this.attachmentMimeType,
    this.attachmentSize,
    this.isEncrypted = false,
    this.encryptionKey,
  });

  // Factory constructor for empty message (used by memory pool)
  factory ChatMessage.empty() {
    return ChatMessage(
      id: '',
      senderId: '',
      senderName: '',
      content: '',
      timestamp: DateTime.now(),
    );
  }

  // Factory constructor for simple text messages
  factory ChatMessage.simple({
    required String content,
    bool isOwn = false,
    bool isSystem = false,
    bool isError = false,
    String? senderName,
    String? senderId,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId ?? (isOwn ? 'me' : 'unknown'),
      senderName: senderName ?? (isOwn ? 'Ben' : 'Bilinmeyen'),
      content: content,
      type: isSystem ? MessageType.emergency : MessageType.text,
      status: isOwn ? MessageStatus.sent : MessageStatus.delivered,
      timestamp: DateTime.now(),
    );
  }

  // Reset method for memory pool reuse
  ChatMessage reset() {
    return ChatMessage.empty();
  }

  // Convenience getters for UI compatibility
  bool get isOwn => senderId == 'me';
  bool get isSystem => type == MessageType.emergency;
  bool get isError => status == MessageStatus.failed;

  // Copy with method for immutable updates
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? channelId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? editedAt,
    String? replyToId,
    Map<String, dynamic>? metadata,
    Uint8List? attachmentData,
    String? attachmentMimeType,
    int? attachmentSize,
    bool? isEncrypted,
    String? encryptionKey,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      channelId: channelId ?? this.channelId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
      attachmentData: attachmentData ?? this.attachmentData,
      attachmentMimeType: attachmentMimeType ?? this.attachmentMimeType,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKey: encryptionKey ?? this.encryptionKey,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'channelId': channelId,
      'content': content,
      'type': type.index,
      'status': status.index,
      'timestamp': timestamp.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'replyToId': replyToId,
      'metadata': metadata,
      'attachmentData': attachmentData?.toList(),
      'attachmentMimeType': attachmentMimeType,
      'attachmentSize': attachmentSize,
      'isEncrypted': isEncrypted,
      'encryptionKey': encryptionKey,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      channelId: json['channelId'],
      content: json['content'] ?? '',
      type: MessageType.values[json['type'] ?? 0],
      status: MessageStatus.values[json['status'] ?? 0],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      replyToId: json['replyToId'],
      metadata: json['metadata'],
      attachmentData: json['attachmentData'] != null 
          ? Uint8List.fromList(List<int>.from(json['attachmentData']))
          : null,
      attachmentMimeType: json['attachmentMimeType'],
      attachmentSize: json['attachmentSize'],
      isEncrypted: json['isEncrypted'] ?? false,
      encryptionKey: json['encryptionKey'],
    );
  }

  // Utility methods
  bool get hasAttachment => attachmentData != null;
  bool get isEdited => editedAt != null;
  bool get isReply => replyToId != null;
  bool get isFailed => status == MessageStatus.failed;
  bool get isDelivered => status == MessageStatus.delivered || status == MessageStatus.read;

  String get displayContent {
    switch (type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.location:
        return '📍 Location';
      case MessageType.emergency:
        return '🚨 Emergency: $content';
      default:
        return content;
    }
  }

  int get estimatedSize {
    int size = 0;
    size += id.length * 2; // UTF-16
    size += senderId.length * 2;
    size += senderName.length * 2;
    size += (channelId?.length ?? 0) * 2;
    size += content.length * 2;
    size += 64; // Enums, dates, booleans
    size += (metadata?.toString().length ?? 0) * 2;
    size += attachmentData?.length ?? 0;
    size += (attachmentMimeType?.length ?? 0) * 2;
    return size;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, sender: $senderName, type: $type, content: ${content.length > 50 ? content.substring(0, 50) + '...' : content})';
  }
}
