// lib/services/network_optimizer.dart - Ağ Performans Optimizasyon Servisi
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:meshnet_app/utils/logger.dart';
import 'package:meshnet_app/services/performance_monitor.dart';
import 'package:meshnet_app/services/memory_optimizer.dart';

class NetworkOptimizer {
  static final NetworkOptimizer _instance = NetworkOptimizer._internal();
  factory NetworkOptimizer() => _instance;
  NetworkOptimizer._internal();

  // Connection management
  final Map<String, NetworkConnection> _connections = {};
  final Queue<NetworkRequest> _requestQueue = Queue<NetworkRequest>();
  final Map<String, Timer> _connectionTimers = {};
  
  // Bandwidth management
  final Map<String, BandwidthTracker> _bandwidthTrackers = {};
  int _currentBandwidthLimit = 0; // bytes per second
  int _priorityBandwidthReserved = 0;
  
  // Request optimization
  final Map<String, Uint8List> _responseCache = {};
  final Queue<String> _cacheKeys = Queue<String>();
  static const int maxCacheSize = 50;
  static const Duration cacheExpiry = Duration(minutes: 5);
  
  // Connection pooling
  final Map<String, List<HttpClient>> _httpClientPools = {};
  static const int maxConnectionsPerHost = 6;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration keepAliveTimeout = Duration(seconds: 30);
  
  // Retry mechanisms
  final Map<String, RetryConfig> _retryConfigs = {};
  final Map<String, int> _retryAttempts = {};
  
  // Performance metrics
  final Map<String, NetworkMetrics> _networkMetrics = {};
  Timer? _metricsTimer;

