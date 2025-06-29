import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval } from 'rxjs';
import { filter, debounceTime, distinctUntilChanged } from 'rxjs/operators';

export interface LocationData {
  latitude: number;
  longitude: number;
  accuracy: number;
  altitude?: number;
  altitudeAccuracy?: number;
  heading?: number;
  speed?: number;
  timestamp: number;
}

export interface LocationHistory {
  id: string;
  location: LocationData;
  type: 'manual' | 'automatic' | 'emergency';
  shared: boolean;
  expiresAt?: number;
}

export interface GeofenceArea {
  id: string;
  name: string;
  center: { latitude: number; longitude: number };
  radius: number; // in meters
  type: 'safe' | 'danger' | 'emergency' | 'custom';
  active: boolean;
  notifications: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class LocationService {
  // Signals for reactive state management
  private _currentLocation = signal<LocationData | null>(null);
  private _locationHistory = signal<LocationHistory[]>([]);
  private _isTracking = signal<boolean>(false);
  private _isSharing = signal<boolean>(false);
  private _geofences = signal<GeofenceArea[]>([]);
  private _locationAccuracy = signal<'high' | 'medium' | 'low'>('medium');

  // Computed signals
  currentLocation = this._currentLocation.asReadonly();
  locationHistory = this._locationHistory.asReadonly();
  isTracking = this._isTracking.asReadonly();
  isSharing = this._isSharing.asReadonly();
  geofences = this._geofences.asReadonly();
  locationAccuracy = this._locationAccuracy.asReadonly();

  hasLocation = computed(() => this._currentLocation() !== null);
  lastLocationTime = computed(() => this._currentLocation()?.timestamp || 0);
  locationAge = computed(() => {
    const lastTime = this.lastLocationTime();
    return lastTime ? Date.now() - lastTime : 0;
  });

  // Subjects for events
  private locationUpdated$ = new Subject<LocationData>();
  private locationError$ = new Subject<GeolocationPositionError>();
  private geofenceEntered$ = new Subject<{ location: LocationData; geofence: GeofenceArea }>();
  private geofenceExited$ = new Subject<{ location: LocationData; geofence: GeofenceArea }>();

  // Location tracking configuration
  private watchId?: number;
  private trackingInterval?: any;
  private sharingInterval?: any;
  private lastGeofenceCheck: Map<string, boolean> = new Map();

  constructor() {
    this.initializeLocationService();
    this.setupGeofenceMonitoring();
  }

  private initializeLocationService(): void {
    // Check if geolocation is supported
    if (!navigator.geolocation) {
      console.error('Geolocation is not supported by this browser');
      return;
    }

    // Load saved settings
    this.loadLocationSettings();
    
    // Setup default geofences
    this.setupDefaultGeofences();

    console.log('Location service initialized');
  }

  private setupGeofenceMonitoring(): void {
    // Monitor location changes for geofence detection
    this.locationUpdated$.subscribe(location => {
      this.checkGeofences(location);
    });
  }

  // Public API Methods

  async getCurrentLocation(options?: {
    highAccuracy?: boolean;
    timeout?: number;
    maximumAge?: number;
  }): Promise<LocationData | null> {
    return new Promise((resolve, reject) => {
      const defaultOptions: PositionOptions = {
        enableHighAccuracy: options?.highAccuracy ?? true,
        timeout: options?.timeout ?? 10000,
        maximumAge: options?.maximumAge ?? 60000
      };

      navigator.geolocation.getCurrentPosition(
        (position) => {
          const locationData = this.convertPositionToLocationData(position);
          this._currentLocation.set(locationData);
          this.addToHistory(locationData, 'manual');
          this.locationUpdated$.next(locationData);
          resolve(locationData);
        },
        (error) => {
          console.error('Failed to get current location:', error);
          this.locationError$.next(error);
          reject(error);
        },
        defaultOptions
      );
    });
  }

  async startLocationTracking(options?: {
    interval?: number;
    highAccuracy?: boolean;
    backgroundTracking?: boolean;
  }): Promise<boolean> {
    if (this._isTracking()) {
      console.log('Location tracking is already active');
      return true;
    }

    try {
      // Request permission first
      const permission = await this.requestLocationPermission();
      if (permission !== 'granted') {
        throw new Error('Location permission denied');
      }

      const trackingOptions: PositionOptions = {
        enableHighAccuracy: options?.highAccuracy ?? true,
        timeout: 15000,
        maximumAge: 30000
      };

      // Start continuous tracking
      this.watchId = navigator.geolocation.watchPosition(
        (position) => {
          const locationData = this.convertPositionToLocationData(position);
          this._currentLocation.set(locationData);
          this.addToHistory(locationData, 'automatic');
          this.locationUpdated$.next(locationData);
        },
        (error) => {
          console.error('Location tracking error:', error);
          this.locationError$.next(error);
        },
        trackingOptions
      );

      // Setup interval-based tracking as backup
      if (options?.interval) {
        this.trackingInterval = setInterval(() => {
          this.getCurrentLocation({ highAccuracy: options.highAccuracy });
        }, options.interval);
      }

      this._isTracking.set(true);
      this.saveLocationSettings();

      console.log('Location tracking started');
      return true;
    } catch (error) {
      console.error('Failed to start location tracking:', error);
      return false;
    }
  }

  stopLocationTracking(): void {
    if (this.watchId !== undefined) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = undefined;
    }

    if (this.trackingInterval) {
      clearInterval(this.trackingInterval);
      this.trackingInterval = undefined;
    }

    this._isTracking.set(false);
    this.saveLocationSettings();

    console.log('Location tracking stopped');
  }

