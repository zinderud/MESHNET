import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, Subject, fromEvent, interval } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged } from 'rxjs/operators';

export interface DeviceMotionData {
  acceleration: {
    x: number;
    y: number;
    z: number;
  };
  accelerationIncludingGravity: {
    x: number;
    y: number;
    z: number;
  };
  rotationRate: {
    alpha: number;
    beta: number;
    gamma: number;
  };
  interval: number;
  timestamp: number;
}

export interface BatteryInfo {
  level: number; // 0-1
  charging: boolean;
  chargingTime: number;
  dischargingTime: number;
  lastUpdated: number;
}

export interface NetworkInfo {
  type: 'bluetooth' | 'cellular' | 'ethernet' | 'none' | 'other' | 'unknown' | 'wifi' | 'wimax';
  effectiveType: 'slow-2g' | '2g' | '3g' | '4g';
  downlink: number;
  rtt: number;
  saveData: boolean;
}

export interface VibrationPattern {
  pattern: number[];
  description: string;
}

@Injectable({
  providedIn: 'root'
})
export class WebApisService {
  // Signals for reactive state management
  private _batteryInfo = signal<BatteryInfo | null>(null);
  private _networkInfo = signal<NetworkInfo | null>(null);
  private _deviceMotion = signal<DeviceMotionData | null>(null);
  private _isVibrationSupported = signal<boolean>('vibrate' in navigator);
  private _notificationPermission = signal<NotificationPermission>('default');

  // Computed signals
  batteryInfo = this._batteryInfo.asReadonly();
  networkInfo = this._networkInfo.asReadonly();
  deviceMotion = this._deviceMotion.asReadonly();
  isVibrationSupported = this._isVibrationSupported.asReadonly();
  notificationPermission = this._notificationPermission.asReadonly();

  batteryLevel$ = computed(() => this._batteryInfo()?.level || 0);
  isCharging$ = computed(() => this._batteryInfo()?.charging || false);
  networkType$ = computed(() => this._networkInfo()?.type || 'unknown');
  connectionQuality$ = computed(() => this._networkInfo()?.effectiveType || 'unknown');

  // Subjects for events
  private deviceMotionEvent$ = new Subject<DeviceMotionData>();
  private batteryStatusChanged$ = new Subject<BatteryInfo>();
  private networkStatusChanged$ = new Subject<NetworkInfo>();
  private visibilityChanged$ = new Subject<boolean>();

  // Vibration patterns
  private vibrationPatterns: Map<string, VibrationPattern> = new Map([
    ['short', { pattern: [200], description: 'Kısa titreşim' }],
    ['long', { pattern: [1000], description: 'Uzun titreşim' }],
    ['double', { pattern: [200, 100, 200], description: 'Çift titreşim' }],
    ['sos', { pattern: [100, 50, 100, 50, 100, 200, 200, 50, 200, 50, 200, 200, 100, 50, 100, 50, 100], description: 'SOS sinyali' }],
    ['emergency', { pattern: [300, 100, 300, 100, 300, 100, 300], description: 'Acil durum' }],
    ['heartbeat', { pattern: [100, 50, 150, 400], description: 'Kalp atışı' }],
    ['alert', { pattern: [50, 50, 50, 50, 50, 200, 200, 50, 50, 50, 50, 50], description: 'Uyarı' }]
  ]);

  constructor() {
    this.initializeWebApis();
    this.setupEventListeners();
    this.startMonitoring();
  }

  private async initializeWebApis(): Promise<void> {
    try {
      // Initialize battery API
      await this.initializeBatteryApi();
      
      // Initialize network information API
      this.initializeNetworkApi();
      
      // Initialize device motion API
      this.initializeDeviceMotionApi();
      
      // Initialize notification API
      await this.initializeNotificationApi();
      
      // Initialize visibility API
      this.initializeVisibilityApi();

      console.log('Web APIs service initialized successfully');
    } catch (error) {
      console.error('Failed to initialize Web APIs service:', error);
    }
  }

