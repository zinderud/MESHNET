import { Injectable, signal, computed } from '@angular/core';
import { SwUpdate, VersionReadyEvent } from '@angular/service-worker';
import { BehaviorSubject, Observable, fromEvent, merge } from 'rxjs';
import { filter, map } from 'rxjs/operators';

export interface PWAInstallPrompt {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export interface PWAStatus {
  isInstalled: boolean;
  isInstallable: boolean;
  isUpdateAvailable: boolean;
  isOnline: boolean;
  lastUpdateCheck: number;
}

@Injectable({
  providedIn: 'root'
})
export class PWAService {
  // Signals for reactive PWA state
  private _pwaStatus = signal<PWAStatus>({
    isInstalled: false,
    isInstallable: false,
    isUpdateAvailable: false,
    isOnline: navigator.onLine,
    lastUpdateCheck: 0
  });

  // Computed PWA indicators
  pwaStatus = this._pwaStatus.asReadonly();
  canInstall = computed(() => this._pwaStatus().isInstallable && !this._pwaStatus().isInstalled);
  needsUpdate = computed(() => this._pwaStatus().isUpdateAvailable);

  // PWA events
  private installPromptEvent: PWAInstallPrompt | null = null;
  private updateAvailable$ = new BehaviorSubject<boolean>(false);
  private installPrompt$ = new BehaviorSubject<boolean>(false);

  constructor(private swUpdate: SwUpdate) {
    this.initializePWA();
    this.setupServiceWorkerUpdates();
    this.setupInstallPrompt();
    this.setupNetworkMonitoring();
  }

  private initializePWA(): void {
    // Check if app is installed
    const isInstalled = this.checkIfInstalled();
    
    // Update PWA status
    this._pwaStatus.update(status => ({
      ...status,
      isInstalled,
      lastUpdateCheck: Date.now()
    }));

    console.log('PWA Service initialized');
  }

  private setupServiceWorkerUpdates(): void {
    if (this.swUpdate.isEnabled) {
      // Check for updates every 6 hours
      setInterval(() => {
        this.checkForUpdates();
      }, 6 * 60 * 60 * 1000);

      // Listen for version updates
      this.swUpdate.versionUpdates.pipe(
        filter((evt): evt is VersionReadyEvent => evt.type === 'VERSION_READY')
      ).subscribe(() => {
        this._pwaStatus.update(status => ({
          ...status,
          isUpdateAvailable: true
        }));
        this.updateAvailable$.next(true);
      });

      // Initial update check
      this.checkForUpdates();
    }
  }

  private setupInstallPrompt(): void {
    // Listen for beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      this.installPromptEvent = e as any;
      
      this._pwaStatus.update(status => ({
        ...status,
        isInstallable: true
      }));
      
      this.installPrompt$.next(true);
    });

