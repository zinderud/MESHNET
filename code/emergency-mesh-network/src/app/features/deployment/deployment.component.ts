import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTabsModule } from '@angular/material/tabs';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatChipsModule } from '@angular/material/chips';
import { MatSelectModule } from '@angular/material/select';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { FormsModule } from '@angular/forms';
import { Subscription } from 'rxjs';

import { DeploymentService, DeploymentConfig, DeploymentStatus } from '../../core/services/deployment.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-deployment',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatTabsModule,
    MatProgressBarModule,
    MatChipsModule,
    MatSelectModule,
    MatFormFieldModule,
    MatInputModule,
    MatSlideToggleModule,
    FormsModule
  ],
  template: `
    <div class="deployment-container">
      <h1>Deployment Dashboard</h1>
      
      <!-- Current Deployment Status -->
      <mat-card class="status-card" *ngIf="isDeploying() || lastDeployment()">
        <mat-card-header>
          <mat-card-title>Deployment Status</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="deployment-status">
            <div class="status-header">
              <div class="status-info">
                <mat-chip [ngClass]="getStatusClass(currentStatus())">
                  {{ getStatusText(currentStatus()) }}
                </mat-chip>
                <h3>{{ getDeploymentTitle() }}</h3>
              </div>
              
              <div class="status-actions" *ngIf="isDeploying()">
                <button mat-raised-button color="warn" (click)="cancelDeployment()">
                  <mat-icon>cancel</mat-icon>
                  Cancel Deployment
                </button>
              </div>
            </div>
            
            <div class="progress-section" *ngIf="isDeploying()">
              <mat-progress-bar mode="determinate" [value]="deploymentProgress()"></mat-progress-bar>
              <span class="progress-text">{{ deploymentProgress() }}% Complete</span>
            </div>
            
            <div class="deployment-details" *ngIf="currentDeployment() as deployment">
              <div class="detail-grid">
                <div class="detail-item">
                  <span class="detail-label">Target:</span>
                  <span class="detail-value">{{ deployment.target }}</span>
                </div>
                
                <div class="detail-item">
                  <span class="detail-label">Started:</span>
                  <span class="detail-value">{{ deployment.startTime | date:'medium' }}</span>
                </div>
                
                <div class="detail-item" *ngIf="deployment.endTime">
                  <span class="detail-label">Completed:</span>
                  <span class="detail-value">{{ deployment.endTime | date:'medium' }}</span>
                </div>
                
                <div class="detail-item" *ngIf="deployment.url">
                  <span class="detail-label">URL:</span>
                  <a [href]="deployment.url" target="_blank" class="detail-value url">{{ deployment.url }}</a>
                </div>
              </div>
              
              <div class="deployment-logs">
                <h4>Deployment Logs</h4>
                <div class="logs-container">
                  <div class="log-entry" *ngFor="let log of deployment.logs">
                    {{ log }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Deployment Configuration -->
      <mat-card class="config-card">
        <mat-card-header>
          <mat-card-title>Deployment Configuration</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="config-form">
            <mat-form-field appearance="outline">
              <mat-label>Target Environment</mat-label>
              <mat-select [(ngModel)]="deploymentTarget">
                <mat-option value="production">Production</mat-option>
                <mat-option value="staging">Staging</mat-option>
                <mat-option value="development">Development</mat-option>
              </mat-select>
            </mat-form-field>
            
            <div class="optimization-toggles">
              <h4>Optimizations</h4>
              <div class="toggle-grid">
                <mat-slide-toggle [(ngModel)]="optimizations.minify">
                  Minify
                </mat-slide-toggle>
                
                <mat-slide-toggle [(ngModel)]="optimizations.treeshaking">
                  Tree Shaking
                </mat-slide-toggle>
                
                <mat-slide-toggle [(ngModel)]="optimizations.compression">
                  Compression
                </mat-slide-toggle>
                
                <mat-slide-toggle [(ngModel)]="optimizations.serviceWorker">
                  Service Worker
                </mat-slide-toggle>
              </div>
            </div>
            
            <div class="cdn-config">
              <h4>CDN Configuration</h4>
              <div class="cdn-toggle">
                <mat-slide-toggle [(ngModel)]="cdnEnabled">
                  Enable CDN
                </mat-slide-toggle>
              </div>
              
              <mat-form-field appearance="outline" *ngIf="cdnEnabled">
                <mat-label>CDN Provider</mat-label>
                <mat-select [(ngModel)]="cdnProvider">
                  <mat-option value="cloudflare">Cloudflare</mat-option>
                  <mat-option value="akamai">Akamai</mat-option>
                  <mat-option value="fastly">Fastly</mat-option>
                </mat-select>
              </mat-form-field>
              
              <mat-form-field appearance="outline" *ngIf="cdnEnabled">
                <mat-label>CDN Domain</mat-label>
                <input matInput [(ngModel)]="cdnDomain" placeholder="cdn.example.com">
              </mat-form-field>
            </div>
          </div>
          
          <div class="deploy-actions">
            <button mat-raised-button color="primary" 
                    (click)="startDeployment()"
                    [disabled]="isDeploying()">
              <mat-icon>rocket_launch</mat-icon>
              Deploy to {{ deploymentTarget }}
            </button>
            
            <button mat-button (click)="resetConfig()">
              <mat-icon>refresh</mat-icon>
              Reset Configuration
            </button>
          </div>
        </mat-card-content>
      </mat-card>
      
      <!-- Deployment History -->
      <mat-card class="history-card">
        <mat-card-header>
          <mat-card-title>Deployment History</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="history-list">
            <div class="history-empty" *ngIf="deploymentHistory().length === 0">
              <mat-icon>history</mat-icon>
              <p>No deployment history available</p>
            </div>
            
            <div class="history-item" *ngFor="let deployment of deploymentHistory()">
              <div class="history-header">
                <div class="history-info">
                  <mat-chip [ngClass]="getStatusClass(deployment.status)">
                    {{ getStatusText(deployment.status) }}
                  </mat-chip>
                  <span class="history-target">{{ deployment.target }}</span>
                  <span class="history-date">{{ deployment.startTime | date:'medium' }}</span>
                </div>
                
                <div class="history-actions">
                  <button mat-icon-button [matMenuTriggerFor]="historyMenu">
                    <mat-icon>more_vert</mat-icon>
                  </button>
                  <mat-menu #historyMenu="matMenu">
                    <button mat-menu-item (click)="viewDeploymentDetails(deployment)">
                      <mat-icon>info</mat-icon>
                      <span>View Details</span>
                    </button>
                    <button mat-menu-item *ngIf="deployment.url" (click)="openDeploymentUrl(deployment)">
                      <mat-icon>open_in_new</mat-icon>
                      <span>Open URL</span>
                    </button>
                    <button mat-menu-item (click)="redeployWithSameConfig(deployment)">
                      <mat-icon>replay</mat-icon>
                      <span>Redeploy</span>
                    </button>
                  </mat-menu>
                </div>
              </div>
              
              <div class="history-details" *ngIf="deployment.url">
                <a [href]="deployment.url" target="_blank" class="deployment-url">
                  <mat-icon>link</mat-icon>
                  {{ deployment.url }}
                </a>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .deployment-container {
      max-width: 1000px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
    }

    .status-card {
      margin-bottom: 24px;
      background: linear-gradient(135deg, #f5f5f5, #e0e0e0);
    }

    .deployment-status {
      padding: 8px 0;
    }

    .status-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .status-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .status-info h3 {
      margin: 0;
      font-size: 18px;
    }

    mat-chip.pending {
      background-color: #9e9e9e;
      color: white;
    }

    mat-chip.building {
      background-color: #2196f3;
      color: white;
    }

    mat-chip.deploying {
      background-color: #ff9800;
      color: white;
    }

    mat-chip.success {
      background-color: #4caf50;
      color: white;
    }

    mat-chip.failed {
      background-color: #f44336;
      color: white;
    }

    .progress-section {
      margin-bottom: 16px;
    }

    .progress-text {
      display: block;
      text-align: center;
      margin-top: 4px;
      font-size: 14px;
      color: #666;
    }

    .deployment-details {
      margin-top: 16px;
    }

    .detail-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 16px;
    }

    .detail-item {
      display: flex;
      flex-direction: column;
      gap: 4px;
    }

    .detail-label {
      font-size: 12px;
      color: #666;
    }

    .detail-value {
      font-size: 14px;
      font-weight: 500;
    }

    .detail-value.url {
      color: #2196f3;
      text-decoration: none;
    }

    .detail-value.url:hover {
      text-decoration: underline;
    }

    .deployment-logs {
      margin-top: 24px;
    }

    .deployment-logs h4 {
      margin: 0 0 8px 0;
      font-size: 16px;
    }

    .logs-container {
      max-height: 200px;
      overflow-y: auto;
      background-color: #f5f5f5;
      border-radius: 4px;
      padding: 8px;
      font-family: monospace;
      font-size: 12px;
    }

    .log-entry {
      margin-bottom: 4px;
      white-space: pre-wrap;
      word-break: break-all;
    }

    .config-card {
      margin-bottom: 24px;
    }

    .config-form {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .optimization-toggles,
    .cdn-config {
      margin-top: 8px;
    }

    .optimization-toggles h4,
    .cdn-config h4 {
      margin: 0 0 12px 0;
      font-size: 16px;
    }

    .toggle-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 16px;
    }

    .cdn-toggle {
      margin-bottom: 16px;
    }

    .deploy-actions {
      display: flex;
      gap: 16px;
      margin-top: 24px;
    }

    .history-card {
      margin-bottom: 24px;
    }

    .history-list {
      max-height: 400px;
      overflow-y: auto;
    }

    .history-empty {
      text-align: center;
      padding: 32px;
      color: #666;
    }

    .history-empty mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    .history-item {
      padding: 16px;
      border-bottom: 1px solid #eee;
    }

    .history-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .history-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .history-target {
      font-weight: 500;
    }

    .history-date {
      font-size: 12px;
      color: #666;
    }

    .history-details {
      margin-top: 8px;
    }

    .deployment-url {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 14px;
      color: #2196f3;
      text-decoration: none;
    }

    .deployment-url:hover {
      text-decoration: underline;
    }

    .deployment-url mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    @media (max-width: 768px) {
      .deployment-container {
        padding: 8px;
      }
      
      .status-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }
      
      .detail-grid {
        grid-template-columns: 1fr;
      }
      
      .toggle-grid {
        grid-template-columns: 1fr;
      }
      
      .deploy-actions {
        flex-direction: column;
      }
      
      .deploy-actions button {
        width: 100%;
      }
      
      .history-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
      }
    }
  `]
})
export class DeploymentComponent implements OnInit, OnDestroy {
  private deploymentService = inject(DeploymentService);
  private analyticsService = inject(AnalyticsService);