  private setupEventListeners(): void {
    // Device motion events
    if ('DeviceMotionEvent' in window) {
      fromEvent<DeviceMotionEvent>(window, 'devicemotion').pipe(
        debounceTime(100), // Throttle to 10Hz
        filter(event => event.acceleration !== null)
      ).subscribe(event => {
        const motionData = this.convertDeviceMotionEvent(event);
        this._deviceMotion.set(motionData);
        this.deviceMotionEvent$.next(motionData);
      });
    }

    // Page visibility changes
    fromEvent(document, 'visibilitychange').subscribe(() => {
      const isVisible = !document.hidden;
      this.visibilityChanged$.next(isVisible);
    });

    // Online/offline events
    fromEvent(window, 'online').subscribe(() => this.updateNetworkInfo());
    fromEvent(window, 'offline').subscribe(() => this.updateNetworkInfo());
  }

  private startMonitoring(): void {
    // Monitor battery status every 30 seconds
    interval(30000).subscribe(() => {
      this.updateBatteryInfo();
    });

    // Monitor network status every 10 seconds
    interval(10000).subscribe(() => {
      this.updateNetworkInfo();
    });
  }

  // Public API Methods

  async requestNotificationPermission(): Promise<NotificationPermission> {
    if (!('Notification' in window)) {
      console.warn('Notifications not supported');
      return 'denied';
    }

    try {
      const permission = await Notification.requestPermission();
      this._notificationPermission.set(permission);
      return permission;
    } catch (error) {
      console.error('Failed to request notification permission:', error);
      return 'denied';
    }
  }

  async showNotification(title: string, options?: {
    body?: string;
    icon?: string;
    badge?: string;
    tag?: string;
    requireInteraction?: boolean;
    silent?: boolean;
    vibrate?: number[];
    actions?: NotificationAction[];
  }): Promise<boolean> {
    if (!('Notification' in window)) {
      console.warn('Notifications not supported');
      return false;
    }

    if (this._notificationPermission() !== 'granted') {
      const permission = await this.requestNotificationPermission();
      if (permission !== 'granted') {
        return false;
      }
    }

    try {
      const notification = new Notification(title, {
        body: options?.body,
        icon: options?.icon || '/assets/icons/icon-192x192.png',
        badge: options?.badge || '/assets/icons/icon-72x72.png',
        tag: options?.tag,
        requireInteraction: options?.requireInteraction || false,
        silent: options?.silent || false,
        vibrate: options?.vibrate,
        actions: options?.actions
      });

      // Auto-close after 5 seconds unless requireInteraction is true
      if (!options?.requireInteraction) {
        setTimeout(() => {
          notification.close();
        }, 5000);
      }

      return true;
    } catch (error) {
      console.error('Failed to show notification:', error);
      return false;
    }
  }

  async vibrate(pattern: string | number | number[]): Promise<boolean> {
    if (!this._isVibrationSupported()) {
      console.warn('Vibration not supported');
      return false;
    }

    try {
      let vibrationPattern: number[];

      if (typeof pattern === 'string') {
        const predefinedPattern = this.vibrationPatterns.get(pattern);
        if (predefinedPattern) {
          vibrationPattern = predefinedPattern.pattern;
        } else {
          console.warn('Unknown vibration pattern:', pattern);
          return false;
        }
      } else if (typeof pattern === 'number') {
        vibrationPattern = [pattern];
      } else {
        vibrationPattern = pattern;
      }

      navigator.vibrate(vibrationPattern);
      return true;
    } catch (error) {
      console.error('Failed to vibrate:', error);
      return false;
    }
  }

  stopVibration(): boolean {
    if (!this._isVibrationSupported()) {
      return false;
    }

    try {
      navigator.vibrate(0);
      return true;
    } catch (error) {
      console.error('Failed to stop vibration:', error);
      return false;
    }
  }

  getVibrationPatterns(): Map<string, VibrationPattern> {
    return new Map(this.vibrationPatterns);
  }

  addVibrationPattern(name: string, pattern: VibrationPattern): void {
    this.vibrationPatterns.set(name, pattern);
  }

