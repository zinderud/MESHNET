import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/services/ai/smart_message_classifier.dart';

void main() {
  test('SmartMessageClassifier initialization test', () async {
    final service = SmartMessageClassifier.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('SmartMessageClassifier message classification test', () async {
    final service = SmartMessageClassifier.instance;
    await service.initialize();
    
    final result = await service.classifyMessage('Hello, how are you?');
    expect(result, isA<Map<String, dynamic>>());
    expect(result['category'], isA<String>());
    expect(result['confidence'], isA<double>());
    
    await service.shutdown();
  });

  test('SmartMessageClassifier sentiment analysis test', () async {
    final service = SmartMessageClassifier.instance;
    await service.initialize();
    
    final result = await service.analyzeSentiment('I am very happy today!');
    expect(result, isA<Map<String, dynamic>>());
    expect(result['sentiment'], isA<String>());
    expect(result['score'], isA<double>());
    
    await service.shutdown();
  });
}
