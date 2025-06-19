# Katman 2: Local Mesh Layer (Yerel Mesh Katmanı)

Bu belge, Infrastructure Layer'ın başarısız olması durumunda devreye giren Local Mesh Layer'ın detaylı analizi ve implementasyonunu içermektedir.

---

## 🌐 Local Mesh Layer Overview

### Katman Tanımı
```
Local Mesh Layer: Altyapı bağımsız, cihazlar arası direkt iletişim 
katmanı. Orta seviye bandwidth ve menzil, düşük güç tüketimi.

Öncelik: 2 (Orta-Yüksek)
Güvenilirlik: Orta-Yüksek (Cihaz yoğunluğuna bağlı)
Bandwidth: 1 kbps - 50 Mbps
Menzil: 1m - 200m
Aktivasyon: Infrastructure Layer failover sonrası
```

### Layer Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                   KATMAN 2: YEREL MESH                     │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ WiFi Direct │  │ Bluetooth LE │  │  NFC Relay Chain   │  │
│  │  Clusters   │  │    Mesh      │  │                    │  │
│  │ ┌─────────┐ │  │ ┌──────────┐ │  │ ┌────────────────┐ │  │
│  │ │P2P Groups│ │  │ │ BLE Mesh │ │  │ │ Proximity Relay│ │  │
│  │ │Hotspots  │ │  │ │ Beacons  │ │  │ │ Manual Transfer│ │  │
│  │ │Multi-hop │ │  │ │ Low Power│ │  │ │ Secure Exchange│ │  │
│  │ └─────────┘ │  │ └──────────┘ │  │ └────────────────┘ │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
        │                    │                    │
        ▼                    ▼                    ▼
   50-200m range        10-100m range         1-4cm range
   High bandwidth       Low power           Ultra secure
```

---

## 📶 WiFi Direct Clustering Strategy

### Advanced WiFi Direct Management
```javascript
class WiFiDirectMeshManager {
    constructor() {
        this.maxGroupSize = 8; // WiFi Direct limitation
        this.clusters = new Map();
        this.bridgeNodes = new Set();
        this.meshTopology = new MeshTopologyManager();
    }
    
    async initializeWiFiDirectMesh() {
        const nearbyDevices = await this.discoverWiFiDirectDevices();
        const clusters = await this.formOptimalClusters(nearbyDevices);
        
        return {
            totalDevices: nearbyDevices.length,
            clusters: clusters,
            bridgeNodes: await this.establishBridgeNodes(clusters),
            meshTopology: await this.createInterClusterMesh(clusters)
        };
    }
    
    async discoverWiFiDirectDevices() {
        const discoveryConfig = {
            discoveryTimeout: 30000, // 30 seconds
            deviceTypes: ['smartphone', 'tablet', 'laptop'],
            serviceTypes: ['emergency_mesh', 'general_mesh'],
            signalThreshold: -70 // dBm
        };
        
        const devices = await this.performWiFiDirectDiscovery(discoveryConfig);
        
        return await Promise.all(
            devices.map(async device => ({
                deviceId: device.id,
                deviceName: device.name,
                signalStrength: device.signalStrength,
                capabilities: await this.assessDeviceCapabilities(device),
                batteryLevel: await this.getBatteryLevel(device),
                meshExperience: await this.getMeshExperience(device),
                trustLevel: await this.calculateTrustLevel(device)
            }))
        );
    }
    
    async formOptimalClusters(devices) {
        // Clustering algorithm based on signal strength, battery, and capabilities
        const clusters = [];
        const availableDevices = [...devices];
        
        while (availableDevices.length > 0) {
            const clusterHead = this.selectClusterHead(availableDevices);
            const clusterMembers = this.selectClusterMembers(clusterHead, availableDevices);
            
            if (clusterMembers.length >= 2) { // Minimum viable cluster
                const cluster = await this.createWiFiDirectCluster({
                    head: clusterHead,
                    members: clusterMembers
                });
                
                clusters.push(cluster);
                
                // Remove clustered devices from available pool
                [clusterHead, ...clusterMembers].forEach(device => {
                    const index = availableDevices.findIndex(d => d.deviceId === device.deviceId);
                    if (index > -1) availableDevices.splice(index, 1);
                });
            } else {
                // Handle orphaned devices
                availableDevices.splice(
                    availableDevices.findIndex(d => d.deviceId === clusterHead.deviceId), 1
                );
            }
        }
        
        return clusters;
    }
    
