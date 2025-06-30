import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTabsModule } from '@angular/material/tabs';
import { MatTableModule } from '@angular/material/table';
import { MatPaginatorModule, PageEvent } from '@angular/material/paginator';
import { MatChipsModule } from '@angular/material/chips';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatBadgeModule } from '@angular/material/badge';
import { Subscription } from 'rxjs';

import { BlockchainService, Block, Transaction } from '../../core/services/blockchain.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-blockchain-explorer',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatTabsModule,
    MatTableModule,
    MatPaginatorModule,
    MatChipsModule,
    MatExpansionModule,
    MatProgressBarModule,
    MatBadgeModule
  ],
  template: `
    <div class="blockchain-explorer-container">
      <h1>Blockchain Explorer</h1>
      
      <!-- Blockchain Overview -->
      <mat-card class="overview-card">
        <mat-card-header>
          <mat-card-title>Blockchain Overview</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="overview-stats">
            <div class="stat-item">
              <mat-icon class="stat-icon">account_tree</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ blockchainStats().blockCount }}</span>
                <span class="stat-label">Blocks</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">swap_horiz</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ blockchainStats().transactionCount }}</span>
                <span class="stat-label">Transactions</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">people</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ blockchainStats().validatorCount }}</span>
                <span class="stat-label">Validators</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">schedule</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ formatTime(blockchainStats().averageBlockTime) }}</span>
                <span class="stat-label">Avg Block Time</span>
              </div>
            </div>
          </div>
          
          <div class="validator-status">
            @if (isValidator()) {
              <div class="validator-badge active">
                <mat-icon>verified</mat-icon>
                <span>Validator Node</span>
                <span class="reputation">Reputation: {{ validatorReputation() }}</span>
              </div>
            } @else {
              <div class="validator-badge inactive">
                <mat-icon>verified_user</mat-icon>
                <span>Not a Validator</span>
                <button mat-button color="primary" (click)="becomeValidator()">
                  Become Validator
                </button>
              </div>
            }
          </div>
          
          <div class="sync-status">
            <div class="sync-indicator" [ngClass]="syncStatus()">
              <mat-icon>{{ getSyncIcon() }}</mat-icon>
              <span>{{ getSyncStatusText() }}</span>
            </div>
            
            <button mat-button color="primary" (click)="syncBlockchain()">
              <mat-icon>sync</mat-icon>
              Sync Blockchain
            </button>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Blockchain Explorer Tabs -->
      <mat-card class="explorer-card">
        <mat-card-content>
          <mat-tab-group>
            <!-- Blocks Tab -->
            <mat-tab label="Blocks">
              <div class="tab-content">
                <div class="blocks-list">
                  @for (block of paginatedBlocks(); track block.index) {
                    <mat-expansion-panel class="block-panel">
                      <mat-expansion-panel-header>
                        <mat-panel-title>
                          <div class="block-header">
                            <span class="block-index">Block #{{ block.index }}</span>
                            <span class="block-time">{{ block.timestamp | date:'medium' }}</span>
                          </div>
                        </mat-panel-title>
                        <mat-panel-description>
                          <div class="block-summary">
                            <span class="transaction-count" 
                                  [matBadge]="block.transactions.length" 
                                  matBadgeOverlap="false">
                              Transactions
                            </span>
                            <span class="validator">Validator: {{ formatAddress(block.validator) }}</span>
                          </div>
                        </mat-panel-description>
                      </mat-expansion-panel-header>
                      
                      <div class="block-details">
                        <div class="block-info">
                          <div class="info-item">
                            <span class="info-label">Hash:</span>
                            <span class="info-value hash">{{ block.hash }}</span>
                          </div>
                          <div class="info-item">
                            <span class="info-label">Previous Hash:</span>
                            <span class="info-value hash">{{ block.previousHash }}</span>
                          </div>
                          <div class="info-item">
                            <span class="info-label">Timestamp:</span>
                            <span class="info-value">{{ block.timestamp | date:'medium' }}</span>
                          </div>
                          <div class="info-item">
                            <span class="info-label">Validator:</span>
                            <span class="info-value">{{ formatAddress(block.validator) }}</span>
                          </div>
                        </div>
                        
                        <div class="transactions-table">
                          <h4>Transactions ({{ block.transactions.length }})</h4>
                          @if (block.transactions.length > 0) {
                            <table>
                              <thead>
                                <tr>
                                  <th>ID</th>
                                  <th>Type</th>
                                  <th>Sender</th>
                                  <th>Recipient</th>
                                  <th>Timestamp</th>
                                </tr>
                              </thead>
                              <tbody>
                                @for (tx of block.transactions; track tx.id) {
                                  <tr>
                                    <td>{{ formatAddress(tx.id) }}</td>
                                    <td>
                                      <mat-chip [ngClass]="getTransactionTypeClass(tx.type)">
                                        {{ tx.type }}
                                      </mat-chip>
                                    </td>
                                    <td>{{ formatAddress(tx.sender) }}</td>
                                    <td>{{ tx.recipient ? formatAddress(tx.recipient) : '-' }}</td>
                                    <td>{{ tx.timestamp | date:'short' }}</td>
                                  </tr>
                                }
                              </tbody>
                            </table>
                          } @else {
                            <div class="no-transactions">
                              <p>No transactions in this block</p>
                            </div>
                          }
                        </div>
                      </div>
                    </mat-expansion-panel>
                  }
                </div>
                
                <mat-paginator
                  [length]="blockCount()"
                  [pageSize]="pageSize"
                  [pageSizeOptions]="[5, 10, 25, 100]"
                  (page)="onPageChange($event)">
                </mat-paginator>
              </div>
            </mat-tab>
            
            <!-- Transactions Tab -->
            <mat-tab label="Transactions">
              <div class="tab-content">
                <div class="transactions-list">
                  @for (tx of paginatedTransactions(); track tx.id) {
                    <mat-card class="transaction-card" [ngClass]="getTransactionTypeClass(tx.type)">
                      <mat-card-content>
                        <div class="transaction-header">
                          <div class="transaction-info">
                            <mat-chip [ngClass]="getTransactionTypeClass(tx.type)">
                              {{ tx.type }}
                            </mat-chip>
                            <span class="transaction-id">{{ formatAddress(tx.id) }}</span>
                          </div>
                          <span class="transaction-time">{{ tx.timestamp | date:'medium' }}</span>
                        </div>
                        
                        <div class="transaction-details">
                          <div class="detail-item">
                            <span class="detail-label">Sender:</span>
                            <span class="detail-value">{{ formatAddress(tx.sender) }}</span>
                          </div>
                          
                          @if (tx.recipient) {
                            <div class="detail-item">
                              <span class="detail-label">Recipient:</span>
                              <span class="detail-value">{{ formatAddress(tx.recipient) }}</span>
                            </div>
                          }
                          
                          <div class="detail-item">
                            <span class="detail-label">Data:</span>
                            <span class="detail-value">{{ formatTransactionData(tx.data) }}</span>
                          </div>
                        </div>
                      </mat-card-content>
                    </mat-card>
                  }
                </div>
                
                <mat-paginator
                  [length]="transactionCount()"
                  [pageSize]="txPageSize"
                  [pageSizeOptions]="[5, 10, 25, 100]"
                  (page)="onTxPageChange($event)">
                </mat-paginator>
              </div>
            </mat-tab>
            
            <!-- Validators Tab -->
            <mat-tab label="Validators">
              <div class="tab-content">
                <div class="validators-list">
                  @if (validators().length > 0) {
                    @for (validator of validators(); track validator.id) {
                      <mat-card class="validator-card">
                        <mat-card-content>
                          <div class="validator-header">
                            <mat-icon>verified_user</mat-icon>
                            <div class="validator-info">
                              <span class="validator-id">{{ formatAddress(validator.id) }}</span>
                              <div class="reputation-bar">
                                <mat-progress-bar mode="determinate" 
                                                  [value]="validator.reputation"
                                                  [color]="getReputationColor(validator.reputation)">
                                </mat-progress-bar>
                                <span class="reputation-value">{{ validator.reputation }}%</span>
                              </div>
                            </div>
                          </div>
                          
                          <div class="validator-stats">
                            <div class="stat-item">
                              <span class="stat-label">Blocks Validated:</span>
                              <span class="stat-value">{{ getValidatorBlockCount(validator.id) }}</span>
                            </div>
                            <div class="stat-item">
                              <span class="stat-label">Last Active:</span>
                              <span class="stat-value">{{ getValidatorLastActive(validator.id) | date:'short' }}</span>
                            </div>
                          </div>
                        </mat-card-content>
                      </mat-card>
                    }
                  } @else {
                    <div class="no-validators">
                      <mat-icon>people_outline</mat-icon>
                      <p>No validators registered</p>
                    </div>
                  }
                </div>
              </div>
            </mat-tab>
          </mat-tab-group>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .blockchain-explorer-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 16px;
    }

    h1 {
      text-align: center;
      margin-bottom: 24px;
      color: #333;
    }

    .overview-card {
      margin-bottom: 24px;
      background: linear-gradient(135deg, #1a237e, #283593);
      color: white;
    }

    .overview-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }

    .stat-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 8px;
    }

    .stat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
    }

    .stat-info {
      display: flex;
      flex-direction: column;
    }

    .stat-value {
      font-size: 24px;
      font-weight: bold;
    }

    .stat-label {
      font-size: 14px;
      opacity: 0.8;
    }

    .validator-status {
      margin-bottom: 16px;
    }

    .validator-badge {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px;
      border-radius: 8px;
    }

    .validator-badge.active {
      background: rgba(76, 175, 80, 0.2);
    }

    .validator-badge.inactive {
      background: rgba(255, 255, 255, 0.1);
    }

    .validator-badge mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .validator-badge .reputation {
      margin-left: auto;
      font-weight: bold;
    }

    .sync-status {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 16px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 8px;
    }

    .sync-indicator {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .sync-indicator.synced {
      color: #4caf50;
    }

    .sync-indicator.syncing {
      color: #ff9800;
    }

    .sync-indicator.error {
      color: #f44336;
    }

    .explorer-card {
      margin-bottom: 24px;
    }

    .tab-content {
      padding: 16px 0;
    }

    .blocks-list {
      margin-bottom: 16px;
    }

    .block-panel {
      margin-bottom: 8px;
    }

    .block-header {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .block-index {
      font-weight: bold;
    }

    .block-time {
      font-size: 12px;
      color: #666;
    }

    .block-summary {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .transaction-count {
      font-size: 14px;
    }

    .validator {
      font-size: 14px;
      color: #666;
    }

    .block-details {
      padding: 16px 0;
    }

    .block-info {
      margin-bottom: 24px;
    }

    .info-item {
      display: flex;
      margin-bottom: 8px;
    }

    .info-label {
      font-weight: bold;
      width: 120px;
      flex-shrink: 0;
    }

    .info-value {
      word-break: break-all;
    }

    .info-value.hash {
      font-family: monospace;
      font-size: 14px;
    }

    .transactions-table {
      overflow-x: auto;
    }

    .transactions-table h4 {
      margin: 0 0 16px 0;
      font-size: 16px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th, td {
      padding: 12px;
      text-align: left;
      border-bottom: 1px solid #eee;
    }

    th {
      font-weight: bold;
      background-color: #f5f5f5;
    }

    .no-transactions {
      padding: 24px;
      text-align: center;
      color: #666;
    }

    .transactions-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
      margin-bottom: 16px;
    }

    .transaction-card {
      border-left: 4px solid #2196f3;
    }

    .transaction-card.message {
      border-left-color: #2196f3;
    }

    .transaction-card.emergency {
      border-left-color: #f44336;
    }

    .transaction-card.location {
      border-left-color: #4caf50;
    }

    .transaction-card.network {
      border-left-color: #ff9800;
    }

    .transaction-card.system {
      border-left-color: #9c27b0;
    }

    .transaction-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    }

    .transaction-info {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .transaction-id {
      font-family: monospace;
      font-size: 14px;
    }

    .transaction-time {
      font-size: 12px;
      color: #666;
    }

    .transaction-details {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }

    .detail-item {
      display: flex;
      flex-direction: column;
    }

    .detail-label {
      font-size: 12px;
      color: #666;
    }

    .detail-value {
      font-size: 14px;
      word-break: break-all;
    }

    mat-chip.message {
      background-color: #2196f3;
      color: white;
    }

    mat-chip.emergency {
      background-color: #f44336;
      color: white;
    }

    mat-chip.location {
      background-color: #4caf50;
      color: white;
    }

    mat-chip.network {
      background-color: #ff9800;
      color: white;
    }

    mat-chip.system {
      background-color: #9c27b0;
      color: white;
    }

    .validators-list {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 16px;
    }

    .validator-card {
      border-left: 4px solid #4caf50;
    }

    .validator-header {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 16px;
    }

    .validator-header mat-icon {
      color: #4caf50;
    }

    .validator-info {
      flex: 1;
    }

    .validator-id {
      font-family: monospace;
      font-size: 14px;
      margin-bottom: 8px;
      display: block;
    }

    .reputation-bar {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    .reputation-bar mat-progress-bar {
      flex: 1;
    }

    .reputation-value {
      font-size: 14px;
      font-weight: bold;
    }

    .validator-stats {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    .stat-item {
      display: flex;
      flex-direction: column;
    }

    .stat-label {
      font-size: 12px;
      color: #666;
    }

    .stat-value {
      font-size: 16px;
      font-weight: bold;
    }

    .no-validators {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .no-validators mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    @media (max-width: 768px) {
      .blockchain-explorer-container {
        padding: 8px;
      }
      
      .overview-stats {
        grid-template-columns: 1fr;
      }
      
      .validator-stats {
        grid-template-columns: 1fr;
      }
      
      .validators-list {
        grid-template-columns: 1fr;
      }
    }
  `]
})
export class BlockchainExplorerComponent implements OnInit, OnDestroy {
  private blockchainService = inject(BlockchainService);
  private analyticsService = inject(AnalyticsService);

