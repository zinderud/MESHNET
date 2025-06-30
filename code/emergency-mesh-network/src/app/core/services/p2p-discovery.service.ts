import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval, merge } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged, takeUntil } from 'rxjs/operators';

import { WebrtcService } from './webrtc.service';
import { AnalyticsService } from './analytics.service';
import { SecurityService } from './security.service';

export interface DiscoveredPeer {
  id: string;
  type: 'direct' | 'mdns' | 'dht' | 'relay' | 'manual';
  address?: string;
  port?: number;
  lastSeen: number;
  signalData?: any;
  metadata?: {
    name?: string;
    deviceType?: string;
    capabilities?: string[];
    version?: string;
  };
}

export interface DiscoveryStats {
  totalDiscovered: number;
  activeDiscoveries: number;
  successRate: number;
  averageDiscoveryTime: number;
  lastDiscoveryTime: number;
}

@Injectable({
  providedIn: 'root'
})
export class P2PDiscoveryService {
  private webrtcService = inject(WebrtcService);
  private analyticsService = inject(AnalyticsService);
  private securityService = inject(SecurityService);

  // Signals for reactive discovery state
  private _discoveredPeers = signal<Map<string, DiscoveredPeer>>(new Map());
  private _isDiscovering = signal<boolean>(false);
  private _discoveryStats = signal<DiscoveryStats>({
    totalDiscovered: 0,
    activeDiscoveries: 0,
    successRate: 0,
    averageDiscoveryTime: 0,
    lastDiscoveryTime: 0
  });
  private _discoveryMethods = signal<{
    mdns: boolean;
    dht: boolean;
    relay: boolean;
    manual: boolean;
  }>({
    mdns: true,
    dht: true,
    relay: true,
    manual: true
  });

  // Computed discovery indicators
  discoveredPeers = this._discoveredPeers.asReadonly();
  isDiscovering = this._isDiscovering.asReadonly();
  discoveryStats = this._discoveryStats.asReadonly();
  discoveryMethods = this._discoveryMethods.asReadonly();

  peerCount = computed(() => this._discoveredPeers().size);
  activePeerCount = computed(() => {
    const now = Date.now();
    const activeTimeWindow = 5 * 60 * 1000; // 5 minutes
    return Array.from(this._discoveredPeers().values()).filter(
      peer => now - peer.lastSeen < activeTimeWindow
    ).length;
  });

  // Discovery events
  private peerDiscovered$ = new Subject<DiscoveredPeer>();
  private discoveryStarted$ = new Subject<void>();
  private discoveryCompleted$ = new Subject<number>(); // Number of peers discovered
  private discoveryError$ = new Subject<string>();

  private destroy$ = new Subject<void>();

  constructor() {
    this.initializeDiscovery();
    this.setupEventListeners();
    this.startPeriodicDiscovery();
  }

  private initializeDiscovery(): void {
    console.log('P2P Discovery Service initialized');
  }

  private setupEventListeners(): void {
    // Listen for WebRTC peer connections
    this.webrtcService.onPeerConnected$.subscribe(peer => {
      this.addDiscoveredPeer({
        id: peer.id,
        type: 'direct',
        lastSeen: Date.now(),
        metadata: {
          name: peer.name,
          deviceType: peer.deviceType,
          capabilities: peer.capabilities
        }
      });
    });

    // Listen for WebRTC peer disconnections
    this.webrtcService.onPeerDisconnected$.subscribe(peer => {
      // Don't remove the peer, just update the last seen time
      this.updatePeerLastSeen(peer.id);
    });

    // Listen for discovery messages
    this.webrtcService.onDataReceived$.pipe(
      filter(data => data.type === 'discovery')
    ).subscribe(data => {
      this.handleDiscoveryMessage(data);
    });
  }

