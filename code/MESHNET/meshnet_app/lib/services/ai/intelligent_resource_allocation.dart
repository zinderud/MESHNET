// lib/services/ai/intelligent_resource_allocation.dart - Intelligent Resource Allocation
import 'dart:async';
import 'dart:math';
import 'dart:collection';

/// Resource types in the mesh network
enum ResourceType {
  bandwidth,
  processing_power,
  memory,
  storage,
  battery,
  connection_slots,
  encryption_capacity,
  routing_priority,
}

/// Allocation strategies
enum AllocationStrategy {
  priority_based,
  fair_share,
  emergency_first,
  load_balanced,
  predictive,
  adaptive,
}

/// Resource priority levels
enum ResourcePriority {
  critical(10),
  emergency(9),
  high(8),
  medium_high(7),
  medium(6),
  medium_low(5),
  low(4),
  very_low(3),
  background(2),
  idle(1);

  const ResourcePriority(this.value);
  final int value;
}

/// Resource request
class ResourceRequest {
  final String id;
  final String requesterId;
  final ResourceType resourceType;
  final double amount;
  final ResourcePriority priority;
  final Duration duration;
  final DateTime requestTime;
  final DateTime? deadline;
  final bool isEmergency;
  final Map<String, dynamic> metadata;

  ResourceRequest({
    required this.id,
    required this.requesterId,
    required this.resourceType,
    required this.amount,
    required this.priority,
    required this.duration,
    required this.requestTime,
    this.deadline,
    this.isEmergency = false,
    this.metadata = const {},
  });

  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);
  bool get isUrgent => deadline != null && 
      DateTime.now().add(const Duration(minutes: 5)).isAfter(deadline!);

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterId': requesterId,
    'resourceType': resourceType.toString(),
    'amount': amount,
    'priority': priority.toString(),
    'duration': duration.inMilliseconds,
    'requestTime': requestTime.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'isEmergency': isEmergency,
    'metadata': metadata,
  };
}

/// Resource allocation
class ResourceAllocation {
  final String id;
  final ResourceRequest request;
  final double allocatedAmount;
  final DateTime allocationTime;
  final DateTime expirationTime;
  final String nodeId;
  final AllocationStrategy strategy;
  final bool isActive;
  final Map<String, dynamic> allocationData;

  ResourceAllocation({
    required this.id,
    required this.request,
    required this.allocatedAmount,
    required this.allocationTime,
    required this.expirationTime,
    required this.nodeId,
    required this.strategy,
    this.isActive = true,
    this.allocationData = const {},
  });

  bool get isExpired => DateTime.now().isAfter(expirationTime);
  double get utilizationRatio => allocatedAmount / request.amount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': request.toJson(),
    'allocatedAmount': allocatedAmount,
    'allocationTime': allocationTime.toIso8601String(),
    'expirationTime': expirationTime.toIso8601String(),
    'nodeId': nodeId,
    'strategy': strategy.toString(),
    'isActive': isActive,
    'allocationData': allocationData,
  };
}

/// Node resource capacity
class NodeResourceCapacity {
  final String nodeId;
  final Map<ResourceType, double> totalCapacity;
  final Map<ResourceType, double> availableCapacity;
  final Map<ResourceType, double> allocatedCapacity;
  final DateTime lastUpdate;
  final double batteryLevel;
  final double processingLoad;
  final bool isEmergencyMode;

  NodeResourceCapacity({
    required this.nodeId,
    required this.totalCapacity,
    required this.availableCapacity,
    required this.allocatedCapacity,
    required this.lastUpdate,
    this.batteryLevel = 1.0,
    this.processingLoad = 0.0,
    this.isEmergencyMode = false,
  });

  double getUtilization(ResourceType type) {
    final total = totalCapacity[type] ?? 0.0;
    final allocated = allocatedCapacity[type] ?? 0.0;
    return total > 0 ? allocated / total : 0.0;
  }

  bool canAllocate(ResourceType type, double amount) {
    final available = availableCapacity[type] ?? 0.0;
    return available >= amount;
  }

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'totalCapacity': totalCapacity.map((k, v) => MapEntry(k.toString(), v)),
    'availableCapacity': availableCapacity.map((k, v) => MapEntry(k.toString(), v)),
    'allocatedCapacity': allocatedCapacity.map((k, v) => MapEntry(k.toString(), v)),
    'lastUpdate': lastUpdate.toIso8601String(),
    'batteryLevel': batteryLevel,
    'processingLoad': processingLoad,
    'isEmergencyMode': isEmergencyMode,
  };
}