  // Pagination
  pageIndex = 0;
  pageSize = 5;
  txPageIndex = 0;
  txPageSize = 10;

  // Reactive state from service
  blockchainStats = this.blockchainService.blockchainStats;
  isValidator = this.blockchainService.isValidator;
  validatorReputation = this.blockchainService.validatorReputation;
  syncStatus = this.blockchainService.syncStatus;
  blockCount = this.blockchainService.blockCount;

  // Computed properties
  blocks = computed(() => {
    const chain = this.blockchainService.blockchainState().chain;
    return [...chain].reverse(); // Show newest blocks first
  });

  paginatedBlocks = computed(() => {
    const start = this.pageIndex * this.pageSize;
    const end = start + this.pageSize;
    return this.blocks().slice(start, end);
  });

  transactions = computed(() => {
    const allTransactions: Transaction[] = [];
    
    // Add transactions from blocks
    for (const block of this.blockchainService.blockchainState().chain) {
      allTransactions.push(...block.transactions);
    }
    
    // Add pending transactions
    allTransactions.push(...this.blockchainService.blockchainState().pendingTransactions);
    
    // Sort by timestamp (newest first)
    return allTransactions.sort((a, b) => b.timestamp - a.timestamp);
  });

  transactionCount = computed(() => this.transactions().length);

