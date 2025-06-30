import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, interval, merge } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged } from 'rxjs/operators';

import { WebrtcService } from './webrtc.service';
import { LocationService } from './location.service';
import { MessagingService } from './messaging.service';
import { CryptoService } from './crypto.service';
import { AnalyticsService } from './analytics.service';

export interface MeshNode {
  id: string;
  deviceType: 'smartphone' | 'tablet' | 'laptop' | 'iot';
  capabilities: string[];
  location?: {
    latitude: number;
    longitude: number;
    accuracy: number;
    timestamp: number;
  };
  batteryLevel: number;
  signalStrength: number;
  connectionType: 'wifi-direct' | 'bluetooth' | 'hotspot' | 'hybrid';
  isRelay: boolean;
  connectedPeers: string[];
  lastSeen: number;
  emergencyRole: 'coordinator' | 'relay' | 'endpoint' | 'bridge';
}

export interface EmergencyNetwork {
  id: string;
  name: string;
  centerLocation: {
    latitude: number;
    longitude: number;
  };
  radius: number; // meters
  nodeCount: number;
  activeNodes: MeshNode[];
  networkHealth: number; // 0-100
  coverageArea: number; // square meters
  messagesThroughput: number;
  emergencyLevel: 'green' | 'yellow' | 'orange' | 'red';
  createdAt: number;
  lastActivity: number;
}

export interface CityWideEmergencyScenario {
  scenarioId: string;
  cityName: string;
  disasterType: 'earthquake' | 'flood' | 'fire' | 'blackout' | 'cyberattack';
  affectedArea: {
    center: { latitude: number; longitude: number };
    radius: number;
  };
  infrastructureStatus: {
    cellularTowers: number; // percentage working
    internetBackbone: number;
    powerGrid: number;
    emergencyServices: number;
  };
  populationDensity: number; // people per km²
  estimatedDevices: number;
  timeElapsed: number; // minutes since disaster
  networks: EmergencyNetwork[];
}

@Injectable({
  providedIn: 'root'
})
export class EmergencyMeshCoordinatorService {
  private webrtcService = inject(WebrtcService);
  private locationService = inject(LocationService);
  private messagingService = inject(MessagingService);
  private cryptoService = inject(CryptoService);
  private analyticsService = inject(AnalyticsService);

  // Signals for reactive emergency coordination
  private _currentScenario = signal<CityWideEmergencyScenario | null>(null);
  private _localNode = signal<MeshNode | null>(null);
  private _discoveredNodes = signal<MeshNode[]>([]);
  private _activeNetworks = signal<EmergencyNetwork[]>([]);
  private _isEmergencyCoordinator = signal<boolean>(false);

  // Computed emergency metrics
  currentScenario = this._currentScenario.asReadonly();
  localNode = this._localNode.asReadonly();
  discoveredNodes = this._discoveredNodes.asReadonly();
  activeNetworks = this._activeNetworks.asReadonly();
  isEmergencyCoordinator = this._isEmergencyCoordinator.asReadonly();

  totalNetworkCoverage = computed(() => {
    const networks = this._activeNetworks();
    return networks.reduce((total, network) => total + network.coverageArea, 0);
  });

  estimatedReachablePopulation = computed(() => {
    const scenario = this._currentScenario();
    if (!scenario) return 0;
    
    const coverage = this.totalNetworkCoverage();
    const density = scenario.populationDensity;
    return Math.floor((coverage / 1000000) * density); // coverage in km², density per km²
  });

  networkEfficiency = computed(() => {
    const networks = this._activeNetworks();
    if (networks.length === 0) return 0;
    
    const avgHealth = networks.reduce((sum, net) => sum + net.networkHealth, 0) / networks.length;
    const nodeUtilization = this.calculateNodeUtilization();
    return Math.round((avgHealth + nodeUtilization) / 2);
  });

  // Emergency coordination subjects
  private emergencyNetworkFormed$ = new BehaviorSubject<EmergencyNetwork | null>(null);
  private cityWideCoordinationEstablished$ = new BehaviorSubject<boolean>(false);
  private massEvacuationCoordinated$ = new BehaviorSubject<string | null>(null);

  constructor() {
    this.initializeEmergencyCoordination();
    this.setupAutomaticNetworkFormation();
    this.startCityWideCoordination();
  }

