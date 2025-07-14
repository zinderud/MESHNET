// lib/models/message.dart - BitChat'teki Message struct'ından çevrildi
class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final int hopCount;
  final List<String> routePath;
  final MessageType type;
  
  // BitChat'teki Message struct'ını Flutter'a çevirme
  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.hopCount = 0,
    this.routePath = const [],
    this.type = MessageType.text,
  });
  
  // Serialization - BitChat'teki binary protocol
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'hopCount': hopCount,
    'routePath': routePath,
    'type': type.toString(),
  };
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      hopCount: json['hopCount'] ?? 0,
      routePath: List<String>.from(json['routePath'] ?? []),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
  
  // BitChat'teki message handling logic
  Message incrementHopCount() {
    return Message(
      id: id,
      senderId: senderId,
      content: content,
      timestamp: timestamp,
      hopCount: hopCount + 1,
      routePath: routePath,
      type: type,
    );
  }
  
  Message addToRoutePath(String nodeId) {
    final newPath = List<String>.from(routePath);
    newPath.add(nodeId);
    return Message(
      id: id,
      senderId: senderId,
      content: content,
      timestamp: timestamp,
      hopCount: hopCount,
      routePath: newPath,
      type: type,
    );
  }
}

enum MessageType { 
  text, 
  image, 
  file, 
  emergency, 
  system,
  channelJoin,
  channelLeave,
  ping,
  pong
}
