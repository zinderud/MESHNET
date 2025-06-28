import { Component, inject, OnInit, OnDestroy, computed, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatSidenavModule } from '@angular/material/sidenav';
import { MatListModule } from '@angular/material/list';
import { MatBadgeModule } from '@angular/material/badge';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Subscription } from 'rxjs';

import { PWAInstallComponent } from './features/pwa-install/pwa-install.component';
import { PWAService } from './core/services/pwa.service';
import { TouchService } from './core/services/touch.service';
import { DeviceApisService } from './core/services/device-apis.service';
import { EmergencyProtocolService } from './core/services/emergency-protocol.service';
import { MessagingService } from './core/services/messaging.service';
import { WebrtcService } from './core/services/webrtc.service';
import { AnalyticsService } from './core/services/analytics.service';
import { EmergencyMeshCoordinatorService } from './core/services/emergency-mesh-coordinator.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    CommonModule,
    RouterOutlet,
    RouterModule,
    MatToolbarModule,
    MatButtonModule,
    MatIconModule,
    MatSidenavModule,
    MatListModule,
    MatBadgeModule,
    PWAInstallComponent
  ],
  template: `
    <mat-sidenav-container class="sidenav-container">
      <mat-sidenav #drawer class="sidenav" fixedInViewport
                   [attr.role]="'navigation'"
                   [mode]="'over'"
                   [opened]="false">
        <mat-toolbar>Menü</mat-toolbar>
        <mat-nav-list>
          <a mat-list-item routerLink="/dashboard" (click)="drawer.close()">
            <mat-icon>dashboard</mat-icon>
            <span>Ana Sayfa</span>
          </a>
          
          <!-- Emergency Menu Item with Angular 20 Control Flow -->
          @if (isEmergencyActive()) {
            <a mat-list-item routerLink="/emergency" (click)="drawer.close()"
               class="emergency-active">
              <mat-icon class="emergency-pulse">warning</mat-icon>
              <span>Acil Durum</span>
              <mat-icon class="emergency-indicator">fiber_manual_record</mat-icon>
            </a>
          } @else {
            <a mat-list-item routerLink="/emergency" (click)="drawer.close()">
              <mat-icon>warning</mat-icon>
              <span>Acil Durum</span>
            </a>
          }

          <!-- Emergency Scenario Menu Item -->
          <a mat-list-item routerLink="/emergency-scenario" (click)="drawer.close()">
            <mat-icon>science</mat-icon>
            <span>Senaryo Simülasyonu</span>
            @if (isScenarioActive()) {
              <mat-icon class="scenario-indicator">play_circle</mat-icon>
            }
          </a>
          
          <a mat-list-item routerLink="/messages" (click)="drawer.close()">
            <mat-icon [matBadge]="unreadMessageCount()" 
                      [matBadgeHidden]="unreadMessageCount() === 0"
                      matBadgeColor="warn">message</mat-icon>
            <span>Mesajlar</span>
          </a>
          
          <a mat-list-item routerLink="/network" (click)="drawer.close()">
            @if (isNetworkConnected()) {
              <mat-icon class="network-connected">network_check</mat-icon>
            } @else {
              <mat-icon class="network-disconnected">signal_wifi_off</mat-icon>
            }
            <span>Ağ Durumu</span>
            <span class="network-status">{{ connectedPeerCount() }} cihaz</span>
          </a>
          
          <a mat-list-item routerLink="/settings" (click)="drawer.close()">
            <mat-icon>settings</mat-icon>
            <span>Ayarlar</span>
          </a>
        </mat-nav-list>
      </mat-sidenav>
      
      <mat-sidenav-content>
        <mat-toolbar color="primary" class="main-toolbar"
                     [class.emergency-mode]="isEmergencyActive()"
                     [class.scenario-mode]="isScenarioActive()">
          <button
            type="button"
            aria-label="Toggle sidenav"
            mat-icon-button
            (click)="drawer.toggle()"
            class="menu-button">
            <mat-icon aria-label="Side nav toggle icon">menu</mat-icon>
          </button>
          
          <span class="app-title">
            @if (isScenarioActive()) {
              🧪 Senaryo Modu
            } @else if (isEmergencyActive()) {
              🚨 Acil Durum
            } @else {
              Acil Durum Mesh Network
            }
          </span>
          
          <span class="spacer"></span>
          
          <!-- Scenario Status -->
          @if (isScenarioActive()) {
            <button mat-icon-button 
                    routerLink="/emergency-scenario"
                    class="scenario-status-button"
                    matTooltip="Aktif senaryo">
              <mat-icon class="scenario-pulse">science</mat-icon>
            </button>
          }

          <!-- Network Status with Angular 20 Control Flow -->
          <button mat-icon-button 
                  [matTooltip]="getNetworkStatusText()"
                  class="network-button">
            @if (isNetworkConnected()) {
              <mat-icon class="network-connected">signal_wifi_4_bar</mat-icon>
            } @else {
              <mat-icon class="network-disconnected">signal_wifi_off</mat-icon>
            }
          </button>

          <!-- Emergency Status -->
          @if (isEmergencyActive()) {
            <button mat-icon-button 
                    routerLink="/emergency"
                    class="emergency-status-button"
                    matTooltip="Acil durum aktif">
              <mat-icon class="emergency-pulse">warning</mat-icon>
            </button>
          }

          <!-- PWA Install/Update -->
          @if (showPWAButton()) {
            <button mat-icon-button 
                    (click)="handlePWAAction()"
                    [matTooltip]="pwaButtonTooltip()">
              <mat-icon>{{ pwaButtonIcon() }}</mat-icon>
            </button>
          }
        </mat-toolbar>
        
        <main class="main-content" 
              [class.touch-device]="isTouchDevice()"
              [class.emergency-mode]="isEmergencyActive()"
              [class.scenario-mode]="isScenarioActive()">
          <router-outlet></router-outlet>
        </main>
      </mat-sidenav-content>
    </mat-sidenav-container>

    <!-- PWA Install/Update Component -->
    <app-pwa-install></app-pwa-install>
  `,
  styles: [`
    .sidenav-container {
      height: 100vh;
    }

    .sidenav {
      width: 250px;
    }

    .sidenav .mat-toolbar {
      background: inherit;
    }

    .main-toolbar {
      position: sticky;
      top: 0;
      z-index: 1;
      transition: background-color 0.3s ease;
    }

    .main-toolbar.emergency-mode {
      background: linear-gradient(135deg, #ff5722, #f44336) !important;
    }

    .main-toolbar.scenario-mode {
      background: linear-gradient(135deg, #9c27b0, #673ab7) !important;
    }

    .menu-button {
      margin-right: 8px;
    }

    .app-title {
      font-size: 18px;
      font-weight: 500;
    }

    .spacer {
      flex: 1 1 auto;
    }

    .network-button mat-icon.network-connected {
      color: #4caf50;
    }

    .network-button mat-icon.network-disconnected {
      color: #f44336;
    }

    .emergency-status-button,
    .scenario-status-button {
      animation: emergency-pulse 2s infinite;
    }

    .emergency-status-button mat-icon {
      color: #ffeb3b;
    }

    .scenario-status-button mat-icon {
      color: #e1bee7;
    }

    .main-content {
      padding: 16px;
      min-height: calc(100vh - 64px);
      transition: all 0.3s ease;
    }

    .main-content.touch-device {
      padding: 8px;
    }

    .main-content.emergency-mode {
      background: linear-gradient(135deg, rgba(255, 87, 34, 0.05), rgba(244, 67, 54, 0.05));
    }

    .main-content.scenario-mode {
      background: linear-gradient(135deg, rgba(156, 39, 176, 0.05), rgba(103, 58, 183, 0.05));
    }

    /* Navigation List Styles */
    .mat-nav-list .mat-list-item.emergency-active {
      background: rgba(255, 87, 34, 0.1);
      border-left: 4px solid #ff5722;
    }

    .mat-nav-list .mat-list-item mat-icon.emergency-pulse {
      animation: emergency-pulse 2s infinite;
      color: #ff5722;
    }

    .mat-nav-list .mat-list-item mat-icon.scenario-pulse {
      animation: scenario-pulse 2s infinite;
      color: #9c27b0;
    }

    .emergency-indicator,
    .scenario-indicator {
      color: #ff5722;
      font-size: 12px;
      width: 12px;
      height: 12px;
      margin-left: auto;
    }

    .scenario-indicator {
      color: #9c27b0;
    }

    .network-status {
      font-size: 12px;
      color: #666;
      margin-left: auto;
    }

    .mat-nav-list .mat-list-item mat-icon.network-connected {
      color: #4caf50;
    }

    .mat-nav-list .mat-list-item mat-icon.network-disconnected {
      color: #f44336;
    }

    /* Emergency Animations */
    @keyframes emergency-pulse {
      0% { 
        transform: scale(1); 
        opacity: 1;
      }
      50% { 
        transform: scale(1.1); 
        opacity: 0.7;
      }
      100% { 
        transform: scale(1); 
        opacity: 1;
      }
    }

    @keyframes scenario-pulse {
      0% { 
        transform: scale(1); 
        opacity: 1;
      }
      50% { 
        transform: scale(1.05); 
        opacity: 0.8;
      }
      100% { 
        transform: scale(1); 
        opacity: 1;
      }
    }

    /* Touch-friendly styles */
    .touch-device .mat-toolbar button {
      min-width: 48px;
      min-height: 48px;
    }

    .touch-device .mat-nav-list .mat-list-item {
      min-height: 56px;
    }

    /* Responsive Design */
    @media (max-width: 768px) {
      .main-content {
        padding: 8px;
      }
      
      .app-title {
        font-size: 16px;
      }
      
      .mat-toolbar {
        padding: 0 8px;
      }
    }

    @media (max-width: 480px) {
      .app-title {
        display: none;
      }
    }

    /* High contrast mode support */
    @media (prefers-contrast: high) {
      .main-toolbar {
        border-bottom: 2px solid #000;
      }
      
      .mat-nav-list .mat-list-item {
        border-bottom: 1px solid #000;
      }
    }

    /* Reduced motion support */
    @media (prefers-reduced-motion: reduce) {
      .emergency-pulse,
      .scenario-pulse,
      .emergency-status-button,
      .scenario-status-button {
        animation: none;
      }
      
      .main-content,
      .main-toolbar {
        transition: none;
      }
    }
  `]
})
export class AppComponent implements OnInit, OnDestroy {
  private pwaService = inject(PWAService);
  private touchService = inject(TouchService);
  private deviceApisService = inject(DeviceApisService);
  private emergencyProtocolService = inject(EmergencyProtocolService);
  private messagingService = inject(MessagingService);
  private webrtcService = inject(WebrtcService);
  private analyticsService = inject(AnalyticsService);
  private emergencyCoordinator = inject(EmergencyMeshCoordinatorService);

