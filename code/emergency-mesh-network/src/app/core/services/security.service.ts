import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, interval } from 'rxjs';
import { filter, map } from 'rxjs/operators';

export interface SecurityThreat {
  id: string;
  type: 'malicious_peer' | 'spam_message' | 'invalid_signature' | 'replay_attack' | 'dos_attack';
  severity: 'low' | 'medium' | 'high' | 'critical';
  source: string;
  description: string;
  timestamp: number;
  blocked: boolean;
}

export interface SecurityMetrics {
  threatsDetected: number;
  threatsBlocked: number;
  suspiciousPeers: number;
  invalidMessages: number;
  lastThreatTime: number;
  securityScore: number;
}

export interface SecurityPolicy {
  maxMessagesPerMinute: number;
  maxConnectionsPerPeer: number;
  messageSignatureRequired: boolean;
  blockSuspiciousPeers: boolean;
  quarantineTime: number; // milliseconds
  autoBlockThreshold: number;
}

@Injectable({
  providedIn: 'root'
})
export class SecurityService {
  // Signals for reactive security monitoring
  private _threats = signal<SecurityThreat[]>([]);
  private _metrics = signal<SecurityMetrics>({
    threatsDetected: 0,
    threatsBlocked: 0,
    suspiciousPeers: 0,
    invalidMessages: 0,
    lastThreatTime: 0,
    securityScore: 100
  });

  private _securityPolicy = signal<SecurityPolicy>({
    maxMessagesPerMinute: 60,
    maxConnectionsPerPeer: 5,
    messageSignatureRequired: true,
    blockSuspiciousPeers: true,
    quarantineTime: 300000, // 5 minutes
    autoBlockThreshold: 5
  });

  // Computed security indicators
  threats = this._threats.asReadonly();
  metrics = this._metrics.asReadonly();
  securityPolicy = this._securityPolicy.asReadonly();
  
  activeThreatCount = computed(() => 
    this._threats().filter(t => !t.blocked && Date.now() - t.timestamp < 300000).length
  );
  
  criticalThreats = computed(() => 
    this._threats().filter(t => t.severity === 'critical' && !t.blocked)
  );
  
  securityStatus = computed(() => {
    const score = this._metrics().securityScore;
    if (score >= 90) return 'excellent';
    if (score >= 70) return 'good';
    if (score >= 50) return 'fair';
    return 'poor';
  });

  // Security monitoring subjects
  private threatDetected$ = new BehaviorSubject<SecurityThreat | null>(null);
  private securityAlert$ = new BehaviorSubject<string | null>(null);

  // Blacklists and reputation system
  private blacklistedPeers = new Set<string>();
  private peerReputation = new Map<string, number>();
  private messageRateLimit = new Map<string, number[]>();

  constructor() {
    this.initializeSecurityMonitoring();
    this.setupThreatDetection();
    this.startSecurityScanning();
  }

  private initializeSecurityMonitoring(): void {
    // Load security policies from storage
    this.loadSecurityPolicies();
    
    // Setup automatic threat cleanup
    interval(60000).subscribe(() => {
      this.cleanupOldThreats();
      this.updateSecurityMetrics();
    });
  }

  private setupThreatDetection(): void {
    // Monitor for security threats
    this.threatDetected$.pipe(
      filter(threat => threat !== null)
    ).subscribe(threat => {
      if (threat) {
        this.handleThreatDetection(threat);
      }
    });

    // Auto-block peers with too many threats
    interval(30000).subscribe(() => {
      this.evaluatePeerReputation();
    });
  }

  private startSecurityScanning(): void {
    // Periodic security scans
    interval(120000).subscribe(() => {
      this.performSecurityScan();
    });
  }

  // Public API for threat detection
  detectThreat(
    type: SecurityThreat['type'],
    source: string,
    description: string,
    severity: SecurityThreat['severity'] = 'medium'
  ): string {
    const threat: SecurityThreat = {
      id: this.generateThreatId(),
      type,
      severity,
      source,
      description,
      timestamp: Date.now(),
      blocked: false
    };

    // Add to threats list
    const threats = this._threats();
    this._threats.set([...threats, threat]);

    // Emit threat detection event
    this.threatDetected$.next(threat);

    // Update metrics
    this.incrementThreatCounter();

    return threat.id;
  }

