// lib/utils/constants.dart - Uygulama sabitleri
class AppConstants {
  // Network configuration
  static const String appName = 'MeshNet Emergency';
  static const String appVersion = '1.0.0';
  static const String protocolVersion = '1.0';
  
  // Bluetooth LE configuration (BitChat ile uyumlu)
  static const String serviceUuid = '6ba1b218-15a8-461f-9fa8-5dcae2650156';
  static const String characteristicUuid = 'c004be86-da43-4c07-b3db-5f92e7e9e6b0';
  
  // Mesh network parameters
  static const int maxHopCount = 8;
  static const int maxPeersPerNetwork = 50;
  static const int messageTimeoutSeconds = 300; // 5 dakika
  static const int peerTimeoutSeconds = 120; // 2 dakika
  
  // Message configuration
  static const int maxMessageLength = 1024;
  static const int maxChannelNameLength = 32;
  static const int maxUsernameLength = 24;
  
  // RTL-SDR/HackRF configuration (BitChat'te olmayan)
  static const double defaultFrequency = 433.92; // MHz
  static const double minFrequency = 400.0;
  static const double maxFrequency = 470.0;
  static const int defaultBandwidth = 2400; // Hz
  
  // Emergency protocols
  static const String emergencyChannel = 'emergency';
  static const String broadcastChannel = 'broadcast';
  static const List<String> systemChannels = [emergencyChannel, broadcastChannel];
  
  // Routing algorithm parameters
  static const int routeTableUpdateInterval = 30; // saniye
  static const int maxRouteAge = 300; // saniye
  static const double signalStrengthThreshold = -90.0; // dBm
  
  // UI configuration
  static const int maxMessagesInMemory = 500;
  static const int messageBatchSize = 20;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Encryption parameters
  static const int keyRotationInterval = 3600; // 1 saat
  static const String defaultEncryptionAlgorithm = 'AES-256-GCM';
  
  // Storage configuration
  static const String databaseName = 'meshnet.db';
  static const int databaseVersion = 1;
  
  // Error codes
  static const int errorBluetoothDisabled = 1001;
  static const int errorPermissionDenied = 1002;
  static const int errorNetworkTimeout = 1003;
  static const int errorEncryptionFailure = 1004;
  static const int errorRadioNotAvailable = 1005;
}

// Message types (BitChat uyumlu + yeni emergency types)
enum MessageType {
  text,
  image,
  file,
  system,
  emergency,
  heartbeat,
  routeUpdate,
  keyExchange,
}

// Network protocols
enum NetworkProtocol {
  bluetoothLE,
  wifiDirect,
  rtlSdr,
  hackRf,
}

// Emergency message priorities
enum EmergencyPriority {
  low,      // Bilgi mesajları
  medium,   // Uyarılar
  high,     // Acil yardım
  critical, // Hayati tehlike
}

// Peer discovery states
enum PeerStatus {
  discovered,
  connecting,
  connected,
  disconnected,
  blocked,
}

// UI themes
class AppTheme {
  static const primaryColor = Color(0xFF1565C0);
  static const accentColor = Color(0xFFFF6F00);
  static const emergencyColor = Color(0xFFD32F2F);
  static const successColor = Color(0xFF388E3C);
  static const warningColor = Color(0xFFF57C00);
  
  static const backgroundColor = Color(0xFF121212);
  static const surfaceColor = Color(0xFF1E1E1E);
  static const cardColor = Color(0xFF2D2D2D);
  
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0BEC5);
  static const textHint = Color(0xFF757575);
}

// Default user configuration
class DefaultConfig {
  static const String defaultUsername = 'User';
  static const String defaultAvatar = 'default_avatar';
  static const bool defaultEncryption = true;
  static const bool defaultEmergencyMode = false;
  static const NetworkProtocol defaultProtocol = NetworkProtocol.bluetoothLE;
  static const double defaultTransmitPower = 10.0; // dBm
}
