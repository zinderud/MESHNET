# Mesh Network İmplementasyon Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin mesh network katmanı implementasyonlarını içermektedir. Bu katman, cihazlar arası çoklu atlamalı (multi-hop) iletişimi ve ağın kendi kendini organize etmesini sağlar. Genel ağ katmanı stratejisi için `code/network/README.md` belgesine başvurulmalıdır.

## Genel Yaklaşım

Mesh network katmanı, P2P bağlantılarının ötesine geçerek, cihazların doğrudan bağlı olmadığı eşler arasında bile mesaj iletebilmesini sağlar. Bu, ağın kapsama alanını genişletir ve dayanıklılığını artırır. Adaptif yönlendirme, çoklu radyo entegrasyonu ve ağın öz-organizasyon yetenekleri bu katmanın temel hedefleridir.

### Temel Prensipler

*   **Çoklu Atlamalı İletişim**: Mesajların, doğrudan erişilemeyen hedeflere ulaşmak için ara node'lar üzerinden iletilmesi.
*   **Hibrit Radyo Entegrasyonu**: WiFi Direct, Bluetooth LE, LoRa ve SDR gibi farklı radyo teknolojilerini bir araya getirerek menzil, bant genişliği ve güç tüketimi arasında dinamik bir denge kurma.
*   **Akıllı Yönlendirme**: Ağ koşullarına (tıkanıklık, sinyal kalitesi, node yoğunluğu) ve mesaj önceliğine göre en verimli iletişim yolunu seçme.
*   **Öz-Organizasyon ve Öz-İyileşme**: Ağın, merkezi bir kontrol olmaksızın kendi kendini kurması, yönetmesi ve arızalara karşı kendini onarması.
*   **Kaynak Verimliliği**: Mobil cihazların batarya ömrünü ve işlem gücünü koruyarak uzun süreli operasyon sağlamak.

## Teknik Implementasyon Detayları

### Mesh Network Mimarisi

*   **Çoklu Radyo Mesh Topolojisi**: Farklı radyo teknolojilerine sahip node'ların (Super Nodes, Regular Mesh Nodes, Low-Power Mesh Nodes) bir araya gelerek katmanlı bir ağ yapısı oluşturması.
*   **Heterojen Radyo Entegrasyonu**: WiFi Direct (yüksek bant genişliği, orta menzil), Bluetooth LE Mesh (düşük güç, kısa menzil), LoRa (ultra düşük güç, uzun menzil) ve SDR (yapılandırılabilir menzil ve bant genişliği) gibi teknolojilerin entegrasyonu.

### Protokol Yığını Implementasyonu

*   **Adaptif Protokol Seçimi**: Mesaj gereksinimlerine (öncelik, boyut, gecikme) ve mevcut radyo arayüzlerinin durumuna göre en uygun radyo teknolojisinin dinamik olarak seçilmesi.
*   **Çok Katmanlı Mesh Protokolü**: Uygulama, Mesh Yönlendirme, Radyo Soyutlama ve Fiziksel Radyo katmanlarından oluşan bir protokol yığını.

### Mesh Yönlendirme Algoritmaları

*   **Hibrit Yönlendirme Protokolü**: Coğrafi yönlendirme, Sel (Flooding) ve Dinamik Kaynak Yönlendirme (DSR) gibi algoritmaların bir kombinasyonu kullanılacaktır.
*   **Çoklu Yol Yönlendirme**: Mesajların birden fazla yedekli yol üzerinden gönderilmesi, güvenilirliği artırır ve tıkanıklığı azaltır.
*   **Acil Durum Yönlendirme Optimizasyonu**: Kritik mesajlar için öncelikli iletim, yedekli yol kullanımı ve protokol yükünün azaltılması.

### Radyo Yönetimi Implementasyonu

*   **Akıllı Radyo Seçimi**: Mesaj gereksinimleri ve radyo arayüzlerinin performans metriklerine (sinyal gücü, batarya etkisi, tıkanıklık) göre en uygun radyo arayüzünün seçilmesi.
*   **Dinamik Spektrum Yönetimi**: Kanal seçimi, girişimden kaçınma ve adaptif güç kontrolü gibi tekniklerle spektrumun verimli kullanılması.
*   **Güç Yönetimi**: Görev döngüsü (duty cycling), adaptif iletim gücü ve uyku/uyanma zamanlaması gibi stratejilerle batarya ömrünün uzatılması.

### WiFi Direct Implementasyonu

*   **Grup Oluşturma**: Cihazlar arası doğrudan bağlantı gruplarının dinamik olarak oluşturulması ve yönetilmesi.
*   **Mesh Uzantıları**: Çoklu atlamalı iletim, köprü modu operasyonu ve yük dengeleme gibi mesh yeteneklerinin WiFi Direct üzerine inşa edilmesi.

### Bluetooth LE Mesh Implementasyonu

*   **BLE Mesh Ağı**: Düşük enerji tüketimli, çoklu atlamalı ağ topolojisinin oluşturulması.
*   **Özellikler**: Yönetilen sel (managed flooding), arkadaşlık (friendship) ilişkileri ve düşük güç node'ları (LPN) gibi BLE Mesh özelliklerinin kullanılması.

### LoRa Entegrasyonu

*   **LoRa Ağı Mimarisi**: Uzun menzilli, düşük bant genişlikli iletişim için LoRa node'larının ve gerekirse LoRa Gateway'lerinin entegrasyonu.
*   **Acil Durum LoRa Adaptasyonu**: Kritik mesajlar için öncelikli kanal tahsisi ve basitleştirilmiş protokol yığını.

### Hücresel Entegrasyon

*   **Hücresel Mesh Köprüsü**: Mevcut hücresel ağların (varsa) mesh network için bir internet ağ geçidi veya uzun menzilli omurga olarak kullanılması.
*   **Hücresel Geri Dönüş (Fallback)**: Diğer radyo teknolojileri başarısız olduğunda hücresel ağın yedek olarak kullanılması.

### Bilişsel Radyo (Cognitive Radio) Implementasyonu

*   **Spektrum Algılama**: Çevredeki radyo spektrumunu analiz ederek boş kanalları ve girişim kaynaklarını tespit etme.
*   **Dinamik Spektrum Erişimi**: Tespit edilen fırsatçı kanalları kullanarak iletişimi optimize etme.

### Ağ Öz-Organizasyonu

*   **Otonom Ağ Oluşumu**: Ağın, merkezi bir kontrol olmaksızın kendi kendini kurması ve yapılandırması.
*   **Adaptif Ağ Yeniden Yapılandırması**: Node hareketliliği, batarya tükenmesi veya sinyal bozulması gibi değişikliklere dinamik olarak adapte olma.

### Hizmet Kalitesi (QoS)

*   **Trafik Sınıflandırması**: Mesajların öncelik seviyelerine göre sınıflandırılması (Acil, Güvenlik Kritik, Operasyonel vb.).
*   **QoS Implementasyonu**: Trafik şekillendirme, öncelik kuyruklama ve bant genişliği tahsisi gibi mekanizmalarla kritik mesajların garantili teslimatı.

## Geliştirmeye Başlarken

Mesh network implementasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/mesh_network_implementasyon.md` ve `doc/Algoritma_ve_Analiz/mesh_network_teknolojileri.md` belgelerini detaylıca incelemeniz önerilir. Bu belgeler, mesh katmanına özel teknik yaklaşımları, algoritmaları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel ağ katmanı stratejileri ve prensipleri için `code/network/README.md` belgesine başvurmayı unutmayın.
