// lib/widgets/mesh_peer_card.dart - Detaylı peer bilgi kartı
import 'package:flutter/material.dart';
import 'package:meshnet_app/models/mesh_peer.dart';

class MeshPeerCard extends StatelessWidget {
  final MeshPeer peer;
  final VoidCallback? onTap;

  const MeshPeerCard({
    Key? key,
    required this.peer,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    peer.id,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  _buildStatusChip(peer.status),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn('Sinyal', '${peer.signalStrength} dBm', Icons.signal_cellular_alt),
                  _buildInfoColumn('Uzaklık', '${peer.distance.toStringAsFixed(2)} m', Icons.location_on),
                  _buildInfoColumn('Son Görülme', _formatLastSeen(peer.lastSeen), Icons.timer),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(PeerStatus status) {
    Color color;
    String text;
    switch (status) {
      case PeerStatus.connected:
        color = Colors.green;
        text = 'Bağlı';
        break;
      case PeerStatus.disconnected:
        color = Colors.red;
        text = 'Bağlantı Kesildi';
        break;
      case PeerStatus.connecting:
        color = Colors.orange;
        text = 'Bağlanıyor';
        break;
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final difference = DateTime.now().difference(lastSeen);
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d önce';
    } else {
      return '${difference.inHours}s önce';
    }
  }
}
