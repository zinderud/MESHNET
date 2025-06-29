import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval, merge } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs/operators';

import { CryptoService } from './crypto.service';
import { AnalyticsService } from './analytics.service';
import { SecurityService } from './security.service';

export interface P2PNode {
  id: string;
  publicKey: string;
  ipAddress: string;
  port: number;
  nodeType: 'full' | 'light' | 'relay' | 'bridge';
  capabilities: string[];
  reputation: number;
  lastSeen: number;
  connectionQuality: number;
  geolocation?: {
    latitude: number;
    longitude: number;
    accuracy: number;
  };
  deviceInfo: {
    type: 'mobile' | 'desktop' | 'iot';
    os: string;
    version: string;
    batteryLevel?: number;
  };
}

export interface P2PMessage {
  id: string;
  type: 'data' | 'control' | 'discovery' | 'heartbeat' | 'emergency';
  payload: any;
  sender: string;
  recipient?: string;
  timestamp: number;
  ttl: number;
  priority: 'low' | 'normal' | 'high' | 'emergency';
  encrypted: boolean;
  signature?: string;
  route: string[];
  hopCount: number;
}

export interface RoutingTable {
  destination: string;
  nextHop: string;
  hopCount: number;
  metric: number;
  lastUpdated: number;
  isActive: boolean;
}

export interface NetworkTopology {
  nodes: Map<string, P2PNode>;
  connections: Map<string, string[]>;
  routingTable: Map<string, RoutingTable>;
  networkDiameter: number;
  clusteringCoefficient: number;
  averagePathLength: number;
}

@Injectable({
  providedIn: 'root'
})
export class P2PNetworkService {
  private cryptoService = inject(CryptoService);
  private analyticsService = inject(AnalyticsService);
  private securityService = inject(SecurityService);

  // Signals for reactive P2P state
  private _localNode = signal<P2PNode | null>(null);
  private _connectedPeers = signal<Map<string, P2PNode>>(new Map());
  private _routingTable = signal<Map<string, RoutingTable>>(new Map());
  private _networkTopology = signal<NetworkTopology | null>(null);
  private _isNetworkActive = signal<boolean>(false);

  // Computed network metrics
  localNode = this._localNode.asReadonly();
  connectedPeers = this._connectedPeers.asReadonly();
  routingTable = this._routingTable.asReadonly();
  networkTopology = this._networkTopology.asReadonly();
  isNetworkActive = this._isNetworkActive.asReadonly();

  peerCount = computed(() => this._connectedPeers().size);
  networkHealth = computed(() => this.calculateNetworkHealth());
  averageLatency = computed(() => this.calculateAverageLatency());
  networkReachability = computed(() => this.calculateNetworkReachability());

  // P2P event subjects
  private peerConnected$ = new Subject<P2PNode>();
  private peerDisconnected$ = new Subject<P2PNode>();
  private messageReceived$ = new Subject<P2PMessage>();
  private routeDiscovered$ = new Subject<RoutingTable>();
  private networkPartitioned$ = new Subject<string[]>();

  // Network configuration
  private readonly MAX_CONNECTIONS = 8;
  private readonly HEARTBEAT_INTERVAL = 30000; // 30 seconds
  private readonly ROUTE_TIMEOUT = 300000; // 5 minutes
  private readonly MESSAGE_TTL = 10;

  private destroy$ = new Subject<void>();

  constructor() {
    this.initializeP2PNetwork();
    this.setupNetworkMonitoring();
    this.startNetworkMaintenance();
  }

  // P2P Network Initialization
  private async initializeP2PNetwork(): Promise<void> {
    try {
      // Initialize local node
      await this.createLocalNode();
      
      // Setup network discovery
      this.setupPeerDiscovery();
      
      // Start routing protocol
      this.initializeRoutingProtocol();
      
      // Setup message handling
      this.setupMessageHandling();
      
      this._isNetworkActive.set(true);
      this.analyticsService.trackEvent('p2p', 'network_initialized', 'success');
      
      console.log('P2P Network initialized successfully');
    } catch (error) {
      console.error('Failed to initialize P2P network:', error);
      this.analyticsService.trackError('p2p', 'Network initialization failed', { error });
    }
  }