  async startLocationSharing(options?: {
    interval?: number;
    duration?: number;
    emergency?: boolean;
  }): Promise<boolean> {
    if (this._isSharing()) {
      console.log('Location sharing is already active');
      return true;
    }

    try {
      // Ensure tracking is active
      if (!this._isTracking()) {
        await this.startLocationTracking({ highAccuracy: true });
      }

      const interval = options?.interval || (options?.emergency ? 10000 : 60000); // 10s for emergency, 1min normal

      this.sharingInterval = setInterval(() => {
        const location = this._currentLocation();
        if (location) {
          this.shareLocation(location, options?.emergency);
        }
      }, interval);

      // Auto-stop after duration
      if (options?.duration) {
        setTimeout(() => {
          this.stopLocationSharing();
        }, options.duration);
      }

      this._isSharing.set(true);
      this.saveLocationSettings();

      console.log('Location sharing started');
      return true;
    } catch (error) {
      console.error('Failed to start location sharing:', error);
      return false;
    }
  }

  stopLocationSharing(): void {
    if (this.sharingInterval) {
      clearInterval(this.sharingInterval);
      this.sharingInterval = undefined;
    }

    this._isSharing.set(false);
    this.saveLocationSettings();

    console.log('Location sharing stopped');
  }

  async shareCurrentLocation(emergency: boolean = false): Promise<boolean> {
    try {
      const location = await this.getCurrentLocation({ highAccuracy: true });
      if (location) {
        return this.shareLocation(location, emergency);
      }
      return false;
    } catch (error) {
      console.error('Failed to share current location:', error);
      return false;
    }
  }

  addGeofence(geofence: Omit<GeofenceArea, 'id'>): string {
    const id = this.generateGeofenceId();
    const newGeofence: GeofenceArea = { id, ...geofence };
    
    const geofences = this._geofences();
    this._geofences.set([...geofences, newGeofence]);
    this.saveGeofences();

    return id;
  }

  updateGeofence(id: string, updates: Partial<GeofenceArea>): boolean {
    const geofences = this._geofences();
    const index = geofences.findIndex(g => g.id === id);
    
    if (index !== -1) {
      const updatedGeofences = [...geofences];
      updatedGeofences[index] = { ...updatedGeofences[index], ...updates };
      this._geofences.set(updatedGeofences);
      this.saveGeofences();
      return true;
    }
    
    return false;
  }