  title = 'Acil Durum Mesh Network';

  // Angular 20 Signals - Reactive state management
  isEmergencyActive = this.emergencyProtocolService.isEmergencyActive;
  unreadMessageCount = this.messagingService.unreadMessages;
  isNetworkConnected = this.webrtcService.isConnected;
  connectedPeerCount = computed(() => this.webrtcService.connectedPeers().length);
  isTouchDevice = this.touchService.isTouchDevice;

  // Emergency Scenario state
  isScenarioActive = computed(() => this.emergencyCoordinator.currentScenario() !== null);

  // PWA state signals
  private _showPWAButton = signal(false);
  private _pwaButtonIcon = signal('download');
  private _pwaButtonTooltip = signal('Uygulamayı yükle');

  showPWAButton = this._showPWAButton.asReadonly();
  pwaButtonIcon = this._pwaButtonIcon.asReadonly();
  pwaButtonTooltip = this._pwaButtonTooltip.asReadonly();

  private subscriptions = new Subscription();

  ngOnInit(): void {
    this.initializeApp();
    this.setupEventListeners();
    this.setupTouchOptimizations();
    this.setupEmergencyGestures();
    this.analyticsService.trackPageView('app_root');
  }

  ngOnDestroy(): void {
    this.subscriptions.unsubscribe();
  }

