import { Component, inject, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subscription } from 'rxjs';
import { Router } from '@angular/router';

import { DeploymentService, DeploymentConfig, DeploymentStatus } from '../../core/services/deployment.service';
import { AnalyticsService } from '../../core/services/analytics.service';
import { DeploymentConfigComponent } from './deployment-config.component';
import { DeploymentStatusComponent } from './deployment-status.component';
import { DeploymentHistoryComponent } from './deployment-history.component';

@Component({
  selector: 'app-deployment',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatProgressBarModule,
    DeploymentConfigComponent,
    DeploymentStatusComponent,
    DeploymentHistoryComponent
  ],
  template: `
    <div class="deployment-container">
      <h1>Application Deployment</h1>
      
      <!-- Deployment Configuration -->
      <app-deployment-config
        [config]="deploymentConfig"
        [isDeploying]="isDeploying()"
        (deploy)="deployApplication($event)"
        (reset)="resetConfiguration()">
      </app-deployment-config>
      
      <!-- Current Deployment Status -->
      <app-deployment-status
        *ngIf="currentDeployment()"
        [deployment]="currentDeployment()!"
        (cancel)="cancelDeployment()">
      </app-deployment-status>
      
      <!-- Deployment History -->
      <app-deployment-history
        [deployments]="deploymentHistory()"
        (viewDetails)="viewDeploymentDetails($event)"
        (openUrl)="openDeploymentUrl($event)"
        (redeploy)="redeployApplication($event)">
      </app-deployment-history>
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

    @media (max-width: 768px) {
      .deployment-container {
        padding: 8px;
      }
    }
  `]
})
export class DeploymentComponent implements OnInit, OnDestroy {
  private deploymentService = inject(DeploymentService);
  private analyticsService = inject(AnalyticsService);
  private snackBar = inject(MatSnackBar);
  private router = inject(Router);

  // Reactive state from service
  isDeploying = this.deploymentService.isDeploying;
  currentDeployment = this.deploymentService.currentDeployment;
  deploymentHistory = this.deploymentService.deploymentHistory;

  // Deployment configuration
  deploymentConfig: DeploymentConfig = {
    target: 'production',
    buildCommand: 'ng build --configuration production',
    outputDir: 'dist/emergency-mesh-network',
    environment: {
      NODE_ENV: 'production'
    },
    optimizations: {
      minify: true,
      treeshaking: true,
      compression: true,
      serviceWorker: true
    }
  };

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.setupEventListeners();
    this.analyticsService.trackPageView('deployment');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private setupEventListeners(): void {
    // Listen for deployment completion
    this.subscriptions.add(
      this.deploymentService.onDeploymentCompleted$.subscribe(deployment => {
        this.snackBar.open(
          `Deployment to ${deployment.target} completed successfully!`,
          'Close',
          { duration: 5000 }
        );
      })
    );

    // Listen for deployment failures
    this.subscriptions.add(
      this.deploymentService.onDeploymentFailed$.subscribe(deployment => {
        this.snackBar.open(
          `Deployment to ${deployment.target} failed: ${deployment.error}`,
          'Close',
          { duration: 5000 }
        );
      })
    );
  }

  async deployApplication(config: DeploymentConfig): Promise<void> {
    try {
      // Update configuration
      this.deploymentConfig = config;
      
      // Start deployment
      const deploymentId = await this.deploymentService.startDeployment(config);
      
      this.analyticsService.trackUserAction('deployment', 'start', config.target);
    } catch (error) {
      console.error('Failed to start deployment:', error);
      
      this.snackBar.open(
        'Failed to start deployment',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('deployment', 'Failed to start deployment', { error });
    }
  }

  cancelDeployment(): void {
    const cancelled = this.deploymentService.cancelDeployment();
    
    if (cancelled) {
      this.snackBar.open(
        'Deployment cancelled',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackUserAction('deployment', 'cancel');
    }
  }

  resetConfiguration(): void {
    this.deploymentConfig = {
      target: 'production',
      buildCommand: 'ng build --configuration production',
      outputDir: 'dist/emergency-mesh-network',
      environment: {
        NODE_ENV: 'production'
      },
      optimizations: {
        minify: true,
        treeshaking: true,
        compression: true,
        serviceWorker: true
      }
    };
    
    this.analyticsService.trackUserAction('deployment', 'reset_config');
  }

  viewDeploymentDetails(deployment: DeploymentStatus): void {
    // In a real implementation, this might navigate to a details page
    // For now, we'll just show the current deployment
    const currentDeployment = this.deploymentService.getDeploymentById(deployment.id);
    
    if (currentDeployment) {
      this.analyticsService.trackUserAction('deployment', 'view_details', deployment.id);
    }
  }

  openDeploymentUrl(deployment: DeploymentStatus): void {
    if (deployment.url) {
      window.open(deployment.url, '_blank');
      this.analyticsService.trackUserAction('deployment', 'open_url', deployment.id);
    }
  }

  async redeployApplication(deployment: DeploymentStatus): Promise<void> {
    try {
      // Start a new deployment with the same configuration
      const deploymentId = await this.deploymentService.startDeployment({
        target: deployment.target,
        buildCommand: this.deploymentConfig.buildCommand,
        outputDir: this.deploymentConfig.outputDir,
        environment: this.deploymentConfig.environment,
        optimizations: this.deploymentConfig.optimizations
      });
      
      this.analyticsService.trackUserAction('deployment', 'redeploy', deployment.target);
    } catch (error) {
      console.error('Failed to redeploy:', error);
      
      this.snackBar.open(
        'Failed to redeploy application',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('deployment', 'Failed to redeploy', { error });
    }
  }
}