# 1. Temel Kurulum ve Geliştirme Ortamı

## 📋 Bu Aşamada Yapılacaklar

Bu aşamada, BitChat projesini temel alarak MESHNET projesi için geliştirme ortamını kuracağız.

### ✅ Tamamlanması Gerekenler:
1. **Geliştirme ortamı kurulumu** (Flutter/React Native)
2. **BitChat kodunu inceleme ve analiz**
3. **Temel proje yapısı oluşturma**
4. **Native platform entegrasyonu hazırlıkları**
5. **Git repository kurulumu**

## 🔧 Geliştirme Ortamı Kurulumu

### **Seçenek 1: Flutter (Önerilen)**

#### **1.1 Flutter SDK Kurulumu**
```bash
# Flutter SDK indirme
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Flutter doctor kontrolü
flutter doctor
```

#### **1.2 Platform Gereksinimleri**
```bash
# Android Studio kurulumu
# iOS development için Xcode kurulumu (macOS)
# VS Code + Flutter extension (önerilen editor)

# Flutter dependencies
flutter doctor --android-licenses
```

#### **1.3 Gerekli Paketler**
```yaml
# pubspec.yaml dependencies
dependencies:
  flutter:
    sdk: flutter
  
  # Network & Communication
  flutter_bluetooth_serial: ^0.4.0
  wifi_scan: ^0.4.1
  network_info_plus: ^4.0.2
  
  # Cryptography
  cryptography: ^2.5.0
  encrypt: ^5.0.1
  
  # Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0
  
  # UI & Utils
  provider: ^6.0.5
  intl: ^0.18.1
  path_provider: ^2.1.0
  
  # SDR Integration (gelecek aşamalar için)
  ffi: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

### **Seçenek 2: React Native**

#### **2.1 React Native CLI Kurulumu**
```bash
# Node.js ve npm kurulumu gerekli
npm install -g react-native-cli

# React Native project oluşturma
npx react-native init MeshNetApp
cd MeshNetApp
```

#### **2.2 Gerekli Paketler**
```json
{
  "dependencies": {
    "react-native-bluetooth-serial": "^0.6.0",
    "react-native-wifi-reborn": "^4.12.0",
    "react-native-crypto-js": "^1.0.0",
    "react-native-sqlite-storage": "^6.0.1",
    "react-native-async-storage": "^1.19.0"
  }
}
```

## 📚 BitChat Kod Analizi

### **1. BitChat Proje Yapısı İnceleme**
```bash
# BitChat projesini inceleme
cd /simple/bitchat-main/
tree -L 3
```

### **2. Temel Dosyalar Analizi**

#### **2.1 BitChatApp.swift (iOS)**
```swift
// BitChat/BitChatApp.swift - Ana uygulama entry point
import SwiftUI

@main
struct BitChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BluetoothManager())
                .environmentObject(MeshNetworkManager())
        }
    }
}
```

#### **2.2 BluetoothManager.swift**
```swift
// Bluetooth LE yönetimi - bu kodu Flutter/RN'e adapt edeceğiz
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    
    // Peer discovery
    func startScanning() { }
    func stopScanning() { }
    
    // Message handling
    func sendMessage(_ message: String) { }
    func broadcastMessage(_ message: String) { }
}
```

#### **2.3 MeshNetworkManager.swift**
```swift
// Mesh network logic - core routing algoritması
class MeshNetworkManager: ObservableObject {
    private var routingTable: [PeerID: RouteInfo] = [:]
    private var messageCache: MessageCache = MessageCache()
    
    // Message routing
    func routeMessage(_ message: Message) -> [PeerID] { }
    func forwardMessage(_ message: Message) { }
    
    // Store & Forward
    func storeMessage(_ message: Message) { }
    func forwardStoredMessages(to peer: PeerID) { }
}
```

### **3. Kilit Dosyaları Flutter'a Çevirme**

#### **3.1 main.dart (Flutter)**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/bluetooth_manager.dart';
import 'services/mesh_network_manager.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
        ChangeNotifierProvider(create: (_) => MeshNetworkManager()),
      ],
      child: MaterialApp(
        title: 'MESHNET',
        theme: ThemeData.dark(),
        home: ChatScreen(),
      ),
    );
  }
}
```

#### **3.2 bluetooth_manager.dart**
```dart
// lib/services/bluetooth_manager.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothManager extends ChangeNotifier {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> _devices = [];
  
  // BitChat'teki CBCentralManager functionality
  Future<void> startScanning() async {
    try {
      _bluetooth.startDiscovery().listen((device) {
        if (!_devices.contains(device.device)) {
          _devices.add(device.device);
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Bluetooth scanning error: $e');
    }
  }
  
  Future<void> stopScanning() async {
    await _bluetooth.cancelDiscovery();
  }
  
  // Message broadcasting - BitChat'teki gibi
  Future<void> broadcastMessage(String message) async {
    for (var device in _devices) {
      await _sendMessageToDevice(device, message);
    }
  }
  
  Future<void> _sendMessageToDevice(BluetoothDevice device, String message) async {
    // Implement message sending logic
  }
}
```

### **4. Proje Klasör Yapısı**

