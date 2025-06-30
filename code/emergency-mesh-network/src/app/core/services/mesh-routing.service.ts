import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval } from 'rxjs';
import { filter, map, takeUntil } from 'rxjs/operators';

import { MeshNetworkImplementationService, MeshNetworkNode, MeshNetwork } from './mesh-network-implementation.service';
import { LocationService } from './location.service';
import { AnalyticsService } from './analytics.service';

export interface MeshRoute {
  destination: string;
  nextHop: string;
  hopCount: number;
  metric: number;
  lastUpdated: number;
  isActive: boolean;
  reliability: number;
  bandwidth: number;
  emergencyPriority: boolean;
}

export interface RoutingTableEntry {
  destination: string;
  routes: MeshRoute[];
}

export interface RoutingMetrics {
  averagePathLength: number;
  networkDiameter: number;
  routingTableSize: number;
  routeDiscoveryLatency: number;
  routeSuccessRate: number;
  routeOptimality: number;
}

export interface RoutingProtocolConfig {
  protocol: 'aodv' | 'olsr' | 'dsr' | 'gpsr' | 'hybrid';
  updateInterval: number;
  maxHops: number;
  routeTimeout: number;
  routeCacheSize: number;
  emergencyRouting: boolean;
  geographicRouting: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class MeshRoutingService {
  private meshService = inject(MeshNetworkImplementationService);
  private locationService = inject(LocationService);
  private analyticsService = inject(AnalyticsService);

  // Signals for reactive routing state
  private _routingTable = signal<Map<string, RoutingTableEntry>>(new Map());
  private _routingMetrics = signal<RoutingMetrics>({
    averagePathLength: 0,
    networkDiameter: 0,
    routingTableSize: 0,
    routeDiscoveryLatency: 0,
    routeSuccessRate: 0,
    routeOptimality: 0
  });
  private _routingConfig = signal<RoutingProtocolConfig>({
    protocol: 'hybrid',
    updateInterval: 60000, // 1 minute
    maxHops: 10,
    routeTimeout: 300000, // 5 minutes
    routeCacheSize: 100,
    emergencyRouting: true,
    geographicRouting: true
  });
  private _isEmergencyRouting = signal<boolean>(false);

  // Computed routing indicators
  routingTable = this._routingTable.asReadonly();
  routingMetrics = this._routingMetrics.asReadonly();
  routingConfig = this._routingConfig.asReadonly();
  isEmergencyRouting = this._isEmergencyRouting.asReadonly();

  routeCount = computed(() => this._routingTable().size);
  activeRouteCount = computed(() => {
    let count = 0;
    this._routingTable().forEach(entry => {
      if (entry.routes.some(route => route.isActive)) count++;
    });
    return count;
  });
  routingEfficiency = computed(() => this._routingMetrics().routeOptimality);

  // Routing events
  private routeDiscovered$ = new Subject<MeshRoute>();
  private routeExpired$ = new Subject<string>();
  private routingTableUpdated$ = new Subject<Map<string, RoutingTableEntry>>();
  private emergencyRouteEstablished$ = new Subject<MeshRoute>();

  private destroy$ = new Subject<void>();

  constructor() {
    this.initializeRoutingService();
    this.startRoutingProtocol();
    this.setupEmergencyRouting();
  }

  private initializeRoutingService(): void {
    // Initialize routing table
    this.loadRoutingTable();
    
    // Setup event listeners
    this.setupMeshEvents();
    
    console.log('Mesh Routing Service initialized');
  }

  private startRoutingProtocol(): void {
    const config = this._routingConfig();
    
    // Start periodic routing updates
    interval(config.updateInterval).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.updateRoutingTable();
    });
    
