// lib/widgets/emergency_controls_widget.dart
import 'package:flutter/material.dart';

class EmergencyControlsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Emergency Controls',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _emergencyWipe,
                    icon: Icon(Icons.delete_forever),
                    label: Text('EMERGENCY WIPE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'WARNING: This will permanently delete all keys and data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _emergencyWipe() {
    // TODO: Implement emergency wipe with confirmation
    debugPrint('Emergency wipe requested');
  }
}
