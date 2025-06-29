import { Injectable, inject } from '@angular/core';
import { BehaviorSubject, Observable, Subject } from 'rxjs';
import { WebrtcService } from '../../core/services/webrtc.service';
import { MeshNetworkImplementationService } from '../../core/services/mesh-network-implementation.service';
import { AnalyticsService } from '../../core/services/analytics.service';
import { NetworkTest, TestResult, TestMetrics, TestEnvironment } from './network-test.model';

@Injectable({
  providedIn: 'root'
})
export class NetworkTestService {
  private webrtcService = inject(WebrtcService);
  private meshService = inject(MeshNetworkImplementationService);
  private analyticsService = inject(AnalyticsService);

  // Test state
  private _availableTests = new BehaviorSubject<NetworkTest[]>([]);
  private _testResults = new BehaviorSubject<TestResult[]>([]);
  private _testMetrics = new BehaviorSubject<TestMetrics>({
    averageLatency: 0,
    throughput: 0,
    reliability: 0,
    coverage: 0,
    batteryImpact: 0,
    emergencyResponseTime: 0
  });
  private _activeTestId = new BehaviorSubject<string | null>(null);

  // Test events
  private testStarted$ = new Subject<NetworkTest>();
  private testCompleted$ = new Subject<TestResult>();
  private testFailed$ = new Subject<{ testId: string; error: string }>();

  constructor() {
    this.initializeTests();
  }

  // Public observables
  get availableTests$(): Observable<NetworkTest[]> {
    return this._availableTests.asObservable();
  }

  get testResults$(): Observable<TestResult[]> {
    return this._testResults.asObservable();
  }

  get testMetrics$(): Observable<TestMetrics> {
    return this._testMetrics.asObservable();
  }

  get activeTestId$(): Observable<string | null> {
    return this._activeTestId.asObservable();
  }

  // Event observables
  get onTestStarted$(): Observable<NetworkTest> {
    return this.testStarted$.asObservable();
  }

  get onTestCompleted$(): Observable<TestResult> {
    return this.testCompleted$.asObservable();
  }

  get onTestFailed$(): Observable<{ testId: string; error: string }> {
    return this.testFailed$.asObservable();
  }

  // Public methods
  async runTest(testId: string): Promise<TestResult | null> {
    const tests = this._availableTests.value;
    const test = tests.find(t => t.id === testId);
    
    if (!test || this._activeTestId.value !== null) {
      return null;
    }

    try {
      // Update test status
      this.updateTestStatus(testId, 'running');
      this._activeTestId.next(testId);
      
      // Emit test started event
      this.testStarted$.next(test);
      
      // Get current environment
      const environment = this.getCurrentEnvironment();
      
      // Run the test
      const result = await this.executeTest(test, environment);
      
      // Update test status and result
      this.updateTestResult(testId, result);
      
      // Add to test results
      const testResults = [...this._testResults.value, result];
      this._testResults.next(testResults);
      
      // Update metrics
      this.updateTestMetrics();
      
      // Emit test completed event
      this.testCompleted$.next(result);
      
      // Track analytics
      this.analyticsService.trackEvent('test', 'completed', test.type, undefined, result.value);
      
      return result;
    } catch (error) {
      // Update test status to failed
      this.updateTestStatus(testId, 'failed');
      
      // Emit test failed event
      this.testFailed$.next({ testId, error: error.message });
      
      // Track analytics
      this.analyticsService.trackError('test', 'Test failed', { testId, error: error.message });
      
      return null;
    } finally {
      this._activeTestId.next(null);
    }
  }

