// test/models/mesh_peer_test.dart - Mesh Peer Model Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:meshnet_app/models/peer.dart';

void main() {
  group('MeshPeer Tests', () {
    test('should create basic mesh peer', () {
      final peer = MeshPeer(
        nodeId: 'node123',
        displayName: 'Test Device',
        nodeType: NodeType.mobile,
        lastSeen: DateTime.now(),
      );

      expect(peer.nodeId, 'node123');
      expect(peer.displayName, 'Test Device');
      expect(peer.nodeType, NodeType.mobile);
      expect(peer.status, NodeStatus.offline);
      expect(peer.hopCount, 0);
      expect(peer.isEncryptionSupported, false);
      expect(peer.supportedConnections, isEmpty);
      expect(peer.capabilities, isEmpty);
      expect(peer.metadata, isEmpty);
    });

    test('should create peer with all properties', () {
      final capabilities = {
        'maxBandwidth': 1000,
        'batteryLevel': 85,
        'storage': 'high',
      };

      final metadata = {
        'version': '1.0.0',
        'build': '123',
      };

      final peer = MeshPeer(
        nodeId: 'node_full',
        displayName: 'Full Feature Device',
        nodeType: NodeType.desktop,
        deviceModel: 'TestDevice Pro',
        operatingSystem: 'Linux',
        supportedConnections: [
          ConnectionType.bluetooth,
          ConnectionType.wifiDirect,
          ConnectionType.sdr
        ],
        capabilities: capabilities,
        status: NodeStatus.online,
        lastSeen: DateTime.now(),
        signalStrength: -65.5,
        hopCount: 2,
        currentLocation: 'Building A, Floor 3',
        isEncryptionSupported: true,
        publicKey: 'rsa_public_key_data',
        metadata: metadata,
      );

      expect(peer.nodeId, 'node_full');
      expect(peer.displayName, 'Full Feature Device');
      expect(peer.nodeType, NodeType.desktop);
      expect(peer.deviceModel, 'TestDevice Pro');
      expect(peer.operatingSystem, 'Linux');
      expect(peer.supportedConnections.length, 3);
      expect(peer.capabilities, capabilities);
      expect(peer.status, NodeStatus.online);
      expect(peer.signalStrength, -65.5);
      expect(peer.hopCount, 2);
      expect(peer.currentLocation, 'Building A, Floor 3');
      expect(peer.isEncryptionSupported, true);
      expect(peer.publicKey, 'rsa_public_key_data');
      expect(peer.metadata, metadata);
    });

    test('should check online status correctly', () {
      final onlinePeer = MeshPeer(
        nodeId: 'online_node',
        displayName: 'Online Device',
        nodeType: NodeType.mobile,
        status: NodeStatus.online,
        lastSeen: DateTime.now(),
      );

      final offlinePeer = MeshPeer(
        nodeId: 'offline_node',
        displayName: 'Offline Device',
        nodeType: NodeType.mobile,
        status: NodeStatus.offline,
        lastSeen: DateTime.now().subtract(Duration(hours: 1)),
      );

      expect(onlinePeer.isOnline, true);
      expect(offlinePeer.isOnline, false);
    });

    test('should check recent activity correctly', () {
      final recentPeer = MeshPeer(
        nodeId: 'recent_node',
        displayName: 'Recent Device',
        nodeType: NodeType.mobile,
        lastSeen: DateTime.now().subtract(Duration(minutes: 3)),
      );

      final oldPeer = MeshPeer(
        nodeId: 'old_node',
        displayName: 'Old Device',
        nodeType: NodeType.mobile,
        lastSeen: DateTime.now().subtract(Duration(minutes: 10)),
      );

      expect(recentPeer.isRecent, true);
      expect(oldPeer.isRecent, false);
    });

    test('should detect emergency status', () {
      final emergencyPeer = MeshPeer(
        nodeId: 'emergency_node',
        displayName: 'Emergency Device',
        nodeType: NodeType.emergency,
        status: NodeStatus.emergency,
        lastSeen: DateTime.now(),
      );

      final normalPeer = MeshPeer(
        nodeId: 'normal_node',
        displayName: 'Normal Device',
        nodeType: NodeType.mobile,
        status: NodeStatus.online,
        lastSeen: DateTime.now(),
      );

      expect(emergencyPeer.isInEmergency, true);
      expect(normalPeer.isInEmergency, false);
    });

    test('should calculate connection quality correctly', () {
      // Excellent quality: strong signal, direct connection
      final excellentPeer = MeshPeer(
        nodeId: 'excellent',
        displayName: 'Excellent Connection',
        nodeType: NodeType.mobile,
        signalStrength: -40.0, // Very strong signal
        hopCount: 0, // Direct connection
        lastSeen: DateTime.now(),
      );

      // Good quality: good signal, low hop count
      final goodPeer = MeshPeer(
        nodeId: 'good',
        displayName: 'Good Connection',
        nodeType: NodeType.mobile,
        signalStrength: -45.0, // Good signal
        hopCount: 1, // One hop
        lastSeen: DateTime.now(),
      );

      // Poor quality: weak signal, high hop count
      final poorPeer = MeshPeer(
        nodeId: 'poor',
        displayName: 'Poor Connection',
        nodeType: NodeType.mobile,
        signalStrength: -75.0,
        hopCount: 3,
        lastSeen: DateTime.now(),
      );

      // Unknown quality: no signal data
      final unknownPeer = MeshPeer(
        nodeId: 'unknown',
        displayName: 'Unknown Connection',
        nodeType: NodeType.mobile,
        signalStrength: null,
        lastSeen: DateTime.now(),
      );

      expect(excellentPeer.connectionQuality, ConnectionQuality.excellent);
      expect(goodPeer.connectionQuality, ConnectionQuality.good);
      expect(poorPeer.connectionQuality, ConnectionQuality.veryPoor);
      expect(unknownPeer.connectionQuality, ConnectionQuality.unknown);
    });

    test('should return correct status text', () {
      final statuses = [
        (NodeStatus.online, 'Online'),
        (NodeStatus.offline, 'Offline'),
        (NodeStatus.busy, 'Busy'),
        (NodeStatus.away, 'Away'),
        (NodeStatus.emergency, 'EMERGENCY'),
        (NodeStatus.maintenance, 'Maintenance'),
      ];

      for (final (status, expectedText) in statuses) {
        final peer = MeshPeer(
          nodeId: 'test_${status.name}',
          displayName: 'Test Device',
          nodeType: NodeType.mobile,
          status: status,
          lastSeen: DateTime.now(),
        );

        expect(peer.statusText, expectedText);
      }
    });

    test('should support different node types', () {
      final nodeTypes = [
        NodeType.mobile,
        NodeType.desktop,
        NodeType.embedded,
        NodeType.gateway,
        NodeType.repeater,
        NodeType.emergency,
      ];

      for (final nodeType in nodeTypes) {
        final peer = MeshPeer(
          nodeId: 'test_${nodeType.name}',
          displayName: 'Test ${nodeType.name}',
          nodeType: nodeType,
          lastSeen: DateTime.now(),
        );

        expect(peer.nodeType, nodeType);
      }
    });

    test('should support different connection types', () {
      final connectionTypes = [
        ConnectionType.bluetooth,
        ConnectionType.wifiDirect,
        ConnectionType.sdr,
        ConnectionType.hamRadio,
        ConnectionType.internet,
        ConnectionType.hybrid,
      ];

      final peer = MeshPeer(
        nodeId: 'multi_connection',
        displayName: 'Multi-Connection Device',
        nodeType: NodeType.gateway,
        supportedConnections: connectionTypes,
        lastSeen: DateTime.now(),
      );

      expect(peer.supportedConnections, connectionTypes);
      expect(peer.supportedConnections.length, 6);
    });

    test('should create copy with updated fields', () {
      final originalPeer = MeshPeer(
        nodeId: 'original',
        displayName: 'Original Device',
        nodeType: NodeType.mobile,
        status: NodeStatus.offline,
        lastSeen: DateTime.now(),
        signalStrength: -70.0,
        hopCount: 1,
      );

      final updatedPeer = originalPeer.copyWith(
        displayName: 'Updated Device',
        status: NodeStatus.online,
        signalStrength: -60.0,
        hopCount: 0,
      );

      // Check that some fields are updated
      expect(updatedPeer.displayName, 'Updated Device');
      expect(updatedPeer.status, NodeStatus.online);
      expect(updatedPeer.signalStrength, -60.0);
      expect(updatedPeer.hopCount, 0);

      // Check that unchanged fields remain the same
      expect(updatedPeer.nodeId, originalPeer.nodeId);
      expect(updatedPeer.nodeType, originalPeer.nodeType);
      expect(updatedPeer.lastSeen, originalPeer.lastSeen);
    });

    test('should handle signal strength ranges correctly', () {
      final strongSignalPeer = MeshPeer(
        nodeId: 'strong',
        displayName: 'Strong Signal',
        nodeType: NodeType.mobile,
        signalStrength: -30.0, // Very strong
        hopCount: 1,
        lastSeen: DateTime.now(),
      );

      final weakSignalPeer = MeshPeer(
        nodeId: 'weak',
        displayName: 'Weak Signal',
        nodeType: NodeType.mobile,
        signalStrength: -90.0, // Very weak
        hopCount: 1,
        lastSeen: DateTime.now(),
      );

      expect(strongSignalPeer.connectionQuality, ConnectionQuality.excellent);
      expect(weakSignalPeer.connectionQuality, ConnectionQuality.veryPoor);
    });

    test('should handle hop count impact on connection quality', () {
      final directPeer = MeshPeer(
        nodeId: 'direct',
        displayName: 'Direct Connection',
        nodeType: NodeType.mobile,
        signalStrength: -60.0,
        hopCount: 0, // Direct connection
        lastSeen: DateTime.now(),
      );

      final multiHopPeer = MeshPeer(
        nodeId: 'multihop',
        displayName: 'Multi-hop Connection',
        nodeType: NodeType.mobile,
        signalStrength: -60.0,
        hopCount: 3, // 3 hops away
        lastSeen: DateTime.now(),
      );

      // Same signal strength, but multi-hop should have worse quality
      expect(directPeer.connectionQuality.index, 
             lessThan(multiHopPeer.connectionQuality.index));
    });
  });
}