  // SENARYO: İstanbul 7.2 Deprem - Baz İstasyonları %95 Çökmüş
  async simulateIstanbulEarthquakeScenario(): Promise<void> {
    const istanbulScenario: CityWideEmergencyScenario = {
      scenarioId: 'istanbul_earthquake_2024',
      cityName: 'İstanbul',
      disasterType: 'earthquake',
      affectedArea: {
        center: { latitude: 41.0082, longitude: 28.9784 }, // İstanbul merkez
        radius: 50000 // 50km radius
      },
      infrastructureStatus: {
        cellularTowers: 5, // %95 çökmüş
        internetBackbone: 10, // %90 çökmüş
        powerGrid: 30, // %70 çökmüş
        emergencyServices: 60 // %40 çökmüş
      },
      populationDensity: 2976, // İstanbul yoğunluğu (kişi/km²)
      estimatedDevices: 12000000, // 12 milyon cihaz
      timeElapsed: 0,
      networks: []
    };

    this._currentScenario.set(istanbulScenario);
    
    // Otomatik mesh network oluşturma başlat
    await this.initiateEmergencyMeshFormation();
    
    // Şehir çapında koordinasyon protokolü başlat
    await this.startCityWideEmergencyProtocol();
    
    this.analyticsService.trackEmergencyActivation('earthquake', 'critical');
  }

  // Otomatik Mesh Network Oluşturma
  private async initiateEmergencyMeshFormation(): Promise<void> {
    // 1. Yerel cihazı emergency node olarak yapılandır
    await this.configureAsEmergencyNode();
    
    // 2. Yakındaki cihazları keşfet (WiFi Direct + Bluetooth)
    await this.discoverNearbyEmergencyDevices();
    
    // 3. En uygun cihazları seç ve bağlan
    await this.establishEmergencyConnections();
    
    // 4. Mesh network topolojisini optimize et
    await this.optimizeMeshTopology();
    
    // 5. Şehir çapında koordinasyon için bridge node'ları belirle
    await this.establishCityWideBridges();
  }

  private async configureAsEmergencyNode(): Promise<void> {
    const location = await this.locationService.getCurrentLocation();
    const deviceInfo = this.getDeviceCapabilities();
    
    const localNode: MeshNode = {
      id: this.generateNodeId(),
      deviceType: this.detectDeviceType(),
      capabilities: this.getEmergencyCapabilities(),
      location: location ? {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy,
        timestamp: Date.now()
      } : undefined,
      batteryLevel: await this.getBatteryLevel(),
      signalStrength: 100,
      connectionType: 'hybrid',
      isRelay: this.shouldActAsRelay(),
      connectedPeers: [],
      lastSeen: Date.now(),
      emergencyRole: this.determineEmergencyRole()
    };

    this._localNode.set(localNode);
    
    // Emergency mode'da cihazı optimize et
    await this.optimizeForEmergency();
  }

  private async discoverNearbyEmergencyDevices(): Promise<void> {
    // WiFi Direct ile yakın cihazları keşfet
    const wifiDirectDevices = await this.discoverWiFiDirectDevices();
    
    // Bluetooth ile yakın cihazları keşfet
    const bluetoothDevices = await this.discoverBluetoothDevices();
    
    // Hotspot olarak çalışan cihazları keşfet
    const hotspotDevices = await this.discoverHotspotDevices();
    
    // Tüm keşfedilen cihazları birleştir
    const allDevices = [...wifiDirectDevices, ...bluetoothDevices, ...hotspotDevices];
    
    // Emergency capability'si olan cihazları filtrele
    const emergencyDevices = allDevices.filter(device => 
      device.capabilities.includes('emergency-mesh')
    );
    
    this._discoveredNodes.set(emergencyDevices);
  }

  private async establishEmergencyConnections(): Promise<void> {
    const discoveredNodes = this._discoveredNodes();
    const localNode = this._localNode();
    
    if (!localNode) return;

    // En uygun node'ları seç (mesafe, pil, sinyal gücü)
    const prioritizedNodes = this.prioritizeNodesForConnection(discoveredNodes);
    
    // Maksimum 8 bağlantı kur (performans için)
    const targetConnections = Math.min(prioritizedNodes.length, 8);
    
    for (let i = 0; i < targetConnections; i++) {
      const targetNode = prioritizedNodes[i];
      
      try {
        const connected = await this.connectToEmergencyNode(targetNode);
        if (connected) {
          localNode.connectedPeers.push(targetNode.id);
          
          // İlk bağlantıda emergency handshake yap
          await this.performEmergencyHandshake(targetNode);
        }
      } catch (error) {
        console.error(`Failed to connect to emergency node ${targetNode.id}:`, error);
      }
    }
    
    this._localNode.set({ ...localNode });
  }

