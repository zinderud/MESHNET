# 🇹🇷 Acil Durum Cep Telefonu Mesh Network
# 🇬🇧 Emergency Mobile Phone Mesh Network

## 🎯 Proje Vizyonu / Project Vision

**🇹🇷 Vizyon:** "Baz istasyonlarının çöktüğü acil durumlarda, cep telefonlarının otomatik mesh network kurarak hayat kurtaran iletişim sağlaması."

**🇬🇧 Vision:** "In emergencies where base stations collapse, mobile phones automatically establish a mesh network to provide life-saving communication."

---

## ✨ Temel Özellikler / Key Features

*   **🇹🇷 Altyapı Bağımsız İletişim:** Merkezi altyapıya (baz istasyonları, internet) bağımlı olmadan iletişim kurabilme.
    *   **🇬🇧 Infrastructure-Independent Communication:** Ability to communicate without relying on centralized infrastructure (base stations, internet).
*   **🇹🇷 Otomatik Ağ Kurulumu:** Kullanıcı müdahalesi olmadan cihazların kendi kendine bir mesh ağı oluşturması.
    *   **🇬🇧 Automatic Network Formation:** Devices automatically form a mesh network without user intervention.
*   **🇹🇷 Mesajlaşma ve Konum Paylaşımı:** Afet anında temel iletişim (metin mesajları, GPS konumları) sağlayabilme.
    *   **🇬🇧 Messaging & Location Sharing:** Providing essential communication (text messages, GPS locations) during disasters.
*   **🇹🇷 Çok Katmanlı Failover (Cascading Network):** İletişim kanallarının kademeli olarak yedeklenmesi (Cellular/WiFi > Yerel Mesh > Genişletilmiş Donanım).
    *   **🇬🇧 Multi-Layer Failover (Cascading Network):** Gradual fallback of communication channels (Cellular/WiFi > Local Mesh > Extended Hardware).
*   **🇹🇷 Hibrit RF Yaklaşımı:** Bluetooth LE, Wi-Fi Direct, SDR, LoRa ve Ham Radio gibi farklı radyo frekans teknolojilerinin entegrasyonu.
    *   **🇬🇧 Hybrid RF Approach:** Integration of various radio frequency technologies such as Bluetooth LE, Wi-Fi Direct, SDR, LoRa, and Ham Radio.
*   **🇹🇷 Blockchain Tabanlı Güvenlik ve Doğrulama:** Mesaj bütünlüğü, kimlik doğrulama ve ağ güvenliği için hafif bir blockchain (ePoA) kullanımı.
    *   **🇬🇧 Blockchain-Based Security & Verification:** Utilizing a lightweight blockchain (ePoA) for message integrity, authentication, and network security.
*   **🇹🇷 Yapay Zeka Destekli Spektrum Yönetimi (Cognitive Radio):** Spektrumun dinamik olarak algılanması, analiz edilmesi ve optimize edilmesi.
    *   **🇬🇧 AI-Powered Spectrum Management (Cognitive Radio):** Dynamically sensing, analyzing, and optimizing the spectrum.
*   **🇹🇷 Acil Durum Protokolü Sömürüsü (ELS):** 112/911 acil çağrı kanallarının Enhanced Location Service (ELS) özelliğini kullanarak mesh sinyalleşmesi.
    *   **🇬🇧 Emergency Protocol Exploitation (ELS):** Utilizing the Enhanced Location Service (ELS) feature of 112/911 emergency call channels for mesh signaling.
*   **🇹🇷 Carrier WiFi Köprüleme:** Mevcut operatör WiFi hotspot'larını kullanarak mesh ağını internete bağlama.
    *   **🇬🇧 Carrier WiFi Bridging:** Connecting the mesh network to the internet using existing carrier WiFi hotspots.

---

## 🏗️ Teknik Mimari / Technical Architecture

### 🇹🇷 Katmanlı Yaklaşım (Cascading Network) / 🇬🇧 Layered Approach (Cascading Network)

Proje, iletişim sürekliliğini sağlamak için çok katmanlı bir yedekleme stratejisi benimser:
The project adopts a multi-layered fallback strategy to ensure communication continuity:

