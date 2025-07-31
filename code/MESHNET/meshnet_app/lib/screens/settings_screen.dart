// lib/screens/settings_screen.dart - Main Settings Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/screens/settings/network_settings_screen.dart';
import 'package:meshnet_app/screens/settings/emergency_settings_screen.dart';
import 'package:meshnet_app/screens/settings/ui_settings_screen.dart';
import 'package:meshnet_app/screens/settings/security_settings_screen.dart';
import 'package:meshnet_app/screens/settings/system_settings_screen.dart';
import 'package:meshnet_app/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Color(UIConstants.PRIMARY_COLOR),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Import Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading settings...'),
                ],
              ),
            );
          }

          if (settingsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    settingsProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      settingsProvider.clearError();
                      settingsProvider.loadSettings();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.all(UIConstants.PADDING_MEDIUM),
            children: [
              // Network Settings
              _buildSettingsCard(
                context,
                icon: Icons.device_hub,
                iconColor: Colors.blue,
                title: 'Network Settings',
                subtitle: 'Configure Bluetooth, WiFi, SDR, and Ham Radio',
                trailing: _buildNetworkStatusChip(settingsProvider),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NetworkSettingsScreen(),
                  ),
                ),
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Emergency Settings
              _buildSettingsCard(
                context,
                icon: Icons.emergency,
                iconColor: Colors.red,
                title: 'Emergency Settings',
                subtitle: 'Configure emergency protocols and responses',
                trailing: _buildEmergencyStatusChip(settingsProvider),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencySettingsScreen(),
                  ),
                ),
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Security Settings
              _buildSettingsCard(
                context,
                icon: Icons.security,
                iconColor: Colors.green,
                title: 'Security Settings',
                subtitle: 'Encryption, authentication, and privacy',
                trailing: _buildSecurityStatusChip(settingsProvider),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecuritySettingsScreen(),
                  ),
                ),
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // UI Settings
              _buildSettingsCard(
                context,
                icon: Icons.palette,
                iconColor: Colors.purple,
                title: 'Interface Settings',
                subtitle: 'Theme, language, and appearance',
                trailing: _buildUIStatusChip(settingsProvider),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UISettingsScreen(),
                  ),
                ),
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // System Settings
              _buildSettingsCard(
                context,
                icon: Icons.settings_system_daydream,
                iconColor: Colors.orange,
                title: 'System Settings',
                subtitle: 'Debug, logging, and advanced options',
                trailing: _buildSystemStatusChip(settingsProvider),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SystemSettingsScreen(),
                  ),
                ),
              ),

              SizedBox(height: UIConstants.PADDING_LARGE),

              // Information Section
              _buildInfoSection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing,
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNetworkStatusChip(SettingsProvider provider) {
    final network = provider.network;
    int activeInterfaces = 0;
    
    if (network.bluetoothEnabled) activeInterfaces++;
    if (network.wifiDirectEnabled) activeInterfaces++;
    if (network.sdrEnabled) activeInterfaces++;
    if (network.hamRadioEnabled) activeInterfaces++;

    return Chip(
      label: Text('$activeInterfaces interfaces'),
      backgroundColor: activeInterfaces > 0 ? Colors.green.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: activeInterfaces > 0 ? Colors.green.shade800 : Colors.grey.shade800,
        fontSize: 12,
      ),
    );
  }

  Widget _buildEmergencyStatusChip(SettingsProvider provider) {
    final emergency = provider.emergency;
    return Chip(
      label: Text(emergency.emergencyModeEnabled ? 'Active' : 'Disabled'),
      backgroundColor: emergency.emergencyModeEnabled ? Colors.red.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: emergency.emergencyModeEnabled ? Colors.red.shade800 : Colors.grey.shade800,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSecurityStatusChip(SettingsProvider provider) {
    final security = provider.security;
    return Chip(
      label: Text(security.encryptionEnabled ? 'Secured' : 'Unsecured'),
      backgroundColor: security.encryptionEnabled ? Colors.green.shade100 : Colors.orange.shade100,
      labelStyle: TextStyle(
        color: security.encryptionEnabled ? Colors.green.shade800 : Colors.orange.shade800,
        fontSize: 12,
      ),
    );
  }

  Widget _buildUIStatusChip(SettingsProvider provider) {
    final ui = provider.ui;
    return Chip(
      label: Text(ui.darkMode ? 'Dark' : 'Light'),
      backgroundColor: ui.darkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: ui.darkMode ? Colors.white : Colors.grey.shade800,
        fontSize: 12,
      ),
    );
  }

  Widget _buildSystemStatusChip(SettingsProvider provider) {
    final system = provider.system;
    return Chip(
      label: Text(system.debugMode ? 'Debug' : 'Normal'),
      backgroundColor: system.debugMode ? Colors.orange.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: system.debugMode ? Colors.orange.shade800 : Colors.grey.shade800,
        fontSize: 12,
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        Divider(),
        ListTile(
          leading: Icon(Icons.info_outline, color: Colors.blue),
          title: Text('About MESHNET'),
          subtitle: Text('Version 1.0.0 • Emergency Mesh Network'),
          onTap: () => _showAboutDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.help_outline, color: Colors.green),
          title: Text('Help & Documentation'),
          subtitle: Text('User guides and troubleshooting'),
          onTap: () => _showHelpDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.bug_report, color: Colors.orange),
          title: Text('Report Issue'),
          subtitle: Text('Send feedback or report problems'),
          onTap: () => _showReportDialog(context),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    final provider = context.read<SettingsProvider>();
    
    switch (action) {
      case 'reset':
        _showResetConfirmation(provider);
        break;
      case 'export':
        _exportSettings(provider);
        break;
      case 'import':
        _importSettings(provider);
        break;
    }
  }

  void _showResetConfirmation(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Settings'),
        content: Text(
          'This will reset all settings to their default values. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _exportSettings(SettingsProvider provider) {
    // TODO: Implement settings export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings export - Coming soon')),
    );
  }

  void _importSettings(SettingsProvider provider) {
    // TODO: Implement settings import
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings import - Coming soon')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MESHNET',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(Icons.emergency, size: 48, color: Colors.orange),
      children: [
        Text('Emergency Mesh Network Communication System'),
        SizedBox(height: 8),
        Text('Built with Flutter for cross-platform emergency communication'),
        SizedBox(height: 8),
        Text('Features multi-protocol networking including Bluetooth, WiFi Direct, SDR, and Ham Radio'),
        SizedBox(height: 16),
        Text('© 2024 MESHNET Project'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Documentation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Help Topics:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Network Setup and Configuration'),
            Text('• Emergency Protocol Usage'),
            Text('• Security and Encryption'),
            Text('• Troubleshooting Connection Issues'),
            Text('• Advanced SDR and Ham Radio Setup'),
            SizedBox(height: 16),
            Text('For detailed documentation, visit the project repository.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Help us improve MESHNET by reporting issues:'),
            SizedBox(height: 16),
            Text('• Bugs and unexpected behavior'),
            Text('• Feature requests'),
            Text('• Performance issues'),
            Text('• Security concerns'),
            SizedBox(height: 16),
            Text('Reports help make the system more reliable for emergency situations.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Issue reporting - Coming soon')),
              );
            },
            child: Text('Report'),
          ),
        ],
      ),
    );
  }
}