#### **4.1 Flutter Proje Yapısı**
```
meshnet_app/
├── android/                    # Android native code
├── ios/                       # iOS native code
├── lib/
│   ├── main.dart             # App entry point
│   ├── models/
│   │   ├── message.dart      # Message model
│   │   ├── peer.dart         # Peer model
│   │   └── channel.dart      # Channel model
│   ├── services/
│   │   ├── bluetooth_manager.dart
│   │   ├── mesh_network_manager.dart
│   │   ├── encryption_service.dart
│   │   └── storage_service.dart
│   ├── screens/
│   │   ├── chat_screen.dart
│   │   ├── channel_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/
│   │   ├── message_bubble.dart
│   │   ├── peer_list.dart
│   │   └── channel_list.dart
│   └── utils/
│       ├── constants.dart
│       ├── crypto_utils.dart
│       └── network_utils.dart
├── test/                     # Unit tests
├── pubspec.yaml             # Dependencies
└── README.md
```

### **5. BitChat'ten Çıkarılacak Temel Özellikler**

#### **5.1 Mesh Network Protokolü**
```dart
// lib/models/message.dart
class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final int hopCount;
  final List<String> routePath;
  final MessageType type;
  
  // BitChat'teki Message struct'ını Flutter'a çevirme
  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.hopCount = 0,
    this.routePath = const [],
    this.type = MessageType.text,
  });
  
  // Serialization - BitChat'teki binary protocol
  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'hopCount': hopCount,
    'routePath': routePath,
    'type': type.toString(),
  };
  
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      hopCount: json['hopCount'] ?? 0,
      routePath: List<String>.from(json['routePath'] ?? []),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

enum MessageType { text, image, file, emergency, system }
```

#### **5.2 Routing Algorithm**
```dart
// lib/services/mesh_network_manager.dart
class MeshNetworkManager extends ChangeNotifier {
  Map<String, RouteInfo> _routingTable = {};
  Map<String, Message> _messageCache = {};
  
  // BitChat'teki routing logic
  List<String> findRoute(String targetPeerId) {
    if (_routingTable.containsKey(targetPeerId)) {
      return _routingTable[targetPeerId]!.path;
    }
    
    // Dijkstra's algorithm for shortest path
    return _calculateShortestPath(targetPeerId);
  }
  
  List<String> _calculateShortestPath(String target) {
    // Implementation of shortest path algorithm
    // Based on BitChat's routing table
    return [];
  }
  
  // Store & Forward - BitChat'teki gibi
  void storeMessage(Message message) {
    _messageCache[message.id] = message;
    
    // Expire old messages
    _cleanupOldMessages();
  }
  
  void forwardStoredMessages(String peerId) {
    for (var message in _messageCache.values) {
      if (message.routePath.contains(peerId)) {
        _forwardMessage(message, peerId);
      }
    }
  }
}
```

## 🔐 Güvenlik Hazırlıkları

### **1. Encryption Setup**
```dart
// lib/services/encryption_service.dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  late final Encrypter _encrypter;
  late final IV _iv;
  
  // BitChat'teki X25519 + AES-256-GCM setup
  void initialize() {
    final key = Key.fromSecureRandom(32); // 256-bit key
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromSecureRandom(16);
  }
  
  String encryptMessage(String message) {
    final encrypted = _encrypter.encrypt(message, iv: _iv);
    return encrypted.base64;
  }
  
  String decryptMessage(String encryptedMessage) {
    final encrypted = Encrypted.fromBase64(encryptedMessage);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}
```

## 📝 Adım Adım Kurulum

### **Adım 1: Flutter Projesi Oluşturma**
```bash
# MESHNET klasöründe Flutter projesi oluşturma
cd /media/zinderud/sade/code/clone/acildurum/code/MESHNET
flutter create meshnet_app
cd meshnet_app
```

### **Adım 2: Dependencies Ekleme**
```bash
# pubspec.yaml'a dependencies ekledikten sonra
flutter pub get
```

### **Adım 3: Native Platform Ayarları**

#### **Android (android/app/src/main/AndroidManifest.xml)**
```xml
<!-- Bluetooth permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- WiFi permissions -->
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

#### **iOS (ios/Runner/Info.plist)**
```xml
<!-- Bluetooth permissions -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to communicate with nearby devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to communicate with nearby devices</string>

<!-- Location permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for emergency features</string>
```

### **Adım 4: Temel Kod Yapısı**
```bash
# Klasör yapısını oluşturma
mkdir -p lib/{models,services,screens,widgets,utils}

# Temel dosyaları oluşturma
touch lib/models/{message.dart,peer.dart,channel.dart}
touch lib/services/{bluetooth_manager.dart,mesh_network_manager.dart,encryption_service.dart}
touch lib/screens/{chat_screen.dart,channel_screen.dart,settings_screen.dart}
```

### **Adım 5: Git Repository Kurulumu**
```bash
# Git repository initialize
git init
git add .
git commit -m "Initial MESHNET project setup based on BitChat"

# Remote repository bağlantısı (gerekirse)
git remote add origin [repository-url]
git push -u origin main
```

## ✅ Bu Aşama Tamamlandığında

- [ ] **Flutter/React Native geliştirme ortamı kuruldu**
- [ ] **BitChat kodu analiz edildi ve anlaşıldı**
- [ ] **Temel proje yapısı oluşturuldu**
- [ ] **Native platform permissions ayarlandı**
- [ ] **Git repository kuruldu**
- [ ] **Temel model sınıfları oluşturuldu**
- [ ] **Service layer hazırlandı**

## 🔄 Sonraki Adım

**2. Adım:** `2-BLUETOOTH-MESH-IMPLEMENTASYON.md` dosyasını inceleyin ve Bluetooth LE mesh network implementasyonuna başlayın.

---

**Son Güncelleme:** 11 Temmuz 2025  
**Durum:** Kurulum Hazır
