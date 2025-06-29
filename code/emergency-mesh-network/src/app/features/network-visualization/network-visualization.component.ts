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
  }

  private resizeCanvas(): void {
    const container = this.canvas.parentElement;
    if (!container) return;
    
    this.canvasWidth = container.clientWidth;
    this.canvasHeight = container.clientHeight;
    
    this.canvas.width = this.canvasWidth;
    this.canvas.height = this.canvasHeight;
    
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
    // Calculate node positions
    const nodes = this.calculateNodePositions(networks);
    
    // Draw connections
    this.drawConnections(nodes, networks);
    
    // Draw nodes
    this.drawNodes(nodes);
    
    // Draw labels if enabled
    if (this.showLabels) {
      this.drawLabels(nodes);
    }
  }

  private drawSignalHeatmap(networks: MeshNetwork[]): void {
    // Calculate node positions
    const nodes = this.calculateNodePositions(networks);
    
    // Draw heatmap
    this.drawHeatmap(nodes);
    
    // Draw nodes
    this.drawNodes(nodes);
    
    // Draw labels if enabled
    if (this.showLabels) {
      this.drawLabels(nodes);
    }
  }

  private drawRoutingPaths(networks: MeshNetwork[]): void {
    // Calculate node positions
    const nodes = this.calculateNodePositions(networks);
    
    // Draw routing paths
    this.drawRoutes(nodes);
    
    // Draw nodes
    this.drawNodes(nodes);
    
    // Draw labels if enabled
    if (this.showLabels) {
      this.drawLabels(nodes);
    }
  }

  private drawEmergencyCoverage(networks: MeshNetwork[]): void {
    // Calculate node positions
    const nodes = this.calculateNodePositions(networks);
    
    // Draw coverage areas
    this.drawCoverageAreas(networks);
    
    // Draw emergency connections
    this.drawEmergencyConnections(nodes);
    
    // Draw nodes
    this.drawNodes(nodes);
    
    // Draw labels if enabled
    if (this.showLabels) {
      this.drawLabels(nodes);
    }
  }

  private calculateNodePositions(networks: MeshNetwork[]): Map<string, { 
    x: number; 
    y: number; 
    node: any; 
    network: MeshNetwork 
  }> {
    const nodes = new Map();
    const centerX = this.canvasWidth / 2 + this.panOffset.x;
    const centerY = this.canvasHeight / 2 + this.panOffset.y;
    
    if (networks.length === 1) {
      // Single network - arrange in a circle
      const network = networks[0];
      const nodeArray = Array.from(network.nodes.values());
      const radius = Math.min(this.canvasWidth, this.canvasHeight) * 0.4 * this.zoomLevel;
      
      nodeArray.forEach((node, index) => {
        const angle = (index / nodeArray.length) * Math.PI * 2;
        const x = centerX + Math.cos(angle) * radius;
        const y = centerY + Math.sin(angle) * radius;
        
        nodes.set(node.id, { x, y, node, network });
      });
    } else {
      // Multiple networks - arrange networks in a grid
      const gridSize = Math.ceil(Math.sqrt(networks.length));
      const cellWidth = this.canvasWidth / gridSize;
      const cellHeight = this.canvasHeight / gridSize;
      
      networks.forEach((network, networkIndex) => {
        const gridX = networkIndex % gridSize;
        const gridY = Math.floor(networkIndex / gridSize);
        
        const networkCenterX = cellWidth * (gridX + 0.5) + this.panOffset.x;
        const networkCenterY = cellHeight * (gridY + 0.5) + this.panOffset.y;
        
        const nodeArray = Array.from(network.nodes.values());
        const networkRadius = Math.min(cellWidth, cellHeight) * 0.4 * this.zoomLevel;
        
        nodeArray.forEach((node, index) => {
          const angle = (index / nodeArray.length) * Math.PI * 2;
          const x = networkCenterX + Math.cos(angle) * networkRadius;
          const y = networkCenterY + Math.sin(angle) * networkRadius;
          
          nodes.set(node.id, { x, y, node, network });
        });
      });
    }
    
    return nodes;
  }

  private drawNodes(nodes: Map<string, any>): void {
    nodes.forEach(({ x, y, node }) => {
      // Draw node circle
      this.ctx.beginPath();
      this.ctx.arc(x, y, this.nodeRadius, 0, Math.PI * 2);
      
      // Set color based on node type
      switch (node.type) {
        case 'coordinator':
          this.ctx.fillStyle = '#f44336';
          break;
        case 'relay':
          this.ctx.fillStyle = '#ff9800';
          break;
        case 'bridge':
          this.ctx.fillStyle = '#2196f3';
          break;
        case 'endpoint':
        default:
          this.ctx.fillStyle = '#4caf50';
          break;
      }
      
      this.ctx.fill();
      
      // Draw border
      this.ctx.strokeStyle = '#fff';
      this.ctx.lineWidth = 2;
      this.ctx.stroke();
      
      // Draw status indicator
      if (node.isOnline) {
        this.ctx.beginPath();
        this.ctx.arc(x + this.nodeRadius * 0.7, y - this.nodeRadius * 0.7, this.nodeRadius * 0.3, 0, Math.PI * 2);
        this.ctx.fillStyle = '#4caf50';
        this.ctx.fill();
      }
      
      // Draw emergency indicator
      if (node.emergencyStatus !== 'normal') {
        this.ctx.beginPath();
        this.ctx.arc(x - this.nodeRadius * 0.7, y - this.nodeRadius * 0.7, this.nodeRadius * 0.3, 0, Math.PI * 2);
        this.ctx.fillStyle = '#f44336';
        this.ctx.fill();
      }
    });
  }

  private drawConnections(nodes: Map<string, any>, networks: MeshNetwork[]): void {
    // Draw connections based on network topology
    networks.forEach(network => {
      const networkNodes = Array.from(network.nodes.values());
      
      switch (network.topology) {
        case 'star':
          this.drawStarTopology(nodes, networkNodes);
          break;
        case 'mesh':
          this.drawMeshTopology(nodes, networkNodes);
          break;
        case 'tree':
          this.drawTreeTopology(nodes, networkNodes);
          break;
        case 'hybrid':
        default:
          this.drawHybridTopology(nodes, networkNodes);
          break;
      }
    });
  }

  private drawStarTopology(nodes: Map<string, any>, networkNodes: any[]): void {
    // Find coordinator node
    const coordinator = networkNodes.find(node => node.type === 'coordinator');
    if (!coordinator) return;
    
    const coordinatorPos = nodes.get(coordinator.id);
    if (!coordinatorPos) return;
    
    // Draw connections from coordinator to all other nodes
    networkNodes.forEach(node => {
      if (node.id === coordinator.id) return;
      
      const nodePos = nodes.get(node.id);
      if (!nodePos) return;
      
      this.drawConnection(
        coordinatorPos.x, coordinatorPos.y,
        nodePos.x, nodePos.y,
        node.signalStrength,
        false
      );
    });
  }

  private drawMeshTopology(nodes: Map<string, any>, networkNodes: any[]): void {
    // Draw connections between all nodes
    for (let i = 0; i < networkNodes.length; i++) {
      const node1 = networkNodes[i];
      const pos1 = nodes.get(node1.id);
      if (!pos1) continue;
      
      for (let j = i + 1; j < networkNodes.length; j++) {
        const node2 = networkNodes[j];
        const pos2 = nodes.get(node2.id);
        if (!pos2) continue;
        
        // Calculate average signal strength
        const signalStrength = (node1.signalStrength + node2.signalStrength) / 2;
        
        this.drawConnection(
          pos1.x, pos1.y,
          pos2.x, pos2.y,
          signalStrength,
          false
        );
      }
    }
  }

  private drawTreeTopology(nodes: Map<string, any>, networkNodes: any[]): void {
    // Find coordinator node
    const coordinator = networkNodes.find(node => node.type === 'coordinator');
    if (!coordinator) return;
    
    // Find relay nodes
    const relays = networkNodes.filter(node => node.type === 'relay');
    
    // Find endpoints
    const endpoints = networkNodes.filter(node => 
      node.type !== 'coordinator' && node.type !== 'relay'
    );
    
    // Draw connections from coordinator to relays
    const coordinatorPos = nodes.get(coordinator.id);
    if (coordinatorPos) {
      relays.forEach(relay => {
        const relayPos = nodes.get(relay.id);
        if (!relayPos) return;
        
        this.drawConnection(
          coordinatorPos.x, coordinatorPos.y,
          relayPos.x, relayPos.y,
          relay.signalStrength,
          false
        );
      });
    }
    
    // Draw connections from relays to endpoints
    relays.forEach((relay, index) => {
      const relayPos = nodes.get(relay.id);
      if (!relayPos) return;
      
      // Assign endpoints to relays
      const relayEndpoints = endpoints.filter((_, i) => i % relays.length === index);
      
      relayEndpoints.forEach(endpoint => {
        const endpointPos = nodes.get(endpoint.id);
        if (!endpointPos) return;
        
        this.drawConnection(
          relayPos.x, relayPos.y,
          endpointPos.x, endpointPos.y,
          endpoint.signalStrength,
          false
        );
      });
    });
  }

  private drawHybridTopology(nodes: Map<string, any>, networkNodes: any[]): void {
    // Find coordinator and relay nodes
    const coordinator = networkNodes.find(node => node.type === 'coordinator');
    const relays = networkNodes.filter(node => node.type === 'relay');
    const bridges = networkNodes.filter(node => node.type === 'bridge');
    
    // Draw mesh between coordinator and relays
    if (coordinator) {
      const coordinatorPos = nodes.get(coordinator.id);
      if (coordinatorPos) {
        relays.forEach(relay => {
          const relayPos = nodes.get(relay.id);
          if (!relayPos) return;
          
          this.drawConnection(
            coordinatorPos.x, coordinatorPos.y,
            relayPos.x, relayPos.y,
            relay.signalStrength,
            false
          );
        });
        
        // Connect coordinator to bridges
        bridges.forEach(bridge => {
          const bridgePos = nodes.get(bridge.id);
          if (!bridgePos) return;
          
          this.drawConnection(
            coordinatorPos.x, coordinatorPos.y,
            bridgePos.x, bridgePos.y,
            bridge.signalStrength,
            true
          );
        });
      }
    }
    
    // Connect relays in a partial mesh
    for (let i = 0; i < relays.length; i++) {
      const relay1 = relays[i];
      const pos1 = nodes.get(relay1.id);
      if (!pos1) continue;
      
      // Connect to some other relays (not all)
      for (let j = i + 1; j < relays.length; j++) {
        if (Math.random() > 0.7) continue; // 30% chance to connect
        
        const relay2 = relays[j];
        const pos2 = nodes.get(relay2.id);
        if (!pos2) continue;
        
        this.drawConnection(
          pos1.x, pos1.y,
          pos2.x, pos2.y,
          Math.min(relay1.signalStrength, relay2.signalStrength),
          false
        );
      }
      
      // Connect relays to endpoints
      networkNodes.forEach(node => {
        if (node.type !== 'endpoint') return;
        if (Math.random() > 0.5) return; // 50% chance to connect
        
        const nodePos = nodes.get(node.id);
        if (!nodePos) return;
        
        this.drawConnection(
          pos1.x, pos1.y,
          nodePos.x, nodePos.y,
          node.signalStrength,
          false
        );
      });
    }
  }

  private drawConnection(x1: number, y1: number, x2: number, y2: number, signalStrength: number, isEmergency: boolean): void {
    this.ctx.beginPath();
    this.ctx.moveTo(x1, y1);
    this.ctx.lineTo(x2, y2);
    
    if (isEmergency) {
      // Emergency connection
      this.ctx.strokeStyle = '#f44336';
      this.ctx.lineWidth = 3;
    } else if (signalStrength >= 70) {
      // Strong connection
      this.ctx.strokeStyle = '#2196f3';
      this.ctx.lineWidth = 2;
    } else {
      // Weak connection
      this.ctx.strokeStyle = '#9e9e9e';
      this.ctx.lineWidth = 1;
      this.ctx.setLineDash([5, 3]);
    }
    
    this.ctx.stroke();
    this.ctx.setLineDash([]);
  }

  private drawLabels(nodes: Map<string, any>): void {
    this.ctx.font = '12px Arial';
    this.ctx.textAlign = 'center';
    this.ctx.textBaseline = 'middle';
    
    nodes.forEach(({ x, y, node }) => {
      // Draw node ID
      this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
      this.ctx.fillRect(
        x - 40, 
        y + this.nodeRadius + 5, 
        80, 
        20
      );
      
      this.ctx.fillStyle = '#fff';
      this.ctx.fillText(
        node.id.substring(0, 8) + '...',
        x,
        y + this.nodeRadius + 15
      );
    });
  }

  private drawHeatmap(nodes: Map<string, any>): void {
    // Create gradient for heatmap
    const gradient = this.ctx.createRadialGradient(0, 0, 0, 0, 0, 100);
    gradient.addColorStop(0, 'rgba(76, 175, 80, 0.8)');
    gradient.addColorStop(0.5, 'rgba(255, 152, 0, 0.5)');
    gradient.addColorStop(1, 'rgba(244, 67, 54, 0.1)');
    
    // Draw heatmap for each node
    nodes.forEach(({ x, y, node }) => {
      const radius = node.signalStrength * 1.5;
      
      this.ctx.save();
      this.ctx.translate(x, y);
      
      this.ctx.beginPath();
      this.ctx.arc(0, 0, radius, 0, Math.PI * 2);
      
      const nodeGradient = this.ctx.createRadialGradient(0, 0, 0, 0, 0, radius);
      nodeGradient.addColorStop(0, `rgba(76, 175, 80, ${node.signalStrength / 100})`);
      nodeGradient.addColorStop(0.7, `rgba(255, 152, 0, ${node.signalStrength / 200})`);
      nodeGradient.addColorStop(1, 'rgba(244, 67, 54, 0)');
      
      this.ctx.fillStyle = nodeGradient;
      this.ctx.fill();
      
      this.ctx.restore();
    });
  }

  private drawRoutes(nodes: Map<string, any>): void {
    // Get routing table
    const routingTable = this.routingService.routingTable();
    
    // Draw routes
    routingTable.forEach(entry => {
      entry.routes.forEach(route => {
        if (!route.isActive) return;
        
        const sourceNode = nodes.get(route.nextHop);
        const destNode = nodes.get(route.destination);
        
        if (!sourceNode || !destNode) return;
        
        // Draw route line
        this.ctx.beginPath();
        this.ctx.moveTo(sourceNode.x, sourceNode.y);
        this.ctx.lineTo(destNode.x, destNode.y);
        
        if (route.emergencyPriority) {
          // Emergency route
          this.ctx.strokeStyle = '#f44336';
          this.ctx.lineWidth = 3;
        } else {
          // Normal route
          this.ctx.strokeStyle = '#2196f3';
          this.ctx.lineWidth = 2;
        }
        
        // Add arrow
        const angle = Math.atan2(destNode.y - sourceNode.y, destNode.x - sourceNode.x);
        const arrowSize = 10;
        
        const arrowX = destNode.x - this.nodeRadius * Math.cos(angle);
        const arrowY = destNode.y - this.nodeRadius * Math.sin(angle);
        
        this.ctx.moveTo(arrowX, arrowY);
        this.ctx.lineTo(
          arrowX - arrowSize * Math.cos(angle - Math.PI / 6),
          arrowY - arrowSize * Math.sin(angle - Math.PI / 6)
        );
        
        this.ctx.moveTo(arrowX, arrowY);
        this.ctx.lineTo(
          arrowX - arrowSize * Math.cos(angle + Math.PI / 6),
          arrowY - arrowSize * Math.sin(angle + Math.PI / 6)
        );
        
        this.ctx.stroke();
        
        // Draw hop count
        this.ctx.font = '12px Arial';
        this.ctx.textAlign = 'center';
        this.ctx.textBaseline = 'middle';
        this.ctx.fillStyle = '#fff';
        
        const midX = (sourceNode.x + destNode.x) / 2;
        const midY = (sourceNode.y + destNode.y) / 2;
        
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        this.ctx.fillRect(midX - 15, midY - 10, 30, 20);
        
        this.ctx.fillStyle = '#fff';
        this.ctx.fillText(route.hopCount.toString(), midX, midY);
      });
    });
  }

  private drawCoverageAreas(networks: MeshNetwork[]): void {
    // Draw coverage area for each network
    networks.forEach(network => {
      // Calculate center position
      const centerX = this.canvasWidth / 2 + this.panOffset.x;
      const centerY = this.canvasHeight / 2 + this.panOffset.y;
      
      // Calculate radius in pixels (scale based on canvas size)
      const pixelRadius = (network.coverage.radius / 1000) * Math.min(this.canvasWidth, this.canvasHeight) * 0.4 * this.zoomLevel;
      
      // Draw coverage circle
      this.ctx.beginPath();
      this.ctx.arc(centerX, centerY, pixelRadius, 0, Math.PI * 2);
      
      // Set color based on network type
      if (network.type === 'emergency') {
        this.ctx.fillStyle = 'rgba(244, 67, 54, 0.1)';
        this.ctx.strokeStyle = 'rgba(244, 67, 54, 0.5)';
      } else {
        this.ctx.fillStyle = 'rgba(33, 150, 243, 0.1)';
        this.ctx.strokeStyle = 'rgba(33, 150, 243, 0.5)';
      }
      
      this.ctx.fill();
      this.ctx.lineWidth = 2;
      this.ctx.stroke();
      
      // Draw coverage radius label
      this.ctx.font = '14px Arial';
      this.ctx.textAlign = 'center';
      this.ctx.textBaseline = 'middle';
      this.ctx.fillStyle = '#333';
      
      this.ctx.fillText(
        `${(network.coverage.radius / 1000).toFixed(1)} km`,
        centerX,
        centerY + pixelRadius + 20
      );
    });
  }

  private drawEmergencyConnections(nodes: Map<string, any>): void {
    // Draw emergency connections between nodes
    nodes.forEach((source, sourceId) => {
      if (source.node.emergencyStatus === 'normal') return;
      
      nodes.forEach((dest, destId) => {
        if (sourceId === destId) return;
        if (dest.node.emergencyStatus === 'normal') return;
        
        // Draw emergency connection
        this.ctx.beginPath();
        this.ctx.moveTo(source.x, source.y);
        this.ctx.lineTo(dest.x, dest.y);
        
        this.ctx.strokeStyle = '#f44336';
        this.ctx.lineWidth = 3;
        this.ctx.stroke();
      });
    });
  }
}