  // Message validation
  validateMessage(message: any, sender: string): boolean {
    try {
      // Check rate limiting
      if (!this.checkRateLimit(sender)) {
        this.detectThreat('spam_message', sender, 'Rate limit exceeded', 'medium');
        return false;
      }

      // Check message signature if required
      if (this._securityPolicy().messageSignatureRequired && !message.signature) {
        this.detectThreat('invalid_signature', sender, 'Missing message signature', 'high');
        return false;
      }

      // Check for replay attacks
      if (this.isReplayAttack(message)) {
        this.detectThreat('replay_attack', sender, 'Potential replay attack detected', 'high');
        return false;
      }

      // Check message content for malicious patterns
      if (this.containsMaliciousContent(message.content)) {
        this.detectThreat('malicious_peer', sender, 'Malicious content detected', 'critical');
        return false;
      }

      return true;
    } catch (error) {
      console.error('Message validation error:', error);
      return false;
    }
  }

  // Peer validation
  validatePeer(peerId: string, connectionInfo: any): boolean {
    // Check if peer is blacklisted
    if (this.blacklistedPeers.has(peerId)) {
      return false;
    }

    // Check peer reputation
    const reputation = this.peerReputation.get(peerId) || 100;
    if (reputation < 30) {
      this.detectThreat('malicious_peer', peerId, 'Low reputation peer', 'medium');
      return false;
    }

    // Check connection limits
    const policy = this._securityPolicy();
    if (connectionInfo.connectionCount > policy.maxConnectionsPerPeer) {
      this.detectThreat('dos_attack', peerId, 'Too many connections', 'high');
      return false;
    }

    return true;
  }

  // Threat management
  blockThreat(threatId: string): void {
    const threats = this._threats();
    const threatIndex = threats.findIndex(t => t.id === threatId);
    
    if (threatIndex !== -1) {
      const updatedThreats = [...threats];
      updatedThreats[threatIndex] = { ...updatedThreats[threatIndex], blocked: true };
      this._threats.set(updatedThreats);

      // Block the source peer
      const threat = updatedThreats[threatIndex];
      this.blockPeer(threat.source, threat.type);

      // Update metrics
      this.incrementBlockedCounter();
    }
  }

  blockPeer(peerId: string, reason: string): void {
    this.blacklistedPeers.add(peerId);
    
    // Reduce peer reputation
    const currentReputation = this.peerReputation.get(peerId) || 100;
    this.peerReputation.set(peerId, Math.max(0, currentReputation - 20));

    console.log(`Peer ${peerId} blocked for: ${reason}`);

    // Auto-unblock after quarantine time
    const quarantineTime = this._securityPolicy().quarantineTime;
    setTimeout(() => {
      this.unblockPeer(peerId);
    }, quarantineTime);
  }

  unblockPeer(peerId: string): void {
    this.blacklistedPeers.delete(peerId);
    console.log(`Peer ${peerId} unblocked`);
  }

  // Security checks
  private checkRateLimit(sender: string): boolean {
    const now = Date.now();
    const policy = this._securityPolicy();
    const timeWindow = 60000; // 1 minute
    
    // Get or create rate limit tracking for sender
    let timestamps = this.messageRateLimit.get(sender) || [];
    
    // Remove old timestamps
    timestamps = timestamps.filter(ts => now - ts < timeWindow);
    
    // Check if rate limit exceeded
    if (timestamps.length >= policy.maxMessagesPerMinute) {
      return false;
    }
    
    // Add current timestamp
    timestamps.push(now);
    this.messageRateLimit.set(sender, timestamps);
    
    return true;
  }

  private isReplayAttack(message: any): boolean {
    // Check if message timestamp is too old or in the future
    const now = Date.now();
    const messageTime = message.timestamp || 0;
    const maxAge = 300000; // 5 minutes
    const maxFuture = 60000; // 1 minute
    
    return (
      messageTime < now - maxAge || 
      messageTime > now + maxFuture
    );
  }

  private containsMaliciousContent(content: string): boolean {
    if (!content) return false;
    
    // Simple malicious pattern detection
    const maliciousPatterns = [
      /<script/i,
      /javascript:/i,
      /data:text\/html/i,
      /vbscript:/i,
      /onload=/i,
      /onerror=/i
    ];
    
    return maliciousPatterns.some(pattern => pattern.test(content));
  }

  private evaluatePeerReputation(): void {
    const policy = this._securityPolicy();
    
    this.peerReputation.forEach((reputation, peerId) => {
      // Auto-block peers with very low reputation
      if (reputation < 10 && policy.blockSuspiciousPeers) {
        this.blockPeer(peerId, 'Very low reputation');
      }
      
      // Gradually restore reputation for good behavior
      if (reputation < 100) {
        this.peerReputation.set(peerId, Math.min(100, reputation + 1));
      }
    });
  }

