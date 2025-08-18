// lib/services/cross_platform/web_interface_bridge.dart - Web Interface Bridge Service
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

/// Web bridge interface types
enum WebInterfaceType {
  iframe,
  popup,
  new_tab,
  embedded,
  modal,
}

/// Web message types
enum WebMessageType {
  command,
  data,
  event,
  response,
  notification,
  error,
}

/// Web API endpoints
enum WebAPIEndpoint {
  mesh_status,
  send_message,
  file_transfer,
  user_management,
  settings,
  emergency,
  analytics,
  health_check,
}

/// Web interface configuration
class WebInterfaceConfig {
  final String id;
  final WebInterfaceType type;
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic> params;
  final bool allowCORS;
  final bool enablePostMessage;
  final int timeoutSeconds;
  final String title;

  WebInterfaceConfig({
    required this.id,
    required this.type,
    required this.url,
    this.headers = const {},
    this.params = const {},
    this.allowCORS = true,
    this.enablePostMessage = true,
    this.timeoutSeconds = 30,
    this.title = 'MeshNet Web Interface',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'url': url,
    'headers': headers,
    'params': params,
    'allowCORS': allowCORS,
    'enablePostMessage': enablePostMessage,
    'timeoutSeconds': timeoutSeconds,
    'title': title,
  };
}

/// Web message
class WebMessage {
  final String id;
  final WebMessageType type;
  final String source;
  final String target;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int? responseId;

  WebMessage({
    required this.id,
    required this.type,
    required this.source,
    required this.target,
    required this.data,
    required this.timestamp,
    this.responseId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'source': source,
    'target': target,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'responseId': responseId,
  };

  factory WebMessage.fromJson(Map<String, dynamic> json) => WebMessage(
    id: json['id'],
    type: WebMessageType.values.firstWhere((e) => e.toString() == json['type']),
    source: json['source'],
    target: json['target'],
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
    responseId: json['responseId'],
  );
}

/// Web API request
class WebAPIRequest {
  final String id;
  final WebAPIEndpoint endpoint;
  final String method;
  final Map<String, dynamic> params;
  final Map<String, String> headers;
  final DateTime timestamp;

