import { Component, inject, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subscription } from 'rxjs';

import { PWAService } from '../../core/services/pwa.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-pwa-install',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule
  ],
  template: `
    <div class="pwa-container" *ngIf="showInstallPrompt">
      <mat-card class="install-card">
        <mat-card-content>
          <div class="install-header">
            <mat-icon class="app-icon">emergency</mat-icon>
            <div class="install-info">
              <h3>Uygulamayı Yükle</h3>
              <p>Acil Durum Mesh Network'ü cihazınıza yükleyerek daha hızlı erişim sağlayın.</p>
            </div>
          </div>

          <div class="install-benefits">
            <div class="benefit-item">
              <mat-icon>offline_bolt</mat-icon>
              <span>Çevrimdışı çalışma</span>
            </div>
            <div class="benefit-item">
              <mat-icon>speed</mat-icon>
              <span>Hızlı başlatma</span>
            </div>
            <div class="benefit-item">
              <mat-icon>notifications</mat-icon>
              <span>Anında bildirimler</span>
            </div>
            <div class="benefit-item">
              <mat-icon>security</mat-icon>
              <span>Güvenli erişim</span>
            </div>
          </div>

          <div class="install-actions">
            <button mat-raised-button color="primary" 
                    (click)="installApp()"
                    [disabled]="isInstalling">
              <mat-icon>download</mat-icon>
              {{ isInstalling ? 'Yükleniyor...' : 'Uygulamayı Yükle' }}
            </button>
            <button mat-button (click)="dismissInstall()">
              Şimdi Değil
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>

    <!-- Update Available Banner -->
    <div class="update-banner" *ngIf="showUpdatePrompt">
      <mat-card class="update-card">
        <mat-card-content>
          <div class="update-content">
            <mat-icon>system_update</mat-icon>
            <div class="update-info">
              <h4>Güncelleme Mevcut</h4>
              <p>Yeni özellikler ve iyileştirmeler için uygulamayı güncelleyin.</p>
            </div>
            <div class="update-actions">
              <button mat-raised-button color="accent" 
                      (click)="updateApp()"
                      [disabled]="isUpdating">
                {{ isUpdating ? 'Güncelleniyor...' : 'Güncelle' }}
              </button>
              <button mat-icon-button (click)="dismissUpdate()">
                <mat-icon>close</mat-icon>
              </button>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>

    <!-- Storage Usage -->
    <div class="storage-info" *ngIf="storageInfo && storageInfo.percentage > 80">
      <mat-card class="storage-card">
        <mat-card-content>
          <div class="storage-header">
            <mat-icon color="warn">storage</mat-icon>
            <h4>Depolama Alanı</h4>
          </div>
          
          <div class="storage-details">
            <p>Depolama alanınız dolmak üzere (%{{ storageInfo.percentage.toFixed(1) }})</p>
            <mat-progress-bar mode="determinate" 
                              [value]="storageInfo.percentage"
                              [color]="storageInfo.percentage > 90 ? 'warn' : 'accent'">
            </mat-progress-bar>
            <div class="storage-stats">
              <span>{{ formatBytes(storageInfo.usage) }} / {{ formatBytes(storageInfo.quota) }}</span>
            </div>
          </div>

          <div class="storage-actions">
            <button mat-button color="primary" (click)="cleanupStorage()">
              Temizle
            </button>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .pwa-container {
      position: fixed;
      bottom: 16px;
      left: 16px;
      right: 16px;
      z-index: 1000;
      max-width: 400px;
      margin: 0 auto;
    }

    .install-card {
      background: linear-gradient(135deg, #2196f3, #21cbf3);
      color: white;
      box-shadow: 0 8px 32px rgba(33, 150, 243, 0.3);
    }

    .install-header {
      display: flex;
      align-items: center;
      margin-bottom: 16px;
    }

    .app-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-right: 16px;
    }

    .install-info h3 {
      margin: 0 0 4px 0;
      font-size: 18px;
    }

    .install-info p {
      margin: 0;
      opacity: 0.9;
      font-size: 14px;
    }

    .install-benefits {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
      margin: 16px 0;
    }

    .benefit-item {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 14px;
    }

    .benefit-item mat-icon {
      font-size: 20px;
      width: 20px;
      height: 20px;
    }

    .install-actions {
      display: flex;
      gap: 12px;
      justify-content: flex-end;
      margin-top: 20px;
    }

    .install-actions button mat-icon {
      margin-right: 8px;
    }

    .update-banner {
      position: fixed;
      top: 16px;
      left: 16px;
      right: 16px;
      z-index: 1001;
      max-width: 500px;
      margin: 0 auto;
    }

    .update-card {
      background: #ff9800;
      color: white;
    }

    .update-content {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .update-content mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .update-info {
      flex: 1;
    }

    .update-info h4 {
      margin: 0 0 4px 0;
      font-size: 16px;
    }

    .update-info p {
      margin: 0;
      font-size: 14px;
      opacity: 0.9;
    }

    .update-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .storage-info {
      position: fixed;
      top: 80px;
      left: 16px;
      right: 16px;
      z-index: 999;
      max-width: 400px;
      margin: 0 auto;
    }

    .storage-card {
      background: #ff5722;
      color: white;
    }

    .storage-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 12px;
    }

    .storage-header h4 {
      margin: 0;
      font-size: 16px;
    }

    .storage-details p {
      margin: 0 0 8px 0;
      font-size: 14px;
    }

    .storage-stats {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      margin-top: 4px;
      opacity: 0.9;
    }

    .storage-actions {
      display: flex;
      justify-content: flex-end;
      margin-top: 12px;
    }

    @media (max-width: 768px) {
      .pwa-container,
      .update-banner,
      .storage-info {
        left: 8px;
        right: 8px;
      }
      
      .install-benefits {
        grid-template-columns: 1fr;
      }
      
      .install-actions {
        flex-direction: column;
      }
      
      .install-actions button {
        width: 100%;
      }
    }
  `]
})
export class PWAInstallComponent implements OnInit, OnDestroy {
  private pwaService = inject(PWAService);
  private analyticsService = inject(AnalyticsService);
  private snackBar = inject(MatSnackBar);

