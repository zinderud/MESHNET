// lib/utils/logger.dart - MESHNET Logging System
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Log levels for the MESHNET application
enum LogLevel {
  verbose(0, 'VERBOSE', '🔍'),
  debug(1, 'DEBUG', '🐛'),
  info(2, 'INFO', 'ℹ️'),
  warning(3, 'WARNING', '⚠️'),
  error(4, 'ERROR', '❌'),
  critical(5, 'CRITICAL', '🚨');

  const LogLevel(this.value, this.name, this.icon);
  
  final int value;
  final String name;
  final String icon;
}

/// Central logging system for MESHNET
class MeshLogger {
  static MeshLogger? _instance;
  static MeshLogger get instance => _instance ??= MeshLogger._internal();
  
  MeshLogger._internal();
  
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  final List<LogEntry> _logBuffer = [];
  static const int _maxBufferSize = 1000;
  bool _fileLoggingEnabled = false;
  String? _logFilePath;
  
  /// Set minimum log level
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }
  
  /// Enable file logging
  Future<void> enableFileLogging([String? customPath]) async {
    _fileLoggingEnabled = true;
    _logFilePath = customPath ?? await _getDefaultLogPath();
  }
  
  /// Disable file logging
  void disableFileLogging() {
    _fileLoggingEnabled = false;
    _logFilePath = null;
  }
  
  /// Log verbose message
  void v(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.verbose, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log debug message
  void d(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log info message
  void i(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning message
  void w(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log error message
  void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Log critical message
  void c(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  /// Internal logging method
  void _log(
    LogLevel level, 
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.value < _minLevel.value) return;
    
    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag ?? _getCallerTag(),
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
    
    // Add to buffer
    _addToBuffer(entry);
    
    // Console output
    _logToConsole(entry);
    
    // File output
    if (_fileLoggingEnabled) {
      _logToFile(entry);
    }
  }
  
  /// Add log entry to buffer
  void _addToBuffer(LogEntry entry) {
    _logBuffer.add(entry);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }
  
  /// Output log to console
  void _logToConsole(LogEntry entry) {
    final formattedMessage = _formatLogEntry(entry, includeTimestamp: false);
    
    if (kDebugMode) {
      print(formattedMessage);
    }
    
    // Also output errors to debugPrint for better visibility
    if (entry.level.value >= LogLevel.error.value) {
      debugPrint(formattedMessage);
    }
  }
  
  /// Output log to file
  Future<void> _logToFile(LogEntry entry) async {
    if (_logFilePath == null) return;
    
    try {
      final file = File(_logFilePath!);
      final formattedMessage = _formatLogEntry(entry, includeTimestamp: true);
      await file.writeAsString('$formattedMessage\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }
  
  /// Format log entry for output
  String _formatLogEntry(LogEntry entry, {bool includeTimestamp = true}) {
    final buffer = StringBuffer();
    
    if (includeTimestamp) {
      buffer.write('${_formatTimestamp(entry.timestamp)} ');
    }
    
    buffer.write('${entry.level.icon} ${entry.level.name}');
    
    if (entry.tag != null) {
      buffer.write(' [${entry.tag}]');
    }
    
    buffer.write(': ${entry.message}');
    
    if (entry.error != null) {
      buffer.write('\nError: ${entry.error}');
    }
    
    if (entry.stackTrace != null) {
      buffer.write('\nStack trace:\n${entry.stackTrace}');
    }
    
    return buffer.toString();
  }
  
  /// Format timestamp for log output
  String _formatTimestamp(DateTime timestamp) {
    return timestamp.toIso8601String();
  }
  
  /// Get caller tag from stack trace
  String _getCallerTag() {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');
      
      // Find the first frame that's not from the logger
      for (final frame in frames) {
        if (!frame.contains('logger.dart') && 
            !frame.contains('Logger') &&
            frame.contains('package:')) {
          final match = RegExp(r'package:[\w_]+/([\w_]+)\.dart').firstMatch(frame);
          if (match != null) {
            return match.group(1) ?? 'Unknown';
          }
        }
      }
    } catch (e) {
      // Ignore errors in tag extraction
    }
    
    return 'Unknown';
  }
  
  /// Get default log file path
  Future<String> _getDefaultLogPath() async {
    // This would need to be implemented based on platform
    // For now, return a generic path
    return 'meshnet.log';
  }
  
  /// Get recent log entries
  List<LogEntry> getRecentLogs({int? limit, LogLevel? minLevel}) {
    var filtered = _logBuffer;
    
    if (minLevel != null) {
      filtered = filtered.where((entry) => entry.level.value >= minLevel.value).toList();
    }
    
    if (limit != null && filtered.length > limit) {
      filtered = filtered.sublist(filtered.length - limit);
    }
    
    return List.from(filtered);
  }
  
  /// Clear log buffer
  void clearBuffer() {
    _logBuffer.clear();
  }
  
  /// Export logs as JSON
  String exportLogsAsJson({LogLevel? minLevel}) {
    final logsToExport = getRecentLogs(minLevel: minLevel);
    final jsonList = logsToExport.map((entry) => entry.toJson()).toList();
    return jsonEncode(jsonList);
  }
  
  /// Get log statistics
  Map<String, int> getLogStats() {
    final stats = <String, int>{};
    for (final level in LogLevel.values) {
      stats[level.name] = _logBuffer.where((entry) => entry.level == level).length;
    }
    return stats;
  }
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  const LogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  /// Create from JSON
  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      error: json['error'],
      stackTrace: json['stackTrace'] != null 
          ? StackTrace.fromString(json['stackTrace']) 
          : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Global logger instance for convenience
final logger = MeshLogger.instance;

/// Service-specific logger mixins
mixin BluetoothLogger {
  void logBluetooth(String message, {LogLevel level = LogLevel.info}) {
    logger._log(level, message, tag: 'Bluetooth');
  }
}

mixin WiFiDirectLogger {
  void logWiFiDirect(String message, {LogLevel level = LogLevel.info}) {
    logger._log(level, message, tag: 'WiFiDirect');
  }
}

mixin EmergencyLogger {
  void logEmergency(String message, {LogLevel level = LogLevel.info}) {
    logger._log(level, message, tag: 'Emergency');
  }
}

mixin LocationLogger {
  void logLocation(String message, {LogLevel level = LogLevel.info}) {
    logger._log(level, message, tag: 'Location');
  }
}

mixin SDRLogger {
  void logSDR(String message, {LogLevel level = LogLevel.info}) {
    logger._log(level, message, tag: 'SDR');
  }
}

mixin HamRadioLogger {
  void logHamRadio(String message, {LogLevel level = LogLevel.info}) {
    logger._log(level, message, tag: 'HamRadio');
  }
}

/// Network activity logger
class NetworkActivityLogger {
  static void logMessageSent(String messageId, String protocol, int size) {
    logger.i('Message sent: $messageId via $protocol (${size} bytes)', tag: 'Network');
  }
  
  static void logMessageReceived(String messageId, String protocol, int size) {
    logger.i('Message received: $messageId via $protocol (${size} bytes)', tag: 'Network');
  }
  
  static void logConnectionEstablished(String peerId, String protocol) {
    logger.i('Connection established: $peerId via $protocol', tag: 'Network');
  }
  
  static void logConnectionLost(String peerId, String protocol, String reason) {
    logger.w('Connection lost: $peerId via $protocol - $reason', tag: 'Network');
  }
  
  static void logPeerDiscovered(String peerId, String protocol) {
    logger.i('Peer discovered: $peerId via $protocol', tag: 'Network');
  }
}

/// Emergency activity logger
class EmergencyActivityLogger {
  static void logEmergencyActivated(String type, String level) {
    logger.c('Emergency activated: $type - $level', tag: 'Emergency');
  }
  
  static void logEmergencyDeactivated() {
    logger.i('Emergency mode deactivated', tag: 'Emergency');
  }
  
  static void logBeaconSent(String beaconId) {
    logger.i('Emergency beacon sent: $beaconId', tag: 'Emergency');
  }
  
  static void logLocationShared(String emergencyId, double lat, double lng) {
    logger.i('Emergency location shared: $emergencyId at $lat, $lng', tag: 'Emergency');
  }
}
