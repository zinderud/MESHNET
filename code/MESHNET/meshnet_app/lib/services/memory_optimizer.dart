// lib/services/memory_optimizer.dart - Bellek Optimizasyon Servisi
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:meshnet_app/models/chat_message.dart';
import 'package:meshnet_app/models/mesh_peer.dart';
import 'package:meshnet_app/utils/logger.dart';
import 'package:meshnet_app/services/performance_monitor.dart';

class MemoryOptimizer {
  static final MemoryOptimizer _instance = MemoryOptimizer._internal();
  factory MemoryOptimizer() => _instance;
  MemoryOptimizer._internal();

  // Object pools for reuse
  final Queue<ChatMessage> _chatMessagePool = Queue<ChatMessage>();
  final Queue<MeshPeer> _meshPeerPool = Queue<MeshPeer>();
  final Queue<Uint8List> _bufferPool = Queue<Uint8List>();
  final Queue<List<int>> _intListPool = Queue<List<int>>();

  // Cache management
  final Map<String, dynamic> _cache = {};
  final Queue<String> _cacheKeys = Queue<String>();
  static const int maxCacheSize = 100;
  
  // Message history management
  final Map<String, Queue<ChatMessage>> _messageHistory = {};
  static const int maxMessagesPerChannel = 1000;
  static const int maxTotalMessages = 5000;
  int _totalMessages = 0;

  // Memory pressure handling
  bool _isMemoryPressureHigh = false;
  DateTime _lastCleanup = DateTime.now();
  static const Duration cleanupInterval = Duration(minutes: 5);

  void initialize() {
    Logger.info('Memory Optimizer initialized');
    
    // Pre-populate pools
    _populateObjectPools();
    
    // Start periodic cleanup
    _schedulePeriodicCleanup();
  }

  void _populateObjectPools() {
    // Pre-create objects for pools
    for (int i = 0; i < 10; i++) {
      _chatMessagePool.add(ChatMessage.empty());
      _meshPeerPool.add(MeshPeer.empty());
      _bufferPool.add(Uint8List(1024)); // 1KB buffers
      _intListPool.add(<int>[]);
    }
    
    Logger.debug('Object pools populated');
  }

  void _schedulePeriodicCleanup() {
    Future.delayed(cleanupInterval, () {
      performCleanup();
      _schedulePeriodicCleanup();
    });
  }

  // Object Pool Management
  ChatMessage getChatMessage() {
    if (_chatMessagePool.isNotEmpty) {
      final message = _chatMessagePool.removeFirst();
      return message.reset(); // Reset to default state
    }
    return ChatMessage.empty();
  }

  void returnChatMessage(ChatMessage message) {
    if (_chatMessagePool.length < 50) { // Limit pool size
      _chatMessagePool.addLast(message);
    }
  }

  MeshPeer getMeshPeer() {
    if (_meshPeerPool.isNotEmpty) {
      final peer = _meshPeerPool.removeFirst();
      return peer.reset();
    }
    return MeshPeer.empty();
  }

  void returnMeshPeer(MeshPeer peer) {
    if (_meshPeerPool.length < 20) {
      _meshPeerPool.addLast(peer);
    }
  }

  Uint8List getBuffer(int size) {
    // Try to find a buffer of appropriate size
    for (int i = 0; i < _bufferPool.length; i++) {
      final buffer = _bufferPool.elementAt(i);
      if (buffer.length >= size) {
        _bufferPool.remove(buffer);
        return buffer;
      }
    }
    
    // Create new buffer if none available
    return Uint8List(size);
  }

  void returnBuffer(Uint8List buffer) {
    if (_bufferPool.length < 20 && buffer.length <= 4096) { // Max 4KB buffers
      _bufferPool.addLast(buffer);
    }
  }

  List<int> getIntList() {
    if (_intListPool.isNotEmpty) {
      final list = _intListPool.removeFirst();
      list.clear();
      return list;
    }
    return <int>[];
  }

