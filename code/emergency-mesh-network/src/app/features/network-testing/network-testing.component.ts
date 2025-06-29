import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatTabsModule } from '@angular/material/tabs';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatSelectModule } from '@angular/material/select';
import { MatFormFieldModule } from '@angular/material/form-field';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';

import { WebrtcService } from '../../core/services/webrtc.service';
import { MeshNetworkImplementationService } from '../../core/services/mesh-network-implementation.service';
import { AnalyticsService } from '../../core/services/analytics.service';

interface TestResult {
  id: string;
  name: string;
  type: 'latency' | 'throughput' | 'reliability' | 'coverage';
  status: 'idle' | 'running' | 'completed' | 'failed';
  value?: number;
  unit?: string;
  timestamp?: number;
  details?: string;
}

@Component({
  selector: 'app-network-testing',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
    MatChipsModule,
    MatTabsModule,
    MatExpansionModule,
    MatSlideToggleModule,
    MatSelectModule,
    MatFormFieldModule,
    FormsModule
  ],
  template: `
    <div class="network-testing-container">
      <h1>Network Testing</h1>
      
      <!-- Test Control Panel -->
      <mat-card class="control-panel">
        <mat-card-header>
          <mat-card-title>Test Control Panel</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="control-actions">
            <div class="network-toggles">
              <mat-slide-toggle [(ngModel)]="webrtcEnabled" (change)="toggleWebRTC()">
                WebRTC
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="meshEnabled" (change)="toggleMeshNetwork()">
                Mesh Network
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="emergencyMode" (change)="toggleEmergencyMode()">
                Emergency Mode
              </mat-slide-toggle>
            </div>

            <div class="test-actions">
              <button mat-raised-button color="primary" 
                      (click)="runLatencyTest()"
                      [disabled]="isTestRunning('latency_test')">
                <mat-icon>network_check</mat-icon>
                Latency Test
              </button>
              
              <button mat-raised-button color="accent" 
                      (click)="runThroughputTest()"
                      [disabled]="isTestRunning('throughput_test')">
                <mat-icon>speed</mat-icon>
                Throughput Test
              </button>
              
              <button mat-raised-button color="warn" 
                      (click)="runReliabilityTest()"
                      [disabled]="isTestRunning('reliability_test')">
                <mat-icon>security</mat-icon>
                Reliability Test
              </button>
              
              <button mat-button 
                      (click)="runAllTests()"
                      [disabled]="isAnyTestRunning()">
                <mat-icon>playlist_play</mat-icon>
                Run All Tests
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Test Results -->
      <mat-card class="results-panel">
        <mat-card-header>
          <mat-card-title>Test Results</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="test-results-grid">
            @for (test of testResults(); track test.id) {
              <div class="test-result-card" [ngClass]="test.status">
                <div class="test-header">
                  <mat-icon>{{ getTestIcon(test.type) }}</mat-icon>
                  <h3>{{ test.name }}</h3>
                  <mat-chip [ngClass]="test.status">{{ getStatusText(test.status) }}</mat-chip>
                </div>
                
                <div class="test-content">
                  @if (test.status === 'completed' && test.value !== undefined) {
                    <div class="test-value">
                      <span class="value">{{ test.value }}</span>
                      <span class="unit">{{ test.unit }}</span>
                    </div>
                    <div class="test-timestamp">
                      {{ test.timestamp | date:'medium' }}
                    </div>
                    @if (test.details) {
                      <div class="test-details">
                        {{ test.details }}
                      </div>
                    }
                  } @else if (test.status === 'running') {
                    <div class="test-running">
                      <mat-progress-bar mode="indeterminate"></mat-progress-bar>
                      <p>Test running...</p>
                    </div>
                  } @else if (test.status === 'failed') {
                    <div class="test-failed">
                      <mat-icon color="warn">error</mat-icon>
                      <p>Test failed. Please try again.</p>
                    </div>
                  } @else {
                    <div class="test-idle">
                      <p>Click the button to run this test</p>
                    </div>
                  }
                </div>
                
                <div class="test-actions">
                  <button mat-button color="primary" 
                          (click)="runTest(test.id)"
                          [disabled]="test.status === 'running'">
                    <mat-icon>play_arrow</mat-icon>
                    Run Test
                  </button>
                </div>
              </div>
            }
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Network Metrics -->
      <mat-card class="metrics-panel">
        <mat-card-header>
          <mat-card-title>Network Metrics</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <mat-tab-group>
            <mat-tab label="WebRTC Metrics">
              <div class="metrics-container">
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>group</mat-icon>
                    <h3>Connected Peers</h3>
                  </div>
                  <div class="metric-value">{{ webrtcPeerCount() }}</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="webrtcPeerCount() * 10"
                                    color="primary">
                  </mat-progress-bar>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>speed</mat-icon>
                    <h3>Average Latency</h3>
                  </div>
                  <div class="metric-value">{{ webrtcLatency() }} ms</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="100 - webrtcLatency() / 5"
                                    [color]="getLatencyColor(webrtcLatency())">
                  </mat-progress-bar>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>swap_horiz</mat-icon>
                    <h3>Data Transferred</h3>
                  </div>
                  <div class="metric-value">{{ formatBytes(webrtcDataTransferred()) }}</div>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>network_check</mat-icon>
                    <h3>Connection Quality</h3>
                  </div>
                  <div class="metric-value">{{ webrtcQuality() }}</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="getQualityValue(webrtcQuality())"
                                    [color]="getQualityColor(webrtcQuality())">
                  </mat-progress-bar>
                </div>
              </div>
            </mat-tab>
            
            <mat-tab label="Mesh Network Metrics">
              <div class="metrics-container">
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>device_hub</mat-icon>
                    <h3>Mesh Nodes</h3>
                  </div>
                  <div class="metric-value">{{ meshNodeCount() }}</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="meshNodeCount() * 5"
                                    color="primary">
                  </mat-progress-bar>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>hub</mat-icon>
                    <h3>Network Count</h3>
                  </div>
                  <div class="metric-value">{{ meshNetworkCount() }}</div>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>route</mat-icon>
                    <h3>Average Path Length</h3>
                  </div>
                  <div class="metric-value">{{ meshPathLength().toFixed(1) }}</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="100 - meshPathLength() * 20"
                                    color="accent">
                  </mat-progress-bar>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>auto_graph</mat-icon>
                    <h3>Network Efficiency</h3>
                  </div>
                  <div class="metric-value">{{ meshEfficiency() }}%</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="meshEfficiency()"
                                    color="primary">
                  </mat-progress-bar>
                </div>
              </div>
            </mat-tab>
            
            <mat-tab label="Emergency Mode Metrics">
              <div class="metrics-container">
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>warning</mat-icon>
                    <h3>Emergency Status</h3>
                  </div>
                  <div class="metric-value">{{ emergencyMode ? 'Active' : 'Inactive' }}</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="emergencyMode ? 100 : 0"
                                    [color]="emergencyMode ? 'warn' : 'primary'">
                  </mat-progress-bar>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>priority_high</mat-icon>
                    <h3>Priority Messages</h3>
                  </div>
                  <div class="metric-value">{{ emergencyMessageCount() }}</div>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>schedule</mat-icon>
                    <h3>Avg. Response Time</h3>
                  </div>
                  <div class="metric-value">{{ emergencyResponseTime() }} ms</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="100 - emergencyResponseTime() / 10"
                                    [color]="getResponseTimeColor(emergencyResponseTime())">
                  </mat-progress-bar>
                </div>
                
                <div class="metric-item">
                  <div class="metric-header">
                    <mat-icon>battery_alert</mat-icon>
                    <h3>Battery Impact</h3>
                  </div>
                  <div class="metric-value">{{ emergencyBatteryImpact() }}%/hr</div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="emergencyBatteryImpact() * 10"
                                    [color]="getBatteryImpactColor(emergencyBatteryImpact())">
                  </mat-progress-bar>
                </div>
              </div>
            </mat-tab>
          </mat-tab-group>
        </mat-card-content>
      </mat-card>

      <!-- Test Logs -->
      <mat-card class="logs-panel">
        <mat-card-header>
          <mat-card-title>Test Logs</mat-card-title>
          <button mat-icon-button (click)="clearLogs()">
            <mat-icon>clear_all</mat-icon>
          </button>
        </mat-card-header>
        <mat-card-content>
          <div class="logs-container">
            @for (log of testLogs(); track log.timestamp) {
              <div class="log-entry" [ngClass]="log.level">
                <span class="log-time">{{ log.timestamp | date:'HH:mm:ss.SSS' }}</span>
                <mat-icon class="log-icon">{{ getLogIcon(log.level) }}</mat-icon>
                <span class="log-message">{{ log.message }}</span>
              </div>
            } @empty {
              <div class="empty-logs">
                <p>No test logs available</p>
              </div>
            }
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .network-testing-container {
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
      background: linear-gradient(135deg, #607d8b, #455a64);
      color: white;
    }

    .control-actions {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .network-toggles {
      display: flex;
      gap: 24px;
      flex-wrap: wrap;
    }

    .test-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .results-panel {
      margin-bottom: 24px;
    }

    .test-results-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .test-result-card {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 16px;
      background: white;
    }

    .test-result-card.running {
      border-color: #2196f3;
      background: #e3f2fd;
    }

    .test-result-card.completed {
      border-color: #4caf50;
      background: #e8f5e8;
    }

    .test-result-card.failed {
      border-color: #f44336;
      background: #ffebee;
    }

    .test-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
    }

    .test-header h3 {
      flex: 1;
      margin: 0;
      font-size: 16px;
    }

    mat-chip.idle {
      background-color: #9e9e9e;
      color: white;
    }

    mat-chip.running {
      background-color: #2196f3;
      color: white;
    }

    mat-chip.completed {
      background-color: #4caf50;
      color: white;
    }

    mat-chip.failed {
      background-color: #f44336;
      color: white;
    }

    .test-content {
      min-height: 100px;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      margin-bottom: 16px;
    }

    .test-value {
      text-align: center;
      margin-bottom: 8px;
    }

    .test-value .value {
      font-size: 32px;
      font-weight: bold;
      color: #333;
    }

    .test-value .unit {
      font-size: 16px;
      color: #666;
      margin-left: 4px;
    }

    .test-timestamp {
      font-size: 12px;
      color: #666;
      margin-bottom: 8px;
    }

    .test-details {
      font-size: 14px;
      color: #666;
      text-align: center;
    }

    .test-running {
      width: 100%;
      text-align: center;
    }

    .test-running mat-progress-bar {
      margin-bottom: 8px;
    }

    .test-failed {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      color: #f44336;
    }

    .test-idle {
      color: #666;
    }

    .test-actions {
      display: flex;
      justify-content: center;
    }

    .metrics-panel {
      margin-bottom: 24px;
    }

    .metrics-container {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      padding: 16px 0;
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

    .logs-panel {
      margin-bottom: 24px;
    }

    .logs-container {
      max-height: 300px;
      overflow-y: auto;
      background: #1e1e1e;
      color: #fff;
      padding: 16px;
      border-radius: 4px;
      font-family: 'Courier New', monospace;
    }

    .log-entry {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 4px;
      padding: 2px 0;
      font-size: 12px;
    }

    .log-entry.info {
      color: #2196f3;
    }

    .log-entry.warning {
      color: #ff9800;
    }

    .log-entry.error {
      color: #f44336;
    }

    .log-entry.success {
      color: #4caf50;
    }

    .log-time {
      color: #888;
      min-width: 80px;
      font-size: 10px;
    }

    .log-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }

    .log-message {
      flex: 1;
    }

    .empty-logs {
      text-align: center;
      color: #666;
      padding: 16px;
    }

    @media (max-width: 768px) {
      .network-testing-container {
        padding: 8px;
      }
      
      .control-actions {
        flex-direction: column;
      }
      
      .network-toggles,
      .test-actions {
        flex-direction: column;
      }
      
      .test-actions button {
        width: 100%;
      }
      
      .test-results-grid {
        grid-template-columns: 1fr;
      }
      
      .metrics-container {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class NetworkTestingComponent implements OnInit, OnDestroy {
  private webrtcService = inject(WebrtcService);
  private meshService = inject(MeshNetworkImplementationService);
  private analyticsService = inject(AnalyticsService);

  // Component state
  webrtcEnabled = false;
  meshEnabled = false;
  emergencyMode = false;

  // Reactive state with signals
  private _testResults = signal<TestResult[]>([]);
  private _testLogs = signal<Array<{
    timestamp: number;
    level: 'info' | 'warning' | 'error' | 'success';
    message: string;
  }>>([]);

  // Computed metrics
  testResults = this._testResults.asReadonly();
  testLogs = this._testLogs.asReadonly();

  // WebRTC metrics
  webrtcPeerCount = computed(() => this.webrtcService.connectedPeers().length);
  webrtcLatency = computed(() => this.getRandomMetric(50, 200)); // Simulated for now
  webrtcDataTransferred = computed(() => this.getRandomMetric(1024, 1024 * 1024)); // Simulated for now
  webrtcQuality = computed(() => {
    const peerCount = this.webrtcPeerCount();
    if (peerCount === 0) return 'Poor';
    if (peerCount < 3) return 'Fair';
    if (peerCount < 5) return 'Good';
    return 'Excellent';
  });

  // Mesh metrics
  meshNodeCount = computed(() => this.meshService.totalMeshNodes());
  meshNetworkCount = computed(() => Array.from(this.meshService.activeMeshNetworks().values()).length);
  meshPathLength = computed(() => this.getRandomMetric(1, 5)); // Simulated for now
  meshEfficiency = computed(() => this.getRandomMetric(60, 95)); // Simulated for now

  // Emergency metrics
  emergencyMessageCount = computed(() => this.getRandomMetric(0, 20)); // Simulated for now
  emergencyResponseTime = computed(() => this.getRandomMetric(50, 500)); // Simulated for now
  emergencyBatteryImpact = computed(() => this.getRandomMetric(1, 10)); // Simulated for now

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.initializeTestResults();
    this.setupEventListeners();
    this.analyticsService.trackPageView('network_testing');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private initializeTestResults(): void {
    const initialTests: TestResult[] = [
      {
        id: 'latency_test',
        name: 'Network Latency',
        type: 'latency',
        status: 'idle'
      },
      {
        id: 'throughput_test',
        name: 'Data Throughput',
        type: 'throughput',
        status: 'idle'
      },
      {
        id: 'reliability_test',
        name: 'Connection Reliability',
        type: 'reliability',
        status: 'idle'
      },
      {
        id: 'coverage_test',
        name: 'Network Coverage',
        type: 'coverage',
        status: 'idle'
      }
    ];

    this._testResults.set(initialTests);
  }

  private setupEventListeners(): void {
    // WebRTC events
    this.subscriptions.add(
      this.webrtcService.onPeerConnected$.subscribe(peer => {
        this.addLog('success', `WebRTC peer connected: ${peer.id.substring(0, 8)}`);
      })
    );

    this.subscriptions.add(
      this.webrtcService.onPeerDisconnected$.subscribe(peer => {
        this.addLog('warning', `WebRTC peer disconnected: ${peer.id.substring(0, 8)}`);
      })
    );

    // Mesh network events
    this.subscriptions.add(
      this.meshService.onMeshNetworkFormed$.subscribe(network => {
        this.addLog('success', `Mesh network formed: ${network.name}`);
      })
    );

    this.subscriptions.add(
      this.meshService.onMeshMessageRouted$.subscribe(message => {
        this.addLog('info', `Message routed: ${message.id.substring(0, 8)}`);
      })
    );
  }

  // Network toggle methods
  toggleWebRTC(): void {
    if (this.webrtcEnabled) {
      this.addLog('info', 'WebRTC enabled');
    } else {
      this.addLog('warning', 'WebRTC disabled');
      this.webrtcService.disconnectAll();
    }
  }

  toggleMeshNetwork(): void {
    if (this.meshEnabled) {
      this.addLog('info', 'Mesh network enabled');
    } else {
      this.addLog('warning', 'Mesh network disabled');
    }
  }

  toggleEmergencyMode(): void {
    if (this.emergencyMode) {
      this.addLog('warning', 'Emergency mode activated');
    } else {
      this.addLog('info', 'Emergency mode deactivated');
    }
  }

  // Test execution methods
  runLatencyTest(): void {
    this.runTest('latency_test');
  }

  runThroughputTest(): void {
    this.runTest('throughput_test');
  }

  runReliabilityTest(): void {
    this.runTest('reliability_test');
  }

  runAllTests(): void {
    this.addLog('info', 'Running all network tests...');
    
    // Run tests sequentially with delays
    setTimeout(() => this.runLatencyTest(), 0);
    setTimeout(() => this.runThroughputTest(), 3000);
    setTimeout(() => this.runReliabilityTest(), 6000);
    setTimeout(() => this.runTest('coverage_test'), 9000);
  }

  runTest(testId: string): void {
    const tests = this._testResults();
    const testIndex = tests.findIndex(t => t.id === testId);
    
    if (testIndex === -1) return;
    
    // Update test status to running
    const updatedTests = [...tests];
    updatedTests[testIndex] = {
      ...updatedTests[testIndex],
      status: 'running'
    };
    
    this._testResults.set(updatedTests);
    
    // Log test start
    this.addLog('info', `Starting ${updatedTests[testIndex].name} test...`);
    
    // Simulate test execution
    setTimeout(() => {
      this.completeTest(testId);
    }, 2000 + Math.random() * 1000);
  }

  private completeTest(testId: string): void {
    const tests = this._testResults();
    const testIndex = tests.findIndex(t => t.id === testId);
    
    if (testIndex === -1) return;
    
    const test = tests[testIndex];
    const success = Math.random() > 0.1; // 90% success rate
    
    let result: TestResult;
    
    if (success) {
      // Generate test result based on type
      switch (test.type) {
        case 'latency':
          result = {
            ...test,
            status: 'completed',
            value: Math.round(50 + Math.random() * 150),
            unit: 'ms',
            timestamp: Date.now(),
            details: 'Round-trip time between nodes'
          };
          break;
        case 'throughput':
          result = {
            ...test,
            status: 'completed',
            value: Math.round(500 + Math.random() * 1500),
            unit: 'KB/s',
            timestamp: Date.now(),
            details: 'Maximum data transfer rate'
          };
          break;
        case 'reliability':
          result = {
            ...test,
            status: 'completed',
            value: Math.round(75 + Math.random() * 25),
            unit: '%',
            timestamp: Date.now(),
            details: 'Message delivery success rate'
          };
          break;
        case 'coverage':
          result = {
            ...test,
            status: 'completed',
            value: Math.round(100 + Math.random() * 900),
            unit: 'm',
            timestamp: Date.now(),
            details: 'Estimated network coverage radius'
          };
          break;
        default:
          result = {
            ...test,
            status: 'completed',
            value: Math.round(Math.random() * 100),
            unit: 'units',
            timestamp: Date.now()
          };
      }
      
      this.addLog('success', `${test.name} test completed: ${result.value} ${result.unit}`);
    } else {
      // Test failed
      result = {
        ...test,
        status: 'failed',
        timestamp: Date.now()
      };
      
      this.addLog('error', `${test.name} test failed`);
    }
    
    // Update test results
    const updatedTests = [...tests];
    updatedTests[testIndex] = result;
    
    this._testResults.set(updatedTests);
    
    // Track analytics
    this.analyticsService.trackEvent(
      'test',
      test.type,
      success ? 'completed' : 'failed',
      undefined,
      success ? result.value : 0
    );
  }

  // Helper methods
  isTestRunning(testId: string): boolean {
    const test = this._testResults().find(t => t.id === testId);
    return test?.status === 'running';
  }

  isAnyTestRunning(): boolean {
    return this._testResults().some(t => t.status === 'running');
  }

  getTestIcon(type: string): string {
    switch (type) {
      case 'latency': return 'network_check';
      case 'throughput': return 'speed';
      case 'reliability': return 'security';
      case 'coverage': return 'wifi_tethering';
      default: return 'science';
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'idle': return 'Idle';
      case 'running': return 'Running';
      case 'completed': return 'Completed';
      case 'failed': return 'Failed';
      default: return 'Unknown';
    }
  }

  getLogIcon(level: string): string {
    switch (level) {
      case 'info': return 'info';
      case 'warning': return 'warning';
      case 'error': return 'error';
      case 'success': return 'check_circle';
      default: return 'help';
    }
  }

  getLatencyColor(latency: number): 'primary' | 'accent' | 'warn' {
    if (latency < 100) return 'primary';
    if (latency < 200) return 'accent';
    return 'warn';
  }

  getQualityValue(quality: string): number {
    switch (quality) {
      case 'Excellent': return 90;
      case 'Good': return 70;
      case 'Fair': return 50;
      case 'Poor': return 30;
      default: return 0;
    }
  }

  getQualityColor(quality: string): 'primary' | 'accent' | 'warn' {
    switch (quality) {
      case 'Excellent': return 'primary';
      case 'Good': return 'primary';
      case 'Fair': return 'accent';
      case 'Poor': return 'warn';
      default: return 'warn';
    }
  }

  getResponseTimeColor(time: number): 'primary' | 'accent' | 'warn' {
    if (time < 100) return 'primary';
    if (time < 300) return 'accent';
    return 'warn';
  }

  getBatteryImpactColor(impact: number): 'primary' | 'accent' | 'warn' {
    if (impact < 3) return 'primary';
    if (impact < 7) return 'accent';
    return 'warn';
  }

  formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  clearLogs(): void {
    this._testLogs.set([]);
  }

  private addLog(level: 'info' | 'warning' | 'error' | 'success', message: string): void {
    const logs = this._testLogs();
    const newLog = {
      timestamp: Date.now(),
      level,
      message
    };
    
    // Keep only last 100 logs
    const updatedLogs = [newLog, ...logs].slice(0, 100);
    this._testLogs.set(updatedLogs);
  }

  private getRandomMetric(min: number, max: number): number {
    return Math.floor(min + Math.random() * (max - min));
  }
}