  private async createLocalNode(): Promise<void> {
    const nodeId = await this.generateNodeId();
    const publicKey = await this.cryptoService.exportPublicKey();
    
    const localNode: P2PNode = {
      id: nodeId,
      publicKey,
      ipAddress: await this.getLocalIPAddress(),
      port: await this.getAvailablePort(),
      nodeType: this.determineNodeType(),
      capabilities: this.getNodeCapabilities(),
      reputation: 100,
      lastSeen: Date.now(),
      connectionQuality: 100,
      deviceInfo: {
        type: this.detectDeviceType(),
        os: this.detectOS(),
        version: this.getAppVersion(),
        batteryLevel: await this.getBatteryLevel()
      }
    };

    this._localNode.set(localNode);
  }

  // Peer Discovery and Connection Management
  async discoverPeers(): Promise<P2PNode[]> {
    const discoveredPeers: P2PNode[] = [];
    
    try {
      // mDNS discovery
      const mdnsPeers = await this.discoverViaMDNS();
      discoveredPeers.push(...mdnsPeers);
      
      // DHT discovery
      const dhtPeers = await this.discoverViaDHT();
      discoveredPeers.push(...dhtPeers);
      
      // Bootstrap nodes discovery
      const bootstrapPeers = await this.discoverViaBootstrap();
      discoveredPeers.push(...bootstrapPeers);
      
      // Local network scanning
      const localPeers = await this.scanLocalNetwork();
      discoveredPeers.push(...localPeers);
      
      return this.filterAndRankPeers(discoveredPeers);
    } catch (error) {
      console.error('Peer discovery failed:', error);
      return [];
    }
  }