    async createWiFiDirectCluster(clusterConfig) {
        const { head, members } = clusterConfig;
        
        // Set cluster head as Group Owner (GO)
        await this.setGroupOwner(head);
        
        // Connect members to the group
        const connections = await Promise.all(
            members.map(async member => ({
                device: member.deviceId,
                connection: await this.connectToGroup(member, head),
                role: 'group_client'
            }))
        );
        
        // Setup mesh routing within cluster
        await this.setupIntraClusterRouting({
            groupOwner: head,
            clients: connections
        });
        
        return {
            clusterId: this.generateClusterId(),
            groupOwner: head,
            members: connections,
            capacity: {
                maxDevices: this.maxGroupSize,
                currentDevices: connections.length + 1,
                availableSlots: this.maxGroupSize - connections.length - 1
            },
            performance: await this.measureClusterPerformance({head, members})
        };
    }
    
    async establishBridgeNodes(clusters) {
        if (clusters.length <= 1) return [];
        
        const bridgeNodes = [];
        
        // Find devices that can bridge between clusters
        for (let i = 0; i < clusters.length; i++) {
            for (let j = i + 1; j < clusters.length; j++) {
                const bridgeCandidates = await this.findBridgeCandidates(
                    clusters[i], clusters[j]
                );
                
                if (bridgeCandidates.length > 0) {
                    const optimalBridge = this.selectOptimalBridge(bridgeCandidates);
                    
                    await this.setupBridgeConnection({
                        bridge: optimalBridge,
                        cluster1: clusters[i],
                        cluster2: clusters[j]
                    });
                    
                    bridgeNodes.push({
                        bridgeDevice: optimalBridge,
                        connectedClusters: [clusters[i].clusterId, clusters[j].clusterId],
                        bridgeType: 'wifi_direct_bridge'
                    });
                }
            }
        }
        
        return bridgeNodes;
    }
}
```

### WiFi Direct Performance Optimization
```javascript
class WiFiDirectPerformanceOptimizer {
    constructor() {
        this.channelOptimizer = new ChannelOptimizer();
        this.powerManager = new WiFiPowerManager();
        this.trafficManager = new TrafficManager();
    }
    
    async optimizeClusterPerformance(cluster) {
        // Channel optimization to avoid interference
        const optimalChannel = await this.channelOptimizer.findOptimalChannel({
            currentChannel: cluster.channel,
            nearbyNetworks: await this.scanNearbyNetworks(),
            interferenceLevel: await this.measureInterference()
        });
        
        if (optimalChannel !== cluster.channel) {
            await this.switchChannel(cluster, optimalChannel);
        }
        
        // Power management optimization
        const powerSettings = await this.powerManager.calculateOptimalPower({
            clusterSize: cluster.members.length,
            signalRequirements: cluster.signalRequirements,
            batteryLevels: cluster.members.map(m => m.batteryLevel)
        });
        
        await this.applyPowerSettings(cluster, powerSettings);
        
        // Traffic management and QoS
        await this.trafficManager.setupQoS({
            cluster: cluster,
            priorityRules: this.getEmergencyPriorityRules(),
            bandwidthAllocation: this.calculateBandwidthAllocation(cluster)
        });
        
        return {
            channelOptimization: optimalChannel,
            powerOptimization: powerSettings,
            trafficOptimization: await this.getTrafficStats(cluster),
            expectedImprovement: this.calculatePerformanceImprovement(cluster)
        };
    }
    
