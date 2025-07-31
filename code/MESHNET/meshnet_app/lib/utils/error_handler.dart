// lib/utils/error_handler.dart - Global Error Handler for MESHNET
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'logger.dart';
import 'constants.dart';

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Error categories for better handling
enum ErrorCategory {
  network,
  bluetooth,
  wifi,
  emergency,
  location,
  security,
  storage,
  ui,
  system,
}

/// Custom error class for MESHNET
class MeshNetError extends Error {
  final String message;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String? code;
  final Map<String, dynamic>? context;
  final DateTime timestamp;

  MeshNetError({
    required this.message,
    required this.category,
    this.severity = ErrorSeverity.medium,
    this.code,
    this.context,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'MeshNetError($category/${severity.name}): $message${code != null ? ' [$code]' : ''}';
  }

  /// Convert to JSON for logging/reporting
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'category': category.name,
      'severity': severity.name,
      'code': code,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// Global error handler for the MESHNET application
class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance => _instance ??= GlobalErrorHandler._internal();
  
  GlobalErrorHandler._internal();
  
  final List<ErrorEntry> _errorHistory = [];
  static const int _maxErrorHistory = 100;
  
  /// Error callbacks for different categories
  final Map<ErrorCategory, List<ErrorCallback>> _categoryCallbacks = {};
  
  /// Global error callback
  ErrorCallback? _globalCallback;
  
  /// Initialize the global error handler
  void initialize() {
    // Set Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      handleFlutterError(details);
    };
    
    // Set zone error handler for async errors
    if (kDebugMode) {
      // In debug mode, let Flutter handle errors normally
      return;
    }
    
    // In release mode, catch and handle async errors
    _setupAsyncErrorHandling();
  }
  
