# Kod Tabanı Teknik Dokümantasyonu Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin kod tabanına özel teknik dokümantasyonunu içermektedir. Bu dokümantasyon, geliştiricilerin kodun nasıl çalıştığını, mimari kararları ve implementasyon detaylarını anlamalarına yardımcı olmayı amaçlamaktadır.

## Genel Yaklaşım

Bu klasördeki dokümantasyon, projenin genel vizyon ve strateji belgelerinden (`doc/` klasöründeki) daha teknik ve implementasyon odaklı olacaktır. Kod seviyesindeki detaylar, API kullanımları, veri yapıları ve karmaşık algoritmaların açıklamaları burada yer alacaktır.

### Temel Prensipler

*   **Kod Odaklı**: Dokümantasyon, doğrudan kod tabanıyla ilgili teknik detayları içerecektir.
*   **Güncel**: Kod değişiklikleriyle birlikte dokümantasyonun da güncel tutulması hedeflenecektir.
*   **Anlaşılır**: Karmaşık teknik konuların anlaşılır bir dille açıklanması sağlanacaktır.
*   **Modüler**: Her bir bileşen veya modül için ayrı dokümantasyon dosyaları oluşturulacaktır.
*   **Referans**: Geliştiriciler için hızlı bir referans kaynağı görevi görecektir.

## İçerik Kategorileri

Bu klasör altında, projenin farklı teknik alanlar��na yönelik dokümantasyonlar bulunacaktır:

*   **API Dokümantasyonu**: Dahili ve harici API'lerin kullanımı, parametreleri ve dönüş değerleri.
*   **Mimari Kararlar**: Belirli mimari desenlerin veya teknolojilerin neden seçildiğine dair açıklamalar (ADR - Architectural Decision Records).
*   **Algoritma Detayları**: Özellikle mesh routing, konsensüs ve şifreleme gibi karmaşık algoritmaların adım adım açıklamaları.
*   **Veri Yapıları**: Uygulama genelinde kullanılan ana veri yapılarının (örneğin, mesaj formatları, eş bilgileri) detayları.
*   **Performans Optimizasyonları**: Uygulanan performans iyileştirme teknikleri ve bunların etkileri.
*   **Güvenlik Protokolleri**: Güvenlik protokollerinin işleyişi, anahtar yönetimi ve tehdit modellemeleri.
*   **Test Senaryoları**: Özellikle entegrasyon ve sistem testleri için detaylı senaryolar.
*   **Hata Yönetimi**: Hata kodları, hata işleme stratejileri ve geri kazanım prosedürleri.

## Dokümantasyon Formatı

Dokümantasyon dosyaları genellikle Markdown (`.md`) formatında olacaktır. Kod örnekleri, diyagramlar ve tablolar kullanılarak anlaşılırlık artırılacaktır.

## Geliştirmeye Başlarken

Bu klasördeki dokümantasyon, `code/` klasörü altındaki ilgili kod modülleriyle birlikte okunmalıdır. Örneğin, `code/network/mesh/` klasöründeki kodları incelerken, buradaki `docs/mesh_routing_algorithm.md` gibi bir dosyaya başvurulabilir.

**Unutmayın**: Bu dokümantasyon, projenin genel `doc/` klasöründeki stratejik ve vizyon belgelerini tamamlayıcı niteliktedir. Her iki dokümantasyon setine de düzenli olarak başvurmanız önerilir.