  void initialize() {
    Logger.info('Network Optimizer initialized');
    _startMetricsCollection();
    _setupDefaultRetryConfigs();
    _startConnectionPoolCleanup();
  }

  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _collectNetworkMetrics();
      _optimizeConnections();
    });
  }

  void _setupDefaultRetryConfigs() {
    // Emergency messages - high priority, aggressive retry
    _retryConfigs['emergency'] = RetryConfig(
      maxAttempts: 5,
      baseDelay: Duration(milliseconds: 100),
      maxDelay: Duration(seconds: 2),
      backoffMultiplier: 1.5,
    );
    
    // Regular messages - medium priority
    _retryConfigs['regular'] = RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 5),
      backoffMultiplier: 2.0,
    );
    
    // File transfers - low priority, patient retry
    _retryConfigs['file'] = RetryConfig(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 10),
      backoffMultiplier: 2.0,
    );
  }

  void _startConnectionPoolCleanup() {
    Timer.periodic(const Duration(minutes: 2), (timer) {
      _cleanupConnectionPools();
    });
  }

  // Connection Management
  Future<NetworkConnection> getConnection(String host, {
    required String protocol,
    int? port,
    bool isSecure = false,
    int priority = 5,
  }) async {
    final connectionId = '$protocol://$host:${port ?? (isSecure ? 443 : 80)}';
    
    // Check existing connection
    if (_connections.containsKey(connectionId)) {
      final connection = _connections[connectionId]!;
      if (connection.isActive && !connection.isOverloaded) {
        return connection;
      }
    }
    
    // Create new connection
    final connection = await _createConnection(
      connectionId,
      host,
      port ?? (isSecure ? 443 : 80),
      protocol,
      isSecure,
      priority,
    );
    
    _connections[connectionId] = connection;
    Logger.debug('New connection created: $connectionId');
    
    return connection;
  }

  Future<NetworkConnection> _createConnection(
    String id,
    String host,
    int port,
    String protocol,
    bool isSecure,
    int priority,
  ) async {
    final connection = NetworkConnection(
      id: id,
      host: host,
      port: port,
      protocol: protocol,
      isSecure: isSecure,
      priority: priority,
      createdAt: DateTime.now(),
    );
    
    // Initialize connection based on protocol
    switch (protocol.toLowerCase()) {
      case 'http':
      case 'https':
        await _initializeHttpConnection(connection);
        break;
      case 'tcp':
        await _initializeTcpConnection(connection);
        break;
      case 'udp':
        await _initializeUdpConnection(connection);
        break;
      case 'bluetooth':
        await _initializeBluetoothConnection(connection);
        break;
      case 'wifi-direct':
        await _initializeWifiDirectConnection(connection);
        break;
    }
    
    return connection;
  }

  Future<void> _initializeHttpConnection(NetworkConnection connection) async {
    final client = HttpClient();
    client.connectionTimeout = connectionTimeout;
    client.idleTimeout = keepAliveTimeout;
    
    // Add to connection pool
    final host = connection.host;
    _httpClientPools.putIfAbsent(host, () => []);
    
    if (_httpClientPools[host]!.length < maxConnectionsPerHost) {
      _httpClientPools[host]!.add(client);
    }
    
    connection.client = client;
  }

  Future<void> _initializeTcpConnection(NetworkConnection connection) async {
    try {
      final socket = await Socket.connect(
        connection.host,
        connection.port,
        timeout: connectionTimeout,
      );
      connection.socket = socket;
    } catch (e) {
      Logger.error('Failed to create TCP connection', error: e);
      rethrow;
    }
  }

  Future<void> _initializeUdpConnection(NetworkConnection connection) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      connection.datagramSocket = socket;
    } catch (e) {
      Logger.error('Failed to create UDP connection', error: e);
      rethrow;
    }
  }

  Future<void> _initializeBluetoothConnection(NetworkConnection connection) async {
    // Bluetooth connection initialization
    // This would integrate with platform-specific Bluetooth APIs
    Logger.debug('Initializing Bluetooth connection: ${connection.id}');
  }

  Future<void> _initializeWifiDirectConnection(NetworkConnection connection) async {
    // WiFi Direct connection initialization
    // This would integrate with platform-specific WiFi Direct APIs
    Logger.debug('Initializing WiFi Direct connection: ${connection.id}');
  }

  // Request Management
  Future<NetworkResponse> sendRequest(NetworkRequest request) async {
    // Add to queue for bandwidth management
    _requestQueue.add(request);
    
    // Check cache first
    if (request.cacheKey != null) {
      final cachedResponse = _getCachedResponse(request.cacheKey!);
      if (cachedResponse != null) {
        Logger.debug('Returning cached response for ${request.cacheKey}');
        return cachedResponse;
      }
    }
    
    // Execute request with optimization
    final response = await _executeRequest(request);
    
    // Cache response if appropriate
    if (request.cacheKey != null && response.isSuccessful) {
      _cacheResponse(request.cacheKey!, response);
    }
    
    return response;
  }

  Future<NetworkResponse> _executeRequest(NetworkRequest request) async {
    final connection = await getConnection(
      request.host,
      protocol: request.protocol,
      port: request.port,
      isSecure: request.isSecure,
      priority: request.priority,
    );
    
    final stopwatch = Stopwatch()..start();
    NetworkResponse? response;
    
    try {
      // Bandwidth throttling
      await _waitForBandwidth(request);
      
      // Execute based on protocol
      switch (request.protocol.toLowerCase()) {
        case 'http':
        case 'https':
          response = await _executeHttpRequest(connection, request);
          break;
        case 'tcp':
          response = await _executeTcpRequest(connection, request);
          break;
        case 'udp':
          response = await _executeUdpRequest(connection, request);
          break;
        default:
          throw UnsupportedError('Protocol ${request.protocol} not supported');
      }
      
      stopwatch.stop();
      
      // Record metrics
      _recordRequestMetrics(request, response, stopwatch.elapsedMilliseconds);
      
      return response;
      
    } catch (e) {
      stopwatch.stop();
      Logger.error('Request failed: ${request.url}', error: e);
      
      // Retry if configured
      if (_shouldRetry(request, e)) {
        return await _retryRequest(request);
      }
      
      throw e;
    }
  }

  Future<NetworkResponse> _executeHttpRequest(NetworkConnection connection, NetworkRequest request) async {
    final client = connection.client as HttpClient;
    
    final uri = Uri.parse(request.url);
    final httpRequest = await client.openUrl(request.method, uri);
    
    // Add headers
    request.headers.forEach((key, value) {
      httpRequest.headers.set(key, value);
    });
    
    // Add body if present
    if (request.body != null) {
      httpRequest.add(request.body!);
    }
    
    final httpResponse = await httpRequest.close();
    final responseBody = await httpResponse.expand((chunk) => chunk).toList();
    
    return NetworkResponse(
      statusCode: httpResponse.statusCode,
      headers: Map<String, String>.from(httpResponse.headers.map(
        (key, values) => MapEntry(key, values.join(', ')),
      )),
      body: Uint8List.fromList(responseBody),
      responseTime: DateTime.now(),
    );
  }

  Future<NetworkResponse> _executeTcpRequest(NetworkConnection connection, NetworkRequest request) async {
    final socket = connection.socket as Socket;
    
    if (request.body != null) {
      socket.add(request.body!);
      await socket.flush();
    }
    
    final completer = Completer<List<int>>();
    final data = <int>[];
    
    socket.listen(
      (response) {
        data.addAll(response);
      },
      onDone: () {
        completer.complete(data);
      },
      onError: (error) {
        completer.completeError(error);
      },
    );
    
    final responseData = await completer.future.timeout(Duration(seconds: 30));
    
    return NetworkResponse(
      statusCode: 200, // TCP doesn't have status codes
      headers: {},
      body: Uint8List.fromList(responseData),
      responseTime: DateTime.now(),
    );
  }

  Future<NetworkResponse> _executeUdpRequest(NetworkConnection connection, NetworkRequest request) async {
    final socket = connection.datagramSocket as RawDatagramSocket;
    
    if (request.body != null) {
      final address = InternetAddress(request.host);
      socket.send(request.body!, address, request.port ?? 8080);
    }
    
    final completer = Completer<List<int>>();
    late StreamSubscription subscription;
    
    subscription = socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          completer.complete(datagram.data);
          subscription.cancel();
        }
      }
    });
    
    final responseData = await completer.future.timeout(Duration(seconds: 10));
    
    return NetworkResponse(
      statusCode: 200, // UDP doesn't have status codes
      headers: {},
      body: Uint8List.fromList(responseData),
      responseTime: DateTime.now(),
    );
  }

  // Bandwidth Management
  Future<void> _waitForBandwidth(NetworkRequest request) async {
    if (_currentBandwidthLimit <= 0) return;
    
    final requiredBandwidth = request.estimatedSize ?? 1024;
    final tracker = _getBandwidthTracker(request.host);
    
    while (tracker.getCurrentUsage() + requiredBandwidth > _currentBandwidthLimit) {
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    tracker.reserveBandwidth(requiredBandwidth);
  }

  BandwidthTracker _getBandwidthTracker(String host) {
    return _bandwidthTrackers.putIfAbsent(host, () => BandwidthTracker());
  }

  void setBandwidthLimit(int bytesPerSecond, {int? priorityReserved}) {
    _currentBandwidthLimit = bytesPerSecond;
    _priorityBandwidthReserved = priorityReserved ?? (bytesPerSecond * 0.3).toInt();
    Logger.info('Bandwidth limit set to ${bytesPerSecond ~/ 1024}KB/s');
  }

  // Caching
  NetworkResponse? _getCachedResponse(String key) {
    final cached = _responseCache[key];
    if (cached != null) {
      // Check if cache is still valid (simplified)
      return NetworkResponse.fromCached(cached);
    }
    return null;
  }

  void _cacheResponse(String key, NetworkResponse response) {
    if (_responseCache.length >= maxCacheSize) {
      final oldestKey = _cacheKeys.removeFirst();
      _responseCache.remove(oldestKey);
    }
    
    _responseCache[key] = response.body;
    _cacheKeys.add(key);
  }

  // Retry Logic
  bool _shouldRetry(NetworkRequest request, dynamic error) {
    final config = _retryConfigs[request.type] ?? _retryConfigs['regular']!;
    final attempts = _retryAttempts[request.id] ?? 0;
    
    if (attempts >= config.maxAttempts) {
      return false;
    }
    
    // Check if error is retryable
    if (error is SocketException || 
        error is TimeoutException ||
        (error is HttpException && _isRetryableHttpError(error))) {
      return true;
    }
    
    return false;
  }

  bool _isRetryableHttpError(HttpException error) {
    final retryableStatuses = [500, 502, 503, 504, 408, 429];
    return retryableStatuses.any((status) => error.message.contains(status.toString()));
  }

  Future<NetworkResponse> _retryRequest(NetworkRequest request) async {
    final config = _retryConfigs[request.type] ?? _retryConfigs['regular']!;
    final attempts = _retryAttempts[request.id] ?? 0;
    
    _retryAttempts[request.id] = attempts + 1;
    
    final delay = _calculateRetryDelay(config, attempts);
    Logger.info('Retrying request ${request.id} after ${delay.inMilliseconds}ms (attempt ${attempts + 1})');
    
    await Future.delayed(delay);
    return await _executeRequest(request);
  }

  Duration _calculateRetryDelay(RetryConfig config, int attempts) {
    final delay = config.baseDelay * math.pow(config.backoffMultiplier, attempts);
    return Duration(
      milliseconds: math.min(delay.inMilliseconds, config.maxDelay.inMilliseconds).toInt(),
    );
  }

  // Metrics and Monitoring
  void _collectNetworkMetrics() {
    final totalConnections = _connections.length;
    final activeConnections = _connections.values.where((c) => c.isActive).length;
    final queuedRequests = _requestQueue.length;
    
    final performanceMonitor = PerformanceMonitor();
    performanceMonitor.recordCustomMetric('network_total_connections', totalConnections.toDouble());
    performanceMonitor.recordCustomMetric('network_active_connections', activeConnections.toDouble());
    performanceMonitor.recordCustomMetric('network_queued_requests', queuedRequests.toDouble());
    
    Logger.debug('Network metrics: connections=$totalConnections, active=$activeConnections, queued=$queuedRequests');
  }

  void _recordRequestMetrics(NetworkRequest request, NetworkResponse response, int responseTime) {
    final metrics = _networkMetrics.putIfAbsent(request.host, () => NetworkMetrics());
    
    metrics.totalRequests++;
    metrics.totalResponseTime += responseTime;
    metrics.totalBytes += response.body.length;
    
    if (response.isSuccessful) {
      metrics.successfulRequests++;
    } else {
      metrics.failedRequests++;
    }
    
    metrics.lastRequestTime = DateTime.now();
  }

  void _optimizeConnections() {
    // Close idle connections
    final now = DateTime.now();
    final toRemove = <String>[];
    
    for (final entry in _connections.entries) {
      final connection = entry.value;
      if (!connection.isActive || 
          now.difference(connection.lastUsed) > Duration(minutes: 5)) {
        toRemove.add(entry.key);
      }
    }
    
    for (final id in toRemove) {
      _closeConnection(id);
    }
  }

  void _closeConnection(String id) {
    final connection = _connections[id];
    if (connection != null) {
      connection.close();
      _connections.remove(id);
      Logger.debug('Connection closed: $id');
    }
  }

  void _cleanupConnectionPools() {
    for (final pool in _httpClientPools.values) {
      while (pool.length > maxConnectionsPerHost ~/ 2) {
        final client = pool.removeLast();
        client.close();
      }
    }
  }

  // Statistics and Recommendations
  Map<String, dynamic> getNetworkStats() {
    final stats = <String, dynamic>{
      'total_connections': _connections.length,
      'active_connections': _connections.values.where((c) => c.isActive).length,
      'queued_requests': _requestQueue.length,
      'cached_responses': _responseCache.length,
      'bandwidth_limit_kbps': _currentBandwidthLimit ~/ 1024,
      'retry_attempts': _retryAttempts.length,
    };
    
    // Add per-host metrics
    final hostMetrics = <String, Map<String, dynamic>>{};
    for (final entry in _networkMetrics.entries) {
      hostMetrics[entry.key] = entry.value.toMap();
    }
    stats['host_metrics'] = hostMetrics;
    
    return stats;
  }

  List<String> getNetworkOptimizationRecommendations() {
    final recommendations = <String>[];
    
    if (_connections.length > maxConnectionsPerHost * 2) {
      recommendations.add('Too many connections open. Consider connection pooling.');
    }
    
    if (_requestQueue.length > 20) {
      recommendations.add('Request queue is large. Consider increasing bandwidth or reducing requests.');
    }
    
    final failureRate = _calculateOverallFailureRate();
    if (failureRate > 0.1) {
      recommendations.add('High network failure rate (${(failureRate * 100).toStringAsFixed(1)}%). Check network stability.');
    }
    
    if (_responseCache.length < maxCacheSize * 0.5) {
      recommendations.add('Low cache utilization. Consider caching more responses.');
    }
    
    return recommendations;
  }

  double _calculateOverallFailureRate() {
    int totalRequests = 0;
    int failedRequests = 0;
    
    for (final metrics in _networkMetrics.values) {
      totalRequests += metrics.totalRequests;
      failedRequests += metrics.failedRequests;
    }
    
    return totalRequests > 0 ? failedRequests / totalRequests : 0.0;
  }

  void dispose() {
    _metricsTimer?.cancel();
    
    // Close all connections
    for (final connection in _connections.values) {
      connection.close();
    }
    _connections.clear();
    
    // Close all HTTP clients
    for (final pool in _httpClientPools.values) {
      for (final client in pool) {
        client.close();
      }
    }
    _httpClientPools.clear();
    
    // Cancel connection timers
    for (final timer in _connectionTimers.values) {
      timer.cancel();
    }
    _connectionTimers.clear();
    
    Logger.info('Network Optimizer disposed');
  }
}

