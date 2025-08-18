import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/services/ai/context_aware_response.dart';

void main() {
  test('ContextAwareResponse initialization test', () async {
    final service = ContextAwareResponse.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('ContextAwareResponse message generation test', () async {
    final service = ContextAwareResponse.instance;
    await service.initialize();
    
    final response = await service.generateResponse(
      'What is the weather like?',
      {'location': 'Istanbul', 'time': DateTime.now().toIso8601String()},
    );
    expect(response, isA<String>());
    expect(response.isNotEmpty, isTrue);
    
    await service.shutdown();
  });

  test('ContextAwareResponse context analysis test', () async {
    final service = ContextAwareResponse.instance;
    await service.initialize();
    
    final context = await service.analyzeContext({
      'userMessage': 'Help me',
      'location': 'Emergency zone',
      'batteryLevel': 0.2,
    });
    expect(context, isA<Map<String, dynamic>>());
    expect(context['priority'], isA<String>());
    
    await service.shutdown();
  });
}
