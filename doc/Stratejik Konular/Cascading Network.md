# Cascading Network: Çok Katmanlı Failover Stratejisi

Bu belge, acil durum mesh network için çok katmanlı, otomatik failover özellikli kademeli ağ mimarisini detaylı olarak analiz etmektedir.

---

## 🏗️ Katmanlı Network Architecture

### 3-Tier Cascading Model
```
┌─────────────────────────────────────────────────────────────┐
│                    KATMAN 1: ALTYAPı                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │   Cellular  │  │     WiFi     │  │ Satellite/Emergency│  │
│  │   Network   │  │ Infrastructure│  │     Services       │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   KATMAN 2: YEREL MESH                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ WiFi Direct │  │ Bluetooth LE │  │  NFC Relay Chain   │  │
│  │  Clusters   │  │    Mesh      │  │                    │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│               KATMAN 3: GENİŞLETİLMİŞ DONANIM               │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ SDR Dongles │  │ LoRa Modules │  │ Ham Radio & Zigbee │  │
│  │             │  │              │  │   Integration      │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Otomatik Failover Mekanizması

### Connection Priority Strategy
```javascript
class CascadingNetworkManager {
    constructor() {
        this.networkLayers = [
            {
                name: 'Infrastructure Layer',
                priority: 1,
                connections: ['cellular', 'wifi', 'satellite'],
                fallback: 'Local Mesh Layer'
            },
            {
                name: 'Local Mesh Layer',
                priority: 2,
                connections: ['wifi-direct', 'bluetooth-le', 'nfc'],
                fallback: 'Extended Hardware Layer'
            },
            {
                name: 'Extended Hardware Layer',
                priority: 3,
                connections: ['sdr', 'lora', 'ham-radio', 'zigbee'],
                fallback: 'Manual Relay'
            },
            {
                name: 'Manual Relay',
                priority: 4,
                connections: ['human-courier', 'visual-signals'],
                fallback: null
            }
        ];
    }
    
    async establishConnection() {
        for (const layer of this.networkLayers) {
            console.log(`🔍 ${layer.name} test ediliyor...`);
            
            for (const connection of layer.connections) {
                try {
                    const success = await this.testConnection(connection);
                    if (success) {
                        console.log(`✅ ${connection} başarılı bağlantı`);
                        await this.activateConnection(connection);
                        await this.prepareBackupLayers(layer.fallback);
                        return { layer: layer.name, connection };
                    }
                } catch (error) {
                    console.log(`❌ ${connection} başarısız: ${error.message}`);
                }
            }
            
            console.log(`🔄 ${layer.fallback || 'Son katman'} katmanına geçiliyor...`);
        }
        
        throw new Error('Hiçbir iletişim kanalı kurulamadı');
    }
}
```

### Katman 1: Altyapı Kontrol (Infrastructure Layer)

#### **Cellular Network Assessment**
```javascript
async testCellularCapability() {
    const tests = [
        { method: 'ping', target: '8.8.8.8', timeout: 5000 },
        { method: 'dataConnectivity', provider: 'current' },
        { method: 'emergencyServices', number: '112' },
        { method: 'carrierAggregation', providers: ['all'] }
    ];
    
    for (const test of tests) {
        const result = await this.runConnectivityTest(test);
        if (result.success) {
            return {
                available: true,
                quality: result.quality,
                method: test.method,
                fallbackOptions: result.alternatives
            };
        }
    }
    
    return { available: false, reason: 'No cellular connectivity' };
}
```

#### **WiFi Infrastructure Setup**
- Internet erişimi olan router'lar
- Corporate/enterprise WiFi networks
- Public WiFi hotspots
- Municipal WiFi infrastructure

#### **Satellite/Emergency Fallback**
- iPhone 14+ satellite emergency
- Dedicated satellite communicators
- Ham radio repeater networks
- Emergency service coordination

### Katman 2: Yerel Mesh Network

#### **WiFi Direct Clustering Strategy**
```javascript
async establishWiFiDirectCluster() {
    const nearbyDevices = await this.discoverWiFiDirectDevices();
    
    if (nearbyDevices.length >= 3) {
        // 3+ cihaz varsa cluster oluştur
        const cluster = await this.createWiFiDirectCluster(nearbyDevices);
        return {
            type: 'wifi-direct-cluster',
            capacity: 'high',
            range: '50-200m',
            devices: nearbyDevices.length
        };
    }
    
    // Fallback to Bluetooth LE
    throw new Error('Insufficient devices for WiFi Direct cluster');
}
```

#### **Bluetooth LE Mesh Integration**
- Native Bluetooth Mesh protocol
- iBeacon/Eddystone relay chains
- Ultra-low power operation
- Universal device compatibility

#### **NFC Relay Chain**
- Ultra-short range (1-4cm)
- Manual device-to-device transfer
- Secure data exchange
- Battery-free operation capability

### Katman 3: Genişletilmiş Donanım

#### **SDR Dongle Configuration**
```javascript
class SDRIntegration {
    async configureSDRDongle() {
        const supportedSDRs = [
            { model: 'RTL-SDR', price: '$20-50', capability: 'RX-only' },
            { model: 'HackRF', price: '$300-400', capability: 'TX/RX' },
            { model: 'LimeSDR', price: '$200-300', capability: 'TX/RX' },
            { model: 'USRP', price: '$1000+', capability: 'Professional' }
        ];
        
        const detectedSDR = await this.detectConnectedSDR();
        if (detectedSDR) {
            await this.configureDSP(detectedSDR);
            await this.loadFrequencyProfiles(detectedSDR);
            return await this.establishSDRMesh(detectedSDR);
        }
        
        throw new Error('No SDR hardware detected');
    }
}
```

#### **LoRa/LoRaWAN Modules**
- ESP32-LoRa integration ($10-20)
- 2-15km range capability
- 20-100mW low power consumption
- IoT protocol compatibility

#### **Ham Radio Integration**
- VHF/UHF transceivers (Baofeng UV-5R)
- HF all-mode radios (FT-818)
- Digital modes (FT8, VARA, Winlink)
- Global emergency frequency networks

---

## ⚡ Dynamic Failover Scenarios

### Scenario 1: Infrastructure Degradation
```
Initial: Cellular network active
Event: Network overload/partial failure
Action:
1. Detect performance degradation (latency >2s, packet loss >10%)
2. Prepare WiFi infrastructure backup
3. Initiate local mesh network setup
4. Graceful transition to hybrid mode
5. Cache critical messages for later transmission

