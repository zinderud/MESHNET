import { Component, inject, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subscription } from 'rxjs';

import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-deployment',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule
  ],
  template: `
    <div class="deployment-container">
      <mat-card class="deployment-card">
        <mat-card-header>
          <mat-icon mat-card-avatar>cloud_upload</mat-icon>
          <mat-card-title>Uygulama Dağıtımı</mat-card-title>
          <mat-card-subtitle>Acil Durum Mesh Network'ünü Netlify'a dağıtın</mat-card-subtitle>
        </mat-card-header>

        <mat-card-content>
          <div class="deployment-info">
            <h3>Dağıtım Bilgileri</h3>
            <p>
              Uygulamanızı Netlify'a dağıtarak, internet bağlantısı olan herkesin erişebileceği bir web adresi alabilirsiniz.
              Bu, acil durum planlaması için önemli bir adımdır.
            </p>
            
            <div class="deployment-benefits">
              <div class="benefit-item">
                <mat-icon>public</mat-icon>
                <span>Global Erişim</span>
              </div>
              <div class="benefit-item">
                <mat-icon>security</mat-icon>
                <span>HTTPS Güvenliği</span>
              </div>
              <div class="benefit-item">
                <mat-icon>speed</mat-icon>
                <span>Hızlı CDN</span>
              </div>
              <div class="benefit-item">
                <mat-icon>update</mat-icon>
                <span>Otomatik Güncellemeler</span>
              </div>
            </div>
          </div>

          <div class="deployment-status" *ngIf="isDeploying">
            <h3>Dağıtım Durumu</h3>
            <mat-progress-bar mode="indeterminate"></mat-progress-bar>
            <p>Uygulama dağıtılıyor, lütfen bekleyin...</p>
          </div>

          <div class="deployment-result" *ngIf="deploymentUrl">
            <h3>Dağıtım Tamamlandı!</h3>
            <p>Uygulamanıza aşağıdaki adresten erişebilirsiniz:</p>
            <div class="url-container">
              <a [href]="deploymentUrl" target="_blank" class="deployment-url">
                {{ deploymentUrl }}
                <mat-icon>open_in_new</mat-icon>
              </a>
            </div>
            
            <div class="qr-container" *ngIf="deploymentUrl">
              <h4>Mobil Cihazlardan Erişim</h4>
              <p>QR kodunu tarayarak mobil cihazınızdan erişebilirsiniz:</p>
              <img [src]="'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=' + deploymentUrl" 
                   alt="QR Code" class="qr-code">
            </div>
          </div>
        </mat-card-content>

        <mat-card-actions>
          <button mat-raised-button color="primary" 
                  (click)="deployApplication()"
                  [disabled]="isDeploying">
            <mat-icon>cloud_upload</mat-icon>
            Uygulamayı Dağıt
          </button>
          
          <button mat-button 
                  [disabled]="!deploymentUrl || isDeploying"
                  (click)="copyDeploymentUrl()">
            <mat-icon>content_copy</mat-icon>
            URL'yi Kopyala
          </button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [`
    .deployment-container {
      max-width: 800px;
      margin: 0 auto;
      padding: 16px;
    }

    .deployment-card {
      width: 100%;
    }

    .deployment-info {
      margin-bottom: 24px;
    }

    .deployment-info h3 {
      margin: 0 0 16px 0;
      color: #333;
    }

    .deployment-benefits {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 16px;
      margin-top: 24px;
    }

    .benefit-item {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px;
      background-color: #f5f5f5;
      border-radius: 8px;
    }

    .benefit-item mat-icon {
      color: #2196f3;
    }

    .deployment-status {
      margin: 24px 0;
      padding: 16px;
      background-color: #e3f2fd;
      border-radius: 8px;
    }

    .deployment-status h3 {
      margin: 0 0 16px 0;
      color: #2196f3;
    }

    .deployment-status p {
      margin: 16px 0 0 0;
      text-align: center;
      color: #666;
    }

    .deployment-result {
      margin: 24px 0;
      padding: 16px;
      background-color: #e8f5e9;
      border-radius: 8px;
    }

    .deployment-result h3 {
      margin: 0 0 16px 0;
      color: #4caf50;
    }

    .url-container {
      margin: 16px 0;
      text-align: center;
    }

    .deployment-url {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      background-color: #f5f5f5;
      border-radius: 8px;
      color: #2196f3;
      text-decoration: none;
      font-weight: 500;
      transition: background-color 0.3s ease;
    }

    .deployment-url:hover {
      background-color: #e0e0e0;
    }

    .qr-container {
      margin-top: 24px;
      text-align: center;
    }

    .qr-container h4 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .qr-container p {
      margin: 0 0 16px 0;
      color: #666;
    }

    .qr-code {
      max-width: 200px;
      border: 1px solid #ddd;
      border-radius: 8px;
    }

    mat-card-actions {
      display: flex;
      gap: 16px;
      padding: 16px;
    }

    @media (max-width: 768px) {
      .deployment-container {
        padding: 8px;
      }
      
      .deployment-benefits {
        grid-template-columns: 1fr 1fr;
      }
      
      mat-card-actions {
        flex-direction: column;
      }
      
      mat-card-actions button {
        width: 100%;
      }
    }
  `]
})
export class DeploymentComponent implements OnInit, OnDestroy {
  private analyticsService = inject(AnalyticsService);
  private snackBar = inject(MatSnackBar);

  isDeploying = false;
  deploymentUrl: string | null = null;
  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.analyticsService.trackPageView('deployment');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  deployApplication(): void {
    this.isDeploying = true;
    this.analyticsService.trackUserAction('deployment', 'start');
    
    // This would be handled by the deployment service in a real implementation
    setTimeout(() => {
      this.isDeploying = false;
      this.deploymentUrl = 'https://emergency-mesh-network.netlify.app';
      
      this.snackBar.open(
        'Uygulama başarıyla dağıtıldı!', 
        'Tamam', 
        { duration: 5000 }
      );
      
      this.analyticsService.trackUserAction('deployment', 'success');
    }, 3000);
  }

  copyDeploymentUrl(): void {
    if (!this.deploymentUrl) return;
    
    navigator.clipboard.writeText(this.deploymentUrl).then(() => {
      this.snackBar.open(
        'URL panoya kopyalandı!', 
        'Tamam', 
        { duration: 3000 }
      );
      
      this.analyticsService.trackUserAction('deployment', 'copy_url');
    });
  }
}