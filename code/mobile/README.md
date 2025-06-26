# Mobil Uygulama Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin mobil uygulama geliştirmelerini içermektedir. Projenin temel amacı, acil durumlarda cep telefonlarının otomatik olarak bir mesh network kurarak hayat kurtaran iletişim sağlamasıdır.

## Genel Yaklaşım

Mobil uygulamalar, kullanıcıların acil durumlarda sezgisel ve güvenilir bir iletişim aracı olarak telefonlarını kullanabilmelerini sağlamak üzere tasarlanacaktır. Geliştirme sürecinde performans, batarya verimliliği, güvenlik ve kullanıcı deneyimi ön planda tutulacaktır.

### Temel Prensipler

*   **Offline-First**: İnternet bağlantısı olmasa bile uygulamanın temel işlevlerini (mesajlaşma, konum paylaşımı, ağ keşfi) yerine getirebilmesi sağlanacaktır.
*   **Batarya Verimliliği**: Mobil cihazların sınırlı batarya ömrü göz önünde bulundurularak, ağ aktiviteleri ve arka plan işlemleri batarya dostu algoritmalarla optimize edilecektir.
*   **Kullanıcı Dostu Arayüz (UX)**: Panik anında bile kolayca kullanılabilecek, sade ve anlaşılır bir arayüz tasarlanacaktır. Tek dokunuşla acil durum bildirimleri gibi özellikler öncelikli olacaktır.
*   **Güvenlik ve Gizlilik**: Tüm iletişim uçtan uca şifrelenecek, konum ve kişisel verilerin gizliliği korunacaktır. Kimlik doğrulama mekanizmaları titizlikle uygulanacaktır.
*   **Adaptif Ağ Yönetimi**: Uygulama, cihazın mevcut bağlantı yeteneklerine (Bluetooth LE, WiFi Direct, hücresel ağ vb.) ve çevresel koşullara göre en uygun ağ stratejisini otomatik olarak seçecektir.

## Klasör Yapısı

Bu `mobile` klasörü altında, farklı mobil platformlara yönelik geliştirme alanları bulunmaktadır:

*   `android/`: Android işletim sistemi için özel geliştirmeler.
*   `ios/`: iOS işletim sistemi için özel geliştirmeler.
*   `cross_platform/`: Android ve iOS arasında paylaşılan kod tabanı ve çapraz platform stratejileri.

Her bir alt klasördeki `README.md` dosyası, o platforma özel geliştirme hedeflerini, teknik yaklaşımları ve önemli implementasyon detaylarını içerecektir. Bu rehberler, geliştiricilerin projeye hızlıca adapte olmalarını ve tutarlı bir şekilde katkıda bulunmalarını sağlamayı amaçlamaktadır.

## Geliştirmeye Başlarken

İlgili platformun `README.md` dosyasını inceleyerek başlayabilirsiniz. Her bir dosya, `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` ve ilgili platforma özel dokümantasyonlara (örneğin, `doc/Yazilim_Gelistirme_Asamalari/android_gelistirme.md`) referans verecektir.

**Unutmayın**: `doc/Yazilim_Gelistirme_Asamalari/mobil_uygulama_gelistirme.md` belgesi, mobil uygulama geliştirme sürecinin genel stratejilerini ve prensiplerini detaylandırmaktadır. Bu belgeye sık sık başvurarak projenin mobil vizyonu hakkında güncel bilgi edinin.
