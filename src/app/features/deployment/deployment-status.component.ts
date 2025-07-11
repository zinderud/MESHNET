import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { DeploymentStatus } from '../../core/services/deployment.service';

@Component({
  selector: 'app-deployment-status',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule,
    MatProgressBarModule
  ],
  template: `
    <mat-card class="status-card">
      <mat-card-content>
        <div class="deployment-status">
          <div class="status-header">
            <div class="status-info">
              <mat-chip [ngClass]="getStatusClass(deployment.status)">
                {{ getStatusText(deployment.status) }}
              </mat-chip>
              <h3>{{ getDeploymentTitle() }}</h3>
            </div>
            
            <div class="status-actions" *ngIf="deployment.status === 'pending' || deployment.status === 'building' || deployment.status === 'deploying'">
              <button mat-raised-button color="warn" (click)="cancel.emit()">
                <mat-icon>cancel</mat-icon>
                Cancel Deployment
              </button>
            </div>
          </div>
          
          <div class="progress-section" *ngIf="deployment.status === 'pending' || deployment.status === 'building' || deployment.status === 'deploying'">
            <mat-progress-bar mode="determinate" [value]="deployment.progress"></mat-progress-bar>
            <span class="progress-text">{{ deployment.progress }}% Complete</span>
          </div>
          
          <div class="deployment-details">
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
  `,
  styles: [`
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

    @media (max-width: 768px) {
      .status-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }
      
      .detail-grid {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class DeploymentStatusComponent {
  @Input() deployment!: DeploymentStatus;
  @Output() cancel = new EventEmitter<void>();

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
    if (this.deployment.status === 'success') {
      return `Successfully deployed to ${this.deployment.target}`;
    } else if (this.deployment.status === 'failed') {
      return `Deployment to ${this.deployment.target} failed`;
    } else {
      return `Deploying to ${this.deployment.target}`;
    }
  }
}