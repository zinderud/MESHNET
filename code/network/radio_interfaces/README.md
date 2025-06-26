# Radyo Arayüzleri Yönetimi Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin farklı radyo teknolojileri (WiFi Direct, Bluetooth LE, LoRa, SDR) için arayüz yönetimi ve entegrasyon kodlarını içermektedir. Genel ağ katmanı stratejisi için `code/network/README.md` belgesine başvurulmalıdır.

## Genel Yaklaşım

Proje, acil durumlarda en uygun iletişim kanalını dinamik olarak seçebilmek için çeşitli radyo arayüzlerini kullanacaktır. Bu klasördeki kodlar, her bir radyo teknolojisinin düşük seviyeli kontrolünü, performans izlemesini ve diğer ağ katmanlarıyla entegrasyonunu sağlayacaktır.

### Temel Prensipler

*   **Soyutlama (Abstraction)**: Üst katmanların (P2P, Mesh) temel radyo teknolojilerinin karmaşıklığından izole edilmesi için bir soyutlama katmanı sağlanacaktır.
*   **Dinamik Seçim**: Mesaj önceliği, ağ koşulları, batarya durumu ve menzil gereksinimlerine göre en uygun radyo arayüzü otomatik olarak seçilecektir.
*   **Güç Yönetimi**: Her bir radyo arayüzünün güç tüketimi, batarya ömrünü maksimize etmek için optimize edilecektir.
*   **Performans İzleme**: Her radyo arayüz��nün sinyal kalitesi, bant genişliği ve gecikme gibi performans metrikleri sürekli olarak izlenecektir.
*   **Girişim Yönetimi**: Farklı radyo teknolojileri arasındaki potansiyel girişimler minimize edilecek ve spektrumun verimli kullanımı sağlanacaktır.

## Teknik Implementasyon Detayları

### Radyo Arayüzü Soyutlama Katmanı

*   **Ortak API**: Her radyo arayüzü için (WiFi Direct, Bluetooth LE, LoRa, SDR) ortak bir programlama arayüzü (API) tanımlanacaktır. Bu API, veri gönderme/alma, bağlantı durumu sorgulama ve performans metriklerini alma gibi temel işlevleri içerecektir.
*   **Adaptör Deseni**: Her radyo teknolojisi için bu ortak API'yi uygulayan adaptörler geliştirilecektir. Bu, yeni radyo teknolojilerinin kolayca entegre edilmesini sağlayacaktır.

### WiFi Direct Arayüzü

*   **Android API Entegrasyonu**: Android'in `WifiP2pManager` API'si kullanılarak cihaz keşfi, grup oluşturma, bağlantı yönetimi ve veri transferi sağlanacaktır.
*   **iOS Alternatifleri**: iOS'ta doğrudan WiFi Direct API bulunmadığından, `MultipeerConnectivity` veya özel WiFi ad-hoc modları gibi alternatif yaklaşımlar değerlendirilecektir.
*   **Performans Optimizasyonu**: Kanal seçimi, iletim gücü ayarı ve trafik şekillendirme gibi tekniklerle performans optimize edilecektir.

### Bluetooth LE Arayüzü

*   **Android API Entegrasyonu**: Android'in `BluetoothManager` ve `BluetoothAdapter` API'leri kullanılarak BLE taraması, reklam (advertisement), bağlantı ve GATT (Generic Attribute Profile) işlemleri yönetilecektir.
*   **iOS API Entegrasyonu**: iOS'un `Core Bluetooth` framework'ü kullanılarak BLE merkezi ve çevresel (peripheral) rolleri implemente edilecektir.
*   **BLE Mesh Desteği**: Yerel BLE Mesh protokolü (varsa) veya özel bir BLE tabanlı mesh implementasyonu geliştirilecektir.
*   **Düşük Güç Optimizasyonu**: Görev döngüsü (duty cycling), uyku modları ve adaptif tarama aralıkları ile batarya tüketimi minimize edilecektir.

### LoRa Arayüzü

*   **Modül Entegrasyonu**: ESP32-LoRa gibi popüler LoRa modülleriyle iletişim kurmak için seri (UART) veya SPI arayüzleri kullanılacaktır.
*   **LoRa PHY Katmanı Kontrolü**: Frekans, yayılma faktörü (spreading factor), bant genişliği ve kodlama oranı gibi LoRa fiziksel katman parametreleri dinamik olarak ayarlanacaktır.
*   **Uzun Menzil Optimizasyonu**: Düşük veri hızlarında bile uzun menzilli iletişim sağlamak için LoRa'nın benzersiz yetenekleri kullanılacaktır.

### SDR (Software Defined Radio) Arayüzü

*   **USB OTG Entegrasyonu**: Android cihazlarda USB OTG (On-The-Go) desteği ile RTL-SDR, HackRF gibi SDR dongle'ları bağlanacaktır.
*   **Düşük Seviyeli Kontrol**: SDR donanımına doğrudan erişim sağlayarak frekans, modülasyon, bant genişliği ve iletim gücü gibi parametreler yazılımsal olarak kontrol edilecektir.
*   **Bilişsel Radyo Yetenekleri**: Spektrum algılama, girişim tespiti ve dinamik frekans seçimi gibi bilişsel radyo yetenekleri implemente edilecektir.

### Radyo Arayüzleri Arası Koordinasyon

*   **Girişim Yönetimi**: Farklı radyo arayüzlerinin aynı anda çalışırken birbirine girişimini önlemek için koordinasyon algoritmaları geliştirilecektir.
*   **Kaynak Paylaşımı**: Anten, güç ve işlemci gibi ortak kaynakların farklı radyo arayüzleri arasında verimli bir şekilde paylaşılması sağlanacaktır.
*   **Handoff Mekanizmaları**: Bir radyo arayüzünden diğerine sorunsuz geçiş (handoff) algoritmaları implemente edilecektir.

## Geliştirmeye Başlarken

Radyo arayüzleri yönetimi implementasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/mesh_network_implementasyon.md` ve `doc/Algoritma_ve_Analiz/mesh_network_teknolojileri.md` belgelerini detaylıca incelemeniz önerilir. Bu belgeler, radyo arayüzlerinin ağ katmanındaki rolünü ve teknik yaklaşımları kapsamaktadır.

**Önemli Not**: Genel ağ katmanı stratejileri ve prensipleri için `code/network/README.md` belgesine başvurmayı unutmayın.
