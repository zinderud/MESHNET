// lib/models/mesh_peer.dart - Mesh Network Peer Model
import 'dart:typed_data';

enum PeerStatus {
  unknown,
  discovering,
  connecting,
  connected,
  disconnected,
  unreachable,
  error,
}

enum PeerType {
  bluetooth,
  wifiDirect,
  sdr,
  hamRadio,
  hybrid,
}

enum ConnectionProtocol {
  bluetooth,
  wifiDirect,
  tcp,
  udp,
  lorawan,
  ham,
  sdr,
}

class MeshPeer {
  final String id;
  final String name;
  final String? deviceId;
  final PeerType type;
  final PeerStatus status;
  final Set<ConnectionProtocol> supportedProtocols;
  final String? currentAddress;
  final int? currentPort;
  final DateTime lastSeen;
  final DateTime? connectedAt;
  final double? signalStrength; // RSSI or similar
  final double? distance; // Estimated distance in meters
  final int hopCount;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> metadata;
  final List<String> routes; // Routes to other peers through this peer
  final bool isRelay;
  final bool isEmergencyNode;
  final String? publicKey;
  final Uint8List? certificateData;

  MeshPeer({
    required this.id,
    required this.name,
    this.deviceId,
    required this.type,
    this.status = PeerStatus.unknown,
    this.supportedProtocols = const {},
    this.currentAddress,
    this.currentPort,
    required this.lastSeen,
    this.connectedAt,
    this.signalStrength,
    this.distance,
    this.hopCount = 1,
    this.capabilities = const {},
    this.metadata = const {},
    this.routes = const [],
    this.isRelay = false,
    this.isEmergencyNode = false,
    this.publicKey,
    this.certificateData,
  });

  // Factory constructor for empty peer (used by memory pool)
  factory MeshPeer.empty() {
    return MeshPeer(
      id: '',
      name: '',
      type: PeerType.bluetooth,
      lastSeen: DateTime.now(),
    );
  }

  // Reset method for memory pool reuse
  MeshPeer reset() {
    return MeshPeer.empty();
  }

  // Copy with method for immutable updates
  MeshPeer copyWith({
    String? id,
    String? name,
    String? deviceId,
    PeerType? type,
    PeerStatus? status,
    Set<ConnectionProtocol>? supportedProtocols,
    String? currentAddress,
    int? currentPort,
    DateTime? lastSeen,
    DateTime? connectedAt,
    double? signalStrength,
    double? distance,
    int? hopCount,
    Map<String, dynamic>? capabilities,
    Map<String, dynamic>? metadata,
    List<String>? routes,
    bool? isRelay,
    bool? isEmergencyNode,
    String? publicKey,
    Uint8List? certificateData,
  }) {
    return MeshPeer(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      status: status ?? this.status,
      supportedProtocols: supportedProtocols ?? this.supportedProtocols,
      currentAddress: currentAddress ?? this.currentAddress,
      currentPort: currentPort ?? this.currentPort,
      lastSeen: lastSeen ?? this.lastSeen,
      connectedAt: connectedAt ?? this.connectedAt,
      signalStrength: signalStrength ?? this.signalStrength,
      distance: distance ?? this.distance,
      hopCount: hopCount ?? this.hopCount,
      capabilities: capabilities ?? this.capabilities,
      metadata: metadata ?? this.metadata,
      routes: routes ?? this.routes,
      isRelay: isRelay ?? this.isRelay,
      isEmergencyNode: isEmergencyNode ?? this.isEmergencyNode,
      publicKey: publicKey ?? this.publicKey,
      certificateData: certificateData ?? this.certificateData,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'type': type.index,
      'status': status.index,
      'supportedProtocols': supportedProtocols.map((p) => p.index).toList(),
      'currentAddress': currentAddress,
      'currentPort': currentPort,
      'lastSeen': lastSeen.toIso8601String(),
      'connectedAt': connectedAt?.toIso8601String(),
      'signalStrength': signalStrength,
      'distance': distance,
      'hopCount': hopCount,
      'capabilities': capabilities,
      'metadata': metadata,
      'routes': routes,
      'isRelay': isRelay,
      'isEmergencyNode': isEmergencyNode,
      'publicKey': publicKey,
      'certificateData': certificateData?.toList(),
    };
  }

