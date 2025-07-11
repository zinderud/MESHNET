# MESHNET Proje Genel Bakış ve Planlama

## 📋 Proje Özeti

Bu proje, **BitChat** projesini temel alarak, acil durum durumları için geliştirilmiş bir mesh network iletişim sistemi geliştirmeyi hedeflemektedir. BitChat'in temel özelliklerini koruyarak, RTL-SDR/HackRF gibi external RF cihazları ile uzun mesafe iletişim yetenekleri eklenecektir.

## 🎯 BitChat'ten Farklılıklar

### BitChat'in Temel Özellikleri:
- ✅ Bluetooth Low Energy (BLE) mesh network
- ✅ WiFi Direct clustering
- ✅ End-to-end encryption (X25519 + AES-256-GCM)
- ✅ Store & Forward messaging
- ✅ IRC-style commands
- ✅ No servers, no phone numbers
- ✅ Emergency wipe functionality

### MESHNET'in Ek Özellikleri:
- 🆕 **RTL-SDR/HackRF entegrasyonu** (uzun mesafe iletişim)
- 🆕 **Ham radio protocol desteği** (APRS, Winlink)
- 🆕 **Emergency frequency monitoring**
- 🆕 **Multi-protocol yaklaşım**
- 🆕 **Satellite communication**
- 🆕 **Cognitive radio capabilities**

## 📁 Proje Dosya Yapısı

```
MESHNET/
├── 0-GENEL-BAKIS.md                    # Bu dosya
├── 1-TEMEL-KURULUM.md                  # Geliştirme ortamı kurulumu
├── 2-BLUETOOTH-MESH-IMPLEMENTASYON.md  # BLE mesh network
├── 3-WIFI-DIRECT-IMPLEMENTASYON.md     # WiFi Direct clustering
├── 4-SIFRELEME-GUVENLIGI.md           # Encryption & Security
├── 5-MESAJ-YONLENDIRME.md             # Message routing
├── 6-SDR-ENTEGRASYONU.md              # RTL-SDR/HackRF integration
├── 7-HAM-RADIO-PROTOKOLLERI.md        # Ham radio protocols
├── 8-ACIL-DURUM-OZELLIKLERI.md        # Emergency features
├── 9-KULLANICI-ARAYUZU.md             # User interface
├── 10-TEST-SIMULASYON.md              # Testing & simulation
├── 11-DERLEME-DEPLOY.md               # Build & deployment
└── 12-DOKUMANTASYON.md                # Final documentation
```

## 🔄 Geliştirme Aşamaları

### **Aşama 1: Temel Altyapı (Hafta 1-2)**
- [ ] Geliştirme ortamı kurulumu
- [ ] BitChat kodunu inceleme ve anlama
- [ ] Temel Flutter/React Native projesi oluşturma
- [ ] Native platform entegrasyonu hazırlıkları

### **Aşama 2: BLE Mesh Network (Hafta 3-4)**
- [ ] Bluetooth LE peripheral/central implementasyonu
- [ ] Device discovery ve pairing
- [ ] Mesh network topology
- [ ] Basic message routing

### **Aşama 3: WiFi Direct (Hafta 5-6)**
- [ ] WiFi Direct clustering
- [ ] High-bandwidth data transfer
- [ ] Cross-cluster bridging
- [ ] Load balancing

### **Aşama 4: Güvenlik ve Şifreleme (Hafta 7-8)**
- [ ] X25519 key exchange
- [ ] AES-256-GCM encryption
- [ ] Digital signatures (Ed25519)
- [ ] Message authentication

### **Aşama 5: Mesaj Yönlendirme (Hafta 9-10)**
- [ ] Store & Forward mechanism
- [ ] Priority-based routing
- [ ] Network topology optimization
- [ ] Congestion control

### **Aşama 6: SDR Entegrasyonu (Hafta 11-12)**
- [ ] RTL-SDR/HackRF driver integration
- [ ] Custom RF protocol implementation
- [ ] Long-range communication
- [ ] Frequency management

