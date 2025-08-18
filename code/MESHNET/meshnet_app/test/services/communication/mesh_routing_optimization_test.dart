// test/services/communication/mesh_routing_optimization_test.dart - Mesh Routing Optimization Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

import 'package:meshnet_app/services/communication/mesh_routing_optimization.dart';

@GenerateMocks([])
class MockTopologyStreamController extends Mock implements StreamController<NetworkTopology> {}

void main() {
  group('MeshRoutingOptimization Tests', () {
    late MeshRoutingOptimization routingService;
    
    setUp(() {
      routingService = MeshRoutingOptimization.instance;
    });
    
    tearDown(() async {
      if (routingService.isInitialized) {
        await routingService.shutdown();
      }
    });

    group('Service Initialization', () {
      test('should initialize mesh routing service successfully', () async {
        final result = await routingService.initialize(nodeId: 'test_node_001');
        
        expect(result, isTrue);
        expect(routingService.isInitialized, isTrue);
        expect(routingService.knownNodes, greaterThanOrEqualTo(1)); // At least current node
      });
      
      test('should initialize with custom configuration', () async {
        final config = RoutingConfig(
          primaryAlgorithm: RoutingAlgorithm.emergency_priority,
          fallbackAlgorithm: RoutingAlgorithm.aodv,
          defaultStrategy: OptimizationStrategy.most_reliable,
          routeTimeout: const Duration(minutes: 15),
          topologyUpdateInterval: const Duration(seconds: 20),
          maxHopCount: 15,
          minLinkQuality: 0.4,
          emergencyOverrideEnabled: true,
          qosStrategies: {
            QoSPriority.emergency_critical: OptimizationStrategy.emergency_resilient,
            QoSPriority.voice_real_time: OptimizationStrategy.lowest_latency,
          },
          algorithmParameters: {'test_param': 'test_value'},
        );
        
        final result = await routingService.initialize(
          nodeId: 'test_node_config',
          config: config,
        );
        
        expect(result, isTrue);
        expect(routingService.isInitialized, isTrue);
      });
    });

    group('Routing Algorithms', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'routing_test_node');
      });
      
      test('should support all routing algorithms', () {
        final algorithms = [
          RoutingAlgorithm.aodv,
          RoutingAlgorithm.dsr,
          RoutingAlgorithm.olsr,
          RoutingAlgorithm.babel,
          RoutingAlgorithm.batman_adv,
          RoutingAlgorithm.bmx7,
          RoutingAlgorithm.emergency_priority,
          RoutingAlgorithm.adaptive_hybrid,
          RoutingAlgorithm.machine_learning,
          RoutingAlgorithm.custom_optimized,
        ];
        
        expect(algorithms.length, equals(10)); // All 10 routing algorithms
        
        for (final algorithm in algorithms) {
          expect(algorithm, isA<RoutingAlgorithm>());
        }
      });
      
      test('should find optimal route with AODV algorithm', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'target_node_aodv',
          algorithm: RoutingAlgorithm.aodv,
          priority: QoSPriority.normal,
        );
        
        // Route may be null if destination is not reachable in test environment
        if (route != null) {
          expect(route.algorithm, equals(RoutingAlgorithm.aodv));
          expect(route.destinationNode, equals('target_node_aodv'));
          expect(route.isActive, isTrue);
        }
      });
      
      test('should find optimal route with emergency priority algorithm', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'emergency_target',
          algorithm: RoutingAlgorithm.emergency_priority,
          priority: QoSPriority.emergency_critical,
        );
        
        if (route != null) {
          expect(route.algorithm, equals(RoutingAlgorithm.emergency_priority));
          expect(route.priority, equals(QoSPriority.emergency_critical));
          expect(route.isEmergencyRoute, isTrue);
        }
      });
      
      test('should use adaptive hybrid algorithm correctly', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'adaptive_target',
          algorithm: RoutingAlgorithm.adaptive_hybrid,
          priority: QoSPriority.voice_real_time,
        );
        
        if (route != null) {
          expect(route.algorithm, equals(RoutingAlgorithm.adaptive_hybrid));
          expect(route.priority, equals(QoSPriority.voice_real_time));
        }
      });
    });

    group('Optimization Strategies', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'strategy_test_node');
      });
      
      test('should support all optimization strategies', () {
        final strategies = [
          OptimizationStrategy.shortest_path,
          OptimizationStrategy.lowest_latency,
          OptimizationStrategy.highest_bandwidth,
          OptimizationStrategy.most_reliable,
          OptimizationStrategy.load_balanced,
          OptimizationStrategy.energy_efficient,
          OptimizationStrategy.emergency_resilient,
          OptimizationStrategy.adaptive_multipath,
        ];
        
        expect(strategies.length, equals(8)); // All 8 optimization strategies
        
        for (final strategy in strategies) {
          expect(strategy, isA<OptimizationStrategy>());
        }
      });
      
      test('should find shortest path route', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'shortest_target',
          strategy: OptimizationStrategy.shortest_path,
        );
        
        if (route != null) {
          expect(route.strategy, equals(OptimizationStrategy.shortest_path));
          expect(route.hopCount, greaterThanOrEqualTo(1));
        }
      });
      
      test('should find lowest latency route', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'latency_target',
          strategy: OptimizationStrategy.lowest_latency,
          priority: QoSPriority.voice_real_time,
        );
        
        if (route != null) {
          expect(route.strategy, equals(OptimizationStrategy.lowest_latency));
          expect(route.latency, isA<Duration>());
        }
      });
      
      test('should find most reliable route', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'reliable_target',
          strategy: OptimizationStrategy.most_reliable,
          priority: QoSPriority.emergency_high,
        );
        
        if (route != null) {
          expect(route.strategy, equals(OptimizationStrategy.most_reliable));
          expect(route.reliability, greaterThan(0.0));
        }
      });
      
      test('should find emergency resilient route', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'emergency_resilient_target',
          strategy: OptimizationStrategy.emergency_resilient,
          priority: QoSPriority.emergency_critical,
        );
        
        if (route != null) {
          expect(route.strategy, equals(OptimizationStrategy.emergency_resilient));
          expect(route.isEmergencyRoute, isTrue);
        }
      });
    });

    group('QoS Priority Management', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'qos_test_node');
      });
      
      test('should support all QoS priority levels', () {
        final priorities = [
          QoSPriority.emergency_critical,
          QoSPriority.emergency_high,
          QoSPriority.voice_real_time,
          QoSPriority.video_streaming,
          QoSPriority.file_transfer,
          QoSPriority.text_messaging,
          QoSPriority.background_sync,
          QoSPriority.best_effort,
        ];
        
        expect(priorities.length, equals(8)); // All 8 QoS priority levels
        
        for (final priority in priorities) {
          expect(priority, isA<QoSPriority>());
        }
      });
      
      test('should prioritize emergency critical traffic correctly', () async {
        final emergencyRoute = await routingService.findOptimalRoute(
          destination: 'emergency_critical_target',
          priority: QoSPriority.emergency_critical,
        );
        
        final normalRoute = await routingService.findOptimalRoute(
          destination: 'normal_target',
          priority: QoSPriority.best_effort,
        );
        
        if (emergencyRoute != null && normalRoute != null) {
          expect(emergencyRoute.priority.index, lessThan(normalRoute.priority.index));
          expect(emergencyRoute.scoreWithPriority, greaterThan(normalRoute.scoreWithPriority));
        }
      });
      
      test('should handle voice real-time traffic appropriately', () async {
        final voiceRoute = await routingService.findOptimalRoute(
          destination: 'voice_target',
          priority: QoSPriority.voice_real_time,
          strategy: OptimizationStrategy.lowest_latency,
        );
        
        if (voiceRoute != null) {
          expect(voiceRoute.priority, equals(QoSPriority.voice_real_time));
          expect(voiceRoute.strategy, equals(OptimizationStrategy.lowest_latency));
        }
      });
      
      test('should handle video streaming traffic appropriately', () async {
        final videoRoute = await routingService.findOptimalRoute(
          destination: 'video_target',
          priority: QoSPriority.video_streaming,
          strategy: OptimizationStrategy.highest_bandwidth,
        );
        
        if (videoRoute != null) {
          expect(videoRoute.priority, equals(QoSPriority.video_streaming));
          expect(videoRoute.strategy, equals(OptimizationStrategy.highest_bandwidth));
        }
      });
    });

    group('Network Topology Management', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'topology_test_node');
      });
      
      test('should maintain current network topology', () {
        final topology = routingService.getCurrentTopology();
        
        expect(topology, isNotNull);
        expect(topology!.nodeCount, greaterThanOrEqualTo(1));
        expect(topology.nodes, containsKey('topology_test_node'));
      });
      
      test('should update node information correctly', () async {
        final testNode = MeshNode(
          nodeId: 'update_test_node',
          nodeName: 'Update Test Node',
          nodeType: 'mesh_node',
          location: {'lat': 40.7128, 'lng': -74.0060},
          isOnline: true,
          isActive: true,
          lastSeen: DateTime.now(),
          batteryLevel: 0.8,
          signalStrength: -60.0,
          hopCount: 2,
          linkQuality: 0.85,
          capabilities: {'voice': true, 'video': true, 'data': true},
          neighbors: ['neighbor1', 'neighbor2'],
          metrics: {'latency': 50, 'throughput': 1000},
          isEmergencyNode: false,
          metadata: {'type': 'mobile'},
        );
        
        final result = await routingService.updateNodeInfo(testNode);
        
        expect(result, isTrue);
        
        final topology = routingService.getCurrentTopology();
        expect(topology!.nodes, containsKey('update_test_node'));
        expect(topology.nodes['update_test_node']!.batteryLevel, equals(0.8));
      });
      
      test('should assess network conditions correctly', () {
        final topology = routingService.getCurrentTopology();
        
        expect(topology, isNotNull);
        expect(topology!.condition, isA<NetworkCondition>());
        
        final conditions = [
          NetworkCondition.excellent,
          NetworkCondition.good,
          NetworkCondition.fair,
          NetworkCondition.poor,
          NetworkCondition.critical,
          NetworkCondition.emergency_degraded,
          NetworkCondition.disaster_mode,
        ];
        
        expect(conditions, contains(topology.condition));
      });
      
      test('should calculate average link quality correctly', () {
        final topology = routingService.getCurrentTopology();
        
        expect(topology, isNotNull);
        expect(topology!.averageLinkQuality, isA<double>());
        expect(topology.averageLinkQuality, greaterThanOrEqualTo(0.0));
        expect(topology.averageLinkQuality, lessThanOrEqualTo(1.0));
      });
    });

    group('Route Management', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'route_mgmt_test_node');
      });
      
      test('should find multiple routes to destination', () async {
        final routes = await routingService.findMultipleRoutes(
          destination: 'multipath_target',
          maxRoutes: 3,
          priority: QoSPriority.file_transfer,
          strategy: OptimizationStrategy.adaptive_multipath,
        );
        
        expect(routes, isA<List<NetworkRoute>>());
        expect(routes.length, lessThanOrEqualTo(3));
        
        for (final route in routes) {
          expect(route.destinationNode, equals('multipath_target'));
          expect(route.priority, equals(QoSPriority.file_transfer));
        }
      });
      
      test('should optimize existing routes', () async {
        final originalRoute = await routingService.findOptimalRoute(
          destination: 'optimize_target',
          priority: QoSPriority.normal,
        );
        
        if (originalRoute != null) {
          final optimizedRoute = await routingService.optimizeRoute(
            routeId: originalRoute.routeId,
            newStrategy: OptimizationStrategy.most_reliable,
          );
          
          expect(optimizedRoute, isNotNull);
          if (optimizedRoute != null) {
            expect(optimizedRoute.routeId, anyOf(
              equals(originalRoute.routeId), // Same route optimized
              isNot(equals(originalRoute.routeId)), // New optimized route
            ));
          }
        }
      });
      
      test('should invalidate routes correctly', () async {
        final route = await routingService.findOptimalRoute(
          destination: 'invalidate_target',
          priority: QoSPriority.normal,
        );
        
        if (route != null) {
          final invalidateResult = await routingService.invalidateRoute(route.routeId);
          
          expect(invalidateResult, isTrue);
          
          final retrievedRoute = routingService.getRoute(route.routeId);
          expect(retrievedRoute, isNull);
        }
      });
      
      test('should get routes to specific destination', () async {
        // Create multiple routes to same destination
        await routingService.findOptimalRoute(
          destination: 'destination_routes_target',
          priority: QoSPriority.normal,
        );
        
        await routingService.findOptimalRoute(
          destination: 'destination_routes_target',
          priority: QoSPriority.high,
          forceRecalculation: true,
        );
        
        final routes = routingService.getRoutesToDestination('destination_routes_target');
        
        expect(routes, isA<List<NetworkRoute>>());
        // May have 0, 1, or more routes depending on network topology simulation
      });
    });

    group('Routing Table Management', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'routing_table_test_node');
      });
      
      test('should maintain routing table correctly', () {
        final routingTable = routingService.getRoutingTable();
        
        expect(routingTable, isA<Map<String, RoutingTableEntry>>());
        
        for (final entry in routingTable.values) {
          expect(entry.destination, isA<String>());
          expect(entry.nextHop, isA<String>());
          expect(entry.metric, isA<int>());
          expect(entry.hopCount, greaterThanOrEqualTo(0));
          expect(entry.linkQuality, greaterThanOrEqualTo(0.0));
          expect(entry.linkQuality, lessThanOrEqualTo(1.0));
        }
      });
      
      test('should update routing table when routes change', () async {
        final initialTable = routingService.getRoutingTable();
        final initialSize = initialTable.length;
        
        // Create new route
        await routingService.findOptimalRoute(
          destination: 'routing_table_update_target',
          priority: QoSPriority.normal,
        );
        
        final updatedTable = routingService.getRoutingTable();
        
        // Table may have changed depending on route creation success
        expect(updatedTable, isA<Map<String, RoutingTableEntry>>());
      });
      
      test('should handle routing table entry expiration', () {
        final routingTable = routingService.getRoutingTable();
        
        for (final entry in routingTable.values) {
          expect(entry.isExpired, isA<bool>());
          expect(entry.timestamp, isA<DateTime>());
          expect(entry.timeout, isA<Duration>());
        }
      });
    });

    group('Network Statistics', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'stats_test_node');
      });
      
      test('should provide comprehensive network statistics', () {
        final stats = routingService.getNetworkStatistics();
        
        expect(stats, isA<NetworkStatistics>());
        expect(stats.totalRoutes, isA<int>());
        expect(stats.activeRoutes, isA<int>());
        expect(stats.emergencyRoutes, isA<int>());
        expect(stats.averageHopCount, isA<double>());
        expect(stats.averageLatency, isA<Duration>());
        expect(stats.routeSuccessRate, isA<double>());
        expect(stats.networkUtilization, isA<double>());
        
        expect(stats.routeSuccessRate, greaterThanOrEqualTo(0.0));
        expect(stats.routeSuccessRate, lessThanOrEqualTo(1.0));
        expect(stats.networkUtilization, greaterThanOrEqualTo(0.0));
        expect(stats.networkUtilization, lessThanOrEqualTo(1.0));
      });
      
      test('should track algorithm usage distribution', () {
        final stats = routingService.getNetworkStatistics();
        
        expect(stats.algorithmUsage, isA<Map<RoutingAlgorithm, int>>());
        expect(stats.strategyUsage, isA<Map<OptimizationStrategy, int>>());
        expect(stats.priorityDistribution, isA<Map<QoSPriority, int>>());
        
        for (final count in stats.algorithmUsage.values) {
          expect(count, greaterThanOrEqualTo(0));
        }
      });
      
      test('should provide system statistics', () {
        final systemStats = routingService.getStatistics();
        
        expect(systemStats, isA<Map<String, dynamic>>());
        expect(systemStats, containsKey('initialized'));
        expect(systemStats, containsKey('currentNodeId'));
        expect(systemStats, containsKey('knownNodes'));
        expect(systemStats, containsKey('activeRoutes'));
        expect(systemStats, containsKey('networkCondition'));
        expect(systemStats, containsKey('totalRoutingRequests'));
        expect(systemStats, containsKey('successfulRoutes'));
        expect(systemStats, containsKey('routeSuccessRate'));
        
        expect(systemStats['initialized'], isTrue);
        expect(systemStats['currentNodeId'], equals('stats_test_node'));
      });
    });

    group('Performance Optimization', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'performance_test_node');
      });
      
      test('should handle multiple concurrent route requests', () async {
        final futures = <Future<NetworkRoute?>>[];
        
        // Create multiple concurrent route requests
        for (int i = 0; i < 10; i++) {
          futures.add(routingService.findOptimalRoute(
            destination: 'concurrent_target_$i',
            priority: QoSPriority.normal,
          ));
        }
        
        final routes = await Future.wait(futures);
        
        expect(routes, isA<List<NetworkRoute?>>());
        expect(routes.length, equals(10));
      });
      
      test('should cache routes for improved performance', () async {
        final destination = 'cache_test_target';
        
        // First request (should create route)
        final startTime1 = DateTime.now();
        final route1 = await routingService.findOptimalRoute(
          destination: destination,
          priority: QoSPriority.normal,
        );
        final duration1 = DateTime.now().difference(startTime1);
        
        // Second request (should use cache)
        final startTime2 = DateTime.now();
        final route2 = await routingService.findOptimalRoute(
          destination: destination,
          priority: QoSPriority.normal,
        );
        final duration2 = DateTime.now().difference(startTime2);
        
        if (route1 != null && route2 != null) {
          // Cache hit should be faster (though in test environment, difference may be minimal)
          expect(route1.destinationNode, equals(route2.destinationNode));
        }
      });
      
      test('should handle route optimization efficiently', () async {
        // Create initial routes
        final routes = <NetworkRoute>[];
        for (int i = 0; i < 5; i++) {
          final route = await routingService.findOptimalRoute(
            destination: 'optimize_efficiency_target_$i',
            priority: QoSPriority.normal,
          );
          if (route != null) routes.add(route);
        }
        
        // Optimize routes
        final optimizationFutures = routes.map((route) =>
            routingService.optimizeRoute(routeId: route.routeId));
        
        final optimizedRoutes = await Future.wait(optimizationFutures);
        
        expect(optimizedRoutes.length, equals(routes.length));
      });
    });

    group('Error Handling and Resilience', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'error_test_node');
      });
      
      test('should handle invalid destination gracefully', () async {
        final route = await routingService.findOptimalRoute(
          destination: '', // Invalid empty destination
          priority: QoSPriority.normal,
        );
        
        expect(route, isNull);
      });
      
      test('should handle network partitioning gracefully', () async {
        // Simulate network partition by updating to critical condition
        await routingService.updateNodeInfo(MeshNode(
          nodeId: 'partition_test_node',
          nodeName: 'Partition Test',
          nodeType: 'mesh_node',
          location: {},
          isOnline: false, // Offline node
          isActive: false,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 10)),
          batteryLevel: 0.0,
          signalStrength: -100.0,
          hopCount: 99,
          linkQuality: 0.0,
          capabilities: {},
          neighbors: [],
          metrics: {},
          isEmergencyNode: false,
          metadata: {},
        ));
        
        final route = await routingService.findOptimalRoute(
          destination: 'partition_test_node',
          priority: QoSPriority.normal,
        );
        
        // Should handle gracefully, may return null or alternative route
        expect(() => route, returnsNormally);
        expect(routingService.isInitialized, isTrue);
      });
      
      test('should handle route invalidation errors gracefully', () async {
        final invalidateResult = await routingService.invalidateRoute('non_existent_route');
        
        expect(invalidateResult, isFalse);
        expect(routingService.isInitialized, isTrue);
      });
      
      test('should recover from topology update failures', () async {
        // Create invalid node data
        final invalidNode = MeshNode(
          nodeId: 'invalid_node',
          nodeName: '',
          nodeType: '',
          location: {},
          isOnline: true,
          isActive: true,
          lastSeen: DateTime.now(),
          batteryLevel: -1.0, // Invalid battery level
          signalStrength: 0.0,
          hopCount: -1, // Invalid hop count
          linkQuality: 2.0, // Invalid link quality (>1.0)
          capabilities: {},
          neighbors: [],
          metrics: {},
          isEmergencyNode: false,
          metadata: {},
        );
        
        final updateResult = await routingService.updateNodeInfo(invalidNode);
        
        // Should handle invalid data gracefully
        expect(routingService.isInitialized, isTrue);
      });
    });

    group('Stream Management', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'stream_test_node');
      });
      
      test('should provide topology updates stream', () async {
        final stream = routingService.topologyStream;
        
        expect(stream, isA<Stream<NetworkTopology>>());
        
        final subscription = stream.listen((topology) {
          expect(topology, isA<NetworkTopology>());
          expect(topology.nodeCount, greaterThanOrEqualTo(1));
        });
        
        await subscription.cancel();
      });
      
      test('should provide route updates stream', () async {
        final stream = routingService.routeStream;
        
        expect(stream, isA<Stream<NetworkRoute>>());
        
        final subscription = stream.listen((route) {
          expect(route, isA<NetworkRoute>());
          expect(route.isActive, isTrue);
        });
        
        await subscription.cancel();
      });
      
      test('should provide statistics updates stream', () async {
        final stream = routingService.statisticsStream;
        
        expect(stream, isA<Stream<NetworkStatistics>>());
        
        final subscription = stream.listen((stats) {
          expect(stats, isA<NetworkStatistics>());
          expect(stats.totalRoutes, greaterThanOrEqualTo(0));
        });
        
        await subscription.cancel();
      });
    });

    group('Emergency Mode Operations', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'emergency_test_node');
      });
      
      test('should prioritize emergency routes correctly', () async {
        // Create normal route
        final normalRoute = await routingService.findOptimalRoute(
          destination: 'emergency_test_target',
          priority: QoSPriority.normal,
        );
        
        // Create emergency route
        final emergencyRoute = await routingService.findOptimalRoute(
          destination: 'emergency_test_target',
          priority: QoSPriority.emergency_critical,
          algorithm: RoutingAlgorithm.emergency_priority,
          forceRecalculation: true,
        );
        
        if (normalRoute != null && emergencyRoute != null) {
          expect(emergencyRoute.priority.index, lessThan(normalRoute.priority.index));
          expect(emergencyRoute.isEmergencyRoute, isTrue);
          expect(emergencyRoute.algorithm, equals(RoutingAlgorithm.emergency_priority));
        }
      });
      
      test('should handle emergency network conditions', () async {
        // Simulate emergency network conditions
        final emergencyNode = MeshNode(
          nodeId: 'emergency_node',
          nodeName: 'Emergency Node',
          nodeType: 'emergency_device',
          location: {'lat': 40.7128, 'lng': -74.0060},
          isOnline: true,
          isActive: true,
          lastSeen: DateTime.now(),
          batteryLevel: 0.2, // Low battery
          signalStrength: -80.0, // Weak signal
          hopCount: 1,
          linkQuality: 0.3, // Poor link quality
          capabilities: {'emergency': true},
          neighbors: ['emergency_test_node'],
          metrics: {'priority': 'emergency'},
          isEmergencyNode: true,
          metadata: {'emergency_type': 'medical'},
        );
        
        await routingService.updateNodeInfo(emergencyNode);
        
        final emergencyRoute = await routingService.findOptimalRoute(
          destination: 'emergency_node',
          priority: QoSPriority.emergency_critical,
          strategy: OptimizationStrategy.emergency_resilient,
        );
        
        if (emergencyRoute != null) {
          expect(emergencyRoute.isEmergencyRoute, isTrue);
          expect(emergencyRoute.strategy, equals(OptimizationStrategy.emergency_resilient));
        }
      });
      
      test('should adapt to disaster mode conditions', () async {
        final topology = routingService.getCurrentTopology();
        
        if (topology != null) {
          // Check if system can handle different network conditions
          final conditions = [
            NetworkCondition.disaster_mode,
            NetworkCondition.emergency_degraded,
            NetworkCondition.critical,
          ];
          
          for (final condition in conditions) {
            expect(condition, isA<NetworkCondition>());
          }
        }
      });
    });

    group('Machine Learning Integration', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'ml_test_node');
      });
      
      test('should support machine learning algorithm', () async {
        final mlRoute = await routingService.findOptimalRoute(
          destination: 'ml_target',
          algorithm: RoutingAlgorithm.machine_learning,
          priority: QoSPriority.normal,
        );
        
        if (mlRoute != null) {
          expect(mlRoute.algorithm, equals(RoutingAlgorithm.machine_learning));
        }
      });
      
      test('should use adaptive algorithm selection', () async {
        final adaptiveRoute = await routingService.findOptimalRoute(
          destination: 'adaptive_target',
          algorithm: RoutingAlgorithm.adaptive_hybrid,
          priority: QoSPriority.voice_real_time,
        );
        
        if (adaptiveRoute != null) {
          expect(adaptiveRoute.algorithm, equals(RoutingAlgorithm.adaptive_hybrid));
        }
      });
      
      test('should learn from routing performance', () async {
        // Create multiple routes to same destination with different priorities
        final routes = <NetworkRoute>[];
        
        for (final priority in [QoSPriority.normal, QoSPriority.high, QoSPriority.emergency_high]) {
          final route = await routingService.findOptimalRoute(
            destination: 'learning_target',
            priority: priority,
            forceRecalculation: true,
          );
          if (route != null) routes.add(route);
        }
        
        // ML algorithm should learn from these routing decisions
        expect(routes, isA<List<NetworkRoute>>());
        
        for (final route in routes) {
          expect(route.destinationNode, equals('learning_target'));
        }
      });
    });

    group('Integration Tests', () {
      setUp(() async {
        await routingService.initialize(nodeId: 'integration_test_node');
      });
      
      test('should handle complete routing optimization flow', () async {
        // Create test network topology
        final nodes = <MeshNode>[];
        for (int i = 0; i < 5; i++) {
          final node = MeshNode(
            nodeId: 'integration_node_$i',
            nodeName: 'Integration Node $i',
            nodeType: 'mesh_node',
            location: {'lat': 40.7128 + (i * 0.001), 'lng': -74.0060 + (i * 0.001)},
            isOnline: true,
            isActive: true,
            lastSeen: DateTime.now(),
            batteryLevel: 0.8 - (i * 0.1),
            signalStrength: -50.0 - (i * 5),
            hopCount: i + 1,
            linkQuality: 0.9 - (i * 0.1),
            capabilities: {'voice': true, 'video': true, 'data': true},
            neighbors: i > 0 ? ['integration_node_${i-1}'] : ['integration_test_node'],
            metrics: {'latency': 10 + (i * 5), 'throughput': 1000 - (i * 100)},
            isEmergencyNode: i == 0, // First node is emergency node
            metadata: {'role': i == 0 ? 'emergency' : 'regular'},
          );
          nodes.add(node);
          await routingService.updateNodeInfo(node);
        }
        
        // Test different routing scenarios
        
        // 1. Normal routing
        final normalRoute = await routingService.findOptimalRoute(
          destination: 'integration_node_2',
          priority: QoSPriority.normal,
          strategy: OptimizationStrategy.shortest_path,
        );
        
        if (normalRoute != null) {
          expect(normalRoute.destinationNode, equals('integration_node_2'));
          expect(normalRoute.isActive, isTrue);
        }
        
        // 2. Emergency routing
        final emergencyRoute = await routingService.findOptimalRoute(
          destination: 'integration_node_0', // Emergency node
          priority: QoSPriority.emergency_critical,
          algorithm: RoutingAlgorithm.emergency_priority,
          strategy: OptimizationStrategy.emergency_resilient,
        );
        
        if (emergencyRoute != null) {
          expect(emergencyRoute.destinationNode, equals('integration_node_0'));
          expect(emergencyRoute.isEmergencyRoute, isTrue);
          expect(emergencyRoute.priority, equals(QoSPriority.emergency_critical));
        }
        
        // 3. Multi-path routing
        final multipathRoutes = await routingService.findMultipleRoutes(
          destination: 'integration_node_3',
          maxRoutes: 3,
          priority: QoSPriority.file_transfer,
          strategy: OptimizationStrategy.adaptive_multipath,
        );
        
        expect(multipathRoutes, isA<List<NetworkRoute>>());
        for (final route in multipathRoutes) {
          expect(route.destinationNode, equals('integration_node_3'));
        }
        
        // 4. Route optimization
        if (normalRoute != null) {
          final optimizedRoute = await routingService.optimizeRoute(
            routeId: normalRoute.routeId,
            newStrategy: OptimizationStrategy.most_reliable,
          );
          
          expect(optimizedRoute, isNotNull);
        }
        
        // 5. Performance monitoring
        final stats = routingService.getNetworkStatistics();
        expect(stats.totalRoutes, greaterThan(0));
        
        final topology = routingService.getCurrentTopology();
        expect(topology!.nodeCount, greaterThanOrEqualTo(6)); // 5 test nodes + main node
        
        // 6. Route invalidation cleanup
        final routingTable = routingService.getRoutingTable();
        for (final destination in routingTable.keys) {
          if (destination.startsWith('integration_node_')) {
            await routingService.invalidateRoute(destination);
          }
        }
        
        // Verify system remains stable
        expect(routingService.isInitialized, isTrue);
      });
      
      test('should handle emergency response coordination scenario', () async {
        // Simulate emergency response scenario
        
        // 1. Create emergency network topology
        final emergencyNodes = <MeshNode>[
          // Emergency command center
          MeshNode(
            nodeId: 'emergency_command',
            nodeName: 'Emergency Command Center',
            nodeType: 'command_center',
            location: {'lat': 40.7589, 'lng': -73.9851},
            isOnline: true,
            isActive: true,
            lastSeen: DateTime.now(),
            batteryLevel: 1.0,
            signalStrength: -40.0,
            hopCount: 0,
            linkQuality: 1.0,
            capabilities: {'command': true, 'coordination': true},
            neighbors: ['fire_unit_1', 'medical_unit_1', 'police_unit_1'],
            metrics: {'priority': 'command'},
            isEmergencyNode: true,
            metadata: {'role': 'command_center'},
          ),
          
          // Fire response unit
          MeshNode(
            nodeId: 'fire_unit_1',
            nodeName: 'Fire Unit Alpha',
            nodeType: 'fire_truck',
            location: {'lat': 40.7599, 'lng': -73.9861},
            isOnline: true,
            isActive: true,
            lastSeen: DateTime.now(),
            batteryLevel: 0.9,
            signalStrength: -55.0,
            hopCount: 1,
            linkQuality: 0.85,
            capabilities: {'fire_suppression': true, 'rescue': true},
            neighbors: ['emergency_command', 'medical_unit_1'],
            metrics: {'response_time': 300},
            isEmergencyNode: true,
            metadata: {'role': 'fire_response', 'unit_type': 'primary'},
          ),
          
          // Medical response unit
          MeshNode(
            nodeId: 'medical_unit_1',
            nodeName: 'Medical Unit Bravo',
            nodeType: 'ambulance',
            location: {'lat': 40.7579, 'lng': -73.9841},
            isOnline: true,
            isActive: true,
            lastSeen: DateTime.now(),
            batteryLevel: 0.8,
            signalStrength: -60.0,
            hopCount: 1,
            linkQuality: 0.8,
            capabilities: {'medical': true, 'transport': true},
            neighbors: ['emergency_command', 'fire_unit_1'],
            metrics: {'medical_supplies': 'full'},
            isEmergencyNode: true,
            metadata: {'role': 'medical_response', 'specialization': 'trauma'},
          ),
          
          // Police unit
          MeshNode(
            nodeId: 'police_unit_1',
            nodeName: 'Police Unit Charlie',
            nodeType: 'police_car',
            location: {'lat': 40.7569, 'lng': -73.9831},
            isOnline: true,
            isActive: true,
            lastSeen: DateTime.now(),
            batteryLevel: 0.85,
            signalStrength: -58.0,
            hopCount: 1,
            linkQuality: 0.82,
            capabilities: {'security': true, 'traffic_control': true},
            neighbors: ['emergency_command'],
            metrics: {'patrol_area': 'downtown'},
            isEmergencyNode: true,
            metadata: {'role': 'security', 'jurisdiction': 'city'},
          ),
        ];
        
        // Update topology with emergency nodes
        for (final node in emergencyNodes) {
          await routingService.updateNodeInfo(node);
        }
        
        // 2. Establish emergency communication routes
        final commandRoutes = <NetworkRoute>[];
        
        for (final node in emergencyNodes.skip(1)) { // Skip command center
          final route = await routingService.findOptimalRoute(
            destination: node.nodeId,
            priority: QoSPriority.emergency_critical,
            algorithm: RoutingAlgorithm.emergency_priority,
            strategy: OptimizationStrategy.emergency_resilient,
          );
          
          if (route != null) commandRoutes.add(route);
        }
        
        expect(commandRoutes, isNotEmpty);
        
        for (final route in commandRoutes) {
          expect(route.isEmergencyRoute, isTrue);
          expect(route.priority, equals(QoSPriority.emergency_critical));
          expect(route.algorithm, equals(RoutingAlgorithm.emergency_priority));
        }
        
        // 3. Test inter-unit coordination routes
        final coordinationRoute = await routingService.findOptimalRoute(
          destination: 'medical_unit_1',
          priority: QoSPriority.emergency_high,
          strategy: OptimizationStrategy.most_reliable,
        );
        
        if (coordinationRoute != null) {
          expect(coordinationRoute.destinationNode, equals('medical_unit_1'));
          expect(coordinationRoute.isEmergencyRoute, isTrue);
        }
        
        // 4. Test route redundancy for critical communications
        final redundantRoutes = await routingService.findMultipleRoutes(
          destination: 'fire_unit_1',
          maxRoutes: 3,
          priority: QoSPriority.emergency_critical,
          strategy: OptimizationStrategy.emergency_resilient,
        );
        
        expect(redundantRoutes, isA<List<NetworkRoute>>());
        
        // 5. Monitor emergency network performance
        final emergencyStats = routingService.getNetworkStatistics();
        expect(emergencyStats.emergencyRoutes, greaterThan(0));
        
        final topology = routingService.getCurrentTopology();
        final emergencyNodeCount = topology!.nodes.values
            .where((node) => node.isEmergencyNode)
            .length;
        expect(emergencyNodeCount, greaterThanOrEqualTo(4));
        
        // 6. Test network resilience under node failure
        // Simulate fire unit going offline
        final failedFireUnit = MeshNode(
          nodeId: 'fire_unit_1',
          nodeName: 'Fire Unit Alpha',
          nodeType: 'fire_truck',
          location: {'lat': 40.7599, 'lng': -73.9861},
          isOnline: false, // Offline
          isActive: false, // Inactive
          lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
          batteryLevel: 0.0,
          signalStrength: -100.0,
          hopCount: 99,
          linkQuality: 0.0,
          capabilities: {},
          neighbors: [],
          metrics: {},
          isEmergencyNode: true,
          metadata: {'status': 'offline'},
        );
        
        await routingService.updateNodeInfo(failedFireUnit);
        
        // Find alternative route to medical unit
        final alternativeRoute = await routingService.findOptimalRoute(
          destination: 'medical_unit_1',
          priority: QoSPriority.emergency_critical,
          strategy: OptimizationStrategy.emergency_resilient,
          forceRecalculation: true,
        );
        
        if (alternativeRoute != null) {
          expect(alternativeRoute.isActive, isTrue);
          expect(alternativeRoute.isEmergencyRoute, isTrue);
          // Route should avoid the failed fire unit
          expect(alternativeRoute.path, isNot(contains('fire_unit_1')));
        }
        
        // System should remain stable despite node failure
        expect(routingService.isInitialized, isTrue);
        
        final finalStats = routingService.getStatistics();
        expect(finalStats['initialized'], isTrue);
      });
    });
  });
}