*   **🇹🇷 Katman 1: Altyapı (Infrastructure):** Cellular ağlar, mevcut WiFi altyapısı ve uydu/acil durum servisleri (varsa).
    *   **🇬🇧 Layer 1: Infrastructure:** Cellular networks, existing WiFi infrastructure, and satellite/emergency services (if available).
*   **🇹🇷 Katman 2: Yerel Mesh (Local Mesh):** WiFi Direct kümeleri, Bluetooth LE mesh ve NFC röle zincirleri ile cihazdan cihaza iletişim.
    *   **🇬🇧 Layer 2: Local Mesh:** Device-to-device communication via WiFi Direct clusters, Bluetooth LE mesh, and NFC relay chains.
*   **🇹🇷 Katman 3: Genişletilmiş Donanım (Extended Hardware):** SDR dongle'lar, LoRa modülleri, Ham Radio ve Zigbee entegrasyonu gibi özel donanımlar aracılığıyla uzun menzilli ve düşük güçlü iletişim.
    *   **🇬🇧 Layer 3: Extended Hardware:** Long-range and low-power communication through specialized hardware like SDR dongles, LoRa modules, Ham Radio, and Zigbee integration.

### 🇹🇷 Çekirdek Teknolojiler / Core Technologies

*   **🇹🇷 P2P Ağ (Peer-to-Peer Network):** Dağıtık Hash Tabloları (DHT) ve akıllı eş seçimi algoritmaları ile merkezi olmayan cihaz keşfi ve yönlendirme.
    *   **🇬🇧 P2P Network:** Decentralized device discovery and routing with Distributed Hash Tables (DHT) and intelligent peer selection algorithms.
*   **🇹🇷 Blockchain:** Emergency Proof of Authority (ePoA) konsensüs mekanizması ve dağıtık mesaj doğrulama sistemi ile güvenli ve değişmez iletişim kayıtları.
    *   **🇬🇧 Blockchain:** Secure and immutable communication records with Emergency Proof of Authority (ePoA) consensus mechanism and distributed message verification system.
*   **🇹🇷 Kriptografi:** Uçtan uca şifreleme, dijital imzalar ve post-quantum kriptografiye hazırlık ile güçlü güvenlik.
    *   **🇬🇧 Cryptography:** Strong security with end-to-end encryption, digital signatures, and readiness for post-quantum cryptography.
*   **🇹🇷 Veri Depolama:** IPFS benzeri içerik adresli depolama ve dağıtık önbellekleme stratejileri ile çevrimdışı ve dayanıklı veri yönetimi.
    *   **🇬🇧 Data Storage:** Offline and resilient data management with IPFS-like content-addressable storage and distributed caching strategies.

### 🇹🇷 Stratejik Yaklaşımlar / Strategic Approaches

*   **🇹🇷 Hibrit Network Yaklaşımı:** WiFi Direct ve Bluetooth LE'nin avantajlarını birleştirerek hem yüksek bant genişliği hem de düşük güç tüketimi sağlama.
    *   **🇬🇧 Hybrid Network Approach:** Combining the advantages of WiFi Direct and Bluetooth LE for both high bandwidth and low power consumption.
*   **🇹🇷 SDR Entegrasyonu:** Gelişmiş kullanıcılar için genişletilmiş frekans desteği ve esneklik sağlamak amacıyla Yazılım Tanımlı Radyo (SDR) donanımlarının entegrasyonu.
    *   **🇬🇧 SDR Integration:** Integration of Software Defined Radio (SDR) hardware to provide extended frequency support and flexibility for advanced users.
*   **🇹🇷 Carrier WiFi Bridge:** Operatör WiFi hotspot'larını kullanarak mesh ağını internete bağlama ve şehir çapında kapsama alanı genişletme.
    *   **🇬🇧 Carrier WiFi Bridge:** Utilizing carrier WiFi hotspots to connect the mesh network to the internet and extend city-wide coverage.
*   **🇹🇷 Emergency Protocol Exploitation:** Acil çağrı kanallarının (112/911) ELS özelliğini kullanarak gizli mesh sinyalleşmesi.
    *   **🇬🇧 Emergency Protocol Exploitation:** Covert mesh signaling using the ELS feature of emergency call channels (112/911).
*   **🇹🇷 Cognitive Radio Implementation:** Yapay zeka destekli akıllı spektrum yönetimi ile ağ performansını ve dayanıklılığını artırma.
    *   **🇬🇧 Cognitive Radio Implementation:** Enhancing network performance and resilience through AI-powered intelligent spectrum management.