  private async optimizeMeshTopology(): Promise<void> {
    const localNode = this._localNode();
    const connectedNodes = this._discoveredNodes().filter(node => 
      localNode?.connectedPeers.includes(node.id)
    );

    // Mesh network'ün sağlığını değerlendir
    const networkHealth = this.calculateNetworkHealth(connectedNodes);
    
    // Gerekirse topology'yi yeniden düzenle
    if (networkHealth < 70) {
      await this.rebalanceMeshTopology();
    }
    
    // Network'ü emergency network olarak kaydet
    const emergencyNetwork = this.createEmergencyNetwork(connectedNodes);
    const networks = this._activeNetworks();
    this._activeNetworks.set([...networks, emergencyNetwork]);
    
    this.emergencyNetworkFormed$.next(emergencyNetwork);
  }

  private async establishCityWideBridges(): Promise<void> {
    const localNode = this._localNode();
    if (!localNode) return;

    // Bu node coordinator olabilir mi?
    const canBeCoordinator = this.evaluateCoordinatorCapability();
    
    if (canBeCoordinator) {
      this._isEmergencyCoordinator.set(true);
      localNode.emergencyRole = 'coordinator';
      
      // Şehir çapında koordinasyon protokolünü başlat
      await this.initiateCityWideCoordination();
    } else {
      // Coordinator node'ları ara ve bağlan
      await this.findAndConnectToCoordinators();
    }
  }

  // Şehir Çapında Koordinasyon
  private async startCityWideEmergencyProtocol(): Promise<void> {
    const scenario = this._currentScenario();
    if (!scenario) return;

    // 1. Bölgesel koordinatörler belirle
    await this.establishRegionalCoordinators();
    
    // 2. İlçeler arası bridge'ler kur
    await this.establishDistrictBridges();
    
    // 3. Emergency service'lerle iletişim kur
    await this.establishEmergencyServiceLinks();
    
    // 4. Toplu mesajlaşma sistemini başlat
    await this.initiateMassMessagingSystem();
    
    // 5. Koordineli tahliye sistemini hazırla
    await this.prepareCoordinatedEvacuation();
    
    this.cityWideCoordinationEstablished$.next(true);
  }

  // Gerçek Zamanlı Senaryo Simülasyonu
  async simulateRealTimeEmergencyProgression(): Promise<void> {
    const scenario = this._currentScenario();
    if (!scenario) return;

    // Her 30 saniyede senaryo durumunu güncelle
    interval(30000).subscribe(() => {
      this.updateScenarioProgression();
    });

    // İlk 10 dakika: Panik ve kaos
    setTimeout(() => this.simulatePanicPhase(), 0);
    
    // 10-30 dakika: Organizasyon başlangıcı
    setTimeout(() => this.simulateOrganizationPhase(), 10 * 60 * 1000);
    
    // 30-60 dakika: Koordineli yanıt
    setTimeout(() => this.simulateCoordinatedResponse(), 30 * 60 * 1000);
    
    // 1-3 saat: Kurtarma operasyonları
    setTimeout(() => this.simulateRescueOperations(), 60 * 60 * 1000);
  }

  private simulatePanicPhase(): void {
    // Yüksek mesaj trafiği
    this.simulateHighMessageVolume();
    
    // Rastgele bağlantı kopmaları
    this.simulateRandomDisconnections();
    
    // Pil tükenmesi başlangıcı
    this.simulateBatteryDrain();
  }

  private simulateOrganizationPhase(): void {
    // Koordinatör node'lar belirleniyor
    this.establishEmergencyCoordinators();
    
    // Sistematik mesajlaşma başlıyor
    this.initializeSystematicMessaging();
    
    // Kaynak optimizasyonu
    this.optimizeResourceUsage();
  }

