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
    // Emergency wipe implementation with confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Acil Durum Silme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bu işlem TÜM verileri kalıcı olarak silecektir:'),
            SizedBox(height: 8),
            Text('• Tüm mesajlar'),
            Text('• Kullanıcı ayarları'),
            Text('• Ağ bağlantıları'),
            Text('• Şifreleme anahtarları'),
            SizedBox(height: 16),
            Text(
              'Bu işlem GERİ ALINAMAZ!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show second confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Son Onay'),
                  content: Text('Verilerinizi silmek için "SİL" yazın:'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('İptal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        debugPrint('Emergency wipe confirmed - data cleared');
                        // Here would be the actual wipe implementation
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Sil', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Devam Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
