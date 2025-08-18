// lib/services/ai/emergency_router.dart - AI-Powered Emergency Router
import 'dart:async';
import 'dart:math';
import 'package:meshnet_app/services/ai/emergency_detection_engine.dart';
import 'package:meshnet_app/services/ai/smart_message_classifier.dart';
import 'package:meshnet_app/services/p2p/mesh_network_core.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Routing strategies for different emergency scenarios
enum RoutingStrategy {
  fastest_path,        // Minimize latency
  most_reliable,       // Maximize delivery probability
  broadcast_flood,     // Flood to all nodes
  priority_cascade,    // Route through priority nodes
  geographic_nearest,  // Route to geographically closest
  trust_based,        // Route through trusted nodes only
  adaptive_hybrid,    // AI decides best strategy
}

/// Emergency response node types
enum EmergencyNodeType {
  emergency_services,  // Police, fire, medical
  coordinator,         // Emergency coordinators
  responder,          // First responders
  medical_facility,   // Hospitals, clinics
  shelter,            // Emergency shelters
  resource_center,    // Supply centers
  communication_hub,  // Communication relays
  civilian,           // Regular civilians
  unknown,            // Unknown node type
}

/// Route quality metrics
class RouteQuality {
  final double reliability;    // 0.0 - 1.0
  final double speed;         // 0.0 - 1.0
  final double trustLevel;    // 0.0 - 1.0
  final double batteryLevel;  // 0.0 - 1.0
  final double signalStrength;// 0.0 - 1.0
  final int hopCount;
  final DateTime lastUpdated;

  RouteQuality({
    required this.reliability,
    required this.speed,
    required this.trustLevel,
    required this.batteryLevel,
    required this.signalStrength,
    required this.hopCount,
    required this.lastUpdated,
  });

  /// Calculate overall quality score
  double get overallScore {
    return (reliability * 0.3 + 
            speed * 0.2 + 
            trustLevel * 0.25 + 
            batteryLevel * 0.15 + 
            signalStrength * 0.1);
  }

  /// Check if route is viable
  bool get isViable {
    return reliability > 0.3 && 
           trustLevel > 0.2 && 
           batteryLevel > 0.1 &&
           hopCount < 10;
  }
}

/// Emergency routing decision
class RoutingDecision {
  final String decisionId;
  final String messageId;
  final List<String> routePath;
  final RoutingStrategy strategy;
  final EmergencyType emergencyType;
  final double confidence;
  final RouteQuality routeQuality;
  final DateTime timestamp;
  final Map<String, dynamic> reasoningData;
  final List<String> alternativeRoutes;
  final bool requiresAcknowledgment;

  RoutingDecision({
    required this.decisionId,
    required this.messageId,
    required this.routePath,
    required this.strategy,
    required this.emergencyType,
    required this.confidence,
    required this.routeQuality,
    required this.timestamp,
    required this.reasoningData,
    required this.alternativeRoutes,
    required this.requiresAcknowledgment,
  });

  factory RoutingDecision.create({
    required String messageId,
    required List<String> routePath,
    required RoutingStrategy strategy,
    required EmergencyType emergencyType,
    required double confidence,
    required RouteQuality routeQuality,
    Map<String, dynamic>? reasoningData,
    List<String>? alternativeRoutes,
    bool requiresAcknowledgment = false,
  }) {
    return RoutingDecision(
      decisionId: _generateDecisionId(),
      messageId: messageId,
      routePath: routePath,
      strategy: strategy,
      emergencyType: emergencyType,
      confidence: confidence,
      routeQuality: routeQuality,
      timestamp: DateTime.now(),
      reasoningData: reasoningData ?? {},
      alternativeRoutes: alternativeRoutes ?? [],
      requiresAcknowledgment: requiresAcknowledgment,
    );
  }

  static String _generateDecisionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'route_${timestamp}_$random';
  }

  Map<String, dynamic> toJson() {
    return {
      'decisionId': decisionId,
      'messageId': messageId,
      'routePath': routePath,
      'strategy': strategy.toString(),
      'emergencyType': emergencyType.toString(),
      'confidence': confidence,
      'routeQuality': {
        'reliability': routeQuality.reliability,
        'speed': routeQuality.speed,
        'trustLevel': routeQuality.trustLevel,
        'batteryLevel': routeQuality.batteryLevel,
        'signalStrength': routeQuality.signalStrength,
        'hopCount': routeQuality.hopCount,
        'overallScore': routeQuality.overallScore,
      },
      'timestamp': timestamp.toIso8601String(),
      'reasoningData': reasoningData,
      'alternativeRoutes': alternativeRoutes,
      'requiresAcknowledgment': requiresAcknowledgment,
    };
  }
}

