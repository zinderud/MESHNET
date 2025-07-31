// lib/models/peer.dart - MESHNET Peer/Node Models

/// Enum for node types in the MESHNET system
enum NodeType {
  mobile,      // Mobile device (phone, tablet)
  desktop,     // Desktop/laptop computer
  embedded,    // Embedded device (Raspberry Pi, etc.)
  gateway,     // Gateway to other networks
  repeater,    // Signal repeater/mesh extender
  emergency,   // Emergency services node
}

/// Enum for node status
enum NodeStatus {
  online,      // Active and reachable
  offline,     // Not reachable
  busy,        // Online but busy
  away,        // Online but away
  emergency,   // In emergency mode
  maintenance, // Undergoing maintenance
}

/// Enum for connection types
enum ConnectionType {
  bluetooth,
  wifiDirect,
  sdr,
  hamRadio,
  internet,
  hybrid,
}

/// Model representing a peer/node in the MESHNET
class MeshPeer {
  final String nodeId;
  final String displayName;
  final NodeType nodeType;
  final String? deviceModel;
  final String? operatingSystem;
  final List<ConnectionType> supportedConnections;
  final Map<String, dynamic> capabilities;
  
  NodeStatus status;
  DateTime lastSeen;
  double? signalStrength; // -100 to 0 dBm
  int hopCount; // Distance in hops from local node
  String? currentLocation;
  bool isEncryptionSupported;
  String? publicKey;
  Map<String, dynamic> metadata;

  MeshPeer({
    required this.nodeId,
    required this.displayName,
    required this.nodeType,
    this.deviceModel,
    this.operatingSystem,
    this.supportedConnections = const [],
    this.capabilities = const {},
    this.status = NodeStatus.offline,
    required this.lastSeen,
    this.signalStrength,
    this.hopCount = 0,
    this.currentLocation,
    this.isEncryptionSupported = false,
    this.publicKey,
    this.metadata = const {},
  });

