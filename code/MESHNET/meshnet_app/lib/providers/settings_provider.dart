// lib/providers/settings_provider.dart - Settings State Management
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meshnet_app/models/settings.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Settings provider for managing application settings
class SettingsProvider extends ChangeNotifier {
  final Logger _logger = Logger('SettingsProvider');
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = false;
  String? _error;

  /// Current settings
  AppSettings get settings => _settings;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Network settings
  NetworkSettings get network => _settings.network;

  /// Emergency settings
  EmergencySettings get emergency => _settings.emergency;

  /// UI settings
  UISettings get ui => _settings.ui;

  /// Security settings
  SecuritySettings get security => _settings.security;

  /// System settings
  SystemSettings get system => _settings.system;

  // Theme mode getter for MaterialApp
  ThemeMode get themeMode => ui.darkMode ? ThemeMode.dark : ThemeMode.light;

  // Primary color for theme
  Color get primaryColor => Color(ui.themeColor);

  // Font family for theme
  String? get fontFamily => 'Roboto'; // Default font family

  // Border radius for UI components
  double get borderRadius => 8.0; // Default border radius

  /// Load settings from storage
  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.info('Loading settings from storage');
      
      // TODO: Implement actual storage loading
      // For now, use defaults
      _settings = AppSettings.defaults();
      
      _logger.info('Settings loaded successfully');
    } catch (e) {
      _error = 'Failed to load settings: $e';
      _logger.severe('Failed to load settings', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save settings to storage
  Future<void> saveSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logger.info('Saving settings to storage');
      
      // TODO: Implement actual storage saving
      final json = _settings.toJson();
      _logger.fine('Settings JSON: $json');
      
      _logger.info('Settings saved successfully');
    } catch (e) {
      _error = 'Failed to save settings: $e';
      _logger.severe('Failed to save settings', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update network settings
  Future<void> updateNetworkSettings(NetworkSettings newNetwork) async {
    _logger.info('Updating network settings');
    
    _settings = _settings.copyWith(network: newNetwork);
    notifyListeners();
    
    await saveSettings();
  }

  /// Update emergency settings
  Future<void> updateEmergencySettings(EmergencySettings newEmergency) async {
    _logger.info('Updating emergency settings');
    
    _settings = _settings.copyWith(emergency: newEmergency);
    notifyListeners();
    
    await saveSettings();
  }

  /// Update UI settings
  Future<void> updateUISettings(UISettings newUI) async {
    _logger.info('Updating UI settings');
    
    _settings = _settings.copyWith(ui: newUI);
    notifyListeners();
    
    await saveSettings();
  }

  /// Update security settings
  Future<void> updateSecuritySettings(SecuritySettings newSecurity) async {
    _logger.info('Updating security settings');
    
    _settings = _settings.copyWith(security: newSecurity);
    notifyListeners();
    
    await saveSettings();
  }

  /// Update system settings
  Future<void> updateSystemSettings(SystemSettings newSystem) async {
    _logger.info('Updating system settings');
    
    _settings = _settings.copyWith(system: newSystem);
    notifyListeners();
    
    await saveSettings();
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    _logger.info('Resetting settings to defaults');
    
    _settings = AppSettings.defaults();
    notifyListeners();
    
    await saveSettings();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Update specific network setting
  void updateBluetoothEnabled(bool enabled) {
    final newNetwork = network.copyWith(bluetoothEnabled: enabled);
    updateNetworkSettings(newNetwork);
  }

  void updateWifiDirectEnabled(bool enabled) {
    final newNetwork = network.copyWith(wifiDirectEnabled: enabled);
    updateNetworkSettings(newNetwork);
  }

  void updateSDREnabled(bool enabled) {
    final newNetwork = network.copyWith(sdrEnabled: enabled);
    updateNetworkSettings(newNetwork);
  }

  void updateHamRadioEnabled(bool enabled) {
    final newNetwork = network.copyWith(hamRadioEnabled: enabled);
    updateNetworkSettings(newNetwork);
  }

  void updateSDRFrequency(double frequency) {
    final newNetwork = network.copyWith(sdrFrequency: frequency);
    updateNetworkSettings(newNetwork);
  }

  void updateHamCallSign(String callSign) {
    final newNetwork = network.copyWith(hamRadioCallSign: callSign);
    updateNetworkSettings(newNetwork);
  }

  /// Update specific UI settings
  void updateDarkMode(bool enabled) {
    final newUI = ui.copyWith(darkMode: enabled);
    updateUISettings(newUI);
  }

  void updateAnimationsEnabled(bool enabled) {
    final newUI = ui.copyWith(animationsEnabled: enabled);
    updateUISettings(newUI);
  }

  void updateSoundEnabled(bool enabled) {
    final newUI = ui.copyWith(soundEnabled: enabled);
    updateUISettings(newUI);
  }

  void updateNotificationsEnabled(bool enabled) {
    final newUI = ui.copyWith(notificationsEnabled: enabled);
    updateUISettings(newUI);
  }

  /// Update specific security settings
  void updateEncryptionEnabled(bool enabled) {
    final newSecurity = security.copyWith(encryptionEnabled: enabled);
    updateSecuritySettings(newSecurity);
  }

  void updateRequireAuthentication(bool enabled) {
    final newSecurity = security.copyWith(requireAuthentication: enabled);
    updateSecuritySettings(newSecurity);
  }

  void updateTrustScoreEnabled(bool enabled) {
    final newSecurity = security.copyWith(trustScoreEnabled: enabled);
    updateSecuritySettings(newSecurity);
  }

  /// Update specific emergency settings
  void updateEmergencyModeEnabled(bool enabled) {
    final newEmergency = emergency.copyWith(emergencyModeEnabled: enabled);
    updateEmergencySettings(newEmergency);
  }

  void updateLocationSharingEnabled(bool enabled) {
    final newEmergency = emergency.copyWith(locationSharingEnabled: enabled);
    updateEmergencySettings(newEmergency);
  }

  void updateAutoEmergencyBroadcast(bool enabled) {
    final newEmergency = emergency.copyWith(autoEmergencyBroadcast: enabled);
    updateEmergencySettings(newEmergency);
  }

  /// Update specific system settings
  void updateDebugMode(bool enabled) {
    final newSystem = system.copyWith(debugMode: enabled);
    updateSystemSettings(newSystem);
  }

  void updateCrashReporting(bool enabled) {
    final newSystem = system.copyWith(crashReporting: enabled);
    updateSystemSettings(newSystem);
  }

  void updateAnalyticsEnabled(bool enabled) {
    final newSystem = system.copyWith(analyticsEnabled: enabled);
    updateSystemSettings(newSystem);
  }

  void updateAutoUpdate(bool enabled) {
    final newSystem = system.copyWith(autoUpdate: enabled);
    updateSystemSettings(newSystem);
  }

  void updateLowPowerMode(bool enabled) {
    final newSystem = system.copyWith(lowPowerMode: enabled);
    updateSystemSettings(newSystem);
  }
}