    // Listen for app installed event
    window.addEventListener('appinstalled', () => {
      this._pwaStatus.update(status => ({
        ...status,
        isInstalled: true,
        isInstallable: false
      }));
      
      this.installPromptEvent = null;
      console.log('PWA was installed');
    });
  }

  private setupNetworkMonitoring(): void {
    const online$ = fromEvent(window, 'online').pipe(map(() => true));
    const offline$ = fromEvent(window, 'offline').pipe(map(() => false));
    
    merge(online$, offline$).subscribe(isOnline => {
      this._pwaStatus.update(status => ({
        ...status,
        isOnline
      }));
    });
  }

  // Public API methods
  async installApp(): Promise<boolean> {
    if (!this.installPromptEvent) {
      return false;
    }

    try {
      await this.installPromptEvent.prompt();
      const choiceResult = await this.installPromptEvent.userChoice;
      
      if (choiceResult.outcome === 'accepted') {
        console.log('User accepted the install prompt');
        return true;
      } else {
        console.log('User dismissed the install prompt');
        return false;
      }
    } catch (error) {
      console.error('Error during app installation:', error);
      return false;
    }
  }

  async updateApp(): Promise<boolean> {
    if (!this.swUpdate.isEnabled || !this._pwaStatus().isUpdateAvailable) {
      return false;
    }

    try {
      await this.swUpdate.activateUpdate();
      window.location.reload();
      return true;
    } catch (error) {
      console.error('Error updating app:', error);
      return false;
    }
  }

  async checkForUpdates(): Promise<boolean> {
    if (!this.swUpdate.isEnabled) {
      return false;
    }

    try {
      const updateFound = await this.swUpdate.checkForUpdate();
      this._pwaStatus.update(status => ({
        ...status,
        lastUpdateCheck: Date.now()
      }));
      return updateFound;
    } catch (error) {
      console.error('Error checking for updates:', error);
      return false;
    }
  }

  // PWA capabilities detection
  getCapabilities(): {
    serviceWorker: boolean;
    pushNotifications: boolean;
    backgroundSync: boolean;
    webShare: boolean;
    installPrompt: boolean;
    fullscreen: boolean;
  } {
    return {
      serviceWorker: 'serviceWorker' in navigator,
      pushNotifications: 'PushManager' in window,
      backgroundSync: 'serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype,
      webShare: 'share' in navigator,
      installPrompt: 'BeforeInstallPromptEvent' in window,
      fullscreen: 'requestFullscreen' in document.documentElement
    };
  }

  // App shortcuts management
  async addShortcut(shortcut: {
    name: string;
    url: string;
    description?: string;
    icons?: Array<{ src: string; sizes: string; type: string }>;
  }): Promise<boolean> {
    try {
      // This would be implemented when the API becomes available
      console.log('Adding shortcut:', shortcut);
      return true;
    } catch (error) {
      console.error('Error adding shortcut:', error);
      return false;
    }
  }

  // Fullscreen management
  async enterFullscreen(): Promise<boolean> {
    try {
      if (document.documentElement.requestFullscreen) {
        await document.documentElement.requestFullscreen();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error entering fullscreen:', error);
      return false;
    }
  }

  async exitFullscreen(): Promise<boolean> {
    try {
      if (document.exitFullscreen) {
        await document.exitFullscreen();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error exiting fullscreen:', error);
      return false;
    }
  }

  isFullscreen(): boolean {
    return !!document.fullscreenElement;
  }

  // Badge API (for app icon badges)
  async setBadge(count?: number): Promise<boolean> {
    try {
      if ('setAppBadge' in navigator) {
        await (navigator as any).setAppBadge(count);
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error setting badge:', error);
      return false;
    }
  }

  async clearBadge(): Promise<boolean> {
    try {
      if ('clearAppBadge' in navigator) {
        await (navigator as any).clearAppBadge();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Error clearing badge:', error);
      return false;
    }
  }

  // Event observables
  get onUpdateAvailable$(): Observable<boolean> {
    return this.updateAvailable$.asObservable();
  }

  get onInstallPrompt$(): Observable<boolean> {
    return this.installPrompt$.asObservable();
  }

  // Private helper methods
  private checkIfInstalled(): boolean {
    // Check if running in standalone mode
    if (window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }

    // Check if running in PWA mode on iOS
    if ((window.navigator as any).standalone === true) {
      return true;
    }

    // Check if installed via Chrome
    if (window.matchMedia('(display-mode: minimal-ui)').matches) {
      return true;
    }

    return false;
  }

  // Storage management
  async getStorageEstimate(): Promise<{
    quota: number;
    usage: number;
    available: number;
    percentage: number;
  }> {
    try {
      if ('storage' in navigator && 'estimate' in navigator.storage) {
        const estimate = await navigator.storage.estimate();
        const quota = estimate.quota || 0;
        const usage = estimate.usage || 0;
        const available = quota - usage;
        const percentage = quota > 0 ? (usage / quota) * 100 : 0;

        return { quota, usage, available, percentage };
      }
    } catch (error) {
      console.error('Error getting storage estimate:', error);
    }

    return { quota: 0, usage: 0, available: 0, percentage: 0 };
  }

  async requestPersistentStorage(): Promise<boolean> {
    try {
      if ('storage' in navigator && 'persist' in navigator.storage) {
        return await navigator.storage.persist();
      }
      return false;
    } catch (error) {
      console.error('Error requesting persistent storage:', error);
      return false;
    }
  }

  // Performance optimization
  async preloadCriticalResources(): Promise<void> {
    const criticalResources = [
      '/assets/icons/icon-192x192.png',
      '/assets/icons/icon-512x512.png'
    ];

    const preloadPromises = criticalResources.map(url => {
      return new Promise<void>((resolve) => {
        const link = document.createElement('link');
        link.rel = 'preload';
        link.href = url;
        link.as = 'image';
        link.onload = () => resolve();
        link.onerror = () => resolve(); // Don't fail on error
        document.head.appendChild(link);
      });
    });

    await Promise.all(preloadPromises);
  }

  // App lifecycle management
  setupAppLifecycleHandlers(): void {
    // Handle app visibility changes
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        console.log('App went to background');
        // Reduce background activity
      } else {
        console.log('App came to foreground');
        // Resume normal activity
        this.checkForUpdates();
      }
    });

    // Handle page freeze/resume (Chrome)
    document.addEventListener('freeze', () => {
      console.log('App frozen');
    });

    document.addEventListener('resume', () => {
      console.log('App resumed');
    });
  }
}