  showInstallPrompt = false;
  showUpdatePrompt = false;
  isInstalling = false;
  isUpdating = false;
  
  storageInfo: {
    quota: number;
    usage: number;
    available: number;
    percentage: number;
  } | null = null;

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.setupPWAListeners();
    this.checkStorageUsage();
    this.analyticsService.trackPageView('pwa_install');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private setupPWAListeners(): void {
    // Listen for install prompt
    this.subscriptions.add(
      this.pwaService.onInstallPrompt$.subscribe(canInstall => {
        this.showInstallPrompt = canInstall && this.pwaService.canInstall();
      })
    );

    // Listen for update availability
    this.subscriptions.add(
      this.pwaService.onUpdateAvailable$.subscribe(updateAvailable => {
        this.showUpdatePrompt = updateAvailable;
      })
    );

    // Check initial state
    const pwaStatus = this.pwaService.pwaStatus();
    this.showInstallPrompt = pwaStatus.isInstallable && !pwaStatus.isInstalled;
    this.showUpdatePrompt = pwaStatus.isUpdateAvailable;
  }

  private async checkStorageUsage(): Promise<void> {
    try {
      this.storageInfo = await this.pwaService.getStorageEstimate();
    } catch (error) {
      console.error('Failed to get storage info:', error);
    }
  }

  async installApp(): Promise<void> {
    this.isInstalling = true;
    this.analyticsService.trackUserAction('pwa_install', 'attempt');

    try {
      const success = await this.pwaService.installApp();
      
      if (success) {
        this.showInstallPrompt = false;
        this.analyticsService.trackUserAction('pwa_install', 'success');
        
        this.snackBar.open(
          'Uygulama başarıyla yüklendi!', 
          'Tamam', 
          { duration: 3000 }
        );
      } else {
        this.analyticsService.trackUserAction('pwa_install', 'cancelled');
        
        this.snackBar.open(
          'Yükleme iptal edildi', 
          'Tamam', 
          { duration: 3000 }
        );
      }
    } catch (error) {
      this.analyticsService.trackError('pwa_install', 'Installation failed', { error });
      
      this.snackBar.open(
        'Yükleme başarısız oldu', 
        'Tamam', 
        { duration: 3000 }
      );
    } finally {
      this.isInstalling = false;
    }
  }

  dismissInstall(): void {
    this.showInstallPrompt = false;
    this.analyticsService.trackUserAction('pwa_install', 'dismissed');
  }

  async updateApp(): Promise<void> {
    this.isUpdating = true;
    this.analyticsService.trackUserAction('pwa_update', 'attempt');

    try {
      const success = await this.pwaService.updateApp();
      
      if (success) {
        this.analyticsService.trackUserAction('pwa_update', 'success');
        // App will reload automatically
      } else {
        this.analyticsService.trackUserAction('pwa_update', 'failed');
        
        this.snackBar.open(
          'Güncelleme başarısız oldu', 
          'Tamam', 
          { duration: 3000 }
        );
      }
    } catch (error) {
      this.analyticsService.trackError('pwa_update', 'Update failed', { error });
      
      this.snackBar.open(
        'Güncelleme sırasında hata oluştu', 
        'Tamam', 
        { duration: 3000 }
      );
    } finally {
      this.isUpdating = false;
    }
  }

  dismissUpdate(): void {
    this.showUpdatePrompt = false;
    this.analyticsService.trackUserAction('pwa_update', 'dismissed');
  }

  async cleanupStorage(): Promise<void> {
    this.analyticsService.trackUserAction('storage', 'cleanup');

    try {
      // Clear old cached data
      if ('caches' in window) {
        const cacheNames = await caches.keys();
        const oldCaches = cacheNames.filter(name => 
          name.includes('old') || name.includes('v1') || name.includes('temp')
        );
        
        await Promise.all(oldCaches.map(name => caches.delete(name)));
      }

      // Clear old localStorage entries
      const keys = Object.keys(localStorage);
      const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
      
      keys.forEach(key => {
        try {
          const item = localStorage.getItem(key);
          if (item) {
            const data = JSON.parse(item);
            if (data.timestamp && data.timestamp < oneWeekAgo) {
              localStorage.removeItem(key);
            }
          }
        } catch {
          // Invalid JSON, keep it
        }
      });

      // Update storage info
      await this.checkStorageUsage();

      this.snackBar.open(
        'Depolama alanı temizlendi', 
        'Tamam', 
        { duration: 3000 }
      );
    } catch (error) {
      this.analyticsService.trackError('storage', 'Cleanup failed', { error });
      
      this.snackBar.open(
        'Temizleme başarısız oldu', 
        'Tamam', 
        { duration: 3000 }
      );
    }
  }

  formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
}