/// Emergency node profile
class EmergencyNodeProfile {
  final String nodeId;
  final EmergencyNodeType nodeType;
  final List<String> capabilities;
  final Map<String, dynamic> location;
  final double trustScore;
  final double responseTime;
  final bool isActive;
  final DateTime lastSeen;
  final Map<String, dynamic> resources;
  final List<String> specializations;

  EmergencyNodeProfile({
    required this.nodeId,
    required this.nodeType,
    required this.capabilities,
    required this.location,
    required this.trustScore,
    required this.responseTime,
    required this.isActive,
    required this.lastSeen,
    required this.resources,
    required this.specializations,
  });

  /// Check if node can handle emergency type
  bool canHandle(EmergencyType emergencyType) {
    switch (emergencyType) {
      case EmergencyType.medical:
        return nodeType == EmergencyNodeType.medical_facility ||
               nodeType == EmergencyNodeType.emergency_services ||
               specializations.contains('medical');
      case EmergencyType.fire:
        return nodeType == EmergencyNodeType.emergency_services ||
               specializations.contains('fire');
      case EmergencyType.accident:
        return nodeType == EmergencyNodeType.emergency_services ||
               nodeType == EmergencyNodeType.responder;
      default:
        return nodeType != EmergencyNodeType.civilian;
    }
  }
}

/// AI-Powered Emergency Router
class EmergencyRouter {
  static EmergencyRouter? _instance;
  static EmergencyRouter get instance => _instance ??= EmergencyRouter._internal();
  
  EmergencyRouter._internal();

  final Logger _logger = Logger('EmergencyRouter');
  
  bool _isInitialized = false;
  Timer? _routeOptimizationTimer;
  
  // Node management
  final Map<String, EmergencyNodeProfile> _emergencyNodes = {};
  final Map<String, RouteQuality> _routeQualities = {};
  final List<RoutingDecision> _routingHistory = {};
  
  // AI routing parameters
  final Map<EmergencyType, double> _emergencyWeights = {};
  final Map<RoutingStrategy, double> _strategyWeights = {};
  
  // Performance metrics
  int _totalRoutingDecisions = 0;
  int _successfulDeliveries = 0;
  double _averageDeliveryTime = 0.0;
  
  // Streaming controller for routing decisions
  final StreamController<RoutingDecision> _routingController = 
      StreamController<RoutingDecision>.broadcast();

  bool get isInitialized => _isInitialized;
  Stream<RoutingDecision> get routingStream => _routingController.stream;
  List<RoutingDecision> get routingHistory => List.unmodifiable(_routingHistory);
  double get deliverySuccessRate => _totalRoutingDecisions > 0 ? _successfulDeliveries / _totalRoutingDecisions : 0.0;

  /// Initialize emergency router
  Future<bool> initialize() async {
    try {
      _logger.info('Initializing AI-powered emergency router...');
      
      // Load routing parameters
      await _loadEmergencyWeights();
      await _loadStrategyWeights();
      
      // Start route optimization timer
      _startRouteOptimizationTimer();
      
      _isInitialized = true;
      _logger.info('AI-powered emergency router initialized successfully');
      return true;
    } catch (e) {
      _logger.severe('Failed to initialize emergency router', e);
      return false;
    }
  }

  /// Shutdown emergency router
  Future<void> shutdown() async {
    _logger.info('Shutting down emergency router...');
    
    _routeOptimizationTimer?.cancel();
    await _routingController.close();
    
    _isInitialized = false;
    _logger.info('Emergency router shut down');
  }

