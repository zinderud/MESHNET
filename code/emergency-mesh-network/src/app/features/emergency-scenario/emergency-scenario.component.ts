import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatTabsModule } from '@angular/material/tabs';
import { MatExpansionModule } from '@angular/material/expansion';
import { Subscription } from 'rxjs';

import { EmergencyMeshCoordinatorService, CityWideEmergencyScenario, EmergencyNetwork } from '../../core/services/emergency-mesh-coordinator.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-emergency-scenario',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
    MatChipsModule,
    MatTabsModule,
    MatExpansionModule
  ],
  template: `
    <div class="scenario-container">
      <h1>🚨 Acil Durum Senaryo Simülasyonu</h1>
      
      <!-- Senaryo Kontrol Paneli -->
      <mat-card class="control-panel">
        <mat-card-header>
          <mat-card-title>Senaryo Kontrolü</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="scenario-buttons">
            <button mat-raised-button color="warn" 
                    (click)="startIstanbulEarthquakeScenario()"
                    [disabled]="isScenarioActive()">
              <mat-icon>warning</mat-icon>
              İstanbul 7.2 Deprem Simülasyonu Başlat
            </button>
            
            <button mat-raised-button color="accent" 
                    (click)="startRealTimeProgression()"
                    [disabled]="!isScenarioActive()">
              <mat-icon>play_arrow</mat-icon>
              Gerçek Zamanlı İlerleme
            </button>
            
            <button mat-button 
                    (click)="stopScenario()"
                    [disabled]="!isScenarioActive()">
              <mat-icon>stop</mat-icon>
              Senaryoyu Durdur
            </button>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Aktif Senaryo Bilgileri -->
      @if (currentScenario(); as scenario) {
        <mat-card class="scenario-info">
          <mat-card-header>
            <mat-icon mat-card-avatar class="disaster-icon">{{ getDisasterIcon(scenario.disasterType) }}</mat-icon>
            <mat-card-title>{{ scenario.cityName }} - {{ getDisasterName(scenario.disasterType) }}</mat-card-title>
            <mat-card-subtitle>Senaryo ID: {{ scenario.scenarioId }}</mat-card-subtitle>
          </mat-card-header>
          
          <mat-card-content>
            <div class="scenario-metrics">
              <div class="metric-grid">
                <div class="metric-item">
                  <mat-icon>cell_tower</mat-icon>
                  <div class="metric-info">
                    <span class="metric-value">{{ scenario.infrastructureStatus.cellularTowers }}%</span>
                    <span class="metric-label">Baz İstasyonları</span>
                  </div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="scenario.infrastructureStatus.cellularTowers"
                                    [color]="getInfrastructureColor(scenario.infrastructureStatus.cellularTowers)">
                  </mat-progress-bar>
                </div>

                <div class="metric-item">
                  <mat-icon>wifi</mat-icon>
                  <div class="metric-info">
                    <span class="metric-value">{{ scenario.infrastructureStatus.internetBackbone }}%</span>
                    <span class="metric-label">İnternet Altyapısı</span>
                  </div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="scenario.infrastructureStatus.internetBackbone"
                                    [color]="getInfrastructureColor(scenario.infrastructureStatus.internetBackbone)">
                  </mat-progress-bar>
                </div>

                <div class="metric-item">
                  <mat-icon>power</mat-icon>
                  <div class="metric-info">
                    <span class="metric-value">{{ scenario.infrastructureStatus.powerGrid }}%</span>
                    <span class="metric-label">Elektrik Şebekesi</span>
                  </div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="scenario.infrastructureStatus.powerGrid"
                                    [color]="getInfrastructureColor(scenario.infrastructureStatus.powerGrid)">
                  </mat-progress-bar>
                </div>

                <div class="metric-item">
                  <mat-icon>local_hospital</mat-icon>
                  <div class="metric-info">
                    <span class="metric-value">{{ scenario.infrastructureStatus.emergencyServices }}%</span>
                    <span class="metric-label">Acil Servisler</span>
                  </div>
                  <mat-progress-bar mode="determinate" 
                                    [value]="scenario.infrastructureStatus.emergencyServices"
                                    [color]="getInfrastructureColor(scenario.infrastructureStatus.emergencyServices)">
                  </mat-progress-bar>
                </div>
              </div>

              <div class="scenario-stats">
                <div class="stat-card">
                  <mat-icon>people</mat-icon>
                  <div class="stat-info">
                    <span class="stat-value">{{ formatNumber(scenario.estimatedDevices) }}</span>
                    <span class="stat-label">Tahmini Cihaz Sayısı</span>
                  </div>
                </div>

                <div class="stat-card">
                  <mat-icon>schedule</mat-icon>
                  <div class="stat-info">
                    <span class="stat-value">{{ formatTime(scenario.timeElapsed) }}</span>
                    <span class="stat-label">Geçen Süre</span>
                  </div>
                </div>

                <div class="stat-card">
                  <mat-icon>location_on</mat-icon>
                  <div class="stat-info">
                    <span class="stat-value">{{ scenario.affectedArea.radius / 1000 }}km</span>
                    <span class="stat-label">Etki Alanı Yarıçapı</span>
                  </div>
                </div>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      }

      <!-- Mesh Network Durumu -->
      <mat-card class="network-status">
        <mat-card-header>
          <mat-card-title>Mesh Network Durumu</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <mat-tab-group>
            <!-- Genel Durum -->
            <mat-tab label="Genel Durum">
              <div class="tab-content">
                <div class="network-overview">
                  @if (communicationCapacity(); as capacity) {
                    <div class="capacity-metrics">
                      <div class="capacity-item">
                        <mat-icon>map</mat-icon>
                        <div class="capacity-info">
                          <span class="capacity-value">{{ capacity.estimatedCoverage }} km²</span>
                          <span class="capacity-label">Kapsama Alanı</span>
                        </div>
                      </div>

                      <div class="capacity-item">
                        <mat-icon>people</mat-icon>
                        <div class="capacity-info">
                          <span class="capacity-value">{{ formatNumber(capacity.reachablePopulation) }}</span>
                          <span class="capacity-label">Ulaşılabilir Nüfus</span>
                        </div>
                      </div>

                      <div class="capacity-item">
                        <mat-icon>message</mat-icon>
                        <div class="capacity-info">
                          <span class="capacity-value">{{ capacity.messageCapacity }}/dk</span>
                          <span class="capacity-label">Mesaj Kapasitesi</span>
                        </div>
                      </div>

                      <div class="capacity-item">
                        <mat-icon>security</mat-icon>
                        <div class="capacity-info">
                          <span class="capacity-value">{{ capacity.networkResilience }}%</span>
                          <span class="capacity-label">Ağ Dayanıklılığı</span>
                        </div>
                        <mat-progress-bar mode="determinate" 
                                          [value]="capacity.networkResilience"
                                          [color]="getResilienceColor(capacity.networkResilience)">
                        </mat-progress-bar>
                      </div>

                      <div class="capacity-item evacuation-status" 
                           [ngClass]="{'available': capacity.evacuationCoordination}">
                        <mat-icon>{{ capacity.evacuationCoordination ? 'check_circle' : 'cancel' }}</mat-icon>
                        <div class="capacity-info">
                          <span class="capacity-value">
                            {{ capacity.evacuationCoordination ? 'Mevcut' : 'Mevcut Değil' }}
                          </span>
                          <span class="capacity-label">Tahliye Koordinasyonu</span>
                        </div>
                      </div>
                    </div>
                  }
                </div>
              </div>
            </mat-tab>

            <!-- Aktif Ağlar -->
            <mat-tab label="Aktif Ağlar">
              <div class="tab-content">
                @for (network of activeNetworks(); track network.id) {
                  <mat-expansion-panel class="network-panel">
                    <mat-expansion-panel-header>
                      <mat-panel-title>
                        <mat-icon [ngClass]="getNetworkHealthClass(network.networkHealth)">
                          {{ getNetworkIcon(network.emergencyLevel) }}
                        </mat-icon>
                        {{ network.name }}
                      </mat-panel-title>
                      <mat-panel-description>
                        {{ network.nodeCount }} node - {{ network.networkHealth }}% sağlık
                      </mat-panel-description>
                    </mat-expansion-panel-header>

                    <div class="network-details">
                      <div class="network-info-grid">
                        <div class="info-item">
                          <span class="info-label">Merkez Konum:</span>
                          <span class="info-value">
                            {{ network.centerLocation.latitude.toFixed(4) }}, 
                            {{ network.centerLocation.longitude.toFixed(4) }}
                          </span>
                        </div>

                        <div class="info-item">
                          <span class="info-label">Kapsama Yarıçapı:</span>
                          <span class="info-value">{{ network.radius }}m</span>
                        </div>

                        <div class="info-item">
                          <span class="info-label">Kapsama Alanı:</span>
                          <span class="info-value">{{ (network.coverageArea / 1000000).toFixed(2) }} km²</span>
                        </div>

                        <div class="info-item">
                          <span class="info-label">Mesaj Trafiği:</span>
                          <span class="info-value">{{ network.messagesThroughput }}/dk</span>
                        </div>

                        <div class="info-item">
                          <span class="info-label">Oluşturulma:</span>
                          <span class="info-value">{{ network.createdAt | date:'short':'tr' }}</span>
                        </div>

                        <div class="info-item">
                          <span class="info-label">Son Aktivite:</span>
                          <span class="info-value">{{ network.lastActivity | date:'short':'tr' }}</span>
                        </div>
                      </div>

                      <div class="network-nodes">
                        <h4>Aktif Node'lar ({{ network.activeNodes.length }})</h4>
                        <div class="nodes-grid">
                          @for (node of network.activeNodes; track node.id) {
                            <div class="node-card" [ngClass]="node.emergencyRole">
                              <div class="node-header">
                                <mat-icon>{{ getNodeIcon(node.deviceType) }}</mat-icon>
                                <span class="node-role">{{ getRoleText(node.emergencyRole) }}</span>
                              </div>
                              <div class="node-metrics">
                                <div class="node-metric">
                                  <mat-icon>battery_full</mat-icon>
                                  <span>{{ node.batteryLevel }}%</span>
                                </div>
                                <div class="node-metric">
                                  <mat-icon>signal_cellular_4_bar</mat-icon>
                                  <span>{{ node.signalStrength }}%</span>
                                </div>
                                <div class="node-metric">
                                  <mat-icon>device_hub</mat-icon>
                                  <span>{{ node.connectedPeers.length }}</span>
                                </div>
                              </div>
                            </div>
                          }
                        </div>
                      </div>
                    </div>
                  </mat-expansion-panel>
                } @empty {
                  <div class="empty-networks">
                    <mat-icon>network_wifi_off</mat-icon>
                    <h3>Aktif Ağ Bulunamadı</h3>
                    <p>Mesh network oluşturmak için senaryo başlatın.</p>
                  </div>
                }
              </div>
            </mat-tab>

            <!-- Yerel Node -->
            <mat-tab label="Yerel Node">
              <div class="tab-content">
                @if (localNode(); as node) {
                  <div class="local-node-info">
                    <div class="node-status">
                      <mat-icon class="node-status-icon" [ngClass]="node.emergencyRole">
                        {{ getNodeIcon(node.deviceType) }}
                      </mat-icon>
                      <div class="node-basic-info">
                        <h3>{{ getRoleText(node.emergencyRole) }}</h3>
                        <p>{{ node.deviceType.toUpperCase() }} - {{ node.id }}</p>
                        @if (isEmergencyCoordinator()) {
                          <mat-chip color="warn">Koordinatör</mat-chip>
                        }
                      </div>
                    </div>

                    <div class="node-capabilities">
                      <h4>Yetenekler</h4>
                      <div class="capabilities-list">
                        @for (capability of node.capabilities; track capability) {
                          <mat-chip>{{ getCapabilityText(capability) }}</mat-chip>
                        }
                      </div>
                    </div>

                    <div class="node-connections">
                      <h4>Bağlantılar ({{ node.connectedPeers.length }})</h4>
                      @if (node.connectedPeers.length > 0) {
                        <div class="connections-list">
                          @for (peerId of node.connectedPeers; track peerId) {
                            <div class="connection-item">
                              <mat-icon>link</mat-icon>
                              <span>{{ peerId.substring(0, 12) }}...</span>
                            </div>
                          }
                        </div>
                      } @else {
                        <p>Henüz bağlantı yok</p>
                      }
                    </div>

                    @if (node.location) {
                      <div class="node-location">
                        <h4>Konum</h4>
                        <div class="location-info">
                          <mat-icon>location_on</mat-icon>
                          <span>
                            {{ node.location.latitude.toFixed(6) }}, 
                            {{ node.location.longitude.toFixed(6) }}
                          </span>
                          <span class="accuracy">(±{{ node.location.accuracy }}m)</span>
                        </div>
                      </div>
                    }
                  </div>
                } @else {
                  <div class="no-local-node">
                    <mat-icon>device_unknown</mat-icon>
                    <h3>Yerel Node Bulunamadı</h3>
                    <p>Acil durum mesh network'üne katılmak için senaryo başlatın.</p>
                  </div>
                }
              </div>
            </mat-tab>
          </mat-tab-group>
        </mat-card-content>
      </mat-card>

      <!-- Gerçek Zamanlı Loglar -->
      @if (isScenarioActive()) {
        <mat-card class="real-time-logs">
          <mat-card-header>
            <mat-card-title>Gerçek Zamanlı Sistem Logları</mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <div class="logs-container">
              @for (log of recentLogs(); track log.timestamp) {
                <div class="log-entry" [ngClass]="log.level">
                  <span class="log-time">{{ log.timestamp | date:'HH:mm:ss' }}</span>
                  <mat-icon class="log-icon">{{ getLogIcon(log.level) }}</mat-icon>
                  <span class="log-message">{{ log.message }}</span>
                </div>
              }
            </div>
          </mat-card-content>
        </mat-card>
      }
    </div>
  `,
  styles: [`
    .scenario-container {
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
      background: linear-gradient(135deg, #ff5722, #f44336);
      color: white;
    }

    .scenario-buttons {
      display: flex;
      gap: 16px;
      flex-wrap: wrap;
    }

    .scenario-buttons button {
      min-width: 200px;
    }

    .scenario-info {
      margin-bottom: 24px;
    }

    .disaster-icon {
      background: #ff5722;
      color: white;
      font-size: 32px;
    }

    .scenario-metrics {
      margin-top: 16px;
    }

    .metric-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .metric-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: #f5f5f5;
      border-radius: 8px;
    }

    .metric-item mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
      color: #666;
    }

    .metric-info {
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .metric-value {
      font-size: 18px;
      font-weight: bold;
      color: #333;
    }

    .metric-label {
      font-size: 12px;
      color: #666;
    }

    .metric-item mat-progress-bar {
      width: 100%;
      margin-top: 8px;
    }

    .scenario-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
    }

    .stat-card {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: linear-gradient(135deg, #2196f3, #21cbf3);
      color: white;
      border-radius: 8px;
    }

    .stat-card mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .stat-info {
      display: flex;
      flex-direction: column;
    }

    .stat-value {
      font-size: 20px;
      font-weight: bold;
    }

    .stat-label {
      font-size: 12px;
      opacity: 0.9;
    }

    .network-status {
      margin-bottom: 24px;
    }

    .tab-content {
      padding: 16px 0;
    }

    .capacity-metrics {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
    }

    .capacity-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: #f8f9fa;
      border-radius: 8px;
      border-left: 4px solid #2196f3;
    }

    .capacity-item.evacuation-status.available {
      border-left-color: #4caf50;
      background: #e8f5e8;
    }

    .capacity-item.evacuation-status:not(.available) {
      border-left-color: #f44336;
      background: #ffebee;
    }

    .capacity-item mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
      color: #2196f3;
    }

    .capacity-item.evacuation-status.available mat-icon {
      color: #4caf50;
    }

    .capacity-item.evacuation-status:not(.available) mat-icon {
      color: #f44336;
    }

    .capacity-info {
      flex: 1;
      display: flex;
      flex-direction: column;
    }

    .capacity-value {
      font-size: 18px;
      font-weight: bold;
      color: #333;
    }

    .capacity-label {
      font-size: 12px;
      color: #666;
    }

    .network-panel {
      margin-bottom: 16px;
    }

    .network-panel mat-icon {
      margin-right: 8px;
    }

    .network-panel mat-icon.excellent {
      color: #4caf50;
    }

    .network-panel mat-icon.good {
      color: #8bc34a;
    }

    .network-panel mat-icon.fair {
      color: #ff9800;
    }

    .network-panel mat-icon.poor {
      color: #f44336;
    }

    .network-details {
      padding: 16px 0;
    }

    .network-info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
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
    }

    .node-card {
      padding: 12px;
      border: 1px solid #ddd;
      border-radius: 8px;
      background: white;
    }

    .node-card.coordinator {
      border-color: #f44336;
      background: #ffebee;
    }

    .node-card.relay {
      border-color: #ff9800;
      background: #fff3e0;
    }

    .node-card.bridge {
      border-color: #2196f3;
      background: #e3f2fd;
    }

    .node-header {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 8px;
    }

    .node-role {
      font-weight: 500;
      font-size: 12px;
    }

    .node-metrics {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .node-metric {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
    }

    .node-metric mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .empty-networks,
    .no-local-node {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .empty-networks mat-icon,
    .no-local-node mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    .local-node-info {
      max-width: 800px;
    }

    .node-status {
      display: flex;
      align-items: center;
      gap: 16px;
      margin-bottom: 24px;
      padding: 16px;
      background: #f5f5f5;
      border-radius: 8px;
    }

    .node-status-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }

    .node-status-icon.coordinator {
      color: #f44336;
    }

    .node-status-icon.relay {
      color: #ff9800;
    }

    .node-status-icon.bridge {
      color: #2196f3;
    }

    .node-status-icon.endpoint {
      color: #4caf50;
    }

    .node-basic-info h3 {
      margin: 0 0 4px 0;
      color: #333;
    }

    .node-basic-info p {
      margin: 0 0 8px 0;
      color: #666;
      font-size: 14px;
    }

    .capabilities-list,
    .connections-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 8px;
    }

    .connection-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      background: #f0f0f0;
      border-radius: 16px;
      font-size: 14px;
    }

    .connection-item mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .location-info {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 8px;
    }

    .accuracy {
      color: #666;
      font-size: 12px;
    }

    .real-time-logs {
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
      margin-bottom: 8px;
      padding: 4px 0;
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
      font-size: 12px;
      color: #888;
      min-width: 60px;
    }

    .log-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .log-message {
      font-size: 14px;
    }

    @media (max-width: 768px) {
      .scenario-container {
        padding: 8px;
      }
      
      .scenario-buttons {
        flex-direction: column;
      }
      
      .scenario-buttons button {
        width: 100%;
      }
      
      .metric-grid,
      .capacity-metrics {
        grid-template-columns: 1fr;
      }
      
      .nodes-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class EmergencyScenarioComponent implements OnInit, OnDestroy {
  private emergencyCoordinator = inject(EmergencyMeshCoordinatorService);
  private analyticsService = inject(AnalyticsService);

  // Reactive state from coordinator service
  currentScenario = this.emergencyCoordinator.currentScenario;
  localNode = this.emergencyCoordinator.localNode;
  activeNetworks = this.emergencyCoordinator.activeNetworks;
  isEmergencyCoordinator = this.emergencyCoordinator.isEmergencyCoordinator;

  // Local component state
  private _recentLogs = signal<Array<{
    timestamp: number;
    level: 'info' | 'warning' | 'error' | 'success';
    message: string;
  }>>([]);

  recentLogs = this._recentLogs.asReadonly();

  // Computed properties
  isScenarioActive = computed(() => this.currentScenario() !== null);
  
  communicationCapacity = computed(() => {
    if (!this.isScenarioActive()) return null;
    return this.emergencyCoordinator.calculateCityWideCommunicationCapacity();
  });

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.setupEventListeners();
    this.analyticsService.trackPageView('emergency_scenario');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private setupEventListeners(): void {
    // Listen for network formation events
    this.subscriptions.add(
      this.emergencyCoordinator.onEmergencyNetworkFormed$.subscribe(network => {
        this.addLog('success', `Acil durum ağı oluşturuldu: ${network.name} (${network.nodeCount} node)`);
      })
    );

    // Listen for city-wide coordination
    this.subscriptions.add(
      this.emergencyCoordinator.onCityWideCoordinationEstablished$.subscribe(established => {
        if (established) {
          this.addLog('success', 'Şehir çapında koordinasyon kuruldu');
        }
      })
    );

    // Listen for evacuation coordination
    this.subscriptions.add(
      this.emergencyCoordinator.onMassEvacuationCoordinated$.subscribe(message => {
        this.addLog('warning', `Toplu tahliye koordinasyonu: ${message}`);
      })
    );
  }

  async startIstanbulEarthquakeScenario(): Promise<void> {
    this.addLog('warning', 'İstanbul 7.2 deprem senaryosu başlatılıyor...');
    
    try {
      await this.emergencyCoordinator.simulateIstanbulEarthquakeScenario();
      this.addLog('success', 'Senaryo başarıyla başlatıldı');
      this.addLog('info', 'Otomatik mesh network oluşturma başladı');
      
      this.analyticsService.trackUserAction('scenario', 'istanbul_earthquake_started');
    } catch (error) {
      this.addLog('error', `Senaryo başlatma hatası: ${error}`);
      this.analyticsService.trackError('scenario', 'Failed to start scenario', { error });
    }
  }

  async startRealTimeProgression(): Promise<void> {
    this.addLog('info', 'Gerçek zamanlı senaryo ilerlemesi başlatılıyor...');
    
    try {
      await this.emergencyCoordinator.simulateRealTimeEmergencyProgression();
      this.addLog('success', 'Gerçek zamanlı simülasyon aktif');
      
      this.analyticsService.trackUserAction('scenario', 'real_time_progression_started');
    } catch (error) {
      this.addLog('error', `Gerçek zamanlı simülasyon hatası: ${error}`);
    }
  }

  stopScenario(): void {
    this.addLog('warning', 'Senaryo durduruluyor...');
    // Implementation for stopping scenario
    this.addLog('info', 'Senaryo durduruldu');
    
    this.analyticsService.trackUserAction('scenario', 'stopped');
  }

  private addLog(level: 'info' | 'warning' | 'error' | 'success', message: string): void {
    const logs = this._recentLogs();
    const newLog = {
      timestamp: Date.now(),
      level,
      message
    };
    
    // Keep only last 50 logs
    const updatedLogs = [newLog, ...logs].slice(0, 50);
    this._recentLogs.set(updatedLogs);
  }

  // Helper methods for template
  getDisasterIcon(type: string): string {
    switch (type) {
      case 'earthquake': return 'terrain';
      case 'flood': return 'waves';
      case 'fire': return 'local_fire_department';
      case 'blackout': return 'power_off';
      case 'cyberattack': return 'security';
      default: return 'warning';
    }
  }

  getDisasterName(type: string): string {
    switch (type) {
      case 'earthquake': return 'Deprem';
      case 'flood': return 'Sel';
      case 'fire': return 'Yangın';
      case 'blackout': return 'Elektrik Kesintisi';
      case 'cyberattack': return 'Siber Saldırı';
      default: return 'Acil Durum';
    }
  }

  getInfrastructureColor(percentage: number): 'primary' | 'accent' | 'warn' {
    if (percentage >= 60) return 'primary';
    if (percentage >= 30) return 'accent';
    return 'warn';
  }

  getResilienceColor(resilience: number): 'primary' | 'accent' | 'warn' {
    if (resilience >= 70) return 'primary';
    if (resilience >= 40) return 'accent';
    return 'warn';
  }

  getNetworkHealthClass(health: number): string {
    if (health >= 80) return 'excellent';
    if (health >= 60) return 'good';
    if (health >= 40) return 'fair';
    return 'poor';
  }

  getNetworkIcon(level: string): string {
    switch (level) {
      case 'green': return 'check_circle';
      case 'yellow': return 'warning';
      case 'orange': return 'error';
      case 'red': return 'dangerous';
      default: return 'help';
    }
  }

  getNodeIcon(deviceType: string): string {
    switch (deviceType) {
      case 'smartphone': return 'smartphone';
      case 'tablet': return 'tablet';
      case 'laptop': return 'laptop';
      case 'iot': return 'sensors';
      default: return 'device_unknown';
    }
  }

  getRoleText(role: string): string {
    switch (role) {
      case 'coordinator': return 'Koordinatör';
      case 'relay': return 'Röle';
      case 'bridge': return 'Köprü';
      case 'endpoint': return 'Uç Nokta';
      default: return 'Bilinmiyor';
    }
  }

  getCapabilityText(capability: string): string {
    switch (capability) {
      case 'emergency-mesh': return 'Acil Durum Mesh';
      case 'location-sharing': return 'Konum Paylaşımı';
      case 'emergency-messaging': return 'Acil Mesajlaşma';
      case 'relay-capable': return 'Röle Yetenekli';
      case 'encryption-support': return 'Şifreleme Desteği';
      default: return capability;
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

  formatNumber(num: number): string {
    return new Intl.NumberFormat('tr-TR').format(num);
  }

  formatTime(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours}s ${mins}dk`;
  }
}