import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, fromEvent, merge, interval } from 'rxjs';
import { filter, map, debounceTime, distinctUntilChanged } from 'rxjs/operators';

export interface DeviceCapabilities {
  geolocation: boolean;
  camera: boolean;
  microphone: boolean;
  accelerometer: boolean;
  gyroscope: boolean;
  magnetometer: boolean;
  ambientLight: boolean;
  proximity: boolean;
  battery: boolean;
  vibration: boolean;
  wakeLock: boolean;
  share: boolean;
  clipboard: boolean;
  fullscreen: boolean;
  orientation: boolean;
}

export interface SensorData {
  accelerometer?: {
    x: number;
    y: number;
    z: number;
    timestamp: number;
  };
  gyroscope?: {
    alpha: number;
    beta: number;
    gamma: number;
    timestamp: number;
  };
  magnetometer?: {
    x: number;
    y: number;
    z: number;
    timestamp: number;
  };
  ambientLight?: {
    illuminance: number;
    timestamp: number;
  };
  proximity?: {
    distance: number;
    near: boolean;
    timestamp: number;
  };
}

export interface DeviceOrientation {
  orientation: 'portrait' | 'landscape';
  angle: number;
  isLocked: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class DeviceApisService {
  // Signals for reactive device state
  private _capabilities = signal<DeviceCapabilities>({
    geolocation: false,
    camera: false,
    microphone: false,
    accelerometer: false,
    gyroscope: false,
    magnetometer: false,
    ambientLight: false,
    proximity: false,
    battery: false,
    vibration: false,
    wakeLock: false,
    share: false,
    clipboard: false,
    fullscreen: false,
    orientation: false
  });

  private _sensorData = signal<SensorData>({});
  private _deviceOrientation = signal<DeviceOrientation>({
    orientation: 'portrait',
    angle: 0,
    isLocked: false
  });

  private _isMonitoring = signal<boolean>(false);

  // Computed device indicators
  capabilities = this._capabilities.asReadonly();
  sensorData = this._sensorData.asReadonly();
  deviceOrientation = this._deviceOrientation.asReadonly();
  isMonitoring = this._isMonitoring.asReadonly();

  hasMotionSensors = computed(() => {
    const caps = this._capabilities();
    return caps.accelerometer || caps.gyroscope || caps.magnetometer;
  });

  hasEnvironmentSensors = computed(() => {
    const caps = this._capabilities();
    return caps.ambientLight || caps.proximity;
  });

  // Device event subjects
  private sensorDataUpdated$ = new BehaviorSubject<SensorData>({});
  private orientationChanged$ = new BehaviorSubject<DeviceOrientation | null>(null);
  private emergencyMotion$ = new BehaviorSubject<string | null>(null);

  // Wake lock reference
  private wakeLock: any = null;

  constructor() {
    this.detectCapabilities();
    this.setupOrientationMonitoring();
  }

  private detectCapabilities(): void {
    const capabilities: DeviceCapabilities = {
      geolocation: 'geolocation' in navigator,
      camera: 'mediaDevices' in navigator && 'getUserMedia' in navigator.mediaDevices,
      microphone: 'mediaDevices' in navigator && 'getUserMedia' in navigator.mediaDevices,
      accelerometer: 'DeviceMotionEvent' in window,
      gyroscope: 'DeviceOrientationEvent' in window,
      magnetometer: 'DeviceOrientationEvent' in window,
      ambientLight: 'AmbientLightSensor' in window,
      proximity: 'ProximitySensor' in window,
      battery: 'getBattery' in navigator,
      vibration: 'vibrate' in navigator,
      wakeLock: 'wakeLock' in navigator,
      share: 'share' in navigator,
      clipboard: 'clipboard' in navigator,
      fullscreen: 'requestFullscreen' in document.documentElement,
      orientation: 'orientation' in screen
    };

    this._capabilities.set(capabilities);
    console.log('Device capabilities detected:', capabilities);
  }

  private setupOrientationMonitoring(): void {
    // Monitor screen orientation changes
    if ('orientation' in screen) {
      const orientationChange$ = fromEvent(window, 'orientationchange');
      const resize$ = fromEvent(window, 'resize');

      merge(orientationChange$, resize$).pipe(
        debounceTime(100)
      ).subscribe(() => {
        this.updateOrientation();
      });

      // Initial orientation
      this.updateOrientation();
    }
  }

  private updateOrientation(): void {
    const orientation: DeviceOrientation = {
      orientation: window.innerHeight > window.innerWidth ? 'portrait' : 'landscape',
      angle: (screen as any).orientation?.angle || 0,
      isLocked: false // Would need to track lock state
    };

    this._deviceOrientation.set(orientation);
    this.orientationChanged$.next(orientation);
  }

  // Public API methods

  async startSensorMonitoring(): Promise<boolean> {
    if (this._isMonitoring()) {
      return true;
    }

    try {
      let success = false;

      // Start accelerometer monitoring
      if (this._capabilities().accelerometer) {
        success = await this.startAccelerometerMonitoring() || success;
      }

      // Start gyroscope monitoring
      if (this._capabilities().gyroscope) {
        success = await this.startGyroscopeMonitoring() || success;
      }

      // Start ambient light monitoring
      if (this._capabilities().ambientLight) {
        success = await this.startAmbientLightMonitoring() || success;
      }

      this._isMonitoring.set(success);
      return success;
    } catch (error) {
      console.error('Failed to start sensor monitoring:', error);
      return false;
    }
  }

  stopSensorMonitoring(): void {
    this._isMonitoring.set(false);
    // Remove event listeners
    window.removeEventListener('devicemotion', this.handleDeviceMotion);
    window.removeEventListener('deviceorientation', this.handleDeviceOrientation);
  }

  private async startAccelerometerMonitoring(): Promise<boolean> {
    try {
      // Request permission for iOS 13+
      if (typeof (DeviceMotionEvent as any).requestPermission === 'function') {
        const permission = await (DeviceMotionEvent as any).requestPermission();
        if (permission !== 'granted') {
          return false;
        }
      }

      window.addEventListener('devicemotion', this.handleDeviceMotion.bind(this));
      return true;
    } catch (error) {
      console.error('Accelerometer monitoring failed:', error);
      return false;
    }
  }

  private async startGyroscopeMonitoring(): Promise<boolean> {
    try {
      // Request permission for iOS 13+
      if (typeof (DeviceOrientationEvent as any).requestPermission === 'function') {
        const permission = await (DeviceOrientationEvent as any).requestPermission();
        if (permission !== 'granted') {
          return false;
        }
      }

      window.addEventListener('deviceorientation', this.handleDeviceOrientation.bind(this));
      return true;
    } catch (error) {
      console.error('Gyroscope monitoring failed:', error);
      return false;
    }
  }

  private async startAmbientLightMonitoring(): Promise<boolean> {
    try {
      if ('AmbientLightSensor' in window) {
        const sensor = new (window as any).AmbientLightSensor();
        sensor.addEventListener('reading', () => {
          this.updateSensorData({
            ambientLight: {
              illuminance: sensor.illuminance,
              timestamp: Date.now()
            }
          });
        });
        sensor.start();
        return true;
      }
      return false;
    } catch (error) {
      console.error('Ambient light monitoring failed:', error);
      return false;
    }
  }

  private handleDeviceMotion = (event: DeviceMotionEvent): void => {
    if (event.acceleration) {
      const accelerometerData = {
        x: event.acceleration.x || 0,
        y: event.acceleration.y || 0,
        z: event.acceleration.z || 0,
        timestamp: Date.now()
      };

      this.updateSensorData({ accelerometer: accelerometerData });
      this.checkEmergencyMotion(accelerometerData);
    }
  };

  private handleDeviceOrientation = (event: DeviceOrientationEvent): void => {
    const gyroscopeData = {
      alpha: event.alpha || 0,
      beta: event.beta || 0,
      gamma: event.gamma || 0,
      timestamp: Date.now()
    };

    this.updateSensorData({ gyroscope: gyroscopeData });
  };

  private updateSensorData(newData: Partial<SensorData>): void {
    const currentData = this._sensorData();
    this._sensorData.set({ ...currentData, ...newData });
    this.sensorDataUpdated$.next(this._sensorData());
  }

  private checkEmergencyMotion(acceleration: { x: number; y: number; z: number }): void {
    // Calculate total acceleration
    const totalAcceleration = Math.sqrt(
      acceleration.x ** 2 + acceleration.y ** 2 + acceleration.z ** 2
    );

    // Detect sudden impact (potential fall)
    if (totalAcceleration > 25) {
      this.emergencyMotion$.next('sudden_impact');
    }

    // Detect free fall
    if (totalAcceleration < 2) {
      this.emergencyMotion$.next('free_fall');
    }

    // Detect shake gesture
    if (totalAcceleration > 15 && totalAcceleration < 25) {
      this.emergencyMotion$.next('shake');
    }
  }

  // Camera and media APIs
  async requestCameraAccess(constraints?: MediaStreamConstraints): Promise<MediaStream | null> {
    if (!this._capabilities().camera) {
      return null;
    }

    try {
      const defaultConstraints: MediaStreamConstraints = {
        video: {
          facingMode: 'environment', // Back camera for emergency documentation
          width: { ideal: 1280 },
          height: { ideal: 720 }
        },
        audio: false
      };

      const stream = await navigator.mediaDevices.getUserMedia(constraints || defaultConstraints);
      return stream;
    } catch (error) {
      console.error('Camera access failed:', error);
      return null;
    }
  }

  async requestMicrophoneAccess(): Promise<MediaStream | null> {
    if (!this._capabilities().microphone) {
      return null;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        },
        video: false
      });
      return stream;
    } catch (error) {
      console.error('Microphone access failed:', error);
      return null;
    }
  }

  // Wake lock management
  async requestWakeLock(): Promise<boolean> {
    if (!this._capabilities().wakeLock) {
      return false;
    }

    try {
      this.wakeLock = await (navigator as any).wakeLock.request('screen');
      
      this.wakeLock.addEventListener('release', () => {
        console.log('Wake lock released');
      });

      return true;
    } catch (error) {
      console.error('Wake lock request failed:', error);
      return false;
    }
  }

  async releaseWakeLock(): Promise<void> {
    if (this.wakeLock) {
      await this.wakeLock.release();
      this.wakeLock = null;
    }
  }

  // Screen orientation control
  async lockOrientation(orientation: 'portrait' | 'landscape'): Promise<boolean> {
    if (!this._capabilities().orientation) {
      return false;
    }

    try {
      await (screen as any).orientation.lock(orientation);
      this._deviceOrientation.update(current => ({
        ...current,
        isLocked: true
      }));
      return true;
    } catch (error) {
      console.error('Orientation lock failed:', error);
      return false;
    }
  }

  async unlockOrientation(): Promise<void> {
    if (this._capabilities().orientation) {
      try {
        (screen as any).orientation.unlock();
        this._deviceOrientation.update(current => ({
          ...current,
          isLocked: false
        }));
      } catch (error) {
        console.error('Orientation unlock failed:', error);
      }
    }
  }

  // Vibration patterns for emergency
  async emergencyVibration(pattern: 'sos' | 'alert' | 'heartbeat' | 'custom', customPattern?: number[]): Promise<boolean> {
    if (!this._capabilities().vibration) {
      return false;
    }

    const patterns = {
      sos: [100, 50, 100, 50, 100, 200, 200, 50, 200, 50, 200, 200, 100, 50, 100, 50, 100],
      alert: [300, 100, 300, 100, 300, 100, 300],
      heartbeat: [100, 50, 150, 400],
      custom: customPattern || [200]
    };

    try {
      navigator.vibrate(patterns[pattern]);
      return true;
    } catch (error) {
      console.error('Vibration failed:', error);
      return false;
    }
  }

  // Share API for emergency information
  async shareEmergencyInfo(data: {
    title?: string;
    text?: string;
    url?: string;
    location?: { lat: number; lng: number };
  }): Promise<boolean> {
    if (!this._capabilities().share) {
      return false;
    }

    try {
      const shareData: any = {
        title: data.title || 'Acil Durum Bilgisi',
        text: data.text || 'Acil durum yardımına ihtiyacım var',
        url: data.url
      };

      if (data.location) {
        shareData.text += `\nKonum: ${data.location.lat}, ${data.location.lng}`;
      }

      await navigator.share(shareData);
      return true;
    } catch (error) {
      console.error('Share failed:', error);
      return false;
    }
  }

  // Clipboard operations
  async copyToClipboard(text: string): Promise<boolean> {
    if (!this._capabilities().clipboard) {
      return false;
    }

    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (error) {
      console.error('Clipboard write failed:', error);
      return false;
    }
  }

  async readFromClipboard(): Promise<string | null> {
    if (!this._capabilities().clipboard) {
      return null;
    }

    try {
      return await navigator.clipboard.readText();
    } catch (error) {
      console.error('Clipboard read failed:', error);
      return null;
    }
  }

  // Device information
  getDeviceInfo(): {
    userAgent: string;
    platform: string;
    language: string;
    cookieEnabled: boolean;
    onLine: boolean;
    hardwareConcurrency: number;
    maxTouchPoints: number;
    deviceMemory?: number;
    connection?: any;
  } {
    return {
      userAgent: navigator.userAgent,
      platform: navigator.platform,
      language: navigator.language,
      cookieEnabled: navigator.cookieEnabled,
      onLine: navigator.onLine,
      hardwareConcurrency: navigator.hardwareConcurrency || 1,
      maxTouchPoints: navigator.maxTouchPoints || 0,
      deviceMemory: (navigator as any).deviceMemory,
      connection: (navigator as any).connection
    };
  }

  // Event observables
  get onSensorDataUpdated$(): Observable<SensorData> {
    return this.sensorDataUpdated$.asObservable();
  }

  get onOrientationChanged$(): Observable<DeviceOrientation> {
    return this.orientationChanged$.pipe(
      filter(orientation => orientation !== null),
      map(orientation => orientation!)
    );
  }

  get onEmergencyMotion$(): Observable<string> {
    return this.emergencyMotion$.pipe(
      filter(motion => motion !== null),
      map(motion => motion!)
    );
  }

  // Cleanup
  destroy(): void {
    this.stopSensorMonitoring();
    this.releaseWakeLock();
  }
}