# Katman 1: Infrastructure Layer (Altyapı Katmanı)

Bu belge, Cascading Network mimarisinin en üst katmanı olan Infrastructure Layer'ın detaylı analizi ve implementasyonunu içermektedir.

---

## 🏗️ Infrastructure Layer Overview

### Katman Tanımı
```
Infrastructure Layer: Mevcut telekomünikasyon altyapısını kullanan 
bağlantı yöntemleri. En yüksek bandwidth ve menzil sağlar, ancak 
dış faktörlere bağımlı.

Öncelik: 1 (En Yüksek)
Güvenilirlik: Yüksek (Normal şartlarda)
Bandwidth: 1 Mbps - 1 Gbps
Menzil: 1km - 100km+
```

### Layer Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    KATMAN 1: ALTYAPı                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │   Cellular  │  │     WiFi     │  │ Satellite/Emergency│  │
│  │   Network   │  │ Infrastructure│  │     Services       │  │
│  │ ┌─────────┐ │  │ ┌──────────┐ │  │ ┌────────────────┐ │  │
│  │ │  2G/3G  │ │  │ │ Public   │ │  │ │ Satellite SOS  │ │  │
│  │ │  4G/5G  │ │  │ │ Private  │ │  │ │ Ham Repeaters  │ │  │
│  │ │ eSIM    │ │  │ │ Municipal│ │  │ │ Emergency Freq │ │  │
│  │ └─────────┘ │  │ └──────────┘ │  │ └────────────────┘ │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📱 Cellular Network Assessment

### Comprehensive Cellular Testing
```javascript
class CellularInfrastructureManager {
    constructor() {
        this.networkTypes = ['2G', '3G', '4G', '5G'];
        this.carriers = ['TurkTelekom', 'Vodafone', 'TurkCell'];
        this.testSuite = new CellularTestSuite();
    }
    
    async performComprehensiveAssessment() {
        const assessmentResults = {
            primaryCarrier: await this.testPrimaryCarrier(),
            carrierAggregation: await this.testCarrierAggregation(),
            emergencyServices: await this.testEmergencyServices(),
            networkQuality: await this.assessNetworkQuality(),
            roamingCapability: await this.testRoamingCapability()
        };
        
        return this.generateRecommendations(assessmentResults);
    }
    
    async testPrimaryCarrier() {
        const currentCarrier = await this.getCurrentCarrier();
        
        const tests = [
            { 
                name: 'Data Connectivity',
                test: () => this.pingTest('8.8.8.8', 5000),
                threshold: 100 // ms
            },
            {
                name: 'Bandwidth Test', 
                test: () => this.bandwidthTest('https://speed.cloudflare.com'),
                threshold: 1000 // kbps
            },
            {
                name: 'Signal Strength',
                test: () => this.getSignalStrength(),
                threshold: -85 // dBm
            },
            {
                name: 'Network Latency',
                test: () => this.latencyTest('1.1.1.1'),
                threshold: 200 // ms
            }
        ];
        
        const results = await Promise.all(
            tests.map(async test => ({
                name: test.name,
                result: await test.test(),
                passed: await this.evaluateThreshold(test),
                timestamp: Date.now()
            }))
        );
        
        return {
            carrier: currentCarrier,
            networkType: await this.getNetworkType(),
            overallHealth: this.calculateOverallHealth(results),
            recommendations: this.generateCarrierRecommendations(results)
        };
    }
    
    async testCarrierAggregation() {
        // Test multiple carrier capability
        const availableCarriers = await this.scanAvailableCarriers();
        const aggregationResults = [];
        
        for (const carrier of availableCarriers) {
            try {
                const connectionTest = await this.testCarrierConnection(carrier);
                if (connectionTest.success) {
                    aggregationResults.push({
                        carrier: carrier.name,
                        signalStrength: carrier.signalStrength,
                        networkType: carrier.networkType,
                        roamingAllowed: carrier.roamingAllowed,
                        emergencyCapable: await this.testEmergencyCapability(carrier)
                    });
                }
            } catch (error) {
                console.log(`Carrier ${carrier.name} test failed: ${error.message}`);
            }
        }
        
        return {
            totalCarriers: aggregationResults.length,
            primaryRecommendation: this.selectPrimaryCarrier(aggregationResults),
            backupCarriers: this.selectBackupCarriers(aggregationResults),
            aggregationPossible: aggregationResults.length > 1
        };
    }
    
    async testEmergencyServices() {
        // Emergency services connectivity test
        const emergencyTests = [
            {
                service: '112', // European emergency
                test: 'connection_capability',
                priority: 1
            },
            {
                service: '911', // International roaming
                test: 'connection_capability', 
                priority: 2
            },
            {
                service: 'Cell Broadcast',
                test: 'reception_capability',
                priority: 3
            }
        ];
        
        const emergencyResults = await Promise.all(
            emergencyTests.map(async emergency => ({
                service: emergency.service,
                available: await this.testEmergencyConnection(emergency),
                latency: await this.measureEmergencyLatency(emergency),
                reliability: await this.assessEmergencyReliability(emergency)
            }))
        );
        
        return {
            emergencyCapable: emergencyResults.some(r => r.available),
            services: emergencyResults,
            overallReliability: this.calculateEmergencyReliability(emergencyResults)
        };
    }
}
```

