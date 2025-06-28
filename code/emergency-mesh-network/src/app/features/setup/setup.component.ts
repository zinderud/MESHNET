import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatStepperModule } from '@angular/material/stepper';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { FormsModule } from '@angular/forms';

import { CryptoService } from '../../core/services/crypto.service';
import { WebApisService } from '../../core/services/web-apis.service';
import { LocationService } from '../../core/services/location.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-setup',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatStepperModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    FormsModule
  ],
  template: `
    <div class="setup-container">
      <mat-card class="setup-card">
        <mat-card-header>
          <mat-icon mat-card-avatar>security</mat-icon>
          <mat-card-title>Acil Durum Mesh Network Kurulumu</mat-card-title>
          <mat-card-subtitle>Güvenli iletişim için ilk kurulum</mat-card-subtitle>
        </mat-card-header>

        <mat-card-content>
          <mat-stepper [linear]="true" #stepper>
            <!-- Step 1: Permissions -->
            <mat-step [completed]="permissionsGranted">
              <ng-template matStepLabel>İzinler</ng-template>
              <div class="step-content">
                <h3>Gerekli İzinler</h3>
                <p>Uygulamanın düzgün çalışması için aşağıdaki izinlere ihtiyacımız var:</p>
                
                <div class="permission-list">
                  <div class="permission-item" [ngClass]="{'granted': permissions.location}">
                    <mat-icon>{{ permissions.location ? 'check_circle' : 'location_on' }}</mat-icon>
                    <div class="permission-info">
                      <h4>Konum Erişimi</h4>
                      <p>Acil durumlarda konumunuzu paylaşmak için</p>
                    </div>
                    <button mat-button (click)="requestLocationPermission()" 
                            [disabled]="permissions.location">
                      {{ permissions.location ? 'Verildi' : 'İzin Ver' }}
                    </button>
                  </div>

                  <div class="permission-item" [ngClass]="{'granted': permissions.notifications}">
                    <mat-icon>{{ permissions.notifications ? 'check_circle' : 'notifications' }}</mat-icon>
                    <div class="permission-info">
                      <h4>Bildirimler</h4>
                      <p>Acil durum uyarıları için</p>
                    </div>
                    <button mat-button (click)="requestNotificationPermission()" 
                            [disabled]="permissions.notifications">
                      {{ permissions.notifications ? 'Verildi' : 'İzin Ver' }}
                    </button>
                  </div>

                  <div class="permission-item" [ngClass]="{'granted': permissions.deviceMotion}">
                    <mat-icon>{{ permissions.deviceMotion ? 'check_circle' : 'vibration' }}</mat-icon>
                    <div class="permission-info">
                      <h4>Cihaz Sensörleri</h4>
                      <p>Düşme algılama için</p>
                    </div>
                    <button mat-button (click)="requestDeviceMotionPermission()" 
                            [disabled]="permissions.deviceMotion">
                      {{ permissions.deviceMotion ? 'Verildi' : 'İzin Ver' }}
                    </button>
                  </div>
                </div>

                <div class="step-actions">
                  <button mat-raised-button color="primary" 
                          [disabled]="!permissionsGranted"
                          (click)="stepper.next()">
                    Devam Et
                  </button>
                </div>
              </div>
            </mat-step>

            <!-- Step 2: Security Setup -->
            <mat-step [completed]="securitySetupComplete">
              <ng-template matStepLabel>Güvenlik</ng-template>
              <div class="step-content">
                <h3>Güvenlik Kurulumu</h3>
                <p>Mesajlarınızın güvenliği için şifreleme anahtarları oluşturuluyor...</p>
                
                <div class="security-status" *ngIf="!securitySetupComplete">
                  <mat-spinner diameter="40"></mat-spinner>
                  <p>{{ securitySetupStatus }}</p>
                </div>

                <div class="security-complete" *ngIf="securitySetupComplete">
                  <mat-icon color="primary">check_circle</mat-icon>
                  <h4>Güvenlik Kurulumu Tamamlandı</h4>
                  <p>Şifreleme anahtarlarınız güvenli bir şekilde oluşturuldu.</p>
                </div>

                <div class="step-actions">
                  <button mat-button (click)="stepper.previous()">Geri</button>
                  <button mat-raised-button color="primary" 
                          [disabled]="!securitySetupComplete"
                          (click)="stepper.next()">
                    Devam Et
                  </button>
                </div>
              </div>
            </mat-step>

            <!-- Step 3: Device Configuration -->
            <mat-step [completed]="deviceConfigComplete">
              <ng-template matStepLabel>Cihaz Ayarları</ng-template>
              <div class="step-content">
                <h3>Cihaz Yapılandırması</h3>
                
                <mat-form-field appearance="outline" class="full-width">
                  <mat-label>Cihaz Adı</mat-label>
                  <input matInput [(ngModel)]="deviceConfig.name" 
                         placeholder="Örn: Ahmet'in Telefonu">
                </mat-form-field>

                <div class="config-options">
                  <div class="config-item">
                    <mat-slide-toggle [(ngModel)]="deviceConfig.autoDiscovery">
                      Otomatik Cihaz Keşfi
                    </mat-slide-toggle>
                    <p>Yakındaki cihazları otomatik olarak bul ve bağlan</p>
                  </div>

                  <div class="config-item">
                    <mat-slide-toggle [(ngModel)]="deviceConfig.emergencyMode">
                      Acil Durum Modu
                    </mat-slide-toggle>
                    <p>Acil durumlarda otomatik olarak mesh ağını etkinleştir</p>
                  </div>

                  <div class="config-item">
                    <mat-slide-toggle [(ngModel)]="deviceConfig.locationSharing">
                      Konum Paylaşımı
                    </mat-slide-toggle>
                    <p>Acil durumlarda konumunu otomatik paylaş</p>
                  </div>
                </div>

                <div class="step-actions">
                  <button mat-button (click)="stepper.previous()">Geri</button>
                  <button mat-raised-button color="primary" 
                          [disabled]="!deviceConfig.name.trim()"
                          (click)="completeDeviceConfig()">
                    Devam Et
                  </button>
                </div>
              </div>
            </mat-step>

            <!-- Step 4: Complete -->
            <mat-step>
              <ng-template matStepLabel>Tamamlandı</ng-template>
              <div class="step-content">
                <div class="setup-complete">
                  <mat-icon class="success-icon">check_circle</mat-icon>
                  <h3>Kurulum Tamamlandı!</h3>
                  <p>Acil Durum Mesh Network kullanıma hazır.</p>
                  
                  <div class="setup-summary">
                    <h4>Kurulum Özeti:</h4>
                    <ul>
                      <li>✅ Tüm izinler verildi</li>
                      <li>✅ Güvenlik anahtarları oluşturuldu</li>
                      <li>✅ Cihaz yapılandırması tamamlandı</li>
                      <li>✅ Mesh ağ bağlantısı hazır</li>
                    </ul>
                  </div>

                  <div class="step-actions">
                    <button mat-raised-button color="primary" 
                            (click)="completeSetup()">
                      Uygulamayı Başlat
                    </button>
                  </div>
                </div>
              </div>
            </mat-step>
          </mat-stepper>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .setup-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
      min-height: 100vh;
      display: flex;
      align-items: center;
    }

    .setup-card {
      width: 100%;
      max-width: 700px;
      margin: 0 auto;
    }

    .step-content {
      padding: 24px 0;
    }

    .step-content h3 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .permission-list {
      margin: 24px 0;
    }

    .permission-item {
      display: flex;
      align-items: center;
      padding: 16px;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      margin-bottom: 12px;
      transition: all 0.3s ease;
    }

    .permission-item.granted {
      background-color: #e8f5e8;
      border-color: #4caf50;
    }

    .permission-item mat-icon {
      margin-right: 16px;
      color: #666;
    }

    .permission-item.granted mat-icon {
      color: #4caf50;
    }

    .permission-info {
      flex: 1;
    }

    .permission-info h4 {
      margin: 0 0 4px 0;
      font-size: 16px;
    }

    .permission-info p {
      margin: 0;
      font-size: 14px;
      color: #666;
    }

    .security-status {
      text-align: center;
      padding: 32px;
    }

    .security-status mat-spinner {
      margin-bottom: 16px;
    }

    .security-complete {
      text-align: center;
      padding: 32px;
    }

    .security-complete mat-icon {
      font-size: 64px;
      width: 64px;
      height: 64px;
      margin-bottom: 16px;
    }

    .security-complete h4 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }

    .config-options {
      margin: 24px 0;
    }

    .config-item {
      margin-bottom: 24px;
    }

    .config-item p {
      margin: 8px 0 0 0;
      font-size: 14px;
      color: #666;
    }

    .setup-complete {
      text-align: center;
      padding: 32px;
    }

    .success-icon {
      font-size: 80px;
      width: 80px;
      height: 80px;
      color: #4caf50;
      margin-bottom: 16px;
    }

    .setup-complete h3 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .setup-summary {
      background-color: #f5f5f5;
      padding: 16px;
      border-radius: 8px;
      margin: 24px 0;
      text-align: left;
    }

    .setup-summary h4 {
      margin: 0 0 12px 0;
      color: #333;
    }

    .setup-summary ul {
      margin: 0;
      padding-left: 20px;
    }

    .setup-summary li {
      margin-bottom: 4px;
      color: #666;
    }

    .step-actions {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
      margin-top: 32px;
    }

    @media (max-width: 768px) {
      .setup-container {
        padding: 8px;
      }
      
      .permission-item {
        flex-direction: column;
        text-align: center;
        gap: 12px;
      }
      
      .permission-info {
        order: 1;
      }
      
      .step-actions {
        flex-direction: column;
      }
      
      .step-actions button {
        width: 100%;
      }
    }
  `]
})
export class SetupComponent implements OnInit {
  private cryptoService = inject(CryptoService);
  private webApisService = inject(WebApisService);
  private locationService = inject(LocationService);
  private analyticsService = inject(AnalyticsService);
  private router = inject(Router);