  /// Route emergency message using AI decision making
  Future<RoutingDecision?> routeEmergencyMessage({
    required String messageId,
    required EmergencyDetectionResult emergencyData,
    required MessageClassificationResult classification,
    required List<MeshNode> availableNodes,
    Map<String, dynamic>? context,
    String? preferredDestination,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Emergency router not initialized');
      return null;
    }

    try {
      // Analyze emergency context
      final emergencyContext = await _analyzeEmergencyContext(
        emergencyData,
        classification,
        context,
      );
      
      // Select optimal routing strategy
      final strategy = await _selectRoutingStrategy(
        emergencyData.type,
        classification.priority,
        availableNodes,
        emergencyContext,
      );
      
      // Find best route path
      final routePath = await _findOptimalRoute(
        strategy,
        emergencyData.type,
        availableNodes,
        preferredDestination,
        emergencyContext,
      );
      
      if (routePath.isEmpty) {
        _logger.warning('No viable route found for emergency message: $messageId');
        return null;
      }
      
      // Calculate route quality
      final routeQuality = await _calculateRouteQuality(routePath, availableNodes);
      
      // Calculate routing confidence
      final confidence = await _calculateRoutingConfidence(
        strategy,
        routePath,
        routeQuality,
        emergencyContext,
      );
      
      // Find alternative routes
      final alternativeRoutes = await _findAlternativeRoutes(
        strategy,
        emergencyData.type,
        availableNodes,
        routePath,
        emergencyContext,
      );
      
      final decision = RoutingDecision.create(
        messageId: messageId,
        routePath: routePath,
        strategy: strategy,
        emergencyType: emergencyData.type,
        confidence: confidence,
        routeQuality: routeQuality,
        reasoningData: emergencyContext,
        alternativeRoutes: alternativeRoutes,
        requiresAcknowledgment: classification.requiresImmediateAction,
      );
      
      // Add to history and stream
      await _addToRoutingHistory(decision);
      _routingController.add(decision);
      
      _logger.info('Emergency route calculated: ${routePath.length} hops, strategy: $strategy, confidence: $confidence');
      return decision;
    } catch (e) {
      _logger.severe('Failed to route emergency message: $messageId', e);
      return null;
    }
  }

  /// Route coordination message between responders
  Future<RoutingDecision?> routeCoordinationMessage({
    required String messageId,
    required String sourceNodeId,
    required List<String> targetNodeIds,
    required MessagePriority priority,
    required List<MeshNode> availableNodes,
    Map<String, dynamic>? context,
  }) async {
    if (!_isInitialized) {
      _logger.warning('Emergency router not initialized');
      return null;
    }

    try {
      // Multi-destination routing for coordination
      final coordinationRoutes = <String>[];
      
      for (final targetId in targetNodeIds) {
        final route = await _findDirectRoute(sourceNodeId, targetId, availableNodes);
        if (route.isNotEmpty) {
          coordinationRoutes.addAll(route);
        }
      }
      
      if (coordinationRoutes.isEmpty) {
        _logger.warning('No coordination routes found for message: $messageId');
        return null;
      }
      
      final routeQuality = await _calculateRouteQuality(coordinationRoutes, availableNodes);
      
      final decision = RoutingDecision.create(
        messageId: messageId,
        routePath: coordinationRoutes,
        strategy: RoutingStrategy.trust_based,
        emergencyType: EmergencyType.coordination,
        confidence: 0.8,
        routeQuality: routeQuality,
        requiresAcknowledgment: priority == MessagePriority.critical,
      );
      
      await _addToRoutingHistory(decision);
      _routingController.add(decision);
      
      return decision;
    } catch (e) {
      _logger.severe('Failed to route coordination message: $messageId', e);
      return null;
    }
  }

  /// Update node profile with emergency capabilities
  Future<bool> updateEmergencyNode({
    required String nodeId,
    required EmergencyNodeType nodeType,
    List<String>? capabilities,
    Map<String, dynamic>? location,
    double? trustScore,
    Map<String, dynamic>? resources,
    List<String>? specializations,
  }) async {
    try {
      final existingProfile = _emergencyNodes[nodeId];
      
      _emergencyNodes[nodeId] = EmergencyNodeProfile(
        nodeId: nodeId,
        nodeType: nodeType,
        capabilities: capabilities ?? existingProfile?.capabilities ?? [],
        location: location ?? existingProfile?.location ?? {},
        trustScore: trustScore ?? existingProfile?.trustScore ?? 0.5,
        responseTime: existingProfile?.responseTime ?? 1.0,
        isActive: true,
        lastSeen: DateTime.now(),
        resources: resources ?? existingProfile?.resources ?? {},
        specializations: specializations ?? existingProfile?.specializations ?? [],
      );
      
      _logger.info('Emergency node profile updated: $nodeId ($nodeType)');
      return true;
    } catch (e) {
      _logger.severe('Failed to update emergency node: $nodeId', e);
      return false;
    }
  }

