# Backend Servisleri Geliştirme Rehberi

Bu klasör, "Acil Durum Cep Telefonu Mesh Network" projesinin backend servisleri geliştirmelerini içermektedir. Projenin temel felsefesi altyapı bağımsızlığı olsa da, belirli durumlarda (örneğin, internet bağlantısı mevcut olduğunda veya gelişmiş koordinasyon gerektiğinde) destekleyici backend servisleri kullanılabilir.

## Genel Yaklaşım

Backend servisleri, projenin ana işlevselliği için kritik bağımlılık oluşturmayacak, ancak ağın yeteneklerini genişletecek ve acil durum dışı senaryolarda veya kısmi altyapı mevcutken ek faydalar sağlayacak şekilde tasarlanacaktır. Bu servisler, merkeziyetsiz ağın bir uzantısı olarak işlev görecektir.

### Temel Prensipler

*   **Minimum Bağımlılık**: Uygulamanın temel mesh network işlevselliği, backend servisleri olmadan da tam olarak çalışabilmelidir. Backend servisleri, bir "eklenti" veya "köprü" görevi görecektir.
*   **Ölçeklenebilirlik ve Yüksek Erişilebilirlik**: Acil durum anlarında yüksek trafik yükünü kaldırabilecek ve sürekli erişilebilirliği sağlayacak şekilde tasarlanacaktır.
*   **Güvenlik**: Tüm backend iletişimi şifrelenecek, kimlik doğrulama ve yetkilendirme mekanizmaları titizlikle uygulanacaktır. Hassas verilerin korunması en üst düzeyde olacaktır.
*   **Modüler Mimari**: Microservices mimarisi benimsenecek, her servis belirli bir işlevselliği yerine getirecek ve bağımsız olarak geliştirilip dağıtılabilecektir.
*   **Veri Tutarlılığı**: Dağıtık sistemlerde veri tutarlılığı zorlukları göz önünde bulundurularak, eventual consistency (nihai tutarlılık) veya CRDT (Conflict-free Replicated Data Types) gibi yaklaşımlar benimsenecektir.

## Teknik Implementasyon Detayları

### Dağıtık Backend Mimarisi

*   **Microservices**: Her bir iş alanı (örneğin, mesaj yönlendirme, kimlik yönetimi, analitik) için ayrı microservices geliştirilecektir. Bu, esneklik, ölçeklenebilirlik ve hata izolasyonu sağlayacaktır.
*   **Containerized Deployment (Docker/Kubernetes)**: Servisler Docker konteynerleri içinde paketlenecek ve Kubernetes gibi bir orkestrasyon aracıyla yönetilecektir. Bu, dağıtım kolaylığı ve ölçeklenebilirlik sunacaktır.
*   **API Gateway**: Servislere gelen istekler için tek bir giriş noktası olarak API Gateway kullanılacaktır. Bu, trafik yönetimi, hız sınırlama ve kimlik doğrulama gibi işlevleri merkezi olarak yönetecek.
*   **Service Mesh (Istio/Linkerd)**: Servisler arası iletişimi yönetmek, güvenlik politikaları uygulamak ve gözlemlenebilirlik sağlamak için bir Service Mesh kullanılabilir.

### Core Servis Portföyü (Örnekler)

*   **Mesaj Röle Servisi (Message Relay Service)**: İnternet bağlantısı mevcut olduğunda, uzak mesh ağları arasında mesajları iletmek için bir köprü görevi görecektir. (Carrier WiFi Bridge stratejisi ile uyumlu).
*   **Kimlik ve Kimlik Doğrulama Servisi (Identity & Authentication Service)**: Gelişmiş kullanıcı kimlik yönetimi, cihaz kaydı ve biyometrik entegrasyon için kullanılabilir (isteğe bağlı).
*   **Analitik ve İzleme Servisi (Analytics & Monitoring Service)**: Ağ performansı metriklerini, kullanıcı davranışlarını ve acil durum yanıt verilerini toplamak ve analiz etmek için kullanılacaktır. Bu veriler, ağ optimizasyonu ve iyileştirme için kullanılacaktır.
*   **Bulut Röle Mimarisi (Cloud Relay Architecture)**: `doc/Stratejik Konular/Carrier WiFi Bridge/2c-Cloud-Relay-Architecture.md` belgesinde detaylandırılan bulut tabanlı mesaj röle sistemi, backend servislerinin önemli bir parçası olacaktır.

### Veri Yönetimi

*   **Dağıtık Veritabanları**: Her microservice kendi veritabanına sahip olabilir (örneğin, PostgreSQL, Apache Cassandra, Redis). Veri tutarlılığı için Saga Pattern veya Event Sourcing gibi dağıtık işlem desenleri kullanılabilir.
*   **Çok Katmanlı Önbellekleme (Multi-Level Caching)**: Performansı artırmak ve veritabanı yükünü azaltmak için Redis gibi dağıtık önbellek sistemleri kullanılacaktır.

### Güvenlik

*   **mTLS (Mutual TLS)**: Servisler arası iletişimi şifrelemek ve kimlik doğrulamak için kullanılacaktır.
*   **JWT (JSON Web Tokens)**: Kimlik doğrulama ve yetkilendirme için kullanılacaktır.
*   **PKI (Public Key Infrastructure)**: Sertifika yönetimi için kullanılacaktır.

### İzleme ve Gözlemlenebilirlik

*   **Metrikler, Loglar, İzler (Metrics, Logs, Traces)**: Prometheus, Grafana, ELK Stack (Elasticsearch, Logstash, Kibana) ve Jaeger gibi araçlarla sistemin gözlemlenebilirliği sağlanacaktır.
*   **Uyarı Sistemleri**: Performans düşüşleri, güvenlik ihlalleri veya servis kesintileri durumunda otomatik uyarılar tetiklenecektir.

## Geliştirmeye Başlarken

Backend servisleri implementasyon sürecine başlamadan önce `doc/Yazilim_Gelistirme_Asamalari/backend_servisleri.md` belgesini detaylıca incelemeniz önerilir. Bu belge, backend mimarisi, teknoloji yığını ve implementasyon detaylarını kapsamaktadır.

**Önemli Not**: Backend servisleri, projenin ana altyapı bağımsızlığı felsefesine uygun olarak, yalnızca ağın yeteneklerini genişletmek ve desteklemek amacıyla kullanılacaktır. Temel mesh network işlevselliği bu servislere bağımlı olmayacaktır.