  // Şehir Çapında İletişim Kapasitesi Hesaplama
  calculateCityWideCommunicationCapacity(): {
    estimatedCoverage: number; // km²
    reachablePopulation: number;
    messageCapacity: number; // messages per minute
    networkResilience: number; // 0-100
    evacuationCoordination: boolean;
  } {
    const scenario = this._currentScenario();
    const networks = this._activeNetworks();
    
    if (!scenario || networks.length === 0) {
      return {
        estimatedCoverage: 0,
        reachablePopulation: 0,
        messageCapacity: 0,
        networkResilience: 0,
        evacuationCoordination: false
      };
    }

    // Her network 500m-2km radius coverage sağlayabilir
    const totalCoverage = networks.reduce((sum, network) => {
      const radius = network.radius / 1000; // km
      const area = Math.PI * radius * radius;
      return sum + area;
    }, 0);

    // Nüfus yoğunluğuna göre ulaşılabilir kişi sayısı
    const reachablePopulation = Math.floor(totalCoverage * scenario.populationDensity);

    // Network kapasitesi (her node dakikada ~10 mesaj işleyebilir)
    const totalNodes = networks.reduce((sum, net) => sum + net.nodeCount, 0);
    const messageCapacity = totalNodes * 10;

    // Network dayanıklılığı
    const avgHealth = networks.reduce((sum, net) => sum + net.networkHealth, 0) / networks.length;
    const redundancy = this.calculateNetworkRedundancy();
    const networkResilience = Math.round((avgHealth + redundancy) / 2);

    // Tahliye koordinasyonu mümkün mü?
    const evacuationCoordination = networks.length >= 3 && networkResilience >= 60;

    return {
      estimatedCoverage: Math.round(totalCoverage * 100) / 100,
      reachablePopulation,
      messageCapacity,
      networkResilience,
      evacuationCoordination
    };
  }

  // Emergency Event Observables
  get onEmergencyNetworkFormed$(): Observable<EmergencyNetwork> {
    return this.emergencyNetworkFormed$.pipe(
      filter(network => network !== null),
      map(network => network!)
    );
  }

  get onCityWideCoordinationEstablished$(): Observable<boolean> {
    return this.cityWideCoordinationEstablished$.asObservable();
  }

  get onMassEvacuationCoordinated$(): Observable<string> {
    return this.massEvacuationCoordinated$.pipe(
      filter(message => message !== null),
      map(message => message!)
    );
  }

  // Private helper methods
  private async discoverWiFiDirectDevices(): Promise<MeshNode[]> {
    // WiFi Direct device discovery implementation
    return [];
  }

  private async discoverBluetoothDevices(): Promise<MeshNode[]> {
    // Bluetooth device discovery implementation
    return [];
  }

  private async discoverHotspotDevices(): Promise<MeshNode[]> {
    // Hotspot device discovery implementation
    return [];
  }

  private prioritizeNodesForConnection(nodes: MeshNode[]): MeshNode[] {
    return nodes.sort((a, b) => {
      // Öncelik: pil seviyesi, sinyal gücü, mesafe
      const scoreA = (a.batteryLevel * 0.4) + (a.signalStrength * 0.4) + (this.calculateDistance(a) * 0.2);
      const scoreB = (b.batteryLevel * 0.4) + (b.signalStrength * 0.4) + (this.calculateDistance(b) * 0.2);
      return scoreB - scoreA;
    });
  }

  private async connectToEmergencyNode(node: MeshNode): Promise<boolean> {
    // Emergency node connection implementation
    return await this.webrtcService.connectToPeer(node.id);
  }

  private simulateCoordinatedResponse(): void {
    // Simulate coordinated response phase
  }

  private simulateRescueOperations(): void {
    // Simulate rescue operations phase
  }

  private async performEmergencyHandshake(node: MeshNode): Promise<void> {
    // Emergency protocol handshake
    const handshakeData = {
      type: 'discovery' as const,
      nodeInfo: this._localNode(),
      emergencyCapabilities: this.getEmergencyCapabilities(),
      timestamp: Date.now(),
      priority: 'high' as const,
      payload: {}
    };

    await this.webrtcService.sendData(node.id, handshakeData);
  }

  private calculateNetworkHealth(nodes: MeshNode[]): number {
    if (nodes.length === 0) return 0;
    
    const avgBattery = nodes.reduce((sum, node) => sum + node.batteryLevel, 0) / nodes.length;
    const avgSignal = nodes.reduce((sum, node) => sum + node.signalStrength, 0) / nodes.length;
    const connectivity = this.calculateConnectivity(nodes);
    
    return Math.round((avgBattery + avgSignal + connectivity) / 3);
  }

  private createEmergencyNetwork(nodes: MeshNode[]): EmergencyNetwork {
    const localNode = this._localNode();
    if (!localNode?.location) {
      throw new Error('Local node location required for network creation');
    }

    return {
      id: this.generateNetworkId(),
      name: `Emergency Network ${Date.now()}`,
      centerLocation: {
        latitude: localNode.location.latitude,
        longitude: localNode.location.longitude
      },
      radius: this.calculateNetworkRadius(nodes),
      nodeCount: nodes.length + 1, // +1 for local node
      activeNodes: [...nodes, localNode],
      networkHealth: this.calculateNetworkHealth(nodes),
      coverageArea: this.calculateCoverageArea(nodes),
      messagesThroughput: 0,
      emergencyLevel: this.determineEmergencyLevel(),
      createdAt: Date.now(),
      lastActivity: Date.now()
    };
  }

