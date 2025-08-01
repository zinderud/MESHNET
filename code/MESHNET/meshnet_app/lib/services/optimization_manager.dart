// lib/services/optimization_manager.dart - Ana Optimizasyon Yöneticisi
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meshnet_app/utils/logger.dart';
import 'package:meshnet_app/services/performance_monitor.dart';
import 'package:meshnet_app/services/memory_optimizer.dart';
import 'package:meshnet_app/services/cpu_optimizer.dart';
import 'package:meshnet_app/services/network_optimizer.dart';
import 'package:meshnet_app/services/battery_optimizer.dart';

enum OptimizationLevel {
  disabled,
  basic,
  moderate,
  aggressive,
  emergency,
}

class OptimizationManager {
  static final OptimizationManager _instance = OptimizationManager._internal();
  factory OptimizationManager() => _instance;
  OptimizationManager._internal();

  // Core services
  late final PerformanceMonitor _performanceMonitor;
  late final MemoryOptimizer _memoryOptimizer;
  late final CpuOptimizer _cpuOptimizer;
  late final NetworkOptimizer _networkOptimizer;
  late final BatteryOptimizer _batteryOptimizer;

  // Current state
  OptimizationLevel _currentLevel = OptimizationLevel.moderate;
  bool _isInitialized = false;
  bool _autoOptimizationEnabled = true;
  Timer? _optimizationTimer;
  Timer? _statisticsTimer;

  // Performance thresholds
  static const double memoryPressureThreshold = 0.8;
  static const double cpuUsageThreshold = 0.75;
  static const double frameTimeThreshold = 33.33; // 30 FPS minimum
  static const int batteryLowThreshold = 20;
  static const int batteryCriticalThreshold = 10;

  // Statistics
  final Map<String, OptimizationResult> _optimizationHistory = {};
  DateTime _lastOptimization = DateTime.now();
  int _totalOptimizations = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.info('Optimization Manager initializing...');

