import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';

interface NetworkNode {
  id: string;
  name: string;
  type: 'mobile' | 'desktop' | 'iot';
  status: 'online' | 'offline' | 'weak';
  signalStrength: number;
  batteryLevel?: number;
  lastSeen: Date;
  distance: number;
}

@Component({
  selector: 'app-network',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
    MatChipsModule
  ],
  template: `
    <div class="network-container">
      <h1>Ağ Durumu</h1>
      
      <!-- Ağ Özeti -->
      <mat-card class="network-summary">
        <mat-card-content>
          <div class="summary-stats">
            <div class="stat-item">
              <mat-icon class="stat-icon">devices</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ nodes.length }}</span>
                <span class="stat-label">Bağlı Cihaz</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">signal_wifi_4_bar</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ getAverageSignal() }}%</span>
                <span class="stat-label">Ortalama Sinyal</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">network_check</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ getNetworkHealth() }}</span>
                <span class="stat-label">Ağ Sağlığı</span>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Cihaz Listesi -->
      <div class="nodes-list">
        <h2>Bağlı Cihazlar</h2>
        
        <mat-card *ngFor="let node of nodes" class="node-card">
          <mat-card-content>
            <div class="node-header">
              <div class="node-info">
                <mat-icon class="node-type-icon" [ngClass]="node.type">
                  {{ getNodeIcon(node.type) }}
                </mat-icon>
                <div class="node-details">
                  <h3>{{ node.name }}</h3>
                  <span class="node-id">ID: {{ node.id }}</span>
                </div>
              </div>
              
              <mat-chip [ngClass]="node.status">
                {{ getStatusText(node.status) }}
              </mat-chip>
            </div>
            
            <div class="node-metrics">
              <div class="metric">
                <span class="metric-label">Sinyal Gücü:</span>
                <mat-progress-bar 
                  mode="determinate" 
                  [value]="node.signalStrength"
                  [ngClass]="getSignalClass(node.signalStrength)">
                </mat-progress-bar>
                <span class="metric-value">{{ node.signalStrength }}%</span>
              </div>
              
              <div class="metric" *ngIf="node.batteryLevel !== undefined">
                <span class="metric-label">Pil Seviyesi:</span>
                <mat-progress-bar 
                  mode="determinate" 
                  [value]="node.batteryLevel"
                  [ngClass]="getBatteryClass(node.batteryLevel)">
                </mat-progress-bar>
                <span class="metric-value">{{ node.batteryLevel }}%</span>
              </div>
              
              <div class="metric">
                <span class="metric-label">Mesafe:</span>
                <span class="metric-value">{{ node.distance }}m</span>
              </div>
              
              <div class="metric">
                <span class="metric-label">Son Görülme:</span>
                <span class="metric-value">{{ node.lastSeen | date:'short':'tr' }}</span>
              </div>
            </div>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Ağ Haritası Placeholder -->
      <mat-card class="network-map">
        <mat-card-header>
          <mat-card-title>Ağ Topolojisi</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="map-placeholder">
            <mat-icon>map</mat-icon>
            <p>Ağ haritası yakında eklenecek</p>
            <button mat-raised-button color="primary">
              Haritayı Görüntüle
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .network-container {
      max-width: 1000px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
    }

    .network-summary {
      margin-bottom: 24px;
      background: linear-gradient(135deg, #2196f3, #21cbf3);
      color: white;
    }

    .summary-stats {
      display: flex;
      justify-content: space-around;
      align-items: center;
    }

    .stat-item {
      display: flex;
      align-items: center;
      text-align: center;
    }

    .stat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      margin-right: 12px;
    }

    .stat-info {
      display: flex;
      flex-direction: column;
    }

    .stat-value {
      font-size: 24px;
      font-weight: bold;
    }

    .stat-label {
      font-size: 12px;
      opacity: 0.8;
    }

    .nodes-list h2 {
      margin: 24px 0 16px 0;
      color: #333;
    }

    .node-card {
      margin-bottom: 16px;
      transition: transform 0.2s ease;
    }

    .node-card:hover {
      transform: translateY(-2px);
    }

    .node-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .node-info {
      display: flex;
      align-items: center;
    }

    .node-type-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      margin-right: 12px;
    }

    .node-type-icon.mobile {
      color: #4caf50;
    }

    .node-type-icon.desktop {
      color: #2196f3;
    }

    .node-type-icon.iot {
      color: #ff9800;
    }

    .node-details h3 {
      margin: 0 0 4px 0;
      font-size: 18px;
    }

    .node-id {
      font-size: 12px;
      color: #666;
    }

    mat-chip.online {
      background-color: #4caf50;
      color: white;
    }

    mat-chip.offline {
      background-color: #f44336;
      color: white;
    }

    mat-chip.weak {
      background-color: #ff9800;
      color: white;
    }

    .node-metrics {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    .metric {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .metric-label {
      font-size: 14px;
      color: #666;
      min-width: 80px;
    }

    .metric-value {
      font-size: 14px;
      font-weight: bold;
      min-width: 40px;
    }

    mat-progress-bar {
      flex: 1;
      height: 8px;
      border-radius: 4px;
    }

    mat-progress-bar.good {
      --mdc-linear-progress-active-indicator-color: #4caf50;
    }

    mat-progress-bar.medium {
      --mdc-linear-progress-active-indicator-color: #ff9800;
    }

    mat-progress-bar.poor {
      --mdc-linear-progress-active-indicator-color: #f44336;
    }

    .network-map {
      margin-top: 24px;
    }

    .map-placeholder {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .map-placeholder mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
    }

    @media (max-width: 768px) {
      .summary-stats {
        flex-direction: column;
        gap: 16px;
      }
      
      .node-metrics {
        grid-template-columns: 1fr;
      }
      
      .node-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
      }
    }
  `]
})
export class NetworkComponent {
  nodes: NetworkNode[] = [
    {
      id: 'EMN-001',
      name: 'Ahmet\'in Telefonu',
      type: 'mobile',
      status: 'online',
      signalStrength: 85,
      batteryLevel: 67,
      lastSeen: new Date(Date.now() - 30000),
      distance: 150
    },
    {
      id: 'EMN-002',
      name: 'Fatma\'nın Tableti',
      type: 'mobile',
      status: 'online',
      signalStrength: 92,
      batteryLevel: 89,
      lastSeen: new Date(Date.now() - 45000),
      distance: 89
    },
    {
      id: 'EMN-003',
      name: 'Ofis Bilgisayarı',
      type: 'desktop',
      status: 'online',
      signalStrength: 78,
      lastSeen: new Date(Date.now() - 60000),
      distance: 245
    },
    {
      id: 'EMN-004',
      name: 'Mehmet\'in Telefonu',
      type: 'mobile',
      status: 'weak',
      signalStrength: 34,
      batteryLevel: 23,
      lastSeen: new Date(Date.now() - 120000),
      distance: 456
    },
    {
      id: 'EMN-005',
      name: 'IoT Sensör',
      type: 'iot',
      status: 'online',
      signalStrength: 56,
      batteryLevel: 78,
      lastSeen: new Date(Date.now() - 90000),
      distance: 123
    }
  ];