  private async initializeApp(): Promise<void> {
    try {
      // Initialize device APIs
      await this.deviceApisService.startSensorMonitoring();
      
      // Setup PWA features
      this.pwaService.setupAppLifecycleHandlers();
      await this.pwaService.preloadCriticalResources();
      
      // Request persistent storage for emergency data
      await this.pwaService.requestPersistentStorage();

      console.log('Angular 20 App initialized successfully');
    } catch (error) {
      console.error('App initialization failed:', error);
      this.analyticsService.trackError('app_init', 'Initialization failed', { error });
    }
  }

  private setupEventListeners(): void {
    // PWA install/update events
    this.subscriptions.add(
      this.pwaService.onInstallPrompt$.subscribe(canInstall => {
        this._showPWAButton.set(canInstall);
        this._pwaButtonIcon.set('download');
        this._pwaButtonTooltip.set('Uygulamayı yükle');
      })
    );

    this.subscriptions.add(
      this.pwaService.onUpdateAvailable$.subscribe(updateAvailable => {
        if (updateAvailable) {
          this._showPWAButton.set(true);
          this._pwaButtonIcon.set('system_update');
          this._pwaButtonTooltip.set('Güncelleme mevcut');
        }
      })
    );

    // Emergency motion detection
    this.subscriptions.add(
      this.deviceApisService.onEmergencyMotion$.subscribe(motionType => {
        if (motionType === 'sudden_impact') {
          this.handleEmergencyMotion('Ani darbe algılandı');
        } else if (motionType === 'free_fall') {
          this.handleEmergencyMotion('Serbest düşüş algılandı');
        }
      })
    );

    // Network status changes
    this.subscriptions.add(
      this.webrtcService.connectionStatus$.subscribe(status => {
        this.analyticsService.trackNetworkConnection(status, status === 'connected');
      })
    );

    // Emergency scenario events
    this.subscriptions.add(
      this.emergencyCoordinator.onEmergencyNetworkFormed$.subscribe(network => {
        this.analyticsService.trackEvent('emergency', 'network_formed', network.name);
      })
    );
  }