  /// Report routing success/failure for learning
  Future<void> reportRoutingResult({
    required String decisionId,
    required bool successful,
    double? deliveryTime,
    String? failureReason,
  }) async {
    try {
      final decision = _routingHistory.where((d) => d.decisionId == decisionId).lastOrNull;
      if (decision == null) return;
      
      _totalRoutingDecisions++;
      if (successful) {
        _successfulDeliveries++;
        
        if (deliveryTime != null) {
          _averageDeliveryTime = (_averageDeliveryTime + deliveryTime) / 2;
        }
        
        // Boost strategy weight for successful routing
        _strategyWeights[decision.strategy] = 
            (_strategyWeights[decision.strategy] ?? 1.0) * 1.02;
      } else {
        // Reduce strategy weight for failed routing
        _strategyWeights[decision.strategy] = 
            (_strategyWeights[decision.strategy] ?? 1.0) * 0.98;
        
        _logger.warning('Routing failed for decision: $decisionId, reason: $failureReason');
      }
      
      _logger.debug('Routing result reported: $decisionId, success: $successful');
    } catch (e) {
      _logger.severe('Failed to report routing result', e);
    }
  }

  /// Get routing statistics
  Map<String, dynamic> getRoutingStatistics() {
    final strategyDistribution = <RoutingStrategy, int>{};
    final emergencyTypeDistribution = <EmergencyType, int>{};
    
    for (final decision in _routingHistory) {
      strategyDistribution[decision.strategy] = (strategyDistribution[decision.strategy] ?? 0) + 1;
      emergencyTypeDistribution[decision.emergencyType] = (emergencyTypeDistribution[decision.emergencyType] ?? 0) + 1;
    }
    
    return {
      'initialized': _isInitialized,
      'totalDecisions': _totalRoutingDecisions,
      'successfulDeliveries': _successfulDeliveries,
      'deliverySuccessRate': deliverySuccessRate,
      'averageDeliveryTime': _averageDeliveryTime,
      'emergencyNodes': _emergencyNodes.length,
      'activeNodes': _emergencyNodes.values.where((n) => n.isActive).length,
      'strategyDistribution': strategyDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'emergencyTypeDistribution': emergencyTypeDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'routeQualities': _routeQualities.length,
    };
  }

