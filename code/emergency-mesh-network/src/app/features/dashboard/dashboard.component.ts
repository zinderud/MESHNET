import { Component, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatGridListModule } from '@angular/material/grid-list';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { RouterModule } from '@angular/router';

interface StatusCard {
  id: string;
  title: string;
  icon: string;
  status: 'online' | 'offline' | 'warning' | 'error';
  value: string;
  description: string;
  action?: string;
  route?: string;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatGridListModule,
    MatProgressBarModule,
    RouterModule
  ],
  template: `
    <div class="dashboard-container">
      <h1>Acil Durum Kontrol Paneli</h1>
      
      <!-- Emergency Button with Angular 20 Control Flow -->
      <mat-card class="emergency-card">
        <mat-card-content>
          <div class="emergency-button-container">
            <button mat-fab color="warn" 
                    class="emergency-button" 
                    routerLink="/emergency"
                    [class.emergency-pulse]="!isEmergencyActive()">
              @if (isEmergencyActive()) {
                <mat-icon>warning</mat-icon>
              } @else {
                <mat-icon>emergency</mat-icon>
              }
            </button>
            
            @if (isEmergencyActive()) {
              <h2>ACİL DURUM AKTİF</h2>
              <p>Acil durum modu şu anda etkin</p>
              <button mat-raised-button color="accent" routerLink="/emergency">
                Acil Durum Yönetimi
              </button>
            } @else {
              <h2>ACİL DURUM</h2>
              <p>Acil durumda bu butona basın</p>
            }
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Status Cards with Angular 20 Control Flow -->
      <mat-grid-list [cols]="getGridCols()" rowHeight="200px" gutterSize="16px" class="status-grid">
        @for (card of statusCards(); track card.id) {
          <mat-grid-tile>
            <mat-card class="status-card" [ngClass]="card.status">
              <mat-card-header>
                <mat-icon mat-card-avatar [ngClass]="card.status">{{ card.icon }}</mat-icon>
                <mat-card-title>{{ card.title }}</mat-card-title>
              </mat-card-header>
              
              <mat-card-content>
                <div class="status-indicator" [ngClass]="card.status">
                  <span class="status-dot"></span>
                  <span class="status-value">{{ card.value }}</span>
                </div>
                <p class="status-description">{{ card.description }}</p>
                
                <!-- Progress bars for certain cards -->
                @if (card.id === 'battery') {
                  <mat-progress-bar 
                    mode="determinate" 
                    [value]="batteryLevel()"
                    [color]="getBatteryColor()">
                  </mat-progress-bar>
                }
                
                @if (card.id === 'network') {
                  <mat-progress-bar 
                    mode="determinate" 
                    [value]="networkStrength()"
                    color="primary">
                  </mat-progress-bar>
                }
              </mat-card-content>
              
              <mat-card-actions>
                @if (card.action && card.route) {
                  <button mat-button [routerLink]="card.route">{{ card.action }}</button>
                } @else if (card.action) {
                  <button mat-button (click)="handleCardAction(card.id)">{{ card.action }}</button>
                }
              </mat-card-actions>
            </mat-card>
          </mat-grid-tile>
        }
      </mat-grid-list>

      <!-- Quick Actions -->
      <mat-card class="quick-actions-card">
        <mat-card-header>
          <mat-card-title>Hızlı İşlemler</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="quick-actions">
            <button mat-raised-button color="primary" routerLink="/messages">
              <mat-icon>message</mat-icon>
              Mesaj Gönder
            </button>
            
            <button mat-raised-button color="accent" (click)="shareLocation()">
              <mat-icon>location_on</mat-icon>
              Konum Paylaş
            </button>
            
            <button mat-raised-button (click)="testNetwork()">
              <mat-icon>network_check</mat-icon>
              Ağ Testi
            </button>
            
            <button mat-raised-button routerLink="/settings">
              <mat-icon>settings</mat-icon>
              Ayarlar
            </button>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- System Status -->
      <mat-card class="system-status-card">
        <mat-card-header>
          <mat-card-title>Sistem Durumu</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="system-metrics">
            @for (metric of systemMetrics(); track metric.name) {
              <div class="metric-item">
                <span class="metric-label">{{ metric.label }}:</span>
                <span class="metric-value" [ngClass]="metric.status">{{ metric.value }}</span>
              </div>
            }
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .dashboard-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
      font-weight: 300;
    }

    .emergency-card {
      margin-bottom: 24px;
      background: linear-gradient(135deg, #ff5722, #f44336);
      color: white;
      box-shadow: 0 8px 32px rgba(244, 67, 54, 0.3);
    }

    .emergency-button-container {
      text-align: center;
      padding: 24px;
    }

    .emergency-button {
      width: 120px;
      height: 120px;
      margin-bottom: 16px;
      transform: scale(1);
      transition: transform 0.2s ease;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }

    .emergency-button:hover {
      transform: scale(1.05);
    }

    .emergency-button.emergency-pulse {
      animation: emergency-pulse 2s infinite;
    }

    .emergency-button mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
    }

    .emergency-card h2 {
      margin: 16px 0 8px 0;
      font-size: 24px;
      font-weight: bold;
    }

    .emergency-card p {
      margin: 0 0 16px 0;
      opacity: 0.9;
    }

    .status-grid {
      margin: 24px 0;
    }

    .status-card {
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
      transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .status-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 16px rgba(0,0,0,0.15);
    }

    .status-card.online {
      border-left: 4px solid #4caf50;
    }

    .status-card.offline {
      border-left: 4px solid #f44336;
    }

    .status-card.warning {
      border-left: 4px solid #ff9800;
    }

    .status-card.error {
      border-left: 4px solid #f44336;
    }

    .status-card mat-card-content {
      flex: 1;
      padding: 16px;
    }

    .status-indicator {
      display: flex;
      align-items: center;
      margin-bottom: 8px;
    }

    .status-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      margin-right: 8px;
    }

    .status-indicator.online .status-dot {
      background-color: #4caf50;
      box-shadow: 0 0 8px rgba(76, 175, 80, 0.6);
    }

    .status-indicator.offline .status-dot {
      background-color: #f44336;
    }

    .status-indicator.warning .status-dot {
      background-color: #ff9800;
    }

    .status-indicator.error .status-dot {
      background-color: #f44336;
    }

    .status-value {
      font-weight: bold;
      font-size: 18px;
    }

    .status-description {
      color: #666;
      font-size: 14px;
      margin: 8px 0;
    }

    .quick-actions-card {
      margin: 24px 0;
    }

    .quick-actions {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
    }

    .quick-actions button {
      height: 56px;
      font-size: 16px;
    }

    .quick-actions button mat-icon {
      margin-right: 8px;
    }

    .system-status-card {
      margin-top: 24px;
    }

    .system-metrics {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 16px;
    }

    .metric-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px;
      background: #f5f5f5;
      border-radius: 8px;
    }

    .metric-label {
      font-weight: 500;
      color: #666;
    }

    .metric-value {
      font-weight: bold;
    }

    .metric-value.good {
      color: #4caf50;
    }

    .metric-value.warning {
      color: #ff9800;
    }

    .metric-value.error {
      color: #f44336;
    }

    @keyframes emergency-pulse {
      0% {
        box-shadow: 0 8px 32px rgba(244, 67, 54, 0.4);
        transform: scale(1);
      }
      50% {
        box-shadow: 0 12px 40px rgba(244, 67, 54, 0.8);
        transform: scale(1.02);
      }
      100% {
        box-shadow: 0 8px 32px rgba(244, 67, 54, 0.4);
        transform: scale(1);
      }
    }

    @media (max-width: 768px) {
      .dashboard-container {
        padding: 8px;
      }
      
      .emergency-button {
        width: 100px;
        height: 100px;
      }
      
      .emergency-button mat-icon {
        font-size: 36px;
        width: 36px;
        height: 36px;
      }
      
      .quick-actions {
        grid-template-columns: 1fr;
      }
      
      .system-metrics {
        grid-template-columns: 1fr;
      }
    }

    @media (prefers-reduced-motion: reduce) {
      .emergency-pulse {
        animation: none;
      }
      
      .status-card {
        transition: none;
      }
    }
  `]
})
export class DashboardComponent {
  // Angular 20 Signals for reactive state
  private _isEmergencyActive = signal(false);
  private _batteryLevel = signal(85);
  private _networkStrength = signal(75);