---

## 🎭 Kullanım Senaryoları ve Simülasyonlar / Use Cases & Simulations

Proje, çeşitli acil durum senaryolarında iletişim sürekliliğini sağlamak üzere tasarlanmıştır:
The project is designed to ensure communication continuity in various emergency scenarios:

*   **🇹🇷 Doğal Afetler:** Deprem, sel, orman yangınları gibi durumlarda baz istasyonlarının çökmesi.
    *   **🇬🇧 Natural Disasters:** Collapse of base stations during events like earthquakes, floods, and wildfires.
*   **🇹🇷 İnsan Kaynaklı Krizler:** Terör saldırıları veya siber saldırılar sonucu iletişim altyapısının kasıtlı olarak kesilmesi.
    *   **🇬🇧 Human-Made Crises:** Deliberate disruption of communication infrastructure due to terrorist attacks or cyberattacks.
*   **🇹🇷 Altyapı Arızaları:** Geniş çaplı elektrik kesintileri veya internet omurga arızaları.
    *   **🇬🇧 Infrastructure Failures:** Widespread power outages or internet backbone failures.

### 🇹🇷 Detaylı İstanbul Deprem Senaryosu Simülasyonu / 🇬🇧 Detailed Istanbul Earthquake Scenario Simulation

Proje, 7.2 büyüklüğündeki bir İstanbul depremi sonrası ilk 72 saati kapsayan detaylı bir simülasyon senaryosu ile test edilmiştir. Bu senaryo, farklı donanım profillerine sahip kullanıcıların (Temel Kullanıcılar, WiFi Hotspot Destekleyiciler, SDR Meraklıları, IoT/Zigbee Ağ Sahipleri) ağa nasıl katkıda bulunduğunu ve ağın zaman içinde nasıl evrildiğini göstermektedir.
The project has been tested with a detailed simulation scenario covering the first 72 hours after a 7.2 magnitude Istanbul earthquake. This scenario demonstrates how users with different hardware profiles (Basic Users, WiFi Hotspot Supporters, SDR Enthusiasts, IoT/Zigbee Network Owners) contribute to the network and how the network evolves over time.

---

## 🛠️ Geliştirme ve Uygulama / Development & Implementation

### 🇹🇷 Metodoloji / Methodology

Proje, çevik (Agile) metodolojiler (Scrum) kullanılarak geliştirilmektedir. Test Odaklı Geliştirme (TDD) ve Sürekli Entegrasyon/Sürekli Dağıtım (CI/CD) süreçleri, yazılım kalitesini ve hızlı yinelemeyi sağlamak için benimsenmiştir.
The project is being developed using Agile methodologies (Scrum). Test-Driven Development (TDD) and Continuous Integration/Continuous Deployment (CI/CD) processes are adopted to ensure software quality and rapid iteration.

### 🇹🇷 Platform Desteği / Platform Support

*   **🇹🇷 Mobil:** Android ve iOS için yerel (Native) uygulamalar geliştirilmektedir. Flutter veya React Native gibi çapraz platform çözümleri, kod tekrarını azaltmak için değerlendirilmektedir.
    *   **🇬🇧 Mobile:** Native applications are being developed for Android and iOS. Cross-platform solutions like Flutter or React Native are being evaluated to reduce code duplication.
*   **🇹🇷 Masaüstü:** Electron, .NET MAUI veya Qt gibi çerçeveler kullanılarak masaüstü istemcileri (Windows, macOS, Linux) entegrasyonu planlanmaktadır.
    *   **🇬🇧 Desktop:** Desktop client integration (Windows, macOS, Linux) is planned using frameworks like Electron, .NET MAUI, or Qt.
*   **🇹🇷 PWA:** Çevrimdışı yeteneklere sahip Progresif Web Uygulamaları (PWA) bir yedekleme çözümü olarak değerlendirilmektedir.
    *   **🇬🇧 PWA:** Progressive Web Apps (PWA) with offline capabilities are being considered as a fallback solution.
