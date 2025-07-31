// lib/screens/settings/network_settings_screen.dart - Network Configuration Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/utils/constants.dart';

class NetworkSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Settings'),
        backgroundColor: Color(UIConstants.PRIMARY_COLOR),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          final network = provider.network;
          
          return ListView(
            padding: EdgeInsets.all(UIConstants.PADDING_MEDIUM),
            children: [
              // Bluetooth Section
              _buildSectionCard(
                context,
                title: 'Bluetooth Low Energy',
                icon: Icons.bluetooth,
                iconColor: Colors.blue,
                children: [
                  SwitchListTile(
                    title: Text('Enable Bluetooth'),
                    subtitle: Text('Use Bluetooth for mesh networking'),
                    value: network.bluetoothEnabled,
                    onChanged: provider.updateBluetoothEnabled,
                  ),
                  if (network.bluetoothEnabled) ...[
                    ListTile(
                      title: Text('Scan Interval'),
                      subtitle: Text('${network.bluetoothScanInterval.inSeconds}s'),
                      trailing: Icon(Icons.timer),
                      onTap: () => _showDurationPicker(
                        context,
                        'Bluetooth Scan Interval',
                        network.bluetoothScanInterval,
                        (duration) {
                          final newNetwork = network.copyWith(bluetoothScanInterval: duration);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Connection Timeout'),
                      subtitle: Text('${network.bluetoothConnectionTimeout.inSeconds}s'),
                      trailing: Icon(Icons.timer),
                      onTap: () => _showDurationPicker(
                        context,
                        'Bluetooth Connection Timeout',
                        network.bluetoothConnectionTimeout,
                        (duration) {
                          final newNetwork = network.copyWith(bluetoothConnectionTimeout: duration);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Max Connections'),
                      subtitle: Text('${network.maxBluetoothConnections} peers'),
                      trailing: Icon(Icons.people),
                      onTap: () => _showNumberPicker(
                        context,
                        'Max Bluetooth Connections',
                        network.maxBluetoothConnections,
                        1,
                        15,
                        (value) {
                          final newNetwork = network.copyWith(maxBluetoothConnections: value);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // WiFi Direct Section
              _buildSectionCard(
                context,
                title: 'WiFi Direct',
                icon: Icons.wifi,
                iconColor: Colors.green,
                children: [
                  SwitchListTile(
                    title: Text('Enable WiFi Direct'),
                    subtitle: Text('Use WiFi Direct for mesh networking'),
                    value: network.wifiDirectEnabled,
                    onChanged: provider.updateWifiDirectEnabled,
                  ),
                  if (network.wifiDirectEnabled) ...[
                    ListTile(
                      title: Text('Group Name'),
                      subtitle: Text(network.wifiDirectGroupName),
                      trailing: Icon(Icons.edit),
                      onTap: () => _showTextPicker(
                        context,
                        'WiFi Direct Group Name',
                        network.wifiDirectGroupName,
                        (value) {
                          final newNetwork = network.copyWith(wifiDirectGroupName: value);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Port'),
                      subtitle: Text('${network.wifiDirectPort}'),
                      trailing: Icon(Icons.settings_ethernet),
                      onTap: () => _showNumberPicker(
                        context,
                        'WiFi Direct Port',
                        network.wifiDirectPort,
                        1024,
                        65535,
                        (value) {
                          final newNetwork = network.copyWith(wifiDirectPort: value);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Connection Timeout'),
                      subtitle: Text('${network.wifiDirectTimeout.inSeconds}s'),
                      trailing: Icon(Icons.timer),
                      onTap: () => _showDurationPicker(
                        context,
                        'WiFi Direct Timeout',
                        network.wifiDirectTimeout,
                        (duration) {
                          final newNetwork = network.copyWith(wifiDirectTimeout: duration);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // SDR Section
              _buildSectionCard(
                context,
                title: 'Software Defined Radio (SDR)',
                icon: Icons.radio,
                iconColor: Colors.orange,
                children: [
                  SwitchListTile(
                    title: Text('Enable SDR'),
                    subtitle: Text('Use RTL-SDR, HackRF, or similar devices'),
                    value: network.sdrEnabled,
                    onChanged: provider.updateSDREnabled,
                  ),
                  if (network.sdrEnabled) ...[
                    ListTile(
                      title: Text('Frequency'),
                      subtitle: Text('${(network.sdrFrequency / 1000000).toStringAsFixed(3)} MHz'),
                      trailing: Icon(Icons.tune),
                      onTap: () => _showFrequencyPicker(
                        context,
                        'SDR Frequency',
                        network.sdrFrequency,
                        (frequency) {
                          final newNetwork = network.copyWith(sdrFrequency: frequency);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Sample Rate'),
                      subtitle: Text('${(network.sdrSampleRate / 1000000).toStringAsFixed(1)} MHz'),
                      trailing: Icon(Icons.speed),
                      onTap: () => _showSampleRatePicker(
                        context,
                        'SDR Sample Rate',
                        network.sdrSampleRate,
                        (rate) {
                          final newNetwork = network.copyWith(sdrSampleRate: rate);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Modulation'),
                      subtitle: Text(network.sdrModulation),
                      trailing: Icon(Icons.settings_input_antenna),
                      onTap: () => _showModulationPicker(
                        context,
                        network.sdrModulation,
                        (modulation) {
                          final newNetwork = network.copyWith(sdrModulation: modulation);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('TX Power'),
                      subtitle: Text('${network.sdrTxPower.toStringAsFixed(1)} dBm'),
                      trailing: Icon(Icons.power),
                      onTap: () => _showTxPowerPicker(
                        context,
                        'SDR TX Power',
                        network.sdrTxPower,
                        (power) {
                          final newNetwork = network.copyWith(sdrTxPower: power);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Ham Radio Section
              _buildSectionCard(
                context,
                title: 'Ham Radio',
                icon: Icons.radio_button_checked,
                iconColor: Colors.red,
                children: [
                  SwitchListTile(
                    title: Text('Enable Ham Radio'),
                    subtitle: Text('Use amateur radio frequencies'),
                    value: network.hamRadioEnabled,
                    onChanged: provider.updateHamRadioEnabled,
                  ),
                  if (network.hamRadioEnabled) ...[
                    ListTile(
                      title: Text('Call Sign'),
                      subtitle: Text(network.hamRadioCallSign),
                      trailing: Icon(Icons.perm_identity),
                      onTap: () => _showCallSignPicker(
                        context,
                        network.hamRadioCallSign,
                        (callSign) {
                          final newNetwork = network.copyWith(hamRadioCallSign: callSign);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Frequency'),
                      subtitle: Text('${(network.hamRadioFrequency / 1000000).toStringAsFixed(3)} MHz'),
                      trailing: Icon(Icons.tune),
                      onTap: () => _showFrequencyPicker(
                        context,
                        'Ham Radio Frequency',
                        network.hamRadioFrequency,
                        (frequency) {
                          final newNetwork = network.copyWith(hamRadioFrequency: frequency);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Baud Rate'),
                      subtitle: Text('${network.hamRadioBaud} bps'),
                      trailing: Icon(Icons.speed),
                      onTap: () => _showBaudRatePicker(
                        context,
                        network.hamRadioBaud,
                        (baud) {
                          final newNetwork = network.copyWith(hamRadioBaud: baud);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Mode'),
                      subtitle: Text(network.hamRadioMode),
                      trailing: Icon(Icons.settings_input_antenna),
                      onTap: () => _showHamModePicker(
                        context,
                        network.hamRadioMode,
                        (mode) {
                          final newNetwork = network.copyWith(hamRadioMode: mode);
                          provider.updateNetworkSettings(newNetwork);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // General Network Settings
              _buildSectionCard(
                context,
                title: 'General Network',
                icon: Icons.settings_ethernet,
                iconColor: Colors.purple,
                children: [
                  ListTile(
                    title: Text('Max Message Size'),
                    subtitle: Text('${(network.maxMessageSize / 1024).toStringAsFixed(1)} KB'),
                    trailing: Icon(Icons.data_usage),
                    onTap: () => _showNumberPicker(
                      context,
                      'Max Message Size (KB)',
                      (network.maxMessageSize / 1024).round(),
                      1,
                      100,
                      (value) {
                        final newNetwork = network.copyWith(maxMessageSize: value * 1024);
                        provider.updateNetworkSettings(newNetwork);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Message Timeout'),
                    subtitle: Text('${network.messageTimeout.inSeconds}s'),
                    trailing: Icon(Icons.timer),
                    onTap: () => _showDurationPicker(
                      context,
                      'Message Timeout',
                      network.messageTimeout,
                      (duration) {
                        final newNetwork = network.copyWith(messageTimeout: duration);
                        provider.updateNetworkSettings(newNetwork);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Heartbeat Interval'),
                    subtitle: Text('${network.heartbeatInterval.inSeconds}s'),
                    trailing: Icon(Icons.favorite),
                    onTap: () => _showDurationPicker(
                      context,
                      'Heartbeat Interval',
                      network.heartbeatInterval,
                      (duration) {
                        final newNetwork = network.copyWith(heartbeatInterval: duration);
                        provider.updateNetworkSettings(newNetwork);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Max Retry Attempts'),
                    subtitle: Text('${network.maxRetryAttempts} attempts'),
                    trailing: Icon(Icons.refresh),
                    onTap: () => _showNumberPicker(
                      context,
                      'Max Retry Attempts',
                      network.maxRetryAttempts,
                      1,
                      10,
                      (value) {
                        final newNetwork = network.copyWith(maxRetryAttempts: value);
                        provider.updateNetworkSettings(newNetwork);
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

  void _showTextPicker(
    BuildContext context,
    String title,
    String current,
    Function(String) onChanged,
  ) {
    final controller = TextEditingController(text: current);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFrequencyPicker(
    BuildContext context,
    String title,
    double current,
    Function(double) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Frequency picker - Coming soon\nCurrent: ${(current / 1000000).toStringAsFixed(3)} MHz'),
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

  void _showSampleRatePicker(
    BuildContext context,
    String title,
    int current,
    Function(int) onChanged,
  ) {
    final sampleRates = [
      250000,
      500000,
      1000000,
      2048000,
      2400000,
      3200000,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sampleRates.map((rate) => RadioListTile<int>(
            title: Text('${(rate / 1000000).toStringAsFixed(1)} MHz'),
            value: rate,
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

  void _showModulationPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final modulations = ['FSK', 'ASK', 'PSK', 'QAM', 'GFSK'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modulation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modulations.map((mod) => RadioListTile<String>(
            title: Text(mod),
            value: mod,
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

  void _showTxPowerPicker(
    BuildContext context,
    String title,
    double current,
    Function(double) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('TX Power picker - Coming soon\nCurrent: ${current.toStringAsFixed(1)} dBm'),
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

  void _showCallSignPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final controller = TextEditingController(text: current);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ham Radio Call Sign'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Call Sign',
                helperText: 'Enter your licensed amateur radio call sign',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 8),
            Text(
              'Note: A valid amateur radio license is required for Ham radio operation.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
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
              onChanged(controller.text.toUpperCase());
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBaudRatePicker(
    BuildContext context,
    int current,
    Function(int) onChanged,
  ) {
    final baudRates = [300, 1200, 2400, 4800, 9600, 19200];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Baud Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: baudRates.map((baud) => RadioListTile<int>(
            title: Text('$baud bps'),
            value: baud,
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

  void _showHamModePicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final modes = ['PACKET', 'APRS', 'FT8', 'PSK31', 'RTTY', 'CW'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ham Radio Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((mode) => RadioListTile<String>(
            title: Text(mode),
            value: mode,
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
}
