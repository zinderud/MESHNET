import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, interval } from 'rxjs';
import { filter, map, takeUntil } from 'rxjs/operators';

import { MeshNetworkImplementationService } from './mesh-network-implementation.service';
import { MeshRoutingService } from './mesh-routing.service';
import { WebrtcService } from './webrtc.service';
import { LocationService } from './location.service';
import { CryptoService } from './crypto.service';
import { AnalyticsService } from './analytics.service';

export interface EmergencyBroadcast {
  id: string;
  type: 'alert' | 'warning' | 'info' | 'evacuation' | 'medical' | 'security';
  severity: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  message: string;
  sender: {
    id: string;
    role: string;
    verified: boolean;
  };
  location?: {
    latitude: number;
    longitude: number;
    accuracy: number;
  };
  timestamp: number;
  expiresAt?: number;
  acknowledgements: number;
  deliveryStatus: 'pending' | 'partial' | 'complete' | 'failed';
  priority: number; // 0-100
  targetArea?: {
    center: { latitude: number; longitude: number };
    radius: number; // meters
  };
  actionRequired?: string;
  attachments?: Array<{
    type: string;
    url?: string;
    data?: string;
  }>;
}

export interface BroadcastStatistics {
  totalBroadcasts: number;
  activeBroadcasts: number;
  deliveryRate: number;
  averageAcknowledgements: number;
  criticalAlerts: number;
  lastBroadcastTime: number;
}

@Injectable({
  providedIn: 'root'
})
export class EmergencyBroadcastService {
  private meshService = inject(MeshNetworkImplementationService);
  private routingService = inject(MeshRoutingService);
  private webrtcService = inject(WebrtcService);
  private locationService = inject(LocationService);
  private cryptoService = inject(CryptoService);
  private analyticsService = inject(AnalyticsService);

  // Signals for reactive broadcast state
  private _activeBroadcasts = signal<Map<string, EmergencyBroadcast>>(new Map());
  private _broadcastHistory = signal<EmergencyBroadcast[]>([]);
  private _broadcastStats = signal<BroadcastStatistics>({
    totalBroadcasts: 0,
    activeBroadcasts: 0,
    deliveryRate: 0,
    averageAcknowledgements: 0,
    criticalAlerts: 0,
    lastBroadcastTime: 0
  });
  private _isEmergencyActive = signal<boolean>(false);

  // Computed broadcast indicators
  activeBroadcasts = this._activeBroadcasts.asReadonly();
  broadcastHistory = this._broadcastHistory.asReadonly();
  broadcastStats = this._broadcastStats.asReadonly();
  isEmergencyActive = this._isEmergencyActive.asReadonly();

  activeBroadcastCount = computed(() => this._activeBroadcasts().size);
  criticalBroadcastCount = computed(() => 
    Array.from(this._activeBroadcasts().values()).filter(b => b.severity === 'critical').length
  );
  latestBroadcast = computed(() => {
    const broadcasts = Array.from(this._activeBroadcasts().values());
    if (broadcasts.length === 0) return null;
    return broadcasts.sort((a, b) => b.timestamp - a.timestamp)[0];
  });

  // Broadcast events
  private broadcastSent$ = new Subject<EmergencyBroadcast>();
  private broadcastReceived$ = new Subject<EmergencyBroadcast>();
  private broadcastAcknowledged$ = new Subject<{ broadcastId: string; nodeId: string }>();
  private broadcastExpired$ = new Subject<string>();
  private emergencyStatusChanged$ = new Subject<boolean>();

  private destroy$ = new Subject<void>();

  constructor() {
    this.initializeBroadcastService();
    this.setupBroadcastHandlers();
    this.startBroadcastMaintenance();
  }

  private initializeBroadcastService(): void {
    // Load saved broadcasts
    this.loadSavedBroadcasts();
    
    // Setup emergency status monitoring
    this.monitorEmergencyStatus();
    
    console.log('Emergency Broadcast Service initialized');
  }

