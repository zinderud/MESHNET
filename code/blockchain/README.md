# Blockchain Katmanı Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin blockchain katmanı geliştirmelerini içermektedir. Blockchain teknolojisi, ağdaki veri bütünlüğünü, güvenilirliği ve merkeziyetsizliği sağlamak için kullanılacaktır.

## Genel Yaklaşım

Acil durum senaryolarına özel olarak tasarlanmış hafif (lightweight) bir blockchain implementasyonu geliştirilecektir. Bu blockchain, özellikle baz istasyonlarının çöktüğü durumlarda bile mesajların ve ağ durum güncellemelerinin güvenli, değişmez ve doğrulanabilir bir şekilde kaydedilmesini sağlayacaktır.

### Temel Prensipler

*   **Hafif Konsensüs Mekanizması**: Mobil cihazların kısıtlı kaynaklarına uygun, hızlı blok üretimi ve düşük enerji tüketimi sağlayan bir konsensüs algoritması (Emergency Proof of Authority - ePoA) benimsenecektir.
*   **Veri Bütünlüğü ve Değişmezlik**: Acil durum mesajları, konum bilgileri ve ağ durumu güncellemeleri gibi kritik veriler, blockchain üzerinde kriptografik olarak güvenli ve değişmez bir şekilde kaydedilecektir.
*   **Merkeziyetsizlik**: Ağdaki hiçbir tekil otoriteye bağımlı olmayan, dağıtık bir yapı kurulacaktır. Bu, sansür ve tek nokta başarısızlığı riskini ortadan kaldıracaktır.
*   **Güvenilirlik ve Doğrulanabilirlik**: Ağdaki tüm işlemler ve mesajlar, blockchain mekanizmaları aracılığıyla doğrulanabilir olacak, kötü niyetli manipülasyonlara karşı dirençli olacaktır.
*   **Mobil Uyumlu Tasarım**: Blockchain node'ları, mobil cihazlarda verimli bir şekilde çalışacak, batarya ve bellek tüketimi optimize edilecektir.

## Klasör Yapısı

Bu `blockchain` klasörü altında, blockchain katmanının farklı bileşenlerine yönelik geliştirme alanları bulunmaktadır:

*   `consensus/`: Konsensüs mekanizması (Emergency Proof of Authority - ePoA) implementasyonları ve validator yönetimi.
*   Diğer alt klasörler (örneğin, `core/`, `wallet/`, `api/`) projenin ilerleyen aşamalarında eklenebilir.

Her bir alt klasördeki `README.md` dosyası, o alandaki geliştirme hedeflerini, teknik yaklaşımları ve önemli implementasyon detaylarını içerecektir. Bu rehberler, geliştiricilerin projeye hızlıca adapte olmalarını ve tutarlı bir şekilde katkıda bulunmalarını sağlamayı amaçlamaktadır.

## Geliştirmeye Başlarken

İlgili alt klasörün `README.md` dosyasını inceleyerek başlayabilirsiniz. Özellikle `doc/Yazilim_Gelistirme_Asamalari/blockchain_implementasyon.md` ve `doc/BLOCKCHAIN_P2P_DETAY_ANALIZ.md` belgeleri, blockchain katmanına özel teknik yaklaşımları, algoritmaları ve implementasyon detaylarını kapsamaktadır.

**Unutmayın**: `doc/Yazilim_Gelistirme_Asamalari/blockchain_implementasyon.md` belgesi, blockchain implementasyon sürecinin genel stratejilerini ve prensiplerini detaylandırmaktadır. Bu belgeye sık sık başvurarak projenin blockchain vizyonu hakkında güncel bilgi edinin.
