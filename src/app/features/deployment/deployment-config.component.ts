import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { MatInputModule } from '@angular/material/input';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { DeploymentConfig } from '../../core/services/deployment.service';

@Component({
  selector: 'app-deployment-config',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatSelectModule,
    MatInputModule,
    MatSlideToggleModule
  ],
  template: `
    <mat-card class="config-card">
      <mat-card-header>
        <mat-card-title>Deployment Configuration</mat-card-title>
      </mat-card-header>
      <mat-card-content>
        <div class="config-form">
          <mat-form-field appearance="outline">
            <mat-label>Target Environment</mat-label>
            <mat-select [(ngModel)]="config.target">
              <mat-option value="production">Production</mat-option>
              <mat-option value="staging">Staging</mat-option>
              <mat-option value="development">Development</mat-option>
            </mat-select>
          </mat-form-field>
          
          <div class="optimization-toggles">
            <h4>Optimizations</h4>
            <div class="toggle-grid">
              <mat-slide-toggle [(ngModel)]="config.optimizations.minify">
                Minify
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="config.optimizations.treeshaking">
                Tree Shaking
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="config.optimizations.compression">
                Compression
              </mat-slide-toggle>
              
              <mat-slide-toggle [(ngModel)]="config.optimizations.serviceWorker">
                Service Worker
              </mat-slide-toggle>
            </div>
          </div>
          
          <div class="cdn-config">
            <h4>CDN Configuration</h4>
            <div class="cdn-toggle">
              <mat-slide-toggle [(ngModel)]="cdnEnabled" (change)="updateCdnConfig()">
                Enable CDN
              </mat-slide-toggle>
            </div>
            
            <mat-form-field appearance="outline" *ngIf="cdnEnabled">
              <mat-label>CDN Provider</mat-label>
              <mat-select [(ngModel)]="cdnProvider" (selectionChange)="updateCdnConfig()">
                <mat-option value="cloudflare">Cloudflare</mat-option>
                <mat-option value="akamai">Akamai</mat-option>
                <mat-option value="fastly">Fastly</mat-option>
              </mat-select>
            </mat-form-field>
            
            <mat-form-field appearance="outline" *ngIf="cdnEnabled">
              <mat-label>CDN Domain</mat-label>
              <input matInput [(ngModel)]="cdnDomain" (blur)="updateCdnConfig()" placeholder="cdn.example.com">
            </mat-form-field>
          </div>
        </div>
        
        <div class="deploy-actions">
          <button mat-raised-button color="primary" 
                  (click)="deploy.emit(config)"
                  [disabled]="isDeploying">
            <mat-icon>rocket_launch</mat-icon>
            Deploy to {{ config.target }}
          </button>
          
          <button mat-button (click)="reset.emit()">
            <mat-icon>refresh</mat-icon>
            Reset Configuration
          </button>
        </div>
      </mat-card-content>
    </mat-card>
  `,
  styles: [`
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

    @media (max-width: 768px) {
      .toggle-grid {
        grid-template-columns: 1fr;
      }
      
      .deploy-actions {
        flex-direction: column;
      }
      
      .deploy-actions button {
        width: 100%;
      }
    }
  `]
})
export class DeploymentConfigComponent {
  @Input() config!: DeploymentConfig;
  @Input() isDeploying = false;
  @Output() deploy = new EventEmitter<DeploymentConfig>();
  @Output() reset = new EventEmitter<void>();

  cdnEnabled = false;
  cdnProvider = 'cloudflare';
  cdnDomain = '';

  ngOnInit(): void {
    // Initialize CDN values from config
    this.cdnEnabled = !!this.config.cdn?.enabled;
    this.cdnProvider = this.config.cdn?.provider || 'cloudflare';
    this.cdnDomain = this.config.cdn?.domain || '';
  }

  updateCdnConfig(): void {
    if (this.cdnEnabled) {
      this.config.cdn = {
        enabled: true,
        provider: this.cdnProvider,
        domain: this.cdnDomain
      };
    } else {
      this.config.cdn = undefined;
    }
  }
}