/// Resource usage statistics
class ResourceUsageStats {
  final ResourceType resourceType;
  final double totalRequested;
  final double totalAllocated;
  final double totalUsed;
  final double averageWaitTime;
  final double allocationSuccessRate;
  final int totalRequests;
  final int successfulAllocations;
  final DateTime periodStart;
  final DateTime periodEnd;

  ResourceUsageStats({
    required this.resourceType,
    required this.totalRequested,
    required this.totalAllocated,
    required this.totalUsed,
    required this.averageWaitTime,
    required this.allocationSuccessRate,
    required this.totalRequests,
    required this.successfulAllocations,
    required this.periodStart,
    required this.periodEnd,
  });

  double get utilizationEfficiency => totalAllocated > 0 ? totalUsed / totalAllocated : 0.0;
  double get wastageRate => totalAllocated > 0 ? (totalAllocated - totalUsed) / totalAllocated : 0.0;

  Map<String, dynamic> toJson() => {
    'resourceType': resourceType.toString(),
    'totalRequested': totalRequested,
    'totalAllocated': totalAllocated,
    'totalUsed': totalUsed,
    'averageWaitTime': averageWaitTime,
    'allocationSuccessRate': allocationSuccessRate,
    'totalRequests': totalRequests,
    'successfulAllocations': successfulAllocations,
    'utilizationEfficiency': utilizationEfficiency,
    'wastageRate': wastageRate,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
  };
}

/// Intelligent Resource Allocation Service
class IntelligentResourceAllocation {
  static final IntelligentResourceAllocation _instance = 
      IntelligentResourceAllocation._internal();
  static IntelligentResourceAllocation get instance => _instance;
  IntelligentResourceAllocation._internal();

  // Service state
  bool _isInitialized = false;
  bool _isOptimizing = false;
  AllocationStrategy _defaultStrategy = AllocationStrategy.priority_based;

  // Data storage
  final Queue<ResourceRequest> _pendingRequests = Queue<ResourceRequest>();
  final Map<String, ResourceAllocation> _activeAllocations = {};
  final Map<String, NodeResourceCapacity> _nodeCapacities = {};
  final List<ResourceAllocation> _allocationHistory = [];
  final Map<ResourceType, ResourceUsageStats> _usageStats = {};

  // Configuration
  final int _maxPendingRequests = 1000;
  final int _maxHistorySize = 5000;
  final Duration _defaultAllocationTimeout = const Duration(minutes: 30);
  final Map<ResourcePriority, double> _priorityWeights = {};

  // Stream controllers
  final StreamController<ResourceRequest> _requestController = 
      StreamController.broadcast();
  final StreamController<ResourceAllocation> _allocationController = 
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _statsController = 
      StreamController.broadcast();

  // Properties
  bool get isInitialized => _isInitialized;
  bool get isOptimizing => _isOptimizing;
  int get pendingRequestsCount => _pendingRequests.length;
  int get activeAllocationsCount => _activeAllocations.length;
  int get registeredNodesCount => _nodeCapacities.length;
  
  // Streams
  Stream<ResourceRequest> get requestStream => _requestController.stream;
  Stream<ResourceAllocation> get allocationStream => _allocationController.stream;
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  /// Initialize the intelligent resource allocation service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize priority weights
      _initializePriorityWeights();
      
      // Start background optimization
      _startOptimizationLoop();
      
      // Start cleanup timer
      _startCleanupTimer();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Register a node with its resource capacity
  Future<bool> registerNode(NodeResourceCapacity capacity) async {
    if (!_isInitialized) return false;

    _nodeCapacities[capacity.nodeId] = capacity;
    await _processOptimization();
    return true;
  }

  /// Update node resource capacity
  Future<bool> updateNodeCapacity(String nodeId, Map<ResourceType, double> newCapacity) async {
    if (!_isInitialized || !_nodeCapacities.containsKey(nodeId)) return false;

    final currentCapacity = _nodeCapacities[nodeId]!;
    final updatedCapacity = NodeResourceCapacity(
      nodeId: nodeId,
      totalCapacity: newCapacity,
      availableCapacity: Map.from(newCapacity),
      allocatedCapacity: Map.from(currentCapacity.allocatedCapacity),
      lastUpdate: DateTime.now(),
      batteryLevel: currentCapacity.batteryLevel,
      processingLoad: currentCapacity.processingLoad,
      isEmergencyMode: currentCapacity.isEmergencyMode,
    );

    // Recalculate available capacity
    for (final type in ResourceType.values) {
      final total = newCapacity[type] ?? 0.0;
      final allocated = currentCapacity.allocatedCapacity[type] ?? 0.0;
      updatedCapacity.availableCapacity[type] = max(0.0, total - allocated);
    }

    _nodeCapacities[nodeId] = updatedCapacity;
    await _processOptimization();
    return true;
  }

