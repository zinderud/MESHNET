// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Identity'),
            subtitle: Text('Manage identity and keys'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Identity settings
            },
          ),
          ListTile(
            leading: Icon(Icons.device_hub),
            title: Text('Interfaces'),
            subtitle: Text('Configure network interfaces'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Interface settings
            },
          ),
          ListTile(
            leading: Icon(Icons.radio),
            title: Text('SDR Settings'),
            subtitle: Text('Configure RTL-SDR and HackRF'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: SDR settings
            },
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Security'),
            subtitle: Text('Encryption and privacy settings'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Security settings
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('MESHNET version and info'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MESHNET',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.emergency, size: 48, color: Colors.orange),
      children: [
        Text('Emergency Mesh Network Communication'),
        SizedBox(height: 8),
        Text('Built with Reticulum-inspired architecture'),
        Text('Based on BitChat principles'),
      ],
    );
  }
}