### **Aşama 7: Ham Radio Protokolleri (Hafta 13-14)**
- [ ] APRS integration
- [ ] Winlink protocol
- [ ] Digital modes (FT8, JS8)
- [ ] Emergency frequency monitoring

### **Aşama 8: Acil Durum Özellikleri (Hafta 15-16)**
- [ ] Emergency mode activation
- [ ] Location-based broadcasts
- [ ] Priority message handling
- [ ] Emergency wipe functionality

### **Aşama 9: Kullanıcı Arayüzü (Hafta 17-18)**
- [ ] IRC-style command interface
- [ ] Channel management
- [ ] User management
- [ ] Settings and configuration

### **Aşama 10: Test ve Simulasyon (Hafta 19-20)**
- [ ] Unit testing
- [ ] Integration testing
- [ ] Network simulation
- [ ] Performance testing

### **Aşama 11: Derleme ve Dağıtım (Hafta 21-22)**
- [ ] iOS build configuration
- [ ] Android build configuration
- [ ] App store deployment
- [ ] Alternative distribution

### **Aşama 12: Dokümantasyon (Hafta 23-24)**
- [ ] User manual
- [ ] Technical documentation
- [ ] API documentation
- [ ] Maintenance guide

## 🛠️ Teknoloji Yığını

### **Cross-Platform Framework:**
- **Flutter** (önerilen - native performance)
- **React Native** (alternatif - web teknolojileri)

### **Native Platform Entegrasyonu:**
- **iOS:** CoreBluetooth, MultipeerConnectivity, Network.framework
- **Android:** BluetoothLE, WiFi P2P, NDK for SDR

### **Kriptografi:**
- **Libsodium** (cross-platform crypto library)
- **Signal Protocol** (advanced messaging crypto)

### **Veri Depolama:**
- **SQLite** (embedded database)
- **ObjectBox** (NoSQL object database)

### **SDR Entegrasyonu:**
- **GNU Radio** (SDR framework)
- **SoapySDR** (hardware abstraction)
- **Native C++ libraries** (performance critical)

### **Ham Radio Protokolleri:**
- **APRS libraries** (packet radio)
- **Winlink gateway** (email over radio)
- **FT8/JS8 decoders** (weak signal modes)

## 📊 Başarı Kriterleri

### **Minimum Viable Product (MVP):**
- [ ] 10+ device BLE mesh network
- [ ] End-to-end encrypted messaging
- [ ] Store & Forward capability
- [ ] 6+ hour battery life
- [ ] Automatic network formation

### **Advanced Features:**
- [ ] 100+ device mesh network
- [ ] WiFi Direct clustering
- [ ] SDR integration (RTL-SDR)
- [ ] Ham radio protocols (APRS)
- [ ] Emergency frequency monitoring

### **Production Ready:**
- [ ] 1000+ device mega-mesh
- [ ] Professional SDR support (HackRF)
- [ ] Multi-protocol optimization
- [ ] Satellite communication
- [ ] Government/NGO partnerships

## 🔗 Referanslar

### **BitChat Proje Dosyaları:**
- `/simple/bitchat-main/README.md` - Genel bakış
- `/simple/bitchat-main/WHITEPAPER.md` - Teknik detaylar
- `/simple/bitchat-main/WIFI_DIRECT_PLAN.md` - WiFi Direct planı
- `/simple/bitchat-main/bitchat/` - Kaynak kod

### **Acil Durum Dokümantasyonu:**
- `/doc/MESH_NETWORK_DURUM_SENARYO.md` - Senaryo analizi
- `/MOBIL_ODAKLI_GELISTIRME_YOL_HARITASI.md` - Yol haritası

### **Stratejik Dokümantasyon:**
- `/doc/Stratejik Konular/` - Stratejik analizler
- `/doc/Algoritma_ve_Analiz/` - Algoritma detayları

## 🚀 Sonraki Adım

**1. Adım:** `1-TEMEL-KURULUM.md` dosyasını inceleyerek geliştirme ortamını kurun.

---

**Son Güncelleme:** 11 Temmuz 2025  
**Versiyon:** 1.0  
**Durum:** Proje Başlangıcı