  /// Request resource allocation
  Future<String?> requestResource(ResourceRequest request) async {
    if (!_isInitialized) return null;

    // Validate request
    if (request.amount <= 0) return null;

    // Add to pending requests
    _pendingRequests.addLast(request);
    if (_pendingRequests.length > _maxPendingRequests) {
      _pendingRequests.removeFirst();
    }

    _requestController.add(request);

    // Try immediate allocation for emergency requests
    if (request.isEmergency || request.priority.value >= ResourcePriority.emergency.value) {
      final allocation = await _tryImmediateAllocation(request);
      if (allocation != null) {
        return allocation.id;
      }
    }

    // Queue for batch processing
    await _processOptimization();
    return request.id;
  }

  /// Get allocation status
  ResourceAllocation? getAllocation(String allocationId) {
    return _activeAllocations[allocationId];
  }

  /// Get all allocations for a requester
  List<ResourceAllocation> getAllocationsForRequester(String requesterId) {
    return _activeAllocations.values
        .where((allocation) => allocation.request.requesterId == requesterId)
        .toList();
  }

  /// Release resource allocation
  Future<bool> releaseAllocation(String allocationId) async {
    if (!_isInitialized || !_activeAllocations.containsKey(allocationId)) {
      return false;
    }

    final allocation = _activeAllocations[allocationId]!;
    await _releaseAllocation(allocation);
    return true;
  }

  /// Set allocation strategy
  void setAllocationStrategy(AllocationStrategy strategy) {
    _defaultStrategy = strategy;
  }

  /// Get resource usage statistics
  Map<ResourceType, ResourceUsageStats> getUsageStatistics() {
    return Map.from(_usageStats);
  }

  /// Get node utilization report
  Map<String, double> getNodeUtilization() {
    final utilization = <String, double>{};
    
    for (final capacity in _nodeCapacities.values) {
      double totalUtilization = 0.0;
      int resourceCount = 0;
      
      for (final type in ResourceType.values) {
        final util = capacity.getUtilization(type);
        if (util > 0) {
          totalUtilization += util;
          resourceCount++;
        }
      }
      
      utilization[capacity.nodeId] = resourceCount > 0 ? totalUtilization / resourceCount : 0.0;
    }
    
    return utilization;
  }

  /// Get optimization recommendations
  List<Map<String, dynamic>> getOptimizationRecommendations() {
    final recommendations = <Map<String, dynamic>>[];
    
    // Analyze resource distribution
    for (final type in ResourceType.values) {
      final stats = _analyzeResourceDistribution(type);
      final imbalance = stats['imbalance'] as double? ?? 0.0;
      if (imbalance > 0.3) {
        recommendations.add({
          'type': 'load_balancing',
          'resourceType': type.toString(),
          'description': 'Resource ${type.toString()} is unevenly distributed',
          'severity': imbalance,
          'recommendation': 'Consider redistributing workload',
        });
      }
    }
    
    // Analyze pending requests
    if (_pendingRequests.length > _maxPendingRequests * 0.8) {
      recommendations.add({
        'type': 'capacity_expansion',
        'description': 'High number of pending requests',
        'severity': _pendingRequests.length / _maxPendingRequests,
        'recommendation': 'Add more nodes or increase capacity',
      });
    }
    
    return recommendations;
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final now = DateTime.now();
    final recentAllocations = _allocationHistory.where(
      (allocation) => now.difference(allocation.allocationTime).inHours < 24
    ).toList();

    return {
      'totalNodes': _nodeCapacities.length,
      'activeAllocations': _activeAllocations.length,
      'pendingRequests': _pendingRequests.length,
      'recentAllocations': recentAllocations.length,
      'averageAllocationTime': _calculateAverageAllocationTime(recentAllocations),
      'allocationSuccessRate': _calculateSuccessRate(recentAllocations),
      'resourceUtilization': _calculateOverallUtilization(),
      'isOptimizing': _isOptimizing,
    };
  }

  /// Shutdown the service
  Future<void> shutdown() async {
    _isInitialized = false;
    _isOptimizing = false;
    
    // Release all active allocations
    for (final allocation in _activeAllocations.values.toList()) {
      await _releaseAllocation(allocation);
    }
    
    await _requestController.close();
    await _allocationController.close();
    await _statsController.close();
    
    _pendingRequests.clear();
    _activeAllocations.clear();
    _nodeCapacities.clear();
    _allocationHistory.clear();
    _usageStats.clear();
  }

