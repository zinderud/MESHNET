import { Component, inject, OnInit, OnDestroy, computed, signal, ElementRef, ViewChild, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSliderModule } from '@angular/material/slider';
import { MatSelectModule } from '@angular/material/select';
import { MatFormFieldModule } from '@angular/material/form-field';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';

import { P2PNetworkService } from '../../core/services/p2p-network.service';
import { MeshNetworkImplementationService, MeshNetwork } from '../../core/services/mesh-network-implementation.service';
import { MeshRoutingService } from '../../core/services/mesh-routing.service';
import { AnalyticsService } from '../../core/services/analytics.service';
import { NetworkTopologyRendererService } from './network-topology-renderer.service';
import { NetworkGraphLayoutService } from './network-graph-layout.service';

@Component({
  selector: 'app-network-visualization',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatSliderModule,
    MatSelectModule,
    MatFormFieldModule,
    FormsModule
  ],
  template: `
    <div class="visualization-container">
      <h1>Mesh Network Visualization</h1>
      
      <!-- Visualization Controls -->
      <mat-card class="control-panel">
        <mat-card-header>
          <mat-card-title>Visualization Controls</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="control-row">
            <mat-form-field appearance="outline">
              <mat-label>Visualization Mode</mat-label>
              <mat-select [(ngModel)]="visualizationMode" (selectionChange)="updateVisualization()">
                <mat-option value="topology">Network Topology</mat-option>
                <mat-option value="heatmap">Signal Strength Heatmap</mat-option>
                <mat-option value="routing">Routing Paths</mat-option>
                <mat-option value="emergency">Emergency Coverage</mat-option>
              </mat-select>
            </mat-form-field>
            
            <mat-form-field appearance="outline">
              <mat-label>Network</mat-label>
              <mat-select [(ngModel)]="selectedNetworkId" (selectionChange)="updateVisualization()">
                <mat-option value="all">All Networks</mat-option>
                @for (network of meshNetworks(); track network.id) {
                  <mat-option [value]="network.id">{{ network.name }}</mat-option>
                }
              </mat-select>
            </mat-form-field>
          </div>
          
          <div class="control-row">
            <div class="zoom-controls">
              <span>Zoom:</span>
              <button mat-icon-button (click)="zoomOut()">
                <mat-icon>zoom_out</mat-icon>
              </button>
              <mat-slider min="0.5" max="2" step="0.1" [discrete]="true">
                <input matSliderThumb [(ngModel)]="zoomLevel" (change)="updateZoom()">
              </mat-slider>
              <button mat-icon-button (click)="zoomIn()">
                <mat-icon>zoom_in</mat-icon>
              </button>
            </div>
            
            <div class="view-controls">
              <button mat-button (click)="resetView()">
                <mat-icon>center_focus_strong</mat-icon>
                Reset View
              </button>
              <button mat-button (click)="toggleLabels()">
                <mat-icon>{{ showLabels ? 'label' : 'label_off' }}</mat-icon>
                {{ showLabels ? 'Hide Labels' : 'Show Labels' }}
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Network Visualization Canvas -->
      <mat-card class="visualization-card">
        <mat-card-content>
          <div class="canvas-container">
            <canvas #networkCanvas></canvas>
            
            @if (isLoading) {
              <div class="loading-overlay">
                <mat-icon>sync</mat-icon>
                <p>Loading network data...</p>
              </div>
            }
            
            @if (!hasNetworkData()) {
              <div class="no-data-overlay">
                <mat-icon>hub_off</mat-icon>
                <h3>No Network Data Available</h3>
                <p>Create a mesh network to visualize it</p>
              </div>
            }
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Network Legend -->
      <mat-card class="legend-card">
        <mat-card-header>
          <mat-card-title>Network Legend</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="legend-items">
            <div class="legend-item">
              <div class="legend-color coordinator"></div>
              <span>Coordinator Node</span>
            </div>
            <div class="legend-item">
              <div class="legend-color relay"></div>
              <span>Relay Node</span>
            </div>
            <div class="legend-item">
              <div class="legend-color endpoint"></div>
              <span>Endpoint Node</span>
            </div>
            <div class="legend-item">
              <div class="legend-color bridge"></div>
              <span>Bridge Node</span>
            </div>
            <div class="legend-item">
              <div class="legend-line active"></div>
              <span>Active Connection</span>
            </div>
            <div class="legend-item">
              <div class="legend-line weak"></div>
              <span>Weak Connection</span>
            </div>
            <div class="legend-item">
              <div class="legend-line emergency"></div>
              <span>Emergency Route</span>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Network Statistics -->
      <mat-card class="stats-card">
        <mat-card-header>
          <mat-card-title>Network Statistics</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="stats-grid">
            <div class="stat-item">
              <div class="stat-label">Nodes</div>
              <div class="stat-value">{{ nodeCount }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Connections</div>
              <div class="stat-value">{{ connectionCount }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Avg. Path Length</div>
              <div class="stat-value">{{ averagePathLength.toFixed(1) }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Network Diameter</div>
              <div class="stat-value">{{ networkDiameter }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Clustering</div>
              <div class="stat-value">{{ clusteringCoefficient.toFixed(2) }}</div>
            </div>
            <div class="stat-item">
              <div class="stat-label">Coverage</div>
              <div class="stat-value">{{ coverageRadius }}m</div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .visualization-container {
      max-width: 1400px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
    }

    .control-panel {
      margin-bottom: 24px;
    }

    .control-row {
      display: flex;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 16px;
    }

    .control-row:last-child {
      margin-bottom: 0;
    }

    mat-form-field {
      flex: 1;
    }

    .zoom-controls {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .zoom-controls span {
      min-width: 50px;
    }

    .zoom-controls mat-slider {
      min-width: 150px;
    }

    .view-controls {
      display: flex;
      gap: 8px;
    }

    .visualization-card {
      margin-bottom: 24px;
      padding: 0;
    }

    .canvas-container {
      position: relative;
      width: 100%;
      height: 500px;
      background-color: #f8f9fa;
      border-radius: 4px;
      overflow: hidden;
    }

    canvas {
      width: 100%;
      height: 100%;
    }

    .loading-overlay,
    .no-data-overlay {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      background-color: rgba(255, 255, 255, 0.8);
    }

    .loading-overlay mat-icon,
    .no-data-overlay mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      color: #666;
    }

    .loading-overlay mat-icon {
      animation: spin 2s infinite linear;
    }

    @keyframes spin {
      from { transform: rotate(0deg); }
      to { transform: rotate(360deg); }
    }

    .no-data-overlay h3 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .no-data-overlay p {
      margin: 0;
      color: #666;
    }

    .legend-card {
      margin-bottom: 24px;
    }

    .legend-items {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
    }

    .legend-item {
      display: flex;
      align-items: center;
      gap: 8px;
      min-width: 150px;
    }

    .legend-color {
      width: 16px;
      height: 16px;
      border-radius: 50%;
    }

    .legend-color.coordinator {
      background-color: #f44336;
    }

    .legend-color.relay {
      background-color: #ff9800;
    }

    .legend-color.endpoint {
      background-color: #4caf50;
    }

    .legend-color.bridge {
      background-color: #2196f3;
    }

    .legend-line {
      width: 24px;
      height: 2px;
    }

    .legend-line.active {
      background-color: #2196f3;
      height: 3px;
    }

    .legend-line.weak {
      background-color: #9e9e9e;
      border-top: 1px dashed #9e9e9e;
      height: 0;
    }

    .legend-line.emergency {
      background-color: #f44336;
      height: 3px;
    }

    .stats-card {
      margin-bottom: 24px;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 16px;
    }

    .stat-item {
      text-align: center;
      padding: 12px;
      background-color: #f5f5f5;
      border-radius: 8px;
    }

    .stat-label {
      font-size: 14px;
      color: #666;
      margin-bottom: 4px;
    }

    .stat-value {
      font-size: 20px;
      font-weight: bold;
      color: #333;
    }

    @media (max-width: 768px) {
      .visualization-container {
        padding: 8px;
      }
      
      .control-row {
        flex-direction: column;
      }
      
      .canvas-container {
        height: 300px;
      }
      
      .legend-items {
        justify-content: center;
      }
    }
  `]
})
export class NetworkVisualizationComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild('networkCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  
  private p2pService = inject(P2PNetworkService);
  private meshService = inject(MeshNetworkImplementationService);
  private routingService = inject(MeshRoutingService);
  private analyticsService = inject(AnalyticsService);
  private rendererService = inject(NetworkTopologyRendererService);
  private layoutService = inject(NetworkGraphLayoutService);

  // Canvas and rendering properties
  private canvas!: HTMLCanvasElement;
  private ctx!: CanvasRenderingContext2D;
  private canvasWidth = 0;
  private canvasHeight = 0;
  private panOffset = { x: 0, y: 0 };
  private isDragging = false;
  private lastMousePos = { x: 0, y: 0 };
  private nodeRadius = 15;
  private animationFrame: number | null = null;

  // Visualization state
  visualizationMode = 'topology';
  selectedNetworkId = 'all';
  zoomLevel = 1;
  showLabels = true;
  isLoading = false;

  // Network statistics
  nodeCount = 0;
  connectionCount = 0;
  averagePathLength = 0;
  networkDiameter = 0;
  clusteringCoefficient = 0;
  coverageRadius = 0;

  // Reactive state from services
  meshNetworks = computed(() => Array.from(this.meshService.activeMeshNetworks().values()));
  
  // Computed properties
  hasNetworkData = computed(() => this.meshNetworks().length > 0);

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.setupEventListeners();
    this.analyticsService.trackPageView('network_visualization');
  }

  ngAfterViewInit(): void {
    this.initializeCanvas();
    this.updateVisualization();
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
    if (this.animationFrame !== null) {
      cancelAnimationFrame(this.animationFrame);
    }
  }

  private initializeCanvas(): void {
    this.canvas = this.canvasRef.nativeElement;
    const ctx = this.canvas.getContext('2d');
    
    if (!ctx) {
      console.error('Failed to get canvas context');
      return;
    }
    
    this.ctx = ctx;
    
    // Set canvas size
    this.resizeCanvas();
    
    // Add event listeners
    this.canvas.addEventListener('mousedown', this.handleMouseDown.bind(this));
    this.canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
    this.canvas.addEventListener('mouseup', this.handleMouseUp.bind(this));
    this.canvas.addEventListener('wheel', this.handleWheel.bind(this));
    
    window.addEventListener('resize', this.resizeCanvas.bind(this));
    
    // Initialize renderer service
    this.rendererService.initialize(this.canvasRef, this.canvasWidth, this.canvasHeight);
  }

  private resizeCanvas(): void {
    const container = this.canvas.parentElement;
    if (!container) return;
    
    this.canvasWidth = container.clientWidth;
    this.canvasHeight = container.clientHeight;
    
    this.canvas.width = this.canvasWidth;
    this.canvas.height = this.canvasHeight;
    
    // Update renderer
    this.rendererService.resize(this.canvasWidth, this.canvasHeight);
    
    this.updateVisualization();
  }

  private setupEventListeners(): void {
    // Listen for mesh network changes
    this.subscriptions.add(
      this.meshService.onMeshNetworkFormed$.subscribe(() => {
        this.updateVisualization();
      })
    );
    
    this.subscriptions.add(
      this.meshService.onMeshNodeJoined$.subscribe(() => {
        this.updateVisualization();
      })
    );
    
    this.subscriptions.add(
      this.meshService.onMeshNodeLeft$.subscribe(() => {
        this.updateVisualization();
      })
    );
    
    // Listen for routing changes
    this.subscriptions.add(
      this.routingService.onRoutingTableUpdated$.subscribe(() => {
        if (this.visualizationMode === 'routing') {
          this.updateVisualization();
        }
      })
    );
  }

  // Canvas interaction handlers
  private handleMouseDown(event: MouseEvent): void {
    this.isDragging = true;
    this.lastMousePos = {
      x: event.offsetX,
      y: event.offsetY
    };
  }

  private handleMouseMove(event: MouseEvent): void {
    if (!this.isDragging) return;
    
    const deltaX = event.offsetX - this.lastMousePos.x;
    const deltaY = event.offsetY - this.lastMousePos.y;
    
    this.panOffset.x += deltaX;
    this.panOffset.y += deltaY;
    
    this.lastMousePos = {
      x: event.offsetX,
      y: event.offsetY
    };
    
    this.updateVisualization();
  }

  private handleMouseUp(): void {
    this.isDragging = false;
  }

  private handleWheel(event: WheelEvent): void {
    event.preventDefault();
    
    const delta = -Math.sign(event.deltaY) * 0.1;
    const newZoom = Math.max(0.5, Math.min(2, this.zoomLevel + delta));
    
    // Zoom around mouse position
    const mouseX = event.offsetX;
    const mouseY = event.offsetY;
    
    const centerX = this.canvasWidth / 2 + this.panOffset.x;
    const centerY = this.canvasHeight / 2 + this.panOffset.y;
    
    const mouseOffsetX = mouseX - centerX;
    const mouseOffsetY = mouseY - centerY;
    
    const scaleFactor = newZoom / this.zoomLevel;
    
    this.panOffset.x -= mouseOffsetX * (scaleFactor - 1);
    this.panOffset.y -= mouseOffsetY * (scaleFactor - 1);
    
    this.zoomLevel = newZoom;
    
    this.updateVisualization();
  }

  // Public control methods
  updateVisualization(): void {
    if (!this.ctx) return;
    
    this.isLoading = true;
    
    // Clear canvas
    this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    
    // Get network data
    const networks = this.getNetworksToVisualize();
    
    if (networks.length === 0) {
      this.isLoading = false;
      return;
    }
    
    // Calculate network statistics
    this.calculateNetworkStatistics(networks);
    
    // Draw based on visualization mode
    switch (this.visualizationMode) {
      case 'topology':
        this.drawNetworkTopology(networks);
        break;
      case 'heatmap':
        this.drawSignalHeatmap(networks);
        break;
      case 'routing':
        this.drawRoutingPaths(networks);
        break;
      case 'emergency':
        this.drawEmergencyCoverage(networks);
        break;
    }
    
    this.isLoading = false;
  }

  zoomIn(): void {
    this.zoomLevel = Math.min(2, this.zoomLevel + 0.1);
    this.updateVisualization();
  }

  zoomOut(): void {
    this.zoomLevel = Math.max(0.5, this.zoomLevel - 0.1);
    this.updateVisualization();
  }

  updateZoom(): void {
    this.updateVisualization();
  }

  resetView(): void {
    this.panOffset = { x: 0, y: 0 };
    this.zoomLevel = 1;
    this.updateVisualization();
  }

  toggleLabels(): void {
    this.showLabels = !this.showLabels;
    this.updateVisualization();
  }

  // Private visualization methods
  private getNetworksToVisualize(): MeshNetwork[] {
    const allNetworks = this.meshNetworks();
    
    if (this.selectedNetworkId === 'all') {
      return allNetworks;
    }
    
    const selectedNetwork = allNetworks.find(n => n.id === this.selectedNetworkId);
    return selectedNetwork ? [selectedNetwork] : [];
  }

  private calculateNetworkStatistics(networks: MeshNetwork[]): void {
    // Calculate combined statistics for all networks
    let totalNodes = 0;
    let totalConnections = 0;
    let maxDiameter = 0;
    let totalPathLength = 0;
    let pathCount = 0;
    let maxRadius = 0;
    
    for (const network of networks) {
      totalNodes += network.nodes.size;
      
      // Estimate connections based on topology
      switch (network.topology) {
        case 'star':
          totalConnections += network.nodes.size - 1;
          break;
        case 'mesh':
          totalConnections += (network.nodes.size * (network.nodes.size - 1)) / 2;
          break;
        case 'tree':
          totalConnections += network.nodes.size - 1;
          break;
        case 'hybrid':
        default:
          totalConnections += network.nodes.size * 1.5;
          break;
      }
      
      // Use routing metrics if available
      const routingMetrics = this.routingService.routingMetrics();
      if (routingMetrics) {
        maxDiameter = Math.max(maxDiameter, routingMetrics.networkDiameter);
        totalPathLength += routingMetrics.averagePathLength * network.nodes.size;
        pathCount += network.nodes.size;
      } else {
        // Estimate based on topology
        switch (network.topology) {
          case 'star':
            maxDiameter = Math.max(maxDiameter, 2);
            totalPathLength += 1.5 * network.nodes.size;
            break;
          case 'mesh':
            maxDiameter = Math.max(maxDiameter, 1);
            totalPathLength += 1 * network.nodes.size;
            break;
          case 'tree':
            maxDiameter = Math.max(maxDiameter, Math.log2(network.nodes.size) * 2);
            totalPathLength += Math.log2(network.nodes.size) * network.nodes.size;
            break;
          case 'hybrid':
          default:
            maxDiameter = Math.max(maxDiameter, Math.sqrt(network.nodes.size));
            totalPathLength += Math.sqrt(network.nodes.size) * network.nodes.size;
            break;
        }
        pathCount += network.nodes.size;
      }
      
      maxRadius = Math.max(maxRadius, network.coverage.radius);
    }
    
    this.nodeCount = totalNodes;
    this.connectionCount = Math.round(totalConnections);
    this.networkDiameter = Math.round(maxDiameter);
    this.averagePathLength = pathCount > 0 ? totalPathLength / pathCount : 0;
    this.clusteringCoefficient = this.estimateClusteringCoefficient(networks);
    this.coverageRadius = maxRadius;
  }

  private estimateClusteringCoefficient(networks: MeshNetwork[]): number {
    // Simplified estimation based on topology
    let coefficient = 0;
    
    for (const network of networks) {
      switch (network.topology) {
        case 'star':
          coefficient += 0;
          break;
        case 'mesh':
          coefficient += 1;
          break;
        case 'tree':
          coefficient += 0.1;
          break;
        case 'hybrid':
        default:
          coefficient += 0.5;
          break;
      }
    }
    
    return networks.length > 0 ? coefficient / networks.length : 0;
  }

  private drawNetworkTopology(networks: MeshNetwork[]): void {
    // Convert mesh networks to graph nodes and links
    const { nodes, links } = this.convertNetworksToGraph(networks);
    
    // Apply layout algorithm
    const layoutedNodes = this.layoutService.applyMeshLayout(nodes, links, {
      width: this.canvasWidth,
      height: this.canvasHeight,
      coordinatorAtCenter: true
    });
    
    // Convert to renderer format
    const renderNodes = layoutedNodes.map(node => ({
      id: node.id,
      x: node.x || 0,
      y: node.y || 0,
      type: node.type as any,
      signalStrength: 85, // Default value
      batteryLevel: 75, // Default value
      isOnline: true,
      emergencyStatus: 'normal' as any,
      label: node.id
    }));
    
    const renderConnections = links.map(link => ({
      source: link.source,
      target: link.target,
      strength: 80, // Default value
      isEmergency: false
    }));
    
    // Render the network
    this.rendererService.renderTopology(
      renderNodes,
      renderConnections,
      {
        showLabels: this.showLabels,
        showSignalStrength: true,
        showBatteryLevel: true,
        showEmergencyStatus: true,
        nodeSize: this.nodeRadius * this.zoomLevel,
        lineWidth: 2 * this.zoomLevel,
        theme: 'light',
        animateConnections: true
      }
    );
  }

  private drawSignalHeatmap(networks: MeshNetwork[]): void {
    // Convert mesh networks to graph nodes
    const { nodes } = this.convertNetworksToGraph(networks);
    
    // Apply layout algorithm
    const layoutedNodes = this.layoutService.applyMeshLayout(nodes, [], {
      width: this.canvasWidth,
      height: this.canvasHeight,
      coordinatorAtCenter: true
    });
    
    // Convert to renderer format
    const renderNodes = layoutedNodes.map(node => ({
      id: node.id,
      x: node.x || 0,
      y: node.y || 0,
      type: node.type as any,
      signalStrength: 85, // Default value
      batteryLevel: 75, // Default value
      isOnline: true,
      emergencyStatus: 'normal' as any,
      label: node.id
    }));
    
    // Render the heatmap
    this.rendererService.renderHeatmap(
      renderNodes,
      {
        showLabels: this.showLabels,
        showSignalStrength: true,
        showBatteryLevel: true,
        showEmergencyStatus: true,
        nodeSize: this.nodeRadius * this.zoomLevel,
        lineWidth: 2 * this.zoomLevel,
        theme: 'light',
        animateConnections: false
      }
    );
  }

  private drawRoutingPaths(networks: MeshNetwork[]): void {
    // Convert mesh networks to graph nodes and links
    const { nodes, links } = this.convertNetworksToGraph(networks);
    
    // Apply layout algorithm
    const layoutedNodes = this.layoutService.applyMeshLayout(nodes, links, {
      width: this.canvasWidth,
      height: this.canvasHeight,
      coordinatorAtCenter: true
    });
    
    // Convert to renderer format
    const renderNodes = layoutedNodes.map(node => ({
      id: node.id,
      x: node.x || 0,
      y: node.y || 0,
      type: node.type as any,
      signalStrength: 85, // Default value
      batteryLevel: 75, // Default value
      isOnline: true,
      emergencyStatus: 'normal' as any,
      label: node.id
    }));
    
    const renderConnections = links.map(link => ({
      source: link.source,
      target: link.target,
      strength: 80, // Default value
      isEmergency: false
    }));
    
    // Generate some sample routes
    const routes = this.generateSampleRoutes(nodes);
    
    // Render the routing paths
    this.rendererService.renderRoutingPaths(
      renderNodes,
      renderConnections,
      routes,
      {
        showLabels: this.showLabels,
        showSignalStrength: true,
        showBatteryLevel: true,
        showEmergencyStatus: true,
        nodeSize: this.nodeRadius * this.zoomLevel,
        lineWidth: 2 * this.zoomLevel,
        theme: 'light',
        animateConnections: true
      }
    );
  }

  private drawEmergencyCoverage(networks: MeshNetwork[]): void {
    // Convert mesh networks to graph nodes and links
    const { nodes, links } = this.convertNetworksToGraph(networks);
    
    // Apply layout algorithm
    const layoutedNodes = this.layoutService.applyMeshLayout(nodes, links, {
      width: this.canvasWidth,
      height: this.canvasHeight,
      coordinatorAtCenter: true
    });
    
    // Convert to renderer format
    const renderNodes = layoutedNodes.map(node => ({
      id: node.id,
      x: node.x || 0,
      y: node.y || 0,
      type: node.type as any,
      signalStrength: 85, // Default value
      batteryLevel: 75, // Default value
      isOnline: true,
      emergencyStatus: node.type === 'coordinator' ? 'emergency' as any : 'normal' as any,
      label: node.id
    }));
    
    const renderConnections = links.map(link => ({
      source: link.source,
      target: link.target,
      strength: 80, // Default value
      isEmergency: false
    }));
    
    // Generate coverage areas
    const coverageAreas = this.generateCoverageAreas(networks);
    
    // Render the emergency coverage
    this.rendererService.renderEmergencyCoverage(
      renderNodes,
      renderConnections,
      coverageAreas,
      {
        showLabels: this.showLabels,
        showSignalStrength: true,
        showBatteryLevel: true,
        showEmergencyStatus: true,
        nodeSize: this.nodeRadius * this.zoomLevel,
        lineWidth: 2 * this.zoomLevel,
        theme: 'light',
        animateConnections: true
      }
    );
  }

  private convertNetworksToGraph(networks: MeshNetwork[]): { 
    nodes: Array<{ id: string; type: string }>;
    links: Array<{ source: string; target: string }>;
  } {
    const nodes: Array<{ id: string; type: string }> = [];
    const links: Array<{ source: string; target: string }> = [];
    const nodeIds = new Set<string>();
    
    // Process each network
    networks.forEach(network => {
      // Add nodes
      Array.from(network.nodes.entries()).forEach(([id, node]) => {
        if (!nodeIds.has(id)) {
          nodes.push({
            id,
            type: node.type
          });
          nodeIds.add(id);
        }
      });
      
      // Add links based on topology
      switch (network.topology) {
        case 'star':
          this.addStarTopologyLinks(network, links);
          break;
        case 'mesh':
          this.addMeshTopologyLinks(network, links);
          break;
        case 'tree':
          this.addTreeTopologyLinks(network, links);
          break;
        case 'hybrid':
        default:
          this.addHybridTopologyLinks(network, links);
          break;
      }
    });
    
    return { nodes, links };
  }

  private addStarTopologyLinks(network: MeshNetwork, links: Array<{ source: string; target: string }>): void {
    // Find coordinator node
    const coordinatorNode = Array.from(network.nodes.values()).find(node => node.type === 'coordinator');
    if (!coordinatorNode) return;
    
    // Connect all nodes to coordinator
    Array.from(network.nodes.entries()).forEach(([id, node]) => {
      if (id !== coordinatorNode.id) {
        links.push({
          source: coordinatorNode.id,
          target: id
        });
      }
    });
  }

  private addMeshTopologyLinks(network: MeshNetwork, links: Array<{ source: string; target: string }>): void {
    // Connect all nodes to each other
    const nodeIds = Array.from(network.nodes.keys());
    
    for (let i = 0; i < nodeIds.length; i++) {
      for (let j = i + 1; j < nodeIds.length; j++) {
        links.push({
          source: nodeIds[i],
          target: nodeIds[j]
        });
      }
    }
  }

  private addTreeTopologyLinks(network: MeshNetwork, links: Array<{ source: string; target: string }>): void {
    // Find coordinator node
    const coordinatorNode = Array.from(network.nodes.values()).find(node => node.type === 'coordinator');
    if (!coordinatorNode) return;
    
    // Find relay nodes
    const relayNodes = Array.from(network.nodes.values()).filter(node => node.type === 'relay');
    
    // Connect coordinator to relays
    relayNodes.forEach(relay => {
      links.push({
        source: coordinatorNode.id,
        target: relay.id
      });
    });
    
    // Connect relays to endpoints
    const endpoints = Array.from(network.nodes.values()).filter(node => 
      node.type !== 'coordinator' && node.type !== 'relay'
    );
    
    endpoints.forEach((endpoint, index) => {
      const relayIndex = index % relayNodes.length;
      links.push({
        source: relayNodes[relayIndex].id,
        target: endpoint.id
      });
    });
  }

  private addHybridTopologyLinks(network: MeshNetwork, links: Array<{ source: string; target: string }>): void {
    // Find coordinator and relay nodes
    const coordinatorNode = Array.from(network.nodes.values()).find(node => node.type === 'coordinator');
    const relayNodes = Array.from(network.nodes.values()).filter(node => node.type === 'relay');
    const bridgeNodes = Array.from(network.nodes.values()).filter(node => node.type === 'bridge');
    const endpointNodes = Array.from(network.nodes.values()).filter(node => node.type === 'endpoint');
    
    // Connect coordinator to relays
    if (coordinatorNode) {
      relayNodes.forEach(relay => {
        links.push({
          source: coordinatorNode.id,
          target: relay.id
        });
      });
      
      // Connect coordinator to bridges
      bridgeNodes.forEach(bridge => {
        links.push({
          source: coordinatorNode.id,
          target: bridge.id
        });
      });
    }
    
    // Connect some relays to each other
    for (let i = 0; i < relayNodes.length; i++) {
      for (let j = i + 1; j < relayNodes.length; j++) {
        if (Math.random() > 0.7) continue; // 30% chance to connect
        
        links.push({
          source: relayNodes[i].id,
          target: relayNodes[j].id
        });
      }
    }
    
    // Connect relays to endpoints
    endpointNodes.forEach(endpoint => {
      const relayIndex = Math.floor(Math.random() * relayNodes.length);
      links.push({
        source: relayNodes[relayIndex].id,
        target: endpoint.id
      });
    });
    
    // Connect bridges to some endpoints
    bridgeNodes.forEach(bridge => {
      const endpointsToConnect = Math.min(2, endpointNodes.length);
      for (let i = 0; i < endpointsToConnect; i++) {
        const endpointIndex = Math.floor(Math.random() * endpointNodes.length);
        links.push({
          source: bridge.id,
          target: endpointNodes[endpointIndex].id
        });
      }
    });
  }

  private generateSampleRoutes(nodes: Array<{ id: string; type: string }>): Array<{ 
    source: string; 
    target: string; 
    hops: number; 
    isEmergency: boolean 
  }> {
    const routes: Array<{ source: string; target: string; hops: number; isEmergency: boolean }> = [];
    
    // Find coordinator node
    const coordinator = nodes.find(node => node.type === 'coordinator');
    if (!coordinator) return routes;
    
    // Generate routes from coordinator to some random nodes
    const targetNodes = nodes.filter(node => node.type !== 'coordinator');
    const routeCount = Math.min(5, targetNodes.length);
    
    for (let i = 0; i < routeCount; i++) {
      const targetIndex = Math.floor(Math.random() * targetNodes.length);
      const target = targetNodes[targetIndex];
      
      routes.push({
        source: coordinator.id,
        target: target.id,
        hops: Math.floor(Math.random() * 3) + 1,
        isEmergency: Math.random() > 0.7 // 30% chance of emergency route
      });
    }
    
    return routes;
  }

  private generateCoverageAreas(networks: MeshNetwork[]): Array<{ 
    center: { x: number; y: number }; 
    radius: number; 
    type: string 
  }> {
    const coverageAreas: Array<{ center: { x: number; y: number }; radius: number; type: string }> = [];
    
    // Generate coverage area for each network
    networks.forEach(network => {
      coverageAreas.push({
        center: { x: this.canvasWidth / 2, y: this.canvasHeight / 2 },
        radius: Math.min(this.canvasWidth, this.canvasHeight) * 0.4,
        type: network.type === 'emergency' ? 'emergency' : 'normal'
      });
    });
    
    return coverageAreas;
  }
}