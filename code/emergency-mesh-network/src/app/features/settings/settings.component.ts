import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatSelectModule } from '@angular/material/select';
import { MatInputModule } from '@angular/material/input';
import { MatFormFieldModule } from '@angular/material/form-field';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatSlideToggleModule,
    MatSelectModule,
    MatInputModule,
    MatFormFieldModule,
    FormsModule
  ],
  template: `
    <div class="settings-container">
      <h1>Ayarlar</h1>
      
      <!-- Genel Ayarlar -->
      <mat-card class="settings-section">
        <mat-card-header>
          <mat-icon mat-card-avatar>settings</mat-icon>
          <mat-card-title>Genel Ayarlar</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="setting-item">
            <div class="setting-info">
              <h3>Otomatik Ağ Keşfi</h3>
              <p>Yakındaki cihazları otomatik olarak keşfet ve bağlan</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.autoDiscovery"></mat-slide-toggle>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <h3>Konum Paylaşımı</h3>
              <p>Acil durumlarda konumunu otomatik olarak paylaş</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.locationSharing"></mat-slide-toggle>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <h3>Bildirimler</h3>
              <p>Acil durum ve sistem bildirimlerini al</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.notifications"></mat-slide-toggle>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Ağ Ayarları -->
      <mat-card class="settings-section">
        <mat-card-header>
          <mat-icon mat-card-avatar>network_wifi</mat-icon>
          <mat-card-title>Ağ Ayarları</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="setting-item">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Cihaz Adı</mat-label>
              <input matInput [(ngModel)]="settings.deviceName" placeholder="Cihazınızın adı">
            </mat-form-field>
          </div>
          
          <div class="setting-item">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Ağ Modu</mat-label>
              <mat-select [(ngModel)]="settings.networkMode">
                <mat-option value="auto">Otomatik</mat-option>
                <mat-option value="wifi">Sadece WiFi</mat-option>
                <mat-option value="bluetooth">Sadece Bluetooth</mat-option>
                <mat-option value="hybrid">Hibrit (WiFi + Bluetooth)</mat-option>
              </mat-select>
            </mat-form-field>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <h3>Güç Tasarrufu Modu</h3>
              <p>Pil ömrünü uzatmak için ağ aktivitesini azalt</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.powerSaving"></mat-slide-toggle>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Güvenlik Ayarları -->
      <mat-card class="settings-section">
        <mat-card-header>
          <mat-icon mat-card-avatar>security</mat-icon>
          <mat-card-title>Güvenlik Ayarları</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="setting-item">
            <div class="setting-info">
              <h3>Uçtan Uca Şifreleme</h3>
              <p>Tüm mesajları şifrele (önerilen)</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.encryption" disabled="true"></mat-slide-toggle>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <h3>Kimlik Doğrulama</h3>
              <p>Yeni cihazları bağlamadan önce doğrula</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.authentication"></mat-slide-toggle>
          </div>
          
          <div class="setting-item">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Güvenlik Seviyesi</mat-label>
              <mat-select [(ngModel)]="settings.securityLevel">
                <mat-option value="low">Düşük</mat-option>
                <mat-option value="medium">Orta</mat-option>
                <mat-option value="high">Yüksek</mat-option>
              </mat-select>
            </mat-form-field>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Acil Durum Ayarları -->
      <mat-card class="settings-section">
        <mat-card-header>
          <mat-icon mat-card-avatar>warning</mat-icon>
          <mat-card-title>Acil Durum Ayarları</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="setting-item">
            <mat-form-field appearance="outline" class="full-width">
              <mat-label>Acil Durum Kişisi</mat-label>
              <input matInput [(ngModel)]="settings.emergencyContact" placeholder="Telefon numarası">
            </mat-form-field>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <h3>Otomatik 112 Arama</h3>
              <p>Acil durum butonuna basıldığında otomatik olarak 112'yi ara</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.auto112Call"></mat-slide-toggle>
          </div>
          
          <div class="setting-item">
            <div class="setting-info">
              <h3>Titreşim Uyarısı</h3>
              <p>Acil durum mesajları için titreşim uyarısı</p>
            </div>
            <mat-slide-toggle [(ngModel)]="settings.vibrationAlert"></mat-slide-toggle>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Sistem Bilgileri -->
      <mat-card class="settings-section">
        <mat-card-header>
          <mat-icon mat-card-avatar>info</mat-icon>
          <mat-card-title>Sistem Bilgileri</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">Uygulama Sürümü:</span>
              <span class="info-value">v1.0.0</span>
            </div>
            <div class="info-item">
              <span class="info-label">Cihaz ID:</span>
              <span class="info-value">EMN-{{ deviceId }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Ağ Durumu:</span>
              <span class="info-value status-online">Çevrimiçi</span>
            </div>
            <div class="info-item">
              <span class="info-label">Son Güncelleme:</span>
              <span class="info-value">{{ lastUpdate | date:'short':'tr' }}</span>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Eylem Butonları -->
      <div class="action-buttons">
        <button mat-raised-button color="primary" (click)="saveSettings()">
          <mat-icon>save</mat-icon>
          Ayarları Kaydet
        </button>
        
        <button mat-raised-button color="accent" (click)="resetSettings()">
          <mat-icon>refresh</mat-icon>
          Varsayılana Sıfırla
        </button>
        
        <button mat-raised-button color="warn" (click)="clearData()">
          <mat-icon>delete</mat-icon>
          Verileri Temizle
        </button>
      </div>
    </div>
  `,
  styles: [`
    .settings-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
    }

    .settings-section {
      margin-bottom: 24px;
    }

    .setting-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px 0;
      border-bottom: 1px solid #eee;
    }

    .setting-item:last-child {
      border-bottom: none;
    }

    .setting-info {
      flex: 1;
      margin-right: 16px;
    }

    .setting-info h3 {
      margin: 0 0 4px 0;
      font-size: 16px;
      font-weight: 500;
    }

    .setting-info p {
      margin: 0;
      font-size: 14px;
      color: #666;
    }

    .full-width {
      width: 100%;
    }

    .info-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    .info-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 0;
    }

    .info-label {
      font-weight: 500;
      color: #666;
    }

    .info-value {
      font-weight: 600;
    }

    .status-online {
      color: #4caf50;
    }

    .action-buttons {
      display: flex;
      gap: 16px;
      justify-content: center;
      margin-top: 32px;
    }

    .action-buttons button {
      min-width: 150px;
    }

    .action-buttons button mat-icon {
      margin-right: 8px;
    }

    @media (max-width: 768px) {
      .settings-container {
        padding: 8px;
      }
      
      .setting-item {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }
      
      .setting-info {
        margin-right: 0;
      }
      
      .info-grid {
        grid-template-columns: 1fr;
      }
      
      .action-buttons {
        flex-direction: column;
      }
      
      .action-buttons button {
        width: 100%;
      }
    }
  `]
})
export class SettingsComponent {
  deviceId = Math.random().toString(36).substr(2, 6).toUpperCase();
  lastUpdate = new Date();
  