    // Start route maintenance
    interval(30000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.maintainRoutes();
    });
  }

  private setupEmergencyRouting(): void {
    // Listen for emergency mode changes
    this.meshService.isEmergencyMode.subscribe(isEmergency => {
      this._isEmergencyRouting.set(isEmergency);
      
      if (isEmergency) {
        this.optimizeForEmergencyRouting();
      } else {
        this.restoreNormalRouting();
      }
    });
  }

  private setupMeshEvents(): void {
    // Listen for mesh network changes
    this.meshService.onMeshNetworkFormed$.subscribe(network => {
      this.initializeRoutesForNetwork(network);
    });
    
    this.meshService.onMeshNodeJoined$.subscribe(({ networkId, node }) => {
      this.addRoutesToNode(networkId, node);
    });
    
    this.meshService.onMeshNodeLeft$.subscribe(({ networkId, nodeId }) => {
      this.removeRoutesForNode(nodeId);
    });
  }

  // Public API Methods
  async findRoute(destination: string, options?: {
    emergency?: boolean;
    maxHops?: number;
    requireReliability?: number;
  }): Promise<MeshRoute | null> {
    const routingTable = this._routingTable();
    const entry = routingTable.get(destination);
    
    if (!entry || entry.routes.length === 0) {
      // No routes found, try to discover
      return await this.discoverRoute(destination, options);
    }
    
    // Filter routes based on options
    let availableRoutes = entry.routes.filter(route => route.isActive);
    
    if (options?.emergency) {
      availableRoutes = availableRoutes.filter(route => route.emergencyPriority);
    }
    
    const maxHops = options?.maxHops ?? 10; // or another sensible default
    const requireReliability = options?.requireReliability ?? 0.5; // or another sensible default

    if (maxHops !== undefined) {
      availableRoutes = availableRoutes.filter(route => route.hopCount <= maxHops);
    }

    if (requireReliability !== undefined) {
      availableRoutes = availableRoutes.filter(route => route.reliability >= requireReliability);
    }
    
    if (availableRoutes.length === 0) {
      // No suitable routes, try to discover
      return await this.discoverRoute(destination, options);
    }
    
    // Sort routes by metric (lower is better)
    availableRoutes.sort((a, b) => a.metric - b.metric);
    
    return availableRoutes[0];
  }

  async discoverRoute(destination: string, options?: {
    emergency?: boolean;
    maxHops?: number;
    timeout?: number;
  }): Promise<MeshRoute | null> {
    const config = this._routingConfig();
    const maxHops = options?.maxHops || config.maxHops;
    const timeout = options?.timeout || 10000; // 10 seconds default
    
    // Implement route discovery based on current protocol
    switch (config.protocol) {
      case 'aodv':
        return await this.discoverRouteAODV(destination, maxHops, timeout);
      case 'olsr':
        return await this.discoverRouteOLSR(destination);
      case 'dsr':
        return await this.discoverRouteDSR(destination, maxHops, timeout);
      case 'gpsr':
        return await this.discoverRouteGPSR(destination);
      case 'hybrid':
      default:
        return await this.discoverRouteHybrid(destination, maxHops, timeout, options?.emergency);
    }
  }

  updateRoutingConfig(config: Partial<RoutingProtocolConfig>): void {
    const currentConfig = this._routingConfig();
    this._routingConfig.set({ ...currentConfig, ...config });
    
    // Restart routing protocol if protocol changed
    if (config.protocol && config.protocol !== currentConfig.protocol) {
      this.restartRoutingProtocol();
    }
  }

  getRoutesForDestination(destination: string): MeshRoute[] {
    const entry = this._routingTable().get(destination);
    return entry ? entry.routes : [];
  }

  invalidateRoute(destination: string, nextHop: string): void {
    const routingTable = new Map(this._routingTable());
    const entry = routingTable.get(destination);
    
    if (entry) {
      const routes = entry.routes.map(route => {
        if (route.nextHop === nextHop) {
          return { ...route, isActive: false };
        }
        return route;
      });
      
      routingTable.set(destination, { ...entry, routes });
      this._routingTable.set(routingTable);
      
      this.routeExpired$.next(destination);
    }
  }

  clearRoutingTable(): void {
    this._routingTable.set(new Map());
    this.saveRoutingTable();
  }

  // Event Observables
  get onRouteDiscovered$(): Observable<MeshRoute> {
    return this.routeDiscovered$.asObservable();
  }

  get onRouteExpired$(): Observable<string> {
    return this.routeExpired$.asObservable();
  }

  get onRoutingTableUpdated$(): Observable<Map<string, RoutingTableEntry>> {
    return this.routingTableUpdated$.asObservable();
  }

  get onEmergencyRouteEstablished$(): Observable<MeshRoute> {
    return this.emergencyRouteEstablished$.asObservable();
  }

  // Private Methods
  private async discoverRouteAODV(destination: string, maxHops: number, timeout: number): Promise<MeshRoute | null> {
    // Ad-hoc On-demand Distance Vector routing implementation
    // 1. Send route request (RREQ)
    // 2. Wait for route reply (RREP)
    // 3. Update routing table
    
    // Simplified implementation
    await new Promise(resolve => setTimeout(resolve, 500));
    
    const route: MeshRoute = {
      destination,
      nextHop: this.generateRandomNodeId(),
      hopCount: Math.floor(Math.random() * maxHops) + 1,
      metric: Math.floor(Math.random() * 100) + 50,
      lastUpdated: Date.now(),
      isActive: true,
      reliability: Math.floor(Math.random() * 30) + 70,
      bandwidth: Math.floor(Math.random() * 500) + 500,
      emergencyPriority: false
    };
    
    this.addRoute(route);
    return route;
  }

  private async discoverRouteOLSR(destination: string): Promise<MeshRoute | null> {
    // Optimized Link State Routing implementation
    // Uses proactive routing with multipoint relays
    
    // Simplified implementation
    const routingTable = this._routingTable();
    const entry = routingTable.get(destination);
    
    if (entry && entry.routes.some(route => route.isActive)) {
      return entry.routes.find(route => route.isActive) || null;
    }
    
    return null;
  }

  private async discoverRouteDSR(destination: string, maxHops: number, timeout: number): Promise<MeshRoute | null> {
    // Dynamic Source Routing implementation
    // 1. Send route request with path accumulation
    // 2. Receive route reply with complete path
    // 3. Cache route
    
    // Simplified implementation
    await new Promise(resolve => setTimeout(resolve, 700));
    
    const route: MeshRoute = {
      destination,
      nextHop: this.generateRandomNodeId(),
      hopCount: Math.floor(Math.random() * maxHops) + 1,
      metric: Math.floor(Math.random() * 100) + 50,
      lastUpdated: Date.now(),
      isActive: true,
      reliability: Math.floor(Math.random() * 30) + 70,
      bandwidth: Math.floor(Math.random() * 500) + 500,
      emergencyPriority: false
    };
    
    this.addRoute(route);
    return route;
  }

  private async discoverRouteGPSR(destination: string): Promise<MeshRoute | null> {
    // Greedy Perimeter Stateless Routing implementation
    // Uses geographic positions for routing
    
    // Simplified implementation
    if (!this._routingConfig().geographicRouting) {
      return null;
    }
    
    await new Promise(resolve => setTimeout(resolve, 300));
    
    const route: MeshRoute = {
      destination,
      nextHop: this.generateRandomNodeId(),
      hopCount: 1,
      metric: 50,
      lastUpdated: Date.now(),
      isActive: true,
      reliability: 90,
      bandwidth: 800,
      emergencyPriority: false
    };
    
    this.addRoute(route);
    return route;
  }

  private async discoverRouteHybrid(
    destination: string, 
    maxHops: number, 
    timeout: number,
    isEmergency: boolean = false
  ): Promise<MeshRoute | null> {
    // Hybrid routing implementation
    // Combines reactive (AODV) and proactive (OLSR) approaches
    // Uses geographic routing when available
    
    // Try geographic routing first if available
    if (this._routingConfig().geographicRouting) {
      const gpsrRoute = await this.discoverRouteGPSR(destination);
      if (gpsrRoute) return gpsrRoute;
    }
    
    // Try AODV for reactive discovery
    const aodvRoute = await this.discoverRouteAODV(destination, maxHops, timeout);
    
    // Mark as emergency route if needed
    if (aodvRoute && isEmergency) {
      aodvRoute.emergencyPriority = true;
      this.emergencyRouteEstablished$.next(aodvRoute);
    }
    
    return aodvRoute;
  }

  private addRoute(route: MeshRoute): void {
    const routingTable = new Map(this._routingTable());
    const entry = routingTable.get(route.destination);
    
    if (entry) {
      // Update existing entry
      const existingRouteIndex = entry.routes.findIndex(r => r.nextHop === route.nextHop);
      
      if (existingRouteIndex !== -1) {
        // Update existing route
        const updatedRoutes = [...entry.routes];
        updatedRoutes[existingRouteIndex] = route;
        routingTable.set(route.destination, { ...entry, routes: updatedRoutes });
      } else {
        // Add new route
        routingTable.set(route.destination, { 
          ...entry, 
          routes: [...entry.routes, route] 
        });
      }
    } else {
      // Create new entry
      routingTable.set(route.destination, {
        destination: route.destination,
        routes: [route]
      });
    }
    
    this._routingTable.set(routingTable);
    this.saveRoutingTable();
    
    this.routeDiscovered$.next(route);
    this.routingTableUpdated$.next(routingTable);
  }

  private updateRoutingTable(): void {
    // Update routing table based on current mesh networks
    const networks = this.meshService.activeMeshNetworks();
    
    for (const network of networks.values()) {
      this.updateRoutesForNetwork(network);
    }
    
    // Update routing metrics
    this.updateRoutingMetrics();
    
    this.routingTableUpdated$.next(this._routingTable());
  }

  private updateRoutesForNetwork(network: MeshNetwork): void {
    const nodes = Array.from(network.nodes.values());
    
    // Update routes to all nodes in the network
    for (const node of nodes) {
      // Skip local node
      if (node.id === this.meshService.localMeshNode()?.id) continue;
      
      // Create or update route
      const route: MeshRoute = {
        destination: node.id,
        nextHop: this.findNextHop(node, network),
        hopCount: this.estimateHopCount(node, network),
        metric: this.calculateRouteMetric(node, network),
        lastUpdated: Date.now(),
        isActive: true,
        reliability: this.estimateReliability(node, network),
        bandwidth: this.estimateBandwidth(node, network),
        emergencyPriority: node.emergencyStatus !== 'normal'
      };
      
      this.addRoute(route);
    }
  }

  private findNextHop(targetNode: MeshNetworkNode, network: MeshNetwork): string {
    // In a real implementation, this would use the network topology
    // to find the best next hop to reach the target node
    
    // Simplified implementation
    return targetNode.id;
  }

  private estimateHopCount(targetNode: MeshNetworkNode, network: MeshNetwork): number {
    // Estimate hop count based on network topology and node distance
    
    // Simplified implementation
    return Math.floor(Math.random() * 3) + 1;
  }

  private calculateRouteMetric(targetNode: MeshNetworkNode, network: MeshNetwork): number {
    // Calculate route metric based on multiple factors:
    // - Signal strength
    // - Battery level
    // - Hop count
    // - Node type (relay nodes preferred)
    
    // Simplified implementation
    const signalFactor = (100 - targetNode.signalStrength) * 0.5;
    const batteryFactor = (100 - targetNode.batteryLevel) * 0.3;
    const hopFactor = this.estimateHopCount(targetNode, network) * 10;
    const typeFactor = targetNode.type === 'relay' ? -10 : 0;
    
    return Math.round(signalFactor + batteryFactor + hopFactor + typeFactor);
  }

  private estimateReliability(targetNode: MeshNetworkNode, network: MeshNetwork): number {
    // Estimate route reliability based on node characteristics
    
    // Simplified implementation
    const signalFactor = targetNode.signalStrength * 0.5;
    const batteryFactor = targetNode.batteryLevel * 0.3;
    const typeFactor = targetNode.type === 'relay' ? 10 : 0;
    
    return Math.min(100, Math.round(signalFactor + batteryFactor + typeFactor));
  }

  private estimateBandwidth(targetNode: MeshNetworkNode, network: MeshNetwork): number {
    // Estimate available bandwidth to the node
    
    // Simplified implementation
    const baseBandwidth = 1000; // 1000 kbps
    const signalFactor = targetNode.signalStrength / 100;
    
    return Math.round(baseBandwidth * signalFactor);
  }

  private maintainRoutes(): void {
    const routingTable = new Map(this._routingTable());
    const config = this._routingConfig();
    const now = Date.now();
    
    // Check for expired routes
    routingTable.forEach((entry, destination) => {
      const updatedRoutes = entry.routes.map(route => {
        if (now - route.lastUpdated > config.routeTimeout) {
          return { ...route, isActive: false };
        }
        return route;
      });
      
      routingTable.set(destination, { ...entry, routes: updatedRoutes });
      
      // Emit event for expired routes
      const newlyExpired = updatedRoutes.filter(route => 
        !route.isActive && 
        entry.routes.find(r => r.nextHop === route.nextHop)?.isActive
      );
      
      for (const route of newlyExpired) {
        this.routeExpired$.next(destination);
      }
    });
    
    this._routingTable.set(routingTable);
    this.saveRoutingTable();
  }

  private updateRoutingMetrics(): void {
    const routingTable = this._routingTable();
    const activeRoutes = Array.from(routingTable.values())
      .flatMap(entry => entry.routes)
      .filter(route => route.isActive);
    
    if (activeRoutes.length === 0) {
      return;
    }
    
    // Calculate metrics
    const pathLengths = activeRoutes.map(route => route.hopCount);
    const averagePathLength = pathLengths.reduce((sum, length) => sum + length, 0) / pathLengths.length;
    const networkDiameter = Math.max(...pathLengths);
    
    const metrics: RoutingMetrics = {
      averagePathLength,
      networkDiameter,
      routingTableSize: routingTable.size,
      routeDiscoveryLatency: 150, // Simulated value (ms)
      routeSuccessRate: 95, // Simulated value (%)
      routeOptimality: 85 // Simulated value (%)
    };
    
    this._routingMetrics.set(metrics);
  }

  private optimizeForEmergencyRouting(): void {
    // Adjust routing parameters for emergency mode
    const config = this._routingConfig();
    
    this._routingConfig.set({
      ...config,
      updateInterval: 30000, // More frequent updates
      maxHops: 15, // Allow longer routes
      routeTimeout: 600000, // Longer timeouts
      emergencyRouting: true
    });
    
    // Prioritize emergency routes
    this.prioritizeEmergencyRoutes();
  }

  private restoreNormalRouting(): void {
    // Restore normal routing parameters
    const config = this._routingConfig();
    
    this._routingConfig.set({
      ...config,
      updateInterval: 60000,
      maxHops: 10,
      routeTimeout: 300000,
      emergencyRouting: false
    });
  }

  private prioritizeEmergencyRoutes(): void {
    const routingTable = new Map(this._routingTable());
    
    // Find nodes with emergency status
    const emergencyNodes = Array.from(this.meshService.activeMeshNetworks().values())
      .flatMap(network => Array.from(network.nodes.values()))
      .filter(node => node.emergencyStatus !== 'normal');
    
    // Prioritize routes to emergency nodes
    for (const node of emergencyNodes) {
      const entry = routingTable.get(node.id);
      
      if (entry) {
        const updatedRoutes = entry.routes.map(route => ({
          ...route,
          emergencyPriority: true
        }));
        
        routingTable.set(node.id, { ...entry, routes: updatedRoutes });
      }
    }
    
    this._routingTable.set(routingTable);
  }

  private initializeRoutesForNetwork(network: MeshNetwork): void {
    // Initialize routes for all nodes in the network
    this.updateRoutesForNetwork(network);
  }

  private addRoutesToNode(networkId: string, node: MeshNetworkNode): void {
    const networks = this.meshService.activeMeshNetworks();
    const network = networks.get(networkId);
    
    if (!network) return;
    
    // Create route to the new node
    const route: MeshRoute = {
      destination: node.id,
      nextHop: node.id, // Direct route
      hopCount: 1,
      metric: this.calculateRouteMetric(node, network),
      lastUpdated: Date.now(),
      isActive: true,
      reliability: this.estimateReliability(node, network),
      bandwidth: this.estimateBandwidth(node, network),
      emergencyPriority: node.emergencyStatus !== 'normal'
    };
    
    this.addRoute(route);
  }

  private removeRoutesForNode(nodeId: string): void {
    const routingTable = new Map(this._routingTable());
    
    // Remove routes to this node
    routingTable.delete(nodeId);
    
    // Remove routes through this node
    routingTable.forEach((entry, destination) => {
      const updatedRoutes = entry.routes.filter(route => route.nextHop !== nodeId);
      
      if (updatedRoutes.length === 0) {
        routingTable.delete(destination);
      } else {
        routingTable.set(destination, { ...entry, routes: updatedRoutes });
      }
    });
    
    this._routingTable.set(routingTable);
    this.saveRoutingTable();
  }

  private restartRoutingProtocol(): void {
    // Restart routing protocol with new configuration
    this.startRoutingProtocol();
  }

  private loadRoutingTable(): void {
    try {
      const savedTable = localStorage.getItem('mesh_routing_table');
      if (savedTable) {
        const parsed = JSON.parse(savedTable);
        const routingTable = new Map<string, RoutingTableEntry>();
        
        Object.entries(parsed).forEach(([key, value]) => {
          routingTable.set(key, value as RoutingTableEntry);
        });
        
        this._routingTable.set(routingTable);
      }
    } catch (error) {
      console.error('Failed to load routing table:', error);
    }
  }

  private saveRoutingTable(): void {
    try {
      const routingTable = this._routingTable();
      const serialized = JSON.stringify(Object.fromEntries(routingTable));
      localStorage.setItem('mesh_routing_table', serialized);
    } catch (error) {
      console.error('Failed to save routing table:', error);
    }
  }

  private generateRandomNodeId(): string {
    return `node_${Math.random().toString(36).substring(2, 9)}`;
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}