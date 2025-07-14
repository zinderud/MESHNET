// lib/widgets/identity_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/identity_manager.dart';

class IdentityStatusWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<IdentityManager>(
      builder: (context, identity, child) {
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      color: identity.isInitialized ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Identity Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                if (identity.isInitialized) ...[
                  Text('Identity Hash: ${identity.identityHashHex.substring(0, 16)}...'),
                  Text('Status: Ready', style: TextStyle(color: Colors.green)),
                ] else ...[
                  Text('Status: Not initialized', style: TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => identity.initialize(),
                    child: Text('Initialize Identity'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