  async connectToPeer(peer: P2PNode): Promise<boolean> {
    try {
      // Check if already connected
      if (this._connectedPeers().has(peer.id)) {
        return true;
      }

      // Check connection limits
      if (this.peerCount() >= this.MAX_CONNECTIONS) {
        await this.optimizeConnections();
      }

      // Validate peer security
      if (!await this.validatePeerSecurity(peer)) {
        this.securityService.detectThreat('malicious_peer', peer.id, 'Peer security validation failed');
        return false;
      }

      // Establish connection
      const connected = await this.establishConnection(peer);
      
      if (connected) {
        // Add to connected peers
        const peers = new Map(this._connectedPeers());
        peers.set(peer.id, peer);
        this._connectedPeers.set(peers);
        
        // Update routing table
        await this.updateRoutingTable(peer);
        
        // Emit connection event
        this.peerConnected$.next(peer);
        
        this.analyticsService.trackNetworkConnection('p2p_peer', true);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error(`Failed to connect to peer ${peer.id}:`, error);
      this.analyticsService.trackNetworkConnection('p2p_peer', false);
      return false;
    }
  }

  async disconnectFromPeer(peerId: string): Promise<void> {
    const peers = new Map(this._connectedPeers());
    const peer = peers.get(peerId);
    
    if (peer) {
      peers.delete(peerId);
      this._connectedPeers.set(peers);
      
      // Remove from routing table
      await this.removeFromRoutingTable(peerId);
      
      // Emit disconnection event
      this.peerDisconnected$.next(peer);
      
      this.analyticsService.trackEvent('p2p', 'peer_disconnected', peerId);
    }
  }

  // Message Routing and Delivery
  async sendMessage(message: Omit<P2PMessage, 'id' | 'timestamp' | 'route' | 'hopCount'>): Promise<boolean> {
    try {
      const fullMessage: P2PMessage = {
        id: this.generateMessageId(),
        timestamp: Date.now(),
        route: [this._localNode()?.id || ''],
        hopCount: 0,
        ...message
      };

      // Encrypt message if required
      if (fullMessage.encrypted) {
        fullMessage.payload = await this.encryptMessagePayload(fullMessage.payload, fullMessage.recipient);
      }

      // Sign message
      fullMessage.signature = await this.cryptoService.signData(JSON.stringify(fullMessage.payload));

      // Route message
      if (fullMessage.recipient) {
        return await this.routeMessage(fullMessage);
      } else {
        return await this.broadcastMessage(fullMessage);
      }
    } catch (error) {
      console.error('Failed to send message:', error);
      return false;
    }
  }

  private async routeMessage(message: P2PMessage): Promise<boolean> {
    const routingTable = this._routingTable();
    const route = routingTable.get(message.recipient!);
    
    if (!route || !route.isActive) {
      // Try to discover route
      const discovered = await this.discoverRoute(message.recipient!);
      if (!discovered) {
        console.warn(`No route found to ${message.recipient}`);
        return false;
      }
    }

    const nextHop = routingTable.get(message.recipient!)?.nextHop;
    if (!nextHop) {
      return false;
    }

    return await this.forwardMessage(message, nextHop);
  }

  private async broadcastMessage(message: P2PMessage): Promise<boolean> {
    const peers = this._connectedPeers();
    let successCount = 0;
    
    for (const [peerId, peer] of peers) {
      try {
        const success = await this.sendDirectMessage(message, peerId);
        if (success) successCount++;
      } catch (error) {
        console.error(`Failed to send message to ${peerId}:`, error);
      }
    }
    
    return successCount > 0;
  }

  private async forwardMessage(message: P2PMessage, nextHop: string): Promise<boolean> {
    // Check TTL
    if (message.ttl <= 0) {
      console.warn('Message TTL expired');
      return false;
    }

    // Update message
    message.ttl--;
    message.hopCount++;
    message.route.push(this._localNode()?.id || '');

    // Forward to next hop
    return await this.sendDirectMessage(message, nextHop);
  }

  // Routing Protocol Implementation
  private async initializeRoutingProtocol(): Promise<void> {
    // Start periodic routing updates
    interval(60000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.sendRoutingUpdates();
    });

    // Start route maintenance
    interval(30000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.maintainRoutes();
    });
  }

  private async discoverRoute(destination: string): Promise<boolean> {
    // Send route discovery request
    const discoveryMessage: P2PMessage = {
      id: this.generateMessageId(),
      type: 'control',
      payload: {
        action: 'route_discovery',
        destination,
        source: this._localNode()?.id
      },
      sender: this._localNode()?.id || '',
      timestamp: Date.now(),
      ttl: this.MESSAGE_TTL,
      priority: 'normal',
      encrypted: false,
      route: [],
      hopCount: 0
    };

    return await this.broadcastMessage(discoveryMessage);
  }

  private async updateRoutingTable(peer: P2PNode): Promise<void> {
    const routingTable = new Map(this._routingTable());
    
    // Direct route to peer
    routingTable.set(peer.id, {
      destination: peer.id,
      nextHop: peer.id,
      hopCount: 1,
      metric: this.calculateRouteMetric(peer),
      lastUpdated: Date.now(),
      isActive: true
    });

    this._routingTable.set(routingTable);
  }

  private async removeFromRoutingTable(peerId: string): Promise<void> {
    const routingTable = new Map(this._routingTable());
    
    // Remove direct routes
    routingTable.delete(peerId);
    
    // Remove routes through this peer
    for (const [destination, route] of routingTable) {
      if (route.nextHop === peerId) {
        routingTable.delete(destination);
      }
    }

    this._routingTable.set(routingTable);
  }

  // Network Topology Management
  private async updateNetworkTopology(): Promise<void> {
    const peers = this._connectedPeers();
    const connections = new Map<string, string[]>();
    
    // Build connection map
    for (const [peerId, peer] of peers) {
      const peerConnections = await this.getPeerConnections(peerId);
      connections.set(peerId, peerConnections);
    }

    const topology: NetworkTopology = {
      nodes: new Map(peers),
      connections,
      routingTable: new Map(this._routingTable()),
      networkDiameter: this.calculateNetworkDiameter(connections),
      clusteringCoefficient: this.calculateClusteringCoefficient(connections),
      averagePathLength: this.calculateAveragePathLength(connections)
    };

    this._networkTopology.set(topology);
  }

  // Network Monitoring and Maintenance
  private setupNetworkMonitoring(): void {
    // Monitor peer health
    interval(this.HEARTBEAT_INTERVAL).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.sendHeartbeats();
      this.checkPeerHealth();
    });

    // Monitor network partitions
    interval(120000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.detectNetworkPartitions();
    });
  }

  private startNetworkMaintenance(): void {
    // Periodic topology updates
    interval(60000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.updateNetworkTopology();
    });

    // Connection optimization
    interval(300000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.optimizeConnections();
    });
  }

  private async sendHeartbeats(): Promise<void> {
    const heartbeatMessage: P2PMessage = {
      id: this.generateMessageId(),
      type: 'heartbeat',
      payload: {
        nodeInfo: this._localNode(),
        timestamp: Date.now()
      },
      sender: this._localNode()?.id || '',
      timestamp: Date.now(),
      ttl: 1,
      priority: 'low',
      encrypted: false,
      route: [],
      hopCount: 0
    };

    await this.broadcastMessage(heartbeatMessage);
  }

  private async checkPeerHealth(): Promise<void> {
    const peers = new Map(this._connectedPeers());
    const now = Date.now();
    const timeout = this.HEARTBEAT_INTERVAL * 3; // 3 missed heartbeats

    for (const [peerId, peer] of peers) {
      if (now - peer.lastSeen > timeout) {
        console.warn(`Peer ${peerId} appears to be offline`);
        await this.disconnectFromPeer(peerId);
      }
    }
  }

  // Security and Validation
  private async validatePeerSecurity(peer: P2PNode): Promise<boolean> {
    try {
      // Check if peer is blacklisted
      if (this.securityService.isBlocked(peer.id)) {
        return false;
      }

      // Verify peer reputation
      if (peer.reputation < 30) {
        return false;
      }

      // Validate public key
      if (!peer.publicKey || peer.publicKey.length < 100) {
        return false;
      }

      // Check peer capabilities
      if (!peer.capabilities.includes('emergency-mesh')) {
        return false;
      }

      return true;
    } catch (error) {
      console.error('Peer security validation failed:', error);
      return false;
    }
  }

  // Event Observables
  get onPeerConnected$(): Observable<P2PNode> {
    return this.peerConnected$.asObservable();
  }

  get onPeerDisconnected$(): Observable<P2PNode> {
    return this.peerDisconnected$.asObservable();
  }

  get onMessageReceived$(): Observable<P2PMessage> {
    return this.messageReceived$.asObservable();
  }

  get onRouteDiscovered$(): Observable<RoutingTable> {
    return this.routeDiscovered$.asObservable();
  }

  get onNetworkPartitioned$(): Observable<string[]> {
    return this.networkPartitioned$.asObservable();
  }

  // Private helper methods
  private async generateNodeId(): Promise<string> {
    const randomBytes = crypto.getRandomValues(new Uint8Array(16));
    return Array.from(randomBytes, byte => byte.toString(16).padStart(2, '0')).join('');
  }

  private generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private determineNodeType(): 'full' | 'light' | 'relay' | 'bridge' {
    // Determine based on device capabilities
    return 'full';
  }

  private getNodeCapabilities(): string[] {
    return [
      'emergency-mesh',
      'message-routing',
      'peer-discovery',
      'encryption',
      'location-sharing'
    ];
  }

  private detectDeviceType(): 'mobile' | 'desktop' | 'iot' {
    return 'mobile'; // Simplified detection
  }

  private detectOS(): string {
    return navigator.platform || 'Unknown';
  }

  private getAppVersion(): string {
    return '1.0.0';
  }

  private async getBatteryLevel(): Promise<number | undefined> {
    try {
      // @ts-ignore
      const battery = await navigator.getBattery?.();
      return battery ? Math.round(battery.level * 100) : undefined;
    } catch {
      return undefined;
    }
  }

  private async getLocalIPAddress(): Promise<string> {
    // Simplified IP detection
    return '192.168.1.100';
  }

  private async getAvailablePort(): Promise<number> {
    // Return available port
    return 8080 + Math.floor(Math.random() * 1000);
  }

  private async discoverViaMDNS(): Promise<P2PNode[]> {
    // mDNS discovery implementation
    return [];
  }

  private async discoverViaDHT(): Promise<P2PNode[]> {
    // DHT discovery implementation
    return [];
  }

  private async discoverViaBootstrap(): Promise<P2PNode[]> {
    // Bootstrap nodes discovery
    return [];
  }

  private async scanLocalNetwork(): Promise<P2PNode[]> {
    // Local network scanning
    return [];
  }

  private filterAndRankPeers(peers: P2PNode[]): P2PNode[] {
    return peers
      .filter(peer => peer.reputation >= 50)
      .sort((a, b) => b.reputation - a.reputation)
      .slice(0, this.MAX_CONNECTIONS);
  }

  private async establishConnection(peer: P2PNode): Promise<boolean> {
    // WebRTC or WebSocket connection establishment
    return true; // Simplified implementation
  }

  private async encryptMessagePayload(payload: any, recipient?: string): Promise<any> {
    if (recipient) {
      // Encrypt for specific recipient
      return await this.cryptoService.encryptMessage(JSON.stringify(payload));
    }
    return payload;
  }

  private async sendDirectMessage(message: P2PMessage, peerId: string): Promise<boolean> {
    // Direct message sending implementation
    return true; // Simplified implementation
  }

  private calculateRouteMetric(peer: P2PNode): number {
    // Calculate route metric based on latency, bandwidth, reliability
    return peer.connectionQuality;
  }

  private async getPeerConnections(peerId: string): Promise<string[]> {
    // Get peer's connections
    return [];
  }

  private calculateNetworkDiameter(connections: Map<string, string[]>): number {
    // Calculate network diameter
    return 5; // Simplified implementation
  }

  private calculateClusteringCoefficient(connections: Map<string, string[]>): number {
    // Calculate clustering coefficient
    return 0.6; // Simplified implementation
  }

  private calculateAveragePathLength(connections: Map<string, string[]>): number {
    // Calculate average path length
    return 2.5; // Simplified implementation
  }

  private calculateNetworkHealth(): number {
    const peerCount = this.peerCount();
    const topology = this._networkTopology();
    
    if (peerCount === 0) return 0;
    
    const connectivityScore = Math.min(peerCount / this.MAX_CONNECTIONS * 100, 100);
    const topologyScore = topology ? topology.clusteringCoefficient * 100 : 50;
    
    return Math.round((connectivityScore + topologyScore) / 2);
  }

  private calculateAverageLatency(): number {
    // Calculate average network latency
    return 150; // Simplified implementation
  }

  private calculateNetworkReachability(): number {
    const routingTable = this._routingTable();
    const activeRoutes = Array.from(routingTable.values()).filter(route => route.isActive);
    
    return activeRoutes.length;
  }

  private async sendRoutingUpdates(): Promise<void> {
    // Send routing table updates to peers
  }

  private async maintainRoutes(): Promise<void> {
    const routingTable = new Map(this._routingTable());
    const now = Date.now();
    
    // Remove expired routes
    for (const [destination, route] of routingTable) {
      if (now - route.lastUpdated > this.ROUTE_TIMEOUT) {
        routingTable.delete(destination);
      }
    }
    
    this._routingTable.set(routingTable);
  }

  private async detectNetworkPartitions(): Promise<void> {
    // Detect network partitions and emit events
  }

  private async optimizeConnections(): Promise<void> {
    // Optimize peer connections based on performance metrics
  }

  private setupPeerDiscovery(): void {
    // Setup peer discovery mechanisms
  }

  private setupMessageHandling(): void {
    // Setup message handling and processing
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}