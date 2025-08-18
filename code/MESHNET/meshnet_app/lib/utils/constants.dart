// lib/utils/constants.dart - MESHNET Application Constants

/// Network Configuration Constants
class NetworkConstants {
  // Bluetooth Configuration
  static const String BLUETOOTH_SERVICE_UUID = "6ba58d1a-72e6-4a8c-b2f7-3c4d5e6f7a8b";
  static const String BLUETOOTH_CHARACTERISTIC_UUID = "8ba58d1a-72e6-4a8c-b2f7-3c4d5e6f7a8c";
  static const int BLUETOOTH_SCAN_TIMEOUT = 30; // seconds
  static const int BLUETOOTH_CONNECTION_TIMEOUT = 15; // seconds
  static const int BLUETOOTH_MAX_CONNECTIONS = 7; // Android BLE limit
  
  // WiFi Direct Configuration
  static const String WIFI_DIRECT_SERVICE_NAME = "MESHNET";
  static const int WIFI_DIRECT_PORT = 8888;
  static const int WIFI_DIRECT_GROUP_SIZE_LIMIT = 8;
  static const int WIFI_DIRECT_DISCOVERY_TIMEOUT = 60; // seconds
  
  // SDR Configuration
  static const String DEFAULT_SDR_FREQUENCY = "433.920"; // MHz
  static const double SDR_MIN_FREQUENCY = 24.0; // MHz
  static const double SDR_MAX_FREQUENCY = 1766.0; // MHz
  static const int SDR_SAMPLE_RATE = 2048000; // 2.048 MHz
  
  // Ham Radio Configuration
  static const String DEFAULT_HAM_FREQUENCY = "144.390"; // MHz APRS
  static const List<String> HAM_EMERGENCY_FREQUENCIES = [
    "146.520", // 2m calling frequency
    "446.000", // 70cm calling frequency
    "144.390", // APRS frequency
  ];
  
  // Message Configuration
  static const int MAX_MESSAGE_SIZE = 1024; // bytes
  static const int MAX_BROADCAST_HOPS = 7;
  static const int MESSAGE_TTL_HOURS = 24;
  static const int RETRY_ATTEMPTS = 3;
  
  // Node Configuration
  static const int NODE_ID_LENGTH = 16; // bytes
  static const int MAX_PEERS = 50;
  static const int PEER_TIMEOUT_MINUTES = 10;
  static const int HEARTBEAT_INTERVAL_SECONDS = 30;

  // Default settings for Settings model
  static const Duration defaultScanInterval = Duration(seconds: 30);
  static const Duration defaultConnectionTimeout = Duration(seconds: 15);
  static const int defaultMaxConnections = 8;
  static const String defaultGroupName = "MESHNET";
  static const int defaultPort = 8080;
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const double defaultSDRFrequency = 433000000.0; // Hz
  static const int defaultSampleRate = 2048000;
  static const double defaultBandwidth = 1000000.0;
  static const String defaultModulation = "FSK";
  static const double defaultTxPower = 10.0;
  static const String defaultCallSign = "N0CALL";
  static const double defaultHamFrequency = 145500000.0; // Hz
  static const int defaultBaud = 1200;
  static const String defaultHamMode = "PACKET";
  static const int defaultMaxMessageSize = 8192;
  static const Duration defaultMessageTimeout = Duration(seconds: 30);
  static const Duration defaultHeartbeatInterval = Duration(seconds: 60);
  static const Duration defaultDiscoveryInterval = Duration(seconds: 30);
  static const int defaultMaxRetries = 3;
}

/// Emergency System Constants
class EmergencyConstants {
  // Emergency Types
  static const String EMERGENCY_MEDICAL = "medical";
  static const String EMERGENCY_FIRE = "fire";
  static const String EMERGENCY_POLICE = "police";
  static const String EMERGENCY_NATURAL_DISASTER = "natural_disaster";
  static const String EMERGENCY_ACCIDENT = "accident";
  static const String EMERGENCY_MISSING_PERSON = "missing_person";
  static const String EMERGENCY_GENERAL = "general";
  
  // Emergency Levels
  static const String LEVEL_INFO = "info";
  static const String LEVEL_LOW = "low";
  static const String LEVEL_MEDIUM = "medium";
  static const String LEVEL_HIGH = "high";
  static const String LEVEL_CRITICAL = "critical";
  
  // Detection Thresholds
  static const double MOVEMENT_THRESHOLD_METERS = 50.0;
  static const double CRASH_DETECTION_THRESHOLD = 120.0; // km/h
  static const int INACTIVITY_TIMEOUT_HOURS = 12;
  static const int PANIC_BUTTON_TIMEOUT_SECONDS = 10;
  static const double SHAKE_DETECTION_THRESHOLD = 15.0; // m/s²
  
