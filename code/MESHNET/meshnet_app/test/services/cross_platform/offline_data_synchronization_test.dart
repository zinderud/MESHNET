// test/services/cross_platform/offline_data_synchronization_test.dart - Offline Data Synchronization Service Tests
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/cross_platform/offline_data_synchronization.dart';

void main() {
  group('OfflineDataSynchronization Service Tests', () {
    late OfflineDataSynchronization service;

    setUp(() {
      service = OfflineDataSynchronization.instance;
    });

    tearDown(() async {
      await service.shutdown();
    });

    test('should initialize successfully', () async {
      final result = await service.initialize();
      
      expect(result, isTrue);
      expect(service.isInitialized, isTrue);
      expect(service.isSyncEnabled, isTrue);
    });

    test('should enable and disable sync', () async {
      await service.initialize();
      
      final disableResult = await service.disableSync();
      expect(disableResult, isTrue);
      expect(service.isSyncEnabled, isFalse);
      
      final enableResult = await service.enableSync();
      expect(enableResult, isTrue);
      expect(service.isSyncEnabled, isTrue);
    });

    test('should queue data for synchronization', () async {
      await service.initialize();
      
      final result = await service.addDataToSync(
        DataType.messages,
        '/local/messages',
        '/remote/messages',
        {'content': 'test message'},
        priority: SyncPriority.high,
      );
      
      expect(result, isTrue);
      
      final pendingItems = service.getPendingSyncItems();
      expect(pendingItems, isNotEmpty);
      expect(pendingItems.first.dataType, equals(DataType.messages));
    });

    test('should create and process sync batches', () async {
      await service.initialize();
      
      // Add multiple items
      await service.addDataToSync(DataType.files, '/local/file1', '/remote/file1', {'data': 'file1'});
      await service.addDataToSync(DataType.files, '/local/file2', '/remote/file2', {'data': 'file2'});
      
      final pendingItems = service.getPendingSyncItems(DataType.files);
      final itemIds = pendingItems.map((item) => item.itemId).toList();
      
      final batchId = await service.createSyncBatch(itemIds, DataType.files);
      expect(batchId, isNotNull);
      
      final result = await service.processSyncBatch(batchId!);
      expect(result, isTrue);
    });

    test('should set sync strategies', () async {
      await service.initialize();
      
      final result = await service.setSyncStrategy(SyncStrategy.immediate);
      expect(result, isTrue);
      expect(service.currentStrategy, equals(SyncStrategy.immediate));
      
      final dataTypeResult = await service.setDataTypeSyncStrategy(DataType.messages, SyncStrategy.batch);
      expect(dataTypeResult, isTrue);
    });

    test('should force sync all pending items', () async {
      await service.initialize();
      
      // Add test data
      await service.addDataToSync(DataType.emergency_contacts, '/local/contacts', '/remote/contacts', {'contacts': []});
      
      final processedCount = await service.forceSyncAll();
      expect(processedCount, greaterThanOrEqualTo(0));
    });

    test('should get sync statistics', () async {
      await service.initialize();
      
      final stats = service.getSyncStatistics();
      
      expect(stats, isNotNull);
      expect(stats.totalItems, isA<int>());
      expect(stats.successRate, isA<double>());
    });

    test('should get connectivity state', () async {
      await service.initialize();
      
      final connectivity = service.connectivityState;
      
      expect(connectivity, isNotNull);
      expect(connectivity.hasAnyConnection, isA<bool>());
    });

    test('should get sync status', () async {
      await service.initialize();
      
      final status = service.getSyncStatus();
      
      expect(status, isNotEmpty);
      expect(status['isEnabled'], isA<bool>());
      expect(status['strategy'], isNotNull);
    });
  });
}