  removeGeofence(id: string): boolean {
    const geofences = this._geofences().filter(g => g.id !== id);
    this._geofences.set(geofences);
    this.saveGeofences();
    return true;
  }

  calculateDistance(
    point1: { latitude: number; longitude: number },
    point2: { latitude: number; longitude: number }
  ): number {
    const R = 6371e3; // Earth's radius in meters
    const φ1 = point1.latitude * Math.PI / 180;
    const φ2 = point2.latitude * Math.PI / 180;
    const Δφ = (point2.latitude - point1.latitude) * Math.PI / 180;
    const Δλ = (point2.longitude - point1.longitude) * Math.PI / 180;

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    return R * c; // Distance in meters
  }

  isLocationInGeofence(location: LocationData, geofence: GeofenceArea): boolean {
    const distance = this.calculateDistance(location, geofence.center);
    return distance <= geofence.radius;
  }

  getLocationHistory(options?: {
    limit?: number;
    type?: 'manual' | 'automatic' | 'emergency';
    since?: number;
  }): LocationHistory[] {
    let history = this._locationHistory();

    // Filter by type
    if (options?.type) {
      history = history.filter(h => h.type === options.type);
    }

    // Filter by time
    if (options?.since) {
      history = history.filter(h => h.location.timestamp >= options.since!);
    }

    // Sort by timestamp (newest first)
    history.sort((a, b) => b.location.timestamp - a.location.timestamp);

    // Limit results
    if (options?.limit) {
      history = history.slice(0, options.limit);
    }

    return history;
  }

  clearLocationHistory(): void {
    this._locationHistory.set([]);
    this.saveLocationHistory();
  }

  setLocationAccuracy(accuracy: 'high' | 'medium' | 'low'): void {
    this._locationAccuracy.set(accuracy);
    this.saveLocationSettings();

    // Restart tracking with new accuracy if active
    if (this._isTracking()) {
      this.stopLocationTracking();
      this.startLocationTracking({
        highAccuracy: accuracy === 'high'
      });
    }
  }

  // Event Observables
  get onLocationUpdated$(): Observable<LocationData> {
    return this.locationUpdated$.asObservable();
  }

  get onLocationError$(): Observable<GeolocationPositionError> {
    return this.locationError$.asObservable();
  }

  get onGeofenceEntered$(): Observable<{ location: LocationData; geofence: GeofenceArea }> {
    return this.geofenceEntered$.asObservable();
  }

  get onGeofenceExited$(): Observable<{ location: LocationData; geofence: GeofenceArea }> {
    return this.geofenceExited$.asObservable();
  }

  // Private Methods

  private async requestLocationPermission(): Promise<PermissionState> {
    try {
      if ('permissions' in navigator) {
        const permission = await navigator.permissions.query({ name: 'geolocation' });
        return permission.state;
      }
      return 'granted'; // Assume granted if permissions API not available
    } catch (error) {
      console.error('Failed to check location permission:', error);
      return 'denied';
    }
  }

  private convertPositionToLocationData(position: GeolocationPosition): LocationData {
    return {
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
      accuracy: position.coords.accuracy,
      altitude: position.coords.altitude || undefined,
      altitudeAccuracy: position.coords.altitudeAccuracy || undefined,
      heading: position.coords.heading || undefined,
      speed: position.coords.speed || undefined,
      timestamp: position.timestamp
    };
  }

  private addToHistory(location: LocationData, type: 'manual' | 'automatic' | 'emergency'): void {
    const historyItem: LocationHistory = {
      id: this.generateHistoryId(),
      location,
      type,
      shared: this._isSharing(),
      expiresAt: Date.now() + (7 * 24 * 60 * 60 * 1000) // 7 days
    };

    const history = this._locationHistory();
    const updatedHistory = [historyItem, ...history].slice(0, 1000); // Keep last 1000 entries
    this._locationHistory.set(updatedHistory);
    this.saveLocationHistory();
  }

