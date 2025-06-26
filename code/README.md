
# Acil Durum Mesh Network - Kod Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin ana kod tabanını içermektedir. Projenin temel amacı, baz istasyonlarının çöktüğü acil durumlarda cep telefonlarının otomatik olarak bir mesh network kurarak hayat kurtaran iletişim sağlamasıdır.

## Geliştirme Yaklaşımı

Proje, modüler ve katmanlı bir mimariyle geliştirilecektir. Her bir ana bileşen (mobil, ağ, blockchain, güvenlik vb.) kendi içinde bağımsız olarak geliştirilip test edilecek ve ardından entegre edilecektir. Geliştirme sürecinde çevik metodolojiler (Agile) benimsenecek, sürekli entegrasyon ve dağıtım (CI/CD) pratikleri uygulanacaktır.

### Temel Prensipler

*   **Mobil Odaklı Tasarım**: Uygulama, mobil cihazların kısıtlı kaynaklarını (batarya, CPU, bellek) en verimli şekilde kullanacak şekilde tasarlanacaktır. Offline-first yaklaşımı benimsenecektir.
*   **Dağıtık Mimari**: Merkezi bir sunucuya bağımlılık minimumda tutulacak, ağ kendi kendini organize eden (self-organizing) ve kendi kendini iyileştiren (self-healing) bir yapıya sahip olacaktır.
*   **Güvenlik ve Gizlilik**: Tüm iletişim uçtan uca şifrelenecek, kullanıcı verilerinin gizliliği en üst düzeyde korunacaktır. Kimlik doğrulama ve yetkilendirme mekanizmaları titizlikle uygulanacaktır.
*   **Adaptif ve Akıllı Sistem**: Ağ, çevresel koşullara (sinyal kalitesi, batarya durumu, node yoğunluğu) ve acil durumun şiddetine göre dinamik olarak adapte olacaktır. Yapay zeka destekli optimizasyonlar kullanılacaktır.
*   **Açık Kaynak Felsefesi**: Topluluk katkısına açık, şeffaf bir geliştirme süreci benimsenecektir.

## Klasör Yapısı

Bu `code` klasörü altında, projenin ana bileşenlerini temsil eden alt klasörler bulunmaktadır. Her bir alt klasör, ilgili geliştirme alanına özel rehberler ve detaylar içeren kendi `README.md` dosyasına sahiptir.

*   `mobile/`: Android, iOS ve çapraz platform mobil uygulama geliştirmeleri.
*   `network/`: P2P, mesh ve radyo arayüzleri implementasyonları.
*   `blockchain/`: Blockchain ve konsensüs mekanizmaları geliştirmeleri.
*   `security/`: Kriptografik ve ağ güvenlik implementasyonları.
*   `backend/`: Gerekli dağıtık backend servisleri (minimum bağımlılıkla).
*   `desktop/`: Masaüstü entegrasyonu ve kontrol merkezi geliştirmeleri.
*   `docs/`: Kod tabanına özel teknik dokümantasyon.

Her bir alt klasördeki `README.md` dosyası, o alandaki geliştirme hedeflerini, teknik yaklaşımları ve önemli implementasyon detaylarını içerecektir. Bu rehberler, geliştiricilerin projeye hızlıca adapte olmalarını ve tutarlı bir şekilde katkıda bulunmalarını sağlamayı amaçlamaktadır.

## Geliştirmeye Başlarken

İlgili alt klasörün `README.md` dosyasını inceleyerek başlayabilirsiniz. Her bir dosya, o alandaki mevcut dokümantasyona (örneğin, `doc/Yazilim_Gelistirme_Asamalari/` altındaki ilgili MD dosyaları) referans verecektir.

**Unutmayın**: Mevcut dokümantasyona sık sık başvurarak projenin vizyonu, hedefleri ve stratejik yaklaşımları hakkında güncel bilgi edinin.
