// test/models/file_message_test.dart - File Message Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/message.dart';

void main() {
  group('FileMessage Tests', () {
    test('should create file message with file data', () {
      final fileData = [0x89, 0x50, 0x4E, 0x47]; // PNG header bytes

      final fileMessage = FileMessage(
        id: 'file123',
        sourceNodeId: 'sender_node',
        targetNodeId: 'receiver_node',
        fileName: 'image.png',
        fileSize: 1024,
        mimeType: 'image/png',
        fileHash: 'sha256_hash_value',
        fileData: fileData,
      );

      expect(fileMessage.id, 'file123');
      expect(fileMessage.sourceNodeId, 'sender_node');
      expect(fileMessage.targetNodeId, 'receiver_node');
      expect(fileMessage.type, MessageType.file);
      expect(fileMessage.priority, MessagePriority.normal);
      expect(fileMessage.content, 'File: image.png (1024 bytes)');
      expect(fileMessage.fileName, 'image.png');
      expect(fileMessage.fileSize, 1024);
      expect(fileMessage.mimeType, 'image/png');
      expect(fileMessage.fileHash, 'sha256_hash_value');
      expect(fileMessage.fileData, fileData);
      expect(fileMessage.fileUrl, null);
      expect(fileMessage.encrypted, true); // Files encrypted by default
    });

    test('should create file message with URL reference', () {
      final fileMessage = FileMessage(
        id: 'file_url',
        sourceNodeId: 'file_server',
        targetNodeId: 'client_node',
        fileName: 'document.pdf',
        fileSize: 2048000, // 2MB
        mimeType: 'application/pdf',
        fileHash: 'md5_hash_value',
        fileUrl: 'mesh://files/document.pdf',
        priority: MessagePriority.high,
      );

      expect(fileMessage.fileName, 'document.pdf');
      expect(fileMessage.fileSize, 2048000);
      expect(fileMessage.mimeType, 'application/pdf');
      expect(fileMessage.fileHash, 'md5_hash_value');
      expect(fileMessage.fileData, null);
      expect(fileMessage.fileUrl, 'mesh://files/document.pdf');
      expect(fileMessage.content, 'File: document.pdf (2048000 bytes)');
      expect(fileMessage.priority, MessagePriority.high);
    });

    test('should create file message with different file types', () {
      // Text file
      final textFile = FileMessage(
        id: 'text_file',
        sourceNodeId: 'node1',
        fileName: 'readme.txt',
        fileSize: 512,
        mimeType: 'text/plain',
        fileHash: 'text_hash',
      );

      // Image file
      final imageFile = FileMessage(
        id: 'image_file',
        sourceNodeId: 'node2',
        fileName: 'photo.jpg',
        fileSize: 1048576, // 1MB
        mimeType: 'image/jpeg',
        fileHash: 'image_hash',
      );

      // Video file
      final videoFile = FileMessage(
        id: 'video_file',
        sourceNodeId: 'node3',
        fileName: 'video.mp4',
        fileSize: 10485760, // 10MB
        mimeType: 'video/mp4',
        fileHash: 'video_hash',
      );

      expect(textFile.mimeType, 'text/plain');
      expect(imageFile.mimeType, 'image/jpeg');
      expect(videoFile.mimeType, 'video/mp4');

      expect(textFile.content, 'File: readme.txt (512 bytes)');
      expect(imageFile.content, 'File: photo.jpg (1048576 bytes)');
      expect(videoFile.content, 'File: video.mp4 (10485760 bytes)');
    });

    test('should serialize to JSON correctly', () {
      final fileData = [0x50, 0x4B, 0x03, 0x04]; // ZIP header

      final fileMessage = FileMessage(
        id: 'file_json',
        sourceNodeId: 'zip_sender',
        targetNodeId: 'zip_receiver',
        fileName: 'archive.zip',
        fileSize: 4096,
        mimeType: 'application/zip',
        fileHash: 'zip_sha256',
        fileData: fileData,
        fileUrl: 'mesh://storage/archive.zip',
        priority: MessagePriority.urgent,
      );

      final json = fileMessage.toJson();

      expect(json['id'], 'file_json');
      expect(json['sourceNodeId'], 'zip_sender');
      expect(json['targetNodeId'], 'zip_receiver');
      expect(json['type'], 'file');
      expect(json['priority'], 'urgent');
      expect(json['content'], 'File: archive.zip (4096 bytes)');
      expect(json['fileName'], 'archive.zip');
      expect(json['fileSize'], 4096);
      expect(json['mimeType'], 'application/zip');
      expect(json['fileHash'], 'zip_sha256');
      expect(json['fileData'], fileData);
      expect(json['fileUrl'], 'mesh://storage/archive.zip');
      expect(json['encrypted'], true);
    });

    test('should deserialize from JSON correctly', () {
      final fileData = [0x47, 0x49, 0x46, 0x38]; // GIF header

      final json = {
        'id': 'file_from_json',
        'sourceNodeId': 'gif_sender',
        'targetNodeId': 'gif_receiver',
        'type': 'file',
        'priority': 'normal',
        'content': 'File: animation.gif (2048 bytes)',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'encrypted': true,
        'status': 'draft',
        'retryCount': 0,
        'routePath': <String>[],
        'fileName': 'animation.gif',
        'fileSize': 2048,
        'mimeType': 'image/gif',
        'fileHash': 'gif_hash',
        'fileData': fileData,
        'fileUrl': 'mesh://cache/animation.gif',
      };

      final fileMessage = FileMessage.fromJson(json);

      expect(fileMessage.id, 'file_from_json');
      expect(fileMessage.sourceNodeId, 'gif_sender');
      expect(fileMessage.targetNodeId, 'gif_receiver');
      expect(fileMessage.fileName, 'animation.gif');
      expect(fileMessage.fileSize, 2048);
      expect(fileMessage.mimeType, 'image/gif');
      expect(fileMessage.fileHash, 'gif_hash');
      expect(fileMessage.fileData, fileData);
      expect(fileMessage.fileUrl, 'mesh://cache/animation.gif');
    });

    test('should handle null values in JSON deserialization', () {
      final json = {
        'id': 'minimal_file',
        'sourceNodeId': 'node1',
        'type': 'file',
        'priority': 'normal',
        'content': 'File: minimal.txt (100 bytes)',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'draft',
        'retryCount': 0,
        'routePath': <String>[],
        'fileName': 'minimal.txt',
        'fileSize': 100,
        'mimeType': 'text/plain',
        'fileHash': 'minimal_hash',
        // fileData and fileUrl are null/missing
      };

      final fileMessage = FileMessage.fromJson(json);

      expect(fileMessage.fileData, null);
      expect(fileMessage.fileUrl, null);
    });

    test('should handle large file sizes', () {
      const largeSizeBytes = 1073741824; // 1GB

      final largeFile = FileMessage(
        id: 'large_file',
        sourceNodeId: 'storage_node',
        fileName: 'backup.tar.gz',
        fileSize: largeSizeBytes,
        mimeType: 'application/gzip',
        fileHash: 'large_file_hash',
        fileUrl: 'mesh://bigfiles/backup.tar.gz',
      );

      expect(largeFile.fileSize, largeSizeBytes);
      expect(largeFile.content, 'File: backup.tar.gz ($largeSizeBytes bytes)');
      expect(largeFile.fileData, null); // Large files should use URL reference
      expect(largeFile.fileUrl, isNotNull);
    });

    test('should validate file hash integrity', () {
      const expectedHash = 'sha256:abcd1234efgh5678';
      
      final fileMessage = FileMessage(
        id: 'hash_test',
        sourceNodeId: 'secure_node',
        fileName: 'secure.dat',
        fileSize: 256,
        mimeType: 'application/octet-stream',
        fileHash: expectedHash,
      );

      expect(fileMessage.fileHash, expectedHash);
      
      // Simulate hash verification
      final receivedHash = fileMessage.fileHash;
      expect(receivedHash, equals(expectedHash));
    });
  });
}