### Signal Quality Metrics
```javascript
class SignalQualityAnalyzer {
    constructor() {
        this.qualityThresholds = {
            excellent: { rsrp: -80, rsrq: -10, sinr: 20 },
            good: { rsrp: -90, rsrq: -15, sinr: 13 },
            fair: { rsrp: -100, rsrq: -20, sinr: 0 },
            poor: { rsrp: -110, rsrq: -25, sinr: -6 }
        };
    }
    
    async analyzeSignalQuality() {
        const metrics = await this.getRFMetrics();
        
        const analysis = {
            rsrp: {
                value: metrics.rsrp,
                quality: this.classifyRSRP(metrics.rsrp),
                description: 'Reference Signal Received Power'
            },
            rsrq: {
                value: metrics.rsrq,
                quality: this.classifyRSRQ(metrics.rsrq),
                description: 'Reference Signal Received Quality'
            },
            sinr: {
                value: metrics.sinr,
                quality: this.classifySINR(metrics.sinr),
                description: 'Signal-to-Interference-plus-Noise Ratio'
            },
            overallQuality: this.calculateOverallQuality(metrics),
            predictedPerformance: this.predictPerformance(metrics),
            recommendations: this.generateSignalRecommendations(metrics)
        };
        
        return analysis;
    }
    
    predictPerformance(metrics) {
        // AI-based performance prediction
        const features = [
            metrics.rsrp, metrics.rsrq, metrics.sinr,
            metrics.cellId, metrics.bandWidth, metrics.networkLoad
        ];
        
        return {
            expectedThroughput: this.predictThroughput(features),
            connectionStability: this.predictStability(features), 
            failoverProbability: this.predictFailover(features),
            optimizationSuggestions: this.generateOptimizations(features)
        };
    }
}
```

---

## 🌐 WiFi Infrastructure Management

