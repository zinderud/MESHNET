import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { AnalyticsService } from './analytics.service';

export interface DeploymentConfig {
  target: 'production' | 'staging' | 'development';
  buildCommand: string;
  outputDir: string;
  environment: Record<string, string>;
  optimizations: {
    minify: boolean;
    treeshaking: boolean;
    compression: boolean;
    serviceWorker: boolean;
  };
  cdn?: {
    enabled: boolean;
    provider: string;
    domain?: string;
  };
}

export interface DeploymentStatus {
  id: string;
  status: 'pending' | 'building' | 'deploying' | 'success' | 'failed';
  target: string;
  startTime: number;
  endTime?: number;
  url?: string;
  error?: string;
  logs: string[];
  progress: number;
}

@Injectable({
  providedIn: 'root'
})
export class DeploymentService {
  private analyticsService = inject(AnalyticsService);

  // Signals for reactive deployment state
  private _deploymentConfig = signal<DeploymentConfig>({
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
  });

  private _currentDeployment = signal<DeploymentStatus | null>(null);
  private _deploymentHistory = signal<DeploymentStatus[]>([]);
  private _isDeploying = signal<boolean>(false);

  // Computed deployment indicators
  deploymentConfig = this._deploymentConfig.asReadonly();
  currentDeployment = this._currentDeployment.asReadonly();
  deploymentHistory = this._deploymentHistory.asReadonly();
  isDeploying = this._isDeploying.asReadonly();

  lastDeployment = computed(() => {
    const history = this._deploymentHistory();
    return history.length > 0 ? history[0] : null;
  });

  deploymentProgress = computed(() => {
    const current = this._currentDeployment();
    return current ? current.progress : 0;
  });

  // Deployment events
  private deploymentStarted$ = new Subject<DeploymentStatus>();
  private deploymentCompleted$ = new Subject<DeploymentStatus>();
  private deploymentFailed$ = new Subject<DeploymentStatus>();
  private deploymentProgress$ = new Subject<number>();

  constructor() {
    this.loadDeploymentHistory();
  }

  // Public API Methods
  async startDeployment(config?: Partial<DeploymentConfig>): Promise<string> {
    if (this._isDeploying()) {
      throw new Error('Deployment already in progress');
    }

    try {
      this._isDeploying.set(true);

      // Update config if provided
      if (config) {
        this._deploymentConfig.update(current => ({ ...current, ...config }));
      }

      // Create deployment status
      const deploymentId = this.generateDeploymentId();
      const deploymentStatus: DeploymentStatus = {
        id: deploymentId,
        status: 'pending',
        target: this._deploymentConfig().target,
        startTime: Date.now(),
        logs: [],
        progress: 0
      };

      this._currentDeployment.set(deploymentStatus);
      this.deploymentStarted$.next(deploymentStatus);
      this.analyticsService.trackEvent('deployment', 'started', this._deploymentConfig().target);

      // Start deployment process
      await this.runDeployment(deploymentStatus);

      return deploymentId;
    } catch (error) {
      this._isDeploying.set(false);
      this.analyticsService.trackError('deployment', 'Failed to start deployment', { error });
      throw error;
    }
  }

  cancelDeployment(): boolean {
    const current = this._currentDeployment();
    if (!current || current.status === 'success' || current.status === 'failed') {
      return false;
    }

    const updatedDeployment = {
      ...current,
      status: 'failed' as const,
      endTime: Date.now(),
      error: 'Deployment cancelled by user'
    };

    this._currentDeployment.set(updatedDeployment);
    this._isDeploying.set(false);

    // Add to history
    this.addToDeploymentHistory(updatedDeployment);
    this.deploymentFailed$.next(updatedDeployment);
    this.analyticsService.trackEvent('deployment', 'cancelled', updatedDeployment.target);

    return true;
  }

  getDeploymentById(deploymentId: string): DeploymentStatus | null {
    if (this._currentDeployment()?.id === deploymentId) {
      return this._currentDeployment();
    }

    return this._deploymentHistory().find(d => d.id === deploymentId) || null;
  }

  updateDeploymentConfig(config: Partial<DeploymentConfig>): void {
    this._deploymentConfig.update(current => ({ ...current, ...config }));
  }

  // Event Observables
  get onDeploymentStarted$(): Observable<DeploymentStatus> {
    return this.deploymentStarted$.asObservable();
  }

  get onDeploymentCompleted$(): Observable<DeploymentStatus> {
    return this.deploymentCompleted$.asObservable();
  }

  get onDeploymentFailed$(): Observable<DeploymentStatus> {
    return this.deploymentFailed$.asObservable();
  }

  get onDeploymentProgress$(): Observable<number> {
    return this.deploymentProgress$.asObservable();
  }