  private performSecurityScan(): void {
    // Scan for suspicious patterns
    const suspiciousPeerCount = Array.from(this.peerReputation.values())
      .filter(rep => rep < 50).length;
    
    // Update security metrics
    const metrics = this._metrics();
    this._metrics.set({
      ...metrics,
      suspiciousPeers: suspiciousPeerCount,
      securityScore: this.calculateSecurityScore()
    });
  }

  private calculateSecurityScore(): number {
    const metrics = this._metrics();
    const recentThreats = this._threats().filter(
      t => Date.now() - t.timestamp < 3600000 // Last hour
    ).length;
    
    let score = 100;
    
    // Deduct points for threats
    score -= recentThreats * 5;
    score -= metrics.suspiciousPeers * 2;
    score -= (metrics.threatsDetected - metrics.threatsBlocked) * 3;
    
    return Math.max(0, Math.min(100, score));
  }

  private handleThreatDetection(threat: SecurityThreat): void {
    console.warn('Security threat detected:', threat);
    
    // Auto-block critical threats
    if (threat.severity === 'critical') {
      this.blockThreat(threat.id);
    }
    
    // Emit security alert
    this.securityAlert$.next(`${threat.type}: ${threat.description}`);
    
    // Reduce peer reputation
    const currentReputation = this.peerReputation.get(threat.source) || 100;
    const reputationPenalty = this.getReputationPenalty(threat.severity);
    this.peerReputation.set(threat.source, Math.max(0, currentReputation - reputationPenalty));
  }

  private getReputationPenalty(severity: SecurityThreat['severity']): number {
    switch (severity) {
      case 'critical': return 30;
      case 'high': return 20;
      case 'medium': return 10;
      case 'low': return 5;
      default: return 5;
    }
  }

  private cleanupOldThreats(): void {
    const oneHourAgo = Date.now() - 3600000;
    const threats = this._threats().filter(t => t.timestamp > oneHourAgo);
    this._threats.set(threats);
  }

  private updateSecurityMetrics(): void {
    const threats = this._threats();
    const metrics: SecurityMetrics = {
      threatsDetected: threats.length,
      threatsBlocked: threats.filter(t => t.blocked).length,
      suspiciousPeers: Array.from(this.peerReputation.values()).filter(rep => rep < 50).length,
      invalidMessages: threats.filter(t => t.type === 'invalid_signature').length,
      lastThreatTime: threats.length > 0 ? Math.max(...threats.map(t => t.timestamp)) : 0,
      securityScore: this.calculateSecurityScore()
    };
    
    this._metrics.set(metrics);
  }

  private incrementThreatCounter(): void {
    const metrics = this._metrics();
    this._metrics.set({
      ...metrics,
      threatsDetected: metrics.threatsDetected + 1
    });
  }

  private incrementBlockedCounter(): void {
    const metrics = this._metrics();
    this._metrics.set({
      ...metrics,
      threatsBlocked: metrics.threatsBlocked + 1
    });
  }

  private loadSecurityPolicies(): void {
    try {
      const saved = localStorage.getItem('security_policies');
      if (saved) {
        const policies = JSON.parse(saved);
        this._securityPolicy.set(policies);
      }
    } catch (error) {
      console.error('Failed to load security policies:', error);
    }
  }

  private generateThreatId(): string {
    return `threat_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Public API for components
  getSecurityReport(): Observable<SecurityMetrics> {
    return this._metrics.asObservable();
  }

  getThreatAlerts(): Observable<string> {
    return this.securityAlert$.pipe(
      filter(alert => alert !== null),
      map(alert => alert!)
    );
  }

  updateSecurityPolicy(policy: Partial<SecurityPolicy>): void {
    const currentPolicy = this._securityPolicy();
    const updatedPolicy = { ...currentPolicy, ...policy };
    this._securityPolicy.set(updatedPolicy);
    
    // Save to storage
    localStorage.setItem('security_policies', JSON.stringify(updatedPolicy));
  }

  isBlocked(peerId: string): boolean {
    return this.blacklistedPeers.has(peerId);
  }

  getPeerReputation(peerId: string): number {
    return this.peerReputation.get(peerId) || 100;
  }

  // Emergency security measures
  enableEmergencyMode(): void {
    this.updateSecurityPolicy({
      maxMessagesPerMinute: 30,
      maxConnectionsPerPeer: 3,
      messageSignatureRequired: true,
      blockSuspiciousPeers: true,
      autoBlockThreshold: 3
    });
    
    console.log('Emergency security mode enabled');
  }

  disableEmergencyMode(): void {
    this.updateSecurityPolicy({
      maxMessagesPerMinute: 60,
      maxConnectionsPerPeer: 5,
      messageSignatureRequired: true,
      blockSuspiciousPeers: true,
      autoBlockThreshold: 5
    });
    
    console.log('Emergency security mode disabled');
  }
}