// lib/services/performance_monitor.dart - Performans İzleme Servisi
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:meshnet_app/utils/logger.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance metrics
  final Map<String, List<double>> _metrics = {};
  final Map<String, DateTime> _startTimes = {};
  Timer? _reportTimer;
  
  // Memory tracking
  int _peakMemoryUsage = 0;
  int _currentMemoryUsage = 0;
  
  // CPU tracking
  double _cpuUsage = 0.0;
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  
  // Network tracking
  int _bytesTransmitted = 0;
  int _bytesReceived = 0;
  int _messagesSent = 0;
  int _messagesReceived = 0;
  
  void initialize() {
    Logger.info('Performance Monitor initialized');
    
    // Start periodic reporting
    _reportTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _generatePerformanceReport();
    });
    
    // Initialize frame rate monitoring
    if (kDebugMode) {
      _startFrameRateMonitoring();
    }
  }

  void dispose() {
    _reportTimer?.cancel();
    Logger.info('Performance Monitor disposed');
  }

  // Timing functions
  void startTimer(String operation) {
    _startTimes[operation] = DateTime.now();
  }

  void endTimer(String operation) {
    final startTime = _startTimes.remove(operation);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMicroseconds / 1000.0;
      _recordMetric(operation, duration);
      
      if (duration > 100) { // Log slow operations (>100ms)
        Logger.warning('Slow operation: $operation took ${duration.toStringAsFixed(2)}ms');
      }
    }
  }

  // Memory tracking
  void recordMemoryUsage(int bytes) {
    _currentMemoryUsage = bytes;
    if (bytes > _peakMemoryUsage) {
      _peakMemoryUsage = bytes;
    }
    _recordMetric('memory_usage_mb', bytes / (1024 * 1024));
  }

  // CPU tracking
  void recordCpuUsage(double percentage) {
    _cpuUsage = percentage;
    _recordMetric('cpu_usage_percent', percentage);
  }

  // Network tracking
  void recordNetworkTraffic({
    int? bytesSent,
    int? bytesReceived,
    int? messagesSent,
    int? messagesReceived,
  }) {
    if (bytesSent != null) {
      _bytesTransmitted += bytesSent;
      _recordMetric('network_bytes_sent', bytesSent.toDouble());
    }
    if (bytesReceived != null) {
      _bytesReceived += bytesReceived;
      _recordMetric('network_bytes_received', bytesReceived.toDouble());
    }
    if (messagesSent != null) {
      _messagesSent += messagesSent;
      _recordMetric('messages_sent', messagesSent.toDouble());
    }
    if (messagesReceived != null) {
      _messagesReceived += messagesReceived;
      _recordMetric('messages_received', messagesReceived.toDouble());
    }
  }

  // Frame rate monitoring
  void _startFrameRateMonitoring() {
    Timer.periodic(Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFrameTime).inMilliseconds;
      
      if (timeDiff > 0) {
        final fps = _frameCount * 1000 / timeDiff;
        _recordMetric('fps', fps);
        
        if (fps < 30) {
          Logger.warning('Low FPS detected: ${fps.toStringAsFixed(1)}');
        }
      }
      
      _frameCount = 0;
      _lastFrameTime = now;
    });
  }

  void recordFrame() {
    _frameCount++;
  }

  // Metric recording
  void _recordMetric(String name, double value) {
    _metrics.putIfAbsent(name, () => <double>[]);
    final values = _metrics[name]!;
    
    values.add(value);
    
    // Keep only last 100 values
    if (values.length > 100) {
      values.removeAt(0);
    }
  }

  // Performance analysis
  Map<String, double> getMetricStatistics(String metricName) {
    final values = _metrics[metricName];
    if (values == null || values.isEmpty) {
      return {};
    }

    values.sort();
    final len = values.length;
    
    return {
      'min': values.first,
      'max': values.last,
      'avg': values.reduce((a, b) => a + b) / len,
      'median': len.isOdd ? values[len ~/ 2] : (values[len ~/ 2 - 1] + values[len ~/ 2]) / 2,
      'p95': values[(len * 0.95).floor()],
      'p99': values[(len * 0.99).floor()],
    };
  }

  // Emergency mode detection
  bool isPerformanceCritical() {
    final memoryStats = getMetricStatistics('memory_usage_mb');
    final cpuStats = getMetricStatistics('cpu_usage_percent');
    final fpsStats = getMetricStatistics('fps');
    
    return (memoryStats['avg'] ?? 0) > 500 || // >500MB memory
           (cpuStats['avg'] ?? 0) > 80 ||      // >80% CPU
           (fpsStats['avg'] ?? 60) < 15;       // <15 FPS
  }

  // Performance optimization recommendations
  List<String> getOptimizationRecommendations() {
    final recommendations = <String>[];
    
    final memoryStats = getMetricStatistics('memory_usage_mb');
    final cpuStats = getMetricStatistics('cpu_usage_percent');
    final fpsStats = getMetricStatistics('fps');
    
    if ((memoryStats['avg'] ?? 0) > 300) {
      recommendations.add('High memory usage detected. Consider reducing cache sizes.');
    }
    
    if ((cpuStats['avg'] ?? 0) > 60) {
      recommendations.add('High CPU usage detected. Consider optimizing algorithms or reducing background tasks.');
    }
    
    if ((fpsStats['avg'] ?? 60) < 30) {
      recommendations.add('Low frame rate detected. Consider reducing UI complexity or animations.');
    }
    
    final networkLatency = getMetricStatistics('message_processing_time');
    if ((networkLatency['avg'] ?? 0) > 1000) {
      recommendations.add('High network latency detected. Consider optimizing message processing.');
    }
    
    return recommendations;
  }

  // Performance report generation
  void _generatePerformanceReport() {
    final report = StringBuffer();
    report.writeln('=== Performance Report ===');
    report.writeln('Timestamp: ${DateTime.now()}');
    report.writeln('');
    
    // System metrics
    report.writeln('System Metrics:');
    report.writeln('  Memory Usage: ${(_currentMemoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB');
    report.writeln('  Peak Memory: ${(_peakMemoryUsage / (1024 * 1024)).toStringAsFixed(1)} MB');
    report.writeln('  CPU Usage: ${_cpuUsage.toStringAsFixed(1)}%');
    report.writeln('');
    
    // Network metrics
    report.writeln('Network Metrics:');
    report.writeln('  Bytes Transmitted: ${(_bytesTransmitted / 1024).toStringAsFixed(1)} KB');
    report.writeln('  Bytes Received: ${(_bytesReceived / 1024).toStringAsFixed(1)} KB');
    report.writeln('  Messages Sent: $_messagesSent');
    report.writeln('  Messages Received: $_messagesReceived');
    report.writeln('');
    
    // Performance metrics
    for (final metricName in _metrics.keys) {
      final stats = getMetricStatistics(metricName);
      if (stats.isNotEmpty) {
        report.writeln('$metricName:');
        report.writeln('  Average: ${stats['avg']?.toStringAsFixed(2)}');
        report.writeln('  95th percentile: ${stats['p95']?.toStringAsFixed(2)}');
      }
    }
    
    // Recommendations
    final recommendations = getOptimizationRecommendations();
    if (recommendations.isNotEmpty) {
      report.writeln('');
      report.writeln('Optimization Recommendations:');
      for (final rec in recommendations) {
        report.writeln('  - $rec');
      }
    }
    
    Logger.info(report.toString());
  }

  // Real-time performance data for UI
  Map<String, dynamic> getCurrentPerformanceData() {
    return {
      'memory_mb': (_currentMemoryUsage / (1024 * 1024)).toStringAsFixed(1),
      'peak_memory_mb': (_peakMemoryUsage / (1024 * 1024)).toStringAsFixed(1),
      'cpu_percent': _cpuUsage.toStringAsFixed(1),
      'bytes_transmitted_kb': (_bytesTransmitted / 1024).toStringAsFixed(1),
      'bytes_received_kb': (_bytesReceived / 1024).toStringAsFixed(1),
      'messages_sent': _messagesSent,
      'messages_received': _messagesReceived,
      'is_critical': isPerformanceCritical(),
      'recommendations': getOptimizationRecommendations(),
    };
  }

  // Get specific metric for monitoring
  double? getLatestMetric(String metricName) {
    final values = _metrics[metricName];
    return values?.isNotEmpty == true ? values!.last : null;
  }
}

// Performance measurement decorator
class PerformanceMeasurement {
  static Future<T> measure<T>(String operation, Future<T> Function() function) async {
    final monitor = PerformanceMonitor();
    monitor.startTimer(operation);
    
    try {
      final result = await function();
      return result;
    } finally {
      monitor.endTimer(operation);
    }
  }

  static T measureSync<T>(String operation, T Function() function) {
    final monitor = PerformanceMonitor();
    monitor.startTimer(operation);
    
    try {
      return function();
    } finally {
      monitor.endTimer(operation);
    }
  }
}
