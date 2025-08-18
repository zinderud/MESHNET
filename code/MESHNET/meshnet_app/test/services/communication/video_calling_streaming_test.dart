import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import 'package:meshnet_app/services/communication/video_calling_streaming.dart';

void main() {
  test('VideoCallingStreaming initialization test', () async {
    final service = VideoCallingStreaming.instance;
    final result = await service.initialize();
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
    await service.shutdown();
  });

  test('VideoCallingStreaming camera test', () async {
    final service = VideoCallingStreaming.instance;
    await service.initialize();
    
    await service.startCamera();
    expect(service.isCameraActive, isTrue);
    
    await service.stopCamera();
    expect(service.isCameraActive, isFalse);
    
    await service.shutdown();
  });

  test('VideoCallingStreaming emergency mode test', () async {
    final service = VideoCallingStreaming.instance;
    await service.initialize();
    
    await service.activateEmergencyMode();
    expect(service.isEmergencyMode, isTrue);
    
    await service.deactivateEmergencyMode();
    expect(service.isEmergencyMode, isFalse);
    
    await service.shutdown();
  });
}