  // Private methods

  void _initializePriorityWeights() {
    _priorityWeights[ResourcePriority.critical] = 1.0;
    _priorityWeights[ResourcePriority.emergency] = 0.9;
    _priorityWeights[ResourcePriority.high] = 0.8;
    _priorityWeights[ResourcePriority.medium_high] = 0.7;
    _priorityWeights[ResourcePriority.medium] = 0.6;
    _priorityWeights[ResourcePriority.medium_low] = 0.5;
    _priorityWeights[ResourcePriority.low] = 0.4;
    _priorityWeights[ResourcePriority.very_low] = 0.3;
    _priorityWeights[ResourcePriority.background] = 0.2;
    _priorityWeights[ResourcePriority.idle] = 0.1;
  }

  void _startOptimizationLoop() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOptimizing && _pendingRequests.isNotEmpty) {
        _processOptimization();
      }
    });
    _isOptimizing = true;
  }

  void _startCleanupTimer() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupExpiredAllocations();
    });
  }

  Future<void> _processOptimization() async {
    if (!_isOptimizing || _pendingRequests.isEmpty) return;

    final requestsToProcess = _pendingRequests.toList();
    _pendingRequests.clear();

    // Sort requests by priority and urgency
    requestsToProcess.sort((a, b) {
      if (a.isEmergency != b.isEmergency) {
        return a.isEmergency ? -1 : 1;
      }
      return b.priority.value.compareTo(a.priority.value);
    });

    for (final request in requestsToProcess) {
      if (request.isExpired) continue;
      
      final allocation = await _allocateResource(request);
      if (allocation == null) {
        // Re-queue if allocation failed and not expired
        if (!request.isExpired) {
          _pendingRequests.addLast(request);
        }
      }
    }

    // Update statistics
    await _updateUsageStatistics();
  }

  Future<ResourceAllocation?> _tryImmediateAllocation(ResourceRequest request) async {
    return await _allocateResource(request);
  }

  Future<ResourceAllocation?> _allocateResource(ResourceRequest request) async {
    final candidateNodes = _findCandidateNodes(request);
    if (candidateNodes.isEmpty) return null;

    final selectedNode = _selectBestNode(candidateNodes, request);
    if (selectedNode == null) return null;

    final allocation = ResourceAllocation(
      id: 'alloc_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
      request: request,
      allocatedAmount: request.amount,
      allocationTime: DateTime.now(),
      expirationTime: DateTime.now().add(request.duration),
      nodeId: selectedNode.nodeId,
      strategy: _defaultStrategy,
      allocationData: {
        'nodeCapacity': selectedNode.totalCapacity[request.resourceType],
        'nodeUtilization': selectedNode.getUtilization(request.resourceType),
      },
    );

    // Update node capacity
    await _updateNodeAllocation(selectedNode, request.resourceType, request.amount, true);
    
    // Store allocation
    _activeAllocations[allocation.id] = allocation;
    _allocationHistory.add(allocation);
    
    // Trim history if needed
    if (_allocationHistory.length > _maxHistorySize) {
      _allocationHistory.removeAt(0);
    }

    _allocationController.add(allocation);
    return allocation;
  }

  List<NodeResourceCapacity> _findCandidateNodes(ResourceRequest request) {
    return _nodeCapacities.values
        .where((node) => node.canAllocate(request.resourceType, request.amount))
        .toList();
  }

  NodeResourceCapacity? _selectBestNode(List<NodeResourceCapacity> candidates, ResourceRequest request) {
    if (candidates.isEmpty) return null;

    // Score each candidate node
    double bestScore = -1;
    NodeResourceCapacity? bestNode;

    for (final node in candidates) {
      double score = _calculateNodeScore(node, request);
      if (score > bestScore) {
        bestScore = score;
        bestNode = node;
      }
    }

    return bestNode;
  }

  double _calculateNodeScore(NodeResourceCapacity node, ResourceRequest request) {
    double score = 0.0;

    // Factor 1: Available capacity (higher is better)
    final available = node.availableCapacity[request.resourceType] ?? 0.0;
    final total = node.totalCapacity[request.resourceType] ?? 1.0;
    score += (available / total) * 0.3;

    // Factor 2: Current utilization (lower is better)
    final utilization = node.getUtilization(request.resourceType);
    score += (1.0 - utilization) * 0.3;

    // Factor 3: Battery level (higher is better)
    score += node.batteryLevel * 0.2;

    // Factor 4: Processing load (lower is better)
    score += (1.0 - node.processingLoad) * 0.1;

    // Factor 5: Emergency mode compatibility
    if (request.isEmergency && node.isEmergencyMode) {
      score += 0.1;
    }

    return score;
  }

  Future<void> _updateNodeAllocation(NodeResourceCapacity node, ResourceType type, double amount, bool allocate) async {
    final currentAllocated = node.allocatedCapacity[type] ?? 0.0;
    final currentAvailable = node.availableCapacity[type] ?? 0.0;

    if (allocate) {
      node.allocatedCapacity[type] = currentAllocated + amount;
      node.availableCapacity[type] = max(0.0, currentAvailable - amount);
    } else {
      node.allocatedCapacity[type] = max(0.0, currentAllocated - amount);
      node.availableCapacity[type] = currentAvailable + amount;
    }
  }

  Future<void> _releaseAllocation(ResourceAllocation allocation) async {
    final node = _nodeCapacities[allocation.nodeId];
    if (node != null) {
      await _updateNodeAllocation(node, allocation.request.resourceType, allocation.allocatedAmount, false);
    }

    _activeAllocations.remove(allocation.id);
  }

  void _cleanupExpiredAllocations() {
    final expiredAllocations = _activeAllocations.values
        .where((allocation) => allocation.isExpired)
        .toList();

    for (final allocation in expiredAllocations) {
      _releaseAllocation(allocation);
    }
  }

  Future<void> _updateUsageStatistics() async {
    final now = DateTime.now();
    
    for (final type in ResourceType.values) {
      final recentAllocations = _allocationHistory
          .where((alloc) => alloc.request.resourceType == type)
          .where((alloc) => now.difference(alloc.allocationTime).inHours < 24)
          .toList();

      if (recentAllocations.isEmpty) continue;

      final totalRequested = recentAllocations.map((a) => a.request.amount).reduce((a, b) => a + b);
      final totalAllocated = recentAllocations.map((a) => a.allocatedAmount).reduce((a, b) => a + b);
      final successfulAllocations = recentAllocations.length;
      final totalRequests = successfulAllocations; // Simplified

      _usageStats[type] = ResourceUsageStats(
        resourceType: type,
        totalRequested: totalRequested,
        totalAllocated: totalAllocated,
        totalUsed: totalAllocated * 0.8, // Estimate 80% usage
        averageWaitTime: 0.0, // Simplified
        allocationSuccessRate: 1.0, // Simplified
        totalRequests: totalRequests,
        successfulAllocations: successfulAllocations,
        periodStart: now.subtract(const Duration(hours: 24)),
        periodEnd: now,
      );
    }

    _statsController.add(getPerformanceMetrics());
  }

  Map<String, double> _analyzeResourceDistribution(ResourceType type) {
    final utilizations = _nodeCapacities.values
        .map((node) => node.getUtilization(type))
        .toList();

    if (utilizations.isEmpty) return {'imbalance': 0.0};

    final average = utilizations.reduce((a, b) => a + b) / utilizations.length;
    final variance = utilizations.map((u) => pow(u - average, 2)).reduce((a, b) => a + b) / utilizations.length;
    final standardDeviation = sqrt(variance);

    return {
      'average': average,
      'variance': variance,
      'standardDeviation': standardDeviation,
      'imbalance': average > 0 ? standardDeviation / average : 0.0,
    };
  }

  double _calculateAverageAllocationTime(List<ResourceAllocation> allocations) {
    if (allocations.isEmpty) return 0.0;
    
    // Simplified - return 0 since we don't track allocation time properly
    return 0.0;
  }

  double _calculateSuccessRate(List<ResourceAllocation> allocations) {
    // Simplified - assume all tracked allocations are successful
    return 1.0;
  }

  double _calculateOverallUtilization() {
    if (_nodeCapacities.isEmpty) return 0.0;

    double totalUtilization = 0.0;
    int nodeCount = 0;

    for (final node in _nodeCapacities.values) {
      double nodeUtilization = 0.0;
      int resourceCount = 0;

      for (final type in ResourceType.values) {
        final util = node.getUtilization(type);
        if (util > 0) {
          nodeUtilization += util;
          resourceCount++;
        }
      }

      if (resourceCount > 0) {
        totalUtilization += nodeUtilization / resourceCount;
        nodeCount++;
      }
    }

    return nodeCount > 0 ? totalUtilization / nodeCount : 0.0;
  }
}
