// lib/models/peer.dart - BitChat'teki Peer management
class Peer {
  final String id;
  final String name;
  final DateTime lastSeen;
  final double signalStrength;
  final List<String> supportedProtocols;
  final PeerStatus status;
  final String? ipAddress;
  final int? port;
  
  Peer({
    required this.id,
    required this.name,
    required this.lastSeen,
    this.signalStrength = -1.0,
    this.supportedProtocols = const ['bluetooth_le'],
    this.status = PeerStatus.discovered,
    this.ipAddress,
    this.port,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lastSeen': lastSeen.toIso8601String(),
    'signalStrength': signalStrength,
    'supportedProtocols': supportedProtocols,
    'status': status.toString(),
    'ipAddress': ipAddress,
    'port': port,
  };
  
  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      id: json['id'],
      name: json['name'],
      lastSeen: DateTime.parse(json['lastSeen']),
      signalStrength: json['signalStrength'] ?? -1.0,
      supportedProtocols: List<String>.from(json['supportedProtocols'] ?? ['bluetooth_le']),
      status: PeerStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PeerStatus.discovered,
      ),
      ipAddress: json['ipAddress'],
      port: json['port'],
    );
  }
  
  // BitChat'teki peer management logic
  bool isOnline() {
    final now = DateTime.now();
    final timeDiff = now.difference(lastSeen);
    return timeDiff.inMinutes < 5; // 5 dakika içinde görüldüyse online
  }
  
  Peer updateLastSeen() {
    return Peer(
      id: id,
      name: name,
      lastSeen: DateTime.now(),
      signalStrength: signalStrength,
      supportedProtocols: supportedProtocols,
      status: status,
      ipAddress: ipAddress,
      port: port,
    );
  }
}

enum PeerStatus {
  discovered,
  connecting,
  connected,
  disconnected,
  blocked
}

class RouteInfo {
  final List<String> path;
  final int hopCount;
  final double reliability;
  final DateTime lastUsed;
  
  RouteInfo({
    required this.path,
    required this.hopCount,
    this.reliability = 1.0,
    required this.lastUsed,
  });
  
  Map<String, dynamic> toJson() => {
    'path': path,
    'hopCount': hopCount,
    'reliability': reliability,
    'lastUsed': lastUsed.toIso8601String(),
  };
  
  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      path: List<String>.from(json['path']),
      hopCount: json['hopCount'],
      reliability: json['reliability'] ?? 1.0,
      lastUsed: DateTime.parse(json['lastUsed']),
    );
  }
}
