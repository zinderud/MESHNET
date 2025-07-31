// lib/screens/settings/emergency_settings_screen.dart - Emergency Configuration Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/utils/constants.dart';

class EmergencySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Settings'),
        backgroundColor: Color(UIConstants.PRIMARY_COLOR),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          final emergency = provider.emergency;
          
          return ListView(
            padding: EdgeInsets.all(UIConstants.PADDING_MEDIUM),
            children: [
              // Emergency Mode Section
              _buildSectionCard(
                context,
                title: 'Emergency Mode',
                icon: Icons.emergency,
                iconColor: Colors.red,
                children: [
                  SwitchListTile(
                    title: Text('Auto Emergency Mode'),
                    subtitle: Text('Automatically activate during emergencies'),
                    value: emergency.autoEmergencyMode,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(autoEmergencyMode: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  ListTile(
                    title: Text('Emergency Level'),
                    subtitle: Text(emergency.emergencyLevel),
                    trailing: Icon(Icons.warning),
                    onTap: () => _showEmergencyLevelPicker(
                      context,
                      emergency.emergencyLevel,
                      (level) {
                        final newEmergency = emergency.copyWith(emergencyLevel: level);
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Emergency Area Radius'),
                    subtitle: Text('${emergency.emergencyAreaRadius.toStringAsFixed(1)} km'),
                    trailing: Icon(Icons.location_on),
                    onTap: () => _showNumberPicker(
                      context,
                      'Emergency Area Radius (km)',
                      emergency.emergencyAreaRadius.toInt(),
                      1,
                      100,
                      (value) {
                        final newEmergency = emergency.copyWith(emergencyAreaRadius: value.toDouble());
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // SOS Configuration
              _buildSectionCard(
                context,
                title: 'SOS Configuration',
                icon: Icons.sos,
                iconColor: Colors.red,
                children: [
                  SwitchListTile(
                    title: Text('Enable SOS'),
                    subtitle: Text('Allow sending SOS messages'),
                    value: emergency.sosEnabled,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(sosEnabled: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  if (emergency.sosEnabled) ...[
                    ListTile(
                      title: Text('SOS Button Hold Time'),
                      subtitle: Text('${emergency.sosButtonHoldTime.inSeconds}s'),
                      trailing: Icon(Icons.timer),
                      onTap: () => _showDurationPicker(
                        context,
                        'SOS Button Hold Time',
                        emergency.sosButtonHoldTime,
                        (duration) {
                          final newEmergency = emergency.copyWith(sosButtonHoldTime: duration);
                          provider.updateEmergencySettings(newEmergency);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('SOS Repeat Interval'),
                      subtitle: Text('${emergency.sosRepeatInterval.inMinutes} min'),
                      trailing: Icon(Icons.repeat),
                      onTap: () => _showDurationPicker(
                        context,
                        'SOS Repeat Interval',
                        emergency.sosRepeatInterval,
                        (duration) {
                          final newEmergency = emergency.copyWith(sosRepeatInterval: duration);
                          provider.updateEmergencySettings(newEmergency);
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: Text('Auto Location in SOS'),
                      subtitle: Text('Include GPS coordinates in SOS messages'),
                      value: emergency.autoLocationInSOS,
                      onChanged: (value) {
                        final newEmergency = emergency.copyWith(autoLocationInSOS: value);
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Emergency Contacts
              _buildSectionCard(
                context,
                title: 'Emergency Contacts',
                icon: Icons.contact_emergency,
                iconColor: Colors.orange,
                children: [
                  ListTile(
                    title: Text('Emergency Contacts'),
                    subtitle: Text('${emergency.emergencyContacts.length} contacts'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () => _showEmergencyContactsScreen(context, emergency.emergencyContacts),
                  ),
                  SwitchListTile(
                    title: Text('Broadcast to All'),
                    subtitle: Text('Send emergency messages to all contacts'),
                    value: emergency.broadcastToAll,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(broadcastToAll: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Auto Forward Emergency'),
                    subtitle: Text('Automatically forward emergency messages'),
                    value: emergency.autoForwardEmergency,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(autoForwardEmergency: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Location Services
              _buildSectionCard(
                context,
                title: 'Location Services',
                icon: Icons.location_on,
                iconColor: Colors.blue,
                children: [
                  SwitchListTile(
                    title: Text('Share Location'),
                    subtitle: Text('Share location with other peers'),
                    value: emergency.shareLocation,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(shareLocation: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  if (emergency.shareLocation) ...[
                    ListTile(
                      title: Text('Location Update Interval'),
                      subtitle: Text('${emergency.locationUpdateInterval.inMinutes} min'),
                      trailing: Icon(Icons.update),
                      onTap: () => _showDurationPicker(
                        context,
                        'Location Update Interval',
                        emergency.locationUpdateInterval,
                        (duration) {
                          final newEmergency = emergency.copyWith(locationUpdateInterval: duration);
                          provider.updateEmergencySettings(newEmergency);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Location Accuracy'),
                      subtitle: Text('${emergency.locationAccuracy.toStringAsFixed(0)}m'),
                      trailing: Icon(Icons.gps_fixed),
                      onTap: () => _showNumberPicker(
                        context,
                        'Location Accuracy (meters)',
                        emergency.locationAccuracy.toInt(),
                        5,
                        100,
                        (value) {
                          final newEmergency = emergency.copyWith(locationAccuracy: value.toDouble());
                          provider.updateEmergencySettings(newEmergency);
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: Text('High Accuracy Mode'),
                      subtitle: Text('Use GPS for better accuracy (drains battery)'),
                      value: emergency.highAccuracyMode,
                      onChanged: (value) {
                        final newEmergency = emergency.copyWith(highAccuracyMode: value);
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Alert Configuration
              _buildSectionCard(
                context,
                title: 'Alert Configuration',
                icon: Icons.notifications_active,
                iconColor: Colors.purple,
                children: [
                  SwitchListTile(
                    title: Text('Sound Alerts'),
                    subtitle: Text('Play alert sounds for emergencies'),
                    value: emergency.soundAlerts,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(soundAlerts: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Vibration Alerts'),
                    subtitle: Text('Vibrate for emergency notifications'),
                    value: emergency.vibrationAlerts,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(vibrationAlerts: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  ListTile(
                    title: Text('Alert Volume'),
                    subtitle: Text('${(emergency.alertVolume * 100).toStringAsFixed(0)}%'),
                    trailing: Icon(Icons.volume_up),
                    onTap: () => _showVolumeSlider(
                      context,
                      emergency.alertVolume,
                      (volume) {
                        final newEmergency = emergency.copyWith(alertVolume: volume);
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Alert Tone'),
                    subtitle: Text(emergency.alertTone),
                    trailing: Icon(Icons.music_note),
                    onTap: () => _showAlertTonePicker(
                      context,
                      emergency.alertTone,
                      (tone) {
                        final newEmergency = emergency.copyWith(alertTone: tone);
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Message Priorities
              _buildSectionCard(
                context,
                title: 'Message Priorities',
                icon: Icons.priority_high,
                iconColor: Colors.green,
                children: [
                  ListTile(
                    title: Text('Priority Levels'),
                    subtitle: Text('Configure message priority handling'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () => _showPriorityLevelsScreen(context),
                  ),
                  SwitchListTile(
                    title: Text('Auto Priority Assignment'),
                    subtitle: Text('Automatically assign priority based on content'),
                    value: emergency.autoPriorityAssignment,
                    onChanged: (value) {
                      final newEmergency = emergency.copyWith(autoPriorityAssignment: value);
                      provider.updateEmergencySettings(newEmergency);
                    },
                  ),
                  ListTile(
                    title: Text('High Priority Timeout'),
                    subtitle: Text('${emergency.highPriorityTimeout.inSeconds}s'),
                    trailing: Icon(Icons.timer),
                    onTap: () => _showDurationPicker(
                      context,
                      'High Priority Timeout',
                      emergency.highPriorityTimeout,
                      (duration) {
                        final newEmergency = emergency.copyWith(highPriorityTimeout: duration);
                        provider.updateEmergencySettings(newEmergency);
                      },
                    ),
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

  // Helper methods for showing pickers
  void _showEmergencyLevelPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final levels = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    final descriptions = {
      'LOW': 'Minor incidents, information only',
      'MEDIUM': 'Moderate emergencies, assistance needed',
      'HIGH': 'Serious emergencies, immediate help required',
      'CRITICAL': 'Life-threatening situations, urgent response',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Level'),
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

  void _showDurationPicker(
    BuildContext context,
    String title,
    Duration current,
    Function(Duration) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Duration picker - Coming soon\nCurrent: ${current.inSeconds}s'),
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

  void _showEmergencyContactsScreen(BuildContext context, List<String> contacts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Contacts'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: contacts.length + 1,
            itemBuilder: (context, index) {
              if (index == contacts.length) {
                return ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Contact'),
                  onTap: () {
                    // Add contact functionality
                  },
                );
              }
              return ListTile(
                leading: Icon(Icons.person),
                title: Text(contacts[index]),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Remove contact functionality
                  },
                ),
              );
            },
          ),
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

  void _showVolumeSlider(
    BuildContext context,
    double current,
    Function(double) onChanged,
  ) {
    double value = current;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Alert Volume'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(value * 100).toStringAsFixed(0)}%'),
              Slider(
                value: value,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                min: 0.0,
                max: 1.0,
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

  void _showAlertTonePicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final tones = ['Default', 'Siren', 'Beep', 'Chime', 'Alert', 'Emergency'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alert Tone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tones.map((tone) => RadioListTile<String>(
            title: Text(tone),
            value: tone,
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

  void _showPriorityLevelsScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Priority Levels'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriorityItem(Icons.arrow_upward, 'CRITICAL', Colors.red, 'Life-threatening emergencies'),
            _buildPriorityItem(Icons.warning, 'HIGH', Colors.orange, 'Urgent assistance needed'),
            _buildPriorityItem(Icons.info, 'MEDIUM', Colors.blue, 'Important but not urgent'),
            _buildPriorityItem(Icons.remove, 'LOW', Colors.grey, 'General information'),
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

  Widget _buildPriorityItem(IconData icon, String level, Color color, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
