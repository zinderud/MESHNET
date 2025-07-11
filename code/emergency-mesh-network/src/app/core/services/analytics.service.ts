import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, interval } from 'rxjs';
import { filter, map, debounceTime } from 'rxjs/operators';

export interface AnalyticsEvent {
  id: string;
  type: 'user_action' | 'system_event' | 'performance' | 'error' | 'emergency';
  category: string;
  action: string;
  label?: string;
  value?: number;
  metadata?: Record<string, any>;
  timestamp: number;
  sessionId: string;
  userId?: string;
}

export interface SessionMetrics {
  sessionId: string;
  startTime: number;
  endTime?: number;
  duration: number;
  pageViews: number;
  userActions: number;
  errors: number;
  emergencyActivations: number;
  networkEvents: number;
}

export interface UsageStatistics {
  totalSessions: number;
  averageSessionDuration: number;
  totalEmergencyActivations: number;
  totalMessagesExchanged: number;
  totalNetworkConnections: number;
  averageResponseTime: number;
  errorRate: number;
  lastUpdated: number;
}

@Injectable({
  providedIn: 'root'
})
export class AnalyticsService {
  // Signals for reactive analytics
  private _events = signal<AnalyticsEvent[]>([]);
  private _currentSession = signal<SessionMetrics | null>(null);
  private _usageStats = signal<UsageStatistics>({
    totalSessions: 0,
    averageSessionDuration: 0,
    totalEmergencyActivations: 0,
    totalMessagesExchanged: 0,
    totalNetworkConnections: 0,
    averageResponseTime: 0,
    errorRate: 0,
    lastUpdated: Date.now()
  });

  // Computed analytics
  events = this._events.asReadonly();
  currentSession = this._currentSession.asReadonly();
  usageStats = this._usageStats.asReadonly();

  recentEvents = computed(() => 
    this._events().filter(e => Date.now() - e.timestamp < 3600000) // Last hour
  );

  emergencyEvents = computed(() => 
    this._events().filter(e => e.type === 'emergency')
  );

  errorEvents = computed(() => 
    this._events().filter(e => e.type === 'error')
  );

  performanceEvents = computed(() => 
    this._events().filter(e => e.type === 'performance')
  );

  // Analytics subjects
  private eventTracked$ = new BehaviorSubject<AnalyticsEvent | null>(null);

  // Session management
  private sessionId: string;
  private userId?: string;

  constructor() {
    this.sessionId = this.generateSessionId();
    this.initializeSession();
    this.setupAnalyticsTracking();
    this.startPeriodicReporting();
  }

  private initializeSession(): void {
    const session: SessionMetrics = {
      sessionId: this.sessionId,
      startTime: Date.now(),
      duration: 0,
      pageViews: 0,
      userActions: 0,
      errors: 0,
      emergencyActivations: 0,
      networkEvents: 0
    };

    this._currentSession.set(session);
    this.trackEvent('system_event', 'session', 'start');
  }

