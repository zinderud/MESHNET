import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar } from '@angular/material/snack-bar';

import { BlockchainService } from '../../core/services/blockchain.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-transaction-creator',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule
  ],
  template: `
    <mat-card class="transaction-card">
      <mat-card-header>
        <mat-card-title>Create Transaction</mat-card-title>
      </mat-card-header>
      <mat-card-content>
        <form (ngSubmit)="createTransaction()" #transactionForm="ngForm">
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Transaction Type</mat-label>
            <mat-select [(ngModel)]="transactionType" name="type" required>
              <mat-option value="message">Message</mat-option>
              <mat-option value="emergency">Emergency</mat-option>
              <mat-option value="location">Location</mat-option>
              <mat-option value="network">Network</mat-option>
              <mat-option value="system">System</mat-option>
            </mat-select>
          </mat-form-field>
          
          <mat-form-field appearance="outline" class="full-width">
            <mat-label>Recipient (Optional)</mat-label>
            <input matInput [(ngModel)]="recipient" name="recipient" placeholder="Leave blank for broadcast">
          </mat-form-field>
          
          <div [ngSwitch]="transactionType">
            <!-- Message Transaction -->
            <div *ngSwitchCase="'message'">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Message</mat-label>
                <textarea matInput [(ngModel)]="messageData" name="message" rows="4" required></textarea>
              </mat-form-field>
            </div>
            
            <!-- Emergency Transaction -->
            <div *ngSwitchCase="'emergency'">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Emergency Type</mat-label>
                <mat-select [(ngModel)]="emergencyData.type" name="emergencyType" required>
                  <mat-option value="medical">Medical</mat-option>
                  <mat-option value="fire">Fire</mat-option>
                  <mat-option value="police">Police</mat-option>
                  <mat-option value="natural_disaster">Natural Disaster</mat-option>
                  <mat-option value="other">Other</mat-option>
                </mat-select>
              </mat-form-field>
              
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Severity</mat-label>
                <mat-select [(ngModel)]="emergencyData.severity" name="emergencySeverity" required>
                  <mat-option value="low">Low</mat-option>
                  <mat-option value="medium">Medium</mat-option>
                  <mat-option value="high">High</mat-option>
                  <mat-option value="critical">Critical</mat-option>
                </mat-select>
              </mat-form-field>
              
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Description</mat-label>
                <textarea matInput [(ngModel)]="emergencyData.description" name="emergencyDescription" rows="3" required></textarea>
              </mat-form-field>
            </div>
            
            <!-- Location Transaction -->
            <div *ngSwitchCase="'location'">
              <div class="location-fields">
                <mat-form-field appearance="outline">
                  <mat-label>Latitude</mat-label>
                  <input matInput [(ngModel)]="locationData.latitude" name="latitude" type="number" step="0.000001" required>
                </mat-form-field>
                
                <mat-form-field appearance="outline">
                  <mat-label>Longitude</mat-label>
                  <input matInput [(ngModel)]="locationData.longitude" name="longitude" type="number" step="0.000001" required>
                </mat-form-field>
                
                <mat-form-field appearance="outline">
                  <mat-label>Accuracy (meters)</mat-label>
                  <input matInput [(ngModel)]="locationData.accuracy" name="accuracy" type="number" required>
                </mat-form-field>
              </div>
              
              <button type="button" mat-button color="primary" (click)="getCurrentLocation()">
                <mat-icon>my_location</mat-icon>
                Use Current Location
              </button>
            </div>
            
            <!-- Network Transaction -->
            <div *ngSwitchCase="'network'">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Network Event Type</mat-label>
                <mat-select [(ngModel)]="networkData.eventType" name="networkEventType" required>
                  <mat-option value="node_joined">Node Joined</mat-option>
                  <mat-option value="node_left">Node Left</mat-option>
                  <mat-option value="network_formed">Network Formed</mat-option>
                  <mat-option value="network_merged">Network Merged</mat-option>
                  <mat-option value="network_partitioned">Network Partitioned</mat-option>
                </mat-select>
              </mat-form-field>
              
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Network ID</mat-label>
                <input matInput [(ngModel)]="networkData.networkId" name="networkId" required>
              </mat-form-field>
              
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Details</mat-label>
                <textarea matInput [(ngModel)]="networkData.details" name="networkDetails" rows="3"></textarea>
              </mat-form-field>
            </div>
            
            <!-- System Transaction -->
            <div *ngSwitchCase="'system'">
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>System Event Type</mat-label>
                <mat-select [(ngModel)]="systemData.eventType" name="systemEventType" required>
                  <mat-option value="validator_registration">Validator Registration</mat-option>
                  <mat-option value="validator_deregistration">Validator Deregistration</mat-option>
                  <mat-option value="parameter_update">Parameter Update</mat-option>
                  <mat-option value="version_update">Version Update</mat-option>
                  <mat-option value="system_message">System Message</mat-option>
                </mat-select>
              </mat-form-field>
              
              <mat-form-field appearance="outline" class="full-width">
                <mat-label>Details</mat-label>
                <textarea matInput [(ngModel)]="systemData.details" name="systemDetails" rows="3" required></textarea>
              </mat-form-field>
            </div>
          </div>
          
          <div class="form-actions">
            <button mat-raised-button color="primary" type="submit" [disabled]="!transactionForm.form.valid || isCreating">
              <mat-icon>send</mat-icon>
              Create Transaction
            </button>
            
            <button mat-button type="button" (click)="resetForm()">
              <mat-icon>clear</mat-icon>
              Reset
            </button>
          </div>
        </form>
      </mat-card-content>
    </mat-card>
  `,
  styles: [`
    .transaction-card {
      max-width: 800px;
      margin: 0 auto 24px auto;
    }

    .full-width {
      width: 100%;
      margin-bottom: 16px;
    }

    .location-fields {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 16px;
    }

    .form-actions {
      display: flex;
      gap: 16px;
      margin-top: 24px;
    }

    @media (max-width: 768px) {
      .form-actions {
        flex-direction: column;
      }
      
      .form-actions button {
        width: 100%;
      }
    }
  `]
})
export class TransactionCreatorComponent implements OnInit {
  private blockchainService = inject(BlockchainService);
  private analyticsService = inject(AnalyticsService);
  private snackBar = inject(MatSnackBar);

