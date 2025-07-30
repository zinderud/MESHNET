// lib/services/priority_message_service.dart - Emergency Priority Messaging
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'emergency_manager.dart';

/// Message priority levels
enum MessagePriority {
  emergency,  // Life-threatening emergency
  urgent,     // Critical situation
  high,       // Important but not critical
  normal,     // Regular message
  low,        // Background information
}

/// Priority message service
class PriorityMessageService extends ChangeNotifier {
  // Message queues by priority
  final Map<MessagePriority, Queue<PriorityMessage>> _messageQueues = {
    MessagePriority.emergency: Queue<PriorityMessage>(),
    MessagePriority.urgent: Queue<PriorityMessage>(),
    MessagePriority.high: Queue<PriorityMessage>(),
    MessagePriority.normal: Queue<PriorityMessage>(),
    MessagePriority.low: Queue<PriorityMessage>(),
  };
  
  // Message processing
  Timer? _processingTimer;
  bool _isProcessing = false;
  int _maxQueueSize = 1000;
  
  // Statistics
  final Map<MessagePriority, int> _messageCounts = {};
  final Map<MessagePriority, Duration> _averageProcessingTime = {};
  
  // Rate limiting
  final Map<MessagePriority, int> _rateLimits = {
    MessagePriority.emergency: 100,  // 100 msg/min
    MessagePriority.urgent: 60,      // 60 msg/min
    MessagePriority.high: 30,        // 30 msg/min
    MessagePriority.normal: 20,      // 20 msg/min
    MessagePriority.low: 10,         // 10 msg/min
  };
  
  // Message processors
  final List<MessageProcessor> _processors = [];
  
  // Getters
  bool get isProcessing => _isProcessing;
  Map<MessagePriority, int> get queueSizes => _messageQueues.map(
    (priority, queue) => MapEntry(priority, queue.length)
  );
  Map<MessagePriority, int> get messageCounts => Map.unmodifiable(_messageCounts);
  
  /// Initialize priority message service
  Future<bool> initialize() async {
    try {
      print('📨 Initializing Priority Message Service...');
      
      // Initialize message counts
      for (final priority in MessagePriority.values) {
        _messageCounts[priority] = 0;
        _averageProcessingTime[priority] = Duration.zero;
      }
      
      // Start message processing
      _startProcessing();
      
      print('📨 Priority Message Service initialized');
      return true;
    } catch (e) {
      print('❌ Error initializing Priority Message Service: $e');
      return false;
    }
  }
  
  /// Add message processor
  void addProcessor(MessageProcessor processor) {
    _processors.add(processor);
    print('🔧 Added message processor: ${processor.name}');
  }
  
  /// Remove message processor
  void removeProcessor(MessageProcessor processor) {
    _processors.remove(processor);
    print('🔧 Removed message processor: ${processor.name}');
  }
  
  /// Submit message with priority
  Future<bool> submitMessage(PriorityMessage message) async {
    try {
      final queue = _messageQueues[message.priority]!;
      
      // Check queue size limits
      if (queue.length >= _maxQueueSize) {
        print('⚠️ Queue full for priority ${message.priority}, dropping oldest message');
        queue.removeFirst();
      }
      
      // Check rate limits
      if (!_checkRateLimit(message.priority)) {
        print('⚠️ Rate limit exceeded for priority ${message.priority}');
        return false;
      }
      
      // Add to appropriate queue
      queue.add(message);
      _messageCounts[message.priority] = (_messageCounts[message.priority] ?? 0) + 1;
      
      print('📨 Message queued: ${message.priority} - ${message.content.length} chars');
      notifyListeners();
      
      return true;
    } catch (e) {
      print('❌ Error submitting message: $e');
      return false;
    }
  }
  
