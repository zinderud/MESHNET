// lib/services/battery_optimizer.dart - Batarya Optimizasyon Servisi
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meshnet_app/utils/logger.dart';
import 'package:meshnet_app/services/performance_monitor.dart';
import 'package:meshnet_app/services/cpu_optimizer.dart';
import 'package:meshnet_app/services/network_optimizer.dart';

enum PowerMode {
  high,           // Maksimum performans
  balanced,       // Dengeli mod
  batterySaver,   // Batarya tasarrufu
  emergency,      // Acil durum modu (minimum güç)
}

class BatteryOptimizer {
  static final BatteryOptimizer _instance = BatteryOptimizer._internal();
  factory BatteryOptimizer() => _instance;
  BatteryOptimizer._internal();

  // Platform channel for battery info
  static const MethodChannel _batteryChannel = MethodChannel('battery_optimizer');

  // Current state
  PowerMode _currentMode = PowerMode.balanced;
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _isPowerSaveMode = false;
  
  // Monitoring
  Timer? _batteryMonitorTimer;
  final List<BatteryReading> _batteryHistory = [];
  static const int maxHistoryEntries = 100;
  
  // Power consumption tracking
  final Map<String, PowerConsumption> _componentConsumption = {};
  double _estimatedRemainingHours = 0.0;
  
  // Optimization settings
  final Map<PowerMode, PowerSettings> _powerSettings = {};
  
  // Background tasks management
  final Set<String> _backgroundTasks = {};
  final Map<String, Timer> _scheduledTasks = {};

  void initialize() async {
    Logger.info('Battery Optimizer initialized');
    
    _setupPowerModeSettings();
    await _setupBatteryMonitoring();
    _startBatteryTracking();
    _setupPowerModeDetection();
  }

  void _setupPowerModeSettings() {
    // High Performance Mode
    _powerSettings[PowerMode.high] = PowerSettings(
      cpuThrottle: 1.0,
      networkFrequency: 1.0,
      screenBrightness: 1.0,
      backgroundTaskLimit: 10,
      bluetoothScanInterval: Duration(seconds: 1),
      wifiScanInterval: Duration(seconds: 2),
      gpsAccuracy: 'high',
      animationsEnabled: true,
      heavyComputationEnabled: true,
    );

    // Balanced Mode
    _powerSettings[PowerMode.balanced] = PowerSettings(
      cpuThrottle: 0.8,
      networkFrequency: 0.8,
      screenBrightness: 0.8,
      backgroundTaskLimit: 5,
      bluetoothScanInterval: Duration(seconds: 3),
      wifiScanInterval: Duration(seconds: 5),
      gpsAccuracy: 'medium',
      animationsEnabled: true,
      heavyComputationEnabled: true,
    );

    // Battery Saver Mode
    _powerSettings[PowerMode.batterySaver] = PowerSettings(
      cpuThrottle: 0.5,
      networkFrequency: 0.4,
      screenBrightness: 0.4,
      backgroundTaskLimit: 2,
      bluetoothScanInterval: Duration(seconds: 10),
      wifiScanInterval: Duration(seconds: 15),
      gpsAccuracy: 'low',
      animationsEnabled: false,
      heavyComputationEnabled: false,
    );

    // Emergency Mode
    _powerSettings[PowerMode.emergency] = PowerSettings(
      cpuThrottle: 0.2,
      networkFrequency: 0.1,
      screenBrightness: 0.2,
      backgroundTaskLimit: 0,
      bluetoothScanInterval: Duration(seconds: 30),
      wifiScanInterval: Duration(seconds: 60),
      gpsAccuracy: 'low',
      animationsEnabled: false,
      heavyComputationEnabled: false,
    );
  }