  private setupBroadcastHandlers(): void {
    // Listen for incoming broadcasts from mesh network
    this.meshService.onMeshMessageRouted$.subscribe(message => {
      if (message.type === 'broadcast' && message.emergencyLevel) {
        this.handleIncomingBroadcast(message.payload);
      }
    });
    
    // Listen for WebRTC broadcasts
    this.webrtcService.onDataReceived$.subscribe(data => {
      if (data.type === 'emergency' && data.payload) {
        this.handleIncomingBroadcast(data.payload);
      }
    });
  }

  private startBroadcastMaintenance(): void {
    // Periodically check for expired broadcasts
    interval(60000).pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.cleanupExpiredBroadcasts();
      this.updateBroadcastStatistics();
    });
    
    // Periodically retry failed broadcasts
    interval(30000).pipe(
      takeUntil(this.destroy$),
      filter(() => this._isEmergencyActive())
    ).subscribe(() => {
      this.retryFailedBroadcasts();
    });
  }

  // Public API Methods
  async createEmergencyBroadcast(
    type: EmergencyBroadcast['type'],
    severity: EmergencyBroadcast['severity'],
    title: string,
    message: string,
    options?: {
      expiresIn?: number; // milliseconds
      targetArea?: {
        center: { latitude: number; longitude: number };
        radius: number;
      };
      actionRequired?: string;
      attachments?: EmergencyBroadcast['attachments'];
    }
  ): Promise<string> {
    try {
      const location = await this.locationService.getCurrentLocation();
      
      const broadcast: EmergencyBroadcast = {
        id: this.generateBroadcastId(),
        type,
        severity,
        title,
        message,
        sender: {
          id: this.getSenderId(),
          role: this.getSenderRole(),
          verified: true
        },
        location: location ? {
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy
        } : undefined,
        timestamp: Date.now(),
        expiresAt: options?.expiresIn ? Date.now() + options.expiresIn : undefined,
        acknowledgements: 0,
        deliveryStatus: 'pending',
        priority: this.calculateBroadcastPriority(severity, type),
        targetArea: options?.targetArea,
        actionRequired: options?.actionRequired,
        attachments: options?.attachments
      };
      
      // Add to active broadcasts
      const broadcasts = new Map(this._activeBroadcasts());
      broadcasts.set(broadcast.id, broadcast);
      this._activeBroadcasts.set(broadcasts);
      
      // Add to history
      const history = [broadcast, ...this._broadcastHistory()].slice(0, 100);
      this._broadcastHistory.set(history);
      
      // Send broadcast
      await this.sendBroadcast(broadcast);
      
      // Update statistics
      this.updateBroadcastStatistics();
      
      // Track analytics
      this.analyticsService.trackEvent('emergency', 'broadcast_created', type, severity);
      
      return broadcast.id;
    } catch (error) {
      console.error('Failed to create emergency broadcast:', error);
      throw error;
    }
  }

  async acknowledgeBroadcast(broadcastId: string): Promise<boolean> {
    const broadcasts = new Map(this._activeBroadcasts());
    const broadcast = broadcasts.get(broadcastId);
    
    if (!broadcast) {
      return false;
    }
    
    // Update acknowledgements
    broadcast.acknowledgements++;
    broadcasts.set(broadcastId, broadcast);
    this._activeBroadcasts.set(broadcasts);
    
    // Send acknowledgement
    await this.sendBroadcastAcknowledgement(broadcastId);
    
    // Emit event
    this.broadcastAcknowledged$.next({ 
      broadcastId, 
      nodeId: this.getSenderId() 
    });
    
    return true;
  }

  cancelBroadcast(broadcastId: string): boolean {
    const broadcasts = new Map(this._activeBroadcasts());
    const broadcast = broadcasts.get(broadcastId);
    
    if (!broadcast) {
      return false;
    }
    
    // Only the sender can cancel
    if (broadcast.sender.id !== this.getSenderId()) {
      return false;
    }
    
    // Remove from active broadcasts
    broadcasts.delete(broadcastId);
    this._activeBroadcasts.set(broadcasts);
    
    // Send cancellation message
    this.sendBroadcastCancellation(broadcastId);
    
    return true;
  }

  getBroadcastById(broadcastId: string): EmergencyBroadcast | null {
    return this._activeBroadcasts().get(broadcastId) || null;
  }

  getBroadcastsByType(type: EmergencyBroadcast['type']): EmergencyBroadcast[] {
    return Array.from(this._activeBroadcasts().values())
      .filter(broadcast => broadcast.type === type)
      .sort((a, b) => b.timestamp - a.timestamp);
  }

  getBroadcastsBySeverity(severity: EmergencyBroadcast['severity']): EmergencyBroadcast[] {
    return Array.from(this._activeBroadcasts().values())
      .filter(broadcast => broadcast.severity === severity)
      .sort((a, b) => b.timestamp - a.timestamp);
  }

  // Event Observables
  get onBroadcastSent$(): Observable<EmergencyBroadcast> {
    return this.broadcastSent$.asObservable();
  }

  get onBroadcastReceived$(): Observable<EmergencyBroadcast> {
    return this.broadcastReceived$.asObservable();
  }

  get onBroadcastAcknowledged$(): Observable<{ broadcastId: string; nodeId: string }> {
    return this.broadcastAcknowledged$.asObservable();
  }

  get onBroadcastExpired$(): Observable<string> {
    return this.broadcastExpired$.asObservable();
  }

  get onEmergencyStatusChanged$(): Observable<boolean> {
    return this.emergencyStatusChanged$.asObservable();
  }

  // Private Methods
  private async sendBroadcast(broadcast: EmergencyBroadcast): Promise<boolean> {
    try {
      // Send via mesh network
      const meshSuccess = await this.sendViaMeshNetwork(broadcast);
      
      // Send via WebRTC as backup
      const webrtcSuccess = await this.sendViaWebRTC(broadcast);
      
      // Update delivery status
      const broadcasts = new Map(this._activeBroadcasts());
      const updatedBroadcast = broadcasts.get(broadcast.id);
      
      if (updatedBroadcast) {
        updatedBroadcast.deliveryStatus = 
          meshSuccess || webrtcSuccess ? 'partial' : 'failed';
        
        broadcasts.set(broadcast.id, updatedBroadcast);
        this._activeBroadcasts.set(broadcasts);
      }
      
      // Emit event
      this.broadcastSent$.next(broadcast);
      
      return meshSuccess || webrtcSuccess;
    } catch (error) {
      console.error('Failed to send broadcast:', error);
      return false;
    }
  }

  private async sendViaMeshNetwork(broadcast: EmergencyBroadcast): Promise<boolean> {
    try {
      if (!this.meshService.isEmergencyMode()) {
        await this.meshService.createEmergencyMeshNetwork('broadcast', broadcast.severity);
      }
      
      // Send as mesh message
      await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: this.convertSeverityToPriority(broadcast.severity),
        payload: broadcast,
        source: this.getSenderId(),
        ttl: 10,
        emergencyLevel: this.convertSeverityToEmergencyLevel(broadcast.severity)
      });
      
      return true;
    } catch (error) {
      console.error('Failed to send via mesh network:', error);
      return false;
    }
  }

  private async sendViaWebRTC(broadcast: EmergencyBroadcast): Promise<boolean> {
    try {
      // Send to all connected WebRTC peers
      const peers = this.webrtcService.getConnectedPeers();
      let successCount = 0;
      
      for (const peer of peers) {
        const success = await this.webrtcService.sendData(peer.id, {
          type: 'emergency',
          payload: broadcast,
          priority: 'emergency'
        });
        
        if (success) successCount++;
      }
      
      return successCount > 0;
    } catch (error) {
      console.error('Failed to send via WebRTC:', error);
      return false;
    }
  }

  private async sendBroadcastAcknowledgement(broadcastId: string): Promise<void> {
    try {
      // Send acknowledgement via mesh network
      await this.meshService.sendMeshMessage({
        type: 'unicast',
        priority: 'normal',
        payload: {
          type: 'broadcast_ack',
          broadcastId,
          timestamp: Date.now()
        },
        source: this.getSenderId(),
        ttl: 5
      });
    } catch (error) {
      console.error('Failed to send broadcast acknowledgement:', error);
    }
  }

  private async sendBroadcastCancellation(broadcastId: string): Promise<void> {
    try {
      // Send cancellation via mesh network
      await this.meshService.sendMeshMessage({
        type: 'broadcast',
        priority: 'high',
        payload: {
          type: 'broadcast_cancel',
          broadcastId,
          timestamp: Date.now()
        },
        source: this.getSenderId(),
        ttl: 10
      });
    } catch (error) {
      console.error('Failed to send broadcast cancellation:', error);
    }
  }

  private handleIncomingBroadcast(payload: any): void {
    try {
      const broadcast = payload as EmergencyBroadcast;
      
      // Validate broadcast
      if (!this.validateBroadcast(broadcast)) {
        console.warn('Invalid broadcast received:', broadcast);
        return;
      }
      
      // Check if already received
      if (this._activeBroadcasts().has(broadcast.id)) {
        return;
      }
      
      // Check if in target area (if specified)
      if (broadcast.targetArea && !this.isInTargetArea(broadcast.targetArea)) {
        return;
      }
      
      // Add to active broadcasts
      const broadcasts = new Map(this._activeBroadcasts());
      broadcasts.set(broadcast.id, broadcast);
      this._activeBroadcasts.set(broadcasts);
      
      // Add to history
      const history = [broadcast, ...this._broadcastHistory()].slice(0, 100);
      this._broadcastHistory.set(history);
      
      // Emit event
      this.broadcastReceived$.next(broadcast);
      
      // Auto-acknowledge
      this.acknowledgeBroadcast(broadcast.id);
      
      // Track analytics
      this.analyticsService.trackEvent('emergency', 'broadcast_received', broadcast.type, broadcast.severity);
      
      // Set emergency active if critical
      if (broadcast.severity === 'critical' && !this._isEmergencyActive()) {
        this._isEmergencyActive.set(true);
        this.emergencyStatusChanged$.next(true);
      }
    } catch (error) {
      console.error('Failed to handle incoming broadcast:', error);
    }
  }

  private validateBroadcast(broadcast: EmergencyBroadcast): boolean {
    // Basic validation
    if (!broadcast.id || !broadcast.type || !broadcast.severity || !broadcast.message) {
      return false;
    }
    
    // Check timestamp (not too old or future)
    const now = Date.now();
    if (broadcast.timestamp < now - 3600000 || broadcast.timestamp > now + 60000) {
      return false;
    }
    
    // Check if expired
    if (broadcast.expiresAt && broadcast.expiresAt < now) {
      return false;
    }
    
    return true;
  }

  private async isInTargetArea(targetArea: EmergencyBroadcast['targetArea']): Promise<boolean> {
    if (!targetArea) return true;
    
    const location = await this.locationService.getCurrentLocation();
    if (!location) return true; // If no location, assume in target area
    
    const distance = this.locationService.calculateDistance(
      { latitude: location.latitude, longitude: location.longitude },
      targetArea.center
    );
    
    return distance <= targetArea.radius;
  }

  private cleanupExpiredBroadcasts(): void {
    const broadcasts = new Map(this._activeBroadcasts());
    const now = Date.now();
    
    // Remove expired broadcasts
    broadcasts.forEach((broadcast, id) => {
      if (broadcast.expiresAt && broadcast.expiresAt < now) {
        broadcasts.delete(id);
        this.broadcastExpired$.next(id);
      }
    });
    
    this._activeBroadcasts.set(broadcasts);
  }

  private retryFailedBroadcasts(): void {
    const broadcasts = new Map(this._activeBroadcasts());
    
    // Retry failed broadcasts
    broadcasts.forEach(async (broadcast, id) => {
      if (broadcast.deliveryStatus === 'failed' || broadcast.deliveryStatus === 'pending') {
        await this.sendBroadcast(broadcast);
      }
    });
  }

  private updateBroadcastStatistics(): void {
    const broadcasts = this._activeBroadcasts();
    const broadcastArray = Array.from(broadcasts.values());
    
    const stats: BroadcastStatistics = {
      totalBroadcasts: this._broadcastHistory().length,
      activeBroadcasts: broadcasts.size,
      deliveryRate: this.calculateDeliveryRate(broadcastArray),
      averageAcknowledgements: this.calculateAverageAcknowledgements(broadcastArray),
      criticalAlerts: broadcastArray.filter(b => b.severity === 'critical').length,
      lastBroadcastTime: broadcastArray.length > 0 
        ? Math.max(...broadcastArray.map(b => b.timestamp))
        : 0
    };
    
    this._broadcastStats.set(stats);
  }

  private calculateDeliveryRate(broadcasts: EmergencyBroadcast[]): number {
    if (broadcasts.length === 0) return 0;
    
    const successfulDeliveries = broadcasts.filter(b => 
      b.deliveryStatus === 'complete' || b.deliveryStatus === 'partial'
    ).length;
    
    return (successfulDeliveries / broadcasts.length) * 100;
  }

  private calculateAverageAcknowledgements(broadcasts: EmergencyBroadcast[]): number {
    if (broadcasts.length === 0) return 0;
    
    const totalAcks = broadcasts.reduce((sum, b) => sum + b.acknowledgements, 0);
    return totalAcks / broadcasts.length;
  }

  private calculateBroadcastPriority(severity: EmergencyBroadcast['severity'], type: EmergencyBroadcast['type']): number {
    // Calculate priority (0-100) based on severity and type
    const severityScore = {
      'critical': 100,
      'high': 75,
      'medium': 50,
      'low': 25
    }[severity] || 50;
    
    const typeScore = {
      'evacuation': 20,
      'medical': 15,
      'security': 15,
      'alert': 10,
      'warning': 5,
      'info': 0
    }[type] || 0;
    
    return Math.min(100, severityScore + typeScore);
  }

  private convertSeverityToPriority(severity: EmergencyBroadcast['severity']): 'low' | 'normal' | 'high' | 'emergency' {
    switch (severity) {
      case 'critical': return 'emergency';
      case 'high': return 'high';
      case 'medium': return 'normal';
      case 'low': return 'low';
      default: return 'normal';
    }
  }

  private convertSeverityToEmergencyLevel(severity: EmergencyBroadcast['severity']): 'info' | 'warning' | 'alert' | 'critical' {
    switch (severity) {
      case 'critical': return 'critical';
      case 'high': return 'alert';
      case 'medium': return 'warning';
      case 'low': return 'info';
      default: return 'info';
    }
  }

  private monitorEmergencyStatus(): void {
    // Monitor mesh service emergency mode
    this.meshService.isEmergencyMode.subscribe(isEmergency => {
      if (isEmergency !== this._isEmergencyActive()) {
        this._isEmergencyActive.set(isEmergency);
        this.emergencyStatusChanged$.next(isEmergency);
      }
    });
  }

  private loadSavedBroadcasts(): void {
    try {
      const savedBroadcasts = localStorage.getItem('emergency_broadcasts');
      const savedHistory = localStorage.getItem('broadcast_history');
      
      if (savedBroadcasts) {
        const broadcasts = new Map<string, EmergencyBroadcast>();
        const parsed = JSON.parse(savedBroadcasts);
        
        Object.entries(parsed).forEach(([id, broadcast]) => {
          broadcasts.set(id, broadcast as EmergencyBroadcast);
        });
        
        this._activeBroadcasts.set(broadcasts);
      }
      
      if (savedHistory) {
        this._broadcastHistory.set(JSON.parse(savedHistory));
      }
    } catch (error) {
      console.error('Failed to load saved broadcasts:', error);
    }
  }

  private saveBroadcasts(): void {
    try {
      const broadcasts = this._activeBroadcasts();
      const history = this._broadcastHistory();
      
      localStorage.setItem('emergency_broadcasts', 
        JSON.stringify(Object.fromEntries(broadcasts))
      );
      
      localStorage.setItem('broadcast_history', 
        JSON.stringify(history)
      );
    } catch (error) {
      console.error('Failed to save broadcasts:', error);
    }
  }

  private generateBroadcastId(): string {
    return `broadcast_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private getSenderId(): string {
    return this.meshService.localMeshNode()?.id || 'unknown';
  }

  private getSenderRole(): string {
    return this.meshService.localMeshNode()?.type || 'endpoint';
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}