### WiFi Network Discovery and Assessment
```javascript
class WiFiInfrastructureManager {
    constructor() {
        this.networkTypes = {
            public: ['free', 'captive_portal', 'sponsored'],
            private: ['wpa2', 'wpa3', 'enterprise'],
            municipal: ['city_wifi', 'transport_wifi', 'education'],
            carrier: ['carrier_offload', 'carrier_hotspot']
        };
    }
    
    async discoverWiFiInfrastructure() {
        const discoveredNetworks = await this.scanWiFiNetworks();
        const categorizedNetworks = this.categorizeNetworks(discoveredNetworks);
        
        const assessmentResults = await Promise.all(
            Object.entries(categorizedNetworks).map(async ([category, networks]) => ({
                category,
                networks: await this.assessNetworkCategory(networks),
                totalCount: networks.length,
                averageQuality: this.calculateAverageQuality(networks),
                accessibilityScore: await this.calculateAccessibility(networks)
            }))
        );
        
        return {
            totalNetworks: discoveredNetworks.length,
            categories: assessmentResults,
            recommendations: this.generateWiFiRecommendations(assessmentResults),
            priorityConnections: this.selectPriorityConnections(assessmentResults)
        };
    }
    
    async assessNetworkCategory(networks) {
        return await Promise.all(
            networks.map(async network => ({
                ssid: network.ssid,
                signalStrength: network.signalStrength,
                security: network.security,
                bandwidth: await this.estimateBandwidth(network),
                accessibility: await this.assessAccessibility(network),
                reliability: await this.assessReliability(network),
                cost: this.calculateCost(network),
                meshCompatibility: this.assessMeshCompatibility(network)
            }))
        );
    }
    
    async establishOptimalWiFiConnection(priorityNetworks) {
        for (const network of priorityNetworks) {
            try {
                const connectionResult = await this.attemptConnection(network);
                
                if (connectionResult.success) {
                    const qualityCheck = await this.performQualityCheck(network);
                    
                    if (qualityCheck.acceptable) {
                        await this.setupMeshBridge(network);
                        return {
                            connected: true,
                            network: network.ssid,
                            quality: qualityCheck,
                            meshBridgeActive: true
                        };
                    }
                }
            } catch (error) {
                console.log(`WiFi connection failed for ${network.ssid}: ${error.message}`);
            }
        }
        
        return { connected: false, reason: 'No suitable WiFi infrastructure found' };
    }
}
```

### Municipal and Public WiFi Integration
```javascript
class PublicWiFiIntegrator {
    constructor() {
        this.municipalNetworks = {
            istanbul: ['IBB-WiFi', 'Istanbul-WiFi', 'Metro-WiFi'],
            ankara: ['Ankara-Belediye', 'Anka-WiFi'],
            izmir: ['IzmirBB-WiFi', 'Izmir-Free']
        };
        
        this.transportNetworks = {
            metro: ['Metro-WiFi', 'UlasimWiFi'],
            bus: ['IETT-WiFi', 'OtobusBB'],
            ferry: ['IDO-WiFi', 'Vapur-Net'],
            airport: ['TAV-Free', 'DHMi-WiFi']
        };
    }
    
    async integrateMunicipalWiFi() {
        const currentCity = await this.detectCurrentCity();
        const availableNetworks = this.municipalNetworks[currentCity] || [];
        
        const integrationResults = await Promise.all(
            availableNetworks.map(async network => ({
                network,
                available: await this.checkNetworkAvailability(network),
                authMethod: await this.detectAuthMethod(network),
                quality: await this.assessNetworkQuality(network),
                coverage: await this.mapNetworkCoverage(network)
            }))
        );
        
        return {
            city: currentCity,
            municipalNetworks: integrationResults,
            bestOptions: this.selectBestMunicipalOptions(integrationResults),
            fallbackStrategy: this.createFallbackStrategy(integrationResults)
        };
    }
}
```

---

## 🛰️ Satellite and Emergency Services

