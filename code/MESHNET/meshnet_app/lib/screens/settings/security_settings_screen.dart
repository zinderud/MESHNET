// lib/screens/settings/security_settings_screen.dart - Security Configuration Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/utils/constants.dart';

class SecuritySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Settings'),
        backgroundColor: Color(UIConstants.PRIMARY_COLOR),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          final security = provider.security;
          
          return ListView(
            padding: EdgeInsets.all(UIConstants.PADDING_MEDIUM),
            children: [
              // Encryption Section
              _buildSectionCard(
                context,
                title: 'Encryption',
                icon: Icons.security,
                iconColor: Colors.green,
                children: [
                  SwitchListTile(
                    title: Text('Enable Encryption'),
                    subtitle: Text('Encrypt all messages and data'),
                    value: security.encryptionEnabled,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(encryptionEnabled: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  if (security.encryptionEnabled) ...[
                    ListTile(
                      title: Text('Encryption Algorithm'),
                      subtitle: Text(security.encryptionAlgorithm),
                      trailing: Icon(Icons.algorithm),
                      onTap: () => _showEncryptionAlgorithmPicker(
                        context,
                        security.encryptionAlgorithm,
                        (algorithm) {
                          final newSecurity = security.copyWith(encryptionAlgorithm: algorithm);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Key Size'),
                      subtitle: Text('${security.keySize} bits'),
                      trailing: Icon(Icons.vpn_key),
                      onTap: () => _showKeySizePicker(
                        context,
                        security.keySize,
                        (keySize) {
                          final newSecurity = security.copyWith(keySize: keySize);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Key Rotation Interval'),
                      subtitle: Text('${security.keyRotationInterval.inHours}h'),
                      trailing: Icon(Icons.refresh),
                      onTap: () => _showDurationPicker(
                        context,
                        'Key Rotation Interval',
                        security.keyRotationInterval,
                        (duration) {
                          final newSecurity = security.copyWith(keyRotationInterval: duration);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Authentication Section
              _buildSectionCard(
                context,
                title: 'Authentication',
                icon: Icons.person_outline,
                iconColor: Colors.blue,
                children: [
                  SwitchListTile(
                    title: Text('Require Authentication'),
                    subtitle: Text('Authenticate users before access'),
                    value: security.requireAuthentication,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(requireAuthentication: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  if (security.requireAuthentication) ...[
                    ListTile(
                      title: Text('Authentication Method'),
                      subtitle: Text(security.authenticationMethod),
                      trailing: Icon(Icons.fingerprint),
                      onTap: () => _showAuthMethodPicker(
                        context,
                        security.authenticationMethod,
                        (method) {
                          final newSecurity = security.copyWith(authenticationMethod: method);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Session Timeout'),
                      subtitle: Text('${security.sessionTimeout.inMinutes} min'),
                      trailing: Icon(Icons.timer),
                      onTap: () => _showDurationPicker(
                        context,
                        'Session Timeout',
                        security.sessionTimeout,
                        (duration) {
                          final newSecurity = security.copyWith(sessionTimeout: duration);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Max Login Attempts'),
                      subtitle: Text('${security.maxLoginAttempts} attempts'),
                      trailing: Icon(Icons.lock),
                      onTap: () => _showNumberPicker(
                        context,
                        'Max Login Attempts',
                        security.maxLoginAttempts,
                        3,
                        10,
                        (value) {
                          final newSecurity = security.copyWith(maxLoginAttempts: value);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Digital Signatures Section
              _buildSectionCard(
                context,
                title: 'Digital Signatures',
                icon: Icons.verified,
                iconColor: Colors.purple,
                children: [
                  SwitchListTile(
                    title: Text('Sign Messages'),
                    subtitle: Text('Digitally sign all outgoing messages'),
                    value: security.signMessages,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(signMessages: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Verify Signatures'),
                    subtitle: Text('Verify signatures on incoming messages'),
                    value: security.verifySignatures,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(verifySignatures: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  if (security.signMessages || security.verifySignatures) ...[
                    ListTile(
                      title: Text('Signature Algorithm'),
                      subtitle: Text(security.signatureAlgorithm),
                      trailing: Icon(Icons.edit_note),
                      onTap: () => _showSignatureAlgorithmPicker(
                        context,
                        security.signatureAlgorithm,
                        (algorithm) {
                          final newSecurity = security.copyWith(signatureAlgorithm: algorithm);
                          provider.updateSecuritySettings(newSecurity);
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Certificate Validation'),
                      subtitle: Text('Manage digital certificates'),
                      trailing: Icon(Icons.certificate),
                      onTap: () => _showCertificateManagement(context),
                    ),
                  ],
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Network Security Section
              _buildSectionCard(
                context,
                title: 'Network Security',
                icon: Icons.shield,
                iconColor: Colors.orange,
                children: [
                  SwitchListTile(
                    title: Text('Secure Protocols Only'),
                    subtitle: Text('Use only secure communication protocols'),
                    value: security.secureProtocolsOnly,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(secureProtocolsOnly: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Firewall Protection'),
                    subtitle: Text('Enable built-in firewall protection'),
                    value: security.firewallEnabled,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(firewallEnabled: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Intrusion Detection'),
                    subtitle: Text('Monitor for suspicious network activity'),
                    value: security.intrusionDetection,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(intrusionDetection: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  ListTile(
                    title: Text('Trusted Peers'),
                    subtitle: Text('${security.trustedPeers.length} trusted peers'),
                    trailing: Icon(Icons.people),
                    onTap: () => _showTrustedPeersScreen(context, security.trustedPeers),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Privacy Section
              _buildSectionCard(
                context,
                title: 'Privacy',
                icon: Icons.privacy_tip,
                iconColor: Colors.indigo,
                children: [
                  SwitchListTile(
                    title: Text('Anonymous Mode'),
                    subtitle: Text('Hide identity information when possible'),
                    value: security.anonymousMode,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(anonymousMode: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Hide Metadata'),
                    subtitle: Text('Strip metadata from messages and files'),
                    value: security.hideMetadata,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(hideMetadata: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                  ListTile(
                    title: Text('Data Retention Period'),
                    subtitle: Text('${security.dataRetentionPeriod.inDays} days'),
                    trailing: Icon(Icons.schedule),
                    onTap: () => _showNumberPicker(
                      context,
                      'Data Retention Period (days)',
                      security.dataRetentionPeriod.inDays,
                      1,
                      365,
                      (value) {
                        final newSecurity = security.copyWith(dataRetentionPeriod: Duration(days: value));
                        provider.updateSecuritySettings(newSecurity);
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: Text('Auto Delete Messages'),
                    subtitle: Text('Automatically delete old messages'),
                    value: security.autoDeleteMessages,
                    onChanged: (value) {
                      final newSecurity = security.copyWith(autoDeleteMessages: value);
                      provider.updateSecuritySettings(newSecurity);
                    },
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Advanced Security Section
              _buildSectionCard(
                context,
                title: 'Advanced Security',
                icon: Icons.security_outlined,
                iconColor: Colors.red,
                children: [
                  ListTile(
                    title: Text('Security Audit Log'),
                    subtitle: Text('View security events and violations'),
                    trailing: Icon(Icons.list_alt),
                    onTap: () => _showSecurityAuditLog(context),
                  ),
                  ListTile(
                    title: Text('Backup Keys'),
                    subtitle: Text('Export encryption keys for backup'),
                    trailing: Icon(Icons.backup),
                    onTap: () => _showKeyBackupDialog(context),
                  ),
                  ListTile(
                    title: Text('Import Keys'),
                    subtitle: Text('Import encryption keys from backup'),
                    trailing: Icon(Icons.restore),
                    onTap: () => _showKeyImportDialog(context),
                  ),
                  ListTile(
                    title: Text('Reset Security Settings'),
                    subtitle: Text('Reset all security settings to defaults'),
                    trailing: Icon(Icons.restore_outlined),
                    onTap: () => _showResetSecurityDialog(context, provider),
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
  void _showEncryptionAlgorithmPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final algorithms = ['AES-256', 'ChaCha20-Poly1305', 'AES-128', 'Twofish'];
    final descriptions = {
      'AES-256': 'Advanced Encryption Standard (256-bit) - High security',
      'ChaCha20-Poly1305': 'ChaCha20 with Poly1305 - Modern, fast',
      'AES-128': 'Advanced Encryption Standard (128-bit) - Balanced',
      'Twofish': 'Twofish cipher - Alternative to AES',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Encryption Algorithm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: algorithms.map((algorithm) => RadioListTile<String>(
            title: Text(algorithm),
            subtitle: Text(descriptions[algorithm] ?? ''),
            value: algorithm,
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

  void _showKeySizePicker(
    BuildContext context,
    int current,
    Function(int) onChanged,
  ) {
    final keySizes = [128, 256, 512, 1024, 2048, 4096];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Key Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: keySizes.map((size) => RadioListTile<int>(
            title: Text('$size bits'),
            subtitle: Text(_getKeySizeDescription(size)),
            value: size,
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

  String _getKeySizeDescription(int size) {
    switch (size) {
      case 128: return 'Fast, moderate security';
      case 256: return 'Balanced security and performance';
      case 512: return 'High security';
      case 1024: return 'Very high security, slower';
      case 2048: return 'Maximum security, slow';
      case 4096: return 'Extreme security, very slow';
      default: return '';
    }
  }

  void _showAuthMethodPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final methods = ['Password', 'PIN', 'Biometric', 'Certificate'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Authentication Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) => RadioListTile<String>(
            title: Text(method),
            value: method,
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

  void _showSignatureAlgorithmPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final algorithms = ['RSA-SHA256', 'ECDSA-SHA256', 'Ed25519', 'RSA-PSS'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Signature Algorithm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: algorithms.map((algorithm) => RadioListTile<String>(
            title: Text(algorithm),
            value: algorithm,
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
        content: Text('Duration picker - Coming soon\nCurrent: ${current.inMinutes} min'),
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

  void _showTrustedPeersScreen(BuildContext context, List<String> peers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trusted Peers'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: peers.length + 1,
            itemBuilder: (context, index) {
              if (index == peers.length) {
                return ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Add Trusted Peer'),
                  onTap: () {
                    // Add peer functionality
                  },
                );
              }
              return ListTile(
                leading: Icon(Icons.verified_user),
                title: Text(peers[index]),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () {
                    // Remove peer functionality
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

  void _showCertificateManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Certificate Management'),
        content: Text('Certificate management functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSecurityAuditLog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Security Audit Log'),
        content: Text('Security audit log functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showKeyBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup Keys'),
        content: Text('This will export your encryption keys for backup purposes.\n\nWarning: Keep the backup secure and never share it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Backup keys functionality
              Navigator.pop(context);
            },
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showKeyImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Keys'),
        content: Text('This will import encryption keys from a backup file.\n\nWarning: This will replace your current keys.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Import keys functionality
              Navigator.pop(context);
            },
            child: Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showResetSecurityDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Security Settings'),
        content: Text('This will reset all security settings to their default values.\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset security settings
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }
}
