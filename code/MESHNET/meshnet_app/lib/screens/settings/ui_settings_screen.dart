// lib/screens/settings/ui_settings_screen.dart - User Interface Configuration Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/utils/constants.dart';

class UISettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UI Settings'),
        backgroundColor: Color(UIConstants.PRIMARY_COLOR),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          final ui = provider.ui;
          
          return ListView(
            padding: EdgeInsets.all(UIConstants.PADDING_MEDIUM),
            children: [
              // Theme Section
              _buildSectionCard(
                context,
                title: 'Theme & Appearance',
                icon: Icons.palette,
                iconColor: Colors.purple,
                children: [
                  ListTile(
                    title: Text('Theme Mode'),
                    subtitle: Text(ui.themeMode),
                    trailing: Icon(Icons.brightness_6),
                    onTap: () => _showThemeModePicker(
                      context,
                      ui.themeMode,
                      (themeMode) {
                        final newUI = ui.copyWith(themeMode: themeMode);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Primary Color'),
                    subtitle: Text('App primary color'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(ui.primaryColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    onTap: () => _showColorPicker(
                      context,
                      'Primary Color',
                      ui.primaryColor,
                      (color) {
                        final newUI = ui.copyWith(primaryColor: color);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Accent Color'),
                    subtitle: Text('App accent color'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(ui.accentColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    onTap: () => _showColorPicker(
                      context,
                      'Accent Color',
                      ui.accentColor,
                      (color) {
                        final newUI = ui.copyWith(accentColor: color);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Font Size'),
                    subtitle: Text('${ui.fontSize.toStringAsFixed(1)}sp'),
                    trailing: Icon(Icons.text_fields),
                    onTap: () => _showFontSizeSlider(
                      context,
                      ui.fontSize,
                      (fontSize) {
                        final newUI = ui.copyWith(fontSize: fontSize);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Font Family'),
                    subtitle: Text(ui.fontFamily),
                    trailing: Icon(Icons.font_download),
                    onTap: () => _showFontFamilyPicker(
                      context,
                      ui.fontFamily,
                      (fontFamily) {
                        final newUI = ui.copyWith(fontFamily: fontFamily);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Language & Localization Section
              _buildSectionCard(
                context,
                title: 'Language & Localization',
                icon: Icons.language,
                iconColor: Colors.blue,
                children: [
                  ListTile(
                    title: Text('Language'),
                    subtitle: Text(ui.language),
                    trailing: Icon(Icons.translate),
                    onTap: () => _showLanguagePicker(
                      context,
                      ui.language,
                      (language) {
                        final newUI = ui.copyWith(language: language);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Date Format'),
                    subtitle: Text(ui.dateFormat),
                    trailing: Icon(Icons.date_range),
                    onTap: () => _showDateFormatPicker(
                      context,
                      ui.dateFormat,
                      (dateFormat) {
                        final newUI = ui.copyWith(dateFormat: dateFormat);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Time Format'),
                    subtitle: Text(ui.timeFormat),
                    trailing: Icon(Icons.access_time),
                    onTap: () => _showTimeFormatPicker(
                      context,
                      ui.timeFormat,
                      (timeFormat) {
                        final newUI = ui.copyWith(timeFormat: timeFormat);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Display Options Section
              _buildSectionCard(
                context,
                title: 'Display Options',
                icon: Icons.display_settings,
                iconColor: Colors.green,
                children: [
                  SwitchListTile(
                    title: Text('Show Status Bar'),
                    subtitle: Text('Display connection status and indicators'),
                    value: ui.showStatusBar,
                    onChanged: (value) {
                      final newUI = ui.copyWith(showStatusBar: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Show Peer Count'),
                    subtitle: Text('Display number of connected peers'),
                    value: ui.showPeerCount,
                    onChanged: (value) {
                      final newUI = ui.copyWith(showPeerCount: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Show Message Timestamps'),
                    subtitle: Text('Display timestamps on messages'),
                    value: ui.showTimestamps,
                    onChanged: (value) {
                      final newUI = ui.copyWith(showTimestamps: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Show Avatars'),
                    subtitle: Text('Display user avatars in chat'),
                    value: ui.showAvatars,
                    onChanged: (value) {
                      final newUI = ui.copyWith(showAvatars: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  ListTile(
                    title: Text('Message Bubble Style'),
                    subtitle: Text(ui.messageBubbleStyle),
                    trailing: Icon(Icons.chat_bubble),
                    onTap: () => _showBubbleStylePicker(
                      context,
                      ui.messageBubbleStyle,
                      (style) {
                        final newUI = ui.copyWith(messageBubbleStyle: style);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Animations & Effects Section
              _buildSectionCard(
                context,
                title: 'Animations & Effects',
                icon: Icons.animation,
                iconColor: Colors.orange,
                children: [
                  SwitchListTile(
                    title: Text('Enable Animations'),
                    subtitle: Text('Use animations and transitions'),
                    value: ui.enableAnimations,
                    onChanged: (value) {
                      final newUI = ui.copyWith(enableAnimations: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  if (ui.enableAnimations) ...[
                    ListTile(
                      title: Text('Animation Speed'),
                      subtitle: Text('${(ui.animationSpeed * 100).toStringAsFixed(0)}%'),
                      trailing: Icon(Icons.speed),
                      onTap: () => _showAnimationSpeedSlider(
                        context,
                        ui.animationSpeed,
                        (speed) {
                          final newUI = ui.copyWith(animationSpeed: speed);
                          provider.updateUISettings(newUI);
                        },
                      ),
                    ),
                  ],
                  SwitchListTile(
                    title: Text('Haptic Feedback'),
                    subtitle: Text('Vibrate on button presses'),
                    value: ui.hapticFeedback,
                    onChanged: (value) {
                      final newUI = ui.copyWith(hapticFeedback: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Sound Effects'),
                    subtitle: Text('Play sounds for UI interactions'),
                    value: ui.soundEffects,
                    onChanged: (value) {
                      final newUI = ui.copyWith(soundEffects: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Layout & Navigation Section
              _buildSectionCard(
                context,
                title: 'Layout & Navigation',
                icon: Icons.view_quilt,
                iconColor: Colors.teal,
                children: [
                  ListTile(
                    title: Text('Layout Density'),
                    subtitle: Text(ui.layoutDensity),
                    trailing: Icon(Icons.density_medium),
                    onTap: () => _showLayoutDensityPicker(
                      context,
                      ui.layoutDensity,
                      (density) {
                        final newUI = ui.copyWith(layoutDensity: density);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: Text('Compact Mode'),
                    subtitle: Text('Use compact UI elements'),
                    value: ui.compactMode,
                    onChanged: (value) {
                      final newUI = ui.copyWith(compactMode: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Show Navigation Labels'),
                    subtitle: Text('Display labels on navigation icons'),
                    value: ui.showNavigationLabels,
                    onChanged: (value) {
                      final newUI = ui.copyWith(showNavigationLabels: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  ListTile(
                    title: Text('Tab Bar Position'),
                    subtitle: Text(ui.tabBarPosition),
                    trailing: Icon(Icons.tab),
                    onTap: () => _showTabBarPositionPicker(
                      context,
                      ui.tabBarPosition,
                      (position) {
                        final newUI = ui.copyWith(tabBarPosition: position);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Accessibility Section
              _buildSectionCard(
                context,
                title: 'Accessibility',
                icon: Icons.accessibility,
                iconColor: Colors.indigo,
                children: [
                  SwitchListTile(
                    title: Text('High Contrast Mode'),
                    subtitle: Text('Increase contrast for better visibility'),
                    value: ui.highContrastMode,
                    onChanged: (value) {
                      final newUI = ui.copyWith(highContrastMode: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Large Text Mode'),
                    subtitle: Text('Use larger text sizes'),
                    value: ui.largeTextMode,
                    onChanged: (value) {
                      final newUI = ui.copyWith(largeTextMode: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Screen Reader Support'),
                    subtitle: Text('Optimize for screen readers'),
                    value: ui.screenReaderSupport,
                    onChanged: (value) {
                      final newUI = ui.copyWith(screenReaderSupport: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  SwitchListTile(
                    title: Text('Reduce Motion'),
                    subtitle: Text('Minimize animations and movement'),
                    value: ui.reduceMotion,
                    onChanged: (value) {
                      final newUI = ui.copyWith(reduceMotion: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                ],
              ),

              SizedBox(height: UIConstants.PADDING_MEDIUM),

              // Advanced UI Section
              _buildSectionCard(
                context,
                title: 'Advanced',
                icon: Icons.tune,
                iconColor: Colors.red,
                children: [
                  SwitchListTile(
                    title: Text('Developer Mode'),
                    subtitle: Text('Show developer options and debug info'),
                    value: ui.developerMode,
                    onChanged: (value) {
                      final newUI = ui.copyWith(developerMode: value);
                      provider.updateUISettings(newUI);
                    },
                  ),
                  if (ui.developerMode) ...[
                    SwitchListTile(
                      title: Text('Show Debug Info'),
                      subtitle: Text('Display debug information overlay'),
                      value: ui.showDebugInfo,
                      onChanged: (value) {
                        final newUI = ui.copyWith(showDebugInfo: value);
                        provider.updateUISettings(newUI);
                      },
                    ),
                    SwitchListTile(
                      title: Text('Show Performance Metrics'),
                      subtitle: Text('Display FPS and performance data'),
                      value: ui.showPerformanceMetrics,
                      onChanged: (value) {
                        final newUI = ui.copyWith(showPerformanceMetrics: value);
                        provider.updateUISettings(newUI);
                      },
                    ),
                  ],
                  ListTile(
                    title: Text('Reset UI Settings'),
                    subtitle: Text('Reset all UI settings to defaults'),
                    trailing: Icon(Icons.restore),
                    onTap: () => _showResetUIDialog(context, provider),
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
  void _showThemeModePicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final themeModes = ['System', 'Light', 'Dark'];
    final descriptions = {
      'System': 'Follow system theme',
      'Light': 'Always use light theme',
      'Dark': 'Always use dark theme',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeModes.map((mode) => RadioListTile<String>(
            title: Text(mode),
            subtitle: Text(descriptions[mode] ?? ''),
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

  void _showColorPicker(
    BuildContext context,
    String title,
    int currentColor,
    Function(int) onChanged,
  ) {
    final colors = [
      Colors.blue.value,
      Colors.green.value,
      Colors.orange.value,
      Colors.red.value,
      Colors.purple.value,
      Colors.teal.value,
      Colors.indigo.value,
      Colors.pink.value,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Wrap(
          children: colors.map((color) => GestureDetector(
            onTap: () {
              onChanged(color);
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: color == currentColor 
                    ? Border.all(color: Colors.black, width: 3)
                    : Border.all(color: Colors.grey),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeSlider(
    BuildContext context,
    double current,
    Function(double) onChanged,
  ) {
    double value = current;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Font Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.toStringAsFixed(1)}sp'),
              Slider(
                value: value,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                min: 10.0,
                max: 24.0,
              ),
              Text('Preview text with selected size', 
                style: TextStyle(fontSize: value)),
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

  void _showFontFamilyPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final fonts = ['System Default', 'Roboto', 'Open Sans', 'Lato', 'Poppins', 'Montserrat'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Font Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fonts.map((font) => RadioListTile<String>(
            title: Text(font, style: TextStyle(
              fontFamily: font == 'System Default' ? null : font,
            )),
            value: font,
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

  void _showLanguagePicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final languages = {
      'English': 'en',
      'Türkçe': 'tr',
      'Español': 'es',
      'Français': 'fr',
      'Deutsch': 'de',
      '中文': 'zh',
      'العربية': 'ar',
      'Русский': 'ru',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.entries.map((entry) => RadioListTile<String>(
            title: Text(entry.key),
            value: entry.value,
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

  void _showDateFormatPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final formats = ['MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd', 'dd MMM yyyy'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) => RadioListTile<String>(
            title: Text(format),
            subtitle: Text('Example: ${_formatDateExample(format)}'),
            value: format,
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

  String _formatDateExample(String format) {
    final now = DateTime.now();
    switch (format) {
      case 'MM/dd/yyyy': return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
      case 'dd/MM/yyyy': return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      case 'yyyy-MM-dd': return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      case 'dd MMM yyyy': return '${now.day} Jan ${now.year}';
      default: return format;
    }
  }

  void _showTimeFormatPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final formats = ['12-hour', '24-hour'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Time Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) => RadioListTile<String>(
            title: Text(format),
            subtitle: Text(format == '12-hour' ? 'Example: 2:30 PM' : 'Example: 14:30'),
            value: format,
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

  void _showBubbleStylePicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final styles = ['Rounded', 'Square', 'Minimal', 'Outlined'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Bubble Style'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: styles.map((style) => RadioListTile<String>(
            title: Text(style),
            value: style,
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

  void _showAnimationSpeedSlider(
    BuildContext context,
    double current,
    Function(double) onChanged,
  ) {
    double value = current;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Animation Speed'),
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
                min: 0.5,
                max: 2.0,
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

  void _showLayoutDensityPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final densities = ['Compact', 'Standard', 'Comfortable'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Layout Density'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: densities.map((density) => RadioListTile<String>(
            title: Text(density),
            value: density,
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

  void _showTabBarPositionPicker(
    BuildContext context,
    String current,
    Function(String) onChanged,
  ) {
    final positions = ['Top', 'Bottom'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tab Bar Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: positions.map((position) => RadioListTile<String>(
            title: Text(position),
            value: position,
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

  void _showResetUIDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset UI Settings'),
        content: Text('This will reset all UI settings to their default values.\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset UI settings
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
