import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, fromEvent, merge, interval } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs/operators';

export interface PeerConnection {
  id: string;
  name: string;
  connection: RTCPeerConnection;
  dataChannel?: RTCDataChannel;
  status: 'connecting' | 'connected' | 'disconnected' | 'failed';
  lastSeen: number;
  signalStrength: number;
  deviceType: 'mobile' | 'desktop' | 'iot';
  capabilities: string[];
  location?: {
    latitude: number;
    longitude: number;
    accuracy: number;
  };
}

export interface NetworkData {
  type: 'message' | 'discovery' | 'heartbeat' | 'emergency' | 'status' | 'mesh_routing';
  payload: any;
  timestamp: number;
  sender: string;
  recipient?: string;
  priority: 'low' | 'normal' | 'high' | 'emergency';
  ttl?: number;
  route?: string[];
}

export interface ConnectionStats {
  totalPeers: number;
  activePeers: number;
  dataTransferred: number;
  messagesExchanged: number;
  averageLatency: number;
  connectionQuality: 'poor' | 'fair' | 'good' | 'excellent';
}

@Injectable({
  providedIn: 'root'
})
export class WebrtcService {
  // Signals for reactive state management
  private _peers = signal<Map<string, PeerConnection>>(new Map());
  private _localPeerId = signal<string>('');
  private _connectionStatus = signal<'disconnected' | 'connecting' | 'connected'>('disconnected');
  private _networkStats = signal<ConnectionStats>({
    totalPeers: 0,
    activePeers: 0,
    dataTransferred: 0,
    messagesExchanged: 0,
    averageLatency: 0,
    connectionQuality: 'poor'
  });

  // Computed signals
  peers = computed(() => Array.from(this._peers().values()));
  connectedPeers = computed(() => this.peers().filter(p => p.status === 'connected'));
  connectionStatus = this._connectionStatus.asReadonly();
  networkStats = this._networkStats.asReadonly();
  isConnected = computed(() => this.connectedPeers().length > 0);

  // Subjects for events
  private dataReceived$ = new Subject<NetworkData>();
  private peerConnected$ = new Subject<PeerConnection>();
  private peerDisconnected$ = new Subject<PeerConnection>();
  private connectionStatusChanged$ = new Subject<'disconnected' | 'connecting' | 'connected'>();

  // WebRTC Configuration
  private rtcConfiguration: RTCConfiguration = {
    iceServers: [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' },
      { urls: 'stun:stun2.l.google.com:19302' }
    ],
    iceCandidatePoolSize: 10
  };

  private localDataChannel?: RTCDataChannel;
  private discoveryInterval?: any;
  private heartbeatInterval?: any;

  constructor() {
    this.initializeWebRTC();
    this.setupNetworkMonitoring();
    this.startDiscovery();
  }

  private initializeWebRTC(): void {
    // Generate unique peer ID
    this._localPeerId.set(this.generatePeerId());
    
    // Setup discovery mechanisms
    this.setupBroadcastDiscovery();
    this.setupWebSocketSignaling();
    
    console.log('WebRTC Service initialized with peer ID:', this._localPeerId());
  }

  private setupNetworkMonitoring(): void {
    // Monitor connection quality
    interval(10000).subscribe(() => {
      this.updateNetworkStats();
      this.cleanupStaleConnections();
    });

    // Heartbeat mechanism
    this.heartbeatInterval = setInterval(() => {
      this.sendHeartbeat();
    }, 30000);
  }

  private startDiscovery(): void {
    // Start peer discovery
    this.discoveryInterval = setInterval(() => {
      this.discoverPeers();
    }, 15000);

    // Initial discovery
    this.discoverPeers();
  }

  // Public API Methods

