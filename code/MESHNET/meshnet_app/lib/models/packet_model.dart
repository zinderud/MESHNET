// lib/models/packet_model.dart
// Reticulum-style packet structure
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PacketModel {
  final String destinationHash;
  final String? sourceHash;
  final PacketType type;
  final Uint8List data;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final int hopCount;
  final int ttl; // Time to live
  
  PacketModel({
    required this.destinationHash,
    this.sourceHash,
    required this.type,
    required this.data,
    this.metadata,
    DateTime? timestamp,
    this.hopCount = 0,
    this.ttl = 30,
  }) : timestamp = timestamp ?? DateTime.now();
  
  // Create packet from raw bytes (Reticulum format)
  factory PacketModel.fromBytes(Uint8List bytes, {Map<String, dynamic>? metadata}) {
    try {
      // Simple packet format for now
      // Real implementation would follow Reticulum packet structure
      
      if (bytes.length < 32) {
        throw Exception('Packet too short');
      }
      
      // Extract destination hash (first 10 bytes in hex)
      final destHashBytes = bytes.sublist(0, 10);
      final destinationHash = destHashBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join('');
      
      // Extract packet type (1 byte)
      final typeValue = bytes[10];
      final type = PacketType.values[typeValue % PacketType.values.length];
      
      // Extract hop count (1 byte)
      final hopCount = bytes[11];
      
      // Extract TTL (1 byte)
      final ttl = bytes[12];
      
      // Extract data (remaining bytes)
      final data = bytes.sublist(13);
      
      return PacketModel(
        destinationHash: destinationHash,
        type: type,
        data: data,
        metadata: metadata,
        hopCount: hopCount,
        ttl: ttl,
      );
      
    } catch (e) {
      throw Exception('Failed to parse packet: $e');
    }
  }
  
  // Serialize packet to bytes (Reticulum format)
  Uint8List toBytes() {
    try {
      // Convert destination hash to bytes
      final destHashBytes = <int>[];
      for (int i = 0; i < destinationHash.length; i += 2) {
        final hex = destinationHash.substring(i, i + 2);
        destHashBytes.add(int.parse(hex, radix: 16));
      }
      
      // Ensure destination hash is 10 bytes
      while (destHashBytes.length < 10) {
        destHashBytes.add(0);
      }
      
      // Build packet
      final packet = <int>[];
      packet.addAll(destHashBytes.take(10)); // Destination hash (10 bytes)
      packet.add(type.index); // Packet type (1 byte)
      packet.add(hopCount); // Hop count (1 byte)
      packet.add(ttl); // TTL (1 byte)
      packet.addAll(data); // Data payload
      
      return Uint8List.fromList(packet);
      
    } catch (e) {
      throw Exception('Failed to serialize packet: $e');
    }
  }
  
  // Create announce packet
  factory PacketModel.announce({
    required String destinationHash,
    required Map<String, Uint8List> publicKeys,
    required String appName,
    List<String> aspects = const [],
  }) {
    final announceData = {
      'destination_hash': destinationHash,
      'public_keys': publicKeys.map((k, v) => MapEntry(k, base64Encode(v))),
      'app_name': appName,
      'aspects': aspects,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final jsonData = jsonEncode(announceData);
    final dataBytes = Uint8List.fromList(utf8.encode(jsonData));
    
    return PacketModel(
      destinationHash: destinationHash,
      type: PacketType.announce,
      data: dataBytes,
    );
  }
  
  // Create data packet
  factory PacketModel.data({
    required String destinationHash,
    String? sourceHash,
    required Uint8List payload,
    int hopCount = 0,
    int ttl = 30,
  }) {
    return PacketModel(
      destinationHash: destinationHash,
      sourceHash: sourceHash,
      type: PacketType.data,
      data: payload,
      hopCount: hopCount,
      ttl: ttl,
    );
  }
  
  // Create emergency packet
  factory PacketModel.emergency({
    required String message,
    String? sourceHash,
    Map<String, dynamic>? location,
  }) {
    final emergencyData = {
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'priority': 'emergency',
    };
    
    final jsonData = jsonEncode(emergencyData);
    final dataBytes = Uint8List.fromList(utf8.encode(jsonData));
    
    return PacketModel(
      destinationHash: 'emergency_broadcast',
      sourceHash: sourceHash,
      type: PacketType.emergency,
      data: dataBytes,
      ttl: 10, // Higher TTL for emergency packets
    );
  }
  
  // Calculate packet hash (for deduplication)
  String calculateHash() {
    final hashInput = toBytes();
    final digest = sha256.convert(hashInput);
    return digest.toString();
  }
  
  // Check if packet is expired
  bool get isExpired {
    final age = DateTime.now().difference(timestamp).inMinutes;
    return age > ttl;
  }
  
  // Create copy with incremented hop count
  PacketModel incrementHops() {
    return PacketModel(
      destinationHash: destinationHash,
      sourceHash: sourceHash,
      type: type,
      data: data,
      metadata: metadata,
      timestamp: timestamp,
      hopCount: hopCount + 1,
      ttl: ttl,
    );
  }
  
  // Check if packet should be forwarded
  bool shouldForward() {
    return hopCount < 10 && !isExpired; // Max 10 hops
  }
  
  @override
  String toString() {
    return 'Packet(dest: $destinationHash, type: $type, hops: $hopCount, size: ${data.length})';
  }
  
  // JSON representation
  Map<String, dynamic> toJson() => {
    'destination_hash': destinationHash,
    'source_hash': sourceHash,
    'type': type.name,
    'data_size': data.length,
    'timestamp': timestamp.toIso8601String(),
    'hop_count': hopCount,
    'ttl': ttl,
    'metadata': metadata,
  };
}

// Packet types (Reticulum-inspired)
enum PacketType {
  data,
  announce,
  pathRequest,
  pathReply,
  emergency,
  proof,
  linkRequest,
  linkProof,
  resource,
}

// Packet priority levels
enum PacketPriority {
  low,
  normal,
  high,
  emergency,
}

// Simple packet header structure
class PacketHeader {
  final int version;
  final PacketType type;
  final PacketPriority priority;
  final int hopCount;
  final int ttl;
  final int dataLength;
  
  PacketHeader({
    this.version = 1,
    required this.type,
    this.priority = PacketPriority.normal,
    this.hopCount = 0,
    this.ttl = 30,
    required this.dataLength,
  });
  
  Uint8List toBytes() {
    return Uint8List.fromList([
      version,
      type.index,
      priority.index,
      hopCount,
      ttl,
      (dataLength >> 8) & 0xFF, // Data length high byte
      dataLength & 0xFF,         // Data length low byte
    ]);
  }
  
  factory PacketHeader.fromBytes(Uint8List bytes) {
    if (bytes.length < 7) {
      throw Exception('Header too short');
    }
    
    return PacketHeader(
      version: bytes[0],
      type: PacketType.values[bytes[1]],
      priority: PacketPriority.values[bytes[2]],
      hopCount: bytes[3],
      ttl: bytes[4],
      dataLength: (bytes[5] << 8) | bytes[6],
    );
  }
}