  private async shareLocation(location: LocationData, emergency: boolean = false): Promise<boolean> {
    try {
      // This would integrate with the messaging service to share location
      console.log('Sharing location:', location, 'Emergency:', emergency);
      
      // Mark as shared in history
      const history = this._locationHistory();
      const latestEntry = history[0];
      if (latestEntry && !latestEntry.shared) {
        latestEntry.shared = true;
        this._locationHistory.set([...history]);
        this.saveLocationHistory();
      }

      return true;
    } catch (error) {
      console.error('Failed to share location:', error);
      return false;
    }
  }

  private checkGeofences(location: LocationData): void {
    const activeGeofences = this._geofences().filter(g => g.active);

    for (const geofence of activeGeofences) {
      const isInside = this.isLocationInGeofence(location, geofence);
      const wasInside = this.lastGeofenceCheck.get(geofence.id) || false;

      if (isInside && !wasInside) {
        // Entered geofence
        this.geofenceEntered$.next({ location, geofence });
        if (geofence.notifications) {
          this.showGeofenceNotification(geofence, 'entered');
        }
      } else if (!isInside && wasInside) {
        // Exited geofence
        this.geofenceExited$.next({ location, geofence });
        if (geofence.notifications) {
          this.showGeofenceNotification(geofence, 'exited');
        }
      }

      this.lastGeofenceCheck.set(geofence.id, isInside);
    }
  }

  private showGeofenceNotification(geofence: GeofenceArea, action: 'entered' | 'exited'): void {
    const message = `${action === 'entered' ? 'Girdiniz' : 'Çıktınız'}: ${geofence.name}`;
    
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification('Konum Uyarısı', {
        body: message,
        icon: '/assets/icons/icon-192x192.png'
      });
    }
  }

  private setupDefaultGeofences(): void {
    const defaultGeofences: Omit<GeofenceArea, 'id'>[] = [
      {
        name: 'Ev',
        center: { latitude: 41.0082, longitude: 28.9784 }, // Istanbul center as example
        radius: 100,
        type: 'safe',
        active: false,
        notifications: true
      },
      {
        name: 'İş Yeri',
        center: { latitude: 41.0082, longitude: 28.9784 },
        radius: 50,
        type: 'safe',
        active: false,
        notifications: true
      }
    ];

    const geofences = defaultGeofences.map(g => ({
      id: this.generateGeofenceId(),
      ...g
    }));

    this._geofences.set(geofences);
  }

  private async loadLocationSettings(): Promise<void> {
    try {
      // Load from localStorage - in real app, this would use the offline service
      const settings = localStorage.getItem('location_settings');
      if (settings) {
        const parsed = JSON.parse(settings);
        this._isTracking.set(parsed.isTracking || false);
        this._isSharing.set(parsed.isSharing || false);
        this._locationAccuracy.set(parsed.accuracy || 'medium');
      }
    } catch (error) {
      console.error('Failed to load location settings:', error);
    }
  }

  private saveLocationSettings(): void {
    try {
      const settings = {
        isTracking: this._isTracking(),
        isSharing: this._isSharing(),
        accuracy: this._locationAccuracy()
      };
      localStorage.setItem('location_settings', JSON.stringify(settings));
    } catch (error) {
      console.error('Failed to save location settings:', error);
    }
  }

  private async saveLocationHistory(): Promise<void> {
    try {
      // Save to localStorage - in real app, this would use the offline service
      localStorage.setItem('location_history', JSON.stringify(this._locationHistory()));
    } catch (error) {
      console.error('Failed to save location history:', error);
    }
  }

  private saveGeofences(): void {
    try {
      localStorage.setItem('geofences', JSON.stringify(this._geofences()));
    } catch (error) {
      console.error('Failed to save geofences:', error);
    }
  }

  private generateHistoryId(): string {
    return `loc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateGeofenceId(): string {
    return `geo_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  ngOnDestroy(): void {
    this.stopLocationTracking();
    this.stopLocationSharing();
  }
}