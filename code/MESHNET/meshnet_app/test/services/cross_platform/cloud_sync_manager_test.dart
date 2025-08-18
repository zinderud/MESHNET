// test/services/cross_platform/cloud_sync_manager_test.dart - Cloud Sync Manager Service Tests
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/cross_platform/cloud_sync_manager.dart';

void main() {
  group('CloudSyncManager Service Tests', () {
    late CloudSyncManager service;

    setUp(() {
      service = CloudSyncManager.instance;
    });

    tearDown(() async {
      await service.shutdown();
    });

    test('should initialize successfully', () async {
      final result = await service.initialize();
      
      expect(result, isTrue);
      expect(service.isInitialized, isTrue);
    });

    test('should add and remove sync configurations', () async {
      await service.initialize();
      
      final config = SyncConfiguration(
        configId: 'test_config',
        provider: CloudProvider.aws,
        endpoint: 'https://test.endpoint.com',
        credentials: {'key': 'value'},
      );
      
      final addResult = await service.addSyncConfiguration(config);
      expect(addResult, isTrue);
      
      final removeResult = await service.removeSyncConfiguration('test_config');
      expect(removeResult, isTrue);
    });

    test('should enable and disable auto sync', () async {
      await service.initialize();
      
      final enableResult = await service.enableAutoSync();
      expect(enableResult, isTrue);
      expect(service.autoSyncEnabled, isTrue);
      
      final disableResult = await service.disableAutoSync();
      expect(disableResult, isTrue);
      expect(service.autoSyncEnabled, isFalse);
    });

    test('should upload files to cloud', () async {
      await service.initialize();
      
      final config = SyncConfiguration(
        configId: 'upload_config',
        provider: CloudProvider.google_cloud,
        endpoint: 'https://storage.googleapis.com',
        credentials: {'token': 'test_token'},
      );
      
      await service.addSyncConfiguration(config);
      
      final operation = await service.uploadFile('/local/path', '/remote/path');
      expect(operation, isNotNull);
      expect(operation!.type, equals(SyncOperationType.upload));
    });

    test('should download files from cloud', () async {
      await service.initialize();
      
      final config = SyncConfiguration(
        configId: 'download_config',
        provider: CloudProvider.azure,
        endpoint: 'https://test.blob.core.windows.net',
        credentials: {'connection_string': 'test_string'},
      );
      
      await service.addSyncConfiguration(config);
      
      final operation = await service.downloadFile('/remote/path', '/local/path');
      expect(operation, isNotNull);
      expect(operation!.type, equals(SyncOperationType.download));
    });

    test('should get sync statistics', () async {
      await service.initialize();
      
      final stats = service.statistics;
      
      expect(stats, isNotNull);
      expect(stats.totalOperations, isA<int>());
      expect(stats.successRate, isA<double>());
    });

    test('should get sync status', () async {
      await service.initialize();
      
      final status = service.getSyncStatus();
      
      expect(status, isNotEmpty);
      expect(status['isActive'], isA<bool>());
      expect(status['statistics'], isNotNull);
    });
  });
}
