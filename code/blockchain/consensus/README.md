# Konsensüs Mekanizması (Emergency Proof of Authority - ePoA) Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin blockchain katmanında kullanılacak olan Emergency Proof of Authority (ePoA) konsensüs mekanizmasının implementasyonlarını içermektedir. Genel blockchain katmanı stratejisi için `code/blockchain/README.md` belgesine başvurulmalıdır.

## Genel Yaklaşım

ePoA, acil durum senaryolarında hızlı blok üretimi ve düşük kaynak tüketimi sağlamak üzere tasarlanmış, mobil cihazlara uyumlu bir konsensüs algoritmasıdır. Bu mekanizma, ağdaki güvenilir node'ların (validator) blokları onaylamasına dayanır ve merkeziyetsizliği korurken yüksek performans hedefler.

### Temel Prensipler

*   **Hızlı Blok Üretimi**: Acil durumlarda kritik mesajların anında ağa kaydedilmesi için çok kısa blok süreleri (örneğin, 3 saniye) hedeflenecektir.
*   **Düşük Kaynak Tüketimi**: Mobil cihazların batarya ve CPU kısıtlamaları göz önünde bulundurularak, konsensüs süreci enerji verimli olacak şekilde tasarlanacaktır.
*   **Dinamik Validator Seçimi**: Ağdaki node'ların güvenilirlik puanı, batarya seviyesi, sinyal kalitesi ve yanıt süresi gibi metrikler baz alınarak dinamik olarak validator'lar seçilecektir.
*   **Acil Durum Adaptasyonu**: Gerçek bir acil durum tespit edildiğinde, konsensüs parametreleri (blok süresi, validator sayısı, onay eşiği) otomatik olarak hızlandırılacaktır.
*   **Güvenilirlik ve Değişmezlik**: Seçilen validator'lar tarafından onaylanan bloklar, ağın güvenilirliğini ve veri bütünlüğünü sağlayacaktır.

## Teknik Implementasyon Detayları

### ePoA Algoritması

*   **Acil Durum Tespiti**: Uygulama, çevresel sensörler, ağ durumu ve kullanıcı girdileri gibi çeşitli kaynaklardan gelen verileri kullanarak gerçek bir acil durumu tespit edecektir. Bu tespit, konsensüs mekanizmasını hızlandırmak için bir tetikleyici görevi görecektir.
*   **Validator Seçimi**: Ağdaki tüm aktif node'lar arasından, belirlenen kriterlere (itibar puanı, batarya, sinyal gücü vb.) göre en uygun node'lar validator olarak seçilecektir. Bu seçim periyodik olarak veya acil durum tetiklendiğinde dinamik olarak güncellenecektir.
*   **Hızlı Blok Oluşturma**: Seçilen validator'lar, çok kısa sürelerde (örneğin, 1-3 saniye) yeni bloklar oluşturacak ve bu blokları ağa yayınlayacaktır.
*   **Onay ve Taahhüt**: Diğer validator'lar ve ağdaki node'lar, yayınlanan blokları hızlıca doğrulayacak ve konsensüs eşiğine ulaşıldığında bloğu zincire ekleyecektir.

### Validator Yönetimi

*   **Validator Kaydı**: Node'ların validator olmak için ağa kaydolma süreci ve gereksinimleri.
*   **İtibar Sistemi**: Validator'ların geçmiş performansına, dürüstlüğüne ve ağa katkısına göre bir itibar puanı sistemi geliştirilecektir. Düşük itibar puanına sahip validator'lar otomatik olarak sistemden çıkarılabilir.
*   **Dinamik Yeniden Seçim**: Validator seti, periyodik olarak veya belirli olaylar (örneğin, bir validator'ın çevrimdışı olması) üzerine yeniden seçilecektir.

### Blok Üretimi ve Yayılımı

*   **Blok Yapısı**: Acil durum mesajları, ağ durumu güncellemeleri ve diğer kritik verileri içerecek şekilde optimize edilmiş hafif blok yapıları.
*   **Blok Yayılımı**: Yeni oluşturulan bloklar, P2P ağ üzerinden hızlı ve verimli bir şekilde tüm node'lara yayılacaktır. Çoklu radyo arayüzleri (WiFi Direct, Bluetooth LE) bu yayılımı hızlandırmak için kullanılacaktır.
*   **Blok Doğrulama**: Node'lar, aldıkları blokları kriptografik olarak (imza, hash) ve konsensüs kurallarına göre hızlıca doğrulayacaktır.

### Güvenlik ve Hata Toleransı

*   **Bizans Hata Toleransı (BFT)**: Kötü niyetli veya arızalı validator'ların ağın bütünlüğünü bozmasını önlemek için BFT prensipleri uygulanacaktır.
*   **Çift Harcama (Double Spending) Önleme**: Mesajların veya işlemlerin ağda birden fazla kez kaydedilmesini önleyen mekanizmalar.
*   **Sybil Saldırısı Önleme**: Sahte kimliklerin ağa sızmasını ve konsensüsü manipüle etmesini önleyen kimlik doğrulama ve itibar sistemleri.

## Geliştirmeye Başlarken

Konsensüs mekanizması implementasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/blockchain_implementasyon.md` ve `doc/BLOCKCHAIN_P2P_DETAY_ANALIZ.md` belgelerini detaylıca incelemeniz önerilir. Bu belgeler, ePoA konsensüsüne özel teknik yaklaşımları, algoritmaları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel blockchain katmanı stratejileri ve prensipleri için `code/blockchain/README.md` belgesine başvurmayı unutmayın.
