import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/services/ai/emergency_detection_engine.dart';

void main() {
  test('EmergencyDetectionEngine initialization test', () async {
    final service = EmergencyDetectionEngine.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('EmergencyDetectionEngine message analysis test', () async {
    final service = EmergencyDetectionEngine.instance;
    await service.initialize();
    
    final result = await service.analyzeMessage('Help! There is a fire in the building!');
    expect(result, isA<Map<String, dynamic>>());
    expect(result['isEmergency'], isA<bool>());
    expect(result['confidence'], isA<double>());
    
    await service.shutdown();
  });

  test('EmergencyDetectionEngine pattern detection test', () async {
    final service = EmergencyDetectionEngine.instance;
    await service.initialize();
    
    await service.startPatternDetection();
    expect(service.isDetecting, isTrue);
    
    await service.stopPatternDetection();
    expect(service.isDetecting, isFalse);
    
    await service.shutdown();
  });
}
