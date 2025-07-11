import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

@Component({
  selector: 'app-emergency',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule
  ],
  template: `
    <div class="emergency-container">
      <mat-card class="emergency-alert-card">
        <mat-card-content>
          <div class="alert-header">
            <mat-icon class="alert-icon">warning</mat-icon>
            <h1>ACİL DURUM MODU</h1>
          </div>
          
          <div class="alert-status">
            <mat-spinner diameter="40"></mat-spinner>
            <p>Acil durum sinyali gönderiliyor...</p>
          </div>

          <div class="emergency-info">
            <h3>Gönderilen Bilgiler:</h3>
            <ul>
              <li>📍 Konum: 41.0082° K, 28.9784° D</li>
              <li>⏰ Zaman: {{ currentTime }}</li>
              <li>📱 Cihaz ID: EMN-{{ deviceId }}</li>
              <li>🔋 Pil: %85</li>
            </ul>
          </div>

          <div class="emergency-actions">
            <button mat-raised-button color="primary" class="action-button">
              <mat-icon>phone</mat-icon>
              112'yi Ara
            </button>
            
            <button mat-raised-button color="accent" class="action-button">
              <mat-icon>message</mat-icon>
              Mesaj Gönder
            </button>
            
            <button mat-raised-button color="warn" (click)="cancelEmergency()">
              <mat-icon>cancel</mat-icon>
              İptal Et
            </button>
          </div>

          <div class="network-status">
            <h3>Ağ Durumu:</h3>
            <div class="status-list">
              <div class="status-item">
                <mat-icon class="status-icon success">check_circle</mat-icon>
                <span>Mesh Network: Aktif (5 cihaz)</span>
              </div>
              <div class="status-item">
                <mat-icon class="status-icon warning">warning</mat-icon>
                <span>Hücresel Ağ: Zayıf sinyal</span>
              </div>
              <div class="status-item">
                <mat-icon class="status-icon error">error</mat-icon>
                <span>WiFi: Bağlantı yok</span>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .emergency-container {
      max-width: 600px;
      margin: 0 auto;
      padding: 16px;
    }

    .emergency-alert-card {
      background: linear-gradient(135deg, #ff5722, #f44336);
      color: white;
      box-shadow: 0 8px 32px rgba(244, 67, 54, 0.3);
    }

    .alert-header {
      text-align: center;
      margin-bottom: 24px;
    }

    .alert-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      animation: pulse 2s infinite;
    }

    @keyframes pulse {
      0% { transform: scale(1); }
      50% { transform: scale(1.1); }
      100% { transform: scale(1); }
    }

    .alert-header h1 {
      margin: 16px 0 0 0;
      font-size: 28px;
      font-weight: bold;
    }

    .alert-status {
      text-align: center;
      margin: 24px 0;
    }

    .alert-status mat-spinner {
      margin-bottom: 16px;
    }

    .emergency-info {
      background: rgba(255, 255, 255, 0.1);
      padding: 16px;
      border-radius: 8px;
      margin: 24px 0;
    }

    .emergency-info h3 {
      margin: 0 0 12px 0;
      font-size: 18px;
    }

    .emergency-info ul {
      list-style: none;
      padding: 0;
      margin: 0;
    }

    .emergency-info li {
      padding: 4px 0;
      font-size: 14px;
    }

    .emergency-actions {
      display: flex;
      flex-direction: column;
      gap: 12px;
      margin: 24px 0;
    }

    .action-button {
      height: 48px;
      font-size: 16px;
    }

    .action-button mat-icon {
      margin-right: 8px;
    }

    .network-status {
      background: rgba(255, 255, 255, 0.1);
      padding: 16px;
      border-radius: 8px;
      margin-top: 24px;
    }

    .network-status h3 {
      margin: 0 0 12px 0;
      font-size: 18px;
    }

    .status-list {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .status-item {
      display: flex;
      align-items: center;
      font-size: 14px;
    }

    .status-icon {
      margin-right: 8px;
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .status-icon.success {
      color: #4caf50;
    }

    .status-icon.warning {
      color: #ff9800;
    }

    .status-icon.error {
      color: #f44336;
    }

    @media (max-width: 768px) {
      .emergency-container {
        padding: 8px;
      }
      
      .alert-icon {
        font-size: 48px;
        width: 48px;
        height: 48px;
      }
      
      .alert-header h1 {
        font-size: 24px;
      }
    }
  `]
})
export class EmergencyComponent {
  currentTime = new Date().toLocaleString('tr-TR');
  deviceId = Math.random().toString(36).substr(2, 6).toUpperCase();

  cancelEmergency() {
    // Acil durum iptal etme mantığı
    console.log('Acil durum iptal edildi');
  }
}