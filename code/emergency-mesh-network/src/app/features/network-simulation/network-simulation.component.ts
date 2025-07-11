import { Component, inject, OnInit, OnDestroy, computed, signal, ViewChild, ElementRef, AfterViewInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatSliderModule } from '@angular/material/slider';
import { MatSelectModule } from '@angular/material/select';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatTabsModule } from '@angular/material/tabs';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';

import { NetworkSimulationService, SimulationScenario, SimulationNode, SimulationEvent, SimulationMessage } from '../network-visualization/network-simulation.service';
import { NetworkTopologyRendererService } from '../network-visualization/network-topology-renderer.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-network-simulation',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
    MatChipsModule,
    MatSliderModule,
    MatSelectModule,
    MatFormFieldModule,
    MatTabsModule,
    FormsModule
  ],
  template: `
    <div class="simulation-container">
      <h1>Network Simulation</h1>
      
      <!-- Simulation Controls -->
      <mat-card class="control-panel">
        <mat-card-header>
          <mat-card-title>Simulation Control Panel</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="control-row">
            <mat-form-field appearance="outline">
              <mat-label>Simulation Scenario</mat-label>
              <mat-select [(ngModel)]="selectedScenarioId" (selectionChange)="onScenarioChange()">
                @for (scenario of availableScenarios; track scenario.id) {
                  <mat-option [value]="scenario.id">{{ scenario.name }}</mat-option>
                }
              </mat-select>
            </mat-form-field>
            
            <div class="simulation-speed">
              <span>Speed:</span>
              <mat-slider min="0.5" max="5" step="0.5" [discrete]="true">
                <input matSliderThumb [(ngModel)]="simulationSpeed" (change)="updateSimulationSpeed()">
              </mat-slider>
              <span>{{ simulationSpeed }}x</span>
            </div>
          </div>
          
          <div class="scenario-description" *ngIf="selectedScenario">
            <p>{{ selectedScenario.description }}</p>
            <div class="scenario-params">
              <div class="param-item">
                <span class="param-label">Nodes:</span>
                <span class="param-value">{{ selectedScenario.nodeCount }}</span>
              </div>
              <div class="param-item">
                <span class="param-label">Message Rate:</span>
                <span class="param-value">{{ selectedScenario.messageRate }}/min</span>
              </div>
              <div class="param-item">
                <span class="param-label">Failure Rate:</span>
                <span class="param-value">{{ (selectedScenario.failureRate * 100).toFixed(1) }}%</span>
              </div>
              <div class="param-item">
                <span class="param-label">Emergency Prob:</span>
                <span class="param-value">{{ (selectedScenario.emergencyProbability * 100).toFixed(1) }}%</span>
              </div>
            </div>
          </div>
          
          <div class="control-actions">
            <ng-container *ngIf="isSimulationRunning$ | async as isRunning">
              <ng-container *ngIf="!isRunning; else runningBlock">
                <button mat-raised-button color="primary" (click)="startSimulation()">
                  <mat-icon>play_arrow</mat-icon>
                  Start Simulation
                </button>
              </ng-container>
              <ng-template #runningBlock>
                <button mat-raised-button color="warn" (click)="stopSimulation()">
                  <mat-icon>stop</mat-icon>
                  Stop Simulation
                </button>
                <ng-container *ngIf="isSimulationPaused; else pauseBlock">
                  <button mat-raised-button color="accent" (click)="resumeSimulation()">
                    <mat-icon>play_arrow</mat-icon>
                    Resume
                  </button>
                </ng-container>
                <ng-template #pauseBlock>
                  <button mat-raised-button color="accent" (click)="pauseSimulation()">
                    <mat-icon>pause</mat-icon>
                    Pause
                  </button>
                </ng-template>
              </ng-template>
              <button mat-button (click)="resetSimulation()" [disabled]="isRunning && !isSimulationPaused">
                <mat-icon>refresh</mat-icon>
                Reset
              </button>
            </ng-container>
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Simulation Visualization -->
      <mat-card class="visualization-card">
        <mat-card-header>
          <mat-card-title>Network Visualization</mat-card-title>
          <ng-container *ngIf="isSimulationRunning$ | async as isRunning">
            <div class="simulation-time" *ngIf="isRunning">
              <mat-icon>timer</mat-icon>
              <ng-container *ngIf="simulationTime$ | async as simTime">
                <span>Time: {{ formatTime(simTime) }}</span>
              </ng-container>
            </div>
          </ng-container>
        </mat-card-header>
        <mat-card-content>
          <div class="canvas-container">
            <canvas #simulationCanvas></canvas>
            <ng-container *ngIf="(isSimulationRunning$ | async) === false && (simulationNodes$ | async)?.length === 0">
              <div class="no-data-overlay">
                <mat-icon>hub</mat-icon>
                <h3>No Simulation Data</h3>
                <p>Select a scenario and start the simulation</p>
              </div>
            </ng-container>
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Simulation Metrics -->
      <mat-card class="metrics-card">
        <mat-card-header>
          <mat-card-title>Simulation Metrics</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <ng-container *ngIf="simulationMetrics$ | async as metrics">
            <div class="metrics-grid">
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>check_circle</mat-icon>
                  <h3>Message Delivery Rate</h3>
                </div>
                <div class="metric-value">{{ metrics.messageDeliveryRate.toFixed(1) }}%</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="metrics.messageDeliveryRate"
                                  [color]="getMetricColor(metrics.messageDeliveryRate, true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>speed</mat-icon>
                  <h3>Average Latency</h3>
                </div>
                <div class="metric-value">{{ metrics.averageLatency.toFixed(1) }} ms</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="100 - (metrics.averageLatency / 5)"
                                  [color]="getMetricColor(100 - (metrics.averageLatency / 5), true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>network_check</mat-icon>
                  <h3>Network Reliability</h3>
                </div>
                <div class="metric-value">{{ metrics.networkReliability.toFixed(1) }}%</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="metrics.networkReliability"
                                  [color]="getMetricColor(metrics.networkReliability, true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>battery_charging_full</mat-icon>
                  <h3>Battery Consumption</h3>
                </div>
                <div class="metric-value">{{ metrics.batteryConsumption.toFixed(2) }}%/min</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="metrics.batteryConsumption * 10"
                                  [color]="getMetricColor(100 - (metrics.batteryConsumption * 10), true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>route</mat-icon>
                  <h3>Routing Efficiency</h3>
                </div>
                <div class="metric-value">{{ metrics.routingEfficiency.toFixed(1) }}%</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="metrics.routingEfficiency"
                                  [color]="getMetricColor(metrics.routingEfficiency, true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>warning</mat-icon>
                  <h3>Emergency Response</h3>
                </div>
                <div class="metric-value">{{ metrics.emergencyResponseTime.toFixed(1) }} ms</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="100 - (metrics.emergencyResponseTime / 10)"
                                  [color]="getMetricColor(100 - (metrics.emergencyResponseTime / 10), true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>wifi_tethering</mat-icon>
                  <h3>Network Coverage</h3>
                </div>
                <div class="metric-value">{{ metrics.networkCoverage.toFixed(1) }}%</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="metrics.networkCoverage"
                                  [color]="getMetricColor(metrics.networkCoverage, true)">
                </mat-progress-bar>
              </div>
              <div class="metric-item">
                <div class="metric-header">
                  <mat-icon>error</mat-icon>
                  <h3>Node Failure Rate</h3>
                </div>
                <div class="metric-value">{{ metrics.nodeFailureRate.toFixed(1) }}%/min</div>
                <mat-progress-bar mode="determinate" 
                                  [value]="metrics.nodeFailureRate"
                                  [color]="getMetricColor(100 - metrics.nodeFailureRate, true)">
                </mat-progress-bar>
              </div>
            </div>
          </ng-container>
        </mat-card-content>
      </mat-card>
      
      <!-- Simulation Events -->
      <mat-card class="events-card">
        <mat-card-header>
          <mat-card-title>Simulation Events</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <ng-container *ngIf="simulationEvents$ | async as events">
            <div class="events-container">
              <ng-container *ngIf="events.length === 0; else eventsList">
                <div class="no-events">
                  <mat-icon>event_busy</mat-icon>
                  <p>No events recorded yet</p>
                </div>
              </ng-container>
              <ng-template #eventsList>
                <div class="events-list">
                  <ng-container *ngFor="let event of events; trackBy: trackByEventId">
                    <div class="event-item" [ngClass]="getSeverityClass(event.severity)">
                      <div class="event-header">
                        <mat-icon>{{ getEventIcon(event.type) }}</mat-icon>
                        <div class="event-info">
                          <div class="event-title">{{ getEventTitle(event) }}</div>
                          <div class="event-time">{{ formatTime(event.timestamp) }}</div>
                        </div>
                        <mat-chip [ngClass]="getSeverityClass(event.severity)">
                          {{ getSeverityText(event.severity) }}
                        </mat-chip>
                      </div>
                      <div class="event-description">
                        {{ event.description }}
                      </div>
                      <ng-container *ngIf="event.resolved">
                        <div class="event-resolution">
                          <mat-icon>check_circle</mat-icon>
                          <span>Resolved at {{ formatTime(event.resolvedAt!) }}</span>
                        </div>
                      </ng-container>
                    </div>
                  </ng-container>
                </div>
              </ng-template>
            </div>
          </ng-container>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .simulation-container {
      max-width: 1200px;
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
      background: linear-gradient(135deg, #673ab7, #9c27b0);
      color: white;
    }

    .control-row {
      display: flex;
      justify-content: space-between;
      gap: 16px;
      margin-bottom: 16px;
    }

    mat-form-field {
      flex: 1;
    }

    .simulation-speed {
      display: flex;
      align-items: center;
      gap: 8px;
      min-width: 200px;
    }

    .simulation-speed mat-slider {
      flex: 1;
    }

    .scenario-description {
      background: rgba(255, 255, 255, 0.1);
      padding: 12px;
      border-radius: 8px;
      margin-bottom: 16px;
    }

    .scenario-description p {
      margin: 0 0 8px 0;
    }

    .scenario-params {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
    }

    .param-item {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .param-label {
      font-size: 12px;
      opacity: 0.8;
    }

    .param-value {
      font-weight: bold;
    }

    .control-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .visualization-card {
      margin-bottom: 24px;
    }

    .simulation-time {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
      color: #666;
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

    .no-data-overlay mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      color: #666;
    }

    .no-data-overlay h3 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .no-data-overlay p {
      margin: 0;
      color: #666;
    }

    .metrics-card {
      margin-bottom: 24px;
    }

    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .metric-item {
      padding: 16px;
      border-radius: 8px;
      background: #f5f5f5;
    }

    .metric-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }

    .metric-header h3 {
      margin: 0;
      font-size: 16px;
      color: #333;
    }

    .metric-header mat-icon {
      color: #666;
    }

    .metric-value {
      font-size: 24px;
      font-weight: bold;
      color: #333;
      margin-bottom: 8px;
    }

    .events-card {
      margin-bottom: 24px;
    }

    .events-container {
      max-height: 400px;
      overflow-y: auto;
    }

    .no-events {
      text-align: center;
      padding: 32px;
      color: #666;
    }

    .no-events mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    .events-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .event-item {
      padding: 12px;
      border-radius: 8px;
      border-left: 4px solid #9e9e9e;
    }

    .event-item.low {
      background-color: #e8f5e9;
      border-left-color: #4caf50;
    }

    .event-item.medium {
      background-color: #fff3e0;
      border-left-color: #ff9800;
    }

    .event-item.high {
      background-color: #ffebee;
      border-left-color: #f44336;
    }

    .event-item.critical {
      background-color: #f44336;
      color: white;
      border-left-color: #b71c1c;
    }

    .event-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 8px;
    }

    .event-info {
      flex: 1;
    }

    .event-title {
      font-weight: bold;
    }

    .event-time {
      font-size: 12px;
      opacity: 0.8;
    }

    .event-description {
      margin-bottom: 8px;
    }

    .event-resolution {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 12px;
      color: #4caf50;
    }

    .event-item.critical .event-resolution {
      color: white;
    }

    mat-chip.low {
      background-color: #4caf50;
      color: white;
    }

    mat-chip.medium {
      background-color: #ff9800;
      color: white;
    }

    mat-chip.high {
      background-color: #f44336;
      color: white;
    }

    mat-chip.critical {
      background-color: #b71c1c;
      color: white;
    }

    @media (max-width: 768px) {
      .simulation-container {
        padding: 8px;
      }
      
      .control-row {
        flex-direction: column;
      }
      
      .control-actions {
        flex-direction: column;
      }
      
      .control-actions button {
        width: 100%;
      }
      
      .canvas-container {
        height: 300px;
      }
      
      .metrics-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class NetworkSimulationComponent implements OnInit, OnDestroy, AfterViewInit {
  @ViewChild('simulationCanvas') canvasRef!: ElementRef<HTMLCanvasElement>;
  
  private simulationService = inject(NetworkSimulationService);
  private rendererService = inject(NetworkTopologyRendererService);
  private analyticsService = inject(AnalyticsService);

  // Simulation state
  availableScenarios: SimulationScenario[] = [];
  selectedScenarioId = '';
  selectedScenario: SimulationScenario | null = null;
  simulationSpeed = 1;
  isSimulationPaused = false;

  // Reactive state from service
  isSimulationRunning$ = this.simulationService.isSimulationRunning$;
  simulationTime$ = this.simulationService.simulationTime$;
  simulationNodes$ = this.simulationService.simulationNodes$;
  simulationMessages$ = this.simulationService.simulationMessages$;
  simulationEvents$ = this.simulationService.simulationEvents$;
  simulationMetrics$ = this.simulationService.simulationMetrics$;

  // Canvas properties
  private animationFrame: number | null = null;

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.loadScenarios();
    this.setupEventListeners();
    this.analyticsService.trackPageView('network_simulation');
  }

  ngAfterViewInit(): void {
    this.initializeCanvas();
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
    if (this.animationFrame !== null) {
      cancelAnimationFrame(this.animationFrame);
    }
  }

  private loadScenarios(): void {
    this.availableScenarios = this.simulationService.getDefaultScenarios();
    if (this.availableScenarios.length > 0) {
      this.selectedScenarioId = this.availableScenarios[0].id;
      this.selectedScenario = this.availableScenarios[0];
    }
  }

  private setupEventListeners(): void {
    // Listen for simulation events
    this.subscriptions.add(
      this.simulationService.onSimulationTick$.subscribe(time => {
        this.renderSimulation();
      })
    );

    this.subscriptions.add(
      this.simulationService.onSimulationEvent$.subscribe(event => {
        // Could add visual feedback for events
      })
    );

    this.subscriptions.add(
      this.simulationService.onSimulationStopped$.subscribe(metrics => {
        this.isSimulationPaused = false;
      })
    );
  }

  private initializeCanvas(): void {
    if (!this.canvasRef) return;
    
    const canvas = this.canvasRef.nativeElement;
    const container = canvas.parentElement;
    
    if (!container) return;
    
    const width = container.clientWidth;
    const height = container.clientHeight;
    
    this.rendererService.initialize(this.canvasRef, width, height);
    
    // Start animation loop
    this.startAnimationLoop();
  }

  private startAnimationLoop(): void {
    const animate = () => {
      this.renderSimulation();
      this.animationFrame = requestAnimationFrame(animate);
    };
    
    this.animationFrame = requestAnimationFrame(animate);
  }

  private renderSimulation(): void {
    this.simulationNodes$.subscribe(nodes => {
      if (!nodes) return;
      // Convert simulation nodes to renderer format
      const renderNodes = nodes.map(node => ({
        id: node.id,
        x: node.x,
        y: node.y,
        type: node.type,
        signalStrength: node.signalStrength,
        batteryLevel: node.batteryLevel,
        isOnline: node.isOnline,
        emergencyStatus: node.emergencyStatus,
        label: this.getNodeLabel(node)
      }));
      // Create connections
      const connections = this.createConnectionsFromNodes(nodes);
      // Render the network
      this.rendererService.renderTopology(
        renderNodes,
        connections,
        {
          showLabels: true,
          showSignalStrength: true,
          showBatteryLevel: true,
          showEmergencyStatus: true,
          nodeSize: 15,
          lineWidth: 2,
          theme: 'light',
          animateConnections: true
        }
      );
    });
  }

  private createConnectionsFromNodes(nodes: SimulationNode[]): Array<{
    source: string;
    target: string;
    strength: number;
    isEmergency: boolean;
  }> {
    const connections: Array<{
      source: string;
      target: string;
      strength: number;
      isEmergency: boolean;
    }> = [];
    
    // Create connections based on node.connections
    nodes.forEach(node => {
      if (!node.isOnline) return;
      
      node.connections.forEach(targetId => {
        const targetNode = nodes.find(n => n.id === targetId);
        if (!targetNode || !targetNode.isOnline) return;
        
        // Avoid duplicate connections
        const existingConnection = connections.find(c => 
          (c.source === node.id && c.target === targetId) ||
          (c.source === targetId && c.target === node.id)
        );
        
        if (existingConnection) return;
        
        connections.push({
          source: node.id,
          target: targetId,
          strength: Math.min(node.signalStrength, targetNode.signalStrength),
          isEmergency: node.emergencyStatus !== 'normal' || targetNode.emergencyStatus !== 'normal'
        });
      });
    });
    
    return connections;
  }

  // UI Event Handlers
  onScenarioChange(): void {
    this.selectedScenario = this.availableScenarios.find(s => s.id === this.selectedScenarioId) || null;
  }

  startSimulation(): void {
    if (!this.selectedScenario) return;
    this.simulationService.startSimulation(this.selectedScenario);
    this.isSimulationPaused = false;
    this.analyticsService.trackUserAction('simulation_start', undefined, { scenarioId: this.selectedScenario.id });
  }

  stopSimulation(): void {
    this.simulationService.stopSimulation();
    this.isSimulationPaused = false;
    this.analyticsService.trackUserAction('simulation_stop');
  }

  pauseSimulation(): void {
    this.simulationService.pauseSimulation();
    this.isSimulationPaused = true;
    this.analyticsService.trackUserAction('simulation_pause');
  }

  resumeSimulation(): void {
    this.simulationService.resumeSimulation();
    this.isSimulationPaused = false;
    this.analyticsService.trackUserAction('simulation_resume');
  }

  resetSimulation(): void {
    this.simulationService.resetSimulation();
    this.isSimulationPaused = false;
    this.analyticsService.trackUserAction('simulation_reset');
  }

  updateSimulationSpeed(): void {
    this.simulationService.setSimulationSpeed(this.simulationSpeed);
    this.analyticsService.trackUserAction('simulation_speed_change', undefined, { speed: this.simulationSpeed });
  }

  // Helper Methods
  getNodeLabel(node: SimulationNode): string {
    return node.type.charAt(0).toUpperCase() + node.id.substring(node.id.lastIndexOf('_') + 1);
  }

  getEventIcon(type: string): string {
    switch (type) {
      case 'node_failure': return 'error';
      case 'battery_depletion': return 'battery_alert';
      case 'signal_degradation': return 'signal_wifi_bad';
      case 'emergency_activation': return 'warning';
      case 'message_loss': return 'message';
      case 'network_partition': return 'device_hub';
      default: return 'info';
    }
  }

  getEventTitle(event: SimulationEvent): string {
    switch (event.type) {
      case 'node_failure': return 'Node Failure';
      case 'battery_depletion': return 'Battery Depletion';
      case 'signal_degradation': return 'Signal Degradation';
      case 'emergency_activation': return 'Emergency Activated';
      case 'message_loss': return 'Message Lost';
      case 'network_partition': return 'Network Partition';
      default: return 'Event';
    }
  }

  getSeverityClass(severity: string): string {
    return severity;
  }

  getSeverityText(severity: string): string {
    switch (severity) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      case 'critical': return 'Critical';
      default: return 'Unknown';
    }
  }

  getMetricColor(value: number, higherIsBetter: boolean = true): 'primary' | 'accent' | 'warn' {
    if (higherIsBetter) {
      if (value >= 80) return 'primary';
      if (value >= 50) return 'accent';
      return 'warn';
    } else {
      if (value <= 20) return 'primary';
      if (value <= 50) return 'accent';
      return 'warn';
    }
  }

  formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  trackByEventId(index: number, event: SimulationEvent) {
    return event.id;
  }
}