  /// Handle Flutter framework errors
  void handleFlutterError(FlutterErrorDetails details) {
    final error = MeshNetError(
      message: details.summary.toString(),
      category: ErrorCategory.ui,
      severity: _determineSeverityFromFlutterError(details),
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
    
    _recordError(error, details.stack);
    _notifyCallbacks(error);
    
    // Log the error
    logger.e(
      'Flutter Error: ${details.summary}',
      tag: 'ErrorHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
    
    // In debug mode, also call the default error handler
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }
  
  /// Handle general errors
  void handleError(
    Object error, {
    StackTrace? stackTrace,
    ErrorCategory category = ErrorCategory.system,
    ErrorSeverity? severity,
    String? code,
    Map<String, dynamic>? context,
  }) {
    final meshError = error is MeshNetError
        ? error
        : MeshNetError(
            message: error.toString(),
            category: category,
            severity: severity ?? _determineSeverityFromError(error),
            code: code,
            context: context,
          );
    
    _recordError(meshError, stackTrace);
    _notifyCallbacks(meshError);
    
    // Log the error
    final logLevel = _getLogLevelForSeverity(meshError.severity);
    logger._log(
      logLevel,
      'Error handled: ${meshError.message}',
      tag: 'ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Handle network errors specifically
  void handleNetworkError(
    Object error, {
    StackTrace? stackTrace,
    String? protocol,
    String? operation,
  }) {
    handleError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.network,
      context: {
        'protocol': protocol,
        'operation': operation,
      },
    );
  }
  
  /// Handle emergency errors specifically
  void handleEmergencyError(
    Object error, {
    StackTrace? stackTrace,
    String? emergencyType,
    String? action,
  }) {
    handleError(
      error,
      stackTrace: stackTrace,
      category: ErrorCategory.emergency,
      severity: ErrorSeverity.high, // Emergency errors are always high severity
      context: {
        'emergencyType': emergencyType,
        'action': action,
      },
    );
  }
  
  /// Register callback for specific error category
  void registerCategoryCallback(ErrorCategory category, ErrorCallback callback) {
    _categoryCallbacks.putIfAbsent(category, () => []).add(callback);
  }
  
  /// Register global callback for all errors
  void registerGlobalCallback(ErrorCallback callback) {
    _globalCallback = callback;
  }
  
  /// Get recent errors
  List<ErrorEntry> getRecentErrors({
    int? limit,
    ErrorCategory? category,
    ErrorSeverity? minSeverity,
  }) {
    var filtered = _errorHistory;
    
    if (category != null) {
      filtered = filtered.where((entry) => entry.error.category == category).toList();
    }
    
    if (minSeverity != null) {
      filtered = filtered.where((entry) => 
          entry.error.severity.index >= minSeverity.index).toList();
    }
    
    if (limit != null && filtered.length > limit) {
      filtered = filtered.sublist(filtered.length - limit);
    }
    
    return List.from(filtered.reversed);
  }
  
  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    final stats = <String, dynamic>{};
    
    // Count by category
    final categoryStats = <String, int>{};
    for (final category in ErrorCategory.values) {
      categoryStats[category.name] = _errorHistory
          .where((entry) => entry.error.category == category)
          .length;
    }
    stats['byCategory'] = categoryStats;
    
    // Count by severity
    final severityStats = <String, int>{};
    for (final severity in ErrorSeverity.values) {
      severityStats[severity.name] = _errorHistory
          .where((entry) => entry.error.severity == severity)
          .length;
    }
    stats['bySeverity'] = severityStats;
    
    // Recent errors (last hour)
    final recentErrors = _errorHistory.where((entry) =>
        DateTime.now().difference(entry.error.timestamp).inHours < 1).length;
    stats['recentErrors'] = recentErrors;
    
    stats['totalErrors'] = _errorHistory.length;
    
    return stats;
  }
  
  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }
  
  /// Export errors for debugging
  String exportErrors() {
    final errorList = _errorHistory.map((entry) => {
      ...entry.error.toJson(),
      'stackTrace': entry.stackTrace?.toString(),
    }).toList();
    
    return '''
MESHNET Error Report
Generated: ${DateTime.now().toIso8601String()}
Total Errors: ${_errorHistory.length}

${errorList.map((e) => '''
[${e['timestamp']}] ${e['category']}/${e['severity']}: ${e['message']}
${e['code'] != null ? 'Code: ${e['code']}\n' : ''}${e['context'] != null ? 'Context: ${e['context']}\n' : ''}${e['stackTrace'] != null ? 'Stack Trace:\n${e['stackTrace']}\n' : ''}
''').join('\n---\n')}
''';
  }
  
  /// Record error in history
  void _recordError(MeshNetError error, StackTrace? stackTrace) {
    _errorHistory.add(ErrorEntry(error: error, stackTrace: stackTrace));
    
    // Keep history size manageable
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }
  
  /// Notify registered callbacks
  void _notifyCallbacks(MeshNetError error) {
    // Notify category-specific callbacks
    final categoryCallbacks = _categoryCallbacks[error.category] ?? [];
    for (final callback in categoryCallbacks) {
      try {
        callback(error);
      } catch (e) {
        // Don't let callback errors crash the error handler
        logger.e('Error in callback: $e', tag: 'ErrorHandler');
      }
    }
    
    // Notify global callback
    if (_globalCallback != null) {
      try {
        _globalCallback!(error);
      } catch (e) {
        logger.e('Error in global callback: $e', tag: 'ErrorHandler');
      }
    }
  }
  
  /// Determine severity from Flutter error
  ErrorSeverity _determineSeverityFromFlutterError(FlutterErrorDetails details) {
    final summary = details.summary.toString().toLowerCase();
    
    if (summary.contains('renderflex') || summary.contains('overflow')) {
      return ErrorSeverity.low;
    }
    
    if (summary.contains('assertion') || summary.contains('state')) {
      return ErrorSeverity.medium;
    }
    
    return ErrorSeverity.high;
  }
  
  /// Determine severity from general error
  ErrorSeverity _determineSeverityFromError(Object error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('timeout') || message.contains('network')) {
      return ErrorSeverity.medium;
    }
    
    if (message.contains('permission') || message.contains('security')) {
      return ErrorSeverity.high;
    }
    
    if (message.contains('emergency') || message.contains('critical')) {
      return ErrorSeverity.critical;
    }
    
    return ErrorSeverity.medium;
  }
  
