# Android Uygulama Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin Android uygulamasına özel geliştirmeleri içermektedir. Projenin genel mobil uygulama stratejisi için `code/mobile/README.md` ve `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgelerine başvurulmalıdır.

## Genel Yaklaşım

Android uygulaması, Türkiye pazarındaki yüksek penetrasyonu ve cihaz çeşitliliği göz önünde bulundurularak geliştirilecektir. Performans, batarya verimliliği ve geniş cihaz uyumluluğu temel önceliklerimizdir.

### Temel Prensipler

*   **Minimum SDK Desteği**: API Level 21 (Android 5.0) ve üzeri cihazları destekleyerek geniş bir kullanıcı kitlesine ulaşılacaktır.
*   **Batarya Optimizasyonu**: Doze modu, App Standby ve WorkManager gibi Android'in batarya optimizasyon mekanizmaları etkin bir şekilde kullanılacaktır. Arka plan servisleri minimum enerji tüketimiyle çalışacak şekilde tasarlanacaktır.
*   **P2P Ağ Entegrasyonu**: WiFi Direct ve Bluetooth LE gibi Android'in yerel P2P yetenekleri, mesh network oluşturmak için kullanılacaktır. Ağ keşfi ve bağlantı yönetimi bu API'ler üzerinden sağlanacaktır.
*   **Güvenlik**: Android Keystore, BiometricPrompt API ve Network Security Config gibi yerel güvenlik özellikleri, uygulamanın ve kullanıcı verilerinin güvenliğini sağlamak için kullanılacaktır.
*   **Kullanıcı Deneyimi**: Material Design prensipleriyle modern ve sezgisel bir arayüz tasarlanacaktır. Acil durum anında kolay kullanım için tek dokunuşla işlem yapma yetenekleri öncelikli olacaktır.
*   **Çevrimdışı Yetenekler**: Room Database gibi yerel depolama çözümleriyle offline-first mimarisi desteklenecek, internet bağlantısı olmasa bile mesajlaşma ve ağ içi iletişim sağlanacaktır.

## Teknik Implementasyon Detayları

### Mimari

*   **MVVM (Model-View-ViewModel)**: Temiz kod, test edilebilirlik ve sürdürülebilirlik için benimsenecektir.
*   **Android Architecture Components**: LiveData, ViewModel, Room ve WorkManager gibi bileşenler kullanılacaktır.

### Ağ Katmanı

*   **WiFi Direct**: Cihazlar arası doğrudan bağlantı ve grup oluşturma için kullanılacaktır.
*   **Bluetooth LE**: Düşük enerji tüketimli mesh network keşfi ve temel mesajlaşma için kullanılacaktır.
*   **Network Service Discovery (NSD)**: Yerel ağdaki diğer mesh node'larını keşfetmek için kullanılacaktır.
*   **Custom UDP/TCP Sockets**: Düşük seviyeli ağ iletişimi ve özel mesh protokolleri için gerekirse kullanılacaktır.

### Veri Yönetimi

*   **Room Database**: Uygulama içi mesaj geçmişi, ağ topolojisi, eş bilgileri ve kullanıcı profilleri gibi verilerin kalıcı olarak depolanması için kullanılacaktır.
*   **SharedPreferences / Proto DataStore**: Kullanıcı tercihleri ve küçük yapılandırma verileri için kullanılacaktır.

### Güvenlik

*   **Android Keystore**: Kriptografik anahtarların güvenli bir şekilde saklanması için kullanılacaktır.
*   **BiometricPrompt API**: Parmak izi veya yüz tanıma gibi biyometrik kimlik doğrulama için kullanılacaktır.
*   **Network Security Config**: Uygulamanın ağ iletişim güvenliğini yapılandırmak için kullanılacaktır.

### Performans Optimizasyonu

*   **Arka Plan İşlemleri**: Foreground Services, WorkManager ve JobScheduler ile batarya dostu arka plan görevleri yönetilecektir.
*   **Bellek Yönetimi**: Bitmap optimizasyonu, View geri dönüşümü ve bellek sızıntısı önleme teknikleri uygulanacaktır.
*   **CPU Optimizasyonu**: Çoklu iş parçacığı yönetimi, Kotlin Coroutines ve JNI (performans kritik kısımlar için) kullanılacaktır.

## Geliştirmeye Başlarken

Android geliştirme sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/android_gelistirme.md` belgesini detaylıca incelemeniz önerilir. Bu belge, Android platformuna özel teknik yaklaşımları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel mobil uygulama geliştirme stratejileri ve prensipleri için `code/mobile/README.md` ve `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgelerine başvurmayı unutmayın.
