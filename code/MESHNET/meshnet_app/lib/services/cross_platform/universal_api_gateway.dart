// lib/services/cross_platform/universal_api_gateway.dart - Universal API Gateway Service
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

/// API protocol types
enum APIProtocol {
  rest,
  graphql,
  websocket,
  grpc,
  mqtt,
  mesh_native,
}

/// Request methods
enum RequestMethod {
  get,
  post,
  put,
  patch,
  delete,
  options,
  head,
}

/// Response formats
enum ResponseFormat {
  json,
  xml,
  protobuf,
  binary,
  text,
  html,
}

/// Authentication types
enum AuthenticationType {
  none,
  basic,
  bearer,
  api_key,
  oauth2,
  jwt,
  custom,
}

/// API endpoint configuration
class APIEndpointConfig {
  final String endpointId;
  final String name;
  final String baseUrl;
  final APIProtocol protocol;
  final AuthenticationType authType;
  final Map<String, String> headers;
  final Map<String, dynamic> authConfig;
  final Duration timeout;
  final int maxRetries;
  final bool enableCache;
  final Duration cacheTimeout;

  APIEndpointConfig({
    required this.endpointId,
    required this.name,
    required this.baseUrl,
    required this.protocol,
    this.authType = AuthenticationType.none,
    this.headers = const {},
    this.authConfig = const {},
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableCache = false,
    this.cacheTimeout = const Duration(minutes: 5),
  });

  Map<String, dynamic> toJson() => {
    'endpointId': endpointId,
    'name': name,
    'baseUrl': baseUrl,
    'protocol': protocol.toString(),
    'authType': authType.toString(),
    'headers': headers,
    'authConfig': authConfig,
    'timeout': timeout.inSeconds,
    'maxRetries': maxRetries,
    'enableCache': enableCache,
    'cacheTimeout': cacheTimeout.inMinutes,
  };
}

/// API request
class APIRequest {
  final String requestId;
  final String endpointId;
  final String path;
  final RequestMethod method;
  final Map<String, dynamic> queryParams;
  final Map<String, String> headers;
  final dynamic body;
  final ResponseFormat expectedFormat;
  final Duration? timeout;
  final int priority;
  final DateTime timestamp;

