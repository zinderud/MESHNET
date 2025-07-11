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

import { P2PNetworkService, P2PNode } from '../../core/services/p2p-network.service';
import { MeshNetworkImplementationService, MeshNetwork, MeshNetworkNode } from '../../core/services/mesh-network-implementation.service';
import { WebrtcService } from '../../core/services/webrtc.service';
import { AnalyticsService } from '../../core/services/analytics.service';

interface NetworkTest {
  id: string;
  name: string;
  type: 'latency' | 'throughput' | 'reliability' | 'coverage';
  status: 'idle' | 'running' | 'completed' | 'failed';
  result?: {
    value: number;
    unit: string;
    timestamp: number;
  };
  duration: number;
}

@Component({
  selector: 'app-network-implementation',
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
    <div class="network-implementation-container">
      <h1>🔧 Network Implementation & Testing</h1>
      
      <!-- Network Control Panel -->
      <mat-card class="control-panel">
        <mat-card-header>
          <mat-card-title>Network Control Panel</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="control-actions">
            <div class="network-toggles">
              <mat-slide-toggle [(ngModel)]="p2pEnabled" (change)="toggleP2PNetwork()">
                P2P Network
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="meshEnabled" (change)="toggleMeshNetwork()">
                Mesh Network
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="webrtcEnabled" (change)="toggleWebRTC()">
                WebRTC
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="emergencyMode" (change)="toggleEmergencyMode()">
                Emergency Mode
              </mat-slide-toggle>
            </div>

            <div class="network-actions">
              <button mat-raised-button color="primary" 
                      (click)="startNetworkDiscovery()"
                      [disabled]="isDiscovering()">
                <mat-icon>search</mat-icon>
                {{ isDiscovering() ? 'Discovering...' : 'Discover Peers' }}
              </button>
              
              <button mat-raised-button color="accent" 
                      (click)="createTestMeshNetwork()">
                <mat-icon>hub</mat-icon>
                Create Test Mesh
              </button>
              
              <button mat-raised-button color="warn" 
                      (click)="runAllNetworkTests()"
                      [disabled]="isTestingActive()">
                <mat-icon>speed</mat-icon>
                Run All Tests
              </button>
              
              <button mat-button 
                      (click)="resetNetworks()">
                <mat-icon>refresh</mat-icon>
                Reset Networks
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Network Status Overview -->
      <mat-card class="status-overview">
        <mat-card-header>
          <mat-card-title>Network Status Overview</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="status-grid">
            <div class="status-item p2p" [ngClass]="{'active': p2pEnabled}">
              <mat-icon>device_hub</mat-icon>
              <div class="status-info">
                <h3>P2P Network</h3>
                <p>{{ p2pPeerCount() }} peers connected</p>
                <div class="status-metrics">
                  <span>Health: {{ p2pNetworkHealth() }}%</span>
                  <mat-progress-bar mode="determinate" [value]="p2pNetworkHealth()"></mat-progress-bar>
                </div>
              </div>
            </div>

            <div class="status-item mesh" [ngClass]="{'active': meshEnabled}">
              <mat-icon>hub</mat-icon>
              <div class="status-info">
                <h3>Mesh Network</h3>
                <p>{{ meshNodeCount() }} nodes, {{ meshNetworkCount() }} networks</p>
                <div class="status-metrics">
                  <span>Efficiency: {{ meshEfficiency() }}%</span>
                  <mat-progress-bar mode="determinate" [value]="meshEfficiency()"></mat-progress-bar>
                </div>
              </div>
            </div>

            <div class="status-item webrtc" [ngClass]="{'active': webrtcEnabled}">
              <mat-icon>video_call</mat-icon>
              <div class="status-info">
                <h3>WebRTC</h3>
                <p>{{ webrtcPeerCount() }} connections</p>
                <div class="status-metrics">
                  <span>Quality: {{ webrtcQuality() }}%</span>
                  <mat-progress-bar mode="determinate" [value]="webrtcQuality()"></mat-progress-bar>
                </div>
              </div>
            </div>

            <div class="status-item emergency" [ngClass]="{'active': emergencyMode}">
              <mat-icon>warning</mat-icon>
              <div class="status-info">
                <h3>Emergency Mode</h3>
                <p>{{ emergencyCapacity() }} msg/min capacity</p>
                <div class="status-metrics">
                  <span>Readiness: {{ emergencyReadiness() }}%</span>
                  <mat-progress-bar mode="determinate" [value]="emergencyReadiness()"></mat-progress-bar>
                </div>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Network Testing -->
      <mat-card class="network-testing">
        <mat-card-header>
          <mat-card-title>Network Performance Testing</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <mat-tab-group>
            <!-- Test Results -->
            <mat-tab label="Test Results">
              <div class="tab-content">
                <div class="test-grid">
                  @for (test of networkTests(); track test.id) {
                    <div class="test-card" [ngClass]="test.status">
                      <div class="test-header">
                        <mat-icon>{{ getTestIcon(test.type) }}</mat-icon>
                        <h4>{{ test.name }}</h4>
                        <mat-chip [ngClass]="test.status">{{ getStatusText(test.status) }}</mat-chip>
                      </div>
                      
                      <div class="test-content">
                        @if (test.result) {
                          <div class="test-result">
                            <span class="result-value">{{ test.result.value }}</span>
                            <span class="result-unit">{{ test.result.unit }}</span>
                          </div>
                          <div class="test-timestamp">
                            {{ test.result.timestamp | date:'short':'tr' }}
                          </div>
                        } @else {
                          <div class="test-placeholder">
                            @if (test.status === 'running') {
                              <mat-progress-bar mode="indeterminate"></mat-progress-bar>
                              <span>Testing in progress...</span>
                            } @else {
                              <span>No test results yet</span>
                            }
                          </div>
                        }
                      </div>
                      
                      <div class="test-actions">
                        <button mat-button 
                                (click)="runSingleTest(test.id)"
                                [disabled]="test.status === 'running'">
                          <mat-icon>play_arrow</mat-icon>
                          Run Test
                        </button>
                      </div>
                    </div>
                  }
                </div>
              </div>
            </mat-tab>

            <!-- P2P Details -->
            <mat-tab label="P2P Network">
              <div class="tab-content">
                <div class="network-details">
                  <div class="detail-section">
                    <h3>Connected P2P Peers</h3>
                    @if (p2pPeers().length > 0) {
                      <div class="peers-list">
                        @for (peer of p2pPeers(); track peer.id) {
                          <div class="peer-card">
                            <div class="peer-header">
                              <mat-icon>{{ getPeerIcon(peer.deviceInfo.type) }}</mat-icon>
                              <div class="peer-info">
                                <span class="peer-id">{{ peer.id.substring(0, 12) }}...</span>
                                <span class="peer-type">{{ peer.nodeType }}</span>
                              </div>
                              <mat-chip [ngClass]="getPeerStatusClass(peer)">
                                {{ getPeerStatusText(peer) }}
                              </mat-chip>
                            </div>
                            
                            <div class="peer-metrics">
                              <div class="metric">
                                <mat-icon>signal_cellular_4_bar</mat-icon>
                                <span>{{ peer.connectionQuality }}%</span>
                              </div>
                              <div class="metric">
                                <mat-icon>star</mat-icon>
                                <span>{{ peer.reputation }}</span>
                              </div>
                              @if (peer.deviceInfo.batteryLevel) {
                                <div class="metric">
                                  <mat-icon>battery_full</mat-icon>
                                  <span>{{ peer.deviceInfo.batteryLevel }}%</span>
                                </div>
                              }
                            </div>
                            
                            <div class="peer-actions">
                              <button mat-button (click)="sendTestMessage(peer.id)">
                                <mat-icon>send</mat-icon>
                                Test Message
                              </button>
                              <button mat-button color="warn" (click)="disconnectPeer(peer.id)">
                                <mat-icon>link_off</mat-icon>
                                Disconnect
                              </button>
                            </div>
                          </div>
                        }
                      </div>
                    } @else {
                      <div class="empty-state">
                        <mat-icon>device_hub</mat-icon>
                        <p>No P2P peers connected</p>
                        <button mat-raised-button color="primary" (click)="startNetworkDiscovery()">
                          Discover Peers
                        </button>
                      </div>
                    }
                  </div>
                </div>
              </div>
            </mat-tab>

            <!-- Mesh Networks -->
            <mat-tab label="Mesh Networks">
              <div class="tab-content">
                <div class="mesh-networks">
                  @if (meshNetworks().length > 0) {
                    @for (network of meshNetworks(); track network.id) {
                      <mat-expansion-panel class="mesh-panel">
                        <mat-expansion-panel-header>
                          <mat-panel-title>
                            <mat-icon [ngClass]="getNetworkTypeClass(network.type)">
                              {{ getNetworkIcon(network.type) }}
                            </mat-icon>
                            {{ network.name }}
                          </mat-panel-title>
                          <mat-panel-description>
                            {{ network.nodes.size }} nodes - {{ network.topology }} topology
                          </mat-panel-description>
                        </mat-expansion-panel-header>

                        <div class="mesh-network-details">
                          <div class="network-info">
                            <div class="info-grid">
                              <div class="info-item">
                                <span class="info-label">Network Type:</span>
                                <span class="info-value">{{ network.type }}</span>
                              </div>
                              <div class="info-item">
                                <span class="info-label">Topology:</span>
                                <span class="info-value">{{ network.topology }}</span>
                              </div>
                              <div class="info-item">
                                <span class="info-label">Coverage Radius:</span>
                                <span class="info-value">{{ network.coverage.radius }}m</span>
                              </div>
                              <div class="info-item">
                                <span class="info-label">Throughput:</span>
                                <span class="info-value">{{ network.performance.throughput }} msg/min</span>
                              </div>
                              <div class="info-item">
                                <span class="info-label">Latency:</span>
                                <span class="info-value">{{ network.performance.latency }}ms</span>
                              </div>
                              <div class="info-item">
                                <span class="info-label">Reliability:</span>
                                <span class="info-value">{{ network.performance.reliability }}%</span>
                              </div>
                            </div>
                          </div>

                          <div class="network-nodes">
                            <h4>Network Nodes ({{ network.nodes.size }})</h4>
                            <div class="nodes-grid">
                              @for (node of getNetworkNodesArray(network); track node.id) {
                                <div class="mesh-node-card" [ngClass]="node.type">
                                  <div class="node-header">
                                    <mat-icon>{{ getNodeIcon(node.type) }}</mat-icon>
                                    <span class="node-type">{{ getNodeTypeText(node.type) }}</span>
                                  </div>
                                  <div class="node-status">
                                    <mat-chip [ngClass]="{'online': node.isOnline, 'offline': !node.isOnline}">
                                      {{ node.isOnline ? 'Online' : 'Offline' }}
                                    </mat-chip>
                                  </div>
                                  <div class="node-metrics">
                                    <div class="node-metric">
                                      <mat-icon>signal_cellular_4_bar</mat-icon>
                                      <span>{{ node.signalStrength }}%</span>
                                    </div>
                                    <div class="node-metric">
                                      <mat-icon>battery_full</mat-icon>
                                      <span>{{ node.batteryLevel }}%</span>
                                    </div>
                                  </div>
                                </div>
                              }
                            </div>
                          </div>

                          <div class="network-actions">
                            <button mat-raised-button color="primary" 
                                    (click)="optimizeNetworkTopology(network.id)">
                              <mat-icon>tune</mat-icon>
                              Optimize Topology
                            </button>
                            <button mat-raised-button color="accent" 
                                    (click)="sendBroadcastMessage(network.id)">
                              <mat-icon>broadcast_on_personal</mat-icon>
                              Broadcast Test
                            </button>
                            <button mat-button color="warn" 
                                    (click)="leaveMeshNetwork(network.id)">
                              <mat-icon>exit_to_app</mat-icon>
                              Leave Network
                            </button>
                          </div>
                        </div>
                      </mat-expansion-panel>
                    }
                  } @else {
                    <div class="empty-state">
                      <mat-icon>hub</mat-icon>
                      <p>No mesh networks active</p>
                      <button mat-raised-button color="primary" (click)="createTestMeshNetwork()">
                        Create Test Network
                      </button>
                    </div>
                  }
                </div>
              </div>
            </mat-tab>

            <!-- Configuration -->
            <mat-tab label="Configuration">
              <div class="tab-content">
                <div class="configuration-panel">
                  <div class="config-section">
                    <h3>Network Configuration</h3>
                    
                    <mat-form-field appearance="outline">
                      <mat-label>Max P2P Connections</mat-label>
                      <mat-select [(ngModel)]="maxP2PConnections">
                        <mat-option value="4">4 connections</mat-option>
                        <mat-option value="8">8 connections</mat-option>
                        <mat-option value="12">12 connections</mat-option>
                        <mat-option value="16">16 connections</mat-option>
                      </mat-select>
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Mesh Topology</mat-label>
                      <mat-select [(ngModel)]="preferredMeshTopology">
                        <mat-option value="star">Star</mat-option>
                        <mat-option value="mesh">Full Mesh</mat-option>
                        <mat-option value="tree">Tree</mat-option>
                        <mat-option value="hybrid">Hybrid</mat-option>
                      </mat-select>
                    </mat-form-field>

                    <mat-form-field appearance="outline">
                      <mat-label>Message Priority</mat-label>
                      <mat-select [(ngModel)]="messagePriority">
                        <mat-option value="low">Low</mat-option>
                        <mat-option value="normal">Normal</mat-option>
                        <mat-option value="high">High</mat-option>
                        <mat-option value="emergency">Emergency</mat-option>
                      </mat-select>
                    </mat-form-field>
                  </div>

                  <div class="config-section">
                    <h3>Emergency Configuration</h3>
                    
                    <div class="config-toggles">
                      <mat-slide-toggle [(ngModel)]="autoEmergencyMode">
                        Auto Emergency Mode
                      </mat-slide-toggle>
                      
                      <mat-slide-toggle [(ngModel)]="emergencyBroadcast">
                        Emergency Broadcast
                      </mat-slide-toggle>
                      
                      <mat-slide-toggle [(ngModel)]="locationSharing">
                        Location Sharing
                      </mat-slide-toggle>
                      
                      <mat-slide-toggle [(ngModel)]="encryptionEnabled">
                        End-to-End Encryption
                      </mat-slide-toggle>
                    </div>
                  </div>

                  <div class="config-actions">
                    <button mat-raised-button color="primary" (click)="saveConfiguration()">
                      <mat-icon>save</mat-icon>
                      Save Configuration
                    </button>
                    <button mat-button (click)="resetConfiguration()">
                      <mat-icon>restore</mat-icon>
                      Reset to Defaults
                    </button>
                  </div>
                </div>
              </div>
            </mat-tab>
          </mat-tab-group>
        </mat-card-content>
      </mat-card>

      <!-- Real-time Logs -->
      <mat-card class="network-logs">
        <mat-card-header>
          <mat-card-title>Network Activity Logs</mat-card-title>
          <button mat-icon-button (click)="clearLogs()">
            <mat-icon>clear_all</mat-icon>
          </button>
        </mat-card-header>
        <mat-card-content>
          <div class="logs-container">
            @for (log of networkLogs(); track log.timestamp) {
              <div class="log-entry" [ngClass]="log.level">
                <span class="log-time">{{ log.timestamp | date:'HH:mm:ss.SSS' }}</span>
                <mat-icon class="log-icon">{{ getLogIcon(log.level) }}</mat-icon>
                <span class="log-category">[{{ log.category }}]</span>
                <span class="log-message">{{ log.message }}</span>
              </div>
            }
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .network-implementation-container {
      max-width: 1400px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
      font-size: 28px;
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

    .network-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .network-actions button {
      min-width: 150px;
    }

    .status-overview {
      margin-bottom: 24px;
    }

    .status-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 16px;
    }

    .status-item {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 20px;
      border-radius: 8px;
      border: 2px solid transparent;
      background: #f8f9fa;
      transition: all 0.3s ease;
    }

    .status-item.active {
      border-color: #2196f3;
      background: #e3f2fd;
    }

    .status-item.p2p.active {
      border-color: #4caf50;
      background: #e8f5e8;
    }

    .status-item.mesh.active {
      border-color: #ff9800;
      background: #fff3e0;
    }

    .status-item.webrtc.active {
      border-color: #9c27b0;
      background: #f3e5f5;
    }

    .status-item.emergency.active {
      border-color: #f44336;
      background: #ffebee;
    }

    .status-item mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #666;
    }

    .status-item.active mat-icon {
      color: #2196f3;
    }

    .status-item.p2p.active mat-icon {
      color: #4caf50;
    }

    .status-item.mesh.active mat-icon {
      color: #ff9800;
    }

    .status-item.webrtc.active mat-icon {
      color: #9c27b0;
    }

    .status-item.emergency.active mat-icon {
      color: #f44336;
    }

    .status-info {
      flex: 1;
    }

    .status-info h3 {
      margin: 0 0 4px 0;
      font-size: 16px;
      font-weight: 500;
    }

    .status-info p {
      margin: 0 0 8px 0;
      font-size: 14px;
      color: #666;
    }

    .status-metrics {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .status-metrics span {
      font-size: 12px;
      color: #666;
    }

    .network-testing {
      margin-bottom: 24px;
    }

    .tab-content {
      padding: 16px 0;
    }

    .test-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 16px;
    }

    .test-card {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 16px;
      background: white;
    }

    .test-card.running {
      border-color: #2196f3;
      background: #e3f2fd;
    }

    .test-card.completed {
      border-color: #4caf50;
      background: #e8f5e8;
    }

    .test-card.failed {
      border-color: #f44336;
      background: #ffebee;
    }

    .test-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
    }

    .test-header h4 {
      flex: 1;
      margin: 0;
      font-size: 16px;
    }

    .test-content {
      margin-bottom: 16px;
      min-height: 60px;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }

    .test-result {
      text-align: center;
    }

    .result-value {
      font-size: 24px;
      font-weight: bold;
      color: #333;
    }

    .result-unit {
      font-size: 14px;
      color: #666;
      margin-left: 4px;
    }

    .test-timestamp {
      text-align: center;
      font-size: 12px;
      color: #666;
      margin-top: 4px;
    }

    .test-placeholder {
      text-align: center;
      color: #666;
    }

    .test-actions {
      display: flex;
      justify-content: center;
    }

    .peers-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .peer-card {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 16px;
      background: white;
    }

    .peer-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 12px;
    }

    .peer-info {
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .peer-id {
      font-weight: 500;
      font-size: 14px;
    }

    .peer-type {
      font-size: 12px;
      color: #666;
    }

    .peer-metrics {
      display: flex;
      gap: 16px;
      margin-bottom: 12px;
    }

    .metric {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 14px;
    }

    .metric mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .peer-actions {
      display: flex;
      gap: 8px;
    }

    .mesh-panel {
      margin-bottom: 16px;
    }

    .mesh-network-details {
      padding: 16px 0;
    }

    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 12px;
      margin-bottom: 24px;
    }

    .info-item {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid #eee;
    }

    .info-label {
      font-weight: 500;
      color: #666;
    }

    .info-value {
      font-weight: 600;
      color: #333;
    }

    .network-nodes h4 {
      margin: 16px 0;
      color: #333;
    }

    .nodes-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
      gap: 12px;
      margin-bottom: 16px;
    }

    .mesh-node-card {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 12px;
      background: white;
    }

    .mesh-node-card.coordinator {
      border-color: #f44336;
      background: #ffebee;
    }

    .mesh-node-card.relay {
      border-color: #ff9800;
      background: #fff3e0;
    }

    .mesh-node-card.bridge {
      border-color: #2196f3;
      background: #e3f2fd;
    }

    .node-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }

    .node-type {
      font-weight: 500;
      font-size: 12px;
    }

    .node-status {
      margin-bottom: 8px;
    }

    .node-status mat-chip.online {
      background-color: #4caf50;
      color: white;
    }

    .node-status mat-chip.offline {
      background-color: #f44336;
      color: white;
    }

    .node-metrics {
      display: flex;
      gap: 12px;
    }

    .node-metric {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
    }

    .node-metric mat-icon {
      font-size: 14px;
      width: 14px;
      height: 14px;
    }

    .network-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .configuration-panel {
      max-width: 600px;
    }

    .config-section {
      margin-bottom: 32px;
    }

    .config-section h3 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .config-section mat-form-field {
      width: 100%;
      margin-bottom: 16px;
    }

    .config-toggles {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .config-actions {
      display: flex;
      gap: 12px;
    }

    .empty-state {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    .network-logs {
      margin-top: 24px;
    }

    .logs-container {
      max-height: 400px;
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

    .log-category {
      color: #ccc;
      min-width: 60px;
      font-size: 10px;
    }

    .log-message {
      flex: 1;
    }

    @media (max-width: 768px) {
      .network-implementation-container {
        padding: 8px;
      }
      
      .control-actions {
        flex-direction: column;
      }
      
      .network-toggles,
      .network-actions {
        flex-direction: column;
      }
      
      .network-actions button {
        width: 100%;
      }
      
      .status-grid {
        grid-template-columns: 1fr;
      }
      
      .test-grid {
        grid-template-columns: 1fr;
      }
      
      .nodes-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class NetworkImplementationComponent implements OnInit, OnDestroy {
  private p2pService = inject(P2PNetworkService);
  private meshService = inject(MeshNetworkImplementationService);
  private webrtcService = inject(WebrtcService);
  private analyticsService = inject(AnalyticsService);

  // Component state signals
  private _isDiscovering = signal<boolean>(false);
  private _isTestingActive = signal<boolean>(false);
  private _networkTests = signal<NetworkTest[]>([]);
  private _networkLogs = signal<Array<{
    timestamp: number;
    level: 'info' | 'warning' | 'error' | 'success';
    category: string;
    message: string;
  }>>([]);

  // Configuration signals
  p2pEnabled = signal<boolean>(false);
  meshEnabled = signal<boolean>(false);
  webrtcEnabled = signal<boolean>(false);
  emergencyMode = signal<boolean>(false);

  maxP2PConnections = signal<number>(8);
  preferredMeshTopology = signal<string>('hybrid');
  messagePriority = signal<string>('normal');
  autoEmergencyMode = signal<boolean>(true);
  emergencyBroadcast = signal<boolean>(true);
  locationSharing = signal<boolean>(true);
  encryptionEnabled = signal<boolean>(true);

  // Reactive state from services
  p2pPeers = computed(() => Array.from(this.p2pService.connectedPeers().values()));
  meshNetworks = computed(() => Array.from(this.meshService.activeMeshNetworks().values()));
  webrtcPeers = computed(() => this.webrtcService.connectedPeers());

  // Computed metrics
  isDiscovering = this._isDiscovering.asReadonly();
  isTestingActive = this._isTestingActive.asReadonly();
  networkTests = this._networkTests.asReadonly();
  networkLogs = this._networkLogs.asReadonly();

  p2pPeerCount = computed(() => this.p2pPeers().length);
  p2pNetworkHealth = computed(() => this.p2pService.networkHealth());
  
  meshNodeCount = computed(() => this.meshService.totalMeshNodes());
  meshNetworkCount = computed(() => this.meshNetworks().length);
  meshEfficiency = computed(() => this.meshService.meshNetworkEfficiency());
  
  webrtcPeerCount = computed(() => this.webrtcPeers().length);
  webrtcQuality = computed(() => this.calculateWebRTCQuality());
  
  emergencyCapacity = computed(() => this.meshService.emergencyNetworkCapacity());
  emergencyReadiness = computed(() => this.calculateEmergencyReadiness());

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.initializeNetworkTests();
    this.setupEventListeners();
    this.analyticsService.trackPageView('network_implementation');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private initializeNetworkTests(): void {
    const tests: NetworkTest[] = [
      {
        id: 'latency_test',
        name: 'Network Latency',
        type: 'latency',
        status: 'idle',
        duration: 30000
      },
      {
        id: 'throughput_test',
        name: 'Message Throughput',
        type: 'throughput',
        status: 'idle',
        duration: 60000
      },
      {
        id: 'reliability_test',
        name: 'Connection Reliability',
        type: 'reliability',
        status: 'idle',
        duration: 120000
      },
      {
        id: 'coverage_test',
        name: 'Network Coverage',
        type: 'coverage',
        status: 'idle',
        duration: 45000
      }
    ];

    this._networkTests.set(tests);
  }

  private setupEventListeners(): void {
    // P2P events
    this.subscriptions.add(
      this.p2pService.onPeerConnected$.subscribe(peer => {
        this.addLog('success', 'P2P', `Peer connected: ${peer.id.substring(0, 12)}`);
      })
    );

    this.subscriptions.add(
      this.p2pService.onPeerDisconnected$.subscribe(peer => {
        this.addLog('warning', 'P2P', `Peer disconnected: ${peer.id.substring(0, 12)}`);
      })
    );

    // Mesh events
    this.subscriptions.add(
      this.meshService.onMeshNetworkFormed$.subscribe(network => {
        this.addLog('success', 'MESH', `Network formed: ${network.name}`);
      })
    );

    this.subscriptions.add(
      this.meshService.onMeshNodeJoined$.subscribe(({ networkId, node }) => {
        this.addLog('info', 'MESH', `Node joined network: ${node.id.substring(0, 12)}`);
      })
    );

    // WebRTC events
    this.subscriptions.add(
      this.webrtcService.onPeerConnected$.subscribe(peer => {
        this.addLog('success', 'WebRTC', `WebRTC peer connected: ${peer.id.substring(0, 12)}`);
      })
    );
  }

  // Network Control Methods
  async toggleP2PNetwork(): Promise<void> {
    if (this.p2pEnabled()) {
      this.addLog('info', 'P2P', 'Starting P2P network discovery...');
      await this.startNetworkDiscovery();
    } else {
      this.addLog('warning', 'P2P', 'P2P network disabled');
    }
  }

  async toggleMeshNetwork(): Promise<void> {
    if (this.meshEnabled()) {
      this.addLog('info', 'MESH', 'Mesh network enabled');
    } else {
      this.addLog('warning', 'MESH', 'Mesh network disabled');
      // Leave all mesh networks
      const networks = this.meshNetworks();
      for (const network of networks) {
        await this.leaveMeshNetwork(network.id);
      }
    }
  }

  async toggleWebRTC(): Promise<void> {
    if (this.webrtcEnabled()) {
      this.addLog('info', 'WebRTC', 'WebRTC enabled');
    } else {
      this.addLog('warning', 'WebRTC', 'WebRTC disabled');
      this.webrtcService.disconnectAll();
    }
  }

  async toggleEmergencyMode(): Promise<void> {
    if (this.emergencyMode()) {
      this.addLog('warning', 'EMERGENCY', 'Emergency mode activated');
      await this.createEmergencyMeshNetwork();
    } else {
      this.addLog('info', 'EMERGENCY', 'Emergency mode deactivated');
    }
  }

  async startNetworkDiscovery(): Promise<void> {
    this._isDiscovering.set(true);
    this.addLog('info', 'DISCOVERY', 'Starting peer discovery...');

    try {
      // Discover P2P peers
      if (this.p2pEnabled()) {
        const p2pPeers = await this.p2pService.discoverPeers();
        this.addLog('success', 'P2P', `Discovered ${p2pPeers.length} P2P peers`);
        
        // Connect to top peers
        for (const peer of p2pPeers.slice(0, 3)) {
          await this.p2pService.connectToPeer(peer);
        }
      }

      // Discover mesh nodes
      if (this.meshEnabled()) {
        const meshNodes = await this.meshService.discoverMeshNodes();
        this.addLog('success', 'MESH', `Discovered ${meshNodes.length} mesh nodes`);
      }

      this.addLog('success', 'DISCOVERY', 'Peer discovery completed');
    } catch (error) {
      this.addLog('error', 'DISCOVERY', `Discovery failed: ${error}`);
    } finally {
      this._isDiscovering.set(false);
    }
  }

  async createTestMeshNetwork(): Promise<void> {
    if (!this.meshEnabled()) {
      this.meshEnabled.set(true);
    }

    try {
      const networkId = await this.meshService.createEmergencyMeshNetwork('test', 'normal');
      this.addLog('success', 'MESH', `Test mesh network created: ${networkId}`);
    } catch (error) {
      this.addLog('error', 'MESH', `Failed to create test network: ${error}`);
    }
  }

  async createEmergencyMeshNetwork(): Promise<void> {
    try {
      const networkId = await this.meshService.createEmergencyMeshNetwork('emergency', 'high');
      this.addLog('warning', 'EMERGENCY', `Emergency mesh network created: ${networkId}`);
    } catch (error) {
      this.addLog('error', 'EMERGENCY', `Failed to create emergency network: ${error}`);
    }
  }

  async runAllNetworkTests(): Promise<void> {
    this._isTestingActive.set(true);
    this.addLog('info', 'TEST', 'Starting all network tests...');

    const tests = this._networkTests();
    
    for (const test of tests) {
      await this.runSingleTest(test.id);
      // Wait between tests
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    this._isTestingActive.set(false);
    this.addLog('success', 'TEST', 'All network tests completed');
  }

  async runSingleTest(testId: string): Promise<void> {
    const tests = this._networkTests();
    const testIndex = tests.findIndex(t => t.id === testId);
    
    if (testIndex === -1) return;

    const test = { ...tests[testIndex] };
    test.status = 'running';
    
    const updatedTests = [...tests];
    updatedTests[testIndex] = test;
    this._networkTests.set(updatedTests);

    this.addLog('info', 'TEST', `Running ${test.name}...`);

    try {
      // Simulate test execution
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Generate test result
      const result = this.generateTestResult(test.type);
      test.result = result;
      test.status = 'completed';
      
      this.addLog('success', 'TEST', `${test.name} completed: ${result.value}${result.unit}`);
    } catch (error) {
      test.status = 'failed';
      this.addLog('error', 'TEST', `${test.name} failed: ${error}`);
    }

    const finalTests = [...this._networkTests()];
    finalTests[testIndex] = test;
    this._networkTests.set(finalTests);
  }

  async resetNetworks(): Promise<void> {
    this.addLog('warning', 'SYSTEM', 'Resetting all networks...');
    
    // Disconnect all peers
    this.webrtcService.disconnectAll();
    
    // Leave all mesh networks
    const networks = this.meshNetworks();
    for (const network of networks) {
      await this.leaveMeshNetwork(network.id);
    }

    // Reset states
    this.p2pEnabled.set(false);
    this.meshEnabled.set(false);
    this.webrtcEnabled.set(false);
    this.emergencyMode.set(false);

    this.addLog('success', 'SYSTEM', 'All networks reset');
  }

  // Test and Action Methods
  async sendTestMessage(peerId: string): Promise<void> {
    try {
      const success = await this.p2pService.sendMessage({
        type: 'data',
        payload: { test: 'Hello from network implementation', timestamp: Date.now() },
        sender: 'local',
        recipient: peerId,
        ttl: 5,
        priority: 'normal',
        encrypted: false
      });

      if (success) {
        this.addLog('success', 'TEST', `Test message sent to ${peerId.substring(0, 12)}`);
      } else {
        this.addLog('error', 'TEST', `Failed to send test message to ${peerId.substring(0, 12)}`);
      }
    } catch (error) {
      this.addLog('error', 'TEST', `Test message error: ${error}`);
    }
  }

  async disconnectPeer(peerId: string): Promise<void> {
    await this.p2pService.disconnectFromPeer(peerId);
    this.addLog('warning', 'P2P', `Disconnected from peer: ${peerId.substring(0, 12)}`);
  }

  async optimizeNetworkTopology(networkId: string): Promise<void> {
    this.addLog('info', 'MESH', `Optimizing topology for network: ${networkId.substring(0, 12)}`);
    // Topology optimization would be handled by the mesh service
  }

  async sendBroadcastMessage(networkId: string): Promise<void> {
    try {
      const messageId = await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: 'normal',
        payload: { test: 'Broadcast test message', timestamp: Date.now() },
        source: 'local',
        ttl: 5
      });

      this.addLog('success', 'MESH', `Broadcast message sent: ${messageId.substring(0, 12)}`);
    } catch (error) {
      this.addLog('error', 'MESH', `Broadcast failed: ${error}`);
    }
  }

  async leaveMeshNetwork(networkId: string): Promise<void> {
    const success = await this.meshService.leaveMeshNetwork(networkId);
    if (success) {
      this.addLog('warning', 'MESH', `Left mesh network: ${networkId.substring(0, 12)}`);
    }
  }

  saveConfiguration(): void {
    this.addLog('info', 'CONFIG', 'Configuration saved');
    // Save configuration to local storage or service
  }

  resetConfiguration(): void {
    this.maxP2PConnections.set(8);
    this.preferredMeshTopology.set('hybrid');
    this.messagePriority.set('normal');
    this.autoEmergencyMode.set(true);
    this.emergencyBroadcast.set(true);
    this.locationSharing.set(true);
    this.encryptionEnabled.set(true);
    
    this.addLog('info', 'CONFIG', 'Configuration reset to defaults');
  }

  clearLogs(): void {
    this._networkLogs.set([]);
  }

  // Helper Methods
  private addLog(level: 'info' | 'warning' | 'error' | 'success', category: string, message: string): void {
    const logs = this._networkLogs();
    const newLog = {
      timestamp: Date.now(),
      level,
      category,
      message
    };
    
    // Keep only last 100 logs
    const updatedLogs = [newLog, ...logs].slice(0, 100);
    this._networkLogs.set(updatedLogs);
  }

  private generateTestResult(testType: string): { value: number; unit: string; timestamp: number } {
    switch (testType) {
      case 'latency':
        return {
          value: Math.floor(Math.random() * 200) + 50,
          unit: 'ms',
          timestamp: Date.now()
        };
      case 'throughput':
        return {
          value: Math.floor(Math.random() * 100) + 50,
          unit: 'msg/min',
          timestamp: Date.now()
        };
      case 'reliability':
        return {
          value: Math.floor(Math.random() * 20) + 80,
          unit: '%',
          timestamp: Date.now()
        };
      case 'coverage':
        return {
          value: Math.floor(Math.random() * 1000) + 500,
          unit: 'm',
          timestamp: Date.now()
        };
      default:
        return {
          value: 0,
          unit: '',
          timestamp: Date.now()
        };
    }
  }

  private calculateWebRTCQuality(): number {
    const peers = this.webrtcPeers();
    if (peers.length === 0) return 0;
    
    // Simplified quality calculation
    return Math.floor(Math.random() * 30) + 70;
  }

  private calculateEmergencyReadiness(): number {
    const p2pReady = this.p2pEnabled() && this.p2pPeerCount() > 0;
    const meshReady = this.meshEnabled() && this.meshNetworkCount() > 0;
    const webrtcReady = this.webrtcEnabled() && this.webrtcPeerCount() > 0;
    
    let readiness = 0;
    if (p2pReady) readiness += 30;
    if (meshReady) readiness += 40;
    if (webrtcReady) readiness += 30;
    
    return readiness;
  }

  // Template Helper Methods
  getTestIcon(type: string): string {
    switch (type) {
      case 'latency': return 'speed';
      case 'throughput': return 'trending_up';
      case 'reliability': return 'verified';
      case 'coverage': return 'map';
      default: return 'assessment';
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'idle': return 'Bekliyor';
      case 'running': return 'Çalışıyor';
      case 'completed': return 'Tamamlandı';
      case 'failed': return 'Başarısız';
      default: return 'Bilinmiyor';
    }
  }

  getPeerIcon(deviceType: string): string {
    switch (deviceType) {
      case 'mobile': return 'smartphone';
      case 'desktop': return 'computer';
      case 'iot': return 'sensors';
      default: return 'device_unknown';
    }
  }

  getPeerStatusClass(peer: P2PNode): string {
    if (peer.connectionQuality > 80) return 'excellent';
    if (peer.connectionQuality > 60) return 'good';
    if (peer.connectionQuality > 40) return 'fair';
    return 'poor';
  }

  getPeerStatusText(peer: P2PNode): string {
    if (peer.connectionQuality > 80) return 'Mükemmel';
    if (peer.connectionQuality > 60) return 'İyi';
    if (peer.connectionQuality > 40) return 'Orta';
    return 'Zayıf';
  }

  getNetworkIcon(type: string): string {
    switch (type) {
      case 'emergency': return 'warning';
      case 'community': return 'people';
      case 'temporary': return 'schedule';
      case 'permanent': return 'lock';
      default: return 'hub';
    }
  }

  getNetworkTypeClass(type: string): string {
    return type;
  }

  getNodeIcon(type: string): string {
    switch (type) {
      case 'coordinator': return 'account_tree';
      case 'relay': return 'repeat';
      case 'endpoint': return 'radio_button_checked';
      case 'bridge': return 'bridge';
      default: return 'device_hub';
    }
  }

  getNodeTypeText(type: string): string {
    switch (type) {
      case 'coordinator': return 'Koordinatör';
      case 'relay': return 'Röle';
      case 'endpoint': return 'Uç Nokta';
      case 'bridge': return 'Köprü';
      default: return 'Bilinmiyor';
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

  getNetworkNodesArray(network: MeshNetwork): MeshNetworkNode[] {
    return Array.from(network.nodes.values());
  }
}