  async connectToPeer(peerId: string, offer?: RTCSessionDescriptionInit): Promise<boolean> {
    try {
      if (this._peers().has(peerId)) {
        console.log('Already connected to peer:', peerId);
        return true;
      }

      const peerConnection = new RTCPeerConnection(this.rtcConfiguration);
      const peer: PeerConnection = {
        id: peerId,
        name: `Peer_${peerId.substr(0, 6)}`,
        connection: peerConnection,
        status: 'connecting',
        lastSeen: Date.now(),
        signalStrength: 100,
        deviceType: 'mobile',
        capabilities: ['messaging', 'emergency']
      };

      // Setup connection event handlers
      this.setupPeerConnectionHandlers(peer);

      // Create data channel
      if (!offer) {
        peer.dataChannel = peerConnection.createDataChannel('emergency-mesh', {
          ordered: true,
          maxRetransmits: 3
        });
        this.setupDataChannelHandlers(peer.dataChannel, peer);
      }

      // Add to peers map
      const peersMap = new Map(this._peers());
      peersMap.set(peerId, peer);
      this._peers.set(peersMap);

      // Handle offer/answer exchange
      if (offer) {
        await peerConnection.setRemoteDescription(offer);
        const answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);
        
        // In real implementation, send answer through signaling server
        console.log('Answer created for peer:', peerId);
      } else {
        const offer = await peerConnection.createOffer();
        await peerConnection.setLocalDescription(offer);
        
        // In real implementation, send offer through signaling server
        console.log('Offer created for peer:', peerId);
      }

      return true;
    } catch (error) {
      console.error('Failed to connect to peer:', error);
      return false;
    }
  }

  async sendData(peerId: string, data: Omit<NetworkData, 'timestamp' | 'sender'>): Promise<boolean> {
    const peer = this._peers().get(peerId);
    if (!peer || peer.status !== 'connected' || !peer.dataChannel) {
      console.warn('Cannot send data to peer:', peerId, peer?.status);
      return false;
    }

    try {
      const networkData: NetworkData = {
        ...data,
        timestamp: Date.now(),
        sender: this._localPeerId()
      };

      const message = JSON.stringify(networkData);
      peer.dataChannel.send(message);

      // Update stats
      this.updateDataStats(message.length);
      
      return true;
    } catch (error) {
      console.error('Failed to send data to peer:', error);
      return false;
    }
  }

  async broadcastData(data: Omit<NetworkData, 'timestamp' | 'sender'>): Promise<number> {
    const connectedPeers = this.connectedPeers();
    let successCount = 0;

    for (const peer of connectedPeers) {
      const success = await this.sendData(peer.id, data);
      if (success) successCount++;
    }

    return successCount;
  }

  disconnectFromPeer(peerId: string): void {
    const peer = this._peers().get(peerId);
    if (peer) {
      peer.connection.close();
      
      const peersMap = new Map(this._peers());
      peersMap.delete(peerId);
      this._peers.set(peersMap);

      this.peerDisconnected$.next(peer);
    }
  }

  disconnectAll(): void {
    const peers = this._peers();
    peers.forEach((peer, peerId) => {
      this.disconnectFromPeer(peerId);
    });
  }

  getConnectedPeers(): PeerConnection[] {
    return this.connectedPeers();
  }

  getLocalPeerId(): string {
    return this._localPeerId();
  }

  getPeerById(peerId: string): PeerConnection | undefined {
    return this._peers().get(peerId);
  }

  // Event Observables
  get onDataReceived$(): Observable<NetworkData> {
    return this.dataReceived$.asObservable();
  }

  get onPeerConnected$(): Observable<PeerConnection> {
    return this.peerConnected$.asObservable();
  }

  get onPeerDisconnected$(): Observable<PeerConnection> {
    return this.peerDisconnected$.asObservable();
  }

  get connectionStatus$(): Observable<'disconnected' | 'connecting' | 'connected'> {
    return this.connectionStatusChanged$.asObservable();
  }

  // Private Methods

  private setupPeerConnectionHandlers(peer: PeerConnection): void {
    const { connection } = peer;

    connection.onicecandidate = (event) => {
      if (event.candidate) {
        // In real implementation, send candidate through signaling server
        console.log('ICE candidate for peer:', peer.id);
      }
    };

    connection.onconnectionstatechange = () => {
      console.log('Connection state changed:', connection.connectionState);
      
      switch (connection.connectionState) {
        case 'connected':
          peer.status = 'connected';
          peer.lastSeen = Date.now();
          this.peerConnected$.next(peer);
          this.updateConnectionStatus();
          break;
        case 'disconnected':
        case 'failed':
        case 'closed':
          peer.status = 'disconnected';
          this.peerDisconnected$.next(peer);
          this.updateConnectionStatus();
          break;
      }
    };

    connection.ondatachannel = (event) => {
      const dataChannel = event.channel;
      peer.dataChannel = dataChannel;
      this.setupDataChannelHandlers(dataChannel, peer);
    };

    connection.onicegatheringstatechange = () => {
      console.log('ICE gathering state:', connection.iceGatheringState);
    };
  }

  private setupDataChannelHandlers(dataChannel: RTCDataChannel, peer: PeerConnection): void {
    dataChannel.onopen = () => {
      console.log('Data channel opened with peer:', peer.id);
      peer.status = 'connected';
      this.updateConnectionStatus();
    };

    dataChannel.onclose = () => {
      console.log('Data channel closed with peer:', peer.id);
      peer.status = 'disconnected';
      this.updateConnectionStatus();
    };

    dataChannel.onmessage = (event) => {
      try {
        const data: NetworkData = JSON.parse(event.data);
        peer.lastSeen = Date.now();
        
        // Update message stats
        this.updateMessageStats();
        
        // Handle different message types
        this.handleIncomingData(data, peer);
        
        // Emit to subscribers
        this.dataReceived$.next(data);
      } catch (error) {
        console.error('Failed to parse incoming data:', error);
      }
    };

    dataChannel.onerror = (error) => {
      console.error('Data channel error with peer:', peer.id, error);
    };
  }

  private handleIncomingData(data: NetworkData, peer: PeerConnection): void {
    switch (data.type) {
      case 'discovery':
        this.handleDiscoveryMessage(data, peer);
        break;
      case 'heartbeat':
        this.handleHeartbeat(data, peer);
        break;
      case 'mesh_routing':
        this.handleMeshRouting(data, peer);
        break;
      default:
        // Regular message - will be handled by subscribers
        break;
    }
  }

  private handleDiscoveryMessage(data: NetworkData, peer: PeerConnection): void {
    // Update peer information
    if (data.payload.deviceInfo) {
      peer.name = data.payload.deviceInfo.name || peer.name;
      peer.deviceType = data.payload.deviceInfo.type || peer.deviceType;
      peer.capabilities = data.payload.deviceInfo.capabilities || peer.capabilities;
      peer.location = data.payload.deviceInfo.location;
    }

    // Send discovery response
    this.sendData(peer.id, {
      type: 'discovery',
      payload: {
        response: true,
        deviceInfo: this.getLocalDeviceInfo()
      },
      priority: 'normal'
    });
  }

  private handleHeartbeat(data: NetworkData, peer: PeerConnection): void {
    peer.lastSeen = Date.now();
    peer.signalStrength = data.payload.signalStrength || peer.signalStrength;
    
    // Update peer in map
    const peersMap = new Map(this._peers());
    peersMap.set(peer.id, { ...peer });
    this._peers.set(peersMap);
  }

  private handleMeshRouting(data: NetworkData, peer: PeerConnection): void {
    // Handle mesh network routing
    if (data.recipient && data.recipient !== this._localPeerId()) {
      // Forward message to intended recipient
      this.forwardMessage(data);
    }
  }

  private async forwardMessage(data: NetworkData): Promise<void> {
    const targetPeer = this._peers().get(data.recipient!);
    
    if (targetPeer && targetPeer.status === 'connected') {
      // Direct connection available
      await this.sendData(targetPeer.id, data);
    } else {
      // Find route through mesh network
      const route = this.findRoute(data.recipient!);
      if (route.length > 0) {
        const nextHop = route[0];
        data.route = route;
        await this.sendData(nextHop, data);
      }
    }
  }

  private findRoute(targetPeerId: string): string[] {
    // Simplified routing algorithm
    // In real implementation, this would use a proper mesh routing protocol
    const connectedPeers = this.connectedPeers();
    
    for (const peer of connectedPeers) {
      // Check if peer knows about target
      if (peer.capabilities.includes('routing')) {
        return [peer.id];
      }
    }
    
    return [];
  }

  private async discoverPeers(): Promise<void> {
    // Broadcast discovery message
    await this.broadcastData({
      type: 'discovery',
      payload: {
        deviceInfo: this.getLocalDeviceInfo(),
        timestamp: Date.now()
      },
      priority: 'low'
    });

    // Simulate peer discovery for demo
    this.simulatePeerDiscovery();
  }

  private simulatePeerDiscovery(): void {
    // This simulates finding peers in the network
    // In real implementation, this would use actual discovery mechanisms
    
    const simulatedPeers = [
      { id: 'peer_001', name: 'Ahmet\'s Phone', deviceType: 'mobile' as const },
      { id: 'peer_002', name: 'Fatma\'s Tablet', deviceType: 'mobile' as const },
      { id: 'peer_003', name: 'Office Computer', deviceType: 'desktop' as const }
    ];

    simulatedPeers.forEach(peerInfo => {
      if (!this._peers().has(peerInfo.id) && Math.random() > 0.7) {
        // Simulate random peer discovery
        this.connectToPeer(peerInfo.id);
      }
    });
  }

  private async sendHeartbeat(): Promise<void> {
    await this.broadcastData({
      type: 'heartbeat',
      payload: {
        signalStrength: this.calculateSignalStrength(),
        batteryLevel: await this.getBatteryLevel(),
        timestamp: Date.now()
      },
      priority: 'low'
    });
  }

  private setupBroadcastDiscovery(): void {
    // Setup WiFi Direct and Bluetooth LE discovery
    // This is a simplified implementation
    console.log('Setting up broadcast discovery mechanisms');
  }

  private setupWebSocketSignaling(): void {
    // Setup WebSocket signaling server connection
    // This would connect to a signaling server for initial peer discovery
    console.log('Setting up WebSocket signaling');
  }

  private updateConnectionStatus(): void {
    const connectedCount = this.connectedPeers().length;
    
    if (connectedCount > 0) {
      this._connectionStatus.set('connected');
    } else if (this._peers().size > 0) {
      this._connectionStatus.set('connecting');
    } else {
      this._connectionStatus.set('disconnected');
    }

    this.connectionStatusChanged$.next(this._connectionStatus());
  }

  private updateNetworkStats(): void {
    const peers = this._peers();
    const connectedPeers = this.connectedPeers();
    
    const stats: ConnectionStats = {
      totalPeers: peers.size,
      activePeers: connectedPeers.length,
      dataTransferred: this.networkStats().dataTransferred,
      messagesExchanged: this.networkStats().messagesExchanged,
      averageLatency: this.calculateAverageLatency(),
      connectionQuality: this.calculateConnectionQuality()
    };

    this._networkStats.set(stats);
  }

  private updateDataStats(bytes: number): void {
    const stats = this._networkStats();
    this._networkStats.set({
      ...stats,
      dataTransferred: stats.dataTransferred + bytes
    });
  }

  private updateMessageStats(): void {
    const stats = this._networkStats();
    this._networkStats.set({
      ...stats,
      messagesExchanged: stats.messagesExchanged + 1
    });
  }

  private cleanupStaleConnections(): void {
    const now = Date.now();
    const staleTimeout = 120000; // 2 minutes
    
    const peersMap = new Map(this._peers());
    
    peersMap.forEach((peer, peerId) => {
      if (now - peer.lastSeen > staleTimeout) {
        console.log('Removing stale peer:', peerId);
        peer.connection.close();
        peersMap.delete(peerId);
      }
    });

    this._peers.set(peersMap);
  }

  private calculateSignalStrength(): number {
    // Simplified signal strength calculation
    return Math.floor(Math.random() * 40) + 60; // 60-100%
  }

  private async getBatteryLevel(): Promise<number> {
    try {
      // @ts-ignore - Battery API might not be available in all browsers
      const battery = await navigator.getBattery?.();
      return battery ? Math.floor(battery.level * 100) : 85;
    } catch {
      return 85; // Default value
    }
  }

  private calculateAverageLatency(): number {
    // Simplified latency calculation
    const connectedPeers = this.connectedPeers();
    if (connectedPeers.length === 0) return 0;
    
    return Math.floor(Math.random() * 100) + 50; // 50-150ms
  }

  private calculateConnectionQuality(): 'poor' | 'fair' | 'good' | 'excellent' {
    const connectedCount = this.connectedPeers().length;
    const averageLatency = this.calculateAverageLatency();
    
    if (connectedCount >= 5 && averageLatency < 100) return 'excellent';
    if (connectedCount >= 3 && averageLatency < 150) return 'good';
    if (connectedCount >= 1 && averageLatency < 200) return 'fair';
    return 'poor';
  }

  private getLocalDeviceInfo(): any {
    return {
      id: this._localPeerId(),
      name: 'My Device',
      type: 'mobile',
      capabilities: ['messaging', 'emergency', 'routing'],
      batteryLevel: 85,
      location: null // Would be populated by location service
    };
  }

  private generatePeerId(): string {
    return `peer_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  ngOnDestroy(): void {
    // Cleanup
    if (this.discoveryInterval) {
      clearInterval(this.discoveryInterval);
    }
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
    }
    
    this.disconnectAll();
  }
}