  async requestWakeLock(): Promise<WakeLockSentinel | null> {
    if (!('wakeLock' in navigator)) {
      console.warn('Wake Lock API not supported');
      return null;
    }

    try {
      // @ts-ignore - Wake Lock API might not be in TypeScript definitions yet
      const wakeLock = await navigator.wakeLock.request('screen');
      console.log('Wake lock acquired');
      return wakeLock;
    } catch (error) {
      console.error('Failed to acquire wake lock:', error);
      return null;
    }
  }

  async shareData(data: {
    title?: string;
    text?: string;
    url?: string;
    files?: File[];
  }): Promise<boolean> {
    if (!('share' in navigator)) {
      console.warn('Web Share API not supported');
      return false;
    }

    try {
      await navigator.share(data);
      return true;
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Failed to share data:', error);
      }
      return false;
    }
  }

  async copyToClipboard(text: string): Promise<boolean> {
    if (!('clipboard' in navigator)) {
      console.warn('Clipboard API not supported');
      return false;
    }

    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (error) {
      console.error('Failed to copy to clipboard:', error);
      return false;
    }
  }

  async readFromClipboard(): Promise<string | null> {
    if (!('clipboard' in navigator)) {
      console.warn('Clipboard API not supported');
      return null;
    }

    try {
      const text = await navigator.clipboard.readText();
      return text;
    } catch (error) {
      console.error('Failed to read from clipboard:', error);
      return null;
    }
  }

  getDeviceInfo(): {
    userAgent: string;
    platform: string;
    language: string;
    cookieEnabled: boolean;
    onLine: boolean;
    hardwareConcurrency: number;
    maxTouchPoints: number;
  } {
    return {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      cookieEnabled: navigator.cookieEnabled,
      onLine: navigator.onLine,
      hardwareConcurrency: navigator.hardwareConcurrency || 1,
      maxTouchPoints: navigator.maxTouchPoints || 0
    };
  }

  async getStorageEstimate(): Promise<StorageEstimate | null> {
    if (!('storage' in navigator) || !('estimate' in navigator.storage)) {
      console.warn('Storage API not supported');
      return null;
    }

    try {
      return await navigator.storage.estimate();
    } catch (error) {
      console.error('Failed to get storage estimate:', error);
      return null;
    }
  }

  // Event Observables
  get onDeviceMotion$(): Observable<DeviceMotionData> {
    return this.deviceMotionEvent$.asObservable();
  }

  get onBatteryStatusChanged$(): Observable<BatteryInfo> {
    return this.batteryStatusChanged$.asObservable();
  }

  get onNetworkStatusChanged$(): Observable<NetworkInfo> {
    return this.networkStatusChanged$.asObservable();
  }

  get onVisibilityChanged$(): Observable<boolean> {
    return this.visibilityChanged$.asObservable();
  }

  // Private Methods

  private async initializeBatteryApi(): Promise<void> {
    try {
      // @ts-ignore - Battery API might not be in TypeScript definitions
      const battery = await navigator.getBattery?.();
      
      if (battery) {
        const batteryInfo: BatteryInfo = {
          level: battery.level,
          charging: battery.charging,
          chargingTime: battery.chargingTime,
          dischargingTime: battery.dischargingTime,
          lastUpdated: Date.now()
        };

        this._batteryInfo.set(batteryInfo);

        // Listen for battery events
        battery.addEventListener('chargingchange', () => this.updateBatteryInfo());
        battery.addEventListener('levelchange', () => this.updateBatteryInfo());
        battery.addEventListener('chargingtimechange', () => this.updateBatteryInfo());
        battery.addEventListener('dischargingtimechange', () => this.updateBatteryInfo());
      }
    } catch (error) {
      console.warn('Battery API not available:', error);
    }
  }

  private initializeNetworkApi(): void {
    try {
      // @ts-ignore - Network Information API might not be in TypeScript definitions
      const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
      
      if (connection) {
        this.updateNetworkInfo();
        
        connection.addEventListener('change', () => {
          this.updateNetworkInfo();
        });
      }
    } catch (error) {
      console.warn('Network Information API not available:', error);
    }
  }

  private initializeDeviceMotionApi(): void {
    if ('DeviceMotionEvent' in window) {
      // Check if permission is required (iOS 13+)
      if (typeof (DeviceMotionEvent as any).requestPermission === 'function') {
        // Permission will be requested when first needed
        console.log('Device motion permission required');
      } else {
        console.log('Device motion API available');
      }
    } else {
      console.warn('Device Motion API not supported');
    }
  }

  private async initializeNotificationApi(): Promise<void> {
    if ('Notification' in window) {
      this._notificationPermission.set(Notification.permission);
    } else {
      console.warn('Notifications not supported');
    }
  }

  private initializeVisibilityApi(): void {
    if ('hidden' in document) {
      console.log('Page Visibility API available');
    } else {
      console.warn('Page Visibility API not supported');
    }
  }

  private async updateBatteryInfo(): Promise<void> {
    try {
      // @ts-ignore
      const battery = await navigator.getBattery?.();
      
      if (battery) {
        const batteryInfo: BatteryInfo = {
          level: battery.level,
          charging: battery.charging,
          chargingTime: battery.chargingTime,
          dischargingTime: battery.dischargingTime,
          lastUpdated: Date.now()
        };

        this._batteryInfo.set(batteryInfo);
        this.batteryStatusChanged$.next(batteryInfo);
      }
    } catch (error) {
      console.error('Failed to update battery info:', error);
    }
  }

  private updateNetworkInfo(): void {
    try {
      // @ts-ignore
      const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
      
      if (connection) {
        const networkInfo: NetworkInfo = {
          type: connection.type || 'unknown',
          effectiveType: connection.effectiveType || 'unknown',
          downlink: connection.downlink || 0,
          rtt: connection.rtt || 0,
          saveData: connection.saveData || false
        };

        this._networkInfo.set(networkInfo);
        this.networkStatusChanged$.next(networkInfo);
      } else {
        // Fallback for browsers without Network Information API
        const networkInfo: NetworkInfo = {
          type: navigator.onLine ? 'unknown' : 'none',
          effectiveType: '4g', // fallback to a valid value
          downlink: 0,
          rtt: 0,
          saveData: false
        };

        this._networkInfo.set(networkInfo);
        this.networkStatusChanged$.next(networkInfo);
      }
    } catch (error) {
      console.error('Failed to update network info:', error);
    }
  }

  private convertDeviceMotionEvent(event: DeviceMotionEvent): DeviceMotionData {
    return {
      acceleration: {
        x: event.acceleration?.x || 0,
        y: event.acceleration?.y || 0,
        z: event.acceleration?.z || 0
      },
      accelerationIncludingGravity: {
        x: event.accelerationIncludingGravity?.x || 0,
        y: event.accelerationIncludingGravity?.y || 0,
        z: event.accelerationIncludingGravity?.z || 0
      },
      rotationRate: {
        alpha: event.rotationRate?.alpha || 0,
        beta: event.rotationRate?.beta || 0,
        gamma: event.rotationRate?.gamma || 0
      },
      interval: event.interval || 0,
      timestamp: Date.now()
    };
  }

  async requestDeviceMotionPermission(): Promise<boolean> {
    if (typeof (DeviceMotionEvent as any).requestPermission === 'function') {
      try {
        const permission = await (DeviceMotionEvent as any).requestPermission();
        return permission === 'granted';
      } catch (error) {
        console.error('Failed to request device motion permission:', error);
        return false;
      }
    }
    return true; // Permission not required
  }

  async requestDeviceOrientationPermission(): Promise<boolean> {
    if (typeof (DeviceOrientationEvent as any).requestPermission === 'function') {
      try {
        const permission = await (DeviceOrientationEvent as any).requestPermission();
        return permission === 'granted';
      } catch (error) {
        console.error('Failed to request device orientation permission:', error);
        return false;
      }
    }
    return true; // Permission not required
  }
}