  WebAPIRequest({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.params,
    this.headers = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'endpoint': endpoint.toString(),
    'method': method,
    'params': params,
    'headers': headers,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Web API response
class WebAPIResponse {
  final String requestId;
  final int statusCode;
  final Map<String, dynamic> data;
  final String? error;
  final DateTime timestamp;

  WebAPIResponse({
    required this.requestId,
    required this.statusCode,
    required this.data,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'statusCode': statusCode,
    'data': data,
    'error': error,
    'timestamp': timestamp.toIso8601String(),
  };

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Web interface session
class WebInterfaceSession {
  final String sessionId;
  final WebInterfaceConfig config;
  final DateTime startTime;
  DateTime lastActivity;
  bool isActive;
  html.Element? element;
  
  WebInterfaceSession({
    required this.sessionId,
    required this.config,
    required this.startTime,
    required this.lastActivity,
    this.isActive = true,
    this.element,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'config': config.toJson(),
    'startTime': startTime.toIso8601String(),
    'lastActivity': lastActivity.toIso8601String(),
    'isActive': isActive,
  };
}

/// Web Interface Bridge Service
class WebInterfaceBridge {
  static final WebInterfaceBridge _instance = WebInterfaceBridge._internal();
  static WebInterfaceBridge get instance => _instance;
  WebInterfaceBridge._internal();

  // Service state
  bool _isInitialized = false;
  bool _isBridgeActive = false;
  final Map<String, WebInterfaceSession> _activeSessions = {};
  final Map<String, Completer<WebAPIResponse>> _pendingRequests = {};

  // Configuration
  final Map<WebAPIEndpoint, String> _apiEndpoints = {};
  final Map<String, dynamic> _globalConfig = {};

  // Message handling
  final Map<String, Function(WebMessage)> _messageHandlers = {};
  final List<WebMessage> _messageHistory = [];

  // Stream controllers
  final StreamController<WebMessage> _messageController = 
      StreamController.broadcast();
  final StreamController<WebAPIResponse> _responseController = 
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _sessionController = 
      StreamController.broadcast();

  // Properties
  bool get isInitialized => _isInitialized;
  bool get isBridgeActive => _isBridgeActive;
  
  // Streams
  Stream<WebMessage> get messageStream => _messageController.stream;
  Stream<WebAPIResponse> get responseStream => _responseController.stream;
  Stream<Map<String, dynamic>> get sessionStream => _sessionController.stream;

  /// Initialize web interface bridge
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Setup API endpoints
      _setupAPIEndpoints();
      
      // Initialize message handlers
      _initializeMessageHandlers();
      
      // Setup JavaScript bridge
      await _setupJavaScriptBridge();
      
      // Setup PostMessage listener
      _setupPostMessageListener();
      
      _isInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start web bridge
  Future<bool> startBridge() async {
    if (!_isInitialized || _isBridgeActive) return false;

    _isBridgeActive = true;
    
    _sessionController.add({
      'event': 'bridge_started',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return true;
  }

  /// Stop web bridge
  Future<bool> stopBridge() async {
    if (!_isInitialized || !_isBridgeActive) return false;

    _isBridgeActive = false;
    
    // Close all active sessions
    for (final session in _activeSessions.values) {
      await closeSession(session.sessionId);
    }
    
    _sessionController.add({
      'event': 'bridge_stopped',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return true;
  }

  /// Create web interface session
  Future<String?> createSession(WebInterfaceConfig config) async {
    if (!_isInitialized || !_isBridgeActive) return null;

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = WebInterfaceSession(
      sessionId: sessionId,
      config: config,
      startTime: DateTime.now(),
      lastActivity: DateTime.now(),
    );

    try {
      // Create web interface based on type
      final element = await _createWebInterface(config);
      session.element = element;
      
      _activeSessions[sessionId] = session;
      
      _sessionController.add({
        'event': 'session_created',
        'sessionId': sessionId,
        'config': config.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return sessionId;
    } catch (e) {
      return null;
    }
  }

  /// Close web interface session
  Future<bool> closeSession(String sessionId) async {
    if (!_isInitialized) return false;

    final session = _activeSessions[sessionId];
    if (session == null) return false;

    try {
      // Remove web interface element
      if (session.element != null) {
        session.element!.remove();
      }
      
      session.isActive = false;
      _activeSessions.remove(sessionId);
      
      _sessionController.add({
        'event': 'session_closed',
        'sessionId': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send message to web interface
  Future<bool> sendMessage(String sessionId, WebMessage message) async {
    if (!_isInitialized || !_isBridgeActive) return false;

    final session = _activeSessions[sessionId];
    if (session == null || !session.isActive) return false;

    try {
      // Send message via PostMessage API
      await _sendPostMessage(session, message);
      
      _messageHistory.add(message);
      _messageController.add(message);
      
      session.lastActivity = DateTime.now();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send API request
  Future<WebAPIResponse?> sendAPIRequest(WebAPIRequest request) async {
    if (!_isInitialized || !_isBridgeActive) return null;

    final completer = Completer<WebAPIResponse>();
    _pendingRequests[request.id] = completer;

    try {
      // Make HTTP request
      final response = await _makeHTTPRequest(request);
      
      completer.complete(response);
      _pendingRequests.remove(request.id);
      
      _responseController.add(response);
      
      return response;
    } catch (e) {
      final errorResponse = WebAPIResponse(
        requestId: request.id,
        statusCode: 500,
        data: {},
        error: e.toString(),
        timestamp: DateTime.now(),
      );
      
      completer.complete(errorResponse);
      _pendingRequests.remove(request.id);
      
      return errorResponse;
    }
  }

  /// Register message handler
  void registerMessageHandler(String messageType, Function(WebMessage) handler) {
    _messageHandlers[messageType] = handler;
  }

  /// Unregister message handler
  void unregisterMessageHandler(String messageType) {
    _messageHandlers.remove(messageType);
  }

  /// Broadcast message to all sessions
  Future<int> broadcastMessage(WebMessage message) async {
    if (!_isInitialized || !_isBridgeActive) return 0;

    int sentCount = 0;
    
    for (final sessionId in _activeSessions.keys) {
      if (await sendMessage(sessionId, message)) {
        sentCount++;
      }
    }
    
    return sentCount;
  }

  /// Get active sessions
  List<WebInterfaceSession> getActiveSessions() {
    return _activeSessions.values.where((s) => s.isActive).toList();
  }

  /// Get session by ID
  WebInterfaceSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  /// Get message history
  List<WebMessage> getMessageHistory([int? limit]) {
    if (limit == null) return List.from(_messageHistory);
    return _messageHistory.take(limit).toList();
  }

  /// Configure API endpoint
  void configureAPIEndpoint(WebAPIEndpoint endpoint, String url) {
    _apiEndpoints[endpoint] = url;
  }

  /// Set global configuration
  void setGlobalConfig(String key, dynamic value) {
    _globalConfig[key] = value;
  }

  /// Get bridge statistics
  Map<String, dynamic> getBridgeStats() {
    return {
      'isActive': _isBridgeActive,
      'activeSessionsCount': _activeSessions.length,
      'messageHistoryCount': _messageHistory.length,
      'pendingRequestsCount': _pendingRequests.length,
      'registeredHandlersCount': _messageHandlers.length,
      'apiEndpointsCount': _apiEndpoints.length,
      'globalConfig': Map.from(_globalConfig),
    };
  }

  /// Cleanup and shutdown
  Future<void> shutdown() async {
    await stopBridge();
    
    await _messageController.close();
    await _responseController.close();
    await _sessionController.close();
    
    _activeSessions.clear();
    _pendingRequests.clear();
    _messageHandlers.clear();
    _messageHistory.clear();
    _apiEndpoints.clear();
    _globalConfig.clear();
    
    _isInitialized = false;
  }

  // Private methods

  void _setupAPIEndpoints() {
    _apiEndpoints[WebAPIEndpoint.mesh_status] = '/api/mesh/status';
    _apiEndpoints[WebAPIEndpoint.send_message] = '/api/mesh/message';
    _apiEndpoints[WebAPIEndpoint.file_transfer] = '/api/mesh/file';
    _apiEndpoints[WebAPIEndpoint.user_management] = '/api/user';
    _apiEndpoints[WebAPIEndpoint.settings] = '/api/settings';
    _apiEndpoints[WebAPIEndpoint.emergency] = '/api/emergency';
    _apiEndpoints[WebAPIEndpoint.analytics] = '/api/analytics';
    _apiEndpoints[WebAPIEndpoint.health_check] = '/api/health';
  }

  void _initializeMessageHandlers() {
    // Default message handlers
    registerMessageHandler('ping', (message) {
      final response = WebMessage(
        id: 'pong_${DateTime.now().millisecondsSinceEpoch}',
        type: WebMessageType.response,
        source: 'bridge',
        target: message.source,
        data: {'pong': true, 'timestamp': DateTime.now().toIso8601String()},
        timestamp: DateTime.now(),
        responseId: int.parse(message.id.split('_').last),
      );
      
      _messageController.add(response);
    });
    
    registerMessageHandler('status', (message) {
      final response = WebMessage(
        id: 'status_${DateTime.now().millisecondsSinceEpoch}',
        type: WebMessageType.response,
        source: 'bridge',
        target: message.source,
        data: getBridgeStats(),
        timestamp: DateTime.now(),
      );
      
      _messageController.add(response);
    });
  }

  Future<void> _setupJavaScriptBridge() async {
    // Setup JavaScript bridge for web communication
    js.context['meshNetBridge'] = js.JsObject.jsify({
      'sendMessage': (data) => _handleJavaScriptMessage(data),
      'getStatus': () => js.JsObject.jsify(getBridgeStats()),
      'isActive': () => _isBridgeActive,
    });
  }

  void _setupPostMessageListener() {
    html.window.onMessage.listen((html.MessageEvent event) {
      try {
        final data = jsonDecode(event.data);
        final message = WebMessage.fromJson(data);
        
        _handleReceivedMessage(message);
      } catch (e) {
        // Handle invalid message format
      }
    });
  }

  Future<html.Element> _createWebInterface(WebInterfaceConfig config) async {
    switch (config.type) {
      case WebInterfaceType.iframe:
        return _createIFrameInterface(config);
      case WebInterfaceType.popup:
        return _createPopupInterface(config);
      case WebInterfaceType.embedded:
        return _createEmbeddedInterface(config);
      case WebInterfaceType.modal:
        return _createModalInterface(config);
      default:
        throw UnsupportedError('Interface type not supported: ${config.type}');
    }
  }

  html.Element _createIFrameInterface(WebInterfaceConfig config) {
    final iframe = html.IFrameElement()
      ..src = config.url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = 'none';
    
    html.document.body!.children.add(iframe);
    return iframe;
  }

  html.Element _createPopupInterface(WebInterfaceConfig config) {
    // For demo purposes, create a div that simulates a popup
    final popup = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '50px'
      ..style.left = '50px'
      ..style.width = '800px'
      ..style.height = '600px'
      ..style.backgroundColor = 'white'
      ..style.border = '1px solid #ccc'
      ..style.zIndex = '1000';
    
    html.document.body!.children.add(popup);
    return popup;
  }

  html.Element _createEmbeddedInterface(WebInterfaceConfig config) {
    final container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '400px';
    
    html.document.body!.children.add(container);
    return container;
  }

  html.Element _createModalInterface(WebInterfaceConfig config) {
    final modal = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'rgba(0,0,0,0.5)'
      ..style.zIndex = '2000';
    
    html.document.body!.children.add(modal);
    return modal;
  }

  Future<void> _sendPostMessage(WebInterfaceSession session, WebMessage message) async {
    if (session.element is html.IFrameElement) {
      final iframe = session.element as html.IFrameElement;
      iframe.contentWindow?.postMessage(jsonEncode(message.toJson()), '*');
    }
  }

  Future<WebAPIResponse> _makeHTTPRequest(WebAPIRequest request) async {
    final endpoint = _apiEndpoints[request.endpoint] ?? '/api/unknown';
    final url = '${_globalConfig['baseUrl'] ?? ''}$endpoint';
    
    // Simulate HTTP request
    await Future.delayed(const Duration(milliseconds: 100));
    
    return WebAPIResponse(
      requestId: request.id,
      statusCode: 200,
      data: {
        'success': true,
        'endpoint': endpoint,
        'method': request.method,
        'params': request.params,
      },
      timestamp: DateTime.now(),
    );
  }

  void _handleJavaScriptMessage(dynamic data) {
    try {
      final message = WebMessage.fromJson(Map<String, dynamic>.from(data));
      _handleReceivedMessage(message);
    } catch (e) {
      // Handle error
    }
  }

  void _handleReceivedMessage(WebMessage message) {
    // Add to history
    _messageHistory.add(message);
    
    // Keep only last 1000 messages
    if (_messageHistory.length > 1000) {
      _messageHistory.removeAt(0);
    }
    
    // Call registered handler
    final handler = _messageHandlers[message.type.toString()];
    if (handler != null) {
      handler(message);
    }
    
    // Emit to stream
    _messageController.add(message);
  }
}
