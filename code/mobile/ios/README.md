# iOS Uygulama Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin iOS uygulamasına özel geliştirmeleri içermektedir. Projenin genel mobil uygulama stratejisi için `code/mobile/README.md` ve `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgelerine başvurulmalıdır.

## Genel Yaklaşım

iOS uygulaması, Apple ekosisteminin sunduğu performans ve güvenlik avantajlarından tam olarak faydalanacak şekilde geliştirilecektir. Kullanıcı deneyimi, gizlilik ve sistem entegrasyonu temel önceliklerimizdir.

### Temel Prensipler

*   **Minimum iOS Desteği**: iOS 12.0 ve üzeri versiyonları destekleyerek geniş bir kullanıcı kitlesine ulaşılacaktır.
*   **Batarya Optimizasyonu**: iOS'un arka plan görev yönetimi (Background App Refresh, Background Tasks API) ve düşük güç modu adaptasyonu gibi mekanizmaları etkin bir şekilde kullanılacaktır. Ağ aktiviteleri batarya dostu olacak şekilde tasarlanacaktır.
*   **P2P Ağ Entegrasyonu**: MultipeerConnectivity ve Core Bluetooth gibi iOS'un yerel P2P yetenekleri, mesh network oluşturmak için kullanılacaktır. Ağ keşfi ve bağlantı yönetimi bu framework'ler üzerinden sağlanacaktır.
*   **Güvenlik ve Gizlilik**: Keychain Services, Secure Enclave ve App Transport Security (ATS) gibi yerel güvenlik özellikleri, uygulamanın ve kullanıcı verilerinin güvenliğini sağlamak için kullanılacaktır. Apple'ın katı gizlilik kurallarına tam uyum sağlanacaktır.
*   **Kullanıcı Deneyimi**: SwiftUI ile modern ve sezgisel bir arayüz tasarlanacaktır. Acil durum anında kolay kullanım için tek dokunuşla işlem yapma yetenekleri ve Haptic Feedback entegrasyonu öncelikli olacaktır.
*   **Çevrimdışı Yetenekler**: Core Data gibi yerel depolama çözümleriyle offline-first mimarisi desteklenecek, internet bağlantısı olmasa bile mesajlaşma ve ağ içi iletişim sağlanacaktır.

## Teknik Implementasyon Detayları

### Mimari

*   **VIPER / MVVM**: Temiz kod, test edilebilirlik ve sürdürülebilirlik için benimsenecektir.
*   **Combine Framework**: Asenkron ve olay tabanlı programlama için kullanılacaktır.

### Ağ Katmanı

*   **MultipeerConnectivity**: Cihazlar arası doğrudan bağlantı ve oturum yönetimi için kullanılacaktır.
*   **Core Bluetooth**: Düşük enerji tüketimli mesh network keşfi ve temel mesajlaşma için kullanılacaktır.
*   **Network.framework**: Düşük seviyeli ağ iletişimi ve özel mesh protokolleri için gerekirse kullanılacaktır.
*   **Bonjour/mDNS**: Yerel ağdaki diğer mesh node'larını keşfetmek için kullanılacaktır.

### Veri Yönetimi

*   **Core Data**: Uygulama içi mesaj geçmişi, ağ topolojisi, eş bilgileri ve kullanıcı profilleri gibi verilerin kalıcı olarak depolanması için kullanılacaktır. CloudKit entegrasyonu ile veri senkronizasyonu sağlanabilir.
*   **UserDefaults / Keychain Services**: Kullanıcı tercihleri ve hassas yapılandırma verileri için kullanılacaktır.

### Güvenlik

*   **Keychain Services**: Kriptografik anahtarların ve hassas verilerin güvenli bir şekilde saklanması için kullanılacaktır.
*   **Secure Enclave**: Donanım tabanlı anahtar depolama ve kriptografik işlemler için kullanılacaktır.
*   **Biometric Authentication (Touch ID/Face ID)**: Biyometrik kimlik doğrulama için kullanılacaktır.
*   **App Transport Security (ATS)**: Uygulamanın ağ iletişim güvenliğini sağlamak için kullanılacaktır.

### Performans Optimizasyonu

*   **Arka Plan İşlemleri**: Background App Refresh, Background Tasks API ve Silent Push Notifications ile batarya dostu arka plan görevleri yönetilecektir.
*   **Bellek Yönetimi**: ARC (Automatic Reference Counting) optimizasyonu, zayıf referanslar ve bellek sızıntısı önleme teknikleri uygulanacaktır.
*   **CPU Optimizasyonu**: Grand Central Dispatch (GCD) ve Combine ile çoklu iş parçacığı yönetimi sağlanacaktır.

## Geliştirmeye Başlarken

iOS geliştirme sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/ios_gelistirme.md` belgesini detaylıca incelemeniz önerilir. Bu belge, iOS platformuna özel teknik yaklaşımları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel mobil uygulama geliştirme stratejileri ve prensipleri için `code/mobile/README.md` ve `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgelerine başvurmayı unutmayın.