  void returnIntList(List<int> list) {
    if (_intListPool.length < 10) {
      _intListPool.addLast(list);
    }
  }

  // Cache Management
  void cacheData(String key, dynamic data) {
    // Implement LRU cache
    if (_cache.containsKey(key)) {
      _cacheKeys.remove(key);
    } else if (_cache.length >= maxCacheSize) {
      final oldestKey = _cacheKeys.removeFirst();
      _cache.remove(oldestKey);
    }
    
    _cache[key] = data;
    _cacheKeys.addLast(key);
  }

  T? getCachedData<T>(String key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      _cacheKeys.remove(key);
      _cacheKeys.addLast(key);
      return _cache[key] as T?;
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
    _cacheKeys.clear();
    Logger.debug('Cache cleared');
  }

  // Message History Management
  void addMessage(String channelId, ChatMessage message) {
    _messageHistory.putIfAbsent(channelId, () => Queue<ChatMessage>());
    final channelMessages = _messageHistory[channelId]!;
    
    channelMessages.addLast(message);
    _totalMessages++;
    
    // Limit messages per channel
    if (channelMessages.length > maxMessagesPerChannel) {
      final oldMessage = channelMessages.removeFirst();
      returnChatMessage(oldMessage);
      _totalMessages--;
    }
    
    // Global message limit
    if (_totalMessages > maxTotalMessages) {
      _performGlobalMessageCleanup();
    }
  }

  List<ChatMessage> getMessages(String channelId) {
    return _messageHistory[channelId]?.toList() ?? [];
  }

  void _performGlobalMessageCleanup() {
    Logger.info('Performing global message cleanup');
    
    // Remove oldest messages from all channels
    int removedCount = 0;
    for (final channelMessages in _messageHistory.values) {
      while (channelMessages.length > maxMessagesPerChannel ~/ 2 && removedCount < 1000) {
        final oldMessage = channelMessages.removeFirst();
        returnChatMessage(oldMessage);
        removedCount++;
        _totalMessages--;
      }
    }
    
    Logger.info('Removed $removedCount old messages');
  }

  // Memory Pressure Management
  void setMemoryPressure(bool isHigh) {
    if (isHigh && !_isMemoryPressureHigh) {
      Logger.warning('High memory pressure detected');
      _performEmergencyCleanup();
    }
    _isMemoryPressureHigh = isHigh;
  }

  void _performEmergencyCleanup() {
    Logger.info('Performing emergency memory cleanup');
    
    // Clear cache
    clearCache();
    
    // Reduce message history
    for (final channelMessages in _messageHistory.values) {
      while (channelMessages.length > 100) {
        final oldMessage = channelMessages.removeFirst();
        returnChatMessage(oldMessage);
        _totalMessages--;
      }
    }
    
    // Trim object pools
    while (_chatMessagePool.length > 5) {
      _chatMessagePool.removeFirst();
    }
    while (_meshPeerPool.length > 5) {
      _meshPeerPool.removeFirst();
    }
    while (_bufferPool.length > 5) {
      _bufferPool.removeFirst();
    }
    
    // Force garbage collection (if available)
    if (kDebugMode) {
      // In debug mode, we can suggest GC
      Logger.debug('Suggesting garbage collection');
    }
    
    Logger.info('Emergency cleanup completed');
  }

  // Regular Cleanup
  void performCleanup() {
    final now = DateTime.now();
    if (now.difference(_lastCleanup) < cleanupInterval) {
      return;
    }
    
    Logger.debug('Performing regular cleanup');
    
    // Remove old cache entries (older than 10 minutes)
    final oldCacheKeys = <String>[];
    for (final key in _cacheKeys) {
      // This is a simple implementation; in practice, you'd store timestamps
      if (_cacheKeys.length > maxCacheSize ~/ 2) {
        oldCacheKeys.add(key);
      }
    }
    
    for (final key in oldCacheKeys.take(10)) {
      _cache.remove(key);
      _cacheKeys.remove(key);
    }
    
    // Report memory usage
    final performanceMonitor = PerformanceMonitor();
    performanceMonitor.recordMemoryUsage(_estimateMemoryUsage());
    
    _lastCleanup = now;
    Logger.debug('Regular cleanup completed');
  }