  paginatedTransactions = computed(() => {
    const start = this.txPageIndex * this.txPageSize;
    const end = start + this.txPageSize;
    return this.transactions().slice(start, end);
  });

  validators = computed(() => {
    const validatorsMap = this.blockchainService.blockchainState().validators;
    return Array.from(validatorsMap.entries()).map(([id, reputation]) => ({
      id,
      reputation
    }));
  });

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.setupEventListeners();
    this.analyticsService.trackPageView('blockchain_explorer');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private setupEventListeners(): void {
    // Listen for new blocks
    this.subscriptions.add(
      this.blockchainService.onBlockAdded$.subscribe(block => {
        // Reset to first page when new blocks are added
        this.pageIndex = 0;
      })
    );

    // Listen for new transactions
    this.subscriptions.add(
      this.blockchainService.onTransactionAdded$.subscribe(transaction => {
        // Reset to first page when new transactions are added
        this.txPageIndex = 0;
      })
    );
  }

  // UI Event Handlers
  onPageChange(event: PageEvent): void {
    this.pageIndex = event.pageIndex;
    this.pageSize = event.pageSize;
  }

  onTxPageChange(event: PageEvent): void {
    this.txPageIndex = event.pageIndex;
    this.txPageSize = event.pageSize;
  }

  async becomeValidator(): Promise<void> {
    try {
      const success = await this.blockchainService.becomeValidator();
      
      if (success) {
        this.analyticsService.trackUserAction('blockchain', 'become_validator', { status: 'success' });
      } else {
        this.analyticsService.trackUserAction('blockchain', 'become_validator', { status: 'failed' });
      }
    } catch (error) {
      console.error('Failed to become validator:', error);
      this.analyticsService.trackError('blockchain', 'Failed to become validator', { error });
    }
  }

