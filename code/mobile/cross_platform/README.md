# Çapraz Platform Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin Android ve iOS platformları arasında paylaşılan kod tabanı ve çapraz platform stratejilerini içermektedir. Projenin genel mobil uygulama stratejisi için `code/mobile/README.md` ve `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgelerine başvurulmalıdır.

## Genel Yaklaşım

Çapraz platform geliştirme, kod tekrarını azaltmak, geliştirme hızını artırmak ve platformlar arası özellik tutarlılığını sağlamak amacıyla kullanılacaktır. Özellikle iş mantığı, veri modelleri ve ağ protokolleri gibi çekirdek bileşenler çapraz platform olarak geliştirilecektir.

### Temel Prensipler

*   **Tek Kod Tabanı (Core Logic)**: Mesaj yönlendirme algoritmaları, şifreleme/şifre çözme mantığı, öncelik kuyruğu yönetimi ve ağ topolojisi algoritmaları gibi çekirdek iş mantığı, platformdan bağımsız olarak tek bir kod tabanında geliştirilecektir.
*   **Yerel Entegrasyon (Native Bridge)**: Performans kritik veya platforma özel donanım erişimi gerektiren durumlarda (örneğin, WiFi Direct, Core Bluetooth, Android Keystore, iOS Keychain Services), yerel modüller (Native Modules/Plugins) aracılığıyla platformun kendi API'leri kullanılacaktır.
*   **Performans ve Batarya Optimizasyonu**: Çapraz platform framework'lerinin getirdiği potansiyel performans yükleri minimize edilecek, batarya verimliliği hem paylaşılan kodda hem de yerel entegrasyonlarda optimize edilecektir.
*   **Kullanıcı Deneyimi Tutarlılığı**: Her ne kadar platforma özel UI/UX öğeleri kullanılsa da, genel kullanıcı akışı ve acil durum arayüzü tutarlı bir deneyim sunacak şekilde tasarlanacaktır.
*   **Test Edilebilirlik**: Paylaşılan iş mantığı, kapsamlı birim ve entegrasyon testleriyle yüksek oranda test kapsamına sahip olacaktır.

## Framework Seçimi

Proje için Flutter veya React Native gibi modern bir çapraz platform framework'ü değerlendirilecektir. Seçim, projenin özel ihtiyaçlarına (performans gereksinimleri, geliştirme hızı, topluluk desteği, yerel modül entegrasyon kolaylığı) göre yapılacaktır. İlk değerlendirmelere göre:

*   **Flutter**: Yüksek performanslı UI renderingi ve güçlü yerel entegrasyon yetenekleri nedeniyle tercih edilebilir.
*   **React Native**: Geniş JavaScript/TypeScript ekosistemi ve olgunluğu nedeniyle tercih edilebilir.

## Teknik Implementasyon Detayları

### Paylaşılan Kod Mimarisi

*   **Core Logic**: Mesajlaşma, ağ yönetimi, güvenlik ve veri senkronizasyonu gibi temel algoritmalar ve iş mantığı, platformdan bağımsız bir kütüphane olarak geliştirilecektir.
*   **Veri Modelleri**: Mesaj, eş, ağ durumu ve kullanıcı profili gibi tüm veri yapıları paylaşılan kod tabanında tanımlanacaktır.
*   **Protokol Tanımları**: P2P, mesh ve güvenlik protokollerinin tanımları ve implementasyonları paylaşılan katmanda yer alacaktır.

### Yerel Modül Entegrasyonu

*   **Platform Kanalları (Flutter Method Channels / React Native Native Modules)**: Çapraz platform kod ile yerel platform API'leri arasında köprü görevi görecektir.
*   **Örnek Kullanım Alanları**: WiFi Direct bağlantıları, Bluetooth LE taramaları, Android Keystore/iOS Keychain erişimi, GPS ve sensör verileri gibi platforma özel yetenekler.

### Performans ve Batarya Optimizasyonu

*   **Arka Plan İşlemleri**: Hem paylaşılan kodda hem de yerel modüllerde batarya dostu arka plan görev yönetimi stratejileri uygulanacaktır.
*   **Bellek ve CPU Optimizasyonu**: Framework'ün sunduğu optimizasyon araçları ve teknikleri (örneğin, Flutter'da Skia motoru, React Native'de Bridge optimizasyonu) kullanılacaktır.

### Test Stratejisi

*   **Birim Testleri**: Paylaşılan iş mantığı için kapsamlı birim testleri yazılacaktır.
*   **Entegrasyon Testleri**: Yerel modüllerin çapraz platform kod ile entegrasyonu test edilecektir.
*   **Uçtan Uca Testler**: Gerçek cihazlarda ve simülatörlerde uçtan uca senaryolar test edilecektir.

## Geliştirmeye Başlarken

Çapraz platform geliştirme sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/cross_platform_stratejiler.md` belgesini detaylıca incelemeniz önerilir. Bu belge, çapraz platform framework'lerinin karşılaştırmasını, mimari yaklaşımları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel mobil uygulama geliştirme stratejileri ve prensipleri için `code/mobile/README.md` ve `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgelerine başvurmayı unutmayın.
