// lib/models/channel.dart - BitChat'teki Channel management
class Channel {
  final String id;
  final String name;
  final String? password;
  final String ownerId;
  final List<String> members;
  final DateTime createdAt;
  final bool isPasswordProtected;
  final bool messageRetention;
  final List<Message> messages;
  
  Channel({
    required this.id,
    required this.name,
    this.password,
    required this.ownerId,
    this.members = const [],
    required this.createdAt,
    this.isPasswordProtected = false,
    this.messageRetention = false,
    this.messages = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'password': password,
    'ownerId': ownerId,
    'members': members,
    'createdAt': createdAt.toIso8601String(),
    'isPasswordProtected': isPasswordProtected,
    'messageRetention': messageRetention,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  
  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      password: json['password'],
      ownerId: json['ownerId'],
      members: List<String>.from(json['members'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      isPasswordProtected: json['isPasswordProtected'] ?? false,
      messageRetention: json['messageRetention'] ?? false,
      messages: (json['messages'] as List?)
          ?.map((m) => Message.fromJson(m))
          .toList() ?? [],
    );
  }
  
  // BitChat'teki channel management logic
  bool canUserJoin(String userId, String? providedPassword) {
    if (isPasswordProtected) {
      return password == providedPassword;
    }
    return true;
  }
  
  Channel addMember(String userId) {
    if (members.contains(userId)) return this;
    
    final newMembers = List<String>.from(members);
    newMembers.add(userId);
    
    return Channel(
      id: id,
      name: name,
      password: password,
      ownerId: ownerId,
      members: newMembers,
      createdAt: createdAt,
      isPasswordProtected: isPasswordProtected,
      messageRetention: messageRetention,
      messages: messages,
    );
  }
  
  Channel removeMember(String userId) {
    final newMembers = List<String>.from(members);
    newMembers.remove(userId);
    
    return Channel(
      id: id,
      name: name,
      password: password,
      ownerId: ownerId,
      members: newMembers,
      createdAt: createdAt,
      isPasswordProtected: isPasswordProtected,
      messageRetention: messageRetention,
      messages: messages,
    );
  }
  
  Channel addMessage(Message message) {
    final newMessages = List<Message>.from(messages);
    newMessages.add(message);
    
    // Limit message history if retention is not enabled
    if (!messageRetention && newMessages.length > 100) {
      newMessages.removeRange(0, newMessages.length - 100);
    }
    
    return Channel(
      id: id,
      name: name,
      password: password,
      ownerId: ownerId,
      members: members,
      createdAt: createdAt,
      isPasswordProtected: isPasswordProtected,
      messageRetention: messageRetention,
      messages: newMessages,
    );
  }
}
