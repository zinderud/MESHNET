import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatTabsModule } from '@angular/material/tabs';
import { MatChipsModule } from '@angular/material/chips';
import { MatBadgeModule } from '@angular/material/badge';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatExpansionModule } from '@angular/material/expansion';
import { MatDividerModule } from '@angular/material/divider';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Subscription } from 'rxjs';

import { P2PDiscoveryService, DiscoveredPeer } from '../../core/services/p2p-discovery.service';
import { WebrtcService } from '../../core/services/webrtc.service';
import { AnalyticsService } from '../../core/services/analytics.service';

@Component({
  selector: 'app-p2p-network-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatTabsModule,
    MatChipsModule,
    MatBadgeModule,
    MatProgressBarModule,
    MatExpansionModule,
    MatDividerModule
  ],
  template: `
    <div class="p2p-dashboard-container">
      <h1>P2P Network Dashboard</h1>
      
      <!-- Network Overview -->
      <mat-card class="overview-card">
        <mat-card-header>
          <mat-card-title>Network Overview</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="overview-stats">
            <div class="stat-item">
              <mat-icon class="stat-icon">devices</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ discoveredPeerCount() }}</span>
                <span class="stat-label">Discovered Peers</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon" [ngClass]="{'connected': connectedPeerCount() > 0}">
                {{ connectedPeerCount() > 0 ? 'link' : 'link_off' }}
              </mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ connectedPeerCount() }}</span>
                <span class="stat-label">Connected Peers</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">speed</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ connectionQuality() }}</span>
                <span class="stat-label">Connection Quality</span>
              </div>
            </div>
            
            <div class="stat-item">
              <mat-icon class="stat-icon">swap_horiz</mat-icon>
              <div class="stat-info">
                <span class="stat-value">{{ formatBytes(dataTransferred()) }}</span>
                <span class="stat-label">Data Transferred</span>
              </div>
            </div>
          </div>
          
          <div class="discovery-actions">
            <button mat-raised-button color="primary" 
                    (click)="startDiscovery()"
                    [disabled]="isDiscovering()">
              <mat-icon>search</mat-icon>
              {{ isDiscovering() ? 'Discovering...' : 'Discover Peers' }}
            </button>
            
            <button mat-raised-button color="accent" 
                    (click)="connectToMultiplePeers()"
                    [disabled]="isDiscovering() || discoveredPeerCount() === 0">
              <mat-icon>link</mat-icon>
              Connect to Peers
            </button>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- P2P Network Tabs -->
      <mat-card class="network-card">
        <mat-card-content>
          <mat-tab-group>
            <!-- Discovered Peers Tab -->
            <mat-tab label="Discovered Peers">
              <div class="tab-content">
                <div class="peers-list">
                  @if (discoveredPeers().length === 0) {
                    <div class="empty-state">
                      <mat-icon>devices_other</mat-icon>
                      <h3>No Peers Discovered</h3>
                      <p>Click "Discover Peers" to find available peers</p>
                    </div>
                  } @else {
                    @for (peer of discoveredPeers(); track peer.id) {
                      <mat-expansion-panel class="peer-panel">
                        <mat-expansion-panel-header>
                          <mat-panel-title>
                            <div class="peer-header">
                              <mat-icon [ngClass]="getPeerTypeClass(peer.type)">
                                {{ getPeerTypeIcon(peer.type) }}
                              </mat-icon>
                              <span class="peer-name">{{ getPeerName(peer) }}</span>
                            </div>
                          </mat-panel-title>
                          <mat-panel-description>
                            <div class="peer-status">
                              <span class="peer-id">{{ formatPeerId(peer.id) }}</span>
                              <span class="peer-time">Last seen: {{ getLastSeenTime(peer) }}</span>
                              <mat-chip [ngClass]="isConnected(peer.id) ? 'connected' : 'disconnected'">
                                {{ isConnected(peer.id) ? 'Connected' : 'Disconnected' }}
                              </mat-chip>
                            </div>
                          </mat-panel-description>
                        </mat-expansion-panel-header>
                        
                        <div class="peer-details">
                          <div class="peer-info">
                            <div class="info-item">
                              <span class="info-label">Peer ID:</span>
                              <span class="info-value">{{ peer.id }}</span>
                            </div>
                            
                            <div class="info-item">
                              <span class="info-label">Discovery Method:</span>
                              <span class="info-value">{{ getPeerTypeText(peer.type) }}</span>
                            </div>
                            
                            @if (peer.address) {
                              <div class="info-item">
                                <span class="info-label">Address:</span>
                                <span class="info-value">{{ peer.address }}{{ peer.port ? ':' + peer.port : '' }}</span>
                              </div>
                            }
                            
                            <div class="info-item">
                              <span class="info-label">Last Seen:</span>
                              <span class="info-value">{{ peer.lastSeen | date:'medium' }}</span>
                            </div>
                          </div>
                          
                          @if (peer.metadata) {
                            <mat-divider></mat-divider>
                            
                            <div class="peer-metadata">
                              <h4>Metadata</h4>
                              
                              @if (peer.metadata.deviceType) {
                                <div class="info-item">
                                  <span class="info-label">Device Type:</span>
                                  <span class="info-value">{{ peer.metadata.deviceType }}</span>
                                </div>
                              }
                              
                              @if (peer.metadata.capabilities) {
                                <div class="info-item">
                                  <span class="info-label">Capabilities:</span>
                                  <div class="capabilities-list">
                                    @for (capability of peer.metadata.capabilities; track capability) {
                                      <mat-chip>{{ capability }}</mat-chip>
                                    }
                                  </div>
                                </div>
                              }
                              
                              @if (peer.metadata.version) {
                                <div class="info-item">
                                  <span class="info-label">Version:</span>
                                  <span class="info-value">{{ peer.metadata.version }}</span>
                                </div>
                              }
                            </div>
                          }
                          
                          <div class="peer-actions">
                            @if (isConnected(peer.id)) {
                              <button mat-raised-button color="warn" (click)="disconnectFromPeer(peer.id)">
                                <mat-icon>link_off</mat-icon>
                                Disconnect
                              </button>
                              
                              <button mat-button (click)="sendTestMessage(peer.id)">
                                <mat-icon>send</mat-icon>
                                Send Test Message
                              </button>
                            } @else {
                              <button mat-raised-button color="primary" (click)="connectToPeer(peer.id)">
                                <mat-icon>link</mat-icon>
                                Connect
                              </button>
                            }
                            
                            <button mat-button color="warn" (click)="removePeer(peer.id)">
                              <mat-icon>delete</mat-icon>
                              Remove
                            </button>
                          </div>
                        </div>
                      </mat-expansion-panel>
                    }
                  }
                </div>
              </div>
            </mat-tab>
            
            <!-- Connected Peers Tab -->
            <mat-tab label="Connected Peers">
              <div class="tab-content">
                <div class="connected-peers-list">
                  @if (connectedPeers().length === 0) {
                    <div class="empty-state">
                      <mat-icon>link_off</mat-icon>
                      <h3>No Connected Peers</h3>
                      <p>Connect to peers to see them here</p>
                    </div>
                  } @else {
                    @for (peer of connectedPeers(); track peer.id) {
                      <mat-card class="connected-peer-card">
                        <mat-card-content>
                          <div class="connected-peer-header">
                            <div class="peer-identity">
                              <mat-icon>person</mat-icon>
                              <div class="peer-info">
                                <h3>{{ peer.name }}</h3>
                                <span class="peer-id">{{ formatPeerId(peer.id) }}</span>
                              </div>
                            </div>
                            
                            <div class="connection-quality">
                              <div class="quality-indicator">
                                <mat-icon [ngClass]="getQualityClass(peer.signalStrength)">
                                  {{ getQualityIcon(peer.signalStrength) }}
                                </mat-icon>
                                <span>{{ getQualityText(peer.signalStrength) }}</span>
                              </div>
                              <mat-progress-bar mode="determinate" 
                                                [value]="peer.signalStrength"
                                                [color]="getQualityColor(peer.signalStrength)">
                              </mat-progress-bar>
                            </div>
                          </div>
                          
                          <div class="connection-stats">
                            <div class="stat-item">
                              <span class="stat-label">Device Type:</span>
                              <span class="stat-value">{{ peer.deviceType }}</span>
                            </div>
                            
                            <div class="stat-item">
                              <span class="stat-label">Connected Since:</span>
                              <span class="stat-value">{{ peer.lastSeen | date:'short' }}</span>
                            </div>
                            
                            <div class="stat-item">
                              <span class="stat-label">Data Exchanged:</span>
                              <span class="stat-value">{{ formatBytes(getDataExchanged(peer.id)) }}</span>
                            </div>
                          </div>
                          
                          <div class="peer-capabilities">
                            <h4>Capabilities</h4>
                            <div class="capabilities-list">
                              @for (capability of peer.capabilities; track capability) {
                                <mat-chip>{{ capability }}</mat-chip>
                              }
                            </div>
                          </div>
                          
                          <div class="connected-peer-actions">
                            <button mat-raised-button color="primary" (click)="sendTestMessage(peer.id)">
                              <mat-icon>send</mat-icon>
                              Send Message
                            </button>
                            
                            <button mat-raised-button color="warn" (click)="disconnectFromPeer(peer.id)">
                              <mat-icon>link_off</mat-icon>
                              Disconnect
                            </button>
                          </div>
                        </mat-card-content>
                      </mat-card>
                    }
                  }
                </div>
              </div>
            </mat-tab>
            
            <!-- Network Topology Tab -->
            <mat-tab label="Network Topology">
              <div class="tab-content">
                <div class="topology-container">
                  <div class="topology-placeholder">
                    <mat-icon>account_tree</mat-icon>
                    <h3>Network Topology Visualization</h3>
                    <p>Visual representation of the P2P network will be displayed here</p>
                  </div>
                </div>
              </div>
            </mat-tab>
          </mat-tab-group>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styles: [`
    .p2p-dashboard-container {
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
      background: linear-gradient(135deg, #3f51b5, #5c6bc0);
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

    .stat-icon.connected {
      color: #4caf50;
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

    .discovery-actions {
      display: flex;
      gap: 16px;
      flex-wrap: wrap;
    }

    .network-card {
      margin-bottom: 24px;
    }

    .tab-content {
      padding: 16px 0;
    }

    .empty-state {
      text-align: center;
      padding: 48px;
      color: #666;
    }

    .empty-state mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    .empty-state h3 {
      margin: 0 0 8px 0;
      color: #333;
    }

    .empty-state p {
      margin: 0;
      color: #666;
    }

    .peers-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
    }

    .peer-panel {
      margin-bottom: 8px;
    }

    .peer-header {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .peer-header mat-icon {
      font-size: 24px;
      width: 24px;
      height: 24px;
    }

    .peer-header mat-icon.mdns {
      color: #4caf50;
    }

    .peer-header mat-icon.dht {
      color: #2196f3;
    }

    .peer-header mat-icon.relay {
      color: #ff9800;
    }

    .peer-header mat-icon.manual {
      color: #9c27b0;
    }

    .peer-header mat-icon.direct {
      color: #f44336;
    }

    .peer-name {
      font-weight: 500;
    }

    .peer-status {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .peer-id {
      font-family: monospace;
      font-size: 12px;
    }

    .peer-time {
      font-size: 12px;
      color: #666;
    }

    mat-chip.connected {
      background-color: #4caf50;
      color: white;
    }

    mat-chip.disconnected {
      background-color: #9e9e9e;
      color: white;
    }

    .peer-details {
      padding: 16px 0;
    }

    .peer-info {
      margin-bottom: 16px;
    }

    .info-item {
      display: flex;
      margin-bottom: 8px;
    }

    .info-label {
      font-weight: 500;
      width: 150px;
      flex-shrink: 0;
    }

    .info-value {
      word-break: break-all;
    }

    .peer-metadata {
      margin: 16px 0;
    }

    .peer-metadata h4 {
      margin: 0 0 12px 0;
      font-size: 16px;
    }

    .capabilities-list {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin-top: 8px;
    }

    .peer-actions {
      display: flex;
      gap: 12px;
      margin-top: 16px;
      flex-wrap: wrap;
    }

    .connected-peers-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
    }

    .connected-peer-card {
      border-left: 4px solid #4caf50;
    }

    .connected-peer-header {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 16px;
    }

    .peer-identity {
      display: flex;
      align-items: center;
      gap: 12px;
    }

    .peer-identity mat-icon {
      font-size: 32px;
      width: 32px;
      height: 32px;
      color: #3f51b5;
    }

    .peer-info h3 {
      margin: 0 0 4px 0;
      font-size: 18px;
    }

    .connection-quality {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      gap: 4px;
      min-width: 150px;
    }

    .quality-indicator {
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .quality-indicator mat-icon {
      font-size: 16px;
      width: 16px;
      height: 16px;
    }

    .quality-indicator mat-icon.excellent {
      color: #4caf50;
    }

    .quality-indicator mat-icon.good {
      color: #8bc34a;
    }

    .quality-indicator mat-icon.fair {
      color: #ff9800;
    }

    .quality-indicator mat-icon.poor {
      color: #f44336;
    }

    .connection-stats {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 16px;
    }

    .peer-capabilities {
      margin-bottom: 16px;
    }

    .peer-capabilities h4 {
      margin: 0 0 8px 0;
      font-size: 16px;
    }

    .connected-peer-actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }

    .topology-container {
      height: 400px;
      background-color: #f5f5f5;
      border-radius: 8px;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .topology-placeholder {
      text-align: center;
      color: #666;
    }

    .topology-placeholder mat-icon {
      font-size: 48px;
      width: 48px;
      height: 48px;
      margin-bottom: 16px;
      opacity: 0.5;
    }

    @media (max-width: 768px) {
      .p2p-dashboard-container {
        padding: 8px;
      }
      
      .overview-stats {
        grid-template-columns: 1fr;
      }
      
      .discovery-actions {
        flex-direction: column;
      }
      
      .discovery-actions button {
        width: 100%;
      }
      
      .connection-stats {
        grid-template-columns: 1fr;
      }
      
      .connected-peer-header {
        flex-direction: column;
        gap: 16px;
      }
      
      .connection-quality {
        align-items: flex-start;
      }
    }
  `]
})
export class P2PNetworkDashboardComponent implements OnInit, OnDestroy {
  private discoveryService = inject(P2PDiscoveryService);
  private webrtcService = inject(WebrtcService);
  private analyticsService = inject(AnalyticsService);
  private snackBar = inject(MatSnackBar);

  // Reactive state from services
  isDiscovering = this.discoveryService.isDiscovering;
  discoveryStats = this.discoveryService.discoveryStats;
  
  // Computed properties
  discoveredPeers = computed(() => {
    return Array.from(this.discoveryService.discoveredPeers().values())
      .sort((a, b) => b.lastSeen - a.lastSeen);
  });
  
  discoveredPeerCount = computed(() => this.discoveredPeers().length);
  
  connectedPeers = computed(() => this.webrtcService.connectedPeers());
  connectedPeerCount = computed(() => this.connectedPeers().length);
  
  connectionQuality = computed(() => {
    const peers = this.connectedPeers();
    if (peers.length === 0) return 'No Connection';
    
    const avgSignalStrength = peers.reduce((sum, peer) => sum + peer.signalStrength, 0) / peers.length;
    
    if (avgSignalStrength >= 80) return 'Excellent';
    if (avgSignalStrength >= 60) return 'Good';
    if (avgSignalStrength >= 40) return 'Fair';
    return 'Poor';
  });
  
  dataTransferred = computed(() => {
    return this.webrtcService.networkStats().dataTransferred;
  });

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.setupEventListeners();
    this.analyticsService.trackPageView('p2p_network_dashboard');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private setupEventListeners(): void {
    // Listen for peer discovery events
    this.subscriptions.add(
      this.discoveryService.onPeerDiscovered$.subscribe(peer => {
        this.snackBar.open(
          `New peer discovered: ${this.getPeerName(peer)}`,
          'Close',
          { duration: 3000 }
        );
      })
    );

    // Listen for WebRTC connection events
    this.subscriptions.add(
      this.webrtcService.onPeerConnected$.subscribe(peer => {
        this.snackBar.open(
          `Connected to peer: ${peer.name}`,
          'Close',
          { duration: 3000 }
        );
      })
    );

    this.subscriptions.add(
      this.webrtcService.onPeerDisconnected$.subscribe(peer => {
        this.snackBar.open(
          `Disconnected from peer: ${peer.name}`,
          'Close',
          { duration: 3000 }
        );
      })
    );
  }

  // UI Event Handlers
  async startDiscovery(): Promise<void> {
    try {
      const discoveredCount = await this.discoveryService.startDiscovery();
      
      this.snackBar.open(
        `Discovered ${discoveredCount} peers`,
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackUserAction('p2p', 'discovery', undefined, undefined, discoveredCount);
    } catch (error) {
      console.error('Discovery failed:', error);
      
      this.snackBar.open(
        'Peer discovery failed',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('p2p', 'Discovery failed', { error });
    }
  }

  async connectToPeer(peerId: string): Promise<void> {
    try {
      const success = await this.discoveryService.connectToPeer(peerId);
      
      if (success) {
        this.snackBar.open(
          'Connected to peer successfully',
          'Close',
          { duration: 3000 }
        );
        
        this.analyticsService.trackUserAction('p2p', 'connect_peer', 'success');
      } else {
        this.snackBar.open(
          'Failed to connect to peer',
          'Close',
          { duration: 3000 }
        );
        
        this.analyticsService.trackUserAction('p2p', 'connect_peer', 'failed');
      }
    } catch (error) {
      console.error(`Failed to connect to peer ${peerId}:`, error);
      
      this.snackBar.open(
        'Connection error',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('p2p', 'Connection failed', { peerId, error });
    }
  }

  async connectToMultiplePeers(): Promise<void> {
    try {
      const connectedCount = await this.discoveryService.connectToMultiplePeers(5);
      
      this.snackBar.open(
        `Connected to ${connectedCount} peers`,
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackUserAction('p2p', 'connect_multiple', undefined, undefined, connectedCount);
    } catch (error) {
      console.error('Failed to connect to multiple peers:', error);
      
      this.snackBar.open(
        'Failed to connect to peers',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('p2p', 'Multiple connection failed', { error });
    }
  }

  async disconnectFromPeer(peerId: string): Promise<void> {
    try {
      this.webrtcService.disconnectFromPeer(peerId);
      
      this.snackBar.open(
        'Disconnected from peer',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackUserAction('p2p', 'disconnect_peer');
    } catch (error) {
      console.error(`Failed to disconnect from peer ${peerId}:`, error);
      
      this.snackBar.open(
        'Disconnection failed',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('p2p', 'Disconnection failed', { peerId, error });
    }
  }

  removePeer(peerId: string): void {
    this.discoveryService.removePeer(peerId);
    
    this.snackBar.open(
      'Peer removed from discovered list',
      'Close',
      { duration: 3000 }
    );
    
    this.analyticsService.trackUserAction('p2p', 'remove_peer');
  }

  async sendTestMessage(peerId: string): Promise<void> {
    try {
      const success = await this.webrtcService.sendData(peerId, {
        type: 'message',
        payload: {
          content: 'Test message from P2P Dashboard',
          timestamp: Date.now()
        },
        priority: 'normal'
      });
      
      if (success) {
        this.snackBar.open(
          'Test message sent successfully',
          'Close',
          { duration: 3000 }
        );
        
        this.analyticsService.trackUserAction('p2p', 'send_test_message', 'success');
      } else {
        this.snackBar.open(
          'Failed to send test message',
          'Close',
          { duration: 3000 }
        );
        
        this.analyticsService.trackUserAction('p2p', 'send_test_message', 'failed');
      }
    } catch (error) {
      console.error(`Failed to send test message to peer ${peerId}:`, error);
      
      this.snackBar.open(
        'Message sending failed',
        'Close',
        { duration: 3000 }
      );
      
      this.analyticsService.trackError('p2p', 'Message sending failed', { peerId, error });
    }
  }

  // Helper Methods
  isConnected(peerId: string): boolean {
    return this.connectedPeers().some(peer => peer.id === peerId);
  }

  formatPeerId(peerId: string): string {
    if (!peerId) return '';
    if (peerId.length <= 12) return peerId;
    return `${peerId.substring(0, 6)}...${peerId.substring(peerId.length - 6)}`;
  }

  getPeerTypeIcon(type: string): string {
    switch (type) {
      case 'mdns': return 'wifi';
      case 'dht': return 'hub';
      case 'relay': return 'router';
      case 'manual': return 'person';
      case 'direct': return 'connect_without_contact';
      default: return 'device_unknown';
    }
  }

  getPeerTypeClass(type: string): string {
    return type;
  }

  getPeerTypeText(type: string): string {
    switch (type) {
      case 'mdns': return 'mDNS';
      case 'dht': return 'DHT';
      case 'relay': return 'Relay Server';
      case 'manual': return 'Manual Entry';
      case 'direct': return 'Direct Connection';
      default: return 'Unknown';
    }
  }

  getPeerName(peer: DiscoveredPeer): string {
    return peer.metadata?.name || `Peer ${this.formatPeerId(peer.id)}`;
  }

  getLastSeenTime(peer: DiscoveredPeer): string {
    const now = Date.now();
    const diff = now - peer.lastSeen;
    
    if (diff < 60000) {
      return 'Just now';
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)} minutes ago`;
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)} hours ago`;
    } else {
      return `${Math.floor(diff / 86400000)} days ago`;
    }
  }

  getQualityIcon(signalStrength: number): string {
    if (signalStrength >= 80) return 'signal_cellular_4_bar';
    if (signalStrength >= 60) return 'signal_cellular_3_bar';
    if (signalStrength >= 40) return 'signal_cellular_2_bar';
    if (signalStrength >= 20) return 'signal_cellular_1_bar';
    return 'signal_cellular_0_bar';
  }

  getQualityClass(signalStrength: number): string {
    if (signalStrength >= 80) return 'excellent';
    if (signalStrength >= 60) return 'good';
    if (signalStrength >= 40) return 'fair';
    return 'poor';
  }

  getQualityText(signalStrength: number): string {
    if (signalStrength >= 80) return 'Excellent';
    if (signalStrength >= 60) return 'Good';
    if (signalStrength >= 40) return 'Fair';
    return 'Poor';
  }

  getQualityColor(signalStrength: number): 'primary' | 'accent' | 'warn' {
    if (signalStrength >= 80) return 'primary';
    if (signalStrength >= 40) return 'accent';
    return 'warn';
  }

  getDataExchanged(peerId: string): number {
    // In a real implementation, this would track data per peer
    // For demo purposes, we'll return a random value
    return Math.floor(Math.random() * 1024 * 1024); // 0-1MB
  }

  formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}