  // Location Configuration
  static const double EMERGENCY_ACCURACY_THRESHOLD = 50.0; // meters
  static const int LOCATION_UPDATE_INTERVAL_SECONDS = 30;
  static const int EMERGENCY_UPDATE_INTERVAL_SECONDS = 10;
  
  // Beacon Configuration
  static const int BEACON_INTERVAL_SECONDS = 60;
  static const int BEACON_TTL_HOURS = 24;
  static const int MAX_BEACON_RETRIES = 5;

  // Default settings for Settings model
  static const Duration defaultTimeout = Duration(hours: 24);
  static const Duration defaultBroadcastInterval = Duration(seconds: 30);
  static const double defaultMaxRange = 10000.0; // meters
  static const List<String> defaultServices = ['ambulance', 'fire', 'police'];
  static const int defaultPriority = 1;
}

/// UI/UX Constants
class UIConstants {
  // Colors
  static const int PRIMARY_COLOR = 0xFF2196F3; // Blue
  static const int EMERGENCY_COLOR = 0xFFF44336; // Red
  static const int SUCCESS_COLOR = 0xFF4CAF50; // Green
  static const int WARNING_COLOR = 0xFFFF9800; // Orange
  static const int INFO_COLOR = 0xFF2196F3; // Blue
  
  // Animation Durations
  static const int ANIMATION_DURATION_SHORT = 200; // milliseconds
  static const int ANIMATION_DURATION_MEDIUM = 400; // milliseconds
  static const int ANIMATION_DURATION_LONG = 800; // milliseconds
  
  // Spacing
  static const double PADDING_SMALL = 8.0;
  static const double PADDING_MEDIUM = 16.0;
  static const double PADDING_LARGE = 24.0;

  // Default settings for Settings model
  static const double defaultFontSize = 14.0;
  static const String defaultLanguage = 'en';
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const int defaultPrimaryColor = 0xFF2196F3;
  
  // Padding
  static const double paddingExtraLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusExtraLarge = 24.0;
  
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeExtraLarge = 18.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeading = 24.0;
  
  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
  
  // Screen Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
}

/// Security Constants
class SecurityConstants {
  // Encryption
  static const int AES_KEY_LENGTH = 256; // bits
  static const int RSA_KEY_LENGTH = 2048; // bits
  static const int SALT_LENGTH = 32; // bytes
  static const int IV_LENGTH = 16; // bytes
  
  // Key Exchange
  static const int KEY_EXCHANGE_TIMEOUT_SECONDS = 30;
  static const int KEY_ROTATION_HOURS = 24;
  static const int MAX_KEY_AGE_DAYS = 7;
  
  // Authentication
  static const int MAX_LOGIN_ATTEMPTS = 5;
  static const int LOCKOUT_DURATION_MINUTES = 15;
  static const int SESSION_TIMEOUT_HOURS = 8;
  
  // Emergency Wipe
  static const int WIPE_PASSES_BASIC = 1;
  static const int WIPE_PASSES_SECURE = 3;
  static const int WIPE_PASSES_MILITARY = 7;
  static const int MAX_FAILED_ATTEMPTS = 10;
  static const int INACTIVITY_TIMEOUT_HOURS = 72;

  // Default settings for Settings model
  static const String defaultEncryptionAlgorithm = 'AES-256-GCM';
  static const int defaultKeySize = 256;
  static const Duration defaultKeyRotationInterval = Duration(hours: 24);
  static const Duration defaultSessionTimeout = Duration(minutes: 30);
  static const int defaultMaxLoginAttempts = 3;
  static const double defaultMinTrustScore = 0.5;
}

/// Storage Constants
class StorageConstants {
  // Database
  static const String DATABASE_NAME = "meshnet.db";
  static const int DATABASE_VERSION = 1;
  static const int MAX_DATABASE_SIZE_MB = 100;
  
  // Cache
  static const int MAX_CACHE_SIZE_MB = 50;
  static const int CACHE_TTL_HOURS = 24;
  static const int MAX_CACHED_MESSAGES = 1000;
  
  // File Storage
  static const int MAX_FILE_SIZE_MB = 10;
  static const String TEMP_DIR = "temp";
  static const String CACHE_DIR = "cache";
  static const String LOGS_DIR = "logs";
  
  // Preferences Keys
  static const String PREF_NODE_ID = "node_id";
  static const String PREF_DISPLAY_NAME = "display_name";
  static const String PREF_ENCRYPTION_ENABLED = "encryption_enabled";
  static const String PREF_EMERGENCY_MODE = "emergency_mode";
  static const String PREF_DARK_MODE = "dark_mode";
  static const String PREF_NOTIFICATION_ENABLED = "notification_enabled";
}

