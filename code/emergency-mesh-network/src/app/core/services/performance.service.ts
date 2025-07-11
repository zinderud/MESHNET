import { Injectable, signal, computed } from '@angular/core';
import { BehaviorSubject, Observable, interval } from 'rxjs';
import { map, debounceTime } from 'rxjs/operators';

export interface PerformanceMetrics {
  memoryUsage: number;
  cpuUsage: number;
  networkLatency: number;
  batteryLevel: number;
  connectionCount: number;
  messageQueueSize: number;
  lastUpdated: number;
}

export interface OptimizationSettings {
  enableLowPowerMode: boolean;
  maxConnections: number;
  messageRetention: number; // hours
  compressionLevel: number; // 0-9
  backgroundSyncInterval: number; // milliseconds
}

@Injectable({
  providedIn: 'root'
})
export class PerformanceService {
  // Signals for reactive performance monitoring
  private _metrics = signal<PerformanceMetrics>({
    memoryUsage: 0,
    cpuUsage: 0,
    networkLatency: 0,
    batteryLevel: 100,
    connectionCount: 0,
    messageQueueSize: 0,
    lastUpdated: Date.now()
  });

  private _optimizationSettings = signal<OptimizationSettings>({
    enableLowPowerMode: false,
    maxConnections: 10,
    messageRetention: 24,
    compressionLevel: 6,
    backgroundSyncInterval: 30000
  });

  // Computed performance indicators
  metrics = this._metrics.asReadonly();
  optimizationSettings = this._optimizationSettings.asReadonly();
  
  performanceScore = computed(() => {
    const m = this._metrics();
    const memoryScore = Math.max(0, 100 - m.memoryUsage);
    const latencyScore = Math.max(0, 100 - (m.networkLatency / 10));
    const batteryScore = m.batteryLevel;
    
    return Math.round((memoryScore + latencyScore + batteryScore) / 3);
  });

  isLowPerformance = computed(() => this.performanceScore() < 50);
  shouldOptimize = computed(() => {
    const m = this._metrics();
    return m.memoryUsage > 80 || m.networkLatency > 1000 || m.batteryLevel < 20;
  });

  // Performance monitoring subjects
  private performanceAlert$ = new BehaviorSubject<string | null>(null);

  constructor() {
    this.startPerformanceMonitoring();
    this.setupOptimizationTriggers();
  }

  private startPerformanceMonitoring(): void {
    // Monitor performance every 10 seconds
    interval(10000).subscribe(() => {
      this.updateMetrics();
    });

    // Monitor memory usage
    if ('memory' in performance) {
      interval(5000).subscribe(() => {
        this.updateMemoryMetrics();
      });
    }
  }

  private setupOptimizationTriggers(): void {
    // Auto-enable low power mode when battery is low
    interval(30000).subscribe(async () => {
      const batteryLevel = await this.getBatteryLevel();
      if (batteryLevel < 20 && !this._optimizationSettings().enableLowPowerMode) {
        this.enableLowPowerMode();
      }
    });

    // Monitor performance alerts
    this.performanceAlert$.pipe(
      debounceTime(5000)
    ).subscribe(alert => {
      if (alert) {
        this.handlePerformanceAlert(alert);
      }
    });
  }

  async updateMetrics(): Promise<void> {
    try {
      const metrics: PerformanceMetrics = {
        memoryUsage: await this.getMemoryUsage(),
        cpuUsage: await this.getCPUUsage(),
        networkLatency: await this.getNetworkLatency(),
        batteryLevel: await this.getBatteryLevel(),
        connectionCount: this.getConnectionCount(),
        messageQueueSize: this.getMessageQueueSize(),
        lastUpdated: Date.now()
      };

      this._metrics.set(metrics);
      this.checkPerformanceThresholds(metrics);
    } catch (error) {
      console.error('Failed to update performance metrics:', error);
    }
  }