  /// Submit emergency message (highest priority)
  Future<bool> submitEmergencyMessage({
    required String content,
    required EmergencyType emergencyType,
    required EmergencyLevel emergencyLevel,
    EmergencyLocation? location,
    Map<String, dynamic>? metadata,
  }) async {
    final message = PriorityMessage(
      id: _generateMessageId(),
      priority: MessagePriority.emergency,
      content: content,
      timestamp: DateTime.now(),
      emergencyType: emergencyType,
      emergencyLevel: emergencyLevel,
      location: location,
      metadata: metadata ?? {},
      ttl: Duration(hours: 24), // Emergency messages live longer
    );
    
    return await submitMessage(message);
  }
  
  /// Submit urgent message
  Future<bool> submitUrgentMessage({
    required String content,
    EmergencyLocation? location,
    Map<String, dynamic>? metadata,
  }) async {
    final message = PriorityMessage(
      id: _generateMessageId(),
      priority: MessagePriority.urgent,
      content: content,
      timestamp: DateTime.now(),
      location: location,
      metadata: metadata ?? {},
      ttl: Duration(hours: 12),
    );
    
    return await submitMessage(message);
  }
  
  /// Submit normal message
  Future<bool> submitNormalMessage({
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final message = PriorityMessage(
      id: _generateMessageId(),
      priority: MessagePriority.normal,
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      ttl: Duration(hours: 6),
    );
    
    return await submitMessage(message);
  }
  
  /// Get next message to process
  PriorityMessage? getNextMessage() {
    // Process in priority order
    for (final priority in MessagePriority.values) {
      final queue = _messageQueues[priority]!;
      if (queue.isNotEmpty) {
        return queue.removeFirst();
      }
    }
    return null;
  }
  
  /// Get messages by priority
  List<PriorityMessage> getMessagesByPriority(MessagePriority priority) {
    return _messageQueues[priority]!.toList();
  }
  
  /// Clear expired messages
  void clearExpiredMessages() {
    final now = DateTime.now();
    int removedCount = 0;
    
    for (final queue in _messageQueues.values) {
      queue.removeWhere((message) {
        if (message.isExpired(now)) {
          removedCount++;
          return true;
        }
        return false;
      });
    }
    
    if (removedCount > 0) {
      print('🗑️ Cleared $removedCount expired messages');
      notifyListeners();
    }
  }
  
  /// Start message processing
  void _startProcessing() {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    _processingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      _processMessages();
    });
    
    print('⚙️ Message processing started');
  }
  
  /// Stop message processing
  void _stopProcessing() {
    _isProcessing = false;
    _processingTimer?.cancel();
    
    print('⚙️ Message processing stopped');
  }
  
  /// Process messages
  void _processMessages() {
    // Clear expired messages periodically
    if (DateTime.now().second % 30 == 0) {
      clearExpiredMessages();
    }
    
    // Process next message
    final message = getNextMessage();
    if (message != null) {
      _processMessage(message);
    }
  }
  
  /// Process individual message
  Future<void> _processMessage(PriorityMessage message) async {
    final startTime = DateTime.now();
    
    try {
      // Send to all registered processors
      for (final processor in _processors) {
        if (processor.canProcess(message)) {
          await processor.processMessage(message);
        }
      }
      
      // Update processing time statistics
      final processingTime = DateTime.now().difference(startTime);
      _updateProcessingTime(message.priority, processingTime);
      
      print('✅ Processed ${message.priority} message in ${processingTime.inMilliseconds}ms');
      
    } catch (e) {
      print('❌ Error processing message: $e');
    }
  }
  
  /// Check rate limit
  bool _checkRateLimit(MessagePriority priority) {
    // Simplified rate limiting - in production would use sliding window
    final limit = _rateLimits[priority] ?? 10;
    final count = _messageCounts[priority] ?? 0;
    
    // Reset count every minute (simplified)
    if (DateTime.now().second == 0) {
      _messageCounts[priority] = 0;
    }
    
    return count < limit;
  }
  
  /// Update processing time statistics
  void _updateProcessingTime(MessagePriority priority, Duration processingTime) {
    final currentAvg = _averageProcessingTime[priority] ?? Duration.zero;
    final newAvg = Duration(
      milliseconds: ((currentAvg.inMilliseconds + processingTime.inMilliseconds) / 2).round()
    );
    _averageProcessingTime[priority] = newAvg;
  }
  
  /// Generate message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${(1000 + DateTime.now().microsecond % 9000)}';
  }
  
  @override
  void dispose() {
    _stopProcessing();
    super.dispose();
  }
}