  async syncBlockchain(): Promise<void> {
    try {
      // This would trigger a blockchain sync
      // For demo purposes, we'll just log it
      console.log('Syncing blockchain...');
      this.analyticsService.trackUserAction('blockchain', 'sync');
    } catch (error) {
      console.error('Failed to sync blockchain:', error);
      this.analyticsService.trackError('blockchain', 'Failed to sync blockchain', { error });
    }
  }

  // Helper Methods
  formatAddress(address: string): string {
    if (!address) return '';
    if (address.length <= 12) return address;
    return `${address.substring(0, 6)}...${address.substring(address.length - 6)}`;
  }

  formatTime(milliseconds: number): string {
    if (!milliseconds) return '0s';
    
    const seconds = Math.floor(milliseconds / 1000);
    if (seconds < 60) return `${seconds}s`;
    
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}m ${remainingSeconds}s`;
  }

  formatTransactionData(data: any): string {
    if (!data) return '';
    
    try {
      if (typeof data === 'object') {
        // Format based on transaction type
        if (data.message) {
          return `Message: ${data.message.substring(0, 50)}${data.message.length > 50 ? '...' : ''}`;
        } else if (data.location) {
          return `Location: ${data.location.latitude.toFixed(6)}, ${data.location.longitude.toFixed(6)}`;
        } else {
          return JSON.stringify(data).substring(0, 50) + (JSON.stringify(data).length > 50 ? '...' : '');
        }
      } else {
        return String(data).substring(0, 50) + (String(data).length > 50 ? '...' : '');
      }
    } catch (error) {
      return 'Error formatting data';
    }
  }

  getTransactionTypeClass(type: string): string {
    return type;
  }

  getReputationColor(reputation: number): 'primary' | 'accent' | 'warn' {
    if (reputation >= 80) return 'primary';
    if (reputation >= 50) return 'accent';
    return 'warn';
  }

  getSyncIcon(): string {
    switch (this.syncStatus()) {
      case 'synced': return 'check_circle';
      case 'syncing': return 'sync';
      case 'error': return 'error';
      default: return 'help';
    }
  }

  getSyncStatusText(): string {
    switch (this.syncStatus()) {
      case 'synced': return 'Blockchain Synced';
      case 'syncing': return 'Syncing Blockchain...';
      case 'error': return 'Sync Error';
      default: return 'Unknown Status';
    }
  }

  getValidatorBlockCount(validatorId: string): number {
    return this.blockchainService.blockchainState().chain.filter(
      block => block.validator === validatorId
    ).length;
  }

  getValidatorLastActive(validatorId: string): number {
    const blocks = this.blockchainService.blockchainState().chain.filter(
      block => block.validator === validatorId
    );
    
    if (blocks.length === 0) return 0;
    
    // Return timestamp of most recent block
    return Math.max(...blocks.map(block => block.timestamp));
  }
}