  /// Get log level for error severity
  LogLevel _getLogLevelForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return LogLevel.warning;
      case ErrorSeverity.medium:
        return LogLevel.error;
      case ErrorSeverity.high:
        return LogLevel.error;
      case ErrorSeverity.critical:
        return LogLevel.critical;
    }
  }
  
  /// Setup async error handling
  void _setupAsyncErrorHandling() {
    // This would be implemented with runZonedGuarded in main.dart
    // For now, just document the approach
  }
}

/// Error entry for history tracking
class ErrorEntry {
  final MeshNetError error;
  final StackTrace? stackTrace;
  
  const ErrorEntry({
    required this.error,
    this.stackTrace,
  });
}

/// Callback type for error handling
typedef ErrorCallback = void Function(MeshNetError error);

/// Convenience methods for common error scenarios
class ErrorHelper {
  /// Create network error
  static MeshNetError networkError(String message, {String? code}) {
    return MeshNetError(
      message: message,
      category: ErrorCategory.network,
      severity: ErrorSeverity.medium,
      code: code,
    );
  }
  
  /// Create emergency error
  static MeshNetError emergencyError(String message, {String? code}) {
    return MeshNetError(
      message: message,
      category: ErrorCategory.emergency,
      severity: ErrorSeverity.high,
      code: code,
    );
  }
  
  /// Create security error
  static MeshNetError securityError(String message, {String? code}) {
    return MeshNetError(
      message: message,
      category: ErrorCategory.security,
      severity: ErrorSeverity.high,
      code: code,
    );
  }
  
  /// Create storage error
  static MeshNetError storageError(String message, {String? code}) {
    return MeshNetError(
      message: message,
      category: ErrorCategory.storage,
      severity: ErrorSeverity.medium,
      code: code,
    );
  }
}

/// Global error handler instance
final errorHandler = GlobalErrorHandler.instance;

/// Widget for displaying errors to users
class ErrorDisplayWidget extends StatelessWidget {
  final MeshNetError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDisplayWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getColorForSeverity(error.severity),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.PADDING_MEDIUM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForCategory(error.category),
                  color: Colors.white,
                ),
                const SizedBox(width: UIConstants.PADDING_SMALL),
                Expanded(
                  child: Text(
                    _getCategoryDisplayName(error.category),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: UIConstants.PADDING_SMALL),
            Text(
              error.message,
              style: const TextStyle(color: Colors.white),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: UIConstants.PADDING_MEDIUM),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.deepOrange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getIconForCategory(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return Icons.signal_wifi_off;
      case ErrorCategory.bluetooth:
        return Icons.bluetooth_disabled;
      case ErrorCategory.wifi:
        return Icons.wifi_off;
      case ErrorCategory.emergency:
        return Icons.emergency;
      case ErrorCategory.location:
        return Icons.location_off;
      case ErrorCategory.security:
        return Icons.security;
      case ErrorCategory.storage:
        return Icons.storage;
      case ErrorCategory.ui:
        return Icons.error;
      case ErrorCategory.system:
        return Icons.warning;
    }
  }

  String _getCategoryDisplayName(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return 'Network Error';
      case ErrorCategory.bluetooth:
        return 'Bluetooth Error';
      case ErrorCategory.wifi:
        return 'WiFi Error';
      case ErrorCategory.emergency:
        return 'Emergency Error';
      case ErrorCategory.location:
        return 'Location Error';
      case ErrorCategory.security:
        return 'Security Error';
      case ErrorCategory.storage:
        return 'Storage Error';
      case ErrorCategory.ui:
        return 'Interface Error';
      case ErrorCategory.system:
        return 'System Error';
    }
  }
}