  factory MeshPeer.fromJson(Map<String, dynamic> json) {
    return MeshPeer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      deviceId: json['deviceId'],
      type: PeerType.values[json['type'] ?? 0],
      status: PeerStatus.values[json['status'] ?? 0],
      supportedProtocols: (json['supportedProtocols'] as List?)
          ?.map((i) => ConnectionProtocol.values[i])
          .toSet() ?? {},
      currentAddress: json['currentAddress'],
      currentPort: json['currentPort'],
      lastSeen: DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
      connectedAt: json['connectedAt'] != null ? DateTime.parse(json['connectedAt']) : null,
      signalStrength: json['signalStrength']?.toDouble(),
      distance: json['distance']?.toDouble(),
      hopCount: json['hopCount'] ?? 1,
      capabilities: Map<String, dynamic>.from(json['capabilities'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      routes: List<String>.from(json['routes'] ?? []),
      isRelay: json['isRelay'] ?? false,
      isEmergencyNode: json['isEmergencyNode'] ?? false,
      publicKey: json['publicKey'],
      certificateData: json['certificateData'] != null 
          ? Uint8List.fromList(List<int>.from(json['certificateData']))
          : null,
    );
  }

  // Utility properties
  bool get isConnected => status == PeerStatus.connected;
  bool get isAvailable => status == PeerStatus.connected || status == PeerStatus.discovering;
  bool get hasStrongSignal => signalStrength != null && signalStrength! > -70; // dBm
  bool get isNearby => distance != null && distance! < 100; // meters
  bool get isMultiHop => hopCount > 1;
  bool get hasRoutes => routes.isNotEmpty;

  Duration get timeSinceLastSeen => DateTime.now().difference(lastSeen);
  Duration? get connectionDuration => connectedAt != null 
      ? DateTime.now().difference(connectedAt!) 
      : null;

  String get statusDisplay {
    switch (status) {
      case PeerStatus.unknown:
        return 'Unknown';
      case PeerStatus.discovering:
        return 'Discovering';
      case PeerStatus.connecting:
        return 'Connecting';
      case PeerStatus.connected:
        return 'Connected';
      case PeerStatus.disconnected:
        return 'Disconnected';
      case PeerStatus.unreachable:
        return 'Unreachable';
      case PeerStatus.error:
        return 'Error';
    }
  }

  String get typeDisplay {
    switch (type) {
      case PeerType.bluetooth:
        return 'Bluetooth';
      case PeerType.wifiDirect:
        return 'WiFi Direct';
      case PeerType.sdr:
        return 'SDR';
      case PeerType.hamRadio:
        return 'Ham Radio';
      case PeerType.hybrid:
        return 'Hybrid';
    }
  }

  String get signalStrengthDisplay {
    if (signalStrength == null) return 'Unknown';
    
    if (signalStrength! > -50) return 'Excellent';
    if (signalStrength! > -70) return 'Good';
    if (signalStrength! > -80) return 'Fair';
    return 'Poor';
  }

  String get distanceDisplay {
    if (distance == null) return 'Unknown';
    
    if (distance! < 10) return '${distance!.toStringAsFixed(1)}m';
    if (distance! < 1000) return '${distance!.round()}m';
    return '${(distance! / 1000).toStringAsFixed(1)}km';
  }

  // Network topology methods
  bool canRouteTo(String peerId) {
    return routes.contains(peerId);
  }

  int getRouteQuality() {
    int quality = 100;
    
    // Reduce quality based on hop count
    quality -= (hopCount - 1) * 20;
    
    // Reduce quality based on signal strength
    if (signalStrength != null) {
      if (signalStrength! < -80) quality -= 30;
      else if (signalStrength! < -70) quality -= 15;
    }
    
    // Reduce quality based on time since last seen
    final timeSinceLastSeenMinutes = timeSinceLastSeen.inMinutes;
    if (timeSinceLastSeenMinutes > 10) quality -= 40;
    else if (timeSinceLastSeenMinutes > 5) quality -= 20;
    
    // Bonus for emergency nodes
    if (isEmergencyNode) quality += 10;
    
    // Bonus for relay capability
    if (isRelay) quality += 5;
    
    return quality.clamp(0, 100);
  }

  // Memory estimation for optimization
  int get estimatedSize {
    int size = 0;
    size += id.length * 2; // UTF-16
    size += name.length * 2;
    size += (deviceId?.length ?? 0) * 2;
    size += (currentAddress?.length ?? 0) * 2;
    size += 128; // Enums, numbers, dates, booleans
    size += capabilities.toString().length * 2;
    size += metadata.toString().length * 2;
    size += routes.join(',').length * 2;
    size += (publicKey?.length ?? 0) * 2;
    size += certificateData?.length ?? 0;
    return size;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeshPeer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MeshPeer(id: $id, name: $name, type: $type, status: $status, hops: $hopCount)';
  }
}

// Utility class for peer management
class PeerManager {
  static List<MeshPeer> sortByQuality(List<MeshPeer> peers) {
    final sortedPeers = List<MeshPeer>.from(peers);
    sortedPeers.sort((a, b) => b.getRouteQuality().compareTo(a.getRouteQuality()));
    return sortedPeers;
  }

  static List<MeshPeer> filterByStatus(List<MeshPeer> peers, PeerStatus status) {
    return peers.where((peer) => peer.status == status).toList();
  }

  static List<MeshPeer> filterByType(List<MeshPeer> peers, PeerType type) {
    return peers.where((peer) => peer.type == type).toList();
  }

  static List<MeshPeer> getEmergencyNodes(List<MeshPeer> peers) {
    return peers.where((peer) => peer.isEmergencyNode).toList();
  }

  static List<MeshPeer> getRelayNodes(List<MeshPeer> peers) {
    return peers.where((peer) => peer.isRelay).toList();
  }

  static MeshPeer? findBestRoute(List<MeshPeer> peers, String targetPeerId) {
    final routingPeers = peers.where((peer) => peer.canRouteTo(targetPeerId)).toList();
    if (routingPeers.isEmpty) return null;
    
    return sortByQuality(routingPeers).first;
  }
}