  // Reactive state from services
  isDeploying = this.deploymentService.isDeploying;
  currentDeployment = this.deploymentService.currentDeployment;
  deploymentHistory = this.deploymentService.deploymentHistory;
  lastDeployment = this.deploymentService.lastDeployment;
  deploymentProgress = this.deploymentService.deploymentProgress;

  // Local component state
  deploymentTarget: 'production' | 'staging' | 'development' = 'production';
  optimizations = {
    minify: true,
    treeshaking: true,
    compression: true,
    serviceWorker: true
  };
  cdnEnabled = false;
  cdnProvider = 'cloudflare';
  cdnDomain = '';

  // Computed properties
  currentStatus = computed(() => {
    const current = this.currentDeployment();
    return current ? current.status : this.lastDeployment()?.status || 'pending';
  });

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.loadConfigFromService();
    this.setupEventListeners();
    this.analyticsService.trackPageView('deployment');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private loadConfigFromService(): void {
    const config = this.deploymentService.deploymentConfig();
    this.deploymentTarget = config.target;
    this.optimizations = { ...config.optimizations };
    this.cdnEnabled = !!config.cdn?.enabled;
    this.cdnProvider = config.cdn?.provider || 'cloudflare';
    this.cdnDomain = config.cdn?.domain || '';
  }

