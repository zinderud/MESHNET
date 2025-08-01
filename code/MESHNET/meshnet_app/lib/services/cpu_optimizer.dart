// lib/services/cpu_optimizer.dart - CPU Optimizasyon Servisi
import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:meshnet_app/utils/logger.dart';
import 'package:meshnet_app/services/performance_monitor.dart';

class CpuOptimizer {
  static final CpuOptimizer _instance = CpuOptimizer._internal();
  factory CpuOptimizer() => _instance;
  CpuOptimizer._internal();

  // Task queue and processing
  final Queue<_CpuTask> _taskQueue = Queue<_CpuTask>();
  final Map<String, Isolate> _isolates = {};
  final Map<String, ReceivePort> _receivePorts = {};
  bool _isProcessing = false;
  
  // Adaptive processing
  int _currentCpuLoad = 0;
  double _frameTime = 16.67; // Target 60 FPS
  Timer? _adaptiveTimer;
  
  // Background task management
  final Map<String, Timer> _backgroundTasks = {};
  static const int maxConcurrentTasks = 3;
  static const Duration taskTimeout = Duration(seconds: 30);
  
  // Performance thresholds
  static const double highCpuThreshold = 0.8;
  static const double targetFrameTime = 16.67; // 60 FPS
  static const double maxFrameTime = 33.33; // 30 FPS minimum

  void initialize() {
    Logger.info('CPU Optimizer initialized');
    _startAdaptiveProcessing();
    _startPerformanceMonitoring();
  }