  Future<void> _setupBatteryMonitoring() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // Platform-specific battery monitoring would be implemented here
        // For now, we'll simulate battery data
        _batteryLevel = 80;
        _isCharging = false;
      }
    } catch (e) {
      Logger.error('Failed to setup battery monitoring', error: e);
    }
  }

  void _startBatteryTracking() {
    _batteryMonitorTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateBatteryStatus();
      _analyzeConsumption();
      _adjustPowerMode();
    });
  }

  void _setupPowerModeDetection() {
    // Listen for system power save mode changes
    Timer.periodic(Duration(minutes: 1), (timer) {
      _detectSystemPowerSaveMode();
    });
  }

  // Battery Status Management
  Future<void> _updateBatteryStatus() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // In a real implementation, this would get actual battery data
        // For simulation, we'll decrease battery level slowly
        if (!_isCharging && _batteryLevel > 0) {
          _batteryLevel = math.max(0, _batteryLevel - 1);
        }
      }
      
      final reading = BatteryReading(
        level: _batteryLevel,
        isCharging: _isCharging,
        timestamp: DateTime.now(),
        powerMode: _currentMode,
      );
      
      _batteryHistory.add(reading);
      if (_batteryHistory.length > maxHistoryEntries) {
        _batteryHistory.removeAt(0);
      }
      
      _estimateRemainingTime();
      
      Logger.debug('Battery: ${_batteryLevel}%, charging: $_isCharging, mode: $_currentMode');
      
    } catch (e) {
      Logger.error('Failed to update battery status', error: e);
    }
  }

  void _analyzeConsumption() {
    // Analyze power consumption patterns
    if (_batteryHistory.length < 2) return;
    
    final recent = _batteryHistory.takeLast(10).toList();
    double consumptionRate = 0.0;
    
    for (int i = 1; i < recent.length; i++) {
      final current = recent[i];
      final previous = recent[i - 1];
      
      if (!current.isCharging && !previous.isCharging) {
        final timeDiff = current.timestamp.difference(previous.timestamp).inMinutes;
        final levelDiff = previous.level - current.level;
        
        if (timeDiff > 0) {
          consumptionRate += levelDiff / timeDiff; // % per minute
        }
      }
    }
    
    if (recent.length > 1) {
      consumptionRate /= (recent.length - 1);
      _recordConsumptionRate(consumptionRate);
    }
  }

  void _recordConsumptionRate(double rate) {
    final component = _componentConsumption.putIfAbsent(
      'overall',
      () => PowerConsumption('overall'),
    );
    
    component.addReading(rate, DateTime.now());
    
    // Report to performance monitor
    final performanceMonitor = PerformanceMonitor();
    performanceMonitor.recordCustomMetric('battery_consumption_rate', rate);
  }

  void _estimateRemainingTime() {
    if (_isCharging || _batteryHistory.length < 2) {
      _estimatedRemainingHours = 0.0;
      return;
    }
    
    final recentConsumption = _getRecentConsumptionRate();
    if (recentConsumption > 0) {
      _estimatedRemainingHours = _batteryLevel / (recentConsumption * 60); // Convert to hours
    }
  }

  double _getRecentConsumptionRate() {
    if (_batteryHistory.length < 2) return 0.0;
    
    final recent = _batteryHistory.takeLast(5).toList();
    double totalRate = 0.0;
    int validReadings = 0;
    
    for (int i = 1; i < recent.length; i++) {
      final current = recent[i];
      final previous = recent[i - 1];
      
      if (!current.isCharging && !previous.isCharging) {
        final timeDiff = current.timestamp.difference(previous.timestamp).inMinutes;
        final levelDiff = previous.level - current.level;
        
        if (timeDiff > 0 && levelDiff >= 0) {
          totalRate += levelDiff / timeDiff;
          validReadings++;
        }
      }
    }
    
    return validReadings > 0 ? totalRate / validReadings : 0.0;
  }

  // Power Mode Management
  void setPowerMode(PowerMode mode) {
    if (_currentMode == mode) return;
    
    final previousMode = _currentMode;
    _currentMode = mode;
    
    Logger.info('Power mode changed: $previousMode -> $mode');
    _applyPowerModeSettings();
    
    // Notify other services
    _notifyPowerModeChange(mode);
  }

  void _adjustPowerMode() {
    // Auto-adjust power mode based on battery level
    if (_isCharging) return; // Don't auto-adjust while charging
    
    if (_batteryLevel <= 5) {
      setPowerMode(PowerMode.emergency);
    } else if (_batteryLevel <= 15) {
      setPowerMode(PowerMode.batterySaver);
    } else if (_batteryLevel <= 30 && _currentMode == PowerMode.high) {
      setPowerMode(PowerMode.balanced);
    }
  }

  void _applyPowerModeSettings() {
    final settings = _powerSettings[_currentMode]!;
    
    // Apply CPU throttling
    _applyCpuThrottling(settings.cpuThrottle);
    
    // Apply network frequency
    _applyNetworkOptimizations(settings.networkFrequency);
    
    // Manage background tasks
    _manageBackgroundTasks(settings.backgroundTaskLimit);
    
    // Apply screen brightness (would need platform channel)
    _applyScreenBrightness(settings.screenBrightness);
    
    Logger.debug('Applied power mode settings: $_currentMode');
  }

  void _applyCpuThrottling(double throttle) {
    // Integrate with CPU optimizer
    final cpuOptimizer = CpuOptimizer();
    
    if (throttle < 0.5) {
      cpuOptimizer.optimizeForBatteryLife();
    } else if (throttle > 0.8) {
      cpuOptimizer.optimizeForPerformance();
    }
  }

  void _applyNetworkOptimizations(double frequency) {
    // Integrate with network optimizer
    final networkOptimizer = NetworkOptimizer();
    
    // Adjust bandwidth based on power mode
    if (frequency < 0.5) {
      networkOptimizer.setBandwidthLimit(128 * 1024); // 128 KB/s
    } else if (frequency < 0.8) {
      networkOptimizer.setBandwidthLimit(512 * 1024); // 512 KB/s
    } else {
      networkOptimizer.setBandwidthLimit(0); // No limit
    }
  }

  void _manageBackgroundTasks(int limit) {
    // Cancel excess background tasks
    if (_backgroundTasks.length > limit) {
      final tasksToCancel = _backgroundTasks.take(_backgroundTasks.length - limit);
      for (final taskId in tasksToCancel) {
        cancelBackgroundTask(taskId);
      }
    }
  }

  void _applyScreenBrightness(double brightness) {
    // Platform-specific implementation would go here
    Logger.debug('Screen brightness set to ${(brightness * 100).toInt()}%');
  }

  void _notifyPowerModeChange(PowerMode mode) {
    // Notify other services about power mode change
    final performanceMonitor = PerformanceMonitor();
    performanceMonitor.recordCustomMetric('power_mode', mode.index.toDouble());
  }

  void _detectSystemPowerSaveMode() {
    // Platform-specific implementation to detect system power save mode
    // For now, simulate based on battery level
    _isPowerSaveMode = _batteryLevel < 20;
    
    if (_isPowerSaveMode && _currentMode != PowerMode.batterySaver && _currentMode != PowerMode.emergency) {
      Logger.info('System power save mode detected, switching to battery saver');
      setPowerMode(PowerMode.batterySaver);
    }
  }

  // Background Task Management
  void scheduleBackgroundTask({
    required String id,
    required Function() task,
    required Duration interval,
    int priority = 5,
  }) {
    // Check if task is allowed in current power mode
    final settings = _powerSettings[_currentMode]!;
    if (_backgroundTasks.length >= settings.backgroundTaskLimit) {
      Logger.warning('Background task limit reached, rejecting task: $id');
      return;
    }
    
    // Cancel existing task
    cancelBackgroundTask(id);
    
    // Adjust interval based on power mode
    final adjustedInterval = Duration(
      milliseconds: (interval.inMilliseconds / settings.networkFrequency).round(),
    );
    
    final timer = Timer.periodic(adjustedInterval, (timer) {
      if (_shouldExecuteBackgroundTask(id, priority)) {
        try {
          task();
        } catch (e) {
          Logger.error('Background task error: $id', error: e);
        }
      }
    });
    
    _scheduledTasks[id] = timer;
    _backgroundTasks.add(id);
    
    Logger.debug('Background task scheduled: $id (interval: ${adjustedInterval.inSeconds}s)');
  }

  bool _shouldExecuteBackgroundTask(String id, int priority) {
    // Skip task in emergency mode unless high priority
    if (_currentMode == PowerMode.emergency && priority < 8) {
      return false;
    }
    
    // Skip task if battery is critically low
    if (_batteryLevel < 5 && priority < 9) {
      return false;
    }
    
    return true;
  }

  void cancelBackgroundTask(String id) {
    _scheduledTasks[id]?.cancel();
    _scheduledTasks.remove(id);
    _backgroundTasks.remove(id);
    Logger.debug('Background task cancelled: $id');
  }

  // Component Power Tracking
  void recordComponentUsage(String componentName, double powerDraw) {
    final component = _componentConsumption.putIfAbsent(
      componentName,
      () => PowerConsumption(componentName),
    );
    
    component.addReading(powerDraw, DateTime.now());
  }

  Map<String, double> getComponentPowerConsumption() {
    final consumption = <String, double>{};
    
    for (final entry in _componentConsumption.entries) {
      consumption[entry.key] = entry.value.getAverageConsumption();
    }
    
    return consumption;
  }

  // Emergency Power Management
  void enterEmergencyMode() {
    Logger.warning('Entering emergency power mode');
    setPowerMode(PowerMode.emergency);
    
    // Disable non-essential features
    _disableNonEssentialFeatures();
    
    // Notify user
    _notifyEmergencyMode();
  }

  void _disableNonEssentialFeatures() {
    // Cancel all but highest priority background tasks
    final tasksToKeep = <String>[];
    for (final taskId in _backgroundTasks) {
      // Keep only emergency communication tasks
      if (taskId.contains('emergency') || taskId.contains('mesh_heartbeat')) {
        tasksToKeep.add(taskId);
      } else {
        cancelBackgroundTask(taskId);
      }
    }
    
    Logger.info('Emergency mode: kept ${tasksToKeep.length} essential tasks');
  }

  void _notifyEmergencyMode() {
    // Platform-specific notification implementation
    Logger.info('Emergency mode notification sent');
  }

  // Optimization Recommendations
  List<String> getBatteryOptimizationRecommendations() {
    final recommendations = <String>[];
    
    if (_batteryLevel < 20 && !_isCharging) {
      recommendations.add('Battery low! Enable battery saver mode or find a charger.');
    }
    
    if (_getRecentConsumptionRate() > 2.0) { // > 2% per minute
      recommendations.add('High battery consumption detected. Close unnecessary apps.');
    }
    
    if (_backgroundTasks.length > 5) {
      recommendations.add('Many background tasks running. Consider disabling non-essential tasks.');
    }
    
    if (_currentMode == PowerMode.high && _batteryLevel < 50) {
      recommendations.add('Consider switching to balanced mode to extend battery life.');
    }
    
    final screenConsumption = _componentConsumption['screen']?.getAverageConsumption() ?? 0;
    if (screenConsumption > 30) { // Arbitrary threshold
      recommendations.add('Screen brightness is high. Reduce to save battery.');
    }
    
    return recommendations;
  }

  // Statistics
  Map<String, dynamic> getBatteryStats() {
    return {
      'battery_level': _batteryLevel,
      'is_charging': _isCharging,
      'power_mode': _currentMode.toString(),
      'estimated_remaining_hours': _estimatedRemainingHours,
      'consumption_rate_percent_per_minute': _getRecentConsumptionRate(),
      'background_tasks': _backgroundTasks.length,
      'component_consumption': getComponentPowerConsumption(),
      'is_power_save_mode': _isPowerSaveMode,
      'battery_history_entries': _batteryHistory.length,
    };
  }

  // Test methods for simulation
  void simulateBatteryLevel(int level) {
    _batteryLevel = math.max(0, math.min(100, level));
    Logger.debug('Battery level simulated: $_batteryLevel%');
  }

  void simulateCharging(bool charging) {
    _isCharging = charging;
    Logger.debug('Charging state simulated: $_isCharging');
  }

  void dispose() {
    _batteryMonitorTimer?.cancel();
    
    // Cancel all background tasks
    for (final timer in _scheduledTasks.values) {
      timer.cancel();
    }
    _scheduledTasks.clear();
    _backgroundTasks.clear();
    
    Logger.info('Battery Optimizer disposed');
  }
}