/// Protocol Constants
class ProtocolConstants {
  // Message Headers
  static const String HEADER_VERSION = "version";
  static const String HEADER_TYPE = "type";
  static const String HEADER_SOURCE = "source";
  static const String HEADER_TARGET = "target";
  static const String HEADER_TIMESTAMP = "timestamp";
  static const String HEADER_TTL = "ttl";
  static const String HEADER_SIGNATURE = "signature";
  
  // Protocol Versions
  static const String PROTOCOL_VERSION_1_0 = "1.0";
  static const String CURRENT_PROTOCOL_VERSION = PROTOCOL_VERSION_1_0;
  
  // Packet Types
  static const String PACKET_ANNOUNCE = "announce";
  static const String PACKET_DATA = "data";
  static const String PACKET_PATH_REQUEST = "path_request";
  static const String PACKET_PATH_REPLY = "path_reply";
  static const String PACKET_EMERGENCY = "emergency";
  static const String PACKET_HEARTBEAT = "heartbeat";
  
  // Magic Numbers
  static const int PACKET_MAGIC = 0xCAFEBABE;
  static const int EMERGENCY_MAGIC = 0xDEADBEEF;
  static const int HEARTBEAT_MAGIC = 0xFEEDFACE;
}

/// Error Messages
class ErrorMessages {
  // Network Errors
  static const String NETWORK_UNAVAILABLE = "Network is not available";
  static const String CONNECTION_FAILED = "Failed to establish connection";
  static const String CONNECTION_TIMEOUT = "Connection timed out";
  static const String BLUETOOTH_DISABLED = "Bluetooth is disabled";
  static const String WIFI_DISABLED = "WiFi is disabled";
  static const String PERMISSION_DENIED = "Permission denied";
  
  // Message Errors
  static const String MESSAGE_TOO_LARGE = "Message is too large";
  static const String MESSAGE_ENCRYPTION_FAILED = "Failed to encrypt message";
  static const String MESSAGE_DECRYPTION_FAILED = "Failed to decrypt message";
  static const String MESSAGE_SEND_FAILED = "Failed to send message";
  static const String MESSAGE_INVALID_FORMAT = "Invalid message format";
  
  // Emergency Errors
  static const String EMERGENCY_ACTIVATION_FAILED = "Failed to activate emergency mode";
  static const String LOCATION_UNAVAILABLE = "Location is not available";
  static const String EMERGENCY_BEACON_FAILED = "Failed to send emergency beacon";
  
  // Security Errors
  static const String KEY_EXCHANGE_FAILED = "Key exchange failed";
  static const String AUTHENTICATION_FAILED = "Authentication failed";
  static const String ENCRYPTION_KEY_INVALID = "Invalid encryption key";
  static const String SIGNATURE_VERIFICATION_FAILED = "Signature verification failed";
  
  // Storage Errors
  static const String DATABASE_ERROR = "Database error occurred";
  static const String STORAGE_FULL = "Storage is full";
  static const String FILE_NOT_FOUND = "File not found";
  static const String PERMISSION_DENIED_STORAGE = "Storage permission denied";
}

/// Success Messages
class SuccessMessages {
  // Network
  static const String CONNECTION_ESTABLISHED = "Connection established successfully";
  static const String PEER_DISCOVERED = "New peer discovered";
  static const String NETWORK_READY = "Network is ready";
  
  // Messages
  static const String MESSAGE_SENT = "Message sent successfully";
  static const String MESSAGE_RECEIVED = "Message received";
  static const String MESSAGE_ENCRYPTED = "Message encrypted successfully";
  
  // Emergency
  static const String EMERGENCY_ACTIVATED = "Emergency mode activated";
  static const String EMERGENCY_BEACON_SENT = "Emergency beacon sent";
  static const String LOCATION_SHARED = "Location shared successfully";
  
  // Security
  static const String KEY_EXCHANGE_COMPLETE = "Key exchange completed";
  static const String AUTHENTICATION_SUCCESS = "Authentication successful";
  static const String ENCRYPTION_ENABLED = "Encryption enabled";
}

/// App Information
class AppInfo {
  static const String APP_NAME = "MESHNET";
  static const String APP_VERSION = "1.0.0";
  static const String APP_BUILD = "1";
  static const String APP_DESCRIPTION = "Emergency Mesh Network Communication";
  static const String DEVELOPER_NAME = "MESHNET Development Team";
  static const String SUPPORT_EMAIL = "support@meshnet.app";
  static const String WEBSITE_URL = "https://meshnet.app";
  static const String GITHUB_URL = "https://github.com/meshnet/meshnet-app";
}
