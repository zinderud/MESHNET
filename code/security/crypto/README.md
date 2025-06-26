# Kriptografik İmplementasyon Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin güvenlik katmanında kullanılacak olan kriptografik algoritmaların ve anahtar yönetimi stratejilerinin implementasyonlarını içermektedir. Genel güvenlik katmanı stratejisi için `code/security/README.md` belgesine başvurulmalıdır.

## Genel Yaklaşım

Kriptografi, projenin temel güvenlik direğidir. Tüm iletişim ve veri depolama süreçleri, modern ve geleceğe dönük (kuantum sonrası) kriptografik algoritmalarla korunacaktır. Anahtar yönetimi, güvenli anahtar değişimi ve anahtar yaşam döngüsü bu klasördeki temel odak noktalarıdır.

### Temel Prensipler

*   **Uçtan Uca Şifreleme**: Mesajların ve verilerin kaynak cihazdan hedefe kadar şifreli kalmasını sağlamak için güçlü simetrik ve asimetrik şifreleme algoritmaları kullanılacaktır.
*   **Kuantum Sonrası Kriptografi (PQC)**: Gelecekteki kuantum bilgisayar tehditlerine karşı dayanıklı, NIST tarafından standartlaştırılan veya önerilen algoritmalar (örneğin, CRYSTALS-Kyber, CRYSTALS-Dilithium) hibrit bir yaklaşımla entegre edilecektir.
*   **Mükemmel İleri Gizlilik (Perfect Forward Secrecy - PFS)**: Her oturum için yeni anahtarlar türetilerek, geçmiş oturum anahtarlarının ele geçirilmesi durumunda bile eski iletişimlerin güvenliği sağlanacaktır.
*   **Anahtar Yönetimi**: Anahtar üretimi, dağıtımı, depolanması, rotasyonu ve iptali gibi tüm anahtar yaşam döngüsü süreçleri güvenli bir şekilde yönetilecektir.
*   **Dijital İmzalar**: Mesajların ve işlemlerin bütünlüğü ile göndericinin kimliği, güvenilir dijital imza algoritmalarıyla doğrulanacaktır.
*   **Mobil Uyumlu Kriptografi**: Mobil cihazların kısıtlı işlem gücü ve batarya ömrü göz önünde bulundurularak, performans ve enerji verimliliği optimize edilmiş kriptografik implementasyonlar tercih edilecektir.

## Teknik Implementasyon Detayları

### Kuantum Sonrası Kriptografi (PQC)

*   **Hibrit Yaklaşım**: Mevcut güvenilir algoritmalar (örneğin, Ed25519, RSA-4096) ile kuantum sonrası algoritmalar (örneğin, CRYSTALS-Kyber for Key Exchange, CRYSTALS-Dilithium for Digital Signatures) bir arada kullanılacaktır. Bu, hem mevcut güvenlik standartlarına uyumu hem de geleceğe dönük korumayı sağlayacaktır.
*   **Geçiş Stratejisi**: Kuantum sonrası algoritmaların tam entegrasyonu ve yaygınlaşması için aşamalı bir geçiş planı uygulanacaktır.

### Anahtar Yönetimi

*   **Anahtar Hiyerarşisi**: Cihaz kimlik anahtarları, oturum anahtarları, grup anahtarları ve geçici anahtarlar gibi farklı seviyelerde anahtarlar tanımlanacaktır. Ana master anahtar, donanım güvenlik modüllerinde (Secure Enclave, Android Keystore) korunacaktır.
*   **Anahtar Rotasyonu**: Güvenliği artırmak için anahtarlar düzenli aralıklarla (örneğin, oturum anahtarları her mesajlaşma oturumunda, cihaz anahtarları aylık) değiştirilecektir.
*   **Güvenli Anahtar Değişimi**: X25519 gibi Elliptic Curve Diffie-Hellman (ECDH) tabanlı protokoller, güvenli anahtar değişimi için kullanılacaktır.

### Şifreleme Algoritmaları

*   **Simetrik Şifreleme**: Mesaj içeriğini şifrelemek için ChaCha20-Poly1305 veya AES-256-GCM gibi hızlı ve güvenli simetrik şifreler kullanılacaktır.
*   **Dijital İmzalar**: Mesajların bütünlüğünü ve göndericinin kimliğini doğrulamak için Ed25519 gibi verimli dijital imza algoritmaları kullanılacaktır.
*   **Hash Fonksiyonları**: Veri bütünlüğü kontrolleri ve Merkle ağacı oluşturma için SHA-3 (Keccak) veya BLAKE2b gibi güvenli hash fonksiyonları kullanılacaktır.

### Mobil Uyumlu Kriptografi

*   **Donanım Hızlandırma**: Mobil cihazlardaki kriptografik hızlandırma donanımları (örneğin, ARM NEON, Secure Enclave) kullanılarak performans optimize edilecektir.
*   **Düşük Güç Tüketimi**: Kriptografik işlemlerin batarya üzerindeki etkisi minimize edilecek, enerji verimli implementasyonlar tercih edilecektir.
*   **Yerel Kütüphaneler**: Platforma özel (iOS için CommonCrypto, Android için Conscrypt/Bouncy Castle) veya çapraz platform (libsodium, OpenSSL) kriptografik kütüphaneler kullanılacaktır.

### Güvenlik Testleri

*   **Kriptografik Doğrulama**: Kullanılan algoritmaların standartlara uygunluğu ve implementasyonlarının doğruluğu test edilecektir.
*   **Yan Kanal Saldırıları**: Zamanlama, güç tüketimi gibi yan kanal saldırılarına karşı direnç testleri yapılacaktır.
*   **Penetrasyon Testleri**: Kriptografik implementasyonlardaki zafiyetleri tespit etmek için kapsamlı penetrasyon testleri uygulanacaktır.

## Geliştirmeye Başlarken

Kriptografik implementasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/guvenlik_implementasyon.md` ve `doc/Algoritma_ve_Analiz/guvenlik_algoritmalari.md` belgelerini detaylıca incelemeniz önerilir. Bu belgeler, kriptografi katmanına özel teknik yaklaşımları, algoritmaları ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Genel güvenlik katmanı stratejileri ve prensipleri için `code/security/README.md` belgesine başvurmayı unutmayın.