// Supporting classes
class PowerSettings {
  final double cpuThrottle;
  final double networkFrequency;
  final double screenBrightness;
  final int backgroundTaskLimit;
  final Duration bluetoothScanInterval;
  final Duration wifiScanInterval;
  final String gpsAccuracy;
  final bool animationsEnabled;
  final bool heavyComputationEnabled;

  PowerSettings({
    required this.cpuThrottle,
    required this.networkFrequency,
    required this.screenBrightness,
    required this.backgroundTaskLimit,
    required this.bluetoothScanInterval,
    required this.wifiScanInterval,
    required this.gpsAccuracy,
    required this.animationsEnabled,
    required this.heavyComputationEnabled,
  });
}

class BatteryReading {
  final int level;
  final bool isCharging;
  final DateTime timestamp;
  final PowerMode powerMode;

  BatteryReading({
    required this.level,
    required this.isCharging,
    required this.timestamp,
    required this.powerMode,
  });
}

class PowerConsumption {
  final String componentName;
  final List<PowerReading> readings = [];
  static const int maxReadings = 50;

  PowerConsumption(this.componentName);

  void addReading(double consumption, DateTime timestamp) {
    readings.add(PowerReading(consumption, timestamp));
    
    if (readings.length > maxReadings) {
      readings.removeAt(0);
    }
  }

  double getAverageConsumption() {
    if (readings.isEmpty) return 0.0;
    
    final total = readings.fold<double>(0.0, (sum, reading) => sum + reading.consumption);
    return total / readings.length;
  }

  double getRecentConsumption() {
    if (readings.isEmpty) return 0.0;
    
    final recent = readings.takeLast(10);
    final total = recent.fold<double>(0.0, (sum, reading) => sum + reading.consumption);
    return total / recent.length;
  }
}

class PowerReading {
  final double consumption;
  final DateTime timestamp;

  PowerReading(this.consumption, this.timestamp);
}

// Utility extensions
extension TakeLast<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (count >= length) return this;
    return skip(length - count);
  }
}

// Import for math
import 'dart:math' as math;
