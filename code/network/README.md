# Ağ Katmanı Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin ağ katmanı geliştirmelerini içermektedir. Projenin temel amacı, baz istasyonlarının çöktüğü acil durumlarda cep telefonlarının otomatik olarak bir mesh network kurarak hayat kurtaran iletişim sağlamasıdır.

## Genel Yaklaşım

Ağ katmanı, uygulamanın kalbi niteliğindedir. Cihazlar arası doğrudan iletişimi, mesaj yönlendirmeyi, ağ topolojisi yönetimini ve farklı radyo teknolojileri arasında adaptasyonu sağlayacaktır. Güvenilirlik, performans ve batarya verimliliği temel tasarım hedefleridir.

### Temel Prensipler

*   **Altyapı Bağımsızlığı**: Merkezi sunuculara veya baz istasyonlarına bağımlı olmadan çalışabilen, kendi kendini organize eden (self-organizing) bir ağ yapısı kurulacaktır.
*   **Hibrit Radyo Yaklaşımı**: WiFi Direct, Bluetooth LE, LoRa ve SDR gibi farklı radyo teknolojileri, menzil, bant genişliği ve güç tüketimi ihtiyaçlarına göre dinamik olarak kullanılacaktır.
*   **Akıllı Yönlendirme (Routing)**: Ağ koşullarına (tıkanıklık, node yoğunluğu, sinyal kalitesi) ve mesaj önceliğine göre en uygun yolu seçen adaptif yönlendirme algoritmaları geliştirilecektir.
*   **Öz-İyileşme (Self-Healing)**: Ağdaki node kayıplarına veya bağlantı kopukluklarına karşı otomatik olarak adapte olabilen ve kendini onarabilen mekanizmalar bulunacaktır.
*   **Güvenlik**: Ağ iletişimi uçtan uca şifrelenecek, node kimlik doğrulaması ve veri bütünlüğü sağlanacaktır. Saldırılara karşı dayanıklı protokoller benimsenecektir.

## Klasör Yapısı

Bu `network` klasörü altında, ağ katmanının farklı bileşenlerine yönelik geliştirme alanları bulunmaktadır:

*   `p2p/`: Peer-to-Peer (Eşten Eşe) ağ protokolleri ve keşif mekanizmaları implementasyonları.
*   `mesh/`: Mesh network topolojisi, yönlendirme algoritmaları ve ağ yönetimi implementasyonları.
*   `radio_interfaces/`: WiFi Direct, Bluetooth LE, LoRa, SDR gibi farklı radyo teknolojileri için arayüz ve yönetim kodları.

Her bir alt klasördeki `README.md` dosyası, o alandaki geliştirme hedeflerini, teknik yaklaşımları ve önemli implementasyon detaylarını içerecektir. Bu rehberler, geliştiricilerin projeye hızlıca adapte olmalarını ve tutarlı bir şekilde katkıda bulunmalarını sağlamayı amaçlamaktadır.

## Geliştirmeye Başlarken

İlgili alt klasörün `README.md` dosyasını inceleyerek başlayabilirsiniz. Her bir dosya, `doc/Yazilim_Gelistirme_Asamalari/mesh_network_implementasyon.md` ve `doc/Yazilim_Gelistirme_Asamalari/p2p_network_implementasyon.md` gibi ilgili dokümantasyonlara referans verecektir.

**Unutmayın**: `doc/Yazilim_Gelistirme_Asamalari/mesh_network_implementasyon.md` ve `doc/Yazilim_Gelistirme_Asamalari/p2p_network_implementasyon.md` belgeleri, ağ katmanının genel stratejilerini ve prensiplerini detaylandırmaktadır. Bu belgelere sık sık başvurarak projenin ağ vizyonu hakkında güncel bilgi edinin.