  private async updateMemoryMetrics(): Promise<void> {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      const memoryUsage = (memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100;
      
      const currentMetrics = this._metrics();
      this._metrics.set({
        ...currentMetrics,
        memoryUsage: Math.round(memoryUsage),
        lastUpdated: Date.now()
      });
    }
  }

  private checkPerformanceThresholds(metrics: PerformanceMetrics): void {
    if (metrics.memoryUsage > 90) {
      this.performanceAlert$.next('Yüksek bellek kullanımı tespit edildi');
    }
    
    if (metrics.networkLatency > 2000) {
      this.performanceAlert$.next('Yüksek ağ gecikmesi tespit edildi');
    }
    
    if (metrics.batteryLevel < 15) {
      this.performanceAlert$.next('Düşük pil seviyesi');
    }
  }

  private handlePerformanceAlert(alert: string): void {
    console.warn('Performance Alert:', alert);
    
    // Auto-optimize based on alert type
    if (alert.includes('bellek')) {
      this.optimizeMemoryUsage();
    } else if (alert.includes('ağ')) {
      this.optimizeNetworkUsage();
    } else if (alert.includes('pil')) {
      this.enableLowPowerMode();
    }
  }

  // Optimization methods
  enableLowPowerMode(): void {
    const settings = this._optimizationSettings();
    this._optimizationSettings.set({
      ...settings,
      enableLowPowerMode: true,
      maxConnections: Math.min(settings.maxConnections, 5),
      backgroundSyncInterval: Math.max(settings.backgroundSyncInterval, 60000),
      compressionLevel: 9
    });
    
    console.log('Low power mode enabled');
  }

  disableLowPowerMode(): void {
    const settings = this._optimizationSettings();
    this._optimizationSettings.set({
      ...settings,
      enableLowPowerMode: false,
      maxConnections: 10,
      backgroundSyncInterval: 30000,
      compressionLevel: 6
    });
    
    console.log('Low power mode disabled');
  }

  optimizeMemoryUsage(): void {
    // Trigger garbage collection if available
    if ('gc' in window) {
      (window as any).gc();
    }
    
    // Clear old cached data
    this.clearOldCache();
    
    // Reduce message retention
    const settings = this._optimizationSettings();
    this._optimizationSettings.set({
      ...settings,
      messageRetention: Math.max(settings.messageRetention / 2, 1)
    });
  }

  optimizeNetworkUsage(): void {
    const settings = this._optimizationSettings();
    this._optimizationSettings.set({
      ...settings,
      maxConnections: Math.max(settings.maxConnections - 2, 3),
      compressionLevel: 9,
      backgroundSyncInterval: settings.backgroundSyncInterval * 1.5
    });
  }

