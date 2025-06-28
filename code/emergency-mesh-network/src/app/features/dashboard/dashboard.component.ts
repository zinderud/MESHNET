import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatGridListModule } from '@angular/material/grid-list';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatGridListModule,
    RouterModule
  ],
  template: `
    <div class="dashboard-container">
      <h1>Acil Durum Kontrol Paneli</h1>
      
      <!-- Acil Durum Butonu -->
      <mat-card class="emergency-card">
        <mat-card-content>
          <div class="emergency-button-container">
            <button mat-fab color="warn" class="emergency-button" routerLink="/emergency">
              <mat-icon>warning</mat-icon>
            </button>
            <h2>ACİL DURUM</h2>
            <p>Acil durumda bu butona basın</p>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Durum Kartları -->
      <mat-grid-list cols="2" rowHeight="200px" gutterSize="16px" class="status-grid">
        <mat-grid-tile>
          <mat-card class="status-card">
            <mat-card-header>
              <mat-icon mat-card-avatar>network_check</mat-icon>
              <mat-card-title>Ağ Durumu</mat-card-title>
            </mat-card-header>
            <mat-card-content>
              <div class="status-indicator online">
                <span class="status-dot"></span>
                <span>Çevrimiçi</span>
              </div>
              <p>5 cihaz bağlı</p>
            </mat-card-content>
            <mat-card-actions>
              <button mat-button routerLink="/network">DETAYLAR</button>
            </mat-card-actions>
          </mat-card>
        </mat-grid-tile>

        <mat-grid-tile>
          <mat-card class="status-card">
            <mat-card-header>
              <mat-icon mat-card-avatar>message</mat-icon>
              <mat-card-title>Mesajlar</mat-card-title>
            </mat-card-header>
            <mat-card-content>
              <p>3 yeni mesaj</p>
              <p>Son: 2 dakika önce</p>
            </mat-card-content>
            <mat-card-actions>
              <button mat-button routerLink="/messages">GÖRÜNTÜLE</button>
            </mat-card-actions>
          </mat-card>
        </mat-grid-tile>

        <mat-grid-tile>
          <mat-card class="status-card">
            <mat-card-header>
              <mat-icon mat-card-avatar>location_on</mat-icon>
              <mat-card-title>Konum</mat-card-title>
            </mat-card-header>
            <mat-card-content>
              <p>GPS: Aktif</p>
              <p>Konum paylaşımı: Açık</p>
            </mat-card-content>
            <mat-card-actions>
              <button mat-button>AYARLAR</button>
            </mat-card-actions>
          </mat-card>
        </mat-grid-tile>

        <mat-grid-tile>
          <mat-card class="status-card">
            <mat-card-header>
              <mat-icon mat-card-avatar>battery_full</mat-icon>
              <mat-card-title>Pil Durumu</mat-card-title>
            </mat-card-header>
            <mat-card-content>
              <p>%85 - İyi</p>
              <p>Tahmini: 8 saat</p>
            </mat-card-content>
            <mat-card-actions>
              <button mat-button>OPTİMİZE ET</button>
            </mat-card-actions>
          </mat-card>
        </mat-grid-tile>
      </mat-grid-list>
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
    }

    .emergency-card {
      margin-bottom: 24px;
      background: linear-gradient(135deg, #ff5722, #f44336);
      color: white;
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
    }

    .emergency-button:hover {
      transform: scale(1.05);
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
      margin: 0;
      opacity: 0.9;
    }

    .status-grid {
      margin-top: 24px;
    }

    .status-card {
      width: 100%;
      height: 100%;
      display: flex;
      flex-direction: column;
    }

    .status-card mat-card-content {
      flex: 1;
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

    @media (max-width: 768px) {
      .status-grid {
        grid-template-columns: 1fr !important;
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
    }
  `]
})
export class DashboardComponent {
}