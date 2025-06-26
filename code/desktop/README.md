# Masaüstü Entegrasyon Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin masaüstü platformlara entegrasyonu için geliştirmeleri içermektedir. Masaüstü uygulamaları, mobil cihazların kısıtlı kaynaklarını tamamlayıcı bir rol oynayacak ve daha güçlü işlem yetenekleri, geniş ekran alanı ve kararlı bağlantılar sunacaktır.

## Genel Yaklaşım

Masaüstü uygulamaları, acil durum anında bir "kontrol merkezi" veya "röle istasyonu" olarak işlev görecektir. Ağ izleme, koordinasyon, veri analizi ve uzun süreli röle operasyonları gibi görevler için kullanılacaktır. Mobil cihazlarla sorunsuz entegrasyon ve veri senkronizasyonu temel hedeflerimizdir.

### Temel Prensipler

*   **Tamamlayıcı Rol**: Masaüstü uygulamaları, mobil mesh network'ün temel işlevselliğine bağımlı olmayacak, ancak ağın yeteneklerini genişletecek ve acil durum yönetimini kolaylaştıracaktır.
*   **Güçlü İşlem Yetenekleri**: Daha fazla CPU, RAM ve depolama kapasitesini kullanarak karmaşık ağ analizi, veri arşivleme ve simülasyon gibi görevleri yerine getirecektir.
*   **Kararlı Bağlantı**: Ethernet veya kararlı WiFi bağlantılar�� üzerinden uzun süreli ve güvenilir bir ağ köprüsü (relay station) olarak işlev görebilecektir.
*   **Gelişmiş Kullanıcı Arayüzü (UI)**: Geniş ekran alanı, çoklu monitör desteği ve gelişmiş giriş/çıkış (klavye, fare) yetenekleri sayesinde detaylı ağ topolojisi görselleştirmeleri ve kriz yönetimi arayüzleri sunacaktır.
*   **Çapraz Platform Desteği**: Windows, macOS ve Linux gibi ana masaüstü işletim sistemlerinde çalışabilirlik sağlanacaktır.

## Teknik Implementasyon Detayları

### Hibrit Mimari Yaklaşımı

*   **Multi-Modal Arayüz**: Masaüstü uygulaması, mobil cihazlarla WebSocket veya REST API'ler üzerinden iletişim kurarak veri senkronizasyonu ve komut kontrolü sağlayacaktır.
*   **Rol Tabanlı Masaüstü Rolleri**: Masaüstü cihazlar, "Kontrol Merkezi" (ağ koordinasyonu), "Röle İstasyonu" (sinyal güçlendirme), "Veri Arşivi" (mesaj arşivleme) veya "Acil Durum Merkezi" (kriz masası) gibi farklı roller üstlenebilecektir.

### Teknoloji Yığını Analizi

*   **Çapraz Platform Framework'leri**: Electron, .NET MAUI veya Qt gibi framework'ler değerlendirilecektir. Seçim, performans gereksinimleri, geliştirme hızı ve platform entegrasyonu kolaylığına göre yapılacaktır.
    *   **Electron**: Web teknolojileriyle hızlı geliştirme için.
    *   **.NET MAUI**: Windows ve macOS'ta native performans ve .NET ekosistemi için.
    *   **Qt**: Gerçek çapraz platform desteği ve C++ tabanlı güçlü performans için.

### Masaüstü-Mobil Entegrasyon

*   **İletişim Protokolleri**: Masaüstü ve mobil cihazlar arasında mDNS/Bonjour, Bluetooth LE beacon tespiti veya WiFi Direct grup oluşturma gibi mekanizmalarla cihaz keşfi yapılacaktır. Veri senkronizasyonu için WebSocket veya gRPC gibi protokoller kullanılacaktır.
*   **Veri Senkronizasyonu**: Mesaj geçmişi, ağ topolojisi güncellemeleri ve acil durum uyarıları gibi veriler gerçek zamanlı olarak senkronize edilecektir.

### Mimari Tasarım Desenleri

*   **Servis Odaklı Mimari (SOA)**: Uygulama, farklı işlevsellikleri (ağ servisi, veri depolama servisi, güvenlik servisi) olan bağımsız servislerden oluşacaktır.
*   **Olay Odaklı Tasarım (Event-Driven)**: Ağ durumu değişiklikleri, cihaz bağlantıları veya acil durum uyarıları gibi olaylar bir olay veri yolu (Event Bus) üzerinden işlenecektir.

### Masaüstü Özel Özellikler

*   **Gelişmiş Analitik Panosu**: Ağ performansı trendleri, coğrafi kapsama haritaları, aktif kullanıcı istatistikleri ve sinyal gücü ısı haritaları gibi detaylı izleme yetenekleri sunulacaktır.
*   **Kriz Yönetimi Arayüzü**: Toplu uyarı yayınlama, kaynak tahsisi, tahliye rotası planlama ve durum değerlendirmesi gibi acil durum koordinasyon araçları sağlanacaktır.
*   **Çoklu Cihaz Orkestrasyonu**: Bağlı mobil cihazların uzaktan yapılandırılması, performanslarının izlenmesi ve toplu ayar güncellemeleri gibi yönetim yetenekleri.

### Güvenlik

*   **Yüksek Yetkili Erişim**: Masaüstü uygulamaları, sistem düzeyinde ağ kontrolü için yüksek yetkilere ihtiyaç duyabilir. Bu nedenle, güvenli kimlik doğrulama, şifreli veri depolama ve denetim kaydı gibi sıkı güvenlik önlemleri uygulanacaktır.
*   **Ağ Güvenliği**: Yerleşik güvenlik duvarı kuralları, VPN entegrasyonu ve uçtan uca şifreleme ile ağ iletişimi korunacaktır.

## Geliştirmeye Başlarken

Masaüstü entegrasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/desktop_entegrasyon.md` belgesini detaylıca incelemeniz önerilir. Bu belge, masaüstü platformlara özel teknik yaklaşımları, framework karşılaştırmalarını ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel kod tabanı stratejileri ve prensipleri için `code/README.md` belgesine başvurmayı unutmayın.