  isEmergencyActive = this._isEmergencyActive.asReadonly();
  batteryLevel = this._batteryLevel.asReadonly();
  networkStrength = this._networkStrength.asReadonly();

  // Computed properties
  statusCards = computed(() => {
    const cards: StatusCard[] = [
      {
        id: 'network',
        title: 'Ağ Durumu',
        icon: 'network_check',
        status: this.networkStrength() > 50 ? 'online' : 'warning',
        value: this.networkStrength() > 50 ? 'Çevrimiçi' : 'Zayıf Sinyal',
        description: `${this.getConnectedDevices()} cihaz bağlı`,
        action: 'DETAYLAR',
        route: '/network'
      },
      {
        id: 'messages',
        title: 'Mesajlar',
        icon: 'message',
        status: 'online',
        value: '3 yeni mesaj',
        description: 'Son: 2 dakika önce',
        action: 'GÖRÜNTÜLE',
        route: '/messages'
      },
      {
        id: 'location',
        title: 'Konum',
        icon: 'location_on',
        status: 'online',
        value: 'GPS: Aktif',
        description: 'Konum paylaşımı: Açık',
        action: 'AYARLAR'
      },
      {
        id: 'battery',
        title: 'Pil Durumu',
        icon: 'battery_full',
        status: this.getBatteryStatus(),
        value: `%${this.batteryLevel()}`,
        description: `Tahmini: ${this.getEstimatedTime()} saat`,
        action: 'OPTİMİZE ET'
      }
    ];
    return cards;
  });