  // Memory Usage Estimation
  int _estimateMemoryUsage() {
    int totalBytes = 0;
    
    // Estimate cache size
    totalBytes += _cache.length * 100; // Rough estimate
    
    // Estimate message history size
    totalBytes += _totalMessages * 200; // Rough estimate per message
    
    // Estimate object pools
    totalBytes += _chatMessagePool.length * 100;
    totalBytes += _meshPeerPool.length * 150;
    totalBytes += _bufferPool.fold<int>(0, (sum, buffer) => sum + buffer.length);
    
    return totalBytes;
  }

  // Memory Statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'cache_entries': _cache.length,
      'total_messages': _totalMessages,
      'message_channels': _messageHistory.length,
      'chat_message_pool': _chatMessagePool.length,
      'mesh_peer_pool': _meshPeerPool.length,
      'buffer_pool': _bufferPool.length,
      'estimated_usage_bytes': _estimateMemoryUsage(),
      'is_memory_pressure_high': _isMemoryPressureHigh,
      'last_cleanup': _lastCleanup.toIso8601String(),
    };
  }

  // Optimization Recommendations
  List<String> getMemoryOptimizationRecommendations() {
    final recommendations = <String>[];
    
    if (_totalMessages > maxTotalMessages * 0.8) {
      recommendations.add('Message history approaching limit. Consider archiving old messages.');
    }
    
    if (_cache.length > maxCacheSize * 0.8) {
      recommendations.add('Cache usage high. Consider reducing cache size or clearing old entries.');
    }
    
    if (_isMemoryPressureHigh) {
      recommendations.add('High memory pressure detected. Reduce background tasks and clear unnecessary data.');
    }
    
    final estimatedMB = _estimateMemoryUsage() / (1024 * 1024);
    if (estimatedMB > 100) {
      recommendations.add('High memory usage (${estimatedMB.toStringAsFixed(1)}MB). Consider optimization.');
    }
    
    return recommendations;
  }

  void dispose() {
    clearCache();
    Logger.info('Memory Optimizer disposed');
  }
}

// Memory-efficient data structures
class CircularBuffer<T> {
  final List<T?> _buffer;
  final int _capacity;
  int _head = 0;
  int _tail = 0;
  int _size = 0;

  CircularBuffer(this._capacity) : _buffer = List<T?>.filled(_capacity, null);

  void add(T item) {
    _buffer[_tail] = item;
    _tail = (_tail + 1) % _capacity;
    
    if (_size < _capacity) {
      _size++;
    } else {
      _head = (_head + 1) % _capacity;
    }
  }

  T? removeFirst() {
    if (_size == 0) return null;
    
    final item = _buffer[_head];
    _buffer[_head] = null;
    _head = (_head + 1) % _capacity;
    _size--;
    
    return item;
  }

  bool get isEmpty => _size == 0;
  bool get isFull => _size == _capacity;
  int get length => _size;
  
  List<T> toList() {
    final result = <T>[];
    int current = _head;
    for (int i = 0; i < _size; i++) {
      final item = _buffer[current];
      if (item != null) result.add(item);
      current = (current + 1) % _capacity;
    }
    return result;
  }
}

// Extension methods for memory-efficient operations
extension MemoryEfficientList<T> on List<T> {
  void addIfNotFull(T item, int maxSize) {
    if (length < maxSize) {
      add(item);
    } else {
      // Replace oldest item
      removeAt(0);
      add(item);
    }
  }
  
  void trimToSize(int maxSize) {
    while (length > maxSize) {
      removeAt(0);
    }
  }
}
