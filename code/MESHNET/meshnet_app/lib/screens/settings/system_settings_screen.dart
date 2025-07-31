// lib/screens/settings/system_settings_screen.dart - System Configuration Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/utils/constants.dart';

class SystemSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Settings'),
        backgroundColor: Color(UIConstants.PRIMARY_COLOR),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          final system = provider.system;
          
          return ListView(
            padding: EdgeInsets.all(UIConstants.PADDING_MEDIUM),
            children: [
              // Performance Section
              _buildSectionCard(
                context,
                title: 'Performance',
                icon: Icons.speed,
                iconColor: Colors.green,
                children: [
                  SwitchListTile(
                    title: Text('Performance Mode'),
                    subtitle: Text('Optimize for better performance'),
                    value: system.performanceMode,
                    onChanged: (value) {
                      final newSystem = system.copyWith(performanceMode: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  if (system.performanceMode) ...[
                    ListTile(
                      title: Text('CPU Usage Limit'),
                      subtitle: Text('${system.cpuUsageLimit.toStringAsFixed(0)}%'),
                      trailing: Icon(Icons.memory),
                      onTap: () => _showSliderPicker(
                        context,
                        'CPU Usage Limit',
                        system.cpuUsageLimit,
                        0.0,
                        100.0,
                        '%',
                        (value) {
                          final newSystem = system.copyWith(cpuUsageLimit: value);
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Memory Usage Limit'),
                      subtitle: Text('${system.memoryUsageLimit.toStringAsFixed(0)}%'),
                      trailing: Icon(Icons.storage),
                      onTap: () => _showSliderPicker(
                        context,
                        'Memory Usage Limit',
                        system.memoryUsageLimit,
                        0.0,
                        100.0,
                        '%',
                        (value) {
                          final newSystem = system.copyWith(memoryUsageLimit: value);
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                  ],
                  SwitchListTile(
                    title: Text('Background Processing'),
                    subtitle: Text('Allow background tasks when app is minimized'),
                    value: system.backgroundProcessing,
                    onChanged: (value) {
                      final newSystem = system.copyWith(backgroundProcessing: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Auto Sleep Mode'),
                    subtitle: Text('Reduce activity when battery is low'),
                    value: system.autoSleepMode,
                    onChanged: (value) {
                      final newSystem = system.copyWith(autoSleepMode: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Storage Section
              _buildSectionCard(
                context,
                title: 'Storage',
                icon: Icons.storage,
                iconColor: Colors.blue,
                children: [
                  ListTile(
                    title: Text('Storage Location'),
                    subtitle: Text(system.storageLocation),
                    trailing: Icon(Icons.folder),
                    onTap: () => _showStorageLocationPicker(
                      context,
                      system.storageLocation,
                      (location) {
                        final newSystem = system.copyWith(storageLocation: location);
                        provider.updateSystemSettings(newSystem);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Max Storage Size'),
                    subtitle: Text('${(system.maxStorageSize / (1024 * 1024)).toStringAsFixed(0)} MB'),
                    trailing: Icon(Icons.data_usage),
                    onTap: () => _showNumberPicker(
                      context,
                      'Max Storage Size (MB)',
                      (system.maxStorageSize / (1024 * 1024)).round(),
                      100,
                      10000,
                      (value) {
                        final newSystem = system.copyWith(maxStorageSize: value * 1024 * 1024);
                        provider.updateSystemSettings(newSystem);
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: Text('Auto Cleanup'),
                    subtitle: Text('Automatically delete old files'),
                    value: system.autoCleanup,
                    onChanged: (value) {
                      final newSystem = system.copyWith(autoCleanup: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  if (system.autoCleanup) ...[
                    ListTile(
                      title: Text('Cleanup Interval'),
                      subtitle: Text('${system.cleanupInterval.inDays} days'),
                      trailing: Icon(Icons.schedule),
                      onTap: () => _showNumberPicker(
                        context,
                        'Cleanup Interval (days)',
                        system.cleanupInterval.inDays,
                        1,
                        30,
                        (value) {
                          final newSystem = system.copyWith(cleanupInterval: Duration(days: value));
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Logging Section
              _buildSectionCard(
                context,
                title: 'Logging & Diagnostics',
                icon: Icons.bug_report,
                iconColor: Colors.orange,
                children: [
                  SwitchListTile(
                    title: Text('Enable Logging'),
                    subtitle: Text('Record system events and errors'),
                    value: system.enableLogging,
                    onChanged: (value) {
                      final newSystem = system.copyWith(enableLogging: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  if (system.enableLogging) ...[
                    ListTile(
                      title: Text('Log Level'),
                      subtitle: Text(system.logLevel),
                      trailing: Icon(Icons.list),
                      onTap: () => _showLogLevelPicker(
                        context,
                        system.logLevel,
                        (level) {
                          final newSystem = system.copyWith(logLevel: level);
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Max Log File Size'),
                      subtitle: Text('${(system.maxLogFileSize / (1024 * 1024)).toStringAsFixed(1)} MB'),
                      trailing: Icon(Icons.description),
                      onTap: () => _showNumberPicker(
                        context,
                        'Max Log File Size (MB)',
                        (system.maxLogFileSize / (1024 * 1024)).round(),
                        1,
                        100,
                        (value) {
                          final newSystem = system.copyWith(maxLogFileSize: value * 1024 * 1024);
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                  ],
                  SwitchListTile(
                    title: Text('Crash Reporting'),
                    subtitle: Text('Send crash reports to developers'),
                    value: system.crashReporting,
                    onChanged: (value) {
                      final newSystem = system.copyWith(crashReporting: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Usage Analytics'),
                    subtitle: Text('Send anonymous usage statistics'),
                    value: system.usageAnalytics,
                    onChanged: (value) {
                      final newSystem = system.copyWith(usageAnalytics: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Updates Section
              _buildSectionCard(
                context,
                title: 'Updates',
                icon: Icons.system_update,
                iconColor: Colors.purple,
                children: [
                  SwitchListTile(
                    title: Text('Auto Updates'),
                    subtitle: Text('Automatically download and install updates'),
                    value: system.autoUpdates,
                    onChanged: (value) {
                      final newSystem = system.copyWith(autoUpdates: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  if (system.autoUpdates) ...[
                    ListTile(
                      title: Text('Update Check Frequency'),
                      subtitle: Text('Every ${system.updateCheckFrequency.inHours} hours'),
                      trailing: Icon(Icons.refresh),
                      onTap: () => _showNumberPicker(
                        context,
                        'Update Check Frequency (hours)',
                        system.updateCheckFrequency.inHours,
                        1,
                        168,
                        (value) {
                          final newSystem = system.copyWith(updateCheckFrequency: Duration(hours: value));
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                  ],
                  SwitchListTile(
                    title: Text('Beta Updates'),
                    subtitle: Text('Include beta versions in updates'),
                    value: system.betaUpdates,
                    onChanged: (value) {
                      final newSystem = system.copyWith(betaUpdates: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  ListTile(
                    title: Text('Check for Updates'),
                    subtitle: Text('Manually check for available updates'),
                    trailing: Icon(Icons.download),
                    onTap: () => _checkForUpdates(context),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Backup & Restore Section
              _buildSectionCard(
                context,
                title: 'Backup & Restore',
                icon: Icons.backup,
                iconColor: Colors.teal,
                children: [
                  SwitchListTile(
                    title: Text('Auto Backup'),
                    subtitle: Text('Automatically backup settings and data'),
                    value: system.autoBackup,
                    onChanged: (value) {
                      final newSystem = system.copyWith(autoBackup: value);
                      provider.updateSystemSettings(newSystem);
                    },
                  ),
                  if (system.autoBackup) ...[
                    ListTile(
                      title: Text('Backup Frequency'),
                      subtitle: Text('Every ${system.backupFrequency.inDays} days'),
                      trailing: Icon(Icons.schedule),
                      onTap: () => _showNumberPicker(
                        context,
                        'Backup Frequency (days)',
                        system.backupFrequency.inDays,
                        1,
                        30,
                        (value) {
                          final newSystem = system.copyWith(backupFrequency: Duration(days: value));
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Backup Location'),
                      subtitle: Text(system.backupLocation),
                      trailing: Icon(Icons.folder),
                      onTap: () => _showStorageLocationPicker(
                        context,
                        system.backupLocation,
                        (location) {
                          final newSystem = system.copyWith(backupLocation: location);
                          provider.updateSystemSettings(newSystem);
                        },
                      ),
                    ),
                  ],
                  ListTile(
                    title: Text('Create Backup'),
                    subtitle: Text('Manually create a backup now'),
                    trailing: Icon(Icons.save),
                    onTap: () => _createBackup(context),
                  ),
                  ListTile(
                    title: Text('Restore from Backup'),
                    subtitle: Text('Restore settings from a backup file'),
                    trailing: Icon(Icons.restore),
                    onTap: () => _restoreBackup(context),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // System Information Section
              _buildSectionCard(
                context,
                title: 'System Information',
                icon: Icons.info,
                iconColor: Colors.indigo,
                children: [
                  ListTile(
                    title: Text('App Version'),
                    subtitle: Text('1.0.0+1'),
                    trailing: Icon(Icons.apps),
                  ),
                  ListTile(
                    title: Text('Build Number'),
                    subtitle: Text('20241201'),
                    trailing: Icon(Icons.build),
                  ),
                  ListTile(
                    title: Text('Flutter Version'),
                    subtitle: Text('3.24.0'),
                    trailing: Icon(Icons.flutter_dash),
                  ),
                  ListTile(
                    title: Text('Platform'),
                    subtitle: Text('Web'),
                    trailing: Icon(Icons.computer),
                  ),
                  ListTile(
                    title: Text('View Licenses'),
                    subtitle: Text('Open source licenses'),
                    trailing: Icon(Icons.article),
                    onTap: () => _showLicenses(context),
                  ),
                  ListTile(
                    title: Text('System Diagnostics'),
                    subtitle: Text('View detailed system information'),
                    trailing: Icon(Icons.monitor_heart),
                    onTap: () => _showSystemDiagnostics(context),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Advanced System Section
              _buildSectionCard(
                context,
                title: 'Advanced',
                icon: Icons.engineering,
                iconColor: Colors.red,
                children: [
                  ListTile(
                    title: Text('Reset All Settings'),
                    subtitle: Text('Reset entire app to factory defaults'),
                    trailing: Icon(Icons.factory),
                    onTap: () => _showResetAllDialog(context, provider),
                  ),
                  ListTile(
                    title: Text('Export Settings'),
                    subtitle: Text('Export all settings to a file'),
                    trailing: Icon(Icons.download),
                    onTap: () => _exportSettings(context),
                  ),
                  ListTile(
                    title: Text('Import Settings'),
                    subtitle: Text('Import settings from a file'),
                    trailing: Icon(Icons.upload),
                    onTap: () => _importSettings(context),
                  ),
                  ListTile(
                    title: Text('Clear Cache'),
                    subtitle: Text('Clear temporary files and cache'),
                    trailing: Icon(Icons.cleaning_services),
                    onTap: () => _clearCache(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // Helper methods
  void _showSliderPicker(
    BuildContext context,
    String title,
    double current,
    double min,
    double max,
    String unit,
    Function(double) onChanged,
  ) {
    double value = current;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.toStringAsFixed(0)}$unit'),
              Slider(
                value: value,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                min: min,
                max: max,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onChanged(value);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNumberPicker(
    BuildContext context,
    String title,
    int current,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Number picker - Coming soon\nCurrent: $current\nRange: $min-$max'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStorageLocationPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final locations = ['Internal Storage', 'External Storage', 'Custom Path'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Storage Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: locations.map((location) => RadioListTile<String>(
            title: Text(location),
            value: location,
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLogLevelPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final levels = ['ERROR', 'WARNING', 'INFO', 'DEBUG', 'VERBOSE'];
    final descriptions = {
      'ERROR': 'Only log errors',
      'WARNING': 'Log warnings and errors',
      'INFO': 'Log general information',
      'DEBUG': 'Log debug information',
      'VERBOSE': 'Log everything (very detailed)',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) => RadioListTile<String>(
            title: Text(level),
            subtitle: Text(descriptions[level] ?? ''),
            value: level,
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check for Updates'),
        content: Text('Checking for updates...\n\nYou are running the latest version.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Backup'),
        content: Text('Creating backup of all settings and data...\n\nBackup created successfully!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _restoreBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restore from Backup'),
        content: Text('Select a backup file to restore settings and data from.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // File picker functionality
              Navigator.pop(context);
            },
            child: Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open Source Licenses'),
        content: Text('This app uses the following open source libraries:\n\n• Flutter SDK\n• Provider Package\n• Material Icons\n• And many more...'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSystemDiagnostics(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('System Diagnostics'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CPU Usage: 15%'),
              Text('Memory Usage: 120 MB'),
              Text('Storage Used: 45 MB'),
              Text('Network Status: Online'),
              Text('Battery Level: 85%'),
              Text('Active Connections: 3'),
              Text('Messages Processed: 1,250'),
              Text('Uptime: 2h 15m'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetAllDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset All Settings'),
        content: Text('This will reset ALL settings to their default values and delete all user data.\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset all settings
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _exportSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Settings'),
        content: Text('This will export all your settings to a file that you can save or share.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Export settings functionality
              Navigator.pop(context);
            },
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _importSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Settings'),
        content: Text('This will import settings from a previously exported file.\n\nWarning: This will overwrite your current settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Import settings functionality
              Navigator.pop(context);
            },
            child: Text('Import'),
          ),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Cache'),
        content: Text('This will clear all temporary files and cached data.\n\nApproximate space to be freed: 25 MB'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear cache functionality
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}