### Satellite Communication Integration
```javascript
class SatelliteEmergencyManager {
    constructor() {
        this.satelliteServices = {
            consumer: [
                { 
                    name: 'iPhone 14+ Emergency SOS',
                    availability: 'limited_regions',
                    capability: 'emergency_only',
                    cost: 'included'
                },
                {
                    name: 'Garmin inReach',
                    availability: 'global',
                    capability: 'two_way_messaging',
                    cost: 'subscription_required'
                }
            ],
            professional: [
                {
                    name: 'Iridium PTT',
                    availability: 'global',
                    capability: 'voice_data',
                    cost: 'high'
                },
                {
                    name: 'Thuraya',
                    availability: 'regional',
                    capability: 'voice_data_gps',
                    cost: 'medium'
                }
            ]
        };
    }
    
    async assessSatelliteCapability() {
        const deviceCapabilities = await this.scanDeviceCapabilities();
        const availableServices = this.filterAvailableServices(deviceCapabilities);
        
        const assessmentResults = await Promise.all(
            availableServices.map(async service => ({
                service: service.name,
                status: await this.testServiceStatus(service),
                signalQuality: await this.measureSatelliteSignal(service),
                latency: await this.measureSatelliteLatency(service),
                cost: this.calculateServiceCost(service),
                meshIntegration: this.assessMeshIntegration(service)
            }))
        );
        
        return {
            totalServices: assessmentResults.length,
            activeServices: assessmentResults.filter(s => s.status === 'active'),
            recommendations: this.generateSatelliteRecommendations(assessmentResults),
            emergencyProcedures: this.defineSatelliteEmergencyProcedures()
        };
    }
    
    async activateEmergencySatellite() {
        const emergencyServices = await this.getEmergencyServices();
        
        for (const service of emergencyServices) {
            try {
                const activation = await this.activateService(service);
                
                if (activation.success) {
                    await this.setupEmergencyProtocol(service);
                    return {
                        activated: true,
                        service: service.name,
                        capabilities: service.capabilities,
                        estimatedCost: service.cost,
                        emergencyProcedures: activation.procedures
                    };
                }
            } catch (error) {
                console.log(`Satellite service ${service.name} activation failed: ${error.message}`);
            }
        }
        
        return { activated: false, reason: 'No satellite services available' };
    }
}
```

### Ham Radio Repeater Networks
```javascript
class HamRepeaterManager {
    constructor() {
        this.repeaterDatabase = new HamRepeaterDatabase();
        this.frequencyBands = {
            vhf: { range: [144, 148], typical: 145.5 },
            uhf: { range: [430, 440], typical: 435.0 },
            hf: { range: [14, 14.35], typical: 14.205 }
        };
    }
    
    async discoverNearbyRepeaters() {
        const currentLocation = await this.getCurrentLocation();
        const nearbyRepeaters = await this.repeaterDatabase.findNearby(currentLocation, 50); // 50km radius
        
        const repeaterAssessment = await Promise.all(
            nearbyRepeaters.map(async repeater => ({
                callSign: repeater.callSign,
                frequency: repeater.frequency,
                distance: this.calculateDistance(currentLocation, repeater.location),
                signalPrediction: await this.predictSignalStrength(repeater),
                operationalStatus: await this.checkRepeaterStatus(repeater),
                emergencyCapable: repeater.emergencyNet,
                meshCompatibility: this.assessMeshCompatibility(repeater)
            }))
        );
        
        return {
            totalRepeaters: repeaterAssessment.length,
            operationalRepeaters: repeaterAssessment.filter(r => r.operationalStatus),
            emergencyRepeaters: repeaterAssessment.filter(r => r.emergencyCapable),
            recommendations: this.generateRepeaterRecommendations(repeaterAssessment)
        };
    }
}
```

---

## 🔄 Infrastructure Layer Failover Logic