  /// Analyze emergency context for routing decisions
  Future<Map<String, dynamic>> _analyzeEmergencyContext(
    EmergencyDetectionResult emergencyData,
    MessageClassificationResult classification,
    Map<String, dynamic>? context,
  ) async {
    final emergencyContext = <String, dynamic>{
      'emergency_severity': emergencyData.severity.toString(),
      'message_priority': classification.priority.toString(),
      'confidence_level': emergencyData.confidence.toString(),
      'requires_immediate_action': classification.requiresImmediateAction,
      'location_available': emergencyData.location.isNotEmpty,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Add location-based context
    if (emergencyData.location.isNotEmpty) {
      emergencyContext['location'] = emergencyData.location;
      emergencyContext['geographic_routing'] = true;
    }
    
    // Add emergency type specific context
    switch (emergencyData.type) {
      case EmergencyType.medical:
        emergencyContext['requires_medical_response'] = true;
        emergencyContext['priority_nodes'] = ['medical_facility', 'emergency_services'];
        break;
      case EmergencyType.fire:
        emergencyContext['requires_fire_response'] = true;
        emergencyContext['priority_nodes'] = ['emergency_services'];
        break;
      case EmergencyType.natural_disaster:
        emergencyContext['requires_coordination'] = true;
        emergencyContext['broadcast_recommended'] = true;
        break;
      default:
        break;
    }
    
    return emergencyContext;
  }

  /// Select optimal routing strategy based on emergency context
  Future<RoutingStrategy> _selectRoutingStrategy(
    EmergencyType emergencyType,
    MessagePriority priority,
    List<MeshNode> availableNodes,
    Map<String, dynamic> context,
  ) async {
    // Critical emergencies use fastest path
    if (priority == MessagePriority.critical) {
      return RoutingStrategy.fastest_path;
    }
    
    // Emergency type specific strategies
    switch (emergencyType) {
      case EmergencyType.medical:
      case EmergencyType.fire:
        return availableNodes.length > 5 
            ? RoutingStrategy.most_reliable 
            : RoutingStrategy.fastest_path;
      
      case EmergencyType.natural_disaster:
        return RoutingStrategy.broadcast_flood;
      
      case EmergencyType.coordination:
        return RoutingStrategy.trust_based;
      
      case EmergencyType.search_rescue:
        return RoutingStrategy.geographic_nearest;
      
      default:
        return RoutingStrategy.adaptive_hybrid;
    }
  }

  /// Find optimal route based on strategy
  Future<List<String>> _findOptimalRoute(
    RoutingStrategy strategy,
    EmergencyType emergencyType,
    List<MeshNode> availableNodes,
    String? preferredDestination,
    Map<String, dynamic> context,
  ) async {
    switch (strategy) {
      case RoutingStrategy.fastest_path:
        return await _findFastestPath(availableNodes, preferredDestination);
      
      case RoutingStrategy.most_reliable:
        return await _findMostReliablePath(availableNodes, preferredDestination);
      
      case RoutingStrategy.broadcast_flood:
        return await _createBroadcastPath(availableNodes);
      
      case RoutingStrategy.priority_cascade:
        return await _findPriorityCascadePath(emergencyType, availableNodes);
      
      case RoutingStrategy.geographic_nearest:
        return await _findGeographicNearestPath(availableNodes, context);
      
      case RoutingStrategy.trust_based:
        return await _findTrustBasedPath(availableNodes, preferredDestination);
      
      case RoutingStrategy.adaptive_hybrid:
        return await _findAdaptiveHybridPath(emergencyType, availableNodes, context);
    }
  }

  /// Find fastest path to destination
  Future<List<String>> _findFastestPath(
    List<MeshNode> availableNodes,
    String? preferredDestination,
  ) async {
    if (availableNodes.isEmpty) return [];
    
    // Simple implementation: direct path to highest signal strength node
    final sortedNodes = List<MeshNode>.from(availableNodes)
      ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
    
    return [sortedNodes.first.nodeId];
  }

  /// Find most reliable path
  Future<List<String>> _findMostReliablePath(
    List<MeshNode> availableNodes,
    String? preferredDestination,
  ) async {
    if (availableNodes.isEmpty) return [];
    
    // Select nodes with highest trust scores and good signal
    final reliableNodes = availableNodes
        .where((node) => node.trustScore > 0.5 && node.signalStrength > 0.3)
        .toList()
      ..sort((a, b) => (b.trustScore * b.signalStrength).compareTo(a.trustScore * a.signalStrength));
    
    return reliableNodes.isNotEmpty 
        ? [reliableNodes.first.nodeId]
        : [availableNodes.first.nodeId];
  }

  /// Create broadcast path to all nodes
  Future<List<String>> _createBroadcastPath(List<MeshNode> availableNodes) async {
    return availableNodes.map((node) => node.nodeId).toList();
  }

  /// Find priority cascade path based on emergency type
  Future<List<String>> _findPriorityCascadePath(
    EmergencyType emergencyType,
    List<MeshNode> availableNodes,
  ) async {
    final priorityNodes = <String>[];
    
    // Find emergency-capable nodes first
    for (final node in availableNodes) {
      final profile = _emergencyNodes[node.nodeId];
      if (profile != null && profile.canHandle(emergencyType)) {
        priorityNodes.add(node.nodeId);
      }
    }
    
    // Add trusted nodes as backup
    if (priorityNodes.length < 3) {
      final trustedNodes = availableNodes
          .where((node) => node.trustScore > 0.7)
          .map((node) => node.nodeId)
          .toList();
      
      priorityNodes.addAll(trustedNodes.take(3 - priorityNodes.length));
    }
    
    return priorityNodes.isNotEmpty ? priorityNodes : [availableNodes.first.nodeId];
  }

  /// Find geographically nearest nodes
  Future<List<String>> _findGeographicNearestPath(
    List<MeshNode> availableNodes,
    Map<String, dynamic> context,
  ) async {
    // Simplified geographic routing (in real implementation, use actual coordinates)
    if (!context.containsKey('location')) {
      return await _findFastestPath(availableNodes, null);
    }
    
    // Sort by proximity (mock implementation)
    final proximityNodes = List<MeshNode>.from(availableNodes)
      ..sort((a, b) => a.nodeId.compareTo(b.nodeId)); // Mock proximity sort
    
    return proximityNodes.take(3).map((node) => node.nodeId).toList();
  }

  /// Find trust-based routing path
  Future<List<String>> _findTrustBasedPath(
    List<MeshNode> availableNodes,
    String? preferredDestination,
  ) async {
    final trustedNodes = availableNodes
        .where((node) => node.trustScore > 0.6)
        .toList()
      ..sort((a, b) => b.trustScore.compareTo(a.trustScore));
    
    return trustedNodes.isNotEmpty 
        ? trustedNodes.take(2).map((node) => node.nodeId).toList()
        : [availableNodes.first.nodeId];
  }

  /// Find adaptive hybrid path using AI decision
  Future<List<String>> _findAdaptiveHybridPath(
    EmergencyType emergencyType,
    List<MeshNode> availableNodes,
    Map<String, dynamic> context,
  ) async {
    // Weighted combination of multiple strategies
    final candidates = <String, double>{};
    
    // Get candidates from different strategies
    final fastPath = await _findFastestPath(availableNodes, null);
    final reliablePath = await _findMostReliablePath(availableNodes, null);
    final trustPath = await _findTrustBasedPath(availableNodes, null);
    
    // Weight the candidates
    for (final nodeId in fastPath) {
      candidates[nodeId] = (candidates[nodeId] ?? 0.0) + 0.4;
    }
    
    for (final nodeId in reliablePath) {
      candidates[nodeId] = (candidates[nodeId] ?? 0.0) + 0.4;
    }
    
    for (final nodeId in trustPath) {
      candidates[nodeId] = (candidates[nodeId] ?? 0.0) + 0.2;
    }
    
    // Sort by weighted score
    final sortedCandidates = candidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCandidates.take(2).map((entry) => entry.key).toList();
  }

  /// Find direct route between two nodes
  Future<List<String>> _findDirectRoute(
    String sourceId,
    String targetId,
    List<MeshNode> availableNodes,
  ) async {
    final targetNode = availableNodes.where((node) => node.nodeId == targetId).lastOrNull;
    return targetNode != null ? [targetId] : [];
  }

  /// Calculate route quality metrics
  Future<RouteQuality> _calculateRouteQuality(
    List<String> routePath,
    List<MeshNode> availableNodes,
  ) async {
    if (routePath.isEmpty) {
      return RouteQuality(
        reliability: 0.0,
        speed: 0.0,
        trustLevel: 0.0,
        batteryLevel: 0.0,
        signalStrength: 0.0,
        hopCount: 0,
        lastUpdated: DateTime.now(),
      );
    }
    
    double totalReliability = 0.0;
    double totalSpeed = 0.0;
    double totalTrust = 0.0;
    double totalBattery = 0.0;
    double totalSignal = 0.0;
    
    for (final nodeId in routePath) {
      final node = availableNodes.where((n) => n.nodeId == nodeId).lastOrNull;
      if (node != null) {
        totalReliability += node.trustScore * node.signalStrength;
        totalSpeed += node.signalStrength;
        totalTrust += node.trustScore;
        totalBattery += node.batteryLevel;
        totalSignal += node.signalStrength;
      }
    }
    
    final pathLength = routePath.length;
    
    return RouteQuality(
      reliability: pathLength > 0 ? totalReliability / pathLength : 0.0,
      speed: pathLength > 0 ? totalSpeed / pathLength : 0.0,
      trustLevel: pathLength > 0 ? totalTrust / pathLength : 0.0,
      batteryLevel: pathLength > 0 ? totalBattery / pathLength : 0.0,
      signalStrength: pathLength > 0 ? totalSignal / pathLength : 0.0,
      hopCount: pathLength,
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculate routing confidence
  Future<double> _calculateRoutingConfidence(
    RoutingStrategy strategy,
    List<String> routePath,
    RouteQuality routeQuality,
    Map<String, dynamic> context,
  ) async {
    double confidence = 0.5; // Base confidence
    
    // Route quality impact
    confidence += routeQuality.overallScore * 0.3;
    
    // Strategy confidence
    confidence += (_strategyWeights[strategy] ?? 1.0) * 0.1;
    
    // Path length impact (shorter is better for most cases)
    if (routePath.length <= 2) {
      confidence += 0.2;
    } else if (routePath.length > 5) {
      confidence -= 0.1;
    }
    
    // Context-based adjustments
    if (context['requires_immediate_action'] == true && strategy == RoutingStrategy.fastest_path) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Find alternative routes for redundancy
  Future<List<String>> _findAlternativeRoutes(
    RoutingStrategy primaryStrategy,
    EmergencyType emergencyType,
    List<MeshNode> availableNodes,
    List<String> primaryRoute,
    Map<String, dynamic> context,
  ) async {
    final alternatives = <String>[];
    
    // Try different strategy for alternative
    RoutingStrategy altStrategy;
    switch (primaryStrategy) {
      case RoutingStrategy.fastest_path:
        altStrategy = RoutingStrategy.most_reliable;
        break;
      case RoutingStrategy.most_reliable:
        altStrategy = RoutingStrategy.trust_based;
        break;
      default:
        altStrategy = RoutingStrategy.fastest_path;
    }
    
    final altRoute = await _findOptimalRoute(
      altStrategy,
      emergencyType,
      availableNodes,
      null,
      context,
    );
    
    // Only include if different from primary
    for (final nodeId in altRoute) {
      if (!primaryRoute.contains(nodeId)) {
        alternatives.add(nodeId);
      }
    }
    
    return alternatives;
  }

  /// Load emergency type weights
  Future<void> _loadEmergencyWeights() async {
    _emergencyWeights.clear();
    
    _emergencyWeights[EmergencyType.medical] = 1.0;
    _emergencyWeights[EmergencyType.fire] = 1.2;
    _emergencyWeights[EmergencyType.accident] = 1.1;
    _emergencyWeights[EmergencyType.natural_disaster] = 1.3;
    _emergencyWeights[EmergencyType.security_threat] = 1.2;
    _emergencyWeights[EmergencyType.search_rescue] = 0.9;
    _emergencyWeights[EmergencyType.chemical_hazard] = 1.3;
    _emergencyWeights[EmergencyType.infrastructure_failure] = 0.8;
    
    _logger.debug('Emergency weights loaded');
  }

  /// Load routing strategy weights
  Future<void> _loadStrategyWeights() async {
    _strategyWeights.clear();
    
    _strategyWeights[RoutingStrategy.fastest_path] = 1.2;
    _strategyWeights[RoutingStrategy.most_reliable] = 1.1;
    _strategyWeights[RoutingStrategy.broadcast_flood] = 0.9;
    _strategyWeights[RoutingStrategy.priority_cascade] = 1.0;
    _strategyWeights[RoutingStrategy.geographic_nearest] = 1.0;
    _strategyWeights[RoutingStrategy.trust_based] = 1.1;
    _strategyWeights[RoutingStrategy.adaptive_hybrid] = 1.3;
    
    _logger.debug('Strategy weights loaded');
  }

  /// Add routing decision to history
  Future<void> _addToRoutingHistory(RoutingDecision decision) async {
    _routingHistory.add(decision);
    
    // Keep only last 500 decisions
    if (_routingHistory.length > 500) {
      _routingHistory.removeAt(0);
    }
  }

  /// Start route optimization timer
  void _startRouteOptimizationTimer() {
    _routeOptimizationTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      await _performRouteOptimization();
    });
  }

  /// Perform periodic route optimization
  Future<void> _performRouteOptimization() async {
    if (_routingHistory.length < 20) return;
    
    try {
      // Analyze recent routing performance
      final recentDecisions = _routingHistory.skip(max(0, _routingHistory.length - 100));
      
      // Update strategy weights based on success patterns
      final strategyPerformance = <RoutingStrategy, double>{};
      for (final decision in recentDecisions) {
        if (decision.routeQuality.overallScore > 0.7) {
          strategyPerformance[decision.strategy] = 
              (strategyPerformance[decision.strategy] ?? 0.0) + 1.0;
        }
      }
      
      // Adjust weights for well-performing strategies
      for (final entry in strategyPerformance.entries) {
        if (entry.value > 5) {
          _strategyWeights[entry.key] = 
              (_strategyWeights[entry.key] ?? 1.0) * 1.01;
        }
      }
      
      _logger.debug('Route optimization completed');
    } catch (e) {
      _logger.warning('Route optimization failed', e);
    }
  }
}