  systemMetrics = computed(() => [
    {
      name: 'uptime',
      label: 'Çalışma Süresi',
      value: '2 saat 15 dakika',
      status: 'good'
    },
    {
      name: 'memory',
      label: 'Bellek Kullanımı',
      value: '%45',
      status: 'good'
    },
    {
      name: 'storage',
      label: 'Depolama',
      value: '%23 dolu',
      status: 'good'
    },
    {
      name: 'encryption',
      label: 'Şifreleme',
      value: 'Aktif',
      status: 'good'
    }
  ]);

  getGridCols(): number {
    if (typeof window !== 'undefined') {
      return window.innerWidth < 768 ? 1 : window.innerWidth < 1024 ? 2 : 2;
    }
    return 2;
  }

  getBatteryColor(): 'primary' | 'accent' | 'warn' {
    const level = this.batteryLevel();
    if (level > 50) return 'primary';
    if (level > 20) return 'accent';
    return 'warn';
  }

  getBatteryStatus(): 'online' | 'warning' | 'error' {
    const level = this.batteryLevel();
    if (level > 50) return 'online';
    if (level > 20) return 'warning';
    return 'error';
  }

  getConnectedDevices(): number {
    return Math.floor(Math.random() * 8) + 2; // 2-10 devices
  }

  getEstimatedTime(): number {
    return Math.floor(this.batteryLevel() / 10); // Rough estimation
  }

  handleCardAction(cardId: string): void {
    switch (cardId) {
      case 'location':
        this.shareLocation();
        break;
      case 'battery':
        this.optimizeBattery();
        break;
      default:
        console.log(`Action for ${cardId}`);
    }
  }

  shareLocation(): void {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          console.log(`Konum paylaşıldı: ${latitude}, ${longitude}`);
          // Implement location sharing logic
        },
        (error) => {
          console.error('Konum alınamadı:', error);
        }
      );
    }
  }

  testNetwork(): void {
    console.log('Ağ testi başlatılıyor...');
    // Implement network testing logic
  }

  optimizeBattery(): void {
    console.log('Pil optimizasyonu başlatılıyor...');
    // Implement battery optimization logic
  }
}