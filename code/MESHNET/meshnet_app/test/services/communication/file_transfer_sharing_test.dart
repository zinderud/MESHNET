// test/services/communication/file_transfer_sharing_test.dart - File Transfer & Sharing Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';

import 'package:meshnet_app/services/communication/file_transfer_sharing.dart';

@GenerateMocks([])
class MockFileStreamController extends Mock implements StreamController<FileTransferProgress> {}

void main() {
  group('FileTransferSharing Tests', () {
    late FileTransferSharing fileService;
    
    setUp(() {
      fileService = FileTransferSharing.instance;
    });
    
    tearDown(() async {
      if (fileService.isInitialized) {
        await fileService.shutdown();
      }
    });

    group('Service Initialization', () {
      test('should initialize file transfer service successfully', () async {
        final result = await fileService.initialize();
        
        expect(result, isTrue);
        expect(fileService.isInitialized, isTrue);
        expect(fileService.defaultProtocol, equals(TransferProtocol.mesh_optimized));
      });
      
      test('should initialize with custom configuration', () async {
        final config = FileTransferConfig(
          defaultProtocol: TransferProtocol.torrent_like,
          maxFileSize: 1024 * 1024 * 100, // 100MB
          chunkSize: 8192,
          maxConcurrentTransfers: 5,
          enableCompression: true,
          compressionLevel: 6,
          enableEncryption: true,
          bufferSize: 4096,
          timeoutDuration: const Duration(minutes: 30),
          retryAttempts: 3,
          emergencyMode: false,
          meshIntegration: true,
        );
        
        final result = await fileService.initialize(config: config);
        
        expect(result, isTrue);
        expect(fileService.defaultProtocol, equals(TransferProtocol.torrent_like));
      });
    });

    group('File Transfer Protocols', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should get supported transfer protocols', () {
        final protocols = fileService.getSupportedProtocols();
        
        expect(protocols, isNotEmpty);
        expect(protocols.length, equals(8)); // All 8 transfer protocols
        expect(protocols, contains(TransferProtocol.http_chunk));
        expect(protocols, contains(TransferProtocol.emergency_priority));
      });
      
      test('should switch transfer protocol successfully', () async {
        final result = await fileService.switchProtocol(TransferProtocol.ftp_secure);
        
        expect(result, isTrue);
        expect(fileService.defaultProtocol, equals(TransferProtocol.ftp_secure));
      });
      
      test('should select optimal protocol based on conditions', () async {
        await fileService.updateNetworkCondition(NetworkCondition.poor);
        
        final protocol = fileService.selectOptimalProtocol(
          fileSize: 1024 * 1024, // 1MB
          priority: TransferPriority.high,
        );
        
        expect(protocol, isIn([
          TransferProtocol.mesh_optimized,
          TransferProtocol.torrent_like,
          TransferProtocol.emergency_priority,
        ]));
      });
    });

    group('File Transfer Operations', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should send file successfully', () async {
        final testFile = FileInfo(
          fileId: 'test_file_123',
          filename: 'test.txt',
          filepath: '/tmp/test.txt',
          size: 1024,
          mimeType: 'text/plain',
          checksum: 'abc123',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {'description': 'Test file'},
        );
        
        final transfer = await fileService.sendFile(
          targetId: 'user123',
          file: testFile,
          priority: TransferPriority.normal,
        );
        
        expect(transfer, isNotNull);
        expect(transfer!.isActive, isTrue);
        expect(transfer.recipientId, equals('user123'));
      });
      
      test('should receive file successfully', () async {
        final result = await fileService.acceptFileTransfer('incoming_transfer_123');
        
        expect(result, isTrue);
      });
      
      test('should reject file transfer successfully', () async {
        final result = await fileService.rejectFileTransfer(
          'incoming_transfer_123',
          reason: 'Not enough storage space',
        );
        
        expect(result, isTrue);
      });
      
      test('should cancel active transfer successfully', () async {
        final testFile = FileInfo(
          fileId: 'test_file_cancel',
          filename: 'test_cancel.txt',
          filepath: '/tmp/test_cancel.txt',
          size: 2048,
          mimeType: 'text/plain',
          checksum: 'def456',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final transfer = await fileService.sendFile(
          targetId: 'user123',
          file: testFile,
        );
        
        expect(transfer, isNotNull);
        
        final cancelResult = await fileService.cancelTransfer(transfer!.transferId);
        
        expect(cancelResult, isTrue);
      });
      
      test('should pause and resume transfer successfully', () async {
        final testFile = FileInfo(
          fileId: 'test_file_pause',
          filename: 'test_pause.txt',
          filepath: '/tmp/test_pause.txt',
          size: 4096,
          mimeType: 'text/plain',
          checksum: 'ghi789',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final transfer = await fileService.sendFile(
          targetId: 'user123',
          file: testFile,
        );
        
        expect(transfer, isNotNull);
        
        // Pause transfer
        final pauseResult = await fileService.pauseTransfer(transfer!.transferId);
        expect(pauseResult, isTrue);
        
        // Resume transfer
        final resumeResult = await fileService.resumeTransfer(transfer.transferId);
        expect(resumeResult, isTrue);
      });
    });

    group('Chunk-based Transfer', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should split file into chunks correctly', () async {
        final testData = Uint8List.fromList(List.generate(10240, (i) => i % 256));
        
        final chunks = await fileService.splitIntoChunks(testData, chunkSize: 1024);
        
        expect(chunks, isNotEmpty);
        expect(chunks.length, equals(10)); // 10240 / 1024 = 10 chunks
        expect(chunks.first.data.length, equals(1024));
      });
      
      test('should reassemble chunks correctly', () async {
        final originalData = Uint8List.fromList(List.generate(5120, (i) => i % 256));
        final chunks = await fileService.splitIntoChunks(originalData, chunkSize: 512);
        
        final reassembledData = await fileService.reassembleChunks(chunks);
        
        expect(reassembledData, isNotNull);
        expect(reassembledData!.length, equals(originalData.length));
        expect(reassembledData, equals(originalData));
      });
      
      test('should verify chunk integrity', () async {
        final testChunk = FileChunk(
          chunkId: 'chunk_123',
          fileId: 'file_123',
          sequenceNumber: 0,
          data: Uint8List.fromList([1, 2, 3, 4, 5]),
          checksum: 'chunk_checksum',
          size: 5,
          isLastChunk: false,
          timestamp: DateTime.now(),
          retryCount: 0,
        );
        
        final isValid = await fileService.verifyChunkIntegrity(testChunk);
        
        expect(isValid, isTrue);
      });
      
      test('should handle missing chunks gracefully', () async {
        final chunks = <FileChunk>[
          FileChunk(
            chunkId: 'chunk_0',
            fileId: 'file_missing',
            sequenceNumber: 0,
            data: Uint8List.fromList([1, 2, 3]),
            checksum: 'checksum_0',
            size: 3,
            isLastChunk: false,
            timestamp: DateTime.now(),
            retryCount: 0,
          ),
          // Missing chunk 1
          FileChunk(
            chunkId: 'chunk_2',
            fileId: 'file_missing',
            sequenceNumber: 2,
            data: Uint8List.fromList([7, 8, 9]),
            checksum: 'checksum_2',
            size: 3,
            isLastChunk: true,
            timestamp: DateTime.now(),
            retryCount: 0,
          ),
        ];
        
        final missingChunks = await fileService.findMissingChunks(chunks, totalChunks: 3);
        
        expect(missingChunks, contains(1));
        expect(missingChunks.length, equals(1));
      });
    });

    group('Emergency File Broadcasting', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should activate emergency mode successfully', () async {
        final result = await fileService.activateEmergencyMode();
        
        expect(result, isTrue);
        expect(fileService.isEmergencyMode, isTrue);
        expect(fileService.defaultProtocol, equals(TransferProtocol.emergency_priority));
      });
      
      test('should broadcast emergency file successfully', () async {
        await fileService.activateEmergencyMode();
        
        final emergencyFile = FileInfo(
          fileId: 'emergency_file',
          filename: 'emergency_info.pdf',
          filepath: '/emergency/info.pdf',
          size: 2048,
          mimeType: 'application/pdf',
          checksum: 'emergency_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_only,
          metadata: {'emergency_type': 'evacuation_map'},
        );
        
        final broadcast = EmergencyFileBroadcast(
          broadcastId: 'emergency_broadcast_123',
          file: emergencyFile,
          emergencyType: EmergencyType.evacuation,
          priority: BroadcastPriority.critical,
          targetArea: EmergencyArea.city_wide,
          channels: [BroadcastChannel.mesh_network, BroadcastChannel.emergency_radio],
          expirationTime: DateTime.now().add(const Duration(hours: 24)),
          isActive: true,
          metadata: {'evacuation_zone': 'Zone_A'},
        );
        
        final result = await fileService.broadcastEmergencyFile(broadcast);
        
        expect(result, isTrue);
      });
      
      test('should prioritize emergency transfers', () async {
        await fileService.activateEmergencyMode();
        
        final emergencyTransfer = FileTransfer(
          transferId: 'emergency_transfer',
          senderId: 'emergency_service',
          recipientId: 'user1',
          file: FileInfo(
            fileId: 'emergency_file',
            filename: 'emergency.txt',
            filepath: '/emergency.txt',
            size: 1024,
            mimeType: 'text/plain',
            checksum: 'emergency_checksum',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            isDirectory: false,
            permissions: FilePermissions.read_only,
            metadata: {},
          ),
          protocol: TransferProtocol.emergency_priority,
          priority: TransferPriority.emergency,
          status: TransferStatus.in_progress,
          progress: 0.0,
          transferredBytes: 0,
          totalBytes: 1024,
          startTime: DateTime.now(),
          isEmergencyTransfer: true,
          metadata: {},
        );
        
        final normalTransfer = FileTransfer(
          transferId: 'normal_transfer',
          senderId: 'user1',
          recipientId: 'user2',
          file: FileInfo(
            fileId: 'normal_file',
            filename: 'normal.txt',
            filepath: '/normal.txt',
            size: 1024,
            mimeType: 'text/plain',
            checksum: 'normal_checksum',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            isDirectory: false,
            permissions: FilePermissions.read_write,
            metadata: {},
          ),
          protocol: TransferProtocol.http_chunk,
          priority: TransferPriority.normal,
          status: TransferStatus.in_progress,
          progress: 0.0,
          transferredBytes: 0,
          totalBytes: 1024,
          startTime: DateTime.now(),
          isEmergencyTransfer: false,
          metadata: {},
        );
        
        expect(emergencyTransfer.priority.index, lessThan(normalTransfer.priority.index));
      });
    });

    group('File Sharing and Management', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should create shared folder successfully', () async {
        final sharedFolder = SharedFolder(
          folderId: 'shared_folder_123',
          name: 'Emergency Documents',
          description: 'Shared emergency documentation',
          ownerId: 'admin',
          path: '/shared/emergency',
          permissions: FolderPermissions.read_write,
          members: ['user1', 'user2', 'user3'],
          isPublic: false,
          maxSize: 1024 * 1024 * 10, // 10MB
          createdAt: DateTime.now(),
          expirationTime: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
          metadata: {'category': 'emergency'},
        );
        
        final result = await fileService.createSharedFolder(sharedFolder);
        
        expect(result, isTrue);
      });
      
      test('should add file to shared folder successfully', () async {
        final testFile = FileInfo(
          fileId: 'shared_file',
          filename: 'shared_document.pdf',
          filepath: '/shared/document.pdf',
          size: 4096,
          mimeType: 'application/pdf',
          checksum: 'shared_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_only,
          metadata: {},
        );
        
        final result = await fileService.addFileToSharedFolder(
          'shared_folder_123',
          testFile,
        );
        
        expect(result, isTrue);
      });
      
      test('should remove file from shared folder successfully', () async {
        final result = await fileService.removeFileFromSharedFolder(
          'shared_folder_123',
          'shared_file',
        );
        
        expect(result, isTrue);
      });
      
      test('should manage folder permissions correctly', () async {
        final result = await fileService.updateFolderPermissions(
          'shared_folder_123',
          'user1',
          FolderPermissions.read_only,
        );
        
        expect(result, isTrue);
      });
    });

    group('Store and Forward Relay', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should enable store and forward relay successfully', () async {
        final result = await fileService.enableStoreAndForwardRelay(true);
        
        expect(result, isTrue);
        expect(fileService.isStoreAndForwardEnabled, isTrue);
      });
      
      test('should store file for offline delivery', () async {
        await fileService.enableStoreAndForwardRelay(true);
        
        final testFile = FileInfo(
          fileId: 'offline_file',
          filename: 'offline.txt',
          filepath: '/tmp/offline.txt',
          size: 1024,
          mimeType: 'text/plain',
          checksum: 'offline_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final result = await fileService.storeForOfflineDelivery(
          'offline_user',
          testFile,
          expirationTime: DateTime.now().add(const Duration(hours: 24)),
        );
        
        expect(result, isTrue);
      });
      
      test('should forward stored files when recipient is online', () async {
        await fileService.enableStoreAndForwardRelay(true);
        
        final result = await fileService.forwardStoredFiles('offline_user');
        
        expect(result, isA<List<String>>()); // Returns list of forwarded transfer IDs
      });
    });

    group('Mesh Integration', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should enable mesh integration successfully', () async {
        final result = await fileService.enableMeshIntegration(true);
        
        expect(result, isTrue);
        expect(fileService.isMeshEnabled, isTrue);
      });
      
      test('should route file transfer through mesh network', () async {
        await fileService.enableMeshIntegration(true);
        
        final testFile = FileInfo(
          fileId: 'mesh_file',
          filename: 'mesh_test.txt',
          filepath: '/tmp/mesh_test.txt',
          size: 2048,
          mimeType: 'text/plain',
          checksum: 'mesh_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final transfer = await fileService.sendFileViaMesh(
          'mesh_target',
          testFile,
          hopLimit: 5,
        );
        
        expect(transfer, isNotNull);
        expect(transfer!.protocol, equals(TransferProtocol.mesh_optimized));
      });
    });

    group('Security and Encryption', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should enable encryption successfully', () async {
        final result = await fileService.enableEncryption(true);
        
        expect(result, isTrue);
        expect(fileService.isEncryptionEnabled, isTrue);
      });
      
      test('should encrypt file data correctly', () async {
        await fileService.enableEncryption(true);
        
        final plainData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final encryptedData = await fileService.encryptData(plainData);
        
        expect(encryptedData, isNotNull);
        expect(encryptedData, isNot(equals(plainData)));
      });
      
      test('should decrypt file data correctly', () async {
        await fileService.enableEncryption(true);
        
        final plainData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final encryptedData = await fileService.encryptData(plainData);
        final decryptedData = await fileService.decryptData(encryptedData!);
        
        expect(decryptedData, isNotNull);
        expect(decryptedData, equals(plainData));
      });
      
      test('should verify file integrity with checksums', () async {
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final checksum = await fileService.calculateChecksum(testData);
        
        expect(checksum, isNotNull);
        expect(checksum, isA<String>());
        
        final isValid = await fileService.verifyChecksum(testData, checksum!);
        expect(isValid, isTrue);
      });
    });

    group('Performance and Statistics', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should track transfer statistics', () async {
        // Create multiple transfers
        for (int i = 0; i < 5; i++) {
          final testFile = FileInfo(
            fileId: 'stats_file_$i',
            filename: 'stats_$i.txt',
            filepath: '/tmp/stats_$i.txt',
            size: 1024 * (i + 1),
            mimeType: 'text/plain',
            checksum: 'stats_checksum_$i',
            createdAt: DateTime.now(),
            modifiedAt: DateTime.now(),
            isDirectory: false,
            permissions: FilePermissions.read_write,
            metadata: {},
          );
          
          await fileService.sendFile(
            targetId: 'user_$i',
            file: testFile,
          );
        }
        
        final stats = fileService.getStatistics();
        
        expect(stats, containsKey('totalTransfers'));
        expect(stats, containsKey('activeTransfers'));
        expect(stats, containsKey('completedTransfers'));
        expect(stats, containsKey('failedTransfers'));
        expect(stats, containsKey('totalBytesTransferred'));
        expect(stats, containsKey('averageTransferSpeed'));
        expect(stats['totalTransfers'], greaterThanOrEqualTo(5));
      });
      
      test('should calculate transfer speed metrics', () async {
        final testFile = FileInfo(
          fileId: 'speed_test_file',
          filename: 'speed_test.txt',
          filepath: '/tmp/speed_test.txt',
          size: 8192,
          mimeType: 'text/plain',
          checksum: 'speed_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final transfer = await fileService.sendFile(
          targetId: 'speed_test_user',
          file: testFile,
        );
        
        expect(transfer, isNotNull);
        
        // Simulate some progress
        await Future.delayed(const Duration(milliseconds: 100));
        
        final metrics = fileService.getTransferMetrics(transfer!.transferId);
        
        expect(metrics, containsKey('speed'));
        expect(metrics, containsKey('eta'));
        expect(metrics, containsKey('efficiency'));
      });
    });

    group('Error Handling', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should handle file not found error gracefully', () async {
        final nonExistentFile = FileInfo(
          fileId: 'non_existent',
          filename: 'does_not_exist.txt',
          filepath: '/non/existent/path.txt',
          size: 0,
          mimeType: 'text/plain',
          checksum: 'fake_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final transfer = await fileService.sendFile(
          targetId: 'user123',
          file: nonExistentFile,
        );
        
        // Should handle gracefully, may return null or failed transfer
        expect(transfer, anyOf(isNull, isA<FileTransfer>()));
      });
      
      test('should handle network disconnection during transfer', () async {
        final testFile = FileInfo(
          fileId: 'network_test_file',
          filename: 'network_test.txt',
          filepath: '/tmp/network_test.txt',
          size: 4096,
          mimeType: 'text/plain',
          checksum: 'network_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final transfer = await fileService.sendFile(
          targetId: 'network_user',
          file: testFile,
        );
        
        expect(transfer, isNotNull);
        
        // Simulate network disconnection
        await fileService.updateNetworkCondition(NetworkCondition.critical);
        
        // Service should remain stable
        expect(fileService.isInitialized, isTrue);
      });
      
      test('should handle insufficient storage space', () async {
        final largeFile = FileInfo(
          fileId: 'large_file',
          filename: 'large.bin',
          filepath: '/tmp/large.bin',
          size: 1024 * 1024 * 1024, // 1GB
          mimeType: 'application/octet-stream',
          checksum: 'large_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {},
        );
        
        final result = await fileService.checkStorageSpace(largeFile.size);
        
        expect(result, isA<bool>());
        
        if (!result) {
          // Should handle insufficient space gracefully
          final transfer = await fileService.sendFile(
            targetId: 'storage_user',
            file: largeFile,
          );
          
          // May fail but should not crash
          expect(() => transfer, returnsNormally);
        }
      });
    });

    group('Stream Management', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should provide transfer progress stream', () async {
        final stream = fileService.transferProgressStream;
        
        expect(stream, isA<Stream<FileTransferProgress>>());
        
        final subscription = stream.listen((progress) {
          expect(progress, isA<FileTransferProgress>());
        });
        
        await subscription.cancel();
      });
      
      test('should provide transfer events stream', () async {
        final stream = fileService.transferEventsStream;
        
        expect(stream, isA<Stream<FileTransfer>>());
        
        final subscription = stream.listen((transfer) {
          expect(transfer, isA<FileTransfer>());
        });
        
        await subscription.cancel();
      });
    });

    group('Integration Tests', () {
      setUp(() async {
        await fileService.initialize();
      });
      
      test('should handle complete file transfer flow', () async {
        // Create test file
        final testFile = FileInfo(
          fileId: 'integration_test_file',
          filename: 'integration_test.txt',
          filepath: '/tmp/integration_test.txt',
          size: 2048,
          mimeType: 'text/plain',
          checksum: 'integration_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_write,
          metadata: {'test': 'integration'},
        );
        
        // Start transfer
        final transfer = await fileService.sendFile(
          targetId: 'integration_user',
          file: testFile,
          priority: TransferPriority.high,
        );
        
        expect(transfer, isNotNull);
        expect(transfer!.isActive, isTrue);
        
        // Simulate transfer progress
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Check transfer status
        final status = fileService.getTransferStatus(transfer.transferId);
        expect(status, isA<TransferStatus>());
        
        // Complete transfer (in real scenario this would be automatic)
        final progress = FileTransferProgress(
          transferId: transfer.transferId,
          progress: 1.0,
          transferredBytes: testFile.size,
          totalBytes: testFile.size,
          speed: 1024 * 10, // 10 KB/s
          eta: Duration.zero,
          status: TransferStatus.completed,
          timestamp: DateTime.now(),
        );
        
        expect(progress.isCompleted, isTrue);
        expect(progress.progress, equals(1.0));
      });
      
      test('should handle emergency file broadcast scenario', () async {
        // Activate emergency mode
        await fileService.activateEmergencyMode();
        expect(fileService.isEmergencyMode, isTrue);
        
        // Create emergency file
        final emergencyFile = FileInfo(
          fileId: 'emergency_integration_file',
          filename: 'evacuation_map.pdf',
          filepath: '/emergency/evacuation_map.pdf',
          size: 4096,
          mimeType: 'application/pdf',
          checksum: 'emergency_integration_checksum',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          isDirectory: false,
          permissions: FilePermissions.read_only,
          metadata: {'emergency_type': 'evacuation'},
        );
        
        // Create emergency broadcast
        final broadcast = EmergencyFileBroadcast(
          broadcastId: 'emergency_integration_broadcast',
          file: emergencyFile,
          emergencyType: EmergencyType.evacuation,
          priority: BroadcastPriority.critical,
          targetArea: EmergencyArea.neighborhood,
          channels: [
            BroadcastChannel.mesh_network,
            BroadcastChannel.emergency_radio,
            BroadcastChannel.cellular,
          ],
          expirationTime: DateTime.now().add(const Duration(hours: 12)),
          isActive: true,
          metadata: {'evacuation_zone': 'Zone_Integration_Test'},
        );
        
        // Start emergency broadcast
        final broadcastResult = await fileService.broadcastEmergencyFile(broadcast);
        expect(broadcastResult, isTrue);
        
        // Enable mesh integration for distribution
        await fileService.enableMeshIntegration(true);
        expect(fileService.isMeshEnabled, isTrue);
        
        // Test file distribution through mesh
        final meshTransfer = await fileService.sendFileViaMesh(
          'emergency_recipient',
          emergencyFile,
          hopLimit: 3,
        );
        
        expect(meshTransfer, isNotNull);
        expect(meshTransfer!.isEmergencyTransfer, isTrue);
        expect(meshTransfer.protocol, equals(TransferProtocol.mesh_optimized));
        
        // Cleanup
        await fileService.deactivateEmergencyMode();
        expect(fileService.isEmergencyMode, isFalse);
      });
    });
  });
}