  private setupEventListeners(): void {
    // Listen for deployment events
    this.subscriptions.add(
      this.deploymentService.onDeploymentCompleted$.subscribe(deployment => {
        // Show success notification
        console.log(`Deployment to ${deployment.target} completed successfully`);
      })
    );

    this.subscriptions.add(
      this.deploymentService.onDeploymentFailed$.subscribe(deployment => {
        // Show error notification
        console.error(`Deployment to ${deployment.target} failed: ${deployment.error}`);
      })
    );
  }

  async startDeployment(): Promise<void> {
    try {
      // Prepare deployment config
      const config: DeploymentConfig = {
        target: this.deploymentTarget,
        buildCommand: `ng build --configuration ${this.deploymentTarget}`,
        outputDir: 'dist/emergency-mesh-network',
        environment: {
          NODE_ENV: this.deploymentTarget
        },
        optimizations: { ...this.optimizations },
        cdn: this.cdnEnabled ? {
          enabled: true,
          provider: this.cdnProvider,
          domain: this.cdnDomain
        } : undefined
      };

      // Start deployment
      await this.deploymentService.startDeployment(config);
      this.analyticsService.trackUserAction('deployment', 'initiated', this.deploymentTarget);
    } catch (error) {
      console.error('Failed to start deployment:', error);
      this.analyticsService.trackError('deployment', 'Failed to start deployment', { error });
    }
  }

  cancelDeployment(): void {
    if (this.deploymentService.cancelDeployment()) {
      this.analyticsService.trackUserAction('deployment', 'cancelled');
    }
  }

  resetConfig(): void {
    this.deploymentTarget = 'production';
    this.optimizations = {
      minify: true,
      treeshaking: true,
      compression: true,
      serviceWorker: true
    };
    this.cdnEnabled = false;
    this.cdnProvider = 'cloudflare';
    this.cdnDomain = '';
  }

  viewDeploymentDetails(deployment: DeploymentStatus): void {
    // This would open a dialog with deployment details
    console.log('View deployment details:', deployment);
  }

  openDeploymentUrl(deployment: DeploymentStatus): void {
    if (deployment.url) {
      window.open(deployment.url, '_blank');
    }
  }

  redeployWithSameConfig(deployment: DeploymentStatus): void {
    this.deploymentTarget = deployment.target as any;
    this.startDeployment();
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'pending': return 'Pending';
      case 'building': return 'Building';
      case 'deploying': return 'Deploying';
      case 'success': return 'Success';
      case 'failed': return 'Failed';
      default: return 'Unknown';
    }
  }

  getStatusClass(status: string): string {
    return status;
  }

  getDeploymentTitle(): string {
    const deployment = this.currentDeployment() || this.lastDeployment();
    if (!deployment) return 'No deployment';

    if (deployment.status === 'success') {
      return `Successfully deployed to ${deployment.target}`;
    } else if (deployment.status === 'failed') {
      return `Deployment to ${deployment.target} failed`;
    } else {
      return `Deploying to ${deployment.target}`;
    }
  }
}