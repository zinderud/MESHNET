export interface NetworkTest {
  id: string;
  name: string;
  description: string;
  type: 'latency' | 'throughput' | 'reliability' | 'coverage' | 'battery' | 'emergency';
  status: 'idle' | 'running' | 'completed' | 'failed';
  result?: {
    value: number;
    unit: string;
    details?: string;
  };
  timestamp?: number;
  duration?: number;
}

export interface TestEnvironment {
  webrtcEnabled: boolean;
  meshEnabled: boolean;
  emergencyMode: boolean;
  peerCount: number;
  nodeCount: number;
  messageRate: number;
  batteryLevel: number;
}

export interface TestResult {
  testId: string;
  environment: TestEnvironment;
  startTime: number;
  endTime?: number;
  status: 'completed' | 'failed';
  value?: number;
  unit?: string;
  details?: string;
  error?: string;
}

export interface TestMetrics {
  averageLatency: number;
  throughput: number;
  reliability: number;
  coverage: number;
  batteryImpact: number;
  emergencyResponseTime: number;
}