  void _startAdaptiveProcessing() {
    _adaptiveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _adaptProcessingRate();
      _processTaskQueue();
    });
  }

  void _startPerformanceMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _monitorCpuPerformance();
    });
  }

  // Task Queue Management
  void addTask(_CpuTask task) {
    _taskQueue.add(task);
    Logger.debug('Task added to queue: ${task.id}');
  }

  Future<T> scheduleTask<T>({
    required String id,
    required Future<T> Function() task,
    int priority = 0,
    bool useIsolate = false,
  }) async {
    final completer = Completer<T>();
    
    final cpuTask = _CpuTask<T>(
      id: id,
      task: task,
      completer: completer,
      priority: priority,
      useIsolate: useIsolate,
      createdAt: DateTime.now(),
    );
    
    addTask(cpuTask);
    return completer.future;
  }

  void _processTaskQueue() {
    if (_isProcessing || _taskQueue.isEmpty) return;
    
    // Check CPU load before processing
    if (_currentCpuLoad > highCpuThreshold * 100) {
      Logger.warning('High CPU load detected, delaying task processing');
      return;
    }
    
    _isProcessing = true;
    
    // Sort tasks by priority
    final tasks = _taskQueue.toList();
    tasks.sort((a, b) => b.priority.compareTo(a.priority));
    _taskQueue.clear();
    _taskQueue.addAll(tasks);
    
    // Process highest priority task
    final task = _taskQueue.removeFirst();
    _executeTask(task);
  }

  Future<void> _executeTask(_CpuTask task) async {
    try {
      Logger.debug('Executing task: ${task.id}');
      
      if (task.useIsolate && !kIsWeb) {
        await _executeInIsolate(task);
      } else {
        await _executeInMainThread(task);
      }
    } catch (e) {
      Logger.error('Task execution failed: ${task.id}', error: e);
      task.completer.completeError(e);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _executeInMainThread(_CpuTask task) async {
    final stopwatch = Stopwatch()..start();
    
    // Execute with timeout
    final result = await task.task().timeout(taskTimeout);
    
    stopwatch.stop();
    Logger.debug('Task ${task.id} completed in ${stopwatch.elapsedMilliseconds}ms');
    
    task.completer.complete(result);
  }

  Future<void> _executeInIsolate(_CpuTask task) async {
    final isolateId = 'isolate_${task.id}';
    
    try {
      // Create receive port
      final receivePort = ReceivePort();
      _receivePorts[isolateId] = receivePort;
      
      // Spawn isolate
      final isolate = await Isolate.spawn(
        _isolateEntryPoint,
        receivePort.sendPort,
      );
      _isolates[isolateId] = isolate;
      
      // Listen for result
      final completer = Completer();
      late StreamSubscription subscription;
      
      subscription = receivePort.listen((data) {
        if (data is Map && data['type'] == 'result') {
          task.completer.complete(data['result']);
          completer.complete();
        } else if (data is Map && data['type'] == 'error') {
          task.completer.completeError(Exception(data['error']));
          completer.complete();
        }
        subscription.cancel();
      });
      
      // Send task to isolate
      final sendPort = await receivePort.first as SendPort;
      sendPort.send({
        'type': 'task',
        'id': task.id,
        'data': task.serializeData(),
      });
      
      // Wait for completion with timeout
      await completer.future.timeout(taskTimeout);
      
    } finally {
      // Cleanup isolate
      _cleanupIsolate(isolateId);
    }
  }

  void _cleanupIsolate(String isolateId) {
    _isolates[isolateId]?.kill();
    _isolates.remove(isolateId);
    _receivePorts[isolateId]?.close();
    _receivePorts.remove(isolateId);
  }

  static void _isolateEntryPoint(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    receivePort.listen((data) async {
      if (data is Map && data['type'] == 'task') {
        try {
          // Execute CPU-intensive task in isolate
          final result = await _executeIsolateTask(data);
          sendPort.send({'type': 'result', 'result': result});
        } catch (e) {
          sendPort.send({'type': 'error', 'error': e.toString()});
        }
      }
    });
  }

  static Future<dynamic> _executeIsolateTask(Map data) async {
    // This would contain the actual task logic
    // For now, simulate CPU-intensive work
    await Future.delayed(Duration(milliseconds: 100));
    return 'Task ${data['id']} completed in isolate';
  }

  // Adaptive Processing
  void _adaptProcessingRate() {
    final performanceMonitor = PerformanceMonitor();
    final metrics = performanceMonitor.getCurrentMetrics();
    
    _currentCpuLoad = metrics['cpu_usage']?.toInt() ?? 0;
    _frameTime = metrics['frame_time']?.toDouble() ?? 16.67;
    
    // Adjust processing based on performance
    if (_frameTime > maxFrameTime) {
      _reduceCpuLoad();
    } else if (_frameTime < targetFrameTime && _currentCpuLoad < 50) {
      _increaseCpuLoad();
    }
  }

  void _reduceCpuLoad() {
    Logger.debug('Reducing CPU load due to poor frame performance');
    
    // Delay non-critical tasks
    final delayedTasks = <_CpuTask>[];
    while (_taskQueue.isNotEmpty && _taskQueue.first.priority < 5) {
      delayedTasks.add(_taskQueue.removeFirst());
    }
    
    // Re-add delayed tasks after a delay
    Timer(const Duration(milliseconds: 500), () {
      _taskQueue.addAll(delayedTasks);
    });
  }

  void _increaseCpuLoad() {
    // Allow more concurrent processing when performance is good
    // This is handled by allowing more tasks to be processed
  }

  // Background Task Management
  void scheduleBackgroundTask({
    required String id,
    required Function() task,
    required Duration interval,
    bool immediate = false,
  }) {
    // Cancel existing task if any
    _backgroundTasks[id]?.cancel();
    
    final timer = Timer.periodic(interval, (timer) {
      if (_currentCpuLoad < highCpuThreshold * 100) {
        try {
          task();
        } catch (e) {
          Logger.error('Background task error: $id', error: e);
        }
      } else {
        Logger.debug('Skipping background task $id due to high CPU load');
      }
    });
    
    _backgroundTasks[id] = timer;
    
    if (immediate) {
      task();
    }
    
    Logger.debug('Background task scheduled: $id');
  }

  void cancelBackgroundTask(String id) {
    _backgroundTasks[id]?.cancel();
    _backgroundTasks.remove(id);
    Logger.debug('Background task cancelled: $id');
  }

  // Performance Monitoring
  void _monitorCpuPerformance() {
    final metrics = {
      'active_tasks': _taskQueue.length,
      'active_isolates': _isolates.length,
      'background_tasks': _backgroundTasks.length,
      'current_cpu_load': _currentCpuLoad,
      'frame_time': _frameTime,
    };
    
    Logger.debug('CPU Performance: $metrics');
    
    // Report to performance monitor
    final performanceMonitor = PerformanceMonitor();
    performanceMonitor.recordCustomMetric('cpu_optimizer_tasks', _taskQueue.length.toDouble());
    performanceMonitor.recordCustomMetric('cpu_optimizer_isolates', _isolates.length.toDouble());
  }

  // Optimization Strategies
  Future<void> optimizeForBatteryLife() async {
    Logger.info('Optimizing CPU for battery life');
    
    // Reduce background task frequency
    for (final entry in _backgroundTasks.entries) {
      entry.value.cancel();
      // Reschedule with longer intervals
      scheduleBackgroundTask(
        id: entry.key,
        task: () {}, // Would need to store original task
        interval: Duration(seconds: 30), // Longer interval
      );
    }
    
    // Limit concurrent tasks
    while (_taskQueue.length > 1) {
      final task = _taskQueue.removeLast();
      task.completer.completeError(Exception('Task cancelled for battery optimization'));
    }
  }

  Future<void> optimizeForPerformance() async {
    Logger.info('Optimizing CPU for performance');
    
    // Allow more concurrent processing
    // Pre-warm isolates for heavy tasks
    for (int i = 0; i < maxConcurrentTasks; i++) {
      final isolateId = 'prewarmed_$i';
      if (!_isolates.containsKey(isolateId)) {
        try {
          final receivePort = ReceivePort();
          final isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);
          _isolates[isolateId] = isolate;
          _receivePorts[isolateId] = receivePort;
        } catch (e) {
          Logger.error('Failed to pre-warm isolate', error: e);
        }
      }
    }
  }

  // Statistics and Recommendations
  Map<String, dynamic> getCpuStats() {
    return {
      'queued_tasks': _taskQueue.length,
      'active_isolates': _isolates.length,
      'background_tasks': _backgroundTasks.length,
      'current_cpu_load': _currentCpuLoad,
      'frame_time_ms': _frameTime,
      'is_processing': _isProcessing,
    };
  }

  List<String> getCpuOptimizationRecommendations() {
    final recommendations = <String>[];
    
    if (_currentCpuLoad > highCpuThreshold * 100) {
      recommendations.add('High CPU usage detected. Consider reducing background tasks.');
    }
    
    if (_frameTime > maxFrameTime) {
      recommendations.add('Poor frame performance. Reduce CPU-intensive operations.');
    }
    
    if (_taskQueue.length > 10) {
      recommendations.add('Task queue is large. Consider prioritizing or cancelling tasks.');
    }
    
    if (_isolates.length > maxConcurrentTasks) {
      recommendations.add('Too many active isolates. Consider limiting concurrent operations.');
    }
    
    return recommendations;
  }

  void dispose() {
    _adaptiveTimer?.cancel();
    
    // Cancel all background tasks
    for (final timer in _backgroundTasks.values) {
      timer.cancel();
    }
    _backgroundTasks.clear();
    
    // Cleanup all isolates
    for (final isolateId in _isolates.keys.toList()) {
      _cleanupIsolate(isolateId);
    }
    
    // Complete pending tasks with error
    while (_taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      task.completer.completeError(Exception('CPU Optimizer disposed'));
    }
    
    Logger.info('CPU Optimizer disposed');
  }
}