  private generateNodeId(): string {
    return `node_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateNetworkId(): string {
    return `network_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private detectDeviceType(): 'smartphone' | 'tablet' | 'laptop' | 'iot' {
    // Device type detection based on screen size and capabilities
    return 'smartphone';
  }

  private getEmergencyCapabilities(): string[] {
    return [
      'emergency-mesh',
      'location-sharing',
      'emergency-messaging',
      'relay-capable',
      'encryption-support'
    ];
  }

  private shouldActAsRelay(): boolean {
    // Determine if device should act as relay based on capabilities
    return true;
  }

  private determineEmergencyRole(): 'coordinator' | 'relay' | 'endpoint' | 'bridge' {
    // Determine emergency role based on device capabilities
    return 'endpoint';
  }

  private async optimizeForEmergency(): Promise<void> {
    // Optimize device settings for emergency operation
    // - Enable power saving mode
    // - Maximize radio range
    // - Prioritize emergency traffic
  }

  private calculateDistance(node: MeshNode): number {
    const localNode = this._localNode();
    if (!localNode?.location || !node.location) return 1000;
    
    return this.locationService.calculateDistance(localNode.location, node.location);
  }

  private calculateConnectivity(nodes: MeshNode[]): number {
    // Calculate network connectivity score
    return 80; // Simplified implementation
  }

  private calculateNetworkRadius(nodes: MeshNode[]): number {
    // Calculate network coverage radius
    return 1000; // 1km default
  }

  private calculateCoverageArea(nodes: MeshNode[]): number {
    // Calculate total coverage area in square meters
    const radius = this.calculateNetworkRadius(nodes);
    return Math.PI * radius * radius;
  }

  private determineEmergencyLevel(): 'green' | 'yellow' | 'orange' | 'red' {
    const scenario = this._currentScenario();
    if (!scenario) return 'green';
    
    if (scenario.infrastructureStatus.cellularTowers < 10) return 'red';
    if (scenario.infrastructureStatus.cellularTowers < 30) return 'orange';
    if (scenario.infrastructureStatus.cellularTowers < 60) return 'yellow';
    return 'green';
  }

  private calculateNodeUtilization(): number {
    // Calculate how efficiently nodes are being used
    return 75; // Simplified implementation
  }

  private calculateNetworkRedundancy(): number {
    // Calculate network redundancy score
    return 60; // Simplified implementation
  }

  private getDeviceCapabilities(): any {
    // Get device hardware capabilities
    return {};
  }

  private async getBatteryLevel(): Promise<number> {
    // Get current battery level
    return 85; // Simplified implementation
  }

  private evaluateCoordinatorCapability(): boolean {
    // Evaluate if this device can act as coordinator
    return true; // Simplified implementation
  }

  private async initiateCityWideCoordination(): Promise<void> {
    // Initiate city-wide coordination protocol
  }

  private async findAndConnectToCoordinators(): Promise<void> {
    // Find and connect to coordinator nodes
  }

  private async establishRegionalCoordinators(): Promise<void> {
    // Establish regional coordinator nodes
  }

  private async establishDistrictBridges(): Promise<void> {
    // Establish bridges between districts
  }

  private async establishEmergencyServiceLinks(): Promise<void> {
    // Establish links with emergency services
  }

  private async initiateMassMessagingSystem(): Promise<void> {
    // Initiate mass messaging system
  }

  private async prepareCoordinatedEvacuation(): Promise<void> {
    // Prepare coordinated evacuation system
  }

  private updateScenarioProgression(): void {
    // Update scenario progression over time
  }

  private simulateHighMessageVolume(): void {
    // Simulate high message volume during panic
  }

  private simulateRandomDisconnections(): void {
    // Simulate random connection failures
  }

  private simulateBatteryDrain(): void {
    // Simulate battery drain over time
  }

  private establishEmergencyCoordinators(): void {
    // Establish emergency coordinator nodes
  }

  private initializeSystematicMessaging(): void {
    // Initialize systematic messaging protocols
  }

  private optimizeResourceUsage(): void {
    // Optimize resource usage for long-term operation
  }

  private async rebalanceMeshTopology(): Promise<void> {
    // Rebalance mesh network topology
  }

  private initializeEmergencyCoordination(): void {
    // Initialize emergency coordination service
  }

  private setupAutomaticNetworkFormation(): void {
    // Setup automatic network formation
  }

  private startCityWideCoordination(): void {
    // Start city-wide coordination
  }
}