// test/models/message_test.dart - Message Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/message.dart';

void main() {
  group('MessageType Tests', () {
    test('should have all required message types', () {
      expect(MessageType.values.length, 9);
      expect(MessageType.values, contains(MessageType.chat));
      expect(MessageType.values, contains(MessageType.emergency));
      expect(MessageType.values, contains(MessageType.location));
      expect(MessageType.values, contains(MessageType.discovery));
      expect(MessageType.values, contains(MessageType.file));
      expect(MessageType.values, contains(MessageType.system));
      expect(MessageType.values, contains(MessageType.broadcast));
      expect(MessageType.values, contains(MessageType.unicast));
      expect(MessageType.values, contains(MessageType.multicast));
    });
  });

  group('MessagePriority Tests', () {
    test('should have correct priority order', () {
      expect(MessagePriority.values.length, 5);
      expect(MessagePriority.emergency.index, 0); // Highest priority
      expect(MessagePriority.urgent.index, 1);
      expect(MessagePriority.high.index, 2);
      expect(MessagePriority.normal.index, 3);
      expect(MessagePriority.low.index, 4); // Lowest priority
    });
  });

  group('MessageStatus Tests', () {
    test('should have all message statuses', () {
      expect(MessageStatus.values.length, 7);
      expect(MessageStatus.values, contains(MessageStatus.draft));
      expect(MessageStatus.values, contains(MessageStatus.sending));
      expect(MessageStatus.values, contains(MessageStatus.sent));
      expect(MessageStatus.values, contains(MessageStatus.delivered));
      expect(MessageStatus.values, contains(MessageStatus.failed));
      expect(MessageStatus.values, contains(MessageStatus.received));
      expect(MessageStatus.values, contains(MessageStatus.read));
    });
  });

  group('MeshMessage Tests', () {
    late MeshMessage testMessage;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testMessage = MeshMessage(
        id: 'test_message_123',
        sourceNodeId: 'node_001',
        targetNodeId: 'node_002',
        type: MessageType.chat,
        priority: MessagePriority.normal,
        content: 'Test message content',
        timestamp: testTimestamp,
      );
    });

    test('should create message with required fields', () {
      expect(testMessage.id, 'test_message_123');
      expect(testMessage.sourceNodeId, 'node_001');
      expect(testMessage.targetNodeId, 'node_002');
      expect(testMessage.type, MessageType.chat);
      expect(testMessage.priority, MessagePriority.normal);
      expect(testMessage.content, 'Test message content');
      expect(testMessage.timestamp, testTimestamp);
    });

    test('should have default values for optional fields', () {
      expect(testMessage.metadata, isNull);
      expect(testMessage.expiryTime, isNull);
      expect(testMessage.encrypted, false);
      expect(testMessage.signature, isNull);
      expect(testMessage.status, MessageStatus.draft);
      expect(testMessage.retryCount, 0);
      expect(testMessage.routePath, isEmpty);
    });

    test('should detect broadcast messages', () {
      final broadcastMessage = MeshMessage(
        id: 'broadcast_123',
        sourceNodeId: 'node_001',
        targetNodeId: null, // Broadcast
        type: MessageType.broadcast,
        content: 'Broadcast message',
        timestamp: DateTime.now(),
      );

      expect(broadcastMessage.isBroadcast, true);
      expect(testMessage.isBroadcast, false);
    });

    test('should detect expired messages', () {
      final expiredMessage = MeshMessage(
        id: 'expired_123',
        sourceNodeId: 'node_001',
        type: MessageType.chat,
        content: 'Expired message',
        timestamp: DateTime.now(),
        expiryTime: DateTime.now().subtract(Duration(hours: 1)), // Already expired
      );

      final validMessage = MeshMessage(
        id: 'valid_123',
        sourceNodeId: 'node_001',
        type: MessageType.chat,
        content: 'Valid message',
        timestamp: DateTime.now(),
        expiryTime: DateTime.now().add(Duration(hours: 1)), // Not expired
      );

      expect(expiredMessage.isExpired, true);
      expect(validMessage.isExpired, false);
      expect(testMessage.isExpired, false); // No expiry time
    });

    test('should calculate message size in bytes', () {
      expect(testMessage.sizeInBytes, greaterThan(0));
      expect(testMessage.sizeInBytes, isA<int>());
    });

    test('should copy message with updated fields', () {
      final updatedMessage = testMessage.copyWith(
        content: 'Updated content',
        priority: MessagePriority.urgent,
        status: MessageStatus.sent,
      );

      expect(updatedMessage.id, testMessage.id); // Unchanged
      expect(updatedMessage.sourceNodeId, testMessage.sourceNodeId); // Unchanged
      expect(updatedMessage.content, 'Updated content'); // Changed
      expect(updatedMessage.priority, MessagePriority.urgent); // Changed
      expect(updatedMessage.status, MessageStatus.sent); // Changed
    });

    test('should serialize to JSON correctly', () {
      final json = testMessage.toJson();

      expect(json['id'], 'test_message_123');
      expect(json['sourceNodeId'], 'node_001');
      expect(json['targetNodeId'], 'node_002');
      expect(json['type'], 'chat');
      expect(json['priority'], 'normal');
      expect(json['content'], 'Test message content');
      expect(json['timestamp'], testTimestamp.millisecondsSinceEpoch);
      expect(json['encrypted'], false);
      expect(json['status'], 'draft');
      expect(json['retryCount'], 0);
      expect(json['routePath'], isEmpty);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'json_message_456',
        'sourceNodeId': 'node_003',
        'targetNodeId': 'node_004',
        'type': 'emergency',
        'priority': 'urgent',
        'content': 'Emergency message',
        'timestamp': testTimestamp.millisecondsSinceEpoch,
        'encrypted': true,
        'status': 'sent',
        'retryCount': 2,
        'routePath': ['node_001', 'node_002'],
      };

      final message = MeshMessage.fromJson(json);

      expect(message.id, 'json_message_456');
      expect(message.sourceNodeId, 'node_003');
      expect(message.targetNodeId, 'node_004');
      expect(message.type, MessageType.emergency);
      expect(message.priority, MessagePriority.urgent);
      expect(message.content, 'Emergency message');
      expect(message.timestamp, DateTime.fromMillisecondsSinceEpoch(testTimestamp.millisecondsSinceEpoch));
      expect(message.encrypted, true);
      expect(message.status, MessageStatus.sent);
      expect(message.retryCount, 2);
      expect(message.routePath, ['node_001', 'node_002']);
    });

    test('should implement equality correctly', () {
      final message1 = MeshMessage(
        id: 'same_id',
        sourceNodeId: 'node_001',
        type: MessageType.chat,
        content: 'Content 1',
        timestamp: DateTime.now(),
      );

      final message2 = MeshMessage(
        id: 'same_id',
        sourceNodeId: 'node_002', // Different source
        type: MessageType.emergency, // Different type
        content: 'Content 2', // Different content
        timestamp: DateTime.now(),
      );

      final message3 = MeshMessage(
        id: 'different_id',
        sourceNodeId: 'node_001',
        type: MessageType.chat,
        content: 'Content 1',
        timestamp: DateTime.now(),
      );

      expect(message1, equals(message2)); // Same ID
      expect(message1, isNot(equals(message3))); // Different ID
      expect(message1.hashCode, equals(message2.hashCode)); // Same hash
    });
  });

  group('ChatMessage Tests', () {
    test('should create chat message with correct defaults', () {
      final chatMessage = ChatMessage(
        id: 'chat_123',
        sourceNodeId: 'user_001',
        content: 'Hello world!',
      );

      expect(chatMessage.type, MessageType.chat);
      expect(chatMessage.priority, MessagePriority.normal);
      expect(chatMessage.isSystem, false);
      expect(chatMessage.isError, false);
      expect(chatMessage.replyToId, isNull);
    });

    test('should create system message correctly', () {
      final systemMessage = ChatMessage.system('System notification');
      final errorMessage = ChatMessage.system('Error occurred', isError: true);

      expect(systemMessage.isSystem, true);
      expect(systemMessage.isError, false);
      expect(systemMessage.sourceNodeId, 'SYSTEM');
      expect(systemMessage.priority, MessagePriority.normal);

      expect(errorMessage.isSystem, true);
      expect(errorMessage.isError, true);
      expect(errorMessage.priority, MessagePriority.urgent);
    });

    test('should create reply message correctly', () {
      final replyMessage = ChatMessage.reply(
        id: 'reply_123',
        sourceNodeId: 'user_001',
        targetNodeId: 'user_002',
        content: 'This is a reply',
        replyToId: 'original_message_456',
      );

      expect(replyMessage.replyToId, 'original_message_456');
      expect(replyMessage.targetNodeId, 'user_002');
    });

    test('should serialize chat-specific fields', () {
      final chatMessage = ChatMessage(
        id: 'chat_123',
        sourceNodeId: 'user_001',
        content: 'Test chat',
        isSystem: true,
        isError: false,
        replyToId: 'original_456',
      );

      final json = chatMessage.toJson();

      expect(json['isSystem'], true);
      expect(json['isError'], false);
      expect(json['replyToId'], 'original_456');
    });

    test('should deserialize chat message from JSON', () {
      final json = {
        'id': 'chat_789',
        'sourceNodeId': 'user_002',
        'targetNodeId': null,
        'type': 'chat',
        'priority': 'normal',
        'content': 'Chat from JSON',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'encrypted': false,
        'status': 'received',
        'retryCount': 0,
        'routePath': [],
        'isSystem': false,
        'isError': true,
        'replyToId': 'reply_to_123',
      };

      final chatMessage = ChatMessage.fromJson(json);

      expect(chatMessage.id, 'chat_789');
      expect(chatMessage.isSystem, false);
      expect(chatMessage.isError, true);
      expect(chatMessage.replyToId, 'reply_to_123');
    });
  });

  group('EmergencyMessage Tests', () {
    test('should create emergency message with correct defaults', () {
      final emergencyMessage = EmergencyMessage(
        id: 'emergency_123',
        sourceNodeId: 'node_001',
        content: 'Medical emergency',
        emergencyType: 'medical',
        severity: 'high',
        locationData: {
          'latitude': 40.7128,
          'longitude': -74.0060,
          'accuracy': 10.0,
        },
      );

      expect(emergencyMessage.type, MessageType.emergency);
      expect(emergencyMessage.priority, MessagePriority.emergency);
      expect(emergencyMessage.targetNodeId, isNull); // Always broadcast
      expect(emergencyMessage.encrypted, false); // Not encrypted for wider reach
      expect(emergencyMessage.expiryTime, isNotNull); // Has expiry time
      expect(emergencyMessage.requiredServices, isEmpty);
    });

    test('should serialize emergency-specific fields', () {
      final emergencyMessage = EmergencyMessage(
        id: 'emergency_456',
        sourceNodeId: 'node_002',
        content: 'Fire emergency',
        emergencyType: 'fire',
        severity: 'critical',
        locationData: {'lat': 40.0, 'lng': -74.0},
        requiredServices: ['fire_department', 'ambulance'],
      );

      final json = emergencyMessage.toJson();

      expect(json['emergencyType'], 'fire');
      expect(json['severity'], 'critical');
      expect(json['locationData'], {'lat': 40.0, 'lng': -74.0});
      expect(json['requiredServices'], ['fire_department', 'ambulance']);
    });

    test('should deserialize emergency message from JSON', () {
      final json = {
        'id': 'emergency_789',
        'sourceNodeId': 'node_003',
        'targetNodeId': null,
        'type': 'emergency',
        'priority': 'emergency',
        'content': 'Police emergency',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiryTime': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch,
        'encrypted': false,
        'status': 'sent',
        'retryCount': 0,
        'routePath': [],
        'emergencyType': 'police',
        'severity': 'high',
        'locationData': {'latitude': 41.0, 'longitude': -75.0},
        'requiredServices': ['police'],
      };

      final emergencyMessage = EmergencyMessage.fromJson(json);

      expect(emergencyMessage.emergencyType, 'police');
      expect(emergencyMessage.severity, 'high');
      expect(emergencyMessage.locationData, {'latitude': 41.0, 'longitude': -75.0});
      expect(emergencyMessage.requiredServices, ['police']);
    });
  });

  group('FileMessage Tests', () {
    test('should create file message with correct defaults', () {
      final fileMessage = FileMessage(
        id: 'file_123',
        sourceNodeId: 'user_001',
        fileName: 'document.pdf',
        fileSize: 1024576, // 1MB
        mimeType: 'application/pdf',
        fileHash: 'sha256_hash_here',
      );

      expect(fileMessage.type, MessageType.file);
      expect(fileMessage.priority, MessagePriority.normal);
      expect(fileMessage.encrypted, true); // Files encrypted by default
      expect(fileMessage.content, 'File: document.pdf (1024576 bytes)');
    });

    test('should handle small files with data', () {
      final smallFileData = List.generate(100, (i) => i % 256);
      final fileMessage = FileMessage(
        id: 'small_file_123',
        sourceNodeId: 'user_001',
        fileName: 'small.txt',
        fileSize: 100,
        mimeType: 'text/plain',
        fileHash: 'small_hash',
        fileData: smallFileData,
      );

      expect(fileMessage.fileData, equals(smallFileData));
      expect(fileMessage.fileUrl, isNull);
    });

    test('should handle large files with URL', () {
      final fileMessage = FileMessage(
        id: 'large_file_123',
        sourceNodeId: 'user_001',
        fileName: 'large_video.mp4',
        fileSize: 104857600, // 100MB
        mimeType: 'video/mp4',
        fileHash: 'large_hash',
        fileUrl: 'https://storage.example.com/large_video.mp4',
      );

      expect(fileMessage.fileData, isNull);
      expect(fileMessage.fileUrl, 'https://storage.example.com/large_video.mp4');
    });

    test('should serialize file-specific fields', () {
      final fileMessage = FileMessage(
        id: 'file_456',
        sourceNodeId: 'user_002',
        fileName: 'image.jpg',
        fileSize: 51200, // 50KB
        mimeType: 'image/jpeg',
        fileHash: 'image_hash',
        fileData: [1, 2, 3, 4, 5],
      );

      final json = fileMessage.toJson();

      expect(json['fileName'], 'image.jpg');
      expect(json['fileSize'], 51200);
      expect(json['mimeType'], 'image/jpeg');
      expect(json['fileHash'], 'image_hash');
      expect(json['fileData'], [1, 2, 3, 4, 5]);
      expect(json['fileUrl'], isNull);
    });

    test('should deserialize file message from JSON', () {
      final json = {
        'id': 'file_789',
        'sourceNodeId': 'user_003',
        'targetNodeId': 'user_004',
        'type': 'file',
        'priority': 'high',
        'content': 'File: test.zip (2048 bytes)',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'encrypted': true,
        'status': 'sent',
        'retryCount': 1,
        'routePath': [],
        'fileName': 'test.zip',
        'fileSize': 2048,
        'mimeType': 'application/zip',
        'fileHash': 'zip_hash',
        'fileData': null,
        'fileUrl': 'https://files.example.com/test.zip',
      };

      final fileMessage = FileMessage.fromJson(json);

      expect(fileMessage.fileName, 'test.zip');
      expect(fileMessage.fileSize, 2048);
      expect(fileMessage.mimeType, 'application/zip');
      expect(fileMessage.fileHash, 'zip_hash');
      expect(fileMessage.fileData, isNull);
      expect(fileMessage.fileUrl, 'https://files.example.com/test.zip');
    });
  });
}
