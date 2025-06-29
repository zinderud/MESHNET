import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatChipsModule } from '@angular/material/chips';
import { MatMenuModule } from '@angular/material/menu';
import { DeploymentStatus } from '../../core/services/deployment.service';

@Component({
  selector: 'app-deployment-history',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule,
    MatMenuModule
  ],
  template: `
    <mat-card class="history-card">
      <mat-card-header>
        <mat-card-title>Deployment History</mat-card-title>
      </mat-card-header>
      <mat-card-content>
        <div class="history-list">
          <div class="history-empty" *ngIf="deployments.length === 0">
            <mat-icon>history</mat-icon>
            <p>No deployment history available</p>
          </div>
          
          <div class="history-item" *ngFor="let deployment of deployments">
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
                  <button mat-menu-item (click)="viewDetails.emit(deployment)">
                    <mat-icon>info</mat-icon>
                    <span>View Details</span>
                  </button>
                  <button mat-menu-item *ngIf="deployment.url" (click)="openUrl.emit(deployment)">
                    <mat-icon>open_in_new</mat-icon>
                    <span>Open URL</span>
                  </button>
                  <button mat-menu-item (click)="redeploy.emit(deployment)">
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
  `,
  styles: [`
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

    @media (max-width: 768px) {
      .history-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
      }
    }
  `]
})
export class DeploymentHistoryComponent {
  @Input() deployments: DeploymentStatus[] = [];
  @Output() viewDetails = new EventEmitter<DeploymentStatus>();
  @Output() openUrl = new EventEmitter<DeploymentStatus>();
  @Output() redeploy = new EventEmitter<DeploymentStatus>();

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
}