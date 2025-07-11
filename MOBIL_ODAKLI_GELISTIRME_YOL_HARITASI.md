# Mobil Odaklı Geliştirme Yol Haritası

Bu döküman, `acildurum` projesinin mobil uygulama geliştirme sürecini, `bitchat-main` proBu yol haritası, BitChat projesini temel alarak projenin hedeflerine ulaşması için esnek ve modüler bir çerçeve sunar. Her fazın sonunda yapılacak değerlendirmelerle, sonraki adımlar revise edilebilir.

## 🚀 Hızlı Başlangıç

### **Adım 1: Proje Yapısını İnceleme**
```bash
# BitChat kaynak kodunu inceleme
cd /simple/bitchat-main/
ls -la bitchat/

# MESHNET implementasyon adımlarını inceleme
cd /code/MESHNET/
ls -la *.md
```

### **Adım 2: Geliştirme Ortamını Kurma**
```bash
# 1. Adım dosyasını takip etme
cat 1-TEMEL-KURULUM.md

# Flutter projesi oluşturma
flutter create meshnet_app
cd meshnet_app
```

### **Adım 3: BitChat Özelliklerini Implement Etme**
```bash
# Her adımı sırasıyla takip etme
# 2-BLUETOOTH-MESH-IMPLEMENTASYON.md
# 3-WIFI-DIRECT-IMPLEMENTASYON.md
# 4-SIFRELEME-GUVENLIGI.md
# vs...
```

### **Temel Fark - BitChat vs MESHNET:**
- **BitChat:** Sadece Bluetooth LE + WiFi Direct (kısa mesafe)
- **MESHNET:** Bluetooth LE + WiFi Direct + RTL-SDR/HackRF (uzun mesafe)
- **BitChat:** Lokal iletişim odaklı
- **MESHNET:** Acil durum ve geniş alan iletişim odaklı

Bu yaklaşım, BitChat'in kanıtlanmış mesh network algoritmasını kullanarak, acil durum iletişimi için kritik olan uzun mesafe yeteneklerini ekler.esinden ve `offlineprotocol.com` vizyonundan ilham alarak detaylandırmaktadır. Amaç, internetsiz ortamlarda çalışabilen, güvenli ve merkeziyetsiz bir iletişim platformu oluşturmaktır.

## 1. Vizyon ve Temel Prensipler

- **Çevrimdışı Öncelikli (Offline-First):** Uygulama, internet bağlantısı olmadan tüm temel işlevlerini yerine getirebilmelidir.
- **Merkeziyetsiz ve Sunucusuz:** İletişim, merkezi bir sunucuya veya otoriteye bağlı olmamalıdır.
- **Güvenlik ve Gizlilik:** Tüm iletişim uçtan uca şifrelenmeli, kullanıcı kimlikleri anonim kalabilmelidir.
- **Dayanıklılık (Resilience):** Ağ, düğümlerin (kullanıcıların) katılması veya ayrılmasıyla dinamik olarak kendini onarabilmelidir.
- **Platformlar Arası Destek:** Geliştirme, başlangıçta iOS ve Android'e odaklanacak, gelecekte ise masaüstü platformları da kapsayabilecektir.

## 2. Geliştirme Fazları

Geliştirme süreci, BitChat projesini temel alarak modüler ve aşamalı bir yaklaşımla ele alınacaktır. Detaylı implementasyon adımları `/code/MESHNET/` klasöründe bulunmaktadır.

### **📁 Detaylı Implementasyon Dosyaları:**
- `0-GENEL-BAKIS.md` - Proje genel bakış ve planlama
- `1-TEMEL-KURULUM.md` - Geliştirme ortamı kurulumu
- `2-BLUETOOTH-MESH-IMPLEMENTASYON.md` - BLE mesh network
- `3-WIFI-DIRECT-IMPLEMENTASYON.md` - WiFi Direct clustering
- `4-SIFRELEME-GUVENLIGI.md` - Encryption & Security
- `5-MESAJ-YONLENDIRME.md` - Message routing
- `6-SDR-ENTEGRASYONU.md` - RTL-SDR/HackRF integration
- `7-HAM-RADIO-PROTOKOLLERI.md` - Ham radio protocols
- `8-ACIL-DURUM-OZELLIKLERI.md` - Emergency features
- `9-KULLANICI-ARAYUZU.md` - User interface
- `10-TEST-SIMULASYON.md` - Testing & simulation
- `11-DERLEME-DEPLOY.md` - Build & deployment
- `12-DOKUMANTASYON.md` - Final documentation

### Faz 1: Çekirdek Ağ ve Mesajlaşma (MVP) - Hafta 1-4

