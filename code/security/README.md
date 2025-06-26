# Güvenlik Katmanı Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin güvenlik katmanı geliştirmelerini içermektedir. Projenin temel amacı, acil durumlarda bile güvenli, gizli ve doğrulanabilir iletişim sağlamaktır.

## Genel Yaklaşım

Güvenlik, projenin her katmanına entegre edilmiş, çok katmanlı (defense-in-depth) bir yaklaşımla ele alınacaktır. Kullanıcı verilerinin gizliliği, mesaj bütünlüğü, kimlik doğrulama ve ağın saldırılara karşı direnci temel önceliklerimizdir.

### Temel Prensipler

*   **Uçtan Uca Şifreleme (End-to-End Encryption)**: Tüm mesajlar ve iletişim, kaynak cihazdan hedef cihaza kadar şifreli olacaktır. Ara node'lar mesaj içeriğini göremeyecektir.
*   **Kimlik Doğrulama ve Yetkilendirme**: Ağdaki her cihaz ve kullanıcı, iletişime başlamadan önce kriptografik olarak doğrulanacaktır. Yetkilendirme mekanizmaları ile erişim kontrolü sağlanacaktır.
*   **Gizlilik (Privacy by Design)**: Konum bilgileri, mesaj içerikleri ve iletişim paternleri gibi hassas verilerin gizliliği tasarım aşamasından itibaren korunacaktır. Veri minimizasyonu ve anonimleştirme teknikleri kullanılacaktır.
*   **Saldırı Direnci**: Sybil saldırıları, ağ tıkanıklığı (flooding), sinyal karıştırma (jamming) ve diğer kötü niyetli saldırılara karşı dayanıklı protokoller ve mekanizmalar geliştirilecektir.
*   **Kuantum Sonrası Kriptografi (Post-Quantum Cryptography)**: Gelecekteki kuantum bilgisayar tehditlerine karşı dayanıklı kriptografik algoritmalar (hibrit yaklaşımla) entegre edilecektir.
*   **Acil Durum Güvenliği**: Kriz anında bile güvenlikten ödün vermeden hızlı ve güvenilir iletişim sağlamak için özel güvenlik protokolleri ve adaptasyonlar geliştirilecektir.

## Klasör Yapısı

Bu `security` klasörü altında, güvenlik katmanının farklı bileşenlerine yönelik geliştirme alanları bulunmaktadır:

*   `crypto/`: Kriptografik algoritmaların (şifreleme, hash, dijital imza) implementasyonları ve anahtar yönetimi.
*   Diğer alt klasörler (örneğin, `auth/`, `privacy/`, `threat_detection/`) projenin ilerleyen aşamalarında eklenebilir.

Her bir alt klasördeki `README.md` dosyası, o alandaki geliştirme hedeflerini, teknik yaklaşımları ve önemli implementasyon detaylarını içerecektir. Bu rehberler, geliştiricilerin projeye hızlıca adapte olmalarını ve tutarlı bir şekilde katkıda bulunmalarını sağlamayı amaçlamaktadır.

## Geliştirmeye Başlarken

İlgili alt klasörün `README.md` dosyasını inceleyerek başlayabilirsiniz. Özellikle `doc/Yazilim_Gelistirme_Asamalari/guvenlik_implementasyon.md` ve `doc/Algoritma_ve_Analiz/guvenlik_algoritmalari.md` belgeleri, güvenlik katmanına özel teknik yaklaşımları, algoritmaları ve implementasyon detaylarını kapsamaktadır.

**Unutmayın**: `doc/Yazilim_Gelistirme_Asamalari/guvenlik_implementasyon.md` belgesi, güvenlik implementasyon sürecinin genel stratejilerini ve prensiplerini detaylandırmaktadır. Bu belgeye sık sık başvurarak projenin güvenlik vizyonu hakkında güncel bilgi edinin.