  private startPeriodicDiscovery(): void {
    // Run discovery every 5 minutes
    interval(5 * 60 * 1000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.startDiscovery();
    });
  }

  // Public API Methods
  async startDiscovery(options?: {
    methods?: {
      mdns?: boolean;
      dht?: boolean;
      relay?: boolean;
      manual?: boolean;
    };
    timeout?: number;
  }): Promise<number> {
    if (this._isDiscovering()) {
      console.log('Discovery already in progress');
      return 0;
    }

    try {
      this._isDiscovering.set(true);
      this.discoveryStarted$.next();

      // Update discovery methods if provided
      if (options?.methods) {
        this._discoveryMethods.update(methods => ({
          ...methods,
          ...options.methods
        }));
      }

      const methods = this._discoveryMethods();
      const startTime = Date.now();
      let discoveredCount = 0;

      // Run discovery methods in parallel
      const discoveryPromises: Promise<DiscoveredPeer[]>[] = [];

      if (methods.mdns) {
        discoveryPromises.push(this.discoverViaMDNS());
      }

      if (methods.dht) {
        discoveryPromises.push(this.discoverViaDHT());
      }

      if (methods.relay) {
        discoveryPromises.push(this.discoverViaRelay());
      }

      if (methods.manual) {
        discoveryPromises.push(this.discoverViaManualList());
      }

      // Wait for all discovery methods to complete or timeout
      const timeout = options?.timeout || 30000; // 30 seconds default
      const timeoutPromise = new Promise<DiscoveredPeer[]>(resolve => {
        setTimeout(() => resolve([]), timeout);
      });

      const results = await Promise.race([
        Promise.all(discoveryPromises),
        timeoutPromise
      ]);

      // Flatten results and filter duplicates
      const allDiscoveredPeers = results.flat();
      const uniquePeers = new Map<string, DiscoveredPeer>();

      for (const peer of allDiscoveredPeers) {
        if (!uniquePeers.has(peer.id)) {
          uniquePeers.set(peer.id, peer);
          this.addDiscoveredPeer(peer);
          discoveredCount++;
        }
      }

      // Update discovery stats
      const discoveryTime = Date.now() - startTime;
      this.updateDiscoveryStats(discoveredCount, discoveryTime);

      // Emit completion event
      this.discoveryCompleted$.next(discoveredCount);

      this.analyticsService.trackEvent('system_event', 'p2p', 'discovery_completed', undefined, discoveredCount);

      return discoveredCount;
    } catch (error) {
      console.error('Discovery failed:', error);
      if (error instanceof Error) {
        this.discoveryError$.next(error.message);
      } else {
        this.discoveryError$.next('Unknown error');
      }
      this.analyticsService.trackError('p2p', 'Discovery failed', { error });
      return 0;
    } finally {
      this._isDiscovering.set(false);
    }
  }

  async connectToPeer(peerId: string): Promise<boolean> {
    const peer = this._discoveredPeers().get(peerId);
    if (!peer) {
      console.warn(`Peer ${peerId} not found`);
      return false;
    }

    try {
      // Check if peer is blocked
      if (this.securityService.isBlocked(peerId)) {
        console.warn(`Peer ${peerId} is blocked`);
        return false;
      }

      // Connect to peer
      const connected = await this.webrtcService.connectToPeer(peerId);
      
      if (connected) {
        // Update peer last seen
        this.updatePeerLastSeen(peerId);
        
        this.analyticsService.trackEvent('system_event', 'p2p', 'peer_connected', peer.type);
      }
      
      return connected;
    } catch (error) {
      console.error(`Failed to connect to peer ${peerId}:`, error);
      this.analyticsService.trackError('p2p', 'Connection failed', { peerId, error });
      return false;
    }
  }

  async connectToMultiplePeers(count: number = 5): Promise<number> {
    // Get active peers sorted by last seen (most recent first)
    const activePeers = Array.from(this._discoveredPeers().values())
      .filter(peer => !this.securityService.isBlocked(peer.id))
      .sort((a, b) => b.lastSeen - a.lastSeen);
    
    // Limit to requested count
    const peersToConnect = activePeers.slice(0, count);
    
    let connectedCount = 0;
    
    for (const peer of peersToConnect) {
      const connected = await this.connectToPeer(peer.id);
      if (connected) {
        connectedCount++;
      }
    }
    
    return connectedCount;
  }

  getPeerById(peerId: string): DiscoveredPeer | undefined {
    return this._discoveredPeers().get(peerId);
  }

  getPeersByType(type: DiscoveredPeer['type']): DiscoveredPeer[] {
    return Array.from(this._discoveredPeers().values()).filter(peer => peer.type === type);
  }

  getActivePeers(): DiscoveredPeer[] {
    const now = Date.now();
    const activeTimeWindow = 5 * 60 * 1000; // 5 minutes
    
    return Array.from(this._discoveredPeers().values()).filter(
      peer => now - peer.lastSeen < activeTimeWindow
    );
  }

  removePeer(peerId: string): void {
    const peers = new Map(this._discoveredPeers());
    peers.delete(peerId);
    this._discoveredPeers.set(peers);
  }

  clearDiscoveredPeers(): void {
    this._discoveredPeers.set(new Map());
  }

  setDiscoveryMethods(methods: {
    mdns?: boolean;
    dht?: boolean;
    relay?: boolean;
    manual?: boolean;
  }): void {
    this._discoveryMethods.update(current => ({
      ...current,
      ...methods
    }));
  }

  // Event Observables
  get onPeerDiscovered$(): Observable<DiscoveredPeer> {
    return this.peerDiscovered$.asObservable();
  }

  get onDiscoveryStarted$(): Observable<void> {
    return this.discoveryStarted$.asObservable();
  }

  get onDiscoveryCompleted$(): Observable<number> {
    return this.discoveryCompleted$.asObservable();
  }

  get onDiscoveryError$(): Observable<string> {
    return this.discoveryError$.asObservable();
  }

  // Private Methods
  private async discoverViaMDNS(): Promise<DiscoveredPeer[]> {
    console.log('Discovering peers via mDNS...');
    
    // In a real implementation, this would use the mDNS API
    // For demo purposes, we'll return some simulated peers
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    return [
      {
        id: `mdns_peer_${Math.random().toString(36).substring(2, 9)}`,
        type: 'mdns',
        address: '192.168.1.100',
        port: 8080,
        lastSeen: Date.now(),
        metadata: {
          name: 'mDNS Peer',
          deviceType: 'mobile',
          capabilities: ['messaging', 'emergency']
        }
      },
      {
        id: `mdns_peer_${Math.random().toString(36).substring(2, 9)}`,
        type: 'mdns',
        address: '192.168.1.101',
        port: 8080,
        lastSeen: Date.now(),
        metadata: {
          name: 'mDNS Peer 2',
          deviceType: 'desktop',
          capabilities: ['messaging', 'emergency', 'relay']
        }
      }
    ];
  }

  private async discoverViaDHT(): Promise<DiscoveredPeer[]> {
    console.log('Discovering peers via DHT...');
    
    // In a real implementation, this would use a DHT library
    // For demo purposes, we'll return some simulated peers
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    return [
      {
        id: `dht_peer_${Math.random().toString(36).substring(2, 9)}`,
        type: 'dht',
        lastSeen: Date.now(),
        metadata: {
          name: 'DHT Peer',
          deviceType: 'mobile',
          capabilities: ['messaging']
        }
      },
      {
        id: `dht_peer_${Math.random().toString(36).substring(2, 9)}`,
        type: 'dht',
        lastSeen: Date.now(),
        metadata: {
          name: 'DHT Peer 2',
          deviceType: 'mobile',
          capabilities: ['messaging', 'emergency']
        }
      }
    ];
  }

  private async discoverViaRelay(): Promise<DiscoveredPeer[]> {
    console.log('Discovering peers via relay servers...');
    
    // In a real implementation, this would contact relay servers
    // For demo purposes, we'll return some simulated peers
    await new Promise(resolve => setTimeout(resolve, 800));
    
    return [
      {
        id: `relay_peer_${Math.random().toString(36).substring(2, 9)}`,
        type: 'relay',
        lastSeen: Date.now(),
        metadata: {
          name: 'Relay Peer',
          deviceType: 'desktop',
          capabilities: ['messaging', 'emergency', 'relay']
        }
      }
    ];
  }

  private async discoverViaManualList(): Promise<DiscoveredPeer[]> {
    console.log('Discovering peers via manual list...');
    
    // In a real implementation, this would use a stored list of known peers
    // For demo purposes, we'll return some simulated peers
    await new Promise(resolve => setTimeout(resolve, 500));
    
    return [
      {
        id: `manual_peer_${Math.random().toString(36).substring(2, 9)}`,
        type: 'manual',
        address: '192.168.1.200',
        port: 8080,
        lastSeen: Date.now(),
        metadata: {
          name: 'Manual Peer',
          deviceType: 'desktop',
          capabilities: ['messaging', 'emergency', 'relay']
        }
      }
    ];
  }

  private addDiscoveredPeer(peer: DiscoveredPeer): void {
    // Check if peer already exists
    const existingPeer = this._discoveredPeers().get(peer.id);
    
    if (existingPeer) {
      // Update existing peer
      const updatedPeer = {
        ...existingPeer,
        ...peer,
        lastSeen: Date.now()
      };
      
      const peers = new Map(this._discoveredPeers());
      peers.set(peer.id, updatedPeer);
      this._discoveredPeers.set(peers);
    } else {
      // Add new peer
      const peers = new Map(this._discoveredPeers());
      peers.set(peer.id, peer);
      this._discoveredPeers.set(peers);
      
      // Emit event
      this.peerDiscovered$.next(peer);
    }
  }

  private updatePeerLastSeen(peerId: string): void {
    const peer = this._discoveredPeers().get(peerId);
    
    if (peer) {
      const updatedPeer = {
        ...peer,
        lastSeen: Date.now()
      };
      
      const peers = new Map(this._discoveredPeers());
      peers.set(peerId, updatedPeer);
      this._discoveredPeers.set(peers);
    }
  }

  private updateDiscoveryStats(discoveredCount: number, discoveryTime: number): void {
    this._discoveryStats.update(stats => {
      const newTotalDiscovered = stats.totalDiscovered + discoveredCount;
      const newActiveDiscoveries = stats.activeDiscoveries + 1;
      
      // Calculate success rate
      const successRate = discoveredCount > 0 ? 
        ((stats.successRate * stats.activeDiscoveries) + 100) / newActiveDiscoveries : 
        ((stats.successRate * stats.activeDiscoveries)) / newActiveDiscoveries;
      
      // Calculate average discovery time
      const avgDiscoveryTime = 
        ((stats.averageDiscoveryTime * stats.activeDiscoveries) + discoveryTime) / 
        newActiveDiscoveries;
      
      return {
        totalDiscovered: newTotalDiscovered,
        activeDiscoveries: newActiveDiscoveries,
        successRate,
        averageDiscoveryTime: avgDiscoveryTime,
        lastDiscoveryTime: Date.now()
      };
    });
  }

  private handleDiscoveryMessage(data: any): void {
    if (!data.payload) return;
    
    const payload = data.payload;
    
    if (payload.type === 'announcement') {
      // Peer is announcing itself
      this.addDiscoveredPeer({
        id: data.sender,
        type: 'direct',
        lastSeen: Date.now(),
        metadata: payload.metadata
      });
      
      // Send response
      this.sendDiscoveryResponse(data.sender);
    } else if (payload.type === 'response') {
      // Peer is responding to our announcement
      this.addDiscoveredPeer({
        id: data.sender,
        type: 'direct',
        lastSeen: Date.now(),
        metadata: payload.metadata
      });
    }
  }

  private async sendDiscoveryResponse(peerId: string): Promise<void> {
    try {
      await this.webrtcService.sendData(peerId, {
        type: 'discovery',
        payload: {
          type: 'response',
          metadata: {
            name: 'My Device',
            deviceType: 'mobile',
            capabilities: ['messaging', 'emergency'],
            version: '1.0.0'
          }
        },
        priority: 'normal'
      });
    } catch (error) {
      console.error(`Failed to send discovery response to ${peerId}:`, error);
    }
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}