  // Form fields
  transactionType: 'message' | 'emergency' | 'location' | 'network' | 'system' = 'message';
  recipient: string = '';
  messageData: string = '';
  emergencyData = {
    type: 'other',
    severity: 'medium',
    description: ''
  };
  locationData = {
    latitude: 0,
    longitude: 0,
    accuracy: 0
  };
  networkData = {
    eventType: 'node_joined',
    networkId: '',
    details: ''
  };
  systemData = {
    eventType: 'system_message',
    details: ''
  };

  isCreating = false;

  ngOnInit(): void {
    this.analyticsService.trackPageView('transaction_creator');
  }

  async createTransaction(): Promise<void> {
    this.isCreating = true;

    try {
      let transactionData: any;
      
      // Prepare transaction data based on type
      switch (this.transactionType) {
        case 'message':
          transactionData = { message: this.messageData };
          break;
        case 'emergency':
          transactionData = this.emergencyData;
          break;
        case 'location':
          transactionData = this.locationData;
          break;
        case 'network':
          transactionData = this.networkData;
          break;
        case 'system':
          transactionData = this.systemData;
          break;
      }
      
      // Create transaction
      const transactionId = await this.blockchainService.addTransaction(
        this.transactionType,
        transactionData,
        this.recipient || undefined
      );
      
      this.snackBar.open(
        'Transaction created successfully',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackUserAction('blockchain', 'create_transaction', this.transactionType);
      
      // Reset form
      this.resetForm();
    } catch (error) {
      console.error('Failed to create transaction:', error);
      
      this.snackBar.open(
        'Failed to create transaction',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('blockchain', 'Transaction creation failed', { error });
    } finally {
      this.isCreating = false;
    }
  }

  resetForm(): void {
    this.transactionType = 'message';
    this.recipient = '';
    this.messageData = '';
    this.emergencyData = {
      type: 'other',
      severity: 'medium',
      description: ''
    };
    this.locationData = {
      latitude: 0,
      longitude: 0,
      accuracy: 0
    };
    this.networkData = {
      eventType: 'node_joined',
      networkId: '',
      details: ''
    };
    this.systemData = {
      eventType: 'system_message',
      details: ''
    };
  }

  async getCurrentLocation(): Promise<void> {
    if (!navigator.geolocation) {
      this.snackBar.open(
        'Geolocation is not supported by your browser',
        'Close',
        { duration: 3000 }
      );
      return;
    }

    try {
      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 5000,
          maximumAge: 0
        });
      });

      this.locationData = {
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        accuracy: position.coords.accuracy
      };
    } catch (error) {
      console.error('Error getting location:', error);
      
      this.snackBar.open(
        'Failed to get current location',
        'Close',
        { duration: 3000 }
      );
    }
  }
}