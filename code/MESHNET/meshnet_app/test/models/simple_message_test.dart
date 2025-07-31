// test/models/simple_message_test.dart - Simple Message Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/message.dart';

void main() {
  group('Simple Message Tests', () {
    test('should create MeshMessage with basic fields', () {
      final message = MeshMessage(
        id: 'test123',
        sourceNodeId: 'node1',
        type: MessageType.chat,
        content: 'Hello World',
        timestamp: DateTime.now(),
      );

      expect(message.id, 'test123');
      expect(message.sourceNodeId, 'node1');
      expect(message.type, MessageType.chat);
      expect(message.content, 'Hello World');
      expect(message.priority, MessagePriority.normal);
      expect(message.status, MessageStatus.draft);
    });

    test('should detect broadcast messages', () {
      final broadcastMessage = MeshMessage(
        id: 'broadcast1',
        sourceNodeId: 'node1',
        targetNodeId: null,
        type: MessageType.broadcast,
        content: 'Broadcast message',
        timestamp: DateTime.now(),
      );

      final unicastMessage = MeshMessage(
        id: 'unicast1',
        sourceNodeId: 'node1',
        targetNodeId: 'node2',
        type: MessageType.unicast,
        content: 'Direct message',
        timestamp: DateTime.now(),
      );

      expect(broadcastMessage.isBroadcast, true);
      expect(unicastMessage.isBroadcast, false);
    });

    test('should convert to JSON and back', () {
      final original = MeshMessage(
        id: 'json_test',
        sourceNodeId: 'node1',
        targetNodeId: 'node2',
        type: MessageType.chat,
        priority: MessagePriority.high,
        content: 'JSON test message',
        timestamp: DateTime.now(),
        encrypted: true,
      );

      final json = original.toJson();
      final restored = MeshMessage.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.sourceNodeId, original.sourceNodeId);
      expect(restored.targetNodeId, original.targetNodeId);
      expect(restored.type, original.type);
      expect(restored.priority, original.priority);
      expect(restored.content, original.content);
      expect(restored.encrypted, original.encrypted);
    });
  });
}
