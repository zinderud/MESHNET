// lib/widgets/transport_stats_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transport_manager.dart';

class TransportStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TransportManager>(
      builder: (context, transport, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timeline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Transport Statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _buildStatRow('Packets Forwarded', transport.packetsForwarded),
                _buildStatRow('Duplicates Filtered', transport.duplicatesFiltered),
                _buildStatRow('Known Routes', transport.routingTable.length),
                _buildStatRow('Known Destinations', transport.announceTable.length),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