    calculatePerformanceImprovement(cluster) {
        return {
            throughputIncrease: '15-30%',
            latencyReduction: '20-40%',
            powerSavings: '10-25%',
            reliabilityImprovement: '5-15%'
        };
    }
}
```

---

## 🔵 Bluetooth LE Mesh Integration

### Native Bluetooth Mesh Implementation
```javascript
class BluetoothLEMeshManager {
    constructor() {
        this.meshNetwork = new BluetoothMeshNetwork();
        this.beaconManager = new BLEBeaconManager();
        this.lowPowerManager = new BLELowPowerManager();
    }
    
    async initializeBluetoothMesh() {
        // Initialize native Bluetooth Mesh networking
        const meshConfig = {
            networkKey: await this.generateNetworkKey(),
            applicationKey: await this.generateApplicationKey(),
            deviceKey: await this.generateDeviceKey(),
            unicastAddress: await this.assignUnicastAddress(),
            features: {
                relay: true,
                proxy: true,
                friend: true,
                lowPower: false // Will be dynamically adjusted
            }
        };
        
        const meshNetwork = await this.meshNetwork.provision(meshConfig);
        
        return {
            networkId: meshNetwork.networkId,
            nodeAddress: meshNetwork.nodeAddress,
            subscriptions: await this.setupMeshSubscriptions(),
            publications: await this.setupMeshPublications(),
            neighbors: await this.discoverMeshNeighbors()
        };
    }
    
    async discoverMeshNeighbors() {
        const discoveryResults = await this.meshNetwork.performNodeDiscovery({
            discoveryTimeout: 60000, // 60 seconds for mesh discovery
            maxHops: 5,
            signalThreshold: -90 // dBm (more sensitive for BLE)
        });
        
        return await Promise.all(
            discoveryResults.map(async node => ({
                nodeId: node.unicastAddress,
                deviceName: await this.getNodeDeviceName(node),
                hopCount: node.hopCount,
                signalStrength: node.rssi,
                batteryLevel: await this.getNodeBatteryLevel(node),
                capabilities: await this.getNodeCapabilities(node),
                meshRole: this.determineMeshRole(node),
                reliability: await this.calculateNodeReliability(node)
            }))
        );
    }
    
    async setupMeshSubscriptions() {
        const subscriptions = [
            {
                address: 0xC000, // All-proxies group
                elementIndex: 0,
                modelId: 0x1000 // Generic OnOff Server
            },
            {
                address: 0xC001, // All-friends group  
                elementIndex: 0,
                modelId: 0x1001 // Generic Level Server
            },
            {
                address: 0xFFFF, // Emergency broadcast group
                elementIndex: 0,
                modelId: 0x1002 // Emergency Alert Model
            }
        ];
        
        await Promise.all(
            subscriptions.map(sub => this.meshNetwork.subscribe(sub))
        );
        
        return subscriptions;
    }
    
    async optimizeForLowPower() {
        const batteryLevel = await this.getBatteryLevel();
        
        if (batteryLevel < 20) {
            // Enable Low Power Node (LPN) feature
            await this.meshNetwork.enableLowPowerNode({
                pollInterval: 10000, // 10 seconds
                receivdeDelay: 100,   // 100ms
                subscriptionListSize: 5
            });
            
            // Find and establish friendship with Friend Node
            const friendNode = await this.findOptimalFriendNode();
            if (friendNode) {
                await this.establishFriendship(friendNode);
            }
            
            return {
                lowPowerEnabled: true,
                friendNode: friendNode?.nodeId,
                expectedBatteryExtension: '3-5x longer'
            };
        }
        
        return { lowPowerEnabled: false };
    }
}
```

### BLE Beacon Chain Implementation
```javascript
class BLEBeaconChainManager {
    constructor() {
        this.beaconTypes = ['iBeacon', 'Eddystone', 'AltBeacon'];
        this.chainManager = new BeaconChainManager();
    }
    
