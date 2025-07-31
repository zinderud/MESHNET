// test/models/peer_test.dart - Peer Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/peer.dart';

void main() {
  group('NodeType Tests', () {
    test('should have all node types', () {
      expect(NodeType.values.length, 6);
      expect(NodeType.values, contains(NodeType.mobile));
      expect(NodeType.values, contains(NodeType.desktop));
      expect(NodeType.values, contains(NodeType.iot));
      expect(NodeType.values, contains(NodeType.gateway));
      expect(NodeType.values, contains(NodeType.relay));
      expect(NodeType.values, contains(NodeType.emergency));
    });
  });

  group('NodeStatus Tests', () {
    test('should have all node statuses', () {
      expect(NodeStatus.values.length, 6);
      expect(NodeStatus.values, contains(NodeStatus.online));
      expect(NodeStatus.values, contains(NodeStatus.offline));
      expect(NodeStatus.values, contains(NodeStatus.connecting));
      expect(NodeStatus.values, contains(NodeStatus.disconnecting));
      expect(NodeStatus.values, contains(NodeStatus.idle));
      expect(NodeStatus.values, contains(NodeStatus.busy));
    });
  });

  group('ConnectionType Tests', () {
    test('should have all connection types', () {
      expect(ConnectionType.values.length, 7);
      expect(ConnectionType.values, contains(ConnectionType.bluetooth));
      expect(ConnectionType.values, contains(ConnectionType.wifi));
      expect(ConnectionType.values, contains(ConnectionType.wifiDirect));
      expect(ConnectionType.values, contains(ConnectionType.ethernet));
      expect(ConnectionType.values, contains(ConnectionType.cellular));
      expect(ConnectionType.values, contains(ConnectionType.sdr));
      expect(ConnectionType.values, contains(ConnectionType.hamRadio));
    });
  });

  group('PeerConnection Tests', () {
    late PeerConnection testConnection;

    setUp(() {
      testConnection = PeerConnection(
        peerId: 'peer_123',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -60,
        establishedAt: DateTime.now(),
        isSecure: true,
      );
    });

    test('should create connection with required fields', () {
      expect(testConnection.peerId, 'peer_123');
      expect(testConnection.connectionType, ConnectionType.bluetooth);
      expect(testConnection.signalStrength, -60);
      expect(testConnection.establishedAt, isA<DateTime>());
      expect(testConnection.isSecure, true);
    });

    test('should have default values for optional fields', () {
      expect(testConnection.bandwidth, isNull);
      expect(testConnection.latency, isNull);
      expect(testConnection.lastActivity, isNull);
      expect(testConnection.connectionMetadata, isEmpty);
    });

    test('should calculate connection quality', () {
      // Strong signal
      final strongConnection = PeerConnection(
        peerId: 'strong_peer',
        connectionType: ConnectionType.wifi,
        signalStrength: -30,
        establishedAt: DateTime.now(),
        isSecure: true,
        bandwidth: 100.0,
        latency: 10,
      );

      // Weak signal
      final weakConnection = PeerConnection(
        peerId: 'weak_peer',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -90,
        establishedAt: DateTime.now(),
        isSecure: false,
        bandwidth: 1.0,
        latency: 500,
      );

      expect(strongConnection.connectionQuality, ConnectionQuality.excellent);
      expect(weakConnection.connectionQuality, ConnectionQuality.poor);
    });

    test('should detect stable connections', () {
      final stableConnection = PeerConnection(
        peerId: 'stable_peer',
        connectionType: ConnectionType.ethernet,
        signalStrength: -40,
        establishedAt: DateTime.now().subtract(Duration(minutes: 30)),
        isSecure: true,
        bandwidth: 50.0,
        latency: 20,
      );

      final unstableConnection = PeerConnection(
        peerId: 'unstable_peer',
        connectionType: ConnectionType.cellular,
        signalStrength: -85,
        establishedAt: DateTime.now().subtract(Duration(seconds: 30)),
        isSecure: false,
        bandwidth: 0.5,
        latency: 1000,
      );

      expect(stableConnection.isStable, true);
      expect(unstableConnection.isStable, false);
    });

    test('should serialize to JSON correctly', () {
      final json = testConnection.toJson();

      expect(json['peerId'], 'peer_123');
      expect(json['connectionType'], 'bluetooth');
      expect(json['signalStrength'], -60);
      expect(json['establishedAt'], isA<int>());
      expect(json['isSecure'], true);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'peerId': 'json_peer_456',
        'connectionType': 'wifi',
        'signalStrength': -45,
        'establishedAt': DateTime.now().millisecondsSinceEpoch,
        'isSecure': false,
        'bandwidth': 25.5,
        'latency': 100,
        'connectionMetadata': {'protocol': 'TCP'},
      };

      final connection = PeerConnection.fromJson(json);

      expect(connection.peerId, 'json_peer_456');
      expect(connection.connectionType, ConnectionType.wifi);
      expect(connection.signalStrength, -45);
      expect(connection.isSecure, false);
      expect(connection.bandwidth, 25.5);
      expect(connection.latency, 100);
      expect(connection.connectionMetadata, {'protocol': 'TCP'});
    });
  });

  group('MeshPeer Tests', () {
    late MeshPeer testPeer;
    late DateTime testTimestamp;

    setUp(() {
      testTimestamp = DateTime.now();
      testPeer = MeshPeer(
        id: 'test_peer_123',
        name: 'Test Peer',
        nodeType: NodeType.mobile,
        publicKey: 'test_public_key_123',
        lastSeen: testTimestamp,
      );
    });

    test('should create peer with required fields', () {
      expect(testPeer.id, 'test_peer_123');
      expect(testPeer.name, 'Test Peer');
      expect(testPeer.nodeType, NodeType.mobile);
      expect(testPeer.publicKey, 'test_public_key_123');
      expect(testPeer.lastSeen, testTimestamp);
    });

    test('should have default values for optional fields', () {
      expect(testPeer.status, NodeStatus.offline);
      expect(testPeer.capabilities, isEmpty);
      expect(testPeer.location, isNull);
      expect(testPeer.metadata, isEmpty);
      expect(testPeer.connections, isEmpty);
      expect(testPeer.isVerified, false);
      expect(testPeer.trustScore, 0.0);
    });

    test('should detect online status', () {
      final onlinePeer = testPeer.copyWith(status: NodeStatus.online);
      final offlinePeer = testPeer.copyWith(status: NodeStatus.offline);
      final connectingPeer = testPeer.copyWith(status: NodeStatus.connecting);

      expect(onlinePeer.isOnline, true);
      expect(offlinePeer.isOnline, false);
      expect(connectingPeer.isOnline, false);
    });

    test('should detect available status', () {
      final availablePeer = testPeer.copyWith(status: NodeStatus.online);
      final busyPeer = testPeer.copyWith(status: NodeStatus.busy);
      final idlePeer = testPeer.copyWith(status: NodeStatus.idle);

      expect(availablePeer.isAvailable, true);
      expect(busyPeer.isAvailable, false);
      expect(idlePeer.isAvailable, true);
    });

    test('should detect trusted peers', () {
      final trustedPeer = testPeer.copyWith(
        isVerified: true,
        trustScore: 0.8,
      );
      
      final untrustedPeer = testPeer.copyWith(
        isVerified: false,
        trustScore: 0.3,
      );

      expect(trustedPeer.isTrusted, true);
      expect(untrustedPeer.isTrusted, false);
    });

    test('should get active connections', () {
      final connection1 = PeerConnection(
        peerId: 'peer_1',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -50,
        establishedAt: DateTime.now(),
        isSecure: true,
      );

      final connection2 = PeerConnection(
        peerId: 'peer_2',
        connectionType: ConnectionType.wifi,
        signalStrength: -30,
        establishedAt: DateTime.now(),
        isSecure: true,
      );

      final peerWithConnections = testPeer.copyWith(
        connections: [connection1, connection2],
      );

      expect(peerWithConnections.activeConnections.length, 2);
      expect(peerWithConnections.activeConnections, contains(connection1));
      expect(peerWithConnections.activeConnections, contains(connection2));
    });

    test('should get best connection', () {
      final bluetoothConnection = PeerConnection(
        peerId: 'peer_bt',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -70,
        establishedAt: DateTime.now(),
        isSecure: true,
        bandwidth: 5.0,
      );

      final wifiConnection = PeerConnection(
        peerId: 'peer_wifi',
        connectionType: ConnectionType.wifi,
        signalStrength: -40,
        establishedAt: DateTime.now(),
        isSecure: true,
        bandwidth: 50.0,
      );

      final peerWithConnections = testPeer.copyWith(
        connections: [bluetoothConnection, wifiConnection],
      );

      final bestConnection = peerWithConnections.bestConnection;
      expect(bestConnection, equals(wifiConnection)); // Better signal and bandwidth
    });

    test('should add connection correctly', () {
      final connection = PeerConnection(
        peerId: 'new_peer',
        connectionType: ConnectionType.wifiDirect,
        signalStrength: -55,
        establishedAt: DateTime.now(),
        isSecure: true,
      );

      testPeer.addConnection(connection);

      expect(testPeer.connections.length, 1);
      expect(testPeer.connections.first, equals(connection));
    });

    test('should remove connection correctly', () {
      final connection1 = PeerConnection(
        peerId: 'peer_1',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -50,
        establishedAt: DateTime.now(),
        isSecure: true,
      );

      final connection2 = PeerConnection(
        peerId: 'peer_2',
        connectionType: ConnectionType.wifi,
        signalStrength: -30,
        establishedAt: DateTime.now(),
        isSecure: true,
      );

      testPeer.addConnection(connection1);
      testPeer.addConnection(connection2);
      expect(testPeer.connections.length, 2);

      testPeer.removeConnection('peer_1');
      expect(testPeer.connections.length, 1);
      expect(testPeer.connections.first.peerId, 'peer_2');

      testPeer.removeConnection('nonexistent');
      expect(testPeer.connections.length, 1); // No change
    });

    test('should update last seen timestamp', () {
      final originalTime = testPeer.lastSeen;
      final newTime = DateTime.now().add(Duration(minutes: 5));

      testPeer.updateLastSeen(newTime);

      expect(testPeer.lastSeen, newTime);
      expect(testPeer.lastSeen.isAfter(originalTime), true);
    });

    test('should copy peer with updated fields', () {
      final updatedPeer = testPeer.copyWith(
        name: 'Updated Peer',
        status: NodeStatus.online,
        trustScore: 0.75,
        isVerified: true,
      );

      expect(updatedPeer.id, testPeer.id); // Unchanged
      expect(updatedPeer.nodeType, testPeer.nodeType); // Unchanged
      expect(updatedPeer.name, 'Updated Peer'); // Changed
      expect(updatedPeer.status, NodeStatus.online); // Changed
      expect(updatedPeer.trustScore, 0.75); // Changed
      expect(updatedPeer.isVerified, true); // Changed
    });

    test('should serialize to JSON correctly', () {
      final json = testPeer.toJson();

      expect(json['id'], 'test_peer_123');
      expect(json['name'], 'Test Peer');
      expect(json['nodeType'], 'mobile');
      expect(json['publicKey'], 'test_public_key_123');
      expect(json['lastSeen'], testTimestamp.millisecondsSinceEpoch);
      expect(json['status'], 'offline');
      expect(json['capabilities'], isEmpty);
      expect(json['location'], isNull);
      expect(json['metadata'], isEmpty);
      expect(json['connections'], isEmpty);
      expect(json['isVerified'], false);
      expect(json['trustScore'], 0.0);
    });

    test('should deserialize from JSON correctly', () {
      final connection = PeerConnection(
        peerId: 'conn_peer',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -60,
        establishedAt: DateTime.now(),
        isSecure: true,
      );

      final json = {
        'id': 'json_peer_456',
        'name': 'JSON Peer',
        'nodeType': 'desktop',
        'publicKey': 'json_public_key_456',
        'lastSeen': testTimestamp.millisecondsSinceEpoch,
        'status': 'online',
        'capabilities': ['chat', 'file_transfer'],
        'location': {'latitude': 40.7128, 'longitude': -74.0060},
        'metadata': {'version': '1.0.0'},
        'connections': [connection.toJson()],
        'isVerified': true,
        'trustScore': 0.85,
      };

      final peer = MeshPeer.fromJson(json);

      expect(peer.id, 'json_peer_456');
      expect(peer.name, 'JSON Peer');
      expect(peer.nodeType, NodeType.desktop);
      expect(peer.publicKey, 'json_public_key_456');
      expect(peer.status, NodeStatus.online);
      expect(peer.capabilities, ['chat', 'file_transfer']);
      expect(peer.location, {'latitude': 40.7128, 'longitude': -74.0060});
      expect(peer.metadata, {'version': '1.0.0'});
      expect(peer.connections.length, 1);
      expect(peer.isVerified, true);
      expect(peer.trustScore, 0.85);
    });

    test('should implement equality correctly', () {
      final peer1 = MeshPeer(
        id: 'same_id',
        name: 'Peer 1',
        nodeType: NodeType.mobile,
        publicKey: 'key_1',
        lastSeen: DateTime.now(),
      );

      final peer2 = MeshPeer(
        id: 'same_id',
        name: 'Peer 2', // Different name
        nodeType: NodeType.desktop, // Different type
        publicKey: 'key_2', // Different key
        lastSeen: DateTime.now(),
      );

      final peer3 = MeshPeer(
        id: 'different_id',
        name: 'Peer 1',
        nodeType: NodeType.mobile,
        publicKey: 'key_1',
        lastSeen: DateTime.now(),
      );

      expect(peer1, equals(peer2)); // Same ID
      expect(peer1, isNot(equals(peer3))); // Different ID
      expect(peer1.hashCode, equals(peer2.hashCode)); // Same hash
    });
  });

  group('ConnectionQuality Tests', () {
    test('should have all quality levels', () {
      expect(ConnectionQuality.values.length, 5);
      expect(ConnectionQuality.values, contains(ConnectionQuality.excellent));
      expect(ConnectionQuality.values, contains(ConnectionQuality.good));
      expect(ConnectionQuality.values, contains(ConnectionQuality.fair));
      expect(ConnectionQuality.values, contains(ConnectionQuality.poor));
      expect(ConnectionQuality.values, contains(ConnectionQuality.unknown));
    });

    test('should calculate quality correctly for different scenarios', () {
      // Test excellent connection
      final excellentConnection = PeerConnection(
        peerId: 'excellent',
        connectionType: ConnectionType.ethernet,
        signalStrength: -20,
        establishedAt: DateTime.now(),
        isSecure: true,
        bandwidth: 100.0,
        latency: 5,
      );

      // Test good connection
      final goodConnection = PeerConnection(
        peerId: 'good',
        connectionType: ConnectionType.wifi,
        signalStrength: -40,
        establishedAt: DateTime.now(),
        isSecure: true,
        bandwidth: 50.0,
        latency: 20,
      );

      // Test fair connection
      final fairConnection = PeerConnection(
        peerId: 'fair',
        connectionType: ConnectionType.bluetooth,
        signalStrength: -65,
        establishedAt: DateTime.now(),
        isSecure: true,
        bandwidth: 10.0,
        latency: 100,
      );

      // Test poor connection
      final poorConnection = PeerConnection(
        peerId: 'poor',
        connectionType: ConnectionType.cellular,
        signalStrength: -90,
        establishedAt: DateTime.now(),
        isSecure: false,
        bandwidth: 1.0,
        latency: 500,
      );

      expect(excellentConnection.connectionQuality, ConnectionQuality.excellent);
      expect(goodConnection.connectionQuality, ConnectionQuality.good);
      expect(fairConnection.connectionQuality, ConnectionQuality.fair);
      expect(poorConnection.connectionQuality, ConnectionQuality.poor);
    });
  });
}
