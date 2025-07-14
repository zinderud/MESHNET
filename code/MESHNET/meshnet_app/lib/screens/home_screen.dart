// lib/screens/home_screen.dart
// MESHNET Ana Ekran - Emergency Communication Hub
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    // TODO: Implement emergency beacon
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emergency beacon sent!'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _shareLocation() {
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Location sharing not implemented yet')),
    );
  }
  
  void _sendFile() {
    // TODO: Implement file sending
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File sending not implemented yet')),
    );
  }
  
  void _showRFStatus() {
    // TODO: Show RF/SDR status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('RF status not implemented yet')),
    );
  }
}
