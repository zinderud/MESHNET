import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/services/ai/predictive_network_optimization.dart';

void main() {
  test('PredictiveNetworkOptimization initialization test', () async {
    final service = PredictiveNetworkOptimization.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('PredictiveNetworkOptimization basic functionality test', () async {
    final service = PredictiveNetworkOptimization.instance;
    await service.initialize();
    
    expect(service.historySize, equals(0));
    expect(service.activeNodes, equals(0));
    
    await service.shutdown();
  });

  test('PredictiveNetworkOptimization performance metrics test', () async {
    final service = PredictiveNetworkOptimization.instance;
    await service.initialize();
    
    final metrics = service.getPerformanceMetrics();
    expect(metrics, isA<Map<String, dynamic>>());
    expect(metrics['totalNodes'], isA<int>());
    expect(metrics['isOptimizing'], isA<bool>());
    
    await service.shutdown();
  });
}