**BitChat'ten Alınan Temel Özellikler:**
- **Bluetooth LE Mesh Network:** BitChat'teki CBCentralManager/CBPeripheralManager yapısını Flutter'da implement etme
- **Otomatik Cihaz Keşfi:** BitChat'teki peer discovery algoritmasını kullanma
- **Store & Forward:** BitChat'teki message caching ve delivery sistemini adapte etme
- **Temel Şifreleme:** X25519 key exchange + AES-256-GCM (BitChat'teki gibi)

**Teknoloji Seçimi:**
- **Ağ Protokolü:** Bluetooth Low Energy (BLE) ve Wi-Fi Direct kullanılacak
- **Platform:** Flutter (native performance için önerilen)
- **Kriptografi:** Libsodium (BitChat'teki gibi)

**Özellikler:**
- **Cihaz Keşfi ve Bağlantı:** BitChat'teki otomatik eşleşme algoritması
- **Genel Sohbet (Public Chat):** BitChat'teki ana özellik - şifresiz genel kanal
- **Geçici Takma Ad (Nickname):** BitChat'teki gibi kalıcı kimlik gerektirmez
- **Mesaj Yayını (Broadcasting):** BitChat'teki multi-hop routing
- **Veri Saklama ve İletme:** BitChat'teki store & forward mekanizması

### Faz 2: Güvenli Kanallar ve Gelişmiş Özellikler - Hafta 5-8

**BitChat'ten Alınan Güvenlik Özellikleri:**
- **IRC-Style Commands:** BitChat'teki `/j #kanal`, `/m @kullanici` komutları
- **Channel Management:** BitChat'teki channel ownership ve password protection
- **Emergency Wipe:** BitChat'teki triple-tap data wipe özelliği
- **Message Retention:** BitChat'teki optional message saving

**Özellikler:**
- **Özel Kanallar:** BitChat'teki `/j #kanal_adi` komut sistemi
- **Uçtan Uca Şifreleme:**
  - **Özel Mesajlar:** BitChat'teki X25519 + AES-256-GCM implementasyonu
  - **Kanallar:** BitChat'teki Argon2id + AES-256-GCM kanal şifrelemesi
- **Kullanıcı Engelleme:** BitChat'teki `/block @kullanici` sistemi
- **Acil Durum Veri Silme:** BitChat'teki emergency wipe mekanizması

### Faz 3: BitChat'ten Farklı - SDR ve RF Entegrasyonu - Hafta 9-12

**BitChat'ten Farklı Özellikler (Ana Fark):**
- **RTL-SDR/HackRF Entegrasyonu:** BitChat'te yok - uzun mesafe iletişim
- **Ham Radio Protokolleri:** APRS, Winlink, FT8 desteği
- **Emergency Frequency Monitoring:** Polis, itfaiye, EMS frequency'leri
- **Multi-Protocol Yaklaşım:** Bluetooth + WiFi + RF kombinasyonu

**Özellikler:**
- **Çevrimdışı Kimlik (OfflineID):** `offlineprotocol.com` esinlenmesi
- **RTL-SDR Entegrasyonu:** GNU Radio ile 25MHz-1.7GHz monitoring
- **HackRF Entegrasyonu:** 1MHz-6GHz TX/RX capability
- **Ham Radio Protocols:** APRS packet radio, Winlink email-over-radio
- **Emergency Frequency Access:** Police/Fire/EMS monitoring
- **Satellite Communication:** LEO/GEO satellite access

### Faz 4: Test, Dağıtım ve Bakım - Hafta 13-16

**BitChat'ten Alınan Test Stratejileri:**
- **Mesh Network Testing:** BitChat'teki multi-hop test scenarios
- **Security Testing:** BitChat'teki encryption validation
- **Performance Testing:** BitChat'teki battery optimization tests

**Test Stratejileri:**
- **Simülasyon Testleri:** BitChat'teki mesh topology simulation
- **Saha Testleri:** BitChat'teki real-world performance testing
- **Güvenlik Testleri:** BitChat'teki external security audits
- **SDR Integration Tests:** BitChat'te olmayan - RF protocol testing

**Dağıtım:**
- **App Store/Google Play:** BitChat'teki gibi mainstream deployment
- **F-Droid/APK:** BitChat'teki gibi alternative distribution
- **Ham Radio Community:** BitChat'te yok - emergency operator distribution

## 3. Teknoloji Yığını (BitChat Tabanlı)

### **BitChat'ten Alınan Teknolojiler:**
- **Kriptografi:** X25519 key exchange + AES-256-GCM + Ed25519 signatures
- **Mesh Protokolü:** Custom binary protocol over Bluetooth LE
- **Veri Formatı:** JSON message serialization
- **Platform APIs:** CoreBluetooth (iOS), BluetoothLE (Android)

### **MESHNET Ek Teknolojileri:**
- **SDR Framework:** GNU Radio + SoapySDR
- **RF Hardware:** RTL-SDR, HackRF One, BladeRF
- **Ham Radio:** APRS, Winlink, FT8 protocol stacks
- **Satellite:** LEO/GEO communication protocols

### **Implementasyon Teknolojileri:**
- **Cross-Platform Framework:** Flutter (BitChat Swift kodu adapte edilecek)
- **Ağ İletişimi (Native Modüller):**
    - **iOS:** CoreBluetooth, MultipeerConnectivity (BitChat'teki gibi)
    - **Android:** BluetoothLE, Wi-Fi P2P
    - **SDR:** GNU Radio C++ bindings via FFI
- **Kriptografi Kütüphaneleri:** Libsodium (BitChat'teki gibi) / Signal Protocol
- **Veri Depolama:** SQLite (BitChat'teki gibi) / ObjectBox
- **Proje Yönetimi:** Flutter build system + native platform configurations

### **BitChat'ten Farklı Ek Teknolojiler:**
- **SDR Software:** GNU Radio, SDR#, CubicSDR
- **RF Protocols:** GFSK, FSK, APRS, Winlink
- **Ham Radio Software:** WSJT-X, fldigi, Pat Winlink
- **Satellite Software:** Gpredict, SatPC32

Bu yol haritası, projenin hedeflerine ulaşması için esnek ve modüler bir çerçeve sunar. Her fazın sonunda yapılacak değerlendirmelerle, sonraki adımlar revize edilebilir.