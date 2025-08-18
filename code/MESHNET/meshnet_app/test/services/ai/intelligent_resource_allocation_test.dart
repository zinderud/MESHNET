import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/services/ai/intelligent_resource_allocation.dart';

void main() {
  test('IntelligentResourceAllocation initialization test', () async {
    final service = IntelligentResourceAllocation.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('IntelligentResourceAllocation basic properties test', () async {
    final service = IntelligentResourceAllocation.instance;
    await service.initialize();
    
    expect(service.pendingRequestsCount, equals(0));
    expect(service.activeAllocationsCount, equals(0));
    expect(service.registeredNodesCount, equals(0));
    
    await service.shutdown();
  });

  test('IntelligentResourceAllocation performance metrics test', () async {
    final service = IntelligentResourceAllocation.instance;
    await service.initialize();
    
    final metrics = service.getPerformanceMetrics();
    expect(metrics, isA<Map<String, dynamic>>());
    expect(metrics['totalNodes'], isA<int>());
    expect(metrics['isOptimizing'], isA<bool>());
    
    await service.shutdown();
  });
}