  async runAllTests(): Promise<TestResult[]> {
    const tests = this._availableTests.value;
    const results: TestResult[] = [];
    
    for (const test of tests) {
      const result = await this.runTest(test.id);
      if (result) {
        results.push(result);
      }
      
      // Wait a bit between tests
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    return results;
  }

  getTestById(testId: string): NetworkTest | undefined {
    return this._availableTests.value.find(t => t.id === testId);
  }

  getTestResults(testId: string): TestResult[] {
    return this._testResults.value.filter(r => r.testId === testId);
  }

  getLatestTestResult(testId: string): TestResult | undefined {
    const results = this.getTestResults(testId);
    if (results.length === 0) return undefined;
    
    return results.sort((a, b) => b.startTime - a.startTime)[0];
  }

  clearTestResults(): void {
    this._testResults.next([]);
    this.updateTestMetrics();
  }

  isTestRunning(testId: string): boolean {
    return this._activeTestId.value === testId;
  }

  isAnyTestRunning(): boolean {
    return this._activeTestId.value !== null;
  }

  // Private methods
  private initializeTests(): void {
    const tests: NetworkTest[] = [
      {
        id: 'latency_test',
        name: 'Network Latency',
        description: 'Measures the round-trip time for messages between nodes',
        type: 'latency',
        status: 'idle'
      },
      {
        id: 'throughput_test',
        name: 'Data Throughput',
        description: 'Measures the maximum data transfer rate',
        type: 'throughput',
        status: 'idle'
      },
      {
        id: 'reliability_test',
        name: 'Connection Reliability',
        description: 'Measures the percentage of successfully delivered messages',
        type: 'reliability',
        status: 'idle'
      },
      {
        id: 'coverage_test',
        name: 'Network Coverage',
        description: 'Estimates the maximum effective range of the network',
        type: 'coverage',
        status: 'idle'
      },
      {
        id: 'battery_test',
        name: 'Battery Impact',
        description: 'Measures battery consumption during network operations',
        type: 'battery',
        status: 'idle'
      },
      {
        id: 'emergency_test',
        name: 'Emergency Response',
        description: 'Tests the network performance during emergency situations',
        type: 'emergency',
        status: 'idle'
      }
    ];
    
    this._availableTests.next(tests);
  }

  private updateTestStatus(testId: string, status: NetworkTest['status']): void {
    const tests = this._availableTests.value;
    const updatedTests = tests.map(test => 
      test.id === testId ? { ...test, status } : test
    );
    
    this._availableTests.next(updatedTests);
  }

  private updateTestResult(testId: string, result: TestResult): void {
    const tests = this._availableTests.value;
    const updatedTests = tests.map(test => {
      if (test.id === testId) {
        return {
          ...test,
          status: result.status === 'completed' ? 'completed' : 'failed',
          result: result.value !== undefined ? {
            value: result.value,
            unit: result.unit || '',
            details: result.details
          } : undefined,
          timestamp: result.endTime
        };
      }
      return test;
    });
    
    this._availableTests.next(updatedTests);
  }

  private updateTestMetrics(): void {
    const results = this._testResults.value;
    
    if (results.length === 0) {
      this._testMetrics.next({
        averageLatency: 0,
        throughput: 0,
        reliability: 0,
        coverage: 0,
        batteryImpact: 0,
        emergencyResponseTime: 0
      });
      return;
    }
    
    // Calculate metrics from test results
    const latencyResults = results.filter(r => r.testId === 'latency_test' && r.status === 'completed');
    const throughputResults = results.filter(r => r.testId === 'throughput_test' && r.status === 'completed');
    const reliabilityResults = results.filter(r => r.testId === 'reliability_test' && r.status === 'completed');
    const coverageResults = results.filter(r => r.testId === 'coverage_test' && r.status === 'completed');
    const batteryResults = results.filter(r => r.testId === 'battery_test' && r.status === 'completed');
    const emergencyResults = results.filter(r => r.testId === 'emergency_test' && r.status === 'completed');
    
    const metrics: TestMetrics = {
      averageLatency: latencyResults.length > 0 
        ? latencyResults.reduce((sum, r) => sum + (r.value || 0), 0) / latencyResults.length 
        : 0,
      throughput: throughputResults.length > 0 
        ? throughputResults.reduce((sum, r) => sum + (r.value || 0), 0) / throughputResults.length 
        : 0,
      reliability: reliabilityResults.length > 0 
        ? reliabilityResults.reduce((sum, r) => sum + (r.value || 0), 0) / reliabilityResults.length 
        : 0,
      coverage: coverageResults.length > 0 
        ? coverageResults.reduce((sum, r) => sum + (r.value || 0), 0) / coverageResults.length 
        : 0,
      batteryImpact: batteryResults.length > 0 
        ? batteryResults.reduce((sum, r) => sum + (r.value || 0), 0) / batteryResults.length 
        : 0,
      emergencyResponseTime: emergencyResults.length > 0 
        ? emergencyResults.reduce((sum, r) => sum + (r.value || 0), 0) / emergencyResults.length 
        : 0
    };
    
    this._testMetrics.next(metrics);
  }

  private getCurrentEnvironment(): TestEnvironment {
    return {
      webrtcEnabled: this.webrtcService.isConnected(),
      meshEnabled: this.meshService.activeMeshNetworks().size > 0,
      emergencyMode: this.meshService.isEmergencyMode(),
      peerCount: this.webrtcService.connectedPeers().length,
      nodeCount: this.meshService.totalMeshNodes(),
      messageRate: 10, // Default value
      batteryLevel: 80 // Default value
    };
  }

  private async executeTest(test: NetworkTest, environment: TestEnvironment): Promise<TestResult> {
    const startTime = Date.now();
    
    try {
      // Execute test based on type
      let result: { value: number; unit: string; details?: string };
      
      switch (test.type) {
        case 'latency':
          result = await this.runLatencyTest(environment);
          break;
        case 'throughput':
          result = await this.runThroughputTest(environment);
          break;
        case 'reliability':
          result = await this.runReliabilityTest(environment);
          break;
        case 'coverage':
          result = await this.runCoverageTest(environment);
          break;
        case 'battery':
          result = await this.runBatteryTest(environment);
          break;
        case 'emergency':
          result = await this.runEmergencyTest(environment);
          break;
        default:
          throw new Error(`Unknown test type: ${test.type}`);
      }
      
      return {
        testId: test.id,
        environment,
        startTime,
        endTime: Date.now(),
        status: 'completed',
        value: result.value,
        unit: result.unit,
        details: result.details
      };
    } catch (error) {
      return {
        testId: test.id,
        environment,
        startTime,
        endTime: Date.now(),
        status: 'failed',
        error: error.message
      };
    }
  }

  // Test implementations
  private async runLatencyTest(environment: TestEnvironment): Promise<{ value: number; unit: string; details?: string }> {
    // Simulate latency test
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Generate realistic latency based on environment
    let baseLatency = 50; // Base latency in ms
    
    // Adjust based on environment
    if (environment.webrtcEnabled) {
      baseLatency += 20; // WebRTC adds some overhead
    }
    
    if (environment.meshEnabled) {
      baseLatency += 30 * Math.log(Math.max(1, environment.nodeCount)); // More nodes = higher latency
    }
    
    if (environment.emergencyMode) {
      baseLatency *= 1.2; // Emergency mode increases latency due to prioritization overhead
    }
    
    // Add some randomness
    const latency = Math.round(baseLatency * (0.8 + Math.random() * 0.4));
    
    return {
      value: latency,
      unit: 'ms',
      details: `Round-trip time between nodes with ${environment.peerCount} active peers`
    };
  }

  private async runThroughputTest(environment: TestEnvironment): Promise<{ value: number; unit: string; details?: string }> {
    // Simulate throughput test
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Generate realistic throughput based on environment
    let baseThroughput = 500; // Base throughput in KB/s
    
    // Adjust based on environment
    if (environment.webrtcEnabled) {
      baseThroughput *= 1.5; // WebRTC has better throughput
    }
    
    if (environment.meshEnabled) {
      baseThroughput *= 0.8; // Mesh routing reduces throughput
      baseThroughput /= Math.sqrt(Math.max(1, environment.nodeCount)); // More nodes = lower throughput
    }
    
    if (environment.emergencyMode) {
      baseThroughput *= 0.7; // Emergency mode prioritizes reliability over speed
    }
    
    // Add some randomness
    const throughput = Math.round(baseThroughput * (0.9 + Math.random() * 0.2));
    
    return {
      value: throughput,
      unit: 'KB/s',
      details: `Maximum data transfer rate with ${environment.peerCount} active connections`
    };
  }

  private async runReliabilityTest(environment: TestEnvironment): Promise<{ value: number; unit: string; details?: string }> {
    // Simulate reliability test
    await new Promise(resolve => setTimeout(resolve, 4000));
    
    // Generate realistic reliability based on environment
    let baseReliability = 95; // Base reliability percentage
    
    // Adjust based on environment
    if (environment.webrtcEnabled) {
      baseReliability += 2; // WebRTC is more reliable for direct connections
    }
    
    if (environment.meshEnabled) {
      baseReliability -= 5; // Mesh routing introduces more points of failure
      baseReliability += 10 * (1 - Math.exp(-environment.nodeCount / 10)); // More nodes = better reliability, with diminishing returns
    }
    
    if (environment.emergencyMode) {
      baseReliability += 3; // Emergency mode prioritizes reliability
    }
    
    // Add some randomness
    const reliability = Math.min(100, Math.round(baseReliability * (0.95 + Math.random() * 0.1)));
    
    return {
      value: reliability,
      unit: '%',
      details: `Message delivery success rate over ${environment.meshEnabled ? 'mesh' : 'direct'} connections`
    };
  }

  private async runCoverageTest(environment: TestEnvironment): Promise<{ value: number; unit: string; details?: string }> {
    // Simulate coverage test
    await new Promise(resolve => setTimeout(resolve, 3500));
    
    // Generate realistic coverage based on environment
    let baseCoverage = 100; // Base coverage in meters
    
    // Adjust based on environment
    if (environment.webrtcEnabled) {
      baseCoverage += 50; // WebRTC extends range
    }
    
    if (environment.meshEnabled) {
      baseCoverage *= 1 + (environment.nodeCount / 10); // More nodes = better coverage
    }
    
    if (environment.emergencyMode) {
      baseCoverage *= 1.2; // Emergency mode increases power to extend range
    }
    
    // Add some randomness
    const coverage = Math.round(baseCoverage * (0.9 + Math.random() * 0.2));
    
    return {
      value: coverage,
      unit: 'm',
      details: `Estimated maximum effective range with ${environment.nodeCount} nodes`
    };
  }

  private async runBatteryTest(environment: TestEnvironment): Promise<{ value: number; unit: string; details?: string }> {
    // Simulate battery test
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Generate realistic battery impact based on environment
    let baseDrain = 2; // Base battery drain in % per hour
    
    // Adjust based on environment
    if (environment.webrtcEnabled) {
      baseDrain += 1; // WebRTC uses more battery
    }
    
    if (environment.meshEnabled) {
      baseDrain += 0.5 * Math.sqrt(environment.nodeCount); // More nodes = more battery drain
    }
    
    if (environment.emergencyMode) {
      baseDrain *= 1.5; // Emergency mode uses more battery
    }
    
    // Add some randomness
    const batteryDrain = Math.round(baseDrain * (0.9 + Math.random() * 0.2) * 10) / 10;
    
    return {
      value: batteryDrain,
      unit: '%/hr',
      details: `Battery consumption rate during ${environment.emergencyMode ? 'emergency' : 'normal'} operation`
    };
  }

  private async runEmergencyTest(environment: TestEnvironment): Promise<{ value: number; unit: string; details?: string }> {
    // Simulate emergency test
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    // Generate realistic emergency response time based on environment
    let baseResponseTime = 200; // Base response time in ms
    
    // Adjust based on environment
    if (environment.webrtcEnabled) {
      baseResponseTime -= 50; // WebRTC is faster
    }
    
    if (environment.meshEnabled) {
      baseResponseTime += 20 * Math.log(Math.max(1, environment.nodeCount)); // More nodes = higher latency
    }
    
    if (environment.emergencyMode) {
      baseResponseTime *= 0.7; // Emergency mode prioritizes emergency messages
    }
    
    // Add some randomness
    const responseTime = Math.round(baseResponseTime * (0.9 + Math.random() * 0.2));
    
    return {
      value: responseTime,
      unit: 'ms',
      details: `Average time to deliver emergency messages across the network`
    };
  }
}