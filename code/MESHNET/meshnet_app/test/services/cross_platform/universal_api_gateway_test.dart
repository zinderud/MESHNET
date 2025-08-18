// test/services/cross_platform/universal_api_gateway_test.dart - Universal API Gateway Service Tests
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/services/cross_platform/universal_api_gateway.dart';

void main() {
  group('UniversalAPIGateway Service Tests', () {
    late UniversalAPIGateway service;

    setUp(() {
      service = UniversalAPIGateway.instance;
    });

    tearDown(() async {
      await service.shutdown();
    });

    test('should initialize successfully', () async {
      final result = await service.initialize();
      
      expect(result, isTrue);
      expect(service.isInitialized, isTrue);
    });

    test('should register and unregister endpoints', () async {
      await service.initialize();
      
      final config = APIEndpointConfig(
        endpointId: 'test_endpoint',
        name: 'Test API',
        baseUrl: 'https://api.test.com',
        protocol: APIProtocol.rest,
      );
      
      final registerResult = await service.registerEndpoint(config);
      expect(registerResult, isTrue);
      
      final endpoint = service.getEndpoint('test_endpoint');
      expect(endpoint, isNotNull);
      expect(endpoint!.name, equals('Test API'));
      
      final unregisterResult = await service.unregisterEndpoint('test_endpoint');
      expect(unregisterResult, isTrue);
    });

    test('should make GET requests', () async {
      await service.initialize();
      
      final config = APIEndpointConfig(
        endpointId: 'get_test',
        name: 'GET Test API',
        baseUrl: 'https://jsonplaceholder.typicode.com',
        protocol: APIProtocol.rest,
      );
      
      await service.registerEndpoint(config);
      
      final response = await service.get('get_test', '/posts/1');
      
      expect(response, isNotNull);
      expect(response.requestId, isNotNull);
    });

    test('should make POST requests', () async {
      await service.initialize();
      
      final config = APIEndpointConfig(
        endpointId: 'post_test',
        name: 'POST Test API',
        baseUrl: 'https://jsonplaceholder.typicode.com',
        protocol: APIProtocol.rest,
      );
      
      await service.registerEndpoint(config);
      
      final response = await service.post(
        'post_test',
        '/posts',
        body: {'title': 'Test', 'body': 'Test body', 'userId': 1},
      );
      
      expect(response, isNotNull);
      expect(response.requestId, isNotNull);
    });

    test('should handle caching', () async {
      await service.initialize();
      
      final config = APIEndpointConfig(
        endpointId: 'cache_test',
        name: 'Cache Test API',
        baseUrl: 'https://api.test.com',
        protocol: APIProtocol.rest,
        enableCache: true,
        cacheTimeout: const Duration(minutes: 5),
      );
      
      await service.registerEndpoint(config);
      
      // Make first request
      final response1 = await service.get('cache_test', '/data');
      expect(response1.fromCache, isFalse);
      
      // Clear cache
      service.clearCache();
      
      // Verify cache was cleared
      expect(service.getGatewayStatus()['cacheSize'], equals(0));
    });

    test('should get queue status', () async {
      await service.initialize();
      
      final queueStatus = service.getQueueStatus();
      
      expect(queueStatus, isNotEmpty);
      expect(queueStatus['queueSize'], isA<int>());
      expect(queueStatus['isProcessing'], isA<bool>());
    });

    test('should get gateway statistics', () async {
      await service.initialize();
      
      final stats = service.statistics;
      
      expect(stats, isNotNull);
      expect(stats.totalRequests, isA<int>());
      expect(stats.successRate, isA<double>());
    });

    test('should get gateway status', () async {
      await service.initialize();
      
      final status = service.getGatewayStatus();
      
      expect(status, isNotEmpty);
      expect(status['isInitialized'], isTrue);
      expect(status['endpointsCount'], isA<int>());
    });

    test('should handle endpoint not found', () async {
      await service.initialize();
      
      final response = await service.get('nonexistent_endpoint', '/test');
      
      expect(response.statusCode, equals(404));
      expect(response.error, contains('Endpoint not found'));
    });
  });
}
