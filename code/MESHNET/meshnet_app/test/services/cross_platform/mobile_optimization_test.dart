// test/services/cross_platform/mobile_optimization_test.dart - Mobile Optimization Service Tests
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/cross_platform/mobile_optimization.dart';

void main() {
  group('MobileOptimization Service Tests', () {
    late MobileOptimization service;

    setUp(() {
      service = MobileOptimization.instance;
    });

    tearDown(() async {
      await service.shutdown();
    });

    test('should initialize successfully', () async {
      final result = await service.initialize();
      
      expect(result, isTrue);
      expect(service.isInitialized, isTrue);
      expect(service.currentPlatform, isNotNull);
    });

    test('should start and stop optimization', () async {
      await service.initialize();
      
      final startResult = await service.startOptimization();
      expect(startResult, isTrue);
      expect(service.isOptimizationActive, isTrue);
      
      final stopResult = await service.stopOptimization();
      expect(stopResult, isTrue);
      expect(service.isOptimizationActive, isFalse);
    });

    test('should set battery optimization level', () async {
      await service.initialize();
      
      final result = await service.setBatteryOptimization(BatteryOptimizationLevel.power_saver);
      expect(result, isTrue);
      expect(service.batteryOptimizationLevel, equals(BatteryOptimizationLevel.power_saver));
    });

    test('should set network optimization strategy', () async {
      await service.initialize();
      
      final result = await service.setNetworkOptimization(NetworkOptimizationStrategy.mesh_priority);
      expect(result, isTrue);
      expect(service.networkStrategy, equals(NetworkOptimizationStrategy.mesh_priority));
    });

    test('should configure background tasks', () async {
      await service.initialize();
      
      final config = BackgroundTaskConfig(
        taskId: 'test_task',
        taskType: 'sync',
        interval: const Duration(minutes: 15),
      );
      
      final result = await service.configureBackgroundTask(config);
      expect(result, isTrue);
    });

    test('should collect performance metrics', () async {
      await service.initialize();
      
      await service.forcePerformanceAnalysis();
      
      final metrics = service.getCurrentMetrics();
      expect(metrics, isNotNull);
      expect(metrics!.performanceScore, isA<double>());
    });

    test('should generate optimization recommendations', () async {
      await service.initialize();
      await service.forcePerformanceAnalysis();
      
      final recommendations = service.getRecommendations();
      expect(recommendations, isA<List<OptimizationRecommendation>>());
    });

    test('should get optimization statistics', () async {
      await service.initialize();
      
      final stats = service.getOptimizationStats();
      
      expect(stats, isNotEmpty);
      expect(stats['isActive'], isA<bool>());
      expect(stats['platform'], isNotNull);
    });
  });
}
