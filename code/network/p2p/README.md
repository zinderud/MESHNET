# P2P (Peer-to-Peer) Network İmplementasyon Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin P2P (Eşten Eşe) ağ katmanı implementasyonlarını içermektedir. Bu katman, cihazlar arası doğrudan iletişimin temelini oluşturur. Genel ağ katmanı stratejisi için `code/network/README.md` belgesine başvurulmalıdır.

## Genel Yaklaşım

P2P katmanı, ağdaki her bir cihazın hem istemci hem de sunucu olarak işlev görmesini sağlayarak merkezi bir altyapıya bağımlılığı ortadan kaldırır. Güvenilir eş keşfi, akıllı eş seçimi ve verimli mesaj iletimi bu katmanın temel hedefleridir.

### Temel Prensipler

*   **Altyapı Bağımsızlığı**: Herhangi bir merkezi sunucu veya baz istasyonu olmadan çalışabilme yeteneği.
*   **Öz-Organizasyon**: Ağdaki eşlerin otomatik olarak birbirini keşfetmesi ve bağlantı kurması.
*   **Esneklik ve Ölçeklenebilirlik**: Değişen ağ koşullarına (eş sayısı, bağlantı kalitesi) dinamik olarak adapte olabilme ve büyük ölçekli ağları destekleyebilme.
*   **Güvenlik ve Gizlilik**: Eşler arası iletişimin güvenli ve gizli olmasını sağlayan mekanizmaların entegrasyonu.
*   **Kaynak Verimliliği**: Mobil cihazların batarya ve işlem gücü gibi kısıtlı kaynaklarını en verimli şekilde kullanma.

## Teknik Implementasyon Detayları

### P2P Network Mimarisi

*   **Hibrit P2P Topolojisi**: Ağda farklı rollere sahip eşler (Super Nodes, Regular Peers, Leaf Nodes) bulunacaktır. Super Node'lar daha kararlı ve güçlü cihazlar (masaüstü bilgisayarlar, sunucular) olabilirken, Regular Peer'lar mobil cihazlar ve Leaf Node'lar IoT sensörleri gibi düşük güçlü cihazlar olacaktır.
*   **Eş Kategorileri ve Rolleri**: Her kategori, ağdaki sorumlulukları (topoloji bakımı, mesaj aktarımı, sensör verisi toplama) ve kaynak yetenekleri (güç, bant genişliği, depolama) açısından tanımlanmıştır.

### P2P Protokol Yığını

*   **Katmanlı Mimari**: Uygulama, P2P, Taşıma ve Ağ katmanlarından oluşan bir protokol yığını kullanılacaktır. Bu yapı, modülerlik ve esneklik sağlayacaktır.

### Eş Keşif Algoritmaları

*   **Çok Kanallı Keşif**: WiFi Direct Service Discovery, Bluetooth LE Advertisement, mDNS/Bonjour Broadcasting ve özel radyo beacon'ları gibi birden fazla kanal kullanılarak eş keşfi yapılacaktır.
*   **Adaptif Keşif Algoritması**: Ağ koşullarına göre (örneğin, acil durum modunda daha agresif tarama) keşif stratejileri dinamik olarak ayarlanacaktır.
*   **Eş İtibar Sistemi**: Eşlerin güvenilirliği, çalışma süresi, yanıt süresi ve batarya seviyesi gibi metrikler üzerinden bir itibar puanı sistemi geliştirilecektir. Bu, akıllı eş seçimi için kullanılacaktır.

### Yönlendirme Algoritmaları

*   **Hibrit Yönlendirme Protokolü**: Coğrafi yönlendirme (konum tabanlı), Dinamik Kaynak Yönlendirme (güvenilirlik için) ve Sel (Flooding) (acil durum yayınları için) gibi farklı stratejilerin bir kombinasyonu kullanılacaktır.
*   **Acil Durum Odaklı Yönlendirme**: Mesaj önceliğine (LIFE_CRITICAL, SAFETY_CRITICAL vb.) göre yönlendirme kararları alınacak, kritik mesajlar için en hızlı ve güvenilir yollar tercih edilecektir.
*   **Akıllı Rota Seçimi**: Hop sayısı, uçtan uca gecikme, enerji verimliliği, bağlantı güvenilirliği, bant genişliği ve güvenlik seviyesi gibi metrikler dikkate alınarak en uygun rota seçilecektir.

### Ağ Topolojisi Yönetimi

*   **Dağıtık Hash Tablosu (DHT)**: Ağdaki eş bilgilerinin ve kaynakların dağıtık olarak depolanması ve keşfedilmesi için kullanılacaktır. Kademlia tabanlı bir DHT implementasyonu düşünülebilir.
*   **Topoloji Bakımı**: Periyodik kalp atışı mesajları, ölü eş tespiti ve rota yeniden hesaplama gibi mekanizmalarla ağ topolojisi sürekli güncel tutulacaktır.
*   **Ağ Bölünmesi Yönetimi**: Ağ bölünmeleri durumunda otomatik yeniden bağlanma ve veri tutarlılığı sağlama stratejileri geliştirilecektir.

### P2P Güvenlik Implementasyonu

*   **Güvenli Eş Kimlik Doğrulaması**: Kriptografik kimlikler (Ed25519), cihaz parmak izi, konum tabanlı doğrulama ve davranış analizi gibi çok katmanlı kimlik doğrulama yöntemleri kullanılacaktır.
*   **Uçtan Uca Şifreleme**: Tüm eşler arası iletişim, Signal Protokolü gibi güçlü uçtan uca şifreleme protokolleriyle korunacaktır.
*   **Bizans Hata Toleransı (BFT)**: Kötü amaçlı eşlerin ağ manipülasyonunu önlemek için BFT mekanizmaları entegre edilecektir.

### Mesaj İşleme Protokolleri

*   **Mesaj Öncelik Kuyruğu**: Acil durum mesajları için farklı öncelik seviyeleri (EMERGENCY_ALERT, SAFETY_WARNING vb.) tanımlanacak ve bu önceliklere göre mesajlar işlenecektir.
*   **Güvenilir Mesaj Teslimatı**: En az bir kez teslimat garantisi, yinelenen mesaj tespiti, mesaj yaşlandırma ve yeniden deneme mekanizmaları uygulanacaktır.
*   **Mesaj Parçalama**: Büyük mesajlar, ağın bant genişliği ve eşlerin kapasitesine göre parçalanacak ve hedefte yeniden birleştirilecektir.

### Veri Senkronizasyonu

*   **Çakışmasız Çoğaltılmış Veri Türleri (CRDT)**: Veri tutarlılığını sağlamak ve çakışmaları otomatik olarak çözmek için CRDT'ler kullanılacaktır.
*   **Gossip Protokolü**: Ağdaki veri ve durum güncellemelerinin verimli bir şekilde yayılması için kullanılacaktır.
*   **Veri Tutarlılık Modelleri**: Nihai tutarlılık varsayılan olarak benimsenecek, ancak kritik veriler için daha güçlü tutarlılık modelleri uygulanacaktır.

## Geliştirmeye Başlarken

P2P network implementasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/p2p_network_implementasyon.md` ve `doc/Algoritma_ve_Analiz/p2p_network_protokolleri.md` belgelerini detaylıca incelemeniz önerilir. Bu belgeler, P2P katmanına özel teknik yaklaşımları, algoritmaları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel ağ katmanı stratejileri ve prensipleri için `code/network/README.md` belgesine başvurmayı unutmayın.