  settings = {
    autoDiscovery: true,
    locationSharing: true,
    notifications: true,
    deviceName: 'Benim Cihazım',
    networkMode: 'auto',
    powerSaving: false,
    encryption: true,
    authentication: true,
    securityLevel: 'high',
    emergencyContact: '',
    auto112Call: false,
    vibrationAlert: true
  };

  saveSettings() {
    // Ayarları kaydetme mantığı
    console.log('Ayarlar kaydedildi:', this.settings);
    // Burada localStorage veya backend'e kaydetme işlemi yapılabilir
  }

  resetSettings() {
    // Varsayılan ayarlara sıfırlama
    this.settings = {
      autoDiscovery: true,
      locationSharing: true,
      notifications: true,
      deviceName: 'Benim Cihazım',
      networkMode: 'auto',
      powerSaving: false,
      encryption: true,
      authentication: true,
      securityLevel: 'high',
      emergencyContact: '',
      auto112Call: false,
      vibrationAlert: true
    };
    console.log('Ayarlar varsayılana sıfırlandı');
  }

  clearData() {
    // Uygulama verilerini temizleme
    if (confirm('Tüm uygulama verileri silinecek. Emin misiniz?')) {
      console.log('Veriler temizlendi');
      // Burada localStorage temizleme işlemi yapılabilir
    }
  }
}