  getNodeIcon(type: string): string {
    switch (type) {
      case 'mobile': return 'smartphone';
      case 'desktop': return 'computer';
      case 'iot': return 'sensors';
      default: return 'device_unknown';
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'online': return 'Çevrimiçi';
      case 'offline': return 'Çevrimdışı';
      case 'weak': return 'Zayıf Bağlantı';
      default: return 'Bilinmiyor';
    }
  }

  getSignalClass(strength: number): string {
    if (strength >= 70) return 'good';
    if (strength >= 40) return 'medium';
    return 'poor';
  }

  getBatteryClass(level: number): string {
    if (level >= 50) return 'good';
    if (level >= 20) return 'medium';
    return 'poor';
  }

  getAverageSignal(): number {
    const onlineNodes = this.nodes.filter(n => n.status === 'online');
    if (onlineNodes.length === 0) return 0;
    
    const total = onlineNodes.reduce((sum, node) => sum + node.signalStrength, 0);
    return Math.round(total / onlineNodes.length);
  }

  getNetworkHealth(): string {
    const onlineCount = this.nodes.filter(n => n.status === 'online').length;
    const totalCount = this.nodes.length;
    const healthPercentage = (onlineCount / totalCount) * 100;
    
    if (healthPercentage >= 80) return 'Mükemmel';
    if (healthPercentage >= 60) return 'İyi';
    if (healthPercentage >= 40) return 'Orta';
    return 'Zayıf';
  }
}