    async createBeaconChain() {
        const nearbyDevices = await this.discoverBLEDevices();
        const beaconCapableDevices = nearbyDevices.filter(d => d.beaconCapable);
        
        if (beaconCapableDevices.length < 2) {
            throw new Error('Insufficient beacon-capable devices for chain');
        }
        
        // Create beacon chain topology
        const chainTopology = this.calculateOptimalChainTopology(beaconCapableDevices);
        
        // Setup beacon relay protocol
        const beaconChain = await Promise.all(
            chainTopology.map(async (link, index) => ({
                linkId: index,
                transmitter: link.from,
                receiver: link.to,
                beaconConfig: await this.generateBeaconConfig(link),
                relayProtocol: await this.setupRelayProtocol(link)
            }))
        );
        
        return {
            chainLength: beaconChain.length,
            totalRange: this.calculateChainRange(beaconChain),
            relayNodes: beaconChain,
            redundancy: this.calculateChainRedundancy(beaconChain),
            latency: this.estimateChainLatency(beaconChain)
        };
    }
    
    async setupRelayProtocol(link) {
        const relayProtocol = {
            beaconInterval: 1000, // 1 second
            payloadSize: 20, // bytes (BLE advertisement limit)
            errorCorrection: 'hamming_code',
            acknowledgment: 'implicit', // Next beacon in chain
            retryMechanism: {
                maxRetries: 3,
                backoffStrategy: 'exponential'
            }
        };
        
        // Setup message fragmentation for larger payloads
        const fragmentationConfig = {
            maxFragmentSize: 18, // bytes (20 - 2 for headers)
            reassemblyTimeout: 30000, // 30 seconds
            sequenceNumbering: true
        };
        
        await this.configureBeaconRelay(link, relayProtocol, fragmentationConfig);
        
        return { relayProtocol, fragmentationConfig };
    }
}
```

---

## 📱 NFC Relay Chain

### Proximity-based Secure Communication
```javascript
class NFCRelayChainManager {
    constructor() {
        this.nfcManager = new NFCManager();
        this.securityManager = new NFCSecurityManager();
        this.relayProtocol = new NFCRelayProtocol();
    }
    
    async initializeNFCRelay() {
        const nfcCapability = await this.nfcManager.checkNFCCapability();
        
        if (!nfcCapability.available) {
            throw new Error('NFC not available on this device');
        }
        
        const nfcConfig = {
            mode: 'peer_to_peer', // P2P mode for device-to-device
            dataExchangeFormat: 'ndef', // NFC Data Exchange Format
            securityLevel: 'high',
            maxPayloadSize: 8192, // 8KB typical NFC limit
            proximityRequired: true // Physical proximity required
        };
        
        await this.nfcManager.initialize(nfcConfig);
        
        return {
            nfcEnabled: true,
            capabilities: nfcCapability,
            securityFeatures: await this.securityManager.getSecurityFeatures(),
            relayProtocol: await this.relayProtocol.initialize()
        };
    }
    
    async establishNFCRelay() {
        // Wait for another NFC-enabled device in proximity
        const proximateDevice = await this.waitForProximateDevice({
            discoveryTimeout: 30000, // 30 seconds
            signalStrength: 'immediate_proximity' // <4cm
        });
        
        if (!proximateDevice) {
            return { relayEstablished: false, reason: 'No proximate NFC device found' };
        }
        
        // Establish secure NFC connection
        const secureConnection = await this.securityManager.establishSecureConnection({
            remoteDevice: proximateDevice,
            authenticationMethod: 'mutual_authentication',
            encryptionLevel: 'aes_256'
        });
        
        // Setup relay protocol
        const relaySession = await this.relayProtocol.startSession({
            connection: secureConnection,
            relayMode: 'store_and_forward',
            maxMessages: 100,
            sessionTimeout: 300000 // 5 minutes
        });
        
        return {
            relayEstablished: true,
            relayPartner: proximateDevice.deviceId,
            securityLevel: secureConnection.securityLevel,
            sessionDetails: relaySession,
            transferCapability: this.calculateTransferCapability(relaySession)
        };
    }
    