### Intelligent Infrastructure Selection
```javascript
class InfrastructureLayerManager {
    constructor() {
        this.cellularManager = new CellularInfrastructureManager();
        this.wifiManager = new WiFiInfrastructureManager();
        this.satelliteManager = new SatelliteEmergencyManager();
        this.hamManager = new HamRepeaterManager();
    }
    
    async selectOptimalInfrastructure() {
        // Parallel assessment of all infrastructure options
        const [cellular, wifi, satellite, ham] = await Promise.all([
            this.cellularManager.performComprehensiveAssessment(),
            this.wifiManager.discoverWiFiInfrastructure(),
            this.satelliteManager.assessSatelliteCapability(),
            this.hamManager.discoverNearbyRepeaters()
        ]);
        
        // Multi-criteria decision making
        const options = this.evaluateInfrastructureOptions({
            cellular, wifi, satellite, ham
        });
        
        // Select primary and backup infrastructure
        const selection = {
            primary: this.selectPrimaryInfrastructure(options),
            secondary: this.selectSecondaryInfrastructure(options),
            emergency: this.selectEmergencyInfrastructure(options),
            failoverPlan: this.createFailoverPlan(options)
        };
        
        return selection;
    }
    
    async executeInfrastructureFailover(currentInfrastructure, failureReason) {
        console.log(`Infrastructure failover triggered: ${failureReason}`);
        
        const failoverPlan = await this.getFailoverPlan(currentInfrastructure);
        
        for (const fallbackOption of failoverPlan) {
            try {
                const connectionResult = await this.attemptConnection(fallbackOption);
                
                if (connectionResult.success) {
                    await this.migrateActiveConnections(fallbackOption);
                    return {
                        success: true,
                        newInfrastructure: fallbackOption.name,
                        migrationTime: connectionResult.migrationTime,
                        qualityAssessment: connectionResult.quality
                    };
                }
            } catch (error) {
                console.log(`Failover to ${fallbackOption.name} failed: ${error.message}`);
            }
        }
        
        return {
            success: false,
            reason: 'All infrastructure options exhausted',
            recommendation: 'Activate Layer 2 (Local Mesh)'
        };
    }
}
```

---

## 📊 Performance Monitoring and Optimization

### Real-time Infrastructure Health Monitoring
```javascript
class InfrastructureHealthMonitor {
    constructor() {
        this.monitoringInterval = 5000; // 5 seconds
        this.healthThresholds = {
            excellent: { latency: 50, packetLoss: 0.1, throughput: 0.9 },
            good: { latency: 100, packetLoss: 1, throughput: 0.7 },
            fair: { latency: 200, packetLoss: 3, throughput: 0.5 },
            poor: { latency: 500, packetLoss: 5, throughput: 0.3 }
        };
    }
    
    startContinuousMonitoring() {
        setInterval(async () => {
            const healthMetrics = await this.collectHealthMetrics();
            const healthAssessment = this.assessHealth(healthMetrics);
            
            if (healthAssessment.requiresAction) {
                await this.handleHealthDegradation(healthAssessment);
            }
            
            this.updateHealthDashboard(healthAssessment);
        }, this.monitoringInterval);
    }
    
    async collectHealthMetrics() {
        return {
            latency: await this.measureLatency(),
            packetLoss: await this.measurePacketLoss(),
            throughput: await this.measureThroughput(),
            signalStrength: await this.measureSignalStrength(),
            connectionStability: await this.assessConnectionStability(),
            timestamp: Date.now()
        };
    }
    
    async handleHealthDegradation(assessment) {
        const degradationLevel = assessment.degradationLevel;
        
        switch (degradationLevel) {
            case 'minor':
                await this.performOptimization();
                break;
            case 'moderate':
                await this.prepareBackupInfrastructure();
                break;
            case 'severe':
                await this.initiateFailover();
                break;
            case 'critical':
                await this.activateEmergencyProtocols();
                break;
        }
    }
}
```

---

## 🎯 Layer 1 Success Metrics

### Key Performance Indicators
- **Connection Establishment**: <10 seconds
- **Bandwidth Utilization**: >70% of theoretical maximum
- **Reliability Score**: >95% uptime
- **Failover Detection**: <5 seconds
- **Quality Degradation Response**: <15 seconds

### Quality Assurance
- **Signal Strength**: >-85 dBm (cellular), >-70 dBm (WiFi)
- **Latency**: <100ms (local), <200ms (internet)
- **Packet Loss**: <1%
- **Jitter**: <10ms
- **Availability**: 99.9% (target)

Bu Infrastructure Layer analizi, Cascading Network'ün temel katmanını oluşturur ve tüm üst seviye iletişim gereksinimlerini karşılamayı hedefler.