  private setupAnalyticsTracking(): void {
    // Track page visibility changes
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        this.trackEvent('system_event', 'page', 'hidden');
      } else {
        this.trackEvent('system_event', 'page', 'visible');
      }
    });

    // Track page unload
    window.addEventListener('beforeunload', () => {
      this.endSession();
    });

    // Update session duration periodically
    interval(30000).subscribe(() => {
      this.updateSessionDuration();
    });
  }

  private startPeriodicReporting(): void {
    // Generate usage reports every 5 minutes
    interval(300000).subscribe(() => {
      this.generateUsageReport();
    });

    // Clean up old events every hour
    interval(3600000).subscribe(() => {
      this.cleanupOldEvents();
    });
  }

  // Public API for event tracking
  trackEvent(
    type: AnalyticsEvent['type'],
    category: string,
    action: string,
    label?: string,
    value?: number,
    metadata?: Record<string, any>
  ): string {
    const event: AnalyticsEvent = {
      id: this.generateEventId(),
      type,
      category,
      action,
      label,
      value,
      metadata,
      timestamp: Date.now(),
      sessionId: this.sessionId,
      userId: this.userId
    };

    // Add to events list
    const events = this._events();
    this._events.set([...events, event]);

    // Update session metrics
    this.updateSessionMetrics(event);

    // Emit event
    this.eventTracked$.next(event);

    // Store in local storage for persistence
    this.persistEvent(event);

    return event.id;
  }

  // Specific tracking methods
  trackUserAction(action: string, label?: string, metadata?: Record<string, any>): string {
    return this.trackEvent('user_action', 'interaction', action, label, undefined, metadata);
  }

  trackEmergencyActivation(emergencyType: string, severity: string): string {
    return this.trackEvent('emergency', 'activation', emergencyType, severity, undefined, {
      timestamp: Date.now(),
      location: 'unknown' // Would be populated by location service
    });
  }

  trackMessageSent(messageType: string, recipientCount: number): string {
    return this.trackEvent('user_action', 'messaging', 'send', messageType, recipientCount);
  }

  trackNetworkConnection(connectionType: string, success: boolean): string {
    return this.trackEvent('system_event', 'network', 'connection', connectionType, success ? 1 : 0);
  }

  trackPerformanceMetric(metric: string, value: number, unit: string): string {
    return this.trackEvent('performance', 'metric', metric, unit, value);
  }

  trackError(errorType: string, errorMessage: string, metadata?: Record<string, any>): string {
    return this.trackEvent('error', errorType, 'occurred', errorMessage, undefined, {
      ...metadata,
      userAgent: navigator.userAgent,
      url: window.location.href
    });
  }

  // Page tracking
  trackPageView(pageName: string): string {
    const session = this._currentSession();
    if (session) {
      this._currentSession.set({
        ...session,
        pageViews: session.pageViews + 1
      });
    }

    return this.trackEvent('user_action', 'navigation', 'page_view', pageName);
  }

  // Session management
  private updateSessionMetrics(event: AnalyticsEvent): void {
    const session = this._currentSession();
    if (!session) return;

    const updatedSession = { ...session };

    switch (event.type) {
      case 'user_action':
        updatedSession.userActions++;
        break;
      case 'error':
        updatedSession.errors++;
        break;
      case 'emergency':
        updatedSession.emergencyActivations++;
        break;
      case 'system_event':
        if (event.category === 'network') {
          updatedSession.networkEvents++;
        }
        break;
    }

    this._currentSession.set(updatedSession);
  }

  private updateSessionDuration(): void {
    const session = this._currentSession();
    if (session) {
      const duration = Date.now() - session.startTime;
      this._currentSession.set({
        ...session,
        duration
      });
    }
  }

  private endSession(): void {
    const session = this._currentSession();
    if (session) {
      const endTime = Date.now();
      const finalSession = {
        ...session,
        endTime,
        duration: endTime - session.startTime
      };

      this._currentSession.set(finalSession);
      this.trackEvent('system_event', 'session', 'end');
      
      // Update usage statistics
      this.updateUsageStatistics(finalSession);
    }
  }

  // Usage statistics
  private generateUsageReport(): void {
    const events = this._events();
    const session = this._currentSession();
    
    if (!session) return;

    const stats = this._usageStats();
    const emergencyCount = events.filter(e => e.type === 'emergency').length;
    const messageCount = events.filter(e => 
      e.category === 'messaging' && e.action === 'send'
    ).length;
    const networkCount = events.filter(e => 
      e.category === 'network' && e.action === 'connection'
    ).length;
    const errorCount = events.filter(e => e.type === 'error').length;

    const updatedStats: UsageStatistics = {
      totalSessions: stats.totalSessions + 1,
      averageSessionDuration: session.duration,
      totalEmergencyActivations: stats.totalEmergencyActivations + emergencyCount,
      totalMessagesExchanged: stats.totalMessagesExchanged + messageCount,
      totalNetworkConnections: stats.totalNetworkConnections + networkCount,
      averageResponseTime: this.calculateAverageResponseTime(),
      errorRate: errorCount / Math.max(events.length, 1) * 100,
      lastUpdated: Date.now()
    };

    this._usageStats.set(updatedStats);
    this.persistUsageStats(updatedStats);
  }

  private updateUsageStatistics(session: SessionMetrics): void {
    const stats = this._usageStats();
    
    // Calculate new averages
    const totalSessions = stats.totalSessions + 1;
    const newAverageDuration = (
      (stats.averageSessionDuration * stats.totalSessions + session.duration) / totalSessions
    );

    const updatedStats: UsageStatistics = {
      ...stats,
      totalSessions,
      averageSessionDuration: newAverageDuration,
      totalEmergencyActivations: stats.totalEmergencyActivations + session.emergencyActivations,
      lastUpdated: Date.now()
    };

    this._usageStats.set(updatedStats);
    this.persistUsageStats(updatedStats);
  }

  private calculateAverageResponseTime(): number {
    const performanceEvents = this.performanceEvents();
    const responseTimes = performanceEvents
      .filter(e => e.action === 'response_time')
      .map(e => e.value || 0);

    if (responseTimes.length === 0) return 0;
    
    return responseTimes.reduce((sum, time) => sum + time, 0) / responseTimes.length;
  }

  // Data persistence
  private persistEvent(event: AnalyticsEvent): void {
    try {
      const key = `analytics_event_${event.id}`;
      localStorage.setItem(key, JSON.stringify(event));
    } catch (error) {
      console.error('Failed to persist analytics event:', error);
    }
  }

  private persistUsageStats(stats: UsageStatistics): void {
    try {
      localStorage.setItem('usage_statistics', JSON.stringify(stats));
    } catch (error) {
      console.error('Failed to persist usage statistics:', error);
    }
  }

  private cleanupOldEvents(): void {
    const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
    
    // Remove old events from memory
    const recentEvents = this._events().filter(e => e.timestamp > oneWeekAgo);
    this._events.set(recentEvents);

    // Remove old events from localStorage
    Object.keys(localStorage).forEach(key => {
      if (key.startsWith('analytics_event_')) {
        try {
          const event = JSON.parse(localStorage.getItem(key) || '');
          if (event.timestamp < oneWeekAgo) {
            localStorage.removeItem(key);
          }
        } catch {
          localStorage.removeItem(key);
        }
      }
    });
  }

  // Analytics queries
  getEventsByCategory(category: string): AnalyticsEvent[] {
    return this._events().filter(e => e.category === category);
  }

  getEventsByTimeRange(startTime: number, endTime: number): AnalyticsEvent[] {
    return this._events().filter(e => 
      e.timestamp >= startTime && e.timestamp <= endTime
    );
  }

  getTopActions(limit: number = 10): Array<{ action: string; count: number }> {
    const actionCounts = new Map<string, number>();
    
    this._events().forEach(event => {
      const key = `${event.category}:${event.action}`;
      actionCounts.set(key, (actionCounts.get(key) || 0) + 1);
    });

    return Array.from(actionCounts.entries())
      .map(([action, count]) => ({ action, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, limit);
  }

  getErrorSummary(): Array<{ error: string; count: number; lastOccurred: number }> {
    const errorMap = new Map<string, { count: number; lastOccurred: number }>();
    
    this.errorEvents().forEach(event => {
      const errorKey = event.label || 'Unknown Error';
      const existing = errorMap.get(errorKey) || { count: 0, lastOccurred: 0 };
      
      errorMap.set(errorKey, {
        count: existing.count + 1,
        lastOccurred: Math.max(existing.lastOccurred, event.timestamp)
      });
    });

    return Array.from(errorMap.entries())
      .map(([error, data]) => ({ error, ...data }))
      .sort((a, b) => b.count - a.count);
  }

  // Privacy and data management
  setUserId(userId: string): void {
    this.userId = userId;
  }

  clearUserId(): void {
    this.userId = undefined;
  }

  exportAnalyticsData(): string {
    const data = {
      events: this._events(),
      session: this._currentSession(),
      stats: this._usageStats(),
      exportTime: Date.now()
    };
    
    return JSON.stringify(data, null, 2);
  }

  clearAnalyticsData(): void {
    this._events.set([]);
    this._usageStats.set({
      totalSessions: 0,
      averageSessionDuration: 0,
      totalEmergencyActivations: 0,
      totalMessagesExchanged: 0,
      totalNetworkConnections: 0,
      averageResponseTime: 0,
      errorRate: 0,
      lastUpdated: Date.now()
    });

    // Clear localStorage
    Object.keys(localStorage).forEach(key => {
      if (key.startsWith('analytics_') || key === 'usage_statistics') {
        localStorage.removeItem(key);
      }
    });
  }

  // Event observables
  getEventStream(): Observable<AnalyticsEvent> {
    return this.eventTracked$.pipe(
      filter(event => event !== null),
      map(event => event!)
    );
  }

  getEmergencyEventStream(): Observable<AnalyticsEvent> {
    return this.getEventStream().pipe(
      filter(event => event.type === 'emergency')
    );
  }

  getErrorEventStream(): Observable<AnalyticsEvent> {
    return this.getEventStream().pipe(
      filter(event => event.type === 'error')
    );
  }

  // Utility methods
  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateEventId(): string {
    return `event_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Load persisted data on initialization
  private loadPersistedData(): void {
    try {
      // Load usage statistics
      const savedStats = localStorage.getItem('usage_statistics');
      if (savedStats) {
        this._usageStats.set(JSON.parse(savedStats));
      }

      // Load recent events
      const events: AnalyticsEvent[] = [];
      Object.keys(localStorage).forEach(key => {
        if (key.startsWith('analytics_event_')) {
          try {
            const event = JSON.parse(localStorage.getItem(key) || '');
            events.push(event);
          } catch {
            localStorage.removeItem(key);
          }
        }
      });

      // Sort events by timestamp
      events.sort((a, b) => a.timestamp - b.timestamp);
      this._events.set(events);
    } catch (error) {
      console.error('Failed to load persisted analytics data:', error);
    }
  }
}