Timeline: 10-30 seconds transition
```

### Scenario 2: Complete Infrastructure Loss
```
Initial: All infrastructure networks down
Event: Major disaster/EMP/cyber attack
Action:
1. Immediate local mesh activation
2. WiFi Direct cluster formation
3. Bluetooth LE mesh backup
4. SDR frequency scanning (if available)
5. Manual relay protocol activation

Timeline: 30-60 seconds full mesh deployment
```

### Scenario 3: Gradual Service Restoration
```
Initial: Pure mesh network operation
Event: Partial infrastructure restoration
Action:
1. Infrastructure quality monitoring
2. Hybrid operation initiation
3. Message queue synchronization
4. Load balancing optimization
5. Redundant connection maintenance

Timeline: Real-time adaptation
```

---

## 📊 Redundancy & Quality Management

### Multi-Interface Simultaneous Operation
```javascript
class RedundantConnectionManager {
    async manageMultipleConnections() {
        const activeConnections = await this.getAllActiveConnections();
        
        // Primary: En yüksek quality connection
        const primary = this.selectPrimaryConnection(activeConnections);
        
        // Secondary: Backup connections ready
        const backups = this.prepareBackupConnections(activeConnections);
        
        // Quality monitoring
        this.startQualityMonitoring(primary, backups);
        
        // Load balancing for non-critical traffic
        this.enableLoadBalancing([primary, ...backups]);
        
        return {
            primary: primary.interface,
            backups: backups.map(b => b.interface),
            totalBandwidth: this.calculateTotalBandwidth(activeConnections)
        };
    }
}
```

### Network Health Monitoring
- **Real-time Latency**: <100ms good, >500ms trigger failover
- **Packet Loss Rate**: <1% good, >5% trigger failover
- **Bandwidth Throughput**: Minimum 1 kbps for basic messaging
- **Connection Stability**: 95%+ uptime target

---

## 🎯 Adaptive Behavior Patterns

### Traffic-based Layer Selection
```
Low Priority (News, Updates):
└── Use lowest priority available connection

Medium Priority (Personal Messages):
└── Use primary connection with backup ready

High Priority (Emergency SOS):
└── Broadcast on all available connections simultaneously

Critical Priority (Life/Death):
└── All channels + manual relay + visual signals
```

### Power Management Integration
- **High Battery**: All layers active, maximum redundancy
- **Medium Battery**: Priority layers only, background monitoring
- **Low Battery**: Single most efficient connection
- **Critical Battery**: Emergency broadcast only, then standby

### Geographic Adaptation
- **Urban Dense**: Focus on WiFi Direct clusters, carrier bridge
- **Suburban**: Hybrid mesh with infrastructure backup
- **Rural**: SDR/LoRa emphasis, ham radio integration
- **Remote**: Satellite backup, manual relay preparation

---

## 🚀 Advanced Features

### AI-Powered Layer Selection
```javascript
class IntelligentLayerSelector {
    constructor() {
        this.mlModel = new NetworkQualityPredictor();
        this.historicalData = new ConnectionHistory();
    }
    
    async predictOptimalLayer(context) {
        const features = {
            location: context.gpsCoordinates,
            timeOfDay: context.timestamp,
            deviceDensity: context.nearbyDevices,
            networkHistory: this.historicalData.getRecentPatterns(),
            emergencyLevel: context.urgency
        };
        
        const prediction = await this.mlModel.predict(features);
        return this.selectLayerBasedOnPrediction(prediction);
    }
}
```

### Mesh Network Healing
- **Auto-detection**: Kopuk bağlantıları otomatik tespit
- **Route Recalculation**: Alternative path finding
- **Node Replacement**: Failed node'lar için replacement strategy
- **Topology Optimization**: Network efficiency iyileştirme

Bu cascading network stratejisi, acil durumlarda maksimum güvenilirlik ve esneklik sağlamak için çok katmanlı, otomatik failover özellikli bir ağ mimarisi sunmaktadır.