// Supporting classes
class NetworkConnection {
  final String id;
  final String host;
  final int port;
  final String protocol;
  final bool isSecure;
  final int priority;
  final DateTime createdAt;
  DateTime lastUsed;
  
  dynamic client;
  Socket? socket;
  RawDatagramSocket? datagramSocket;
  
  bool isActive = true;
  bool isOverloaded = false;
  int requestCount = 0;

  NetworkConnection({
    required this.id,
    required this.host,
    required this.port,
    required this.protocol,
    required this.isSecure,
    required this.priority,
    required this.createdAt,
  }) : lastUsed = DateTime.now();

  void updateUsage() {
    lastUsed = DateTime.now();
    requestCount++;
  }

  void close() {
    isActive = false;
    socket?.close();
    datagramSocket?.close();
    if (client is HttpClient) {
      (client as HttpClient).close();
    }
  }
}

class NetworkRequest {
  final String id;
  final String url;
  final String host;
  final String protocol;
  final String method;
  final Map<String, String> headers;
  final Uint8List? body;
  final int? port;
  final bool isSecure;
  final int priority;
  final String type;
  final String? cacheKey;
  final int? estimatedSize;

  NetworkRequest({
    required this.id,
    required this.url,
    required this.host,
    required this.protocol,
    this.method = 'GET',
    this.headers = const {},
    this.body,
    this.port,
    this.isSecure = false,
    this.priority = 5,
    this.type = 'regular',
    this.cacheKey,
    this.estimatedSize,
  });
}

class NetworkResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List body;
  final DateTime responseTime;

  NetworkResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.responseTime,
  });

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  static NetworkResponse fromCached(Uint8List cachedData) {
    return NetworkResponse(
      statusCode: 200,
      headers: {'X-From-Cache': 'true'},
      body: cachedData,
      responseTime: DateTime.now(),
    );
  }
}

class BandwidthTracker {
  final Queue<BandwidthUsage> _usage = Queue<BandwidthUsage>();
  static const Duration trackingWindow = Duration(seconds: 1);

  void reserveBandwidth(int bytes) {
    _usage.add(BandwidthUsage(bytes, DateTime.now()));
    _cleanOldUsage();
  }

  int getCurrentUsage() {
    _cleanOldUsage();
    return _usage.fold<int>(0, (sum, usage) => sum + usage.bytes);
  }

  void _cleanOldUsage() {
    final cutoff = DateTime.now().subtract(trackingWindow);
    while (_usage.isNotEmpty && _usage.first.timestamp.isBefore(cutoff)) {
      _usage.removeFirst();
    }
  }
}

class BandwidthUsage {
  final int bytes;
  final DateTime timestamp;

  BandwidthUsage(this.bytes, this.timestamp);
}

class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  RetryConfig({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
  });
}

class NetworkMetrics {
  int totalRequests = 0;
  int successfulRequests = 0;
  int failedRequests = 0;
  int totalResponseTime = 0;
  int totalBytes = 0;
  DateTime? lastRequestTime;

  double get averageResponseTime => 
      totalRequests > 0 ? totalResponseTime / totalRequests : 0.0;
  
  double get successRate => 
      totalRequests > 0 ? successfulRequests / totalRequests : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'total_requests': totalRequests,
      'successful_requests': successfulRequests,
      'failed_requests': failedRequests,
      'average_response_time': averageResponseTime,
      'success_rate': successRate,
      'total_bytes': totalBytes,
      'last_request_time': lastRequestTime?.toIso8601String(),
    };
  }
}

// Import for math
import 'dart:math' as math;
