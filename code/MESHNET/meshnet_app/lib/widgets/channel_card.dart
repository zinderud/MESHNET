// lib/widgets/channel_card.dart - Kanal bilgi kartı
import 'package:flutter/material.dart';
import 'package:meshnet_app/models/mesh_channel.dart';

class ChannelCard extends StatelessWidget {
  final MeshChannel channel;
  final VoidCallback? onTap;

  const ChannelCard({
    Key? key,
    required this.channel,
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
                children: [
                  Icon(
                    channel.isPublic ? Icons.public : Icons.lock,
                    color: channel.isPublic ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      channel.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              if (channel.description != null && channel.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  channel.description!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    '${channel.memberCount} Üye',
                    Icons.people,
                    Colors.green,
                  ),
                  _buildInfoChip(
                    '${channel.messageCount} Mesaj',
                    Icons.message,
                    Colors.purple,
                  ),
                  if (channel.lastActivity != null)
                    _buildInfoChip(
                      _formatLastActivity(channel.lastActivity!),
                      Icons.timer,
                      Colors.grey,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final difference = DateTime.now().difference(lastActivity);
    if (difference.inSeconds < 60) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }
}
