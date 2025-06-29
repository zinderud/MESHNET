import { Injectable, signal, computed, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject, timer } from 'rxjs';
import { filter, debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { MessagingService, EmergencyData } from '../services/messaging.service';
import { LocationService } from '../services/location.service';
import { WebApisService } from '../services/web-apis.service';
import { WebrtcService } from '../services/webrtc.service';

export interface EmergencyProtocol {
  id: string;
  name: string;
  type: 'automatic' | 'manual' | 'triggered';
  priority: 'low' | 'medium' | 'high' | 'critical';
  conditions: EmergencyCondition[];
  actions: EmergencyAction[];
  enabled: boolean;
  lastTriggered?: number;
  triggerCount: number;
}

export interface EmergencyCondition {
  type: 'battery' | 'motion' | 'location' | 'network' | 'manual' | 'time';
  operator: 'equals' | 'greater' | 'less' | 'contains' | 'exists';
  value: any;
  threshold?: number;
}

export interface EmergencyAction {
  type: 'message' | 'broadcast' | 'location' | 'alert' | 'call' | 'vibrate';
  parameters: any;
  delay?: number;
  repeat?: number;
}

export interface EmergencySession {
  id: string;
  type: EmergencyData['emergencyType'];
  severity: EmergencyData['severity'];
  startTime: number;
  endTime?: number;
  status: 'active' | 'resolved' | 'cancelled';
  location?: {
    latitude: number;
    longitude: number;
    accuracy: number;
  };
  messages: string[];
  contacts: string[];
  autoActions: string[];
  userActions: string[];
}

export interface EmergencyContact {
  id: string;
  name: string;
  phone?: string;
  email?: string;
  relationship: 'family' | 'friend' | 'medical' | 'emergency_service' | 'other';
  priority: number;
  autoNotify: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class EmergencyProtocolService {
  private messagingService = inject(MessagingService);
  private locationService = inject(LocationService);
  private webApisService = inject(WebApisService);
  private webrtcService = inject(WebrtcService);

  // Signals for reactive state management
  private _emergencyMode = signal<boolean>(false);
  private _activeSession = signal<EmergencySession | null>(null);
  private _protocols = signal<EmergencyProtocol[]>([]);
  private _emergencyContacts = signal<EmergencyContact[]>([]);
  private _emergencyHistory = signal<EmergencySession[]>([]);

  // Computed signals
  emergencyMode = this._emergencyMode.asReadonly();
  activeSession = this._activeSession.asReadonly();
  protocols = this._protocols.asReadonly();
  emergencyContacts = this._emergencyContacts.asReadonly();
  emergencyHistory = this._emergencyHistory.asReadonly();

  isEmergencyActive = computed(() => this._emergencyMode() && this._activeSession() !== null);
  activeEmergencyType = computed(() => this._activeSession()?.type || null);
  emergencyDuration = computed(() => {
    const session = this._activeSession();
    return session ? Date.now() - session.startTime : 0;
  });

  // Subjects for events
  private emergencyTriggered$ = new Subject<EmergencySession>();
  private emergencyResolved$ = new Subject<EmergencySession>();
  private protocolTriggered$ = new Subject<{ protocol: EmergencyProtocol; session: EmergencySession }>();

  constructor() {
    this.initializeProtocols();
    this.setupEmergencyDetection();
    this.setupEmergencyHandlers();
  }

  private initializeProtocols(): void {
    // Load default emergency protocols
    const defaultProtocols: EmergencyProtocol[] = [
      {
        id: 'fall-detection',
        name: 'Düşme Algılama',
        type: 'automatic',
        priority: 'high',
        conditions: [
          {
            type: 'motion',
            operator: 'greater',
            value: 'fall_detected',
            threshold: 2.5
          }
        ],
        actions: [
          {
            type: 'alert',
            parameters: { message: 'Düşme algılandı! 10 saniye içinde iptal etmezseniz acil durum mesajı gönderilecek.' },
            delay: 0
          },
          {
            type: 'message',
            parameters: {
              type: 'emergency',
              content: '🚨 DÜŞME ALGILANDI: Yardıma ihtiyacım olabilir!',
              emergencyType: 'medical'
            },
            delay: 10000
          },
          {
            type: 'vibrate',
            parameters: { pattern: 'sos' },
            delay: 0,
            repeat: 3
          }
        ],
        enabled: true,
        triggerCount: 0
      },
      {
        id: 'panic-button',
        name: 'Panik Butonu',
        type: 'manual',
        priority: 'critical',
        conditions: [
          {
            type: 'manual',
            operator: 'equals',
            value: 'panic_activated'
          }
        ],
        actions: [
          {
            type: 'broadcast',
            parameters: {
              type: 'emergency',
              content: '🚨 ACİL DURUM: Yardıma ihtiyacım var!',
              emergencyType: 'other',
              severity: 'critical'
            },
            delay: 0
          },
          {
            type: 'location',
            parameters: { share: true, continuous: true },
            delay: 0
          },
          {
            type: 'vibrate',
            parameters: { pattern: 'emergency' },
            delay: 0,
            repeat: 5
          }
        ],
        enabled: true,
        triggerCount: 0
      },
      {
        id: 'low-battery-emergency',
        name: 'Düşük Pil Acil Durumu',
        type: 'automatic',
        priority: 'medium',
        conditions: [
          {
            type: 'battery',
            operator: 'less',
            value: 10,
            threshold: 10
          }
        ],
        actions: [
          {
            type: 'message',
            parameters: {
              type: 'status',
              content: '🔋 Pilim %10\'un altında. Acil durumda ulaşılamayabilirim.',
              priority: 'high'
            },
            delay: 0
          }
        ],
        enabled: true,
        triggerCount: 0
      },
      {
        id: 'network-isolation',
        name: 'Ağ İzolasyonu',
        type: 'automatic',
        priority: 'medium',
        conditions: [
          {
            type: 'network',
            operator: 'equals',
            value: 'isolated',
            threshold: 300000 // 5 minutes
          }
        ],
        actions: [
          {
            type: 'message',
            parameters: {
              type: 'status',
              content: '📡 Ağ bağlantısı 5 dakikadır yok. Mesh ağ üzerinden iletişim kurmaya çalışıyorum.',
              priority: 'high'
            },
            delay: 0
          }
        ],
        enabled: true,
        triggerCount: 0
      }
    ];

    this._protocols.set(defaultProtocols);
    this.loadEmergencyContacts();
  }

  private setupEmergencyDetection(): void {
    // Monitor device motion for fall detection
    this.webApisService.onDeviceMotion$.subscribe(motion => {
      this.checkFallDetection(motion);
    });

    // Monitor battery level
    this.webApisService.batteryLevel$.subscribe(level => {
      this.checkBatteryEmergency(level);
    });

    // Monitor network connectivity
    this.webrtcService.connectionStatus$.subscribe(status => {
      this.checkNetworkIsolation(status);
    });

    // Periodic protocol evaluation
    setInterval(() => {
      this.evaluateProtocols();
    }, 5000);
  }

  private setupEmergencyHandlers(): void {
    // Handle emergency message responses
    this.messagingService.onMessageReceived$.pipe(
      filter(message => message.type === 'emergency')
    ).subscribe(message => {
      this.handleEmergencyResponse(message);
    });

    // Auto-resolve emergency sessions after timeout
    setInterval(() => {
      this.checkEmergencyTimeout();
    }, 60000);
  }

  // Public API Methods

  async activateEmergency(
    type: EmergencyData['emergencyType'],
    severity: EmergencyData['severity'] = 'high',
    description?: string
  ): Promise<string> {
    const sessionId = this.generateSessionId();
    const location = await this.locationService.getCurrentLocation();

    const session: EmergencySession = {
      id: sessionId,
      type,
      severity,
      startTime: Date.now(),
      status: 'active',
      location: location ? {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy
      } : undefined,
      messages: [],
      contacts: [],
      autoActions: [],
      userActions: []
    };

    this._activeSession.set(session);
    this._emergencyMode.set(true);

    // Trigger emergency protocols
    await this.executeEmergencyActions(session, description);

    // Add to history
    const history = this._emergencyHistory();
    this._emergencyHistory.set([...history, session]);

    // Emit event
    this.emergencyTriggered$.next(session);

    return sessionId;
  }

  async activatePanicButton(): Promise<string> {
    return this.activateEmergency('other', 'critical', 'Panik butonu aktivasyonu');
  }

  async resolveEmergency(sessionId?: string): Promise<void> {
    const session = this._activeSession();
    if (!session || (sessionId && session.id !== sessionId)) {
      return;
    }

    session.endTime = Date.now();
    session.status = 'resolved';

    this._activeSession.set(null);
    this._emergencyMode.set(false);

    // Update history
    this.updateEmergencyHistory(session);

    // Send resolution message
    await this.messagingService.sendMessage(
      '✅ Acil durum çözüldü. Güvendeyim.',
      'status',
      'high'
    );

    // Emit event
    this.emergencyResolved$.next(session);
  }

  async cancelEmergency(sessionId?: string): Promise<void> {
    const session = this._activeSession();
    if (!session || (sessionId && session.id !== sessionId)) {
      return;
    }

    session.endTime = Date.now();
    session.status = 'cancelled';

    this._activeSession.set(null);
    this._emergencyMode.set(false);

    // Update history
    this.updateEmergencyHistory(session);

    // Send cancellation message
    await this.messagingService.sendMessage(
      '❌ Acil durum iptal edildi. Yanlış alarm.',
      'status',
      'normal'
    );

    // Emit event
    this.emergencyResolved$.next(session);
  }

  async sendEmergencyUpdate(message: string): Promise<void> {
    const session = this._activeSession();
    if (!session) {
      throw new Error('No active emergency session');
    }

    const messageId = await this.messagingService.sendMessage(
      `🚨 ACİL DURUM GÜNCELLEMESİ: ${message}`,
      'emergency',
      'emergency'
    );

    session.messages.push(messageId);
    session.userActions.push(`update: ${message}`);
    this._activeSession.set({ ...session });
  }

  async requestSpecificHelp(helpType: string[]): Promise<void> {
    const session = this._activeSession();
    if (!session) {
      throw new Error('No active emergency session');
    }

    const helpMessage = `🆘 Özel yardım talebi: ${helpType.join(', ')}`;
    
    const messageId = await this.messagingService.sendMessage(
      helpMessage,
      'emergency',
      'emergency'
    );

    session.messages.push(messageId);
    session.userActions.push(`help_request: ${helpType.join(',')}`);
    this._activeSession.set({ ...session });
  }

  addEmergencyContact(contact: Omit<EmergencyContact, 'id'>): string {
    const contactId = this.generateContactId();
    const newContact: EmergencyContact = {
      id: contactId,
      ...contact
    };

    const contacts = this._emergencyContacts();
    this._emergencyContacts.set([...contacts, newContact]);
    this.saveEmergencyContacts();

    return contactId;
  }

  updateEmergencyContact(contactId: string, updates: Partial<EmergencyContact>): void {
    const contacts = this._emergencyContacts();
    const contactIndex = contacts.findIndex(c => c.id === contactId);

    if (contactIndex !== -1) {
      const updatedContacts = [...contacts];
      updatedContacts[contactIndex] = { ...updatedContacts[contactIndex], ...updates };
      this._emergencyContacts.set(updatedContacts);
      this.saveEmergencyContacts();
    }
  }

  removeEmergencyContact(contactId: string): void {
    const contacts = this._emergencyContacts().filter(c => c.id !== contactId);
    this._emergencyContacts.set(contacts);
    this.saveEmergencyContacts();
  }

  enableProtocol(protocolId: string): void {
    this.updateProtocol(protocolId, { enabled: true });
  }

  disableProtocol(protocolId: string): void {
    this.updateProtocol(protocolId, { enabled: false });
  }

  // Event Observables
  get onEmergencyTriggered$(): Observable<EmergencySession> {
    return this.emergencyTriggered$.asObservable();
  }

  get onEmergencyResolved$(): Observable<EmergencySession> {
    return this.emergencyResolved$.asObservable();
  }

  get onProtocolTriggered$(): Observable<{ protocol: EmergencyProtocol; session: EmergencySession }> {
    return this.protocolTriggered$.asObservable();
  }

  // Private Methods

  private async executeEmergencyActions(session: EmergencySession, description?: string): Promise<void> {
    // Find and execute relevant protocols
    const relevantProtocols = this._protocols().filter(p => 
      p.enabled && this.evaluateProtocolConditions(p, session)
    );

    for (const protocol of relevantProtocols) {
      await this.executeProtocol(protocol, session);
    }

    // Send initial emergency message
    const emergencyData: EmergencyData = {
      emergencyType: session.type,
      severity: session.severity,
      description: description || `Acil durum: ${session.type}`,
      assistanceNeeded: this.getDefaultAssistanceTypes(session.type),
      autoGenerated: true
    };

    const messageId = await this.messagingService.sendEmergencyMessage(
      session.type,
      emergencyData.description,
      session.severity,
      emergencyData.assistanceNeeded
    );

    session.messages.push(messageId);
    session.autoActions.push('initial_emergency_message');
  }

  private async executeProtocol(protocol: EmergencyProtocol, session: EmergencySession): Promise<void> {
    protocol.lastTriggered = Date.now();
    protocol.triggerCount++;

    for (const action of protocol.actions) {
      if (action.delay && action.delay > 0) {
        timer(action.delay).subscribe(() => {
          this.executeAction(action, session);
        });
      } else {
        await this.executeAction(action, session);
      }
    }

    this.updateProtocol(protocol.id, protocol);
    this.protocolTriggered$.next({ protocol, session });
  }

  private async executeAction(action: EmergencyAction, session: EmergencySession): Promise<void> {
    try {
      switch (action.type) {
        case 'message':
          const messageId = await this.messagingService.sendMessage(
            action.parameters.content,
            action.parameters.type || 'emergency',
            action.parameters.priority || 'emergency'
          );
          session.messages.push(messageId);
          break;

        case 'broadcast':
          await this.messagingService.broadcastEmergency(
            action.parameters.emergencyType || session.type,
            action.parameters.content,
            action.parameters.severity || session.severity
          );
          break;

        case 'location':
          if (action.parameters.share) {
            await this.locationService.startLocationSharing();
          }
          break;

        case 'alert':
          // Show system alert/notification
          await this.webApisService.showNotification(
            'Acil Durum',
            action.parameters.message
          );
          break;

        case 'vibrate':
          await this.webApisService.vibrate(action.parameters.pattern);
          break;

        case 'call':
          // This would integrate with phone calling API
          console.log('Emergency call action:', action.parameters);
          break;
      }

      session.autoActions.push(`${action.type}: ${JSON.stringify(action.parameters)}`);
    } catch (error) {
      console.error('Failed to execute emergency action:', error);
    }
  }

  private evaluateProtocols(): void {
    const protocols = this._protocols().filter(p => p.enabled);
    
    for (const protocol of protocols) {
      if (this.shouldTriggerProtocol(protocol)) {
        this.triggerProtocol(protocol);
      }
    }
  }

  private shouldTriggerProtocol(protocol: EmergencyProtocol): boolean {
    // Avoid triggering the same protocol too frequently
    if (protocol.lastTriggered && Date.now() - protocol.lastTriggered < 60000) {
      return false;
    }

    return protocol.conditions.every(condition => this.evaluateCondition(condition));
  }

  private evaluateCondition(condition: EmergencyCondition): boolean {
    switch (condition.type) {
      case 'battery':
        const batteryLevel = this.webApisService.batteryLevel$;
        // This is simplified - in real implementation, you'd get the actual value
        return this.compareValues(25, condition.operator, condition.value);

      case 'motion':
        // This would check actual motion data
        return condition.value === 'fall_detected' && this.lastFallDetected;

      case 'network':
        const isConnected = this.webrtcService.isConnected();
        return condition.value === 'isolated' && !isConnected;

      case 'manual':
        return condition.value === 'panic_activated' && this.panicActivated;

      default:
        return false;
    }
  }

  private evaluateProtocolConditions(protocol: EmergencyProtocol, session: EmergencySession): boolean {
    return protocol.conditions.some(condition => {
      switch (condition.type) {
        case 'manual':
          return condition.value === 'panic_activated';
        default:
          return true;
      }
    });
  }

  private compareValues(actual: any, operator: string, expected: any): boolean {
    switch (operator) {
      case 'equals': return actual === expected;
      case 'greater': return actual > expected;
      case 'less': return actual < expected;
      case 'contains': return String(actual).includes(String(expected));
      case 'exists': return actual !== null && actual !== undefined;
      default: return false;
    }
  }

  private async triggerProtocol(protocol: EmergencyProtocol): Promise<void> {
    if (!this._emergencyMode()) {
      // Auto-activate emergency for automatic protocols
      await this.activateEmergency('other', 'medium', `Otomatik protokol: ${protocol.name}`);
    }

    const session = this._activeSession();
    if (session) {
      await this.executeProtocol(protocol, session);
    }
  }

  private checkFallDetection(motion: any): void {
    // Simplified fall detection logic
    if (motion && motion.acceleration) {
      const totalAcceleration = Math.sqrt(
        motion.acceleration.x ** 2 + 
        motion.acceleration.y ** 2 + 
        motion.acceleration.z ** 2
      );

      if (totalAcceleration > 25) { // Threshold for fall detection
        this.lastFallDetected = true;
        setTimeout(() => { this.lastFallDetected = false; }, 5000);
      }
    }
  }

  private checkBatteryEmergency(level: number): void {
    if (level <= 10 && !this.lowBatteryAlerted) {
      this.lowBatteryAlerted = true;
      // This will be caught by protocol evaluation
    }
  }

  private checkNetworkIsolation(status: any): void {
    if (!status.connected) {
      if (!this.networkIsolationStart) {
        this.networkIsolationStart = Date.now();
      }
    } else {
      this.networkIsolationStart = null;
    }
  }

  private checkEmergencyTimeout(): void {
    const session = this._activeSession();
    if (session && Date.now() - session.startTime > 3600000) { // 1 hour timeout
      this.resolveEmergency(session.id);
    }
  }

  private handleEmergencyResponse(message: any): void {
    const session = this._activeSession();
    if (session) {
      session.messages.push(message.id);
      this._activeSession.set({ ...session });
    }
  }

  private getDefaultAssistanceTypes(emergencyType: EmergencyData['emergencyType']): string[] {
    switch (emergencyType) {
      case 'medical': return ['medical', 'ambulance'];
      case 'fire': return ['fire_department', 'evacuation'];
      case 'police': return ['police', 'security'];
      case 'natural_disaster': return ['rescue', 'evacuation', 'shelter'];
      case 'accident': return ['rescue', 'medical', 'police'];
      default: return ['rescue'];
    }
  }

  private updateProtocol(protocolId: string, updates: Partial<EmergencyProtocol>): void {
    const protocols = this._protocols();
    const protocolIndex = protocols.findIndex(p => p.id === protocolId);

    if (protocolIndex !== -1) {
      const updatedProtocols = [...protocols];
      updatedProtocols[protocolIndex] = { ...updatedProtocols[protocolIndex], ...updates };
      this._protocols.set(updatedProtocols);
    }
  }

  private updateEmergencyHistory(session: EmergencySession): void {
    const history = this._emergencyHistory();
    const sessionIndex = history.findIndex(s => s.id === session.id);

    if (sessionIndex !== -1) {
      const updatedHistory = [...history];
      updatedHistory[sessionIndex] = session;
      this._emergencyHistory.set(updatedHistory);
    }
  }

  private async loadEmergencyContacts(): Promise<void> {
    // Load from storage - simplified implementation
    const defaultContacts: EmergencyContact[] = [
      {
        id: 'emergency-112',
        name: '112 Acil Çağrı',
        phone: '112',
        relationship: 'emergency_service',
        priority: 1,
        autoNotify: true
      }
    ];

    this._emergencyContacts.set(defaultContacts);
  }

  private async saveEmergencyContacts(): Promise<void> {
    // Save to storage - simplified implementation
    console.log('Emergency contacts saved:', this._emergencyContacts());
  }

  private generateSessionId(): string {
    return `emergency_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateContactId(): string {
    return `contact_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Temporary state variables (in real implementation, these would be properly managed)
  private lastFallDetected = false;
  private lowBatteryAlerted = false;
  private networkIsolationStart: number | null = null;
  private panicActivated = false;
}