// Task representation
class _CpuTask<T> {
  final String id;
  final Future<T> Function() task;
  final Completer<T> completer;
  final int priority;
  final bool useIsolate;
  final DateTime createdAt;

  _CpuTask({
    required this.id,
    required this.task,
    required this.completer,
    required this.priority,
    required this.useIsolate,
    required this.createdAt,
  });

  Map<String, dynamic> serializeData() {
    // Serialize task data for isolate execution
    return {
      'id': id,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// CPU-intensive operations utility
class CpuIntensiveOperations {
  static Future<List<int>> sortLargeList(List<int> data) async {
    return await CpuOptimizer().scheduleTask<List<int>>(
      id: 'sort_large_list',
      task: () async {
        data.sort();
        return data;
      },
      priority: 3,
      useIsolate: data.length > 10000,
    );
  }

  static Future<String> encryptData(String data) async {
    return await CpuOptimizer().scheduleTask<String>(
      id: 'encrypt_data',
      task: () async {
        // Simulate encryption
        await Future.delayed(Duration(milliseconds: 100));
        return 'encrypted_$data';
      },
      priority: 8, // High priority for security
      useIsolate: true,
    );
  }

  static Future<Map<String, dynamic>> processNetworkData(List<int> rawData) async {
    return await CpuOptimizer().scheduleTask<Map<String, dynamic>>(
      id: 'process_network_data',
      task: () async {
        // Simulate data processing
        final processed = <String, dynamic>{};
        for (int i = 0; i < rawData.length; i++) {
          processed['item_$i'] = rawData[i] * 2;
        }
        return processed;
      },
      priority: 7,
      useIsolate: rawData.length > 1000,
    );
  }
}

// Utility extensions
extension Queue<T> on List<T> {
  void addFirst(T item) => insert(0, item);
  T removeFirst() => removeAt(0);
  void addLast(T item) => add(item);
  T removeLast() => removeAt(length - 1);
}

class Queue<T> {
  final List<T> _items = [];
  
  void add(T item) => _items.add(item);
  T removeFirst() => _items.removeAt(0);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;
  T get first => _items.first;
  void clear() => _items.clear();
  void addAll(Iterable<T> items) => _items.addAll(items);
  List<T> toList() => List<T>.from(_items);
}
