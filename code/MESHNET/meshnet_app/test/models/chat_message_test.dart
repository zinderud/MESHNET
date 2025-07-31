// test/models/chat_message_test.dart - Chat Message Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/message.dart';

void main() {
  group('ChatMessage Tests', () {
    test('should create basic chat message', () {
      final chatMessage = ChatMessage(
        id: 'chat123',
        sourceNodeId: 'user1',
        targetNodeId: 'user2',
        content: 'Hello from chat!',
      );

      expect(chatMessage.id, 'chat123');
      expect(chatMessage.sourceNodeId, 'user1');
      expect(chatMessage.targetNodeId, 'user2');
      expect(chatMessage.content, 'Hello from chat!');
      expect(chatMessage.type, MessageType.chat);
      expect(chatMessage.isSystem, false);
      expect(chatMessage.isError, false);
      expect(chatMessage.replyToId, null);
    });

    test('should create system message', () {
      final systemMessage = ChatMessage.system('System notification');

      expect(systemMessage.sourceNodeId, 'SYSTEM');
      expect(systemMessage.content, 'System notification');
      expect(systemMessage.isSystem, true);
      expect(systemMessage.isError, false);
      expect(systemMessage.priority, MessagePriority.normal);
    });

    test('should create system error message', () {
      final errorMessage = ChatMessage.system('Connection failed', isError: true);

      expect(errorMessage.sourceNodeId, 'SYSTEM');
      expect(errorMessage.content, 'Connection failed');
      expect(errorMessage.isSystem, true);
      expect(errorMessage.isError, true);
      expect(errorMessage.priority, MessagePriority.urgent);
    });

    test('should create reply message', () {
      final replyMessage = ChatMessage.reply(
        id: 'reply123',
        sourceNodeId: 'user2',
        targetNodeId: 'user1',
        content: 'This is a reply',
        replyToId: 'original123',
        priority: MessagePriority.high,
      );

      expect(replyMessage.id, 'reply123');
      expect(replyMessage.sourceNodeId, 'user2');
      expect(replyMessage.targetNodeId, 'user1');
      expect(replyMessage.content, 'This is a reply');
      expect(replyMessage.replyToId, 'original123');
      expect(replyMessage.priority, MessagePriority.high);
    });

    test('should serialize chat message to JSON correctly', () {
      final chatMessage = ChatMessage(
        id: 'chat_json',
        sourceNodeId: 'user1',
        targetNodeId: 'user2',
        content: 'Chat with metadata',
        isSystem: false,
        isError: false,
        replyToId: 'reply_to_123',
      );

      final json = chatMessage.toJson();

      expect(json['id'], 'chat_json');
      expect(json['sourceNodeId'], 'user1');
      expect(json['targetNodeId'], 'user2');
      expect(json['content'], 'Chat with metadata');
      expect(json['type'], 'chat');
      expect(json['isSystem'], false);
      expect(json['isError'], false);
      expect(json['replyToId'], 'reply_to_123');
    });

    test('should deserialize chat message from JSON correctly', () {
      final json = {
        'id': 'chat_from_json',
        'sourceNodeId': 'user3',
        'targetNodeId': 'user4',
        'type': 'chat',
        'priority': 'normal',
        'content': 'Deserialized chat',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'encrypted': false,
        'status': 'draft',
        'retryCount': 0,
        'routePath': <String>[],
        'isSystem': true,
        'isError': false,
        'replyToId': 'original_msg',
      };

      final chatMessage = ChatMessage.fromJson(json);

      expect(chatMessage.id, 'chat_from_json');
      expect(chatMessage.sourceNodeId, 'user3');
      expect(chatMessage.targetNodeId, 'user4');
      expect(chatMessage.content, 'Deserialized chat');
      expect(chatMessage.isSystem, true);
      expect(chatMessage.isError, false);
      expect(chatMessage.replyToId, 'original_msg');
    });

    test('should handle null values in JSON deserialization', () {
      final json = {
        'id': 'minimal_chat',
        'sourceNodeId': 'user1',
        'type': 'chat',
        'priority': 'normal',
        'content': 'Minimal chat',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'draft',
        'retryCount': 0,
        'routePath': <String>[],
      };

      final chatMessage = ChatMessage.fromJson(json);

      expect(chatMessage.isSystem, false);
      expect(chatMessage.isError, false);
      expect(chatMessage.replyToId, null);
    });
  });
}