  // Performance measurement methods
  private async getMemoryUsage(): Promise<number> {
    if ('memory' in performance) {
      const memory = (performance as any).memory;
      return Math.round((memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100);
    }
    return 0;
  }

  private async getCPUUsage(): Promise<number> {
    // Simplified CPU usage estimation
    const start = performance.now();
    let iterations = 0;
    const duration = 100; // 100ms test
    
    while (performance.now() - start < duration) {
      iterations++;
    }
    
    // Normalize to percentage (higher iterations = lower CPU usage)
    const baselineIterations = 100000; // Baseline for good performance
    return Math.max(0, Math.min(100, 100 - (iterations / baselineIterations * 100)));
  }

  private async getNetworkLatency(): Promise<number> {
    try {
      const start = performance.now();
      await fetch('/ping', { method: 'HEAD' });
      return performance.now() - start;
    } catch {
      return 0;
    }
  }

  private async getBatteryLevel(): Promise<number> {
    try {
      // @ts-ignore - Battery API might not be available
      const battery = await navigator.getBattery?.();
      return battery ? Math.round(battery.level * 100) : 100;
    } catch {
      return 100;
    }
  }

  private getConnectionCount(): number {
    // This would be injected from WebRTC service
    return 0; // Placeholder
  }

  private getMessageQueueSize(): number {
    // This would be injected from Messaging service
    return 0; // Placeholder
  }

  private clearOldCache(): void {
    // Clear old localStorage entries
    const keys = Object.keys(localStorage);
    const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
    
    keys.forEach(key => {
      try {
        const item = localStorage.getItem(key);
        if (item) {
          const data = JSON.parse(item);
          if (data.timestamp && data.timestamp < oneWeekAgo) {
            localStorage.removeItem(key);
          }
        }
      } catch {
        // Invalid JSON, remove it
        localStorage.removeItem(key);
      }
    });
  }

  // Bundle optimization methods
  async optimizeBundleSize(): Promise<void> {
    // Dynamic imports for non-critical features
    const { default: heavyModule } = await import('./heavy-module');
    // Use heavy module only when needed
  }

  // Memory leak prevention
  preventMemoryLeaks(): void {
    // Remove event listeners
    window.removeEventListener('beforeunload', this.cleanup);
    
    // Clear intervals and timeouts
    // This would be handled in component destruction
  }

  private cleanup = (): void => {
    // Cleanup resources before page unload
    this.clearOldCache();
  }

  // Public API for components
  getPerformanceReport(): Observable<PerformanceMetrics> {
    return this._metrics.asObservable();
  }

  getOptimizationRecommendations(): string[] {
    const metrics = this._metrics();
    const recommendations: string[] = [];

    if (metrics.memoryUsage > 80) {
      recommendations.push('Bellek kullanımını azaltmak için eski mesajları temizleyin');
    }

    if (metrics.networkLatency > 1000) {
      recommendations.push('Ağ performansını artırmak için bağlantı sayısını azaltın');
    }

    if (metrics.batteryLevel < 30) {
      recommendations.push('Pil ömrünü uzatmak için düşük güç modunu etkinleştirin');
    }

    if (metrics.connectionCount > 8) {
      recommendations.push('Performansı artırmak için aktif bağlantı sayısını sınırlayın');
    }

    return recommendations;
  }

  // Performance testing methods
  async runPerformanceTest(): Promise<{
    score: number;
    details: Record<string, number>;
    recommendations: string[];
  }> {
    const startTime = performance.now();
    
    // Test various performance aspects
    const memoryTest = await this.testMemoryPerformance();
    const networkTest = await this.testNetworkPerformance();
    const renderTest = await this.testRenderPerformance();
    
    const totalTime = performance.now() - startTime;
    
    const details = {
      memory: memoryTest,
      network: networkTest,
      render: renderTest,
      totalTime
    };
    
    const score = this.calculatePerformanceScore(details);
    const recommendations = this.getOptimizationRecommendations();
    
    return { score, details, recommendations };
  }

  private async testMemoryPerformance(): Promise<number> {
    const start = performance.now();
    
    // Create and destroy objects to test memory management
    const testArray = new Array(10000).fill(0).map((_, i) => ({ id: i, data: Math.random() }));
    testArray.sort((a, b) => a.data - b.data);
    
    return performance.now() - start;
  }

  private async testNetworkPerformance(): Promise<number> {
    const start = performance.now();
    
    try {
      // Test network latency
      await fetch('/api/ping', { method: 'HEAD' });
      return performance.now() - start;
    } catch {
      return 5000; // High latency if failed
    }
  }

  private async testRenderPerformance(): Promise<number> {
    const start = performance.now();
    
    // Test DOM manipulation performance
    const testElement = document.createElement('div');
    for (let i = 0; i < 1000; i++) {
      const child = document.createElement('span');
      child.textContent = `Item ${i}`;
      testElement.appendChild(child);
    }
    
    return performance.now() - start;
  }

  private calculatePerformanceScore(details: Record<string, number>): number {
    // Calculate weighted performance score
    const memoryScore = Math.max(0, 100 - (details.memory / 10));
    const networkScore = Math.max(0, 100 - (details.network / 50));
    const renderScore = Math.max(0, 100 - (details.render / 20));
    
    return Math.round((memoryScore + networkScore + renderScore) / 3);
  }
}