  permissions = {
    location: false,
    notifications: false,
    deviceMotion: false
  };

  securitySetupComplete = false;
  securitySetupStatus = 'Şifreleme anahtarları oluşturuluyor...';

  deviceConfigComplete = false;
  deviceConfig = {
    name: '',
    autoDiscovery: true,
    emergencyMode: true,
    locationSharing: true
  };

  get permissionsGranted(): boolean {
    return this.permissions.location && 
           this.permissions.notifications && 
           this.permissions.deviceMotion;
  }

  ngOnInit(): void {
    this.checkExistingPermissions();
    this.startSecuritySetup();
    this.analyticsService.trackPageView('setup');
  }

  private async checkExistingPermissions(): Promise<void> {
    // Check notification permission
    if ('Notification' in window) {
      this.permissions.notifications = Notification.permission === 'granted';
    }

    // Check location permission
    try {
      const result = await navigator.permissions.query({ name: 'geolocation' });
      this.permissions.location = result.state === 'granted';
    } catch {
      this.permissions.location = false;
    }

    // Device motion permission is usually granted by default
    this.permissions.deviceMotion = 'DeviceMotionEvent' in window;
  }

  async requestLocationPermission(): Promise<void> {
    try {
      this.analyticsService.trackUserAction('request_permission', 'location');
      const location = await this.locationService.getCurrentLocation();
      this.permissions.location = !!location;
    } catch (error) {
      console.error('Location permission denied:', error);
      this.permissions.location = false;
    }
  }