    try {
      // Initialize core services
      _performanceMonitor = PerformanceMonitor();
      _memoryOptimizer = MemoryOptimizer();
      _cpuOptimizer = CpuOptimizer();
      _networkOptimizer = NetworkOptimizer();
      _batteryOptimizer = BatteryOptimizer();

      // Initialize all services
      await _performanceMonitor.initialize();
      _memoryOptimizer.initialize();
      _cpuOptimizer.initialize();
      _networkOptimizer.initialize();
      await _batteryOptimizer.initialize();

      // Start monitoring and optimization
      _startAutoOptimization();
      _startStatisticsCollection();

      _isInitialized = true;
      Logger.info('Optimization Manager initialized successfully');

    } catch (e) {
      Logger.error('Failed to initialize Optimization Manager', error: e);
      rethrow;
    }
  }

  void _startAutoOptimization() {
    _optimizationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_autoOptimizationEnabled) {
        _performAutoOptimization();
      }
    });
  }

  void _startStatisticsCollection() {
    _statisticsTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _collectAndAnalyzeStatistics();
    });
  }

  // Auto Optimization Logic
  Future<void> _performAutoOptimization() async {
    try {
      final metrics = _performanceMonitor.getCurrentMetrics();
      final batteryStats = _batteryOptimizer.getBatteryStats();
      
      // Determine required optimization level
      final requiredLevel = _determineOptimizationLevel(metrics, batteryStats);
      
      if (requiredLevel != _currentLevel) {
        Logger.info('Auto-optimization changing level: $_currentLevel -> $requiredLevel');
        await setOptimizationLevel(requiredLevel);
      }
      
      // Perform specific optimizations based on metrics
      await _performTargetedOptimizations(metrics, batteryStats);
      
    } catch (e) {
      Logger.error('Auto-optimization failed', error: e);
    }
  }

  OptimizationLevel _determineOptimizationLevel(
    Map<String, dynamic> metrics,
    Map<String, dynamic> batteryStats,
  ) {
    final memoryUsage = metrics['memory_usage']?.toDouble() ?? 0.0;
    final cpuUsage = metrics['cpu_usage']?.toDouble() ?? 0.0;
    final frameTime = metrics['frame_time']?.toDouble() ?? 16.67;
    final batteryLevel = batteryStats['battery_level']?.toInt() ?? 100;
    final isCharging = batteryStats['is_charging'] ?? false;

    // Emergency mode conditions
    if (batteryLevel <= batteryCriticalThreshold && !isCharging) {
      return OptimizationLevel.emergency;
    }

    // Aggressive optimization conditions
    if ((memoryUsage > memoryPressureThreshold && cpuUsage > cpuUsageThreshold) ||
        (frameTime > frameTimeThreshold * 2) ||
        (batteryLevel <= batteryLowThreshold && !isCharging)) {
      return OptimizationLevel.aggressive;
    }

    // Moderate optimization conditions
    if (memoryUsage > memoryPressureThreshold * 0.7 ||
        cpuUsage > cpuUsageThreshold * 0.7 ||
        frameTime > frameTimeThreshold ||
        (batteryLevel <= 40 && !isCharging)) {
      return OptimizationLevel.moderate;
    }

    // Basic optimization conditions
    if (memoryUsage > 0.5 || cpuUsage > 0.5) {
      return OptimizationLevel.basic;
    }

    return OptimizationLevel.basic;
  }

  Future<void> _performTargetedOptimizations(
    Map<String, dynamic> metrics,
    Map<String, dynamic> batteryStats,
  ) async {
    final memoryUsage = metrics['memory_usage']?.toDouble() ?? 0.0;
    final cpuUsage = metrics['cpu_usage']?.toDouble() ?? 0.0;
    
    // Memory optimization
    if (memoryUsage > memoryPressureThreshold) {
      Logger.info('High memory usage detected, performing cleanup');
      _memoryOptimizer.setMemoryPressure(true);
      _memoryOptimizer.performCleanup();
    } else {
      _memoryOptimizer.setMemoryPressure(false);
    }
    
    // CPU optimization
    if (cpuUsage > cpuUsageThreshold) {
      Logger.info('High CPU usage detected, optimizing for battery');
      await _cpuOptimizer.optimizeForBatteryLife();
    }
    
    // Network optimization based on battery
    final batteryLevel = batteryStats['battery_level']?.toInt() ?? 100;
    if (batteryLevel < batteryLowThreshold) {
      _networkOptimizer.setBandwidthLimit(256 * 1024); // 256 KB/s
    } else if (batteryLevel < 50) {
      _networkOptimizer.setBandwidthLimit(512 * 1024); // 512 KB/s
    }
  }

  // Manual Optimization Control
  Future<void> setOptimizationLevel(OptimizationLevel level) async {
    if (!_isInitialized) {
      throw StateError('Optimization Manager not initialized');
    }

    final previousLevel = _currentLevel;
    _currentLevel = level;

    Logger.info('Setting optimization level: $previousLevel -> $level');

    try {
      await _applyOptimizationLevel(level);
      
      final result = OptimizationResult(
        level: level,
        timestamp: DateTime.now(),
        success: true,
        improvementMetrics: await _measureImprovements(),
      );
      
      _optimizationHistory[DateTime.now().toIso8601String()] = result;
      _totalOptimizations++;
      _lastOptimization = DateTime.now();

      Logger.info('Optimization level applied successfully: $level');

    } catch (e) {
      Logger.error('Failed to apply optimization level: $level', error: e);
      
      final result = OptimizationResult(
        level: level,
        timestamp: DateTime.now(),
        success: false,
        error: e.toString(),
      );
      
      _optimizationHistory[DateTime.now().toIso8601String()] = result;
      rethrow;
    }
  }

  Future<void> _applyOptimizationLevel(OptimizationLevel level) async {
    switch (level) {
      case OptimizationLevel.disabled:
        await _applyDisabledOptimization();
        break;
      case OptimizationLevel.basic:
        await _applyBasicOptimization();
        break;
      case OptimizationLevel.moderate:
        await _applyModerateOptimization();
        break;
      case OptimizationLevel.aggressive:
        await _applyAggressiveOptimization();
        break;
      case OptimizationLevel.emergency:
        await _applyEmergencyOptimization();
        break;
    }
  }

  Future<void> _applyDisabledOptimization() async {
    // Minimal optimizations, maximum performance
    await _cpuOptimizer.optimizeForPerformance();
    _networkOptimizer.setBandwidthLimit(0); // No limit
    _batteryOptimizer.setPowerMode(PowerMode.high);
  }

  Future<void> _applyBasicOptimization() async {
    // Light optimizations
    _memoryOptimizer.performCleanup();
    _networkOptimizer.setBandwidthLimit(2 * 1024 * 1024); // 2 MB/s
    _batteryOptimizer.setPowerMode(PowerMode.balanced);
  }

  Future<void> _applyModerateOptimization() async {
    // Balanced optimizations
    _memoryOptimizer.performCleanup();
    _networkOptimizer.setBandwidthLimit(1024 * 1024); // 1 MB/s
    _batteryOptimizer.setPowerMode(PowerMode.balanced);
    
    // Cancel low priority background tasks
    _cancelLowPriorityTasks();
  }

  Future<void> _applyAggressiveOptimization() async {
    // Strong optimizations
    _memoryOptimizer.setMemoryPressure(true);
    _memoryOptimizer.performCleanup();
    await _cpuOptimizer.optimizeForBatteryLife();
    _networkOptimizer.setBandwidthLimit(512 * 1024); // 512 KB/s
    _batteryOptimizer.setPowerMode(PowerMode.batterySaver);
    
    // Cancel most background tasks
    _cancelBackgroundTasks(priorityThreshold: 7);
  }

  Future<void> _applyEmergencyOptimization() async {
    // Maximum optimizations, minimum power usage
    _memoryOptimizer.setMemoryPressure(true);
    _memoryOptimizer.performCleanup();
    await _cpuOptimizer.optimizeForBatteryLife();
    _networkOptimizer.setBandwidthLimit(128 * 1024); // 128 KB/s
    _batteryOptimizer.enterEmergencyMode();
    
    // Cancel all but highest priority tasks
    _cancelBackgroundTasks(priorityThreshold: 9);
  }

  void _cancelLowPriorityTasks() {
    _cancelBackgroundTasks(priorityThreshold: 3);
  }

  void _cancelBackgroundTasks({required int priorityThreshold}) {
    // This would integrate with actual task management system
    Logger.info('Cancelling background tasks below priority $priorityThreshold');
  }

  // Performance Measurement
  Future<Map<String, double>> _measureImprovements() async {
    // Wait a bit for optimizations to take effect
    await Future.delayed(Duration(seconds: 2));
    
    final metrics = _performanceMonitor.getCurrentMetrics();
    final improvements = <String, double>{};
    
    improvements['memory_usage'] = metrics['memory_usage']?.toDouble() ?? 0.0;
    improvements['cpu_usage'] = metrics['cpu_usage']?.toDouble() ?? 0.0;
    improvements['frame_time'] = metrics['frame_time']?.toDouble() ?? 16.67;
    improvements['fps'] = metrics['fps']?.toDouble() ?? 60.0;
    
    return improvements;
  }

  // Statistics and Analysis
  void _collectAndAnalyzeStatistics() {
    final stats = getComprehensiveStats();
    
    // Log key metrics
    Logger.debug('Optimization stats: ${stats['summary']}');
    
    // Record to performance monitor
    _performanceMonitor.recordCustomMetric(
      'optimization_level',
      _currentLevel.index.toDouble(),
    );
    _performanceMonitor.recordCustomMetric(
      'total_optimizations',
      _totalOptimizations.toDouble(),
    );
  }

  // Public API
  void enableAutoOptimization() {
    _autoOptimizationEnabled = true;
    Logger.info('Auto-optimization enabled');
  }

  void disableAutoOptimization() {
    _autoOptimizationEnabled = false;
    Logger.info('Auto-optimization disabled');
  }

  Future<void> performManualOptimization() async {
    Logger.info('Performing manual optimization');
    await _performAutoOptimization();
  }

  Future<void> optimizeForEmergency() async {
    Logger.warning('Emergency optimization requested');
    await setOptimizationLevel(OptimizationLevel.emergency);
  }

  Future<void> optimizeForBattery() async {
    Logger.info('Battery optimization requested');
    await setOptimizationLevel(OptimizationLevel.aggressive);
  }

  Future<void> optimizeForPerformance() async {
    Logger.info('Performance optimization requested');
    await setOptimizationLevel(OptimizationLevel.basic);
  }

  // Statistics and Reporting
  Map<String, dynamic> getComprehensiveStats() {
    final performanceStats = _performanceMonitor.getCurrentMetrics();
    final memoryStats = _memoryOptimizer.getMemoryStats();
    final cpuStats = _cpuOptimizer.getCpuStats();
    final networkStats = _networkOptimizer.getNetworkStats();
    final batteryStats = _batteryOptimizer.getBatteryStats();

    return {
      'current_level': _currentLevel.toString(),
      'auto_optimization_enabled': _autoOptimizationEnabled,
      'total_optimizations': _totalOptimizations,
      'last_optimization': _lastOptimization.toIso8601String(),
      'summary': {
        'memory_usage_mb': (performanceStats['memory_usage'] ?? 0) / (1024 * 1024),
        'cpu_usage_percent': performanceStats['cpu_usage'] ?? 0,
        'frame_time_ms': performanceStats['frame_time'] ?? 16.67,
        'battery_level': batteryStats['battery_level'] ?? 100,
        'active_connections': networkStats['active_connections'] ?? 0,
      },
      'detailed_stats': {
        'performance': performanceStats,
        'memory': memoryStats,
        'cpu': cpuStats,
        'network': networkStats,
        'battery': batteryStats,
      },
      'optimization_history': _optimizationHistory,
    };
  }

  List<String> getAllOptimizationRecommendations() {
    final recommendations = <String>[];
    
    recommendations.addAll(_memoryOptimizer.getMemoryOptimizationRecommendations());
    recommendations.addAll(_cpuOptimizer.getCpuOptimizationRecommendations());
    recommendations.addAll(_networkOptimizer.getNetworkOptimizationRecommendations());
    recommendations.addAll(_batteryOptimizer.getBatteryOptimizationRecommendations());
    
    // Add general recommendations
    if (_currentLevel == OptimizationLevel.disabled) {
      recommendations.add('Consider enabling optimizations to improve battery life and performance.');
    }
    
    if (_totalOptimizations == 0) {
      recommendations.add('Run optimizations to improve app performance.');
    }
    
    final timeSinceLastOptimization = DateTime.now().difference(_lastOptimization);
    if (timeSinceLastOptimization.inHours > 2) {
      recommendations.add('Consider running optimizations - last run ${timeSinceLastOptimization.inHours} hours ago.');
    }
    
    return recommendations;
  }

  // Testing and Development
  Future<void> runOptimizationTest() async {
    if (!kDebugMode) return;
    
    Logger.info('Running optimization test suite');
    
    try {
      // Test all optimization levels
      for (final level in OptimizationLevel.values) {
        if (level == OptimizationLevel.emergency) continue; // Skip emergency in tests
        
        Logger.debug('Testing optimization level: $level');
        await setOptimizationLevel(level);
        await Future.delayed(Duration(seconds: 1));
        
        final stats = getComprehensiveStats();
        Logger.debug('Level $level stats: ${stats['summary']}');
      }
      
      // Return to moderate level
      await setOptimizationLevel(OptimizationLevel.moderate);
      
      Logger.info('Optimization test completed successfully');
      
    } catch (e) {
      Logger.error('Optimization test failed', error: e);
    }
  }

  void dispose() {
    _optimizationTimer?.cancel();
    _statisticsTimer?.cancel();
    
    if (_isInitialized) {
      _performanceMonitor.dispose();
      _memoryOptimizer.dispose();
      _cpuOptimizer.dispose();
      _networkOptimizer.dispose();
      _batteryOptimizer.dispose();
    }
    
    _isInitialized = false;
    Logger.info('Optimization Manager disposed');
  }
}

// Supporting classes
class OptimizationResult {
  final OptimizationLevel level;
  final DateTime timestamp;
  final bool success;
  final String? error;
  final Map<String, double>? improvementMetrics;

  OptimizationResult({
    required this.level,
    required this.timestamp,
    required this.success,
    this.error,
    this.improvementMetrics,
  });

  Map<String, dynamic> toMap() {
    return {
      'level': level.toString(),
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'error': error,
      'improvement_metrics': improvementMetrics,
    };
  }
}
