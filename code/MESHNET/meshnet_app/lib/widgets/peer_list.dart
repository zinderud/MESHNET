// lib/widgets/peer_list.dart - BitChat'teki peer discovery display
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_manager.dart';
import '../models/peer.dart';

class PeerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothManager>(
      builder: (context, bluetoothManager, child) {
        final peers = bluetoothManager.discoveredPeers;
        final isScanning = bluetoothManager.isScanning;
        
        return Column(
          children: [
            // Scanning controls
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isScanning 
                          ? () => bluetoothManager.stopScanning()
                          : () => bluetoothManager.startScanning(),
                      icon: Icon(isScanning ? Icons.stop : Icons.search),
                      label: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScanning ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scanning indicator
            if (isScanning)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Scanning for peers...',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 16),
            
            // Peers list
            Expanded(
              child: peers.isEmpty 
                  ? _buildEmptyState(isScanning)
                  : ListView.builder(
                      itemCount: peers.length,
                      itemBuilder: (context, index) {
                        final peer = peers[index];
                        return _buildPeerTile(context, peer, bluetoothManager);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildEmptyState(bool isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            isScanning 
                ? 'Searching for peers...'
                : 'No peers discovered',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          if (!isScanning) ...[
            SizedBox(height: 8),
            Text(
              'Tap "Start Scan" to discover nearby devices',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPeerTile(BuildContext context, Peer peer, BluetoothManager bluetoothManager) {
    final isOnline = peer.isOnline();
    final isConnected = peer.status == PeerStatus.connected;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getPeerColor(peer),
              child: Text(
                peer.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            
            // Online/offline indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        
        title: Text(
          peer.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOnline ? Colors.white : Colors.grey[400],
          ),
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              peer.id,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            
            SizedBox(height: 4),
            
            Row(
              children: [
                // Signal strength
                if (peer.signalStrength > -1) ...[
                  Icon(
                    _getSignalIcon(peer.signalStrength),
                    size: 12,
                    color: _getSignalColor(peer.signalStrength),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${peer.signalStrength.toInt()} dBm',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                
                // Last seen
                Text(
                  'Last seen: ${_formatLastSeen(peer.lastSeen)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            
            // Supported protocols
            Wrap(
              spacing: 4,
              children: peer.supportedProtocols.map((protocol) {
                return Chip(
                  label: Text(
                    protocol.toUpperCase(),
                    style: TextStyle(fontSize: 8),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
        
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Connection status
            Icon(
              isConnected ? Icons.link : Icons.link_off,
              color: isConnected ? Colors.green : Colors.grey,
              size: 20,
            ),
            
            Text(
              _getStatusText(peer.status),
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.grey[400],
                fontSize: 10,
              ),
            ),
          ],
        ),
        
        onTap: () => _handlePeerTap(context, peer, bluetoothManager),
      ),
    );
  }
  
  Color _getPeerColor(Peer peer) {
    final hash = peer.id.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[hash.abs() % colors.length];
  }
  
  IconData _getSignalIcon(double strength) {
    if (strength > -50) return Icons.signal_wifi_4_bar;
    if (strength > -70) return Icons.signal_wifi_3_bar;
    if (strength > -80) return Icons.signal_wifi_2_bar;
    if (strength > -90) return Icons.signal_wifi_1_bar;
    return Icons.signal_wifi_0_bar;
  }
  
  Color _getSignalColor(double strength) {
    if (strength > -50) return Colors.green;
    if (strength > -70) return Colors.orange;
    return Colors.red;
  }
  
  String _getStatusText(PeerStatus status) {
    switch (status) {
      case PeerStatus.discovered:
        return 'Discovered';
      case PeerStatus.connecting:
        return 'Connecting';
      case PeerStatus.connected:
        return 'Connected';
      case PeerStatus.disconnected:
        return 'Offline';
      case PeerStatus.blocked:
        return 'Blocked';
    }
  }
  
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    
    if (diff.inSeconds < 30) {
      return 'just now';
    } else if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
  
  void _handlePeerTap(BuildContext context, Peer peer, BluetoothManager bluetoothManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(peer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${peer.id}'),
            Text('Status: ${_getStatusText(peer.status)}'),
            if (peer.signalStrength > -1)
              Text('Signal: ${peer.signalStrength.toInt()} dBm'),
            Text('Last seen: ${_formatLastSeen(peer.lastSeen)}'),
            Text('Protocols: ${peer.supportedProtocols.join(', ')}'),
          ],
        ),
        actions: [
          if (peer.status != PeerStatus.connected)
            TextButton(
              onPressed: () {
                bluetoothManager.connectToPeer(peer);
                Navigator.of(context).pop();
              },
              child: Text('Connect'),
            ),
          
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