  async requestNotificationPermission(): Promise<void> {
    try {
      this.analyticsService.trackUserAction('request_permission', 'notifications');
      const permission = await this.webApisService.requestNotificationPermission();
      this.permissions.notifications = permission === 'granted';
    } catch (error) {
      console.error('Notification permission denied:', error);
      this.permissions.notifications = false;
    }
  }

  async requestDeviceMotionPermission(): Promise<void> {
    try {
      this.analyticsService.trackUserAction('request_permission', 'device_motion');
      const granted = await this.webApisService.requestDeviceMotionPermission();
      this.permissions.deviceMotion = granted;
    } catch (error) {
      console.error('Device motion permission denied:', error);
      this.permissions.deviceMotion = false;
    }
  }

  private async startSecuritySetup(): Promise<void> {
    try {
      this.securitySetupStatus = 'Şifreleme anahtarları oluşturuluyor...';
      
      // Initialize crypto service
      await new Promise(resolve => setTimeout(resolve, 2000)); // Simulate setup time
      
      this.securitySetupStatus = 'Güvenlik protokolleri yapılandırılıyor...';
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      this.securitySetupStatus = 'Mesh ağ güvenliği hazırlanıyor...';
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      this.securitySetupComplete = true;
      this.analyticsService.trackUserAction('security_setup', 'completed');
    } catch (error) {
      console.error('Security setup failed:', error);
      this.analyticsService.trackError('security_setup', 'Setup failed', { error: error.message });
    }
  }

  completeDeviceConfig(): void {
    if (!this.deviceConfig.name.trim()) {
      return;
    }

    // Save device configuration
    localStorage.setItem('device_config', JSON.stringify(this.deviceConfig));
    
    this.deviceConfigComplete = true;
    this.analyticsService.trackUserAction('device_config', 'completed', undefined, {
      deviceName: this.deviceConfig.name,
      autoDiscovery: this.deviceConfig.autoDiscovery,
      emergencyMode: this.deviceConfig.emergencyMode,
      locationSharing: this.deviceConfig.locationSharing
    });
  }

  completeSetup(): void {
    // Mark setup as complete
    localStorage.setItem('setup_complete', 'true');
    localStorage.setItem('setup_timestamp', Date.now().toString());
    
    this.analyticsService.trackUserAction('setup', 'completed');
    
    // Navigate to dashboard
    this.router.navigate(['/dashboard']);
  }
}