  private setupTouchOptimizations(): void {
    if (this.touchService.isTouchDevice()) {
      // Enable emergency gestures
      this.touchService.enableEmergencyGestures();
      
      // Optimize touch targets
      setTimeout(() => {
        const buttons = document.querySelectorAll('button, .mat-list-item');
        buttons.forEach(button => {
          this.touchService.optimizeForTouch(button as HTMLElement);
        });
      }, 1000);
    }
  }

  private setupEmergencyGestures(): void {
    // Listen for emergency gestures
    this.subscriptions.add(
      this.touchService.onEmergencyGesture$.subscribe(gestureType => {
        if (gestureType === 'emergency_long_press') {
          this.handleEmergencyGesture('Uzun basma ile acil durum');
        } else if (gestureType === 'emergency_swipe_up') {
          this.handleEmergencyGesture('Yukarı kaydırma ile acil durum');
        }
      })
    );
  }

  private async handleEmergencyMotion(description: string): Promise<void> {
    this.analyticsService.trackEvent('emergency', 'motion_detected', description);
    
    // Show confirmation dialog before activating emergency
    const shouldActivate = confirm(
      `${description}\n\nAcil durum modu etkinleştirilsin mi?`
    );

    if (shouldActivate) {
      await this.emergencyProtocolService.activateEmergency('accident', 'high', description);
    }
  }

  private async handleEmergencyGesture(description: string): Promise<void> {
    this.analyticsService.trackEvent('emergency', 'gesture_detected', description);
    
    // Immediate emergency activation for gestures
    await this.emergencyProtocolService.activateEmergency('other', 'high', description);
  }

  async handlePWAAction(): Promise<void> {
    const pwaStatus = this.pwaService.pwaStatus();
    
    if (pwaStatus.isUpdateAvailable) {
      await this.pwaService.updateApp();
    } else if (pwaStatus.isInstallable) {
      await this.pwaService.installApp();
    }
  }

  getNetworkStatusText(): string {
    const isConnected = this.isNetworkConnected();
    const peerCount = this.connectedPeerCount();
    
    if (isConnected) {
      return `Bağlı - ${peerCount} cihaz`;
    } else {
      return 'Bağlantı yok';
    }
  }
}