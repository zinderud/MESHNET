// test/services/cross_platform/desktop_integration_test.dart - Desktop Integration Service Tests
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/cross_platform/desktop_integration.dart';

void main() {
  group('DesktopIntegration Service Tests', () {
    late DesktopIntegration service;

    setUp(() {
      service = DesktopIntegration.instance;
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

    test('should detect platform capabilities', () async {
      await service.initialize();
      
      final capabilities = service.getCapabilities();
      
      expect(capabilities, isNotEmpty);
      expect(capabilities.containsKey(DesktopFeature.notifications), isTrue);
      expect(capabilities.containsKey(DesktopFeature.file_system_access), isTrue);
    });

    test('should get capabilities', () async {
      await service.initialize();
      
      final capabilities = service.getCapabilities();
      expect(capabilities, isA<Map<DesktopFeature, bool>>());
    });

    test('should have system information', () async {
      await service.initialize();
      
      final systemInfo = service.getSystemInfo();
      
      expect(systemInfo, isNotEmpty);
      expect(systemInfo['platform'], isNotNull);
      expect(systemInfo.containsKey('isInitialized'), isTrue);
    });

    test('should track system tray state', () async {
      await service.initialize();
      
      expect(service.isSystemTrayEnabled, isA<bool>());
      expect(service.isBackgroundServiceRunning, isA<bool>());
    });
  });
}