  /// Create a copy with updated fields
  MeshPeer copyWith({
    String? nodeId,
    String? displayName,
    NodeType? nodeType,
    String? deviceModel,
    String? operatingSystem,
    List<ConnectionType>? supportedConnections,
    Map<String, dynamic>? capabilities,
    NodeStatus? status,
    DateTime? lastSeen,
    double? signalStrength,
    int? hopCount,
    String? currentLocation,
    bool? isEncryptionSupported,
    String? publicKey,
    Map<String, dynamic>? metadata,
  }) {
    return MeshPeer(
      nodeId: nodeId ?? this.nodeId,
      displayName: displayName ?? this.displayName,
      nodeType: nodeType ?? this.nodeType,
      deviceModel: deviceModel ?? this.deviceModel,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      supportedConnections: supportedConnections ?? this.supportedConnections,
      capabilities: capabilities ?? this.capabilities,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      signalStrength: signalStrength ?? this.signalStrength,
      hopCount: hopCount ?? this.hopCount,
      currentLocation: currentLocation ?? this.currentLocation,
      isEncryptionSupported: isEncryptionSupported ?? this.isEncryptionSupported,
      publicKey: publicKey ?? this.publicKey,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if peer is currently online
  bool get isOnline => status == NodeStatus.online;

  /// Check if peer was seen recently (within last 5 minutes)
  bool get isRecent {
    return DateTime.now().difference(lastSeen).inMinutes <= 5;
  }

  /// Check if peer is in emergency mode
  bool get isInEmergency => status == NodeStatus.emergency;

  /// Get connection quality based on signal strength and hop count
  ConnectionQuality get connectionQuality {
    if (signalStrength == null) return ConnectionQuality.unknown;
    
    // Adjust quality based on hop count
    double adjustedStrength = signalStrength! - (hopCount * 10);
    
    if (adjustedStrength >= -50) return ConnectionQuality.excellent;
    if (adjustedStrength >= -60) return ConnectionQuality.good;
    if (adjustedStrength >= -70) return ConnectionQuality.fair;
    if (adjustedStrength >= -80) return ConnectionQuality.poor;
    return ConnectionQuality.veryPoor;
  }

  /// Get human-readable status
  String get statusText {
    switch (status) {
      case NodeStatus.online:
        return 'Online';
      case NodeStatus.offline:
        return 'Offline';
      case NodeStatus.busy:
        return 'Busy';
      case NodeStatus.away:
        return 'Away';
      case NodeStatus.emergency:
        return 'EMERGENCY';
      case NodeStatus.maintenance:
        return 'Maintenance';
    }
  }

  /// Get node type icon
  String get nodeTypeIcon {
    switch (nodeType) {
      case NodeType.mobile:
        return '📱';
      case NodeType.desktop:
        return '💻';
      case NodeType.embedded:
        return '🔧';
      case NodeType.gateway:
        return '🌐';
      case NodeType.repeater:
        return '📡';
      case NodeType.emergency:
        return '🚨';
    }
  }

  /// Get status color
  String get statusColor {
    switch (status) {
      case NodeStatus.online:
        return '#4CAF50'; // Green
      case NodeStatus.offline:
        return '#9E9E9E'; // Grey
      case NodeStatus.busy:
        return '#FF9800'; // Orange
      case NodeStatus.away:
        return '#FFEB3B'; // Yellow
      case NodeStatus.emergency:
        return '#F44336'; // Red
      case NodeStatus.maintenance:
        return '#9C27B0'; // Purple
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'displayName': displayName,
      'nodeType': nodeType.name,
      'deviceModel': deviceModel,
      'operatingSystem': operatingSystem,
      'supportedConnections': supportedConnections.map((e) => e.name).toList(),
      'capabilities': capabilities,
      'status': status.name,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'signalStrength': signalStrength,
      'hopCount': hopCount,
      'currentLocation': currentLocation,
      'isEncryptionSupported': isEncryptionSupported,
      'publicKey': publicKey,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory MeshPeer.fromJson(Map<String, dynamic> json) {
    return MeshPeer(
      nodeId: json['nodeId'],
      displayName: json['displayName'],
      nodeType: NodeType.values.firstWhere((e) => e.name == json['nodeType']),
      deviceModel: json['deviceModel'],
      operatingSystem: json['operatingSystem'],
      supportedConnections: (json['supportedConnections'] as List?)
          ?.map((e) => ConnectionType.values.firstWhere((ct) => ct.name == e))
          .toList() ?? [],
      capabilities: Map<String, dynamic>.from(json['capabilities'] ?? {}),
      status: NodeStatus.values.firstWhere((e) => e.name == json['status']),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen']),
      signalStrength: json['signalStrength']?.toDouble(),
      hopCount: json['hopCount'] ?? 0,
      currentLocation: json['currentLocation'],
      isEncryptionSupported: json['isEncryptionSupported'] ?? false,
      publicKey: json['publicKey'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'MeshPeer(id: $nodeId, name: $displayName, type: $nodeType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeshPeer && other.nodeId == nodeId;
  }

  @override
  int get hashCode => nodeId.hashCode;
}

/// Enum for connection quality
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
  veryPoor,
  unknown,
}

/// Extension for connection quality
extension ConnectionQualityExtension on ConnectionQuality {
  String get displayName {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.veryPoor:
        return 'Very Poor';
      case ConnectionQuality.unknown:
        return 'Unknown';
    }
  }

  String get icon {
    switch (this) {
      case ConnectionQuality.excellent:
        return '📶';
      case ConnectionQuality.good:
        return '📶';
      case ConnectionQuality.fair:
        return '📶';
      case ConnectionQuality.poor:
        return '📶';
      case ConnectionQuality.veryPoor:
        return '📶';
      case ConnectionQuality.unknown:
        return '❓';
    }
  }

  double get strength {
    switch (this) {
      case ConnectionQuality.excellent:
        return 1.0;
      case ConnectionQuality.good:
        return 0.8;
      case ConnectionQuality.fair:
        return 0.6;
      case ConnectionQuality.poor:
        return 0.4;
      case ConnectionQuality.veryPoor:
        return 0.2;
      case ConnectionQuality.unknown:
        return 0.0;
    }
  }
}

/// Model for active connections between peers
class PeerConnection {
  final String connectionId;
  final String localNodeId;
  final String remoteNodeId;
  final ConnectionType connectionType;
  final DateTime establishedAt;
  final double? bandwidth; // Mbps
  final double? latency; // milliseconds
  final int bytesTransmitted;
  final int bytesReceived;
  final bool isSecure;

  DateTime lastActivity;
  ConnectionStatus status;

  PeerConnection({
    required this.connectionId,
    required this.localNodeId,
    required this.remoteNodeId,
    required this.connectionType,
    required this.establishedAt,
    this.bandwidth,
    this.latency,
    this.bytesTransmitted = 0,
    this.bytesReceived = 0,
    this.isSecure = false,
    required this.lastActivity,
    this.status = ConnectionStatus.active,
  });

  /// Get connection duration
  Duration get duration => DateTime.now().difference(establishedAt);

  /// Get total bytes transferred
  int get totalBytes => bytesTransmitted + bytesReceived;

  /// Check if connection is active
  bool get isActive => status == ConnectionStatus.active;

  /// Get connection type icon
  String get connectionIcon {
    switch (connectionType) {
      case ConnectionType.bluetooth:
        return '🔷';
      case ConnectionType.wifiDirect:
        return '📶';
      case ConnectionType.sdr:
        return '📻';
      case ConnectionType.hamRadio:
        return '📡';
      case ConnectionType.internet:
        return '🌐';
      case ConnectionType.hybrid:
        return '🔗';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'localNodeId': localNodeId,
      'remoteNodeId': remoteNodeId,
      'connectionType': connectionType.name,
      'establishedAt': establishedAt.millisecondsSinceEpoch,
      'bandwidth': bandwidth,
      'latency': latency,
      'bytesTransmitted': bytesTransmitted,
      'bytesReceived': bytesReceived,
      'isSecure': isSecure,
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  /// Create from JSON
  factory PeerConnection.fromJson(Map<String, dynamic> json) {
    return PeerConnection(
      connectionId: json['connectionId'],
      localNodeId: json['localNodeId'],
      remoteNodeId: json['remoteNodeId'],
      connectionType: ConnectionType.values.firstWhere((e) => e.name == json['connectionType']),
      establishedAt: DateTime.fromMillisecondsSinceEpoch(json['establishedAt']),
      bandwidth: json['bandwidth']?.toDouble(),
      latency: json['latency']?.toDouble(),
      bytesTransmitted: json['bytesTransmitted'] ?? 0,
      bytesReceived: json['bytesReceived'] ?? 0,
      isSecure: json['isSecure'] ?? false,
      lastActivity: DateTime.fromMillisecondsSinceEpoch(json['lastActivity']),
      status: ConnectionStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }
}

/// Enum for connection status
enum ConnectionStatus {
  active,
  inactive,
  connecting,
  disconnecting,
  failed,
}
