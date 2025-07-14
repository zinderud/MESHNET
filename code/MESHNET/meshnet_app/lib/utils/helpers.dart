// lib/utils/helpers.dart - Yardımcı fonksiyonlar
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'constants.dart';

class Helpers {
  // UUID generation (BitChat'teki gibi)
  static String generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Version 4 UUID
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
  
  // Mesaj ID generation
  static String generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_${random.toString().padLeft(6, '0')}';
  }
  
  // Peer ID generation (MAC address benzeri)
  static String generatePeerId() {
    final random = Random();
    final bytes = List<int>.generate(6, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
  }
  
  // Signal strength to bars conversion
  static int signalStrengthToBars(double rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }
  
  // Distance estimation from RSSI (rough calculation)
  static double estimateDistance(double rssi, double txPower) {
    if (rssi == 0) return -1.0;
    
    final ratio = txPower / rssi;
    if (ratio < 1.0) {
      return pow(ratio, 10).toDouble();
    } else {
      final accuracy = (0.89976) * pow(ratio, 7.7095) + 0.111;
      return accuracy;
    }
  }
  
  // Format bytes to human readable
  static String formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  // Format duration to human readable
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  // Format timestamp for messages
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (diff.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
  
  // Color from string (consistent peer colors)
  static Color colorFromString(String text) {
    final hash = text.hashCode;
    final colors = [
      AppTheme.primaryColor,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }
  
  // Validate message content
  static bool isValidMessage(String content) {
    if (content.trim().isEmpty) return false;
    if (content.length > AppConstants.maxMessageLength) return false;
    return true;
  }
  
  // Validate channel name
  static bool isValidChannelName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.length > AppConstants.maxChannelNameLength) return false;
    if (name.contains(' ')) return false;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) return false;
    return true;
  }
  
  // Validate username
  static bool isValidUsername(String name) {
    if (name.trim().isEmpty) return false;
    if (name.length > AppConstants.maxUsernameLength) return false;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name)) return false;
    return true;
  }
  
  // Parse IRC-style command
  static Map<String, dynamic>? parseCommand(String input) {
    if (!input.startsWith('/')) return null;
    
    final parts = input.substring(1).split(' ');
    if (parts.isEmpty) return null;
    
    final command = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];
    
    return {
      'command': command,
      'args': args,
      'raw': input,
    };
  }
  
  // Generate emergency alert sound pattern
  static List<int> generateAlertPattern(EmergencyPriority priority) {
    switch (priority) {
      case EmergencyPriority.low:
        return [100, 100]; // Tek beep
      case EmergencyPriority.medium:
        return [100, 100, 100, 100]; // Çift beep
      case EmergencyPriority.high:
        return [200, 100, 200, 100, 200]; // Uzun-kısa-uzun
      case EmergencyPriority.critical:
        return [500, 100, 500, 100, 500, 100, 500]; // Sürekli alarm
    }
  }
  
  // JSON safe encoding/decoding
  static String safeJsonEncode(dynamic data) {
    try {
      return json.encode(data);
    } catch (e) {
      return '{}';
    }
  }
  
  static dynamic safeJsonDecode(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      return {};
    }
  }
  
  // Frequency validation for RTL-SDR/HackRF
  static bool isValidFrequency(double frequency) {
    return frequency >= AppConstants.minFrequency && 
           frequency <= AppConstants.maxFrequency;
  }
  
  // Calculate hop penalty for routing
  static double calculateHopPenalty(int hopCount) {
    return hopCount * 0.1; // Her hop için 0.1 penalty
  }
  
  // Generate mesh network topology description
  static String generateTopologyDescription(Map<String, List<String>> connections) {
    final totalPeers = connections.keys.length;
    final totalConnections = connections.values
        .map((peers) => peers.length)
        .fold(0, (a, b) => a + b);
    
    return 'Network: $totalPeers peers, $totalConnections connections';
  }
  
  // Debug helper for logging
  static void debugLog(String tag, String message) {
    print('[$tag] ${DateTime.now()}: $message');
  }
}
