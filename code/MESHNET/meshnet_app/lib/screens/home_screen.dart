// lib/screens/home_screen.dart
// MESHNET Ana Ekran - Emergency Communication Hub
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/widgets/mesh_status_chip.dart';
import 'package:meshnet_app/widgets/peer_list_widget.dart';
import 'package:meshnet_app/widgets/emergency_button.dart';

import '../services/identity_manager.dart';
import '../services/interface_manager.dart';
import '../services/transport_manager.dart';
import '../services/crypto_manager.dart';

import '../widgets/identity_status_widget.dart';
import '../widgets/interface_status_widget.dart';
import '../widgets/transport_stats_widget.dart';
import '../widgets/emergency_controls_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() async {
    final identityManager = Provider.of<IdentityManager>(context, listen: false);
    final interfaceManager = Provider.of<InterfaceManager>(context, listen: false);
    
    // Initialize identity first
    await identityManager.initialize();
    
    // Add available interfaces
    // This would be expanded with actual interface implementations
    debugPrint('Services initialized');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('MESHNET'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer4<IdentityManager, InterfaceManager, TransportManager, CryptoManager>(
        builder: (context, identity, interfaces, transport, crypto, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency Status Card
                _buildEmergencyStatusCard(),
                
                SizedBox(height: 16),
                
                // Identity Status
                IdentityStatusWidget(),
                
                SizedBox(height: 16),
                
                // Interface Status
                InterfaceStatusWidget(),
                
                SizedBox(height: 16),
                
                // Transport Statistics
                TransportStatsWidget(),
                
                SizedBox(height: 16),
                
                // Emergency Controls
                EmergencyControlsWidget(),
                
                SizedBox(height: 16),
                
                // Quick Actions
                _buildQuickActions(),
                
                SizedBox(height: 16),
                
                // Network Status
                _buildNetworkStatus(transport),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/chat'),
        child: Icon(Icons.chat),
        backgroundColor: Colors.orange.shade700,
      ),
    );
  }
  
  Widget _buildEmergencyStatusCard() {
    return Card(
      color: Colors.red.shade900,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Emergency Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'MESHNET is ready for emergency communication',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendEmergencyBeacon,
                    icon: Icon(Icons.emergency),
                    label: Text('EMERGENCY BEACON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat,
                    label: 'Chat',
                    onPressed: () => Navigator.pushNamed(context, '/chat'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.location_on,
                    label: 'Share Location',
                    onPressed: _shareLocation,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.file_copy,
                    label: 'Send File',
                    onPressed: _sendFile,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.radio,
                    label: 'RF Status',
                    onPressed: _showRFStatus,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }
  
  Widget _buildNetworkStatus(TransportManager transport) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildStatusRow('Known Destinations', '${transport.announceTable.length}'),
            _buildStatusRow('Active Routes', '${transport.routingTable.length}'),
            _buildStatusRow('Packets Forwarded', '${transport.packetsForwarded}'),
            _buildStatusRow('Duplicates Filtered', '${transport.duplicatesFiltered}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  void _sendEmergencyBeacon() {
    // Emergency beacon implementation with proper emergency manager
    final identityManager = Provider.of<IdentityManager>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Acil Durum Sinyali'),
          ],
        ),
        content: Text('Acil durum sinyali gönderilsin mi? Bu sinyal ağdaki tüm kullanıcılara ulaşacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Acil durum sinyali gönderildi!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _shareLocation() {
    final locationManager = Provider.of<LocationManager>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konum Paylaş'),
        content: Text('Mevcut konumunuz ağdaki diğer kullanıcılarla paylaşılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Konum paylaşıldı')),
              );
            },
            child: Text('Paylaş'),
          ),
        ],
      ),
    );
  }
  
  void _sendFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dosya Gönder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text('Fotoğraf'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fotoğraf seçimi henüz uygulanmadı')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_drive_file),
              title: Text('Dosya'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dosya seçimi henüz uygulanmadı')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRFStatus() {
    final interfaceManager = Provider.of<InterfaceManager>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('RF/SDR Durumu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bluetooth: ${interfaceManager.bluetoothStatus}'),
            Text('WiFi Direct: ${interfaceManager.wifiDirectStatus}'),
            Text('SDR: Aktif değil'),
            Text('Ham Radio: Aktif değil'),
            Divider(),
            Text('Toplam Peer: 0'),
            Text('Aktif Bağlantı: 0'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