    async performManualRelay(messages) {
        // Manual message relay via NFC touch
        const relayResults = [];
        
        for (const message of messages) {
            const relayAttempt = await this.attemptMessageRelay(message);
            relayResults.push({
                messageId: message.id,
                relaySuccess: relayAttempt.success,
                transferTime: relayAttempt.transferTime,
                dataIntegrity: relayAttempt.dataIntegrity
            });
            
            if (!relayAttempt.success) {
                // Retry mechanism for failed transfers
                const retryResult = await this.retryMessageRelay(message);
                relayResults[relayResults.length - 1].retryResult = retryResult;
            }
        }
        
        return {
            totalMessages: messages.length,
            successfulRelays: relayResults.filter(r => r.relaySuccess).length,
            failedRelays: relayResults.filter(r => !r.relaySuccess).length,
            averageTransferTime: this.calculateAverageTransferTime(relayResults),
            relayDetails: relayResults
        };
    }
}
```

### Ultra-secure Data Exchange
```javascript
class NFCSecurityManager {
    constructor() {
        this.cryptoEngine = new NFCCryptoEngine();
        this.authManager = new NFCAuthenticationManager();
    }
    
    async establishSecureConnection(options) {
        const { remoteDevice, authenticationMethod, encryptionLevel } = options;
        
        // Mutual authentication
        const authResult = await this.authManager.performMutualAuth({
            remoteDevice: remoteDevice,
            authMethod: authenticationMethod,
            challengeResponse: true
        });
        
        if (!authResult.authenticated) {
            throw new Error('NFC authentication failed');
        }
        
        // Key exchange via NFC
        const keyExchange = await this.cryptoEngine.performKeyExchange({
            method: 'ecdh', // Elliptic Curve Diffie-Hellman
            keySize: 256,
            remoteDevice: remoteDevice
        });
        
        // Establish encrypted channel
        const encryptedChannel = await this.cryptoEngine.createEncryptedChannel({
            sharedSecret: keyExchange.sharedSecret,
            encryptionAlgorithm: encryptionLevel,
            integrityProtection: 'hmac_sha256'
        });
        
        return {
            connectionId: this.generateConnectionId(),
            authenticated: true,
            encrypted: true,
            securityLevel: encryptionLevel,
            keyExchangeMethod: 'ecdh',
            integrityProtection: true,
            sessionKey: encryptedChannel.sessionKey
        };
    }
    
    async verifyDataIntegrity(data, integrityTag) {
        const computedTag = await this.cryptoEngine.computeHMAC(data);
        return computedTag === integrityTag;
    }
}
```

---

## 🔄 Layer 2 Coordination and Failover

### Inter-technology Coordination
```javascript
class LocalMeshCoordinator {
    constructor() {
        this.wifiDirectManager = new WiFiDirectMeshManager();
        this.bluetoothManager = new BluetoothLEMeshManager();
        this.nfcManager = new NFCRelayChainManager();
        this.coordinationEngine = new MeshCoordinationEngine();
    }
    
    async activateLocalMeshLayer() {
        console.log('🔄 Activating Local Mesh Layer...');
        
        // Parallel initialization of all mesh technologies
        const initResults = await Promise.allSettled([
            this.wifiDirectManager.initializeWiFiDirectMesh(),
            this.bluetoothManager.initializeBluetoothMesh(),
            this.nfcManager.initializeNFCRelay()
        ]);
        
        const availableTechnologies = this.processInitResults(initResults);
        
        if (availableTechnologies.length === 0) {
            throw new Error('No mesh technologies available');
        }
        
        // Select primary mesh technology
        const primaryMesh = this.selectPrimaryMeshTechnology(availableTechnologies);
        
        // Setup backup mesh technologies
        const backupMesh = this.setupBackupMeshTechnologies(
            availableTechnologies.filter(tech => tech !== primaryMesh)
        );
        
        // Coordinate between mesh technologies
        const coordination = await this.coordinationEngine.setupCoordination({
            primary: primaryMesh,
            backup: backupMesh,
            bridgingStrategy: 'transparent_bridging'
        });
        
        return {
            layerActive: true,
            primaryTechnology: primaryMesh.type,
            backupTechnologies: backupMesh.map(b => b.type),
            coordination: coordination,
            networkTopology: await this.generateNetworkTopology()
        };
    }
    