*   **🇹🇷 Arka Uç (Backend):** Mikroservis mimarisi, Kubernetes tabanlı konteynerizasyon ve dağıtık veritabanları (örneğin, Apache Cassandra, Redis) kullanılarak ölçeklenebilir ve dayanıklı arka uç servisleri oluşturulmaktadır.
    *   **🇬🇧 Backend:** Scalable and resilient backend services are being built using a microservices architecture, Kubernetes-based containerization, and distributed databases (e.g., Apache Cassandra, Redis).

---

## 🔒 Güvenlik ve Etik / Security & Ethics

### 🇹🇷 Güvenlik / Security

*   **🇹🇷 Çok Katmanlı Güvenlik:** Cihazdan uygulamaya, ağdan protokole kadar her katmanda güvenlik önlemleri.
    *   **🇬🇧 Multi-Layer Security:** Security measures at every layer, from device to application, network to protocol.
*   **🇹🇷 Zero-Trust Mimarisi:** "Asla güvenme, her zaman doğrula" prensibiyle sürekli kimlik doğrulama ve yetkilendirme.
   *   **🇬🇧 Zero-Trust Architecture:** Continuous authentication and authorization based on the principle of "never trust, always verify."
*   **🇹🇷 Uçtan Uca Şifreleme:** Tüm mesajlar için Signal Protokolü benzeri uçtan uca şifreleme (ChaCha20-Poly1305, X25519, Ed25519).
   *   **🇬🇧 End-to-End Encryption:** Signal Protocol-like end-to-end encryption (ChaCha20-Poly1305, X25519, Ed25519) for all messages.
 
*   **🇹🇷 Anti-Jamming ve Sybil Saldırısı Önleme:** Frekans atlama, davranış analizi ve itibar sistemleri ile ağ saldırılarına karşı dayanıklılık.
   *   **🇬🇧 Anti-Jamming & Sybil Attack Prevention:** Network resilience against attacks through frequency hopping, behavioral analysis, and reputation systems.

### 🇹🇷 Etik / Ethics

*   **🇹🇷 Hayat Kurtarma Önceliği:** Tüm kararlarda insan hayatının korunması en üst önceliktir.
   *   **🇬🇧 Life-Saving Priority:** The protection of human life is the highest priority in all decisions.
*   **🇹🇷 Yasal Uyumluluk:** Ulusal ve uluslararası acil durum kanunlarına, frekans düzenlemelerine ve veri koruma yasalarına (GDPR/KVKK) tam uyum.
   *   **🇬🇧 Legal Compliance:** Full compliance with national and international emergency laws, frequency regulations, and data protection laws (GDPR/KVKK).
*   **🇹🇷 Şeffaflık ve Kötüye Kullanım Önleme:** Acil servislerle şeffaf iletişim, gerçek acil durum tespiti ve kötüye kullanımın önlenmesi için mekanizmalar.
   *   **🇬🇧 Transparency & Abuse Prevention:** Transparent communication with emergency services, real emergency detection, and mechanisms to prevent misuse.
*   **🇹🇷 Gizlilik Koruması:** Konum anonimleştirme, veri minimizasyonu ve kullanıcı kontrolü ile gizliliğin korunması.
   *   **🇬🇧 Privacy Protection:** Protecting privacy through location anonymization, data minimization, and user control.

---

## 📊 Performans ve Optimizasyon / Performance & Optimization

*   **🇹🇷 Adaptif Yönlendirme ve Mesaj Önceliklendirme:** Ağ koşullarına ve mesajın aciliyetine göre dinamik rota seçimi ve önceliklendirme.
   *   **🇬🇧 Adaptive Routing & Message Prioritization:** Dynamic route selection and prioritization based on network conditions and message urgency.
*   **🇹🇷 Bant Genişliği ve Güç Yönetimi:** Kaynakları verimli kullanmak için akıllı bant genişliği tahsisi ve pil ömrü optimizasyonu.
   *   **🇬🇧 Bandwidth & Power Management:** Intelligent bandwidth allocation and battery life optimization for efficient resource utilization.
*   **🇹🇷 Gerçek Zamanlı Analiz ve Yapay Zeka Destekli Optimizasyon:** Ağ sağlığını sürekli izleme ve yapay zeka algoritmalarıyla performansı otomatik olarak iyileştirme.
   *   **🇬🇧 Real-time Analytics & AI-Powered Optimization:** Continuously monitoring network health and automatically improving performance with AI algorithms.