  // Private Methods
  private async runDeployment(deployment: DeploymentStatus): Promise<void> {
    try {
      // Update status to building
      deployment.status = 'building';
      deployment.logs.push(`[${new Date().toISOString()}] Starting build process...`);
      deployment.progress = 10;
      this._currentDeployment.set({ ...deployment });
      this.deploymentProgress$.next(deployment.progress);

      // Simulate build process
      await this.simulateBuildProcess(deployment);

      // Update status to deploying
      deployment.status = 'deploying';
      deployment.logs.push(`[${new Date().toISOString()}] Build completed. Starting deployment...`);
      deployment.progress = 60;
      this._currentDeployment.set({ ...deployment });
      this.deploymentProgress$.next(deployment.progress);

      // Simulate deployment process
      await this.simulateDeployProcess(deployment);

      // Update status to success
      deployment.status = 'success';
      deployment.endTime = Date.now();
      deployment.url = this.getDeploymentUrl(deployment);
      deployment.logs.push(`[${new Date().toISOString()}] Deployment completed successfully.`);
      deployment.progress = 100;
      this._currentDeployment.set({ ...deployment });
      this.deploymentProgress$.next(deployment.progress);

      // Add to history
      this.addToDeploymentHistory(deployment);
      this.deploymentCompleted$.next(deployment);
      this.analyticsService.trackEvent('deployment', 'completed', deployment.target);
    } catch (error) {
      // Update status to failed
      deployment.status = 'failed';
      deployment.endTime = Date.now();
      deployment.error = error.message || 'Unknown error occurred during deployment';
      deployment.logs.push(`[${new Date().toISOString()}] Deployment failed: ${deployment.error}`);
      this._currentDeployment.set({ ...deployment });

      // Add to history
      this.addToDeploymentHistory(deployment);
      this.deploymentFailed$.next(deployment);
      this.analyticsService.trackError('deployment', 'Deployment failed', { error });
    } finally {
      this._isDeploying.set(false);
    }
  }

  private async simulateBuildProcess(deployment: DeploymentStatus): Promise<void> {
    // Simulate build steps
    const buildSteps = [
      { message: 'Installing dependencies...', progress: 20 },
      { message: 'Compiling TypeScript...', progress: 30 },
      { message: 'Bundling modules...', progress: 40 },
      { message: 'Optimizing assets...', progress: 50 }
    ];

    for (const step of buildSteps) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      deployment.logs.push(`[${new Date().toISOString()}] ${step.message}`);
      deployment.progress = step.progress;
      this._currentDeployment.set({ ...deployment });
      this.deploymentProgress$.next(deployment.progress);
    }
  }

  private async simulateDeployProcess(deployment: DeploymentStatus): Promise<void> {
    // Simulate deployment steps
    const deploySteps = [
      { message: 'Uploading assets...', progress: 70 },
      { message: 'Configuring CDN...', progress: 80 },
      { message: 'Setting up service worker...', progress: 90 },
      { message: 'Finalizing deployment...', progress: 95 }
    ];

    for (const step of deploySteps) {
      await new Promise(resolve => setTimeout(resolve, 1000));
      deployment.logs.push(`[${new Date().toISOString()}] ${step.message}`);
      deployment.progress = step.progress;
      this._currentDeployment.set({ ...deployment });
      this.deploymentProgress$.next(deployment.progress);
    }
  }

  private getDeploymentUrl(deployment: DeploymentStatus): string {
    const config = this._deploymentConfig();
    
    switch (deployment.target) {
      case 'production':
        return config.cdn?.enabled && config.cdn.domain 
          ? `https://${config.cdn.domain}` 
          : 'https://emergency-mesh-network.app';
      case 'staging':
        return 'https://staging.emergency-mesh-network.app';
      case 'development':
        return 'https://dev.emergency-mesh-network.app';
      default:
        return 'https://emergency-mesh-network.app';
    }
  }

  private addToDeploymentHistory(deployment: DeploymentStatus): void {
    const history = this._deploymentHistory();
    this._deploymentHistory.set([deployment, ...history].slice(0, 10));
    this.saveDeploymentHistory();
  }

  private loadDeploymentHistory(): void {
    try {
      const savedHistory = localStorage.getItem('deployment_history');
      if (savedHistory) {
        this._deploymentHistory.set(JSON.parse(savedHistory));
      }
    } catch (error) {
      console.error('Failed to load deployment history:', error);
    }
  }

  private saveDeploymentHistory(): void {
    try {
      localStorage.setItem('deployment_history', JSON.stringify(this._deploymentHistory()));
    } catch (error) {
      console.error('Failed to save deployment history:', error);
    }
  }

  private generateDeploymentId(): string {
    return `deploy_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}