    selectPrimaryMeshTechnology(availableTechnologies) {
        // Selection criteria: capacity > range > power efficiency
        const selectionCriteria = [
            { tech: 'wifi_direct', score: this.calculateWiFiDirectScore() },
            { tech: 'bluetooth_mesh', score: this.calculateBluetoothScore() },
            { tech: 'nfc_relay', score: this.calculateNFCScore() }
        ];
        
        const bestOption = selectionCriteria
            .filter(criteria => availableTechnologies.some(tech => tech.type === criteria.tech))
            .sort((a, b) => b.score - a.score)[0];
        
        return availableTechnologies.find(tech => tech.type === bestOption.tech);
    }
    
    async handleMeshFailover(failedTechnology, availableBackups) {
        console.log(`🔄 Mesh failover from ${failedTechnology} initiated`);
        
        for (const backup of availableBackups) {
            try {
                const failoverResult = await this.attemptFailover({
                    from: failedTechnology,
                    to: backup
                });
                
                if (failoverResult.success) {
                    await this.migrateActiveConnections(failoverResult);
                    return {
                        failoverSuccess: true,
                        newPrimaryTechnology: backup.type,
                        migrationTime: failoverResult.migrationTime
                    };
                }
            } catch (error) {
                console.log(`Failover to ${backup.type} failed: ${error.message}`);
            }
        }
        
        return {
            failoverSuccess: false,
            recommendation: 'Activate Layer 3 (Extended Hardware)'
        };
    }
}
```

---

## 📊 Layer 2 Performance Metrics

### Quality Assurance and Monitoring
```javascript
class LocalMeshPerformanceMonitor {
    constructor() {
        this.metricsCollector = new MeshMetricsCollector();
        this.qualityAnalyzer = new MeshQualityAnalyzer();
    }
    
    async monitorLayerPerformance() {
        const metrics = await this.metricsCollector.collectMetrics();
        
        return {
            wifiDirectMetrics: {
                clusterCount: metrics.wifiDirect.clusters.length,
                averageClusterSize: metrics.wifiDirect.averageClusterSize,
                interClusterLatency: metrics.wifiDirect.interClusterLatency,
                throughput: metrics.wifiDirect.throughput
            },
            bluetoothMetrics: {
                meshNodeCount: metrics.bluetooth.nodeCount,
                hopCount: metrics.bluetooth.averageHopCount,
                powerConsumption: metrics.bluetooth.powerConsumption,
                reliability: metrics.bluetooth.reliability
            },
            nfcMetrics: {
                relayChainLength: metrics.nfc.chainLength,
                transferSuccessRate: metrics.nfc.transferSuccessRate,
                averageTransferTime: metrics.nfc.averageTransferTime,
                securityLevel: metrics.nfc.securityLevel
            },
            overallPerformance: this.calculateOverallPerformance(metrics)
        };
    }
}
```

### Success Criteria for Layer 2
- **WiFi Direct**: 3+ cihaz cluster, >10 Mbps throughput
- **Bluetooth LE**: <100mW power consumption, >95% message delivery
- **NFC Relay**: <4cm range, 100% data integrity
- **Coordination**: <5 second technology switching
- **Reliability**: >90% mesh network uptime

Bu Local Mesh Layer analizi, altyapı bağımsız iletişimin temelini oluşturur ve Cascading Network'ün ikinci savunma hattını sağlar.