### 🇹🇷 Temel Performans Göstergeleri (KPI'lar) / 🇬🇧 Key Performance Indicators (KPIs)

*   **🇹🇷 Mesaj İletim Başarı Oranı:** Hedef %95+ güvenilirlik.
   *   **🇬🇧 Message Delivery Success Rate:** Target 95%+ reliability.
*   **🇹🇷 Ortalama Gecikme:** Yerel mesajlar için <5 saniye.
   *   **🇬🇧 Average Latency:** <5 seconds for local messages.
*   **🇹🇷 Pil Ömrü:** Hibrit modda 6-12 saat sürekli çalışma.
   *   **🇬🇧 Battery Life:** 6-12 hours of continuous operation in hybrid mode.
*   **🇹🇷 Ağ Kapsama Alanı:** Node başına 500m-5km yarıçap.
   *   **🇬🇧 Network Coverage Area:** 500m-5km radius per node.

---

## 🗺️ Yol Haritası / Roadmap

### 🇹🇷 Faz 1: Temel Altyapı (Tamamlandı) / 🇬🇧 Phase 1: Core Infrastructure (Completed)

*   **🇹🇷 Temel Hibrit Mesh:** WiFi Direct ve Bluetooth LE entegrasyonu.
   *   **🇬🇧 Basic Hybrid Mesh:** WiFi Direct and Bluetooth LE integration.
*   **🇹🇷 Otomatik Keşif:** Tak ve çalıştır deneyimi.
   *   **🇬🇧 Automatic Discovery:** Plug-and-play experience.
*   **🇹🇷 Temel Güvenlik:** Uçtan uca şifreleme.
   *   **🇬🇧 Basic Security:** End-to-end encryption.

### 🇹🇷 Faz 2: Gelişmiş Özellikler (Devam Ediyor) / 🇬🇧 Phase 2: Advanced Features (Ongoing)

*   **🇹🇷 Carrier WiFi Entegrasyonu:** Operatör hotspot kullanımı.
   *   **🇬🇧 Carrier WiFi Integration:** Utilization of carrier hotspots.
*   **🇹🇷 Acil Durum Protokolü:** Acil çağrı kanalı kullanımı.
   *   **🇬🇧 Emergency Protocol:** Use of emergency call channels.
*   **🇹🇷 Gelişmiş Kullanıcı Arayüzü:** Kullanıcı tipi bazlı arayüzler.
   *   **🇬🇧 Advanced User Interface:** User-type based interfaces.
*   **🇹🇷 Blockchain Entegrasyonu:** ePoA ve dağıtık doğrulama.
   *   **🇬🇧 Blockchain Integration:** ePoA and distributed verification.

### 🇹🇷 Faz 3: Üretim Dağıtımı (Planlandı) / 🇬🇧 Phase 3: Production Deployment (Planned)

*   **🇹🇷 SDR Geliştirmesi:** Gelişmiş kullanıcılar için frekans genişletme.
   *   **🇬🇧 SDR Enhancement:** Frequency extension for advanced users.
*   **🇹🇷 Yapay Zeka Optimizasyonu:** Makine öğrenmesi ile ağ optimizasyonu.
   *   **🇬🇧 AI Optimization:** Network optimization with machine learning.
*   **🇹🇷 IoT Entegrasyonu:** Akıllı şehir sistemleri entegrasyonu.
   *   **🇬🇧 IoT Integration:** Smart city systems integration.
*   **🇹🇷 Küresel Dağıtım:** Uluslararası acil durum kuruluşlarıyla işbirliği.
   *   **🇬🇧 Global Deployment:** Collaboration with international emergency organizations.

---

## 📞 İletişim / Contact

*   **🇹🇷 Proje Yöneticisi:** acildurum-pm@example.com
   *   **🇬🇧 Project Manager:** acildurum-pm@example.com
*   **🇹🇷 Teknik Lider:** acildurum-tech@example.com
   *   **🇬🇧 Technical Lead:** acildurum-tech@example.com
*   **🇹🇷 Güvenlik Uzmanı:** acildurum-security@example.com
   *   **🇬🇧 Security Specialist:** acildurum-security@example.com
*   **🇹🇷 Topluluk Yöneticisi:** acildurum-community@example.com
   *   **🇬🇧 Community Manager:** acildurum-community@example.com