  APIRequest({
    required this.requestId,
    required this.endpointId,
    required this.path,
    required this.method,
    this.queryParams = const {},
    this.headers = const {},
    this.body,
    this.expectedFormat = ResponseFormat.json,
    this.timeout,
    this.priority = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'endpointId': endpointId,
    'path': path,
    'method': method.toString(),
    'queryParams': queryParams,
    'headers': headers,
    'body': body,
    'expectedFormat': expectedFormat.toString(),
    'timeout': timeout?.inSeconds,
    'priority': priority,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// API response
class APIResponse {
  final String requestId;
  final int statusCode;
  final Map<String, String> headers;
  final dynamic data;
  final ResponseFormat format;
  final DateTime timestamp;
  final Duration responseTime;
  final bool fromCache;
  final String? error;

  APIResponse({
    required this.requestId,
    required this.statusCode,
    this.headers = const {},
    this.data,
    this.format = ResponseFormat.json,
    required this.timestamp,
    required this.responseTime,
    this.fromCache = false,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'statusCode': statusCode,
    'headers': headers,
    'data': data,
    'format': format.toString(),
    'timestamp': timestamp.toIso8601String(),
    'responseTime': responseTime.inMilliseconds,
    'fromCache': fromCache,
    'error': error,
  };

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}

/// Request queue item
class QueuedRequest {
  final APIRequest request;
  final Completer<APIResponse> completer;
  final DateTime queuedAt;
  int retryCount;

  QueuedRequest({
    required this.request,
    required this.completer,
    required this.queuedAt,
    this.retryCount = 0,
  });
}

/// Cache entry
class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime cachedAt;
  final Duration ttl;
  final Map<String, String> headers;

  CacheEntry({
    required this.key,
    required this.data,
    required this.cachedAt,
    required this.ttl,
    this.headers = const {},
  });

  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;

  Map<String, dynamic> toJson() => {
    'key': key,
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'ttl': ttl.inMinutes,
    'headers': headers,
  };
}

/// API statistics
class APIStatistics {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int cachedResponses;
  final Duration averageResponseTime;
  final Map<String, int> endpointUsage;
  final Map<int, int> statusCodeCounts;
  final DateTime lastRequestTime;

  APIStatistics({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.cachedResponses,
    required this.averageResponseTime,
    required this.endpointUsage,
    required this.statusCodeCounts,
    required this.lastRequestTime,
  });

  Map<String, dynamic> toJson() => {
    'totalRequests': totalRequests,
    'successfulRequests': successfulRequests,
    'failedRequests': failedRequests,
    'cachedResponses': cachedResponses,
    'averageResponseTime': averageResponseTime.inMilliseconds,
    'endpointUsage': endpointUsage,
    'statusCodeCounts': statusCodeCounts,
    'lastRequestTime': lastRequestTime.toIso8601String(),
  };

  double get successRate => totalRequests > 0 ? successfulRequests / totalRequests : 0.0;
  double get cacheHitRate => totalRequests > 0 ? cachedResponses / totalRequests : 0.0;
}

/// Universal API Gateway Service
class UniversalAPIGateway {
  static final UniversalAPIGateway _instance = UniversalAPIGateway._internal();
  static UniversalAPIGateway get instance => _instance;
  UniversalAPIGateway._internal();

  // Service state
  bool _isInitialized = false;
  bool _isProcessingQueue = false;

  // Configuration
  final Map<String, APIEndpointConfig> _endpoints = {};
  final Map<String, CacheEntry> _responseCache = {};
  final List<QueuedRequest> _requestQueue = [];
  final List<APIResponse> _responseHistory = [];

  // Statistics
  APIStatistics _statistics = APIStatistics(
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    cachedResponses: 0,
    averageResponseTime: Duration.zero,
    endpointUsage: {},
    statusCodeCounts: {},
    lastRequestTime: DateTime.now(),
  );

  // Request processing
  Timer? _queueProcessor;
  final Map<String, Timer> _retryTimers = {};

  // Stream controllers
  final StreamController<APIRequest> _requestController = 
      StreamController.broadcast();
  final StreamController<APIResponse> _responseController = 
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _statusController = 
      StreamController.broadcast();

  // Properties
  bool get isInitialized => _isInitialized;
  bool get isProcessingQueue => _isProcessingQueue;
  APIStatistics get statistics => _statistics;
  
  // Streams
  Stream<APIRequest> get requestStream => _requestController.stream;
  Stream<APIResponse> get responseStream => _responseController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  /// Initialize universal API gateway
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Load endpoint configurations
      await _loadEndpointConfigurations();
      
      // Start request queue processor
      _startQueueProcessor();
      
      // Setup cache cleanup
      _setupCacheCleanup();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Register API endpoint
  Future<bool> registerEndpoint(APIEndpointConfig config) async {
    if (!_isInitialized) return false;

    try {
      // Validate endpoint configuration
      if (!await _validateEndpointConfig(config)) {
        return false;
      }
      
      _endpoints[config.endpointId] = config;
      
      _statusController.add({
        'event': 'endpoint_registered',
        'endpointId': config.endpointId,
        'name': config.name,
        'protocol': config.protocol.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unregister API endpoint
  Future<bool> unregisterEndpoint(String endpointId) async {
    if (!_isInitialized) return false;

    final endpoint = _endpoints.remove(endpointId);
    if (endpoint == null) return false;

    // Cancel any pending requests for this endpoint
    _requestQueue.removeWhere((queuedRequest) {
      if (queuedRequest.request.endpointId == endpointId) {
        queuedRequest.completer.complete(APIResponse(
          requestId: queuedRequest.request.requestId,
          statusCode: 503,
          timestamp: DateTime.now(),
          responseTime: Duration.zero,
          error: 'Endpoint unregistered',
        ));
        return true;
      }
      return false;
    });
    
    _statusController.add({
      'event': 'endpoint_unregistered',
      'endpointId': endpointId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return true;
  }

  /// Make API request
  Future<APIResponse> makeRequest(APIRequest request) async {
    if (!_isInitialized) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 503,
        timestamp: DateTime.now(),
        responseTime: Duration.zero,
        error: 'Gateway not initialized',
      );
    }

    final endpoint = _endpoints[request.endpointId];
    if (endpoint == null) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 404,
        timestamp: DateTime.now(),
        responseTime: Duration.zero,
        error: 'Endpoint not found',
      );
    }

    _requestController.add(request);

    // Check cache first
    if (endpoint.enableCache && request.method == RequestMethod.get) {
      final cachedResponse = _getCachedResponse(request, endpoint);
      if (cachedResponse != null) {
        return cachedResponse;
      }
    }

    // Queue request for processing
    final completer = Completer<APIResponse>();
    final queuedRequest = QueuedRequest(
      request: request,
      completer: completer,
      queuedAt: DateTime.now(),
    );

    _requestQueue.add(queuedRequest);

    return completer.future;
  }

  /// Make GET request
  Future<APIResponse> get(
    String endpointId,
    String path, {
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    ResponseFormat format = ResponseFormat.json,
  }) async {
    final request = APIRequest(
      requestId: 'get_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      endpointId: endpointId,
      path: path,
      method: RequestMethod.get,
      queryParams: queryParams,
      headers: headers,
      expectedFormat: format,
      timestamp: DateTime.now(),
    );

    return await makeRequest(request);
  }

  /// Make POST request
  Future<APIResponse> post(
    String endpointId,
    String path, {
    dynamic body,
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    ResponseFormat format = ResponseFormat.json,
  }) async {
    final request = APIRequest(
      requestId: 'post_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      endpointId: endpointId,
      path: path,
      method: RequestMethod.post,
      body: body,
      queryParams: queryParams,
      headers: headers,
      expectedFormat: format,
      timestamp: DateTime.now(),
    );

    return await makeRequest(request);
  }

  /// Make PUT request
  Future<APIResponse> put(
    String endpointId,
    String path, {
    dynamic body,
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    ResponseFormat format = ResponseFormat.json,
  }) async {
    final request = APIRequest(
      requestId: 'put_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      endpointId: endpointId,
      path: path,
      method: RequestMethod.put,
      body: body,
      queryParams: queryParams,
      headers: headers,
      expectedFormat: format,
      timestamp: DateTime.now(),
    );

    return await makeRequest(request);
  }

  /// Make DELETE request
  Future<APIResponse> delete(
    String endpointId,
    String path, {
    Map<String, dynamic> queryParams = const {},
    Map<String, String> headers = const {},
    ResponseFormat format = ResponseFormat.json,
  }) async {
    final request = APIRequest(
      requestId: 'delete_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}',
      endpointId: endpointId,
      path: path,
      method: RequestMethod.delete,
      queryParams: queryParams,
      headers: headers,
      expectedFormat: format,
      timestamp: DateTime.now(),
    );

    return await makeRequest(request);
  }

  /// Get registered endpoints
  List<APIEndpointConfig> getEndpoints() {
    return _endpoints.values.toList();
  }

  /// Get endpoint by ID
  APIEndpointConfig? getEndpoint(String endpointId) {
    return _endpoints[endpointId];
  }

  /// Clear response cache
  void clearCache([String? endpointId]) {
    if (endpointId == null) {
      _responseCache.clear();
    } else {
      _responseCache.removeWhere((key, entry) => key.startsWith(endpointId));
    }
  }

  /// Get queue status
  Map<String, dynamic> getQueueStatus() {
    return {
      'queueSize': _requestQueue.length,
      'isProcessing': _isProcessingQueue,
      'oldestRequestAge': _requestQueue.isNotEmpty 
          ? DateTime.now().difference(_requestQueue.first.queuedAt).inSeconds
          : 0,
    };
  }

  /// Get response history
  List<APIResponse> getResponseHistory([int? limit]) {
    if (limit == null) return List.from(_responseHistory);
    return _responseHistory.take(limit).toList();
  }

  /// Get gateway status
  Map<String, dynamic> getGatewayStatus() {
    return {
      'isInitialized': _isInitialized,
      'endpointsCount': _endpoints.length,
      'cacheSize': _responseCache.length,
      'queueStatus': getQueueStatus(),
      'statistics': _statistics.toJson(),
    };
  }

  /// Cleanup and shutdown
  Future<void> shutdown() async {
    _queueProcessor?.cancel();
    
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    
    // Complete pending requests with error
    for (final queuedRequest in _requestQueue) {
      queuedRequest.completer.complete(APIResponse(
        requestId: queuedRequest.request.requestId,
        statusCode: 503,
        timestamp: DateTime.now(),
        responseTime: Duration.zero,
        error: 'Gateway shutdown',
      ));
    }
    
    await _requestController.close();
    await _responseController.close();
    await _statusController.close();
    
    _endpoints.clear();
    _responseCache.clear();
    _requestQueue.clear();
    _responseHistory.clear();
    
    _isInitialized = false;
  }

  // Private methods

  Future<void> _loadEndpointConfigurations() async {
    // Load default endpoints
    await registerEndpoint(APIEndpointConfig(
      endpointId: 'mesh_api',
      name: 'Mesh Network API',
      baseUrl: 'http://localhost:8080/api',
      protocol: APIProtocol.rest,
      authType: AuthenticationType.jwt,
      enableCache: true,
    ));
  }

  void _startQueueProcessor() {
    _queueProcessor = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isProcessingQueue && _requestQueue.isNotEmpty) {
        await _processRequestQueue();
      }
    });
  }

  void _setupCacheCleanup() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _cleanupExpiredCache();
    });
  }

  Future<bool> _validateEndpointConfig(APIEndpointConfig config) async {
    // Validate endpoint configuration
    return config.baseUrl.isNotEmpty && config.name.isNotEmpty;
  }

  APIResponse? _getCachedResponse(APIRequest request, APIEndpointConfig endpoint) {
    final cacheKey = '${request.endpointId}_${request.path}_${jsonEncode(request.queryParams)}';
    final cacheEntry = _responseCache[cacheKey];
    
    if (cacheEntry != null && !cacheEntry.isExpired) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 200,
        data: cacheEntry.data,
        headers: cacheEntry.headers,
        timestamp: DateTime.now(),
        responseTime: Duration.zero,
        fromCache: true,
      );
    }
    
    return null;
  }

  Future<void> _processRequestQueue() async {
    if (_requestQueue.isEmpty) return;

    _isProcessingQueue = true;

    try {
      // Sort by priority and timestamp
      _requestQueue.sort((a, b) {
        final priorityCompare = b.request.priority.compareTo(a.request.priority);
        if (priorityCompare != 0) return priorityCompare;
        return a.queuedAt.compareTo(b.queuedAt);
      });

      final queuedRequest = _requestQueue.removeAt(0);
      final response = await _executeRequest(queuedRequest.request);
      
      _responseHistory.add(response);
      _responseController.add(response);
      
      // Update statistics
      _updateStatistics(response);
      
      queuedRequest.completer.complete(response);
      
    } catch (e) {
      // Handle queue processing error
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<APIResponse> _executeRequest(APIRequest request) async {
    final startTime = DateTime.now();
    final endpoint = _endpoints[request.endpointId]!;

    try {
      // Simulate API request execution
      final response = await _simulateAPIRequest(request, endpoint);
      
      // Cache response if enabled
      if (endpoint.enableCache && response.isSuccess) {
        _cacheResponse(request, response, endpoint);
      }
      
      return response;
    } catch (e) {
      return APIResponse(
        requestId: request.requestId,
        statusCode: 500,
        timestamp: DateTime.now(),
        responseTime: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  Future<APIResponse> _simulateAPIRequest(APIRequest request, APIEndpointConfig endpoint) async {
    // Simulate network delay
    final delay = Duration(milliseconds: 50 + math.Random().nextInt(200));
    await Future.delayed(delay);

    // Simulate occasional failures
    if (math.Random().nextDouble() < 0.05) {
      throw Exception('Simulated network error');
    }

    // Generate mock response
    final statusCode = [200, 201, 400, 404, 500][math.Random().nextInt(5)];
    final responseData = {
      'status': statusCode < 400 ? 'success' : 'error',
      'requestId': request.requestId,
      'endpoint': endpoint.name,
      'path': request.path,
      'method': request.method.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return APIResponse(
      requestId: request.requestId,
      statusCode: statusCode,
      data: responseData,
      headers: {'content-type': 'application/json'},
      timestamp: DateTime.now(),
      responseTime: delay,
    );
  }

  void _cacheResponse(APIRequest request, APIResponse response, APIEndpointConfig endpoint) {
    final cacheKey = '${request.endpointId}_${request.path}_${jsonEncode(request.queryParams)}';
    final cacheEntry = CacheEntry(
      key: cacheKey,
      data: response.data,
      cachedAt: DateTime.now(),
      ttl: endpoint.cacheTimeout,
      headers: response.headers,
    );
    
    _responseCache[cacheKey] = cacheEntry;
  }

  void _cleanupExpiredCache() {
    _responseCache.removeWhere((key, entry) => entry.isExpired);
  }

  void _updateStatistics(APIResponse response) {
    final endpointUsage = Map<String, int>.from(_statistics.endpointUsage);
    final statusCodeCounts = Map<int, int>.from(_statistics.statusCodeCounts);
    
    // Update endpoint usage
    final endpoint = _endpoints.values.firstWhere(
      (e) => response.requestId.contains(e.endpointId),
      orElse: () => throw StateError('Endpoint not found'),
    );
    endpointUsage[endpoint.name] = (endpointUsage[endpoint.name] ?? 0) + 1;
    
    // Update status code counts
    statusCodeCounts[response.statusCode] = (statusCodeCounts[response.statusCode] ?? 0) + 1;
    
    // Calculate average response time
    final totalRequests = _statistics.totalRequests + 1;
    final totalResponseTime = _statistics.averageResponseTime * _statistics.totalRequests + response.responseTime;
    final averageResponseTime = Duration(microseconds: (totalResponseTime.inMicroseconds / totalRequests).round());
    
    _statistics = APIStatistics(
      totalRequests: totalRequests,
      successfulRequests: _statistics.successfulRequests + (response.isSuccess ? 1 : 0),
      failedRequests: _statistics.failedRequests + (response.isSuccess ? 0 : 1),
      cachedResponses: _statistics.cachedResponses + (response.fromCache ? 1 : 0),
      averageResponseTime: averageResponseTime,
      endpointUsage: endpointUsage,
      statusCodeCounts: statusCodeCounts,
      lastRequestTime: DateTime.now(),
    );
  }
}
