import { Injectable, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

import { MeshNetworkImplementationService } from '../../core/services/mesh-network-implementation.service';
import { MeshRoutingService } from '../../core/services/mesh-routing.service';
import { MeshRoutingAlgorithmsService } from '../../core/services/mesh-routing-algorithms.service';
import { AnalyticsService } from '../../core/services/analytics.service';

export interface SimulationNode {
  id: string;
  type: 'coordinator' | 'relay' | 'endpoint' | 'bridge';
  x: number;
  y: number;
  signalStrength: number;
  batteryLevel: number;
  isOnline: boolean;
  emergencyStatus: 'normal' | 'alert' | 'emergency' | 'critical';
  connections: string[];
  messageQueue: SimulationMessage[];
  batteryDrainRate: number;
  movementPattern?: 'static' | 'random' | 'directed';
  movementSpeed?: number;
  movementTarget?: { x: number; y: number };
}

export interface SimulationMessage {
  id: string;
  source: string;
  destination: string;
  content: string;
  priority: 'low' | 'normal' | 'high' | 'emergency';
  size: number;
  createdAt: number;
  deliveredAt?: number;
  status: 'queued' | 'sending' | 'delivered' | 'failed';
  route: string[];
  hopCount: number;
  ttl: number;
}

export interface SimulationEvent {
  id: string;
  type: 'node_failure' | 'battery_depletion' | 'signal_degradation' | 'emergency_activation' | 'message_loss' | 'network_partition';
  nodeId?: string;
  timestamp: number;
  description: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  resolved: boolean;
  resolvedAt?: number;
}

export interface SimulationScenario {
  id: string;
  name: string;
  description: string;
  duration: number;
  nodeCount: number;
  messageRate: number;
  failureRate: number;
  emergencyProbability: number;
  mobilityFactor: number;
  batteryDrainFactor: number;
  signalInterferenceFactor: number;
  events: SimulationEvent[];
}

export interface SimulationMetrics {
  messageDeliveryRate: number;
  averageLatency: number;
  networkReliability: number;
  batteryConsumption: number;
  routingEfficiency: number;
  emergencyResponseTime: number;
  networkCoverage: number;
  nodeFailureRate: number;
}

@Injectable({
  providedIn: 'root'
})
export class NetworkSimulationService {
  private meshService = inject(MeshNetworkImplementationService);
  private routingService = inject(MeshRoutingService);
  private routingAlgorithmsService = inject(MeshRoutingAlgorithmsService);
  private analyticsService = inject(AnalyticsService);

  // Simulation state
  private _simulationNodes = new BehaviorSubject<SimulationNode[]>([]);
  private _simulationMessages = new BehaviorSubject<SimulationMessage[]>([]);
  private _simulationEvents = new BehaviorSubject<SimulationEvent[]>([]);
  private _simulationMetrics = new BehaviorSubject<SimulationMetrics>({
    messageDeliveryRate: 0,
    averageLatency: 0,
    networkReliability: 0,
    batteryConsumption: 0,
    routingEfficiency: 0,
    emergencyResponseTime: 0,
    networkCoverage: 0,
    nodeFailureRate: 0
  });
  private _isSimulationRunning = new BehaviorSubject<boolean>(false);
  private _simulationTime = new BehaviorSubject<number>(0);
  private _simulationSpeed = new BehaviorSubject<number>(1);

  // Simulation events
  private simulationStarted$ = new Subject<SimulationScenario>();
  private simulationStopped$ = new Subject<SimulationMetrics>();
  private simulationTick$ = new Subject<number>();
  private simulationEvent$ = new Subject<SimulationEvent>();

  // Simulation control
  private simulationInterval: any;
  private destroy$ = new Subject<void>();
  private currentScenario: SimulationScenario | null = null;

  constructor() {}

  // Public observables
  get simulationNodes$(): Observable<SimulationNode[]> {
    return this._simulationNodes.asObservable();
  }

  get simulationMessages$(): Observable<SimulationMessage[]> {
    return this._simulationMessages.asObservable();
  }

  get simulationEvents$(): Observable<SimulationEvent[]> {
    return this._simulationEvents.asObservable();
  }

  get simulationMetrics$(): Observable<SimulationMetrics> {
    return this._simulationMetrics.asObservable();
  }

  get isSimulationRunning$(): Observable<boolean> {
    return this._isSimulationRunning.asObservable();
  }

  get simulationTime$(): Observable<number> {
    return this._simulationTime.asObservable();
  }

  get simulationSpeed$(): Observable<number> {
    return this._simulationSpeed.asObservable();
  }

  // Event observables
  get onSimulationStarted$(): Observable<SimulationScenario> {
    return this.simulationStarted$.asObservable();
  }

  get onSimulationStopped$(): Observable<SimulationMetrics> {
    return this.simulationStopped$.asObservable();
  }

  get onSimulationTick$(): Observable<number> {
    return this.simulationTick$.asObservable();
  }

  get onSimulationEvent$(): Observable<SimulationEvent> {
    return this.simulationEvent$.asObservable();
  }

  // Public methods
  startSimulation(scenario: SimulationScenario): void {
    if (this._isSimulationRunning.value) {
      this.stopSimulation();
    }

    this.currentScenario = scenario;
    this._isSimulationRunning.next(true);
    this._simulationTime.next(0);

    // Initialize simulation
    this.initializeSimulation(scenario);

    // Start simulation loop
    const tickInterval = 1000 / this._simulationSpeed.value;
    this.simulationInterval = setInterval(() => {
      this.simulationTick();
    }, tickInterval);

    this.simulationStarted$.next(scenario);
    this.analyticsService.trackEvent('simulation', 'started', scenario.name);
  }

  stopSimulation(): void {
    if (!this._isSimulationRunning.value) return;

    clearInterval(this.simulationInterval);
    this._isSimulationRunning.next(false);

    // Calculate final metrics
    const finalMetrics = this.calculateSimulationMetrics();
    this._simulationMetrics.next(finalMetrics);

    this.simulationStopped$.next(finalMetrics);
    this.analyticsService.trackEvent('simulation', 'stopped', this.currentScenario?.name || 'unknown');
  }

  pauseSimulation(): void {
    if (!this._isSimulationRunning.value) return;

    clearInterval(this.simulationInterval);
    this._isSimulationRunning.next(false);
  }

  resumeSimulation(): void {
    if (this._isSimulationRunning.value || !this.currentScenario) return;

    this._isSimulationRunning.next(true);

    // Restart simulation loop
    const tickInterval = 1000 / this._simulationSpeed.value;
    this.simulationInterval = setInterval(() => {
      this.simulationTick();
    }, tickInterval);
  }

  setSimulationSpeed(speed: number): void {
    if (speed <= 0) return;

    this._simulationSpeed.next(speed);

    // Update simulation interval if running
    if (this._isSimulationRunning.value) {
      clearInterval(this.simulationInterval);
      
      const tickInterval = 1000 / speed;
      this.simulationInterval = setInterval(() => {
        this.simulationTick();
      }, tickInterval);
    }
  }

  resetSimulation(): void {
    this.stopSimulation();
    this._simulationNodes.next([]);
    this._simulationMessages.next([]);
    this._simulationEvents.next([]);
    this._simulationTime.next(0);
    this.currentScenario = null;
  }

  // Predefined scenarios
  getDefaultScenarios(): SimulationScenario[] {
    return [
      {
        id: 'normal_operation',
        name: 'Normal Operation',
        description: 'Simulates normal network operation with minimal failures',
        duration: 300, // 5 minutes
        nodeCount: 20,
        messageRate: 5, // messages per minute
        failureRate: 0.05, // 5% chance of failure
        emergencyProbability: 0.01, // 1% chance of emergency
        mobilityFactor: 0.2, // 20% mobility
        batteryDrainFactor: 0.5, // 50% normal battery drain
        signalInterferenceFactor: 0.2, // 20% signal interference
        events: []
      },
      {
        id: 'emergency_scenario',
        name: 'Emergency Scenario',
        description: 'Simulates network behavior during an emergency situation',
        duration: 300,
        nodeCount: 30,
        messageRate: 15,
        failureRate: 0.2,
        emergencyProbability: 0.5,
        mobilityFactor: 0.4,
        batteryDrainFactor: 1.0,
        signalInterferenceFactor: 0.6,
        events: []
      },
      {
        id: 'network_stress_test',
        name: 'Network Stress Test',
        description: 'Tests network performance under high load and failure conditions',
        duration: 300,
        nodeCount: 50,
        messageRate: 30,
        failureRate: 0.3,
        emergencyProbability: 0.2,
        mobilityFactor: 0.3,
        batteryDrainFactor: 1.5,
        signalInterferenceFactor: 0.8,
        events: []
      },
      {
        id: 'battery_optimization',
        name: 'Battery Optimization Test',
        description: 'Tests network behavior with focus on battery conservation',
        duration: 300,
        nodeCount: 25,
        messageRate: 8,
        failureRate: 0.1,
        emergencyProbability: 0.05,
        mobilityFactor: 0.1,
        batteryDrainFactor: 0.3,
        signalInterferenceFactor: 0.3,
        events: []
      },
      {
        id: 'routing_algorithm_comparison',
        name: 'Routing Algorithm Comparison',
        description: 'Compares different routing algorithms under similar conditions',
        duration: 300,
        nodeCount: 40,
        messageRate: 20,
        failureRate: 0.15,
        emergencyProbability: 0.1,
        mobilityFactor: 0.3,
        batteryDrainFactor: 0.7,
        signalInterferenceFactor: 0.4,
        events: []
      }
    ];
  }

  // Private methods
  private initializeSimulation(scenario: SimulationScenario): void {
    // Create simulation nodes
    const nodes = this.createSimulationNodes(scenario);
    this._simulationNodes.next(nodes);

    // Initialize messages
    this._simulationMessages.next([]);

    // Initialize events
    this._simulationEvents.next([]);

    // Initialize metrics
    this._simulationMetrics.next({
      messageDeliveryRate: 100,
      averageLatency: 0,
      networkReliability: 100,
      batteryConsumption: 0,
      routingEfficiency: 100,
      emergencyResponseTime: 0,
      networkCoverage: 100,
      nodeFailureRate: 0
    });
  }

  private createSimulationNodes(scenario: SimulationScenario): SimulationNode[] {
    const nodes: SimulationNode[] = [];
    const { nodeCount } = scenario;

    // Create coordinator node
    nodes.push({
      id: 'node_coordinator',
      type: 'coordinator',
      x: 400,
      y: 300,
      signalStrength: 95,
      batteryLevel: 90,
      isOnline: true,
      emergencyStatus: 'normal',
      connections: [],
      messageQueue: [],
      batteryDrainRate: 0.02 * scenario.batteryDrainFactor
    });

    // Create relay nodes (20% of total)
    const relayCount = Math.floor(nodeCount * 0.2);
    for (let i = 0; i < relayCount; i++) {
      nodes.push({
        id: `node_relay_${i}`,
        type: 'relay',
        x: 200 + Math.random() * 400,
        y: 150 + Math.random() * 300,
        signalStrength: 85 + Math.random() * 10,
        batteryLevel: 70 + Math.random() * 20,
        isOnline: true,
        emergencyStatus: 'normal',
        connections: [],
        messageQueue: [],
        batteryDrainRate: 0.05 * scenario.batteryDrainFactor,
        movementPattern: Math.random() < scenario.mobilityFactor ? 'random' : 'static',
        movementSpeed: 0.5 + Math.random() * 1.5
      });
    }

    // Create bridge nodes (10% of total)
    const bridgeCount = Math.floor(nodeCount * 0.1);
    for (let i = 0; i < bridgeCount; i++) {
      nodes.push({
        id: `node_bridge_${i}`,
        type: 'bridge',
        x: 100 + Math.random() * 600,
        y: 100 + Math.random() * 400,
        signalStrength: 80 + Math.random() * 15,
        batteryLevel: 60 + Math.random() * 30,
        isOnline: true,
        emergencyStatus: 'normal',
        connections: [],
        messageQueue: [],
        batteryDrainRate: 0.04 * scenario.batteryDrainFactor,
        movementPattern: Math.random() < scenario.mobilityFactor ? 'random' : 'static',
        movementSpeed: 0.3 + Math.random() * 1.0
      });
    }

    // Create endpoint nodes (remaining)
    const endpointCount = nodeCount - relayCount - bridgeCount - 1;
    for (let i = 0; i < endpointCount; i++) {
      nodes.push({
        id: `node_endpoint_${i}`,
        type: 'endpoint',
        x: 50 + Math.random() * 700,
        y: 50 + Math.random() * 500,
        signalStrength: 70 + Math.random() * 20,
        batteryLevel: 50 + Math.random() * 40,
        isOnline: true,
        emergencyStatus: 'normal',
        connections: [],
        messageQueue: [],
        batteryDrainRate: 0.03 * scenario.batteryDrainFactor,
        movementPattern: Math.random() < scenario.mobilityFactor * 1.5 ? 'random' : 'static',
        movementSpeed: 0.2 + Math.random() * 1.0
      });
    }

    // Create initial connections
    this.createInitialConnections(nodes, scenario);

    return nodes;
  }

  private createInitialConnections(nodes: SimulationNode[], scenario: SimulationScenario): void {
    const coordinator = nodes.find(node => node.type === 'coordinator');
    if (!coordinator) return;

    // Connect coordinator to all relay nodes
    const relays = nodes.filter(node => node.type === 'relay');
    relays.forEach(relay => {
      coordinator.connections.push(relay.id);
      relay.connections.push(coordinator.id);
    });

    // Connect relays to bridges
    const bridges = nodes.filter(node => node.type === 'bridge');
    relays.forEach((relay, index) => {
      // Connect each relay to some bridges
      const bridgesToConnect = Math.min(2, bridges.length);
      for (let i = 0; i < bridgesToConnect; i++) {
        const bridgeIndex = (index + i) % bridges.length;
        const bridge = bridges[bridgeIndex];
        
        relay.connections.push(bridge.id);
        bridge.connections.push(relay.id);
      }
    });

    // Connect bridges and relays to endpoints
    const endpoints = nodes.filter(node => node.type === 'endpoint');
    const connectors = [...relays, ...bridges];

    endpoints.forEach(endpoint => {
      // Connect each endpoint to 1-3 connectors
      const connectCount = 1 + Math.floor(Math.random() * 3);
      const shuffledConnectors = this.shuffleArray([...connectors]);
      
      for (let i = 0; i < Math.min(connectCount, shuffledConnectors.length); i++) {
        const connector = shuffledConnectors[i];
        
        endpoint.connections.push(connector.id);
        connector.connections.push(endpoint.id);
      }
    });

    // Add some random connections for redundancy
    const connectionProbability = 0.1;
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        if (Math.random() < connectionProbability) {
          const node1 = nodes[i];
          const node2 = nodes[j];
          
          if (!node1.connections.includes(node2.id)) {
            node1.connections.push(node2.id);
            node2.connections.push(node1.id);
          }
        }
      }
    }
  }

  private simulationTick(): void {
    if (!this.currentScenario) return;

    // Update simulation time
    const currentTime = this._simulationTime.value + 1;
    this._simulationTime.next(currentTime);

    // Get current state
    const nodes = [...this._simulationNodes.value];
    const messages = [...this._simulationMessages.value];
    const events = [...this._simulationEvents.value];

    // Check if simulation should end
    if (currentTime >= this.currentScenario.duration) {
      this.stopSimulation();
      return;
    }

    // Update node state
    this.updateNodes(nodes, this.currentScenario);

    // Generate new messages
    const newMessages = this.generateMessages(nodes, this.currentScenario);
    messages.push(...newMessages);

    // Process messages
    this.processMessages(messages, nodes);

    // Generate random events
    const newEvents = this.generateEvents(nodes, this.currentScenario);
    events.push(...newEvents);

    // Process events
    this.processEvents(events, nodes);

    // Update metrics
    const metrics = this.calculateSimulationMetrics();

    // Update state
    this._simulationNodes.next(nodes);
    this._simulationMessages.next(messages);
    this._simulationEvents.next(events);
    this._simulationMetrics.next(metrics);

    // Emit tick event
    this.simulationTick$.next(currentTime);
  }

  private updateNodes(nodes: SimulationNode[], scenario: SimulationScenario): void {
    nodes.forEach(node => {
      // Update battery level
      node.batteryLevel = Math.max(0, node.batteryLevel - node.batteryDrainRate);
      
      // Check if node should go offline due to battery
      if (node.batteryLevel <= 0 && node.isOnline) {
        node.isOnline = false;
        this.addEvent({
          id: `event_battery_${node.id}_${Date.now()}`,
          type: 'battery_depletion',
          nodeId: node.id,
          timestamp: this._simulationTime.value,
          description: `Node ${node.id} went offline due to battery depletion`,
          severity: 'medium',
          resolved: false
        });
      }
      
      // Update node position based on movement pattern
      if (node.isOnline && node.movementPattern && node.movementPattern !== 'static') {
        this.updateNodePosition(node, scenario);
      }
      
      // Random signal strength fluctuation
      if (node.isOnline) {
        const fluctuation = (Math.random() - 0.5) * 2 * scenario.signalInterferenceFactor;
        node.signalStrength = Math.max(0, Math.min(100, node.signalStrength + fluctuation));
      }
      
      // Update connections based on signal strength and distance
      this.updateNodeConnections(node, nodes, scenario);
    });
  }

  private updateNodePosition(node: SimulationNode, scenario: SimulationScenario): void {
    if (!node.movementSpeed) return;
    
    const speed = node.movementSpeed * scenario.mobilityFactor;
    
    if (node.movementPattern === 'random') {
      // Random movement
      const angle = Math.random() * Math.PI * 2;
      node.x += Math.cos(angle) * speed;
      node.y += Math.sin(angle) * speed;
      
      // Boundary check
      node.x = Math.max(0, Math.min(800, node.x));
      node.y = Math.max(0, Math.min(600, node.y));
    } else if (node.movementPattern === 'directed' && node.movementTarget) {
      // Move towards target
      const dx = node.movementTarget.x - node.x;
      const dy = node.movementTarget.y - node.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      
      if (distance > speed) {
        node.x += (dx / distance) * speed;
        node.y += (dy / distance) * speed;
      } else {
        // Reached target, set new random target
        node.movementTarget = {
          x: Math.random() * 800,
          y: Math.random() * 600
        };
      }
    }
  }

  private updateNodeConnections(node: SimulationNode, nodes: SimulationNode[], scenario: SimulationScenario): void {
    if (!node.isOnline) {
      // Remove all connections for offline nodes
      nodes.forEach(otherNode => {
        otherNode.connections = otherNode.connections.filter(id => id !== node.id);
      });
      node.connections = [];
      return;
    }
    
    // Check existing connections
    const connectionsToRemove: string[] = [];
    
    node.connections.forEach(connectionId => {
      const connectedNode = nodes.find(n => n.id === connectionId);
      
      if (!connectedNode || !connectedNode.isOnline) {
        // Remove connection to offline nodes
        connectionsToRemove.push(connectionId);
      } else {
        // Check signal strength and distance
        const distance = this.calculateDistance(node, connectedNode);
        const maxDistance = (node.signalStrength + connectedNode.signalStrength) / 2;
        
        if (distance > maxDistance * 2) {
          // Connection lost due to distance
          connectionsToRemove.push(connectionId);
          
          // Add event
          this.addEvent({
            id: `event_connection_lost_${node.id}_${connectionId}_${Date.now()}`,
            type: 'signal_degradation',
            nodeId: node.id,
            timestamp: this._simulationTime.value,
            description: `Connection lost between ${node.id} and ${connectionId} due to distance`,
            severity: 'low',
            resolved: false
          });
        }
      }
    });
    
    // Remove connections
    node.connections = node.connections.filter(id => !connectionsToRemove.includes(id));
    
    // Update other nodes' connections
    connectionsToRemove.forEach(id => {
      const otherNode = nodes.find(n => n.id === id);
      if (otherNode) {
        otherNode.connections = otherNode.connections.filter(connId => connId !== node.id);
      }
    });
    
    // Discover new connections
    nodes.forEach(otherNode => {
      if (otherNode.id === node.id || !otherNode.isOnline || node.connections.includes(otherNode.id)) {
        return;
      }
      
      const distance = this.calculateDistance(node, otherNode);
      const maxDistance = (node.signalStrength + otherNode.signalStrength) / 2;
      
      if (distance <= maxDistance && Math.random() < 0.1) {
        // New connection discovered
        node.connections.push(otherNode.id);
        otherNode.connections.push(node.id);
      }
    });
  }

  private generateMessages(nodes: SimulationNode[], scenario: SimulationScenario): SimulationMessage[] {
    const messages: SimulationMessage[] = [];
    const onlineNodes = nodes.filter(node => node.isOnline);
    
    if (onlineNodes.length < 2) return messages;
    
    // Calculate how many messages to generate this tick
    const messagesPerTick = scenario.messageRate / 60;
    const messagesToGenerate = Math.random() < (messagesPerTick % 1) ? 
      Math.floor(messagesPerTick) + 1 : 
      Math.floor(messagesPerTick);
    
    for (let i = 0; i < messagesToGenerate; i++) {
      // Select random source and destination
      const sourceIndex = Math.floor(Math.random() * onlineNodes.length);
      let destIndex = Math.floor(Math.random() * onlineNodes.length);
      
      // Ensure source and destination are different
      while (destIndex === sourceIndex) {
        destIndex = Math.floor(Math.random() * onlineNodes.length);
      }
      
      const source = onlineNodes[sourceIndex];
      const destination = onlineNodes[destIndex];
      
      // Determine message priority
      let priority: 'low' | 'normal' | 'high' | 'emergency';
      const rand = Math.random();
      
      if (rand < scenario.emergencyProbability) {
        priority = 'emergency';
      } else if (rand < scenario.emergencyProbability + 0.1) {
        priority = 'high';
      } else if (rand < scenario.emergencyProbability + 0.3) {
        priority = 'normal';
      } else {
        priority = 'low';
      }
      
      // Create message
      const message: SimulationMessage = {
        id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        source: source.id,
        destination: destination.id,
        content: `Message from ${source.id} to ${destination.id}`,
        priority,
        size: 1000 + Math.floor(Math.random() * 9000), // 1-10KB
        createdAt: this._simulationTime.value,
        status: 'queued',
        route: [source.id],
        hopCount: 0,
        ttl: 10
      };
      
      // Add to source node's queue
      source.messageQueue.push(message);
      
      messages.push(message);
    }
    
    return messages;
  }

  private processMessages(messages: SimulationMessage[], nodes: SimulationNode[]): void {
    // Process each node's message queue
    nodes.forEach(node => {
      if (!node.isOnline || node.messageQueue.length === 0) return;
      
      // Process up to 3 messages per tick
      const messagesToProcess = Math.min(3, node.messageQueue.length);
      
      for (let i = 0; i < messagesToProcess; i++) {
        const message = node.messageQueue[i];
        
        // Skip already processed messages
        if (message.status !== 'queued') continue;
        
        // Update message status
        message.status = 'sending';
        
        // Find next hop
        const nextHop = this.findNextHop(message, node, nodes);
        
        if (nextHop) {
          // Forward message to next hop
          message.route.push(nextHop.id);
          message.hopCount++;
          message.ttl--;
          
          // Check if destination reached
          if (nextHop.id === message.destination) {
            message.status = 'delivered';
            message.deliveredAt = this._simulationTime.value;
          } else if (message.ttl <= 0) {
            // TTL expired
            message.status = 'failed';
          } else {
            // Add to next hop's queue
            nextHop.messageQueue.push(message);
          }
          
          // Remove from current node's queue
          node.messageQueue = node.messageQueue.filter(m => m.id !== message.id);
          
          // Battery drain for message processing
          node.batteryLevel -= 0.01 * (message.priority === 'emergency' ? 2 : 1);
        } else {
          // No route found
          message.status = 'failed';
          
          // Remove from queue
          node.messageQueue = node.messageQueue.filter(m => m.id !== message.id);
          
          // Add event
          this.addEvent({
            id: `event_message_loss_${message.id}_${Date.now()}`,
            type: 'message_loss',
            nodeId: node.id,
            timestamp: this._simulationTime.value,
            description: `Message ${message.id} lost due to no route from ${node.id} to ${message.destination}`,
            severity: message.priority === 'emergency' ? 'high' : 'low',
            resolved: true,
            resolvedAt: this._simulationTime.value
          });
        }
      }
    });
  }

  private findNextHop(message: SimulationMessage, currentNode: SimulationNode, nodes: SimulationNode[]): SimulationNode | null {
    // If directly connected to destination, send directly
    if (currentNode.connections.includes(message.destination)) {
      return nodes.find(n => n.id === message.destination) || null;
    }
    
    // Use different routing strategies based on message priority
    if (message.priority === 'emergency') {
      // For emergency messages, use flooding
      // Send to all connections that are not already in the route
      const possibleNextHops = currentNode.connections
        .filter(id => !message.route.includes(id))
        .map(id => nodes.find(n => n.id === id))
        .filter(n => n && n.isOnline) as SimulationNode[];
      
      if (possibleNextHops.length > 0) {
        // Choose the one with highest signal strength
        return possibleNextHops.sort((a, b) => b.signalStrength - a.signalStrength)[0];
      }
    } else {
      // For normal messages, use greedy routing
      // Find the connection closest to destination
      const destination = nodes.find(n => n.id === message.destination);
      if (!destination) return null;
      
      const possibleNextHops = currentNode.connections
        .filter(id => !message.route.includes(id))
        .map(id => nodes.find(n => n.id === id))
        .filter(n => n && n.isOnline) as SimulationNode[];
      
      if (possibleNextHops.length > 0) {
        // Sort by distance to destination
        return possibleNextHops.sort((a, b) => {
          const distA = this.calculateDistance(a, destination);
          const distB = this.calculateDistance(b, destination);
          return distA - distB;
        })[0];
      }
    }
    
    return null;
  }

  private generateEvents(nodes: SimulationNode[], scenario: SimulationScenario): SimulationEvent[] {
    const events: SimulationEvent[] = [];
    
    // Random node failures
    nodes.forEach(node => {
      if (!node.isOnline) return;
      
      // Skip coordinator for failures
      if (node.type === 'coordinator') return;
      
      // Random failure based on failure rate
      if (Math.random() < scenario.failureRate / 100) {
        node.isOnline = false;
        
        events.push({
          id: `event_failure_${node.id}_${Date.now()}`,
          type: 'node_failure',
          nodeId: node.id,
          timestamp: this._simulationTime.value,
          description: `Node ${node.id} failed unexpectedly`,
          severity: 'medium',
          resolved: false
        });
      }
    });
    
    // Random emergency activations
    if (Math.random() < scenario.emergencyProbability / 10) {
      const onlineNodes = nodes.filter(n => n.isOnline);
      
      if (onlineNodes.length > 0) {
        const randomNode = onlineNodes[Math.floor(Math.random() * onlineNodes.length)];
        randomNode.emergencyStatus = 'emergency';
        
        events.push({
          id: `event_emergency_${randomNode.id}_${Date.now()}`,
          type: 'emergency_activation',
          nodeId: randomNode.id,
          timestamp: this._simulationTime.value,
          description: `Emergency activated on node ${randomNode.id}`,
          severity: 'high',
          resolved: false
        });
      }
    }
    
    // Check for network partitions
    const partitions = this.detectNetworkPartitions(nodes);
    if (partitions.length > 1) {
      events.push({
        id: `event_partition_${Date.now()}`,
        type: 'network_partition',
        timestamp: this._simulationTime.value,
        description: `Network partitioned into ${partitions.length} disconnected segments`,
        severity: 'critical',
        resolved: false
      });
    }
    
    return events;
  }

  private processEvents(events: SimulationEvent[], nodes: SimulationNode[]): void {
    // Process unresolved events
    const unresolvedEvents = events.filter(e => !e.resolved);
    
    unresolvedEvents.forEach(event => {
      switch (event.type) {
        case 'node_failure':
          this.processNodeFailureEvent(event, nodes);
          break;
        case 'battery_depletion':
          this.processBatteryDepletionEvent(event, nodes);
          break;
        case 'emergency_activation':
          this.processEmergencyActivationEvent(event, nodes);
          break;
        case 'network_partition':
          this.processNetworkPartitionEvent(event, nodes);
          break;
      }
    });
  }

  private processNodeFailureEvent(event: SimulationEvent, nodes: SimulationNode[]): void {
    if (!event.nodeId) return;
    
    const node = nodes.find(n => n.id === event.nodeId);
    if (!node) return;
    
    // 10% chance of recovery per tick
    if (Math.random() < 0.1) {
      node.isOnline = true;
      event.resolved = true;
      event.resolvedAt = this._simulationTime.value;
      
      // Emit event
      this.simulationEvent$.next({
        ...event,
        description: `Node ${node.id} recovered from failure`,
        severity: 'low'
      });
    }
  }

  private processBatteryDepletionEvent(event: SimulationEvent, nodes: SimulationNode[]): void {
    if (!event.nodeId) return;
    
    const node = nodes.find(n => n.id === event.nodeId);
    if (!node) return;
    
    // 5% chance of battery recovery (e.g., solar charging)
    if (Math.random() < 0.05) {
      node.batteryLevel += 10;
      
      if (node.batteryLevel > 15) {
        node.isOnline = true;
        event.resolved = true;
        event.resolvedAt = this._simulationTime.value;
        
        // Emit event
        this.simulationEvent$.next({
          ...event,
          description: `Node ${node.id} battery recharged to ${node.batteryLevel.toFixed(1)}%`,
          severity: 'low'
        });
      }
    }
  }

  private processEmergencyActivationEvent(event: SimulationEvent, nodes: SimulationNode[]): void {
    if (!event.nodeId) return;
    
    const node = nodes.find(n => n.id === event.nodeId);
    if (!node) return;
    
    // Propagate emergency status to neighbors
    node.connections.forEach(connectionId => {
      const connectedNode = nodes.find(n => n.id === connectionId);
      if (connectedNode && connectedNode.isOnline && connectedNode.emergencyStatus === 'normal') {
        connectedNode.emergencyStatus = 'alert';
      }
    });
    
    // 2% chance of emergency resolution per tick
    if (Math.random() < 0.02) {
      node.emergencyStatus = 'normal';
      event.resolved = true;
      event.resolvedAt = this._simulationTime.value;
      
      // Emit event
      this.simulationEvent$.next({
        ...event,
        description: `Emergency resolved on node ${node.id}`,
        severity: 'medium'
      });
    }
  }

  private processNetworkPartitionEvent(event: SimulationEvent, nodes: SimulationNode[]): void {
    // Check if network is still partitioned
    const partitions = this.detectNetworkPartitions(nodes);
    
    if (partitions.length <= 1) {
      event.resolved = true;
      event.resolvedAt = this._simulationTime.value;
      
      // Emit event
      this.simulationEvent$.next({
        ...event,
        description: 'Network partition resolved',
        severity: 'medium'
      });
    }
  }

  private detectNetworkPartitions(nodes: SimulationNode[]): string[][] {
    const onlineNodes = nodes.filter(n => n.isOnline);
    const visited = new Set<string>();
    const partitions: string[][] = [];
    
    onlineNodes.forEach(node => {
      if (visited.has(node.id)) return;
      
      // Start a new partition
      const partition: string[] = [];
      const queue: string[] = [node.id];
      
      while (queue.length > 0) {
        const currentId = queue.shift()!;
        
        if (visited.has(currentId)) continue;
        visited.add(currentId);
        partition.push(currentId);
        
        // Add connected nodes to queue
        const currentNode = onlineNodes.find(n => n.id === currentId);
        if (currentNode) {
          currentNode.connections.forEach(connId => {
            if (!visited.has(connId) && onlineNodes.some(n => n.id === connId)) {
              queue.push(connId);
            }
          });
        }
      }
      
      partitions.push(partition);
    });
    
    return partitions;
  }

  private calculateSimulationMetrics(): SimulationMetrics {
    const nodes = this._simulationNodes.value;
    const messages = this._simulationMessages.value;
    const events = this._simulationEvents.value;
    const time = this._simulationTime.value;
    
    // Message delivery metrics
    const completedMessages = messages.filter(m => m.status === 'delivered' || m.status === 'failed');
    const deliveredMessages = messages.filter(m => m.status === 'delivered');
    
    const deliveryRate = completedMessages.length > 0 ? 
      (deliveredMessages.length / completedMessages.length) * 100 : 100;
    
    // Latency calculation
    const messagesWithLatency = deliveredMessages.filter(m => m.deliveredAt !== undefined);
    const totalLatency = messagesWithLatency.reduce((sum, m) => sum + ((m.deliveredAt || 0) - m.createdAt), 0);
    const averageLatency = messagesWithLatency.length > 0 ? totalLatency / messagesWithLatency.length : 0;
    
    // Network reliability
    const onlineNodes = nodes.filter(n => n.isOnline);
    const networkReliability = (onlineNodes.length / nodes.length) * 100;
    
    // Battery consumption
    const initialBattery = 80; // Assumed average initial battery
    const currentBattery = onlineNodes.reduce((sum, n) => sum + n.batteryLevel, 0) / onlineNodes.length;
    const batteryConsumption = time > 0 ? (initialBattery - currentBattery) / time * 60 : 0; // % per minute
    
    // Routing efficiency
    const avgHopCount = deliveredMessages.reduce((sum, m) => sum + m.hopCount, 0) / Math.max(1, deliveredMessages.length);
    const routingEfficiency = 100 - (avgHopCount * 5); // Lower hop count is better
    
    // Emergency response time
    const emergencyMessages = deliveredMessages.filter(m => m.priority === 'emergency' && m.deliveredAt !== undefined);
    const totalEmergencyLatency = emergencyMessages.reduce((sum, m) => sum + ((m.deliveredAt || 0) - m.createdAt), 0);
    const emergencyResponseTime = emergencyMessages.length > 0 ? totalEmergencyLatency / emergencyMessages.length : 0;
    
    // Network coverage
    const totalConnections = nodes.reduce((sum, n) => sum + n.connections.length, 0);
    const maxPossibleConnections = nodes.length * (nodes.length - 1);
    const networkCoverage = (totalConnections / maxPossibleConnections) * 100;
    
    // Node failure rate
    const nodeFailures = events.filter(e => e.type === 'node_failure').length;
    const nodeFailureRate = time > 0 ? (nodeFailures / nodes.length) * (60 / time) * 100 : 0; // % per minute
    
    return {
      messageDeliveryRate: Math.round(deliveryRate * 10) / 10,
      averageLatency: Math.round(averageLatency * 10) / 10,
      networkReliability: Math.round(networkReliability * 10) / 10,
      batteryConsumption: Math.round(batteryConsumption * 100) / 100,
      routingEfficiency: Math.max(0, Math.round(routingEfficiency * 10) / 10),
      emergencyResponseTime: Math.round(emergencyResponseTime * 10) / 10,
      networkCoverage: Math.round(networkCoverage * 10) / 10,
      nodeFailureRate: Math.round(nodeFailureRate * 10) / 10
    };
  }

  private calculateDistance(node1: SimulationNode, node2: SimulationNode): number {
    const dx = node1.x - node2.x;
    const dy = node1.y - node2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  private addEvent(event: SimulationEvent): void {
    const events = [...this._simulationEvents.value, event];
    this._simulationEvents.next(events);
    this.simulationEvent$.next(event);
  }

  private shuffleArray<T>(array: T[]): T[] {
    const result = [...array];
    for (let i = result.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [result[i], result[j]] = [result[j], result[i]];
    }
    return result;
  }

  ngOnDestroy(): void {
    this.stopSimulation();
    this.destroy$.next();
    this.destroy$.complete();
  }
}