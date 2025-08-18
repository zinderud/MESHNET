import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/services/ai/emergency_router.dart';

void main() {
  test('EmergencyRouter initialization test', () async {
    final service = EmergencyRouter.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('EmergencyRouter route calculation test', () async {
    final service = EmergencyRouter.instance;
    await service.initialize();
    
    final route = await service.calculateEmergencyRoute('node1', 'node2');
    expect(route, isA<List<String>>());
    
    await service.shutdown();
  });

  test('EmergencyRouter priority routing test', () async {
    final service = EmergencyRouter.instance;
    await service.initialize();
    
    final result = await service.routeWithPriority('test_message', 'high');
    expect(result, isA<Map<String, dynamic>>());
    expect(result['success'], isA<bool>());
    
    await service.shutdown();
  });
}