/// Priority message
class PriorityMessage {
  final String id;
  final MessagePriority priority;
  final String content;
  final DateTime timestamp;
  final Duration ttl;
  final EmergencyType? emergencyType;
  final EmergencyLevel? emergencyLevel;
  final EmergencyLocation? location;
  final Map<String, dynamic> metadata;
  
  PriorityMessage({
    required this.id,
    required this.priority,
    required this.content,
    required this.timestamp,
    required this.ttl,
    this.emergencyType,
    this.emergencyLevel,
    this.location,
    this.metadata = const {},
  });
  
  /// Check if message is expired
  bool isExpired(DateTime now) {
    return now.difference(timestamp) > ttl;
  }
  
  /// Get priority weight for sorting
  int get priorityWeight {
    switch (priority) {
      case MessagePriority.emergency:
        return 1000;
      case MessagePriority.urgent:
        return 800;
      case MessagePriority.high:
        return 600;
      case MessagePriority.normal:
        return 400;
      case MessagePriority.low:
        return 200;
    }
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'priority': priority.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inSeconds,
      'emergencyType': emergencyType?.toString(),
      'emergencyLevel': emergencyLevel?.toString(),
      'location': location?.toJson(),
      'metadata': metadata,
    };
  }
}

/// Message processor interface
abstract class MessageProcessor {
  String get name;
  
  bool canProcess(PriorityMessage message);
  Future<void> processMessage(PriorityMessage message);
}

/// Bluetooth message processor
class BluetoothMessageProcessor implements MessageProcessor {
  @override
  String get name => 'Bluetooth';
  
  @override
  bool canProcess(PriorityMessage message) {
    // Process all emergency and urgent messages via Bluetooth
    return message.priority == MessagePriority.emergency ||
           message.priority == MessagePriority.urgent;
  }
  
  @override
  Future<void> processMessage(PriorityMessage message) async {
    // Send via Bluetooth mesh
    print('📶 Sending via Bluetooth: ${message.content}');
    await Future.delayed(Duration(milliseconds: 50)); // Simulate sending
  }
}

/// WiFi Direct message processor
class WiFiDirectMessageProcessor implements MessageProcessor {
  @override
  String get name => 'WiFi Direct';
  
  @override
  bool canProcess(PriorityMessage message) {
    // Process high-priority messages via WiFi Direct for higher bandwidth
    return message.priority == MessagePriority.emergency ||
           message.priority == MessagePriority.urgent ||
           message.priority == MessagePriority.high;
  }
  
  @override
  Future<void> processMessage(PriorityMessage message) async {
    // Send via WiFi Direct
    print('📡 Sending via WiFi Direct: ${message.content}');
    await Future.delayed(Duration(milliseconds: 100)); // Simulate sending
  }
}

/// SDR message processor
class SDRMessageProcessor implements MessageProcessor {
  @override
  String get name => 'SDR';
  
  @override
  bool canProcess(PriorityMessage message) {
    // Process emergency messages via SDR for long-range
    return message.priority == MessagePriority.emergency;
  }
  
  @override
  Future<void> processMessage(PriorityMessage message) async {
    // Send via SDR
    print('📻 Sending via SDR: ${message.content}');
    await Future.delayed(Duration(milliseconds: 200)); // Simulate sending
  }
}

/// Ham Radio message processor
class HamRadioMessageProcessor implements MessageProcessor {
  @override
  String get name => 'Ham Radio';
  
  @override
  bool canProcess(PriorityMessage message) {
    // Process emergency and urgent messages via Ham Radio
    return message.priority == MessagePriority.emergency ||
           message.priority == MessagePriority.urgent;
  }
  
  @override
  Future<void> processMessage(PriorityMessage message) async {
    // Send via Ham Radio protocols
    print('📡 Sending via Ham Radio: ${message.content}');
    await Future.delayed(Duration(milliseconds: 150)); // Simulate sending
  }
}
