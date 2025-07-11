# 2a: Otomatik Failover Algoritması

Bu belge, Cascading Network mimarisinin kalbi olan otomatik failover algoritmasının detaylı analizi ve implementasyonunu içermektedir.

---

## 🤖 Failover Algorithm Overview

### Algoritma Tanımı
```
Otomatik Failover: Aktif katmanın performans degradasyonu veya 
başarısızlığı durumunda, önceden belirlenmiş kriterler temelinde 
bir sonraki katmana geçişi sağlayan akıllı karar verme sistemi.

Temel Prensipler:
├── Sürekli Monitoring: Real-time performance tracking
├── Predictive Analysis: Failure prediction before complete loss
├── Graceful Degradation: Smooth transition between layers
└── Automatic Recovery: Return to optimal layer when possible
```

### Failover Decision Matrix
```
┌─────────────────┬──────────────┬──────────────┬─────────────┐
│   Performance   │   Action     │   Timeout    │ Next Layer  │
│   Indicator     │   Required   │   Duration   │             │
├─────────────────┼──────────────┼──────────────┼─────────────┤
│ Latency >500ms  │ Prepare L2   │ 10 seconds   │ Local Mesh  │
│ PacketLoss >5%  │ Prepare L2   │ 15 seconds   │ Local Mesh  │
│ Complete Loss   │ Immediate    │ 0 seconds    │ Next Layer  │
│ SNR <10dB       │ Optimize     │ 30 seconds   │ Same Layer  │
│ Battery <20%    │ Power Save   │ 5 seconds    │ Low Power   │
└─────────────────┴──────────────┴──────────────┴─────────────┘
```

---

## 📊 Performance Monitoring System

### Real-time Metrics Collection
```javascript
class PerformanceMonitoringSystem {
    constructor() {
        this.monitoringInterval = 1000; // 1 second
        this.metricHistory = new CircularBuffer(300); // 5 minutes history
        this.thresholds = new PerformanceThresholds();
        this.predictiveEngine = new FailurePredictionEngine();
    }
    
    async startContinuousMonitoring() {
        setInterval(async () => {
            const metrics = await this.collectMetrics();
            this.metricHistory.push(metrics);
            
            const analysis = await this.analyzeMetrics(metrics);
            
            if (analysis.failoverRequired) {
                await this.triggerFailover(analysis);
            } else if (analysis.optimizationNeeded) {
                await this.optimizeCurrentLayer(analysis);
            }
            
            this.updateDashboard(metrics, analysis);
        }, this.monitoringInterval);
    }
    
    async collectMetrics() {
        const timestamp = Date.now();
        
        // Network performance metrics
        const networkMetrics = await this.collectNetworkMetrics();
        
        // System resource metrics  
        const systemMetrics = await this.collectSystemMetrics();
        
        // Quality of experience metrics
        const qoeMetrics = await this.collectQoEMetrics();
        
        // Environmental metrics
        const environmentMetrics = await this.collectEnvironmentMetrics();
        
        return {
            timestamp,
            network: networkMetrics,
            system: systemMetrics,
            qoe: qoeMetrics,
            environment: environmentMetrics,
            composite: this.calculateCompositeScore({
                networkMetrics, systemMetrics, qoeMetrics, environmentMetrics
            })
        };
    }
    
    async collectNetworkMetrics() {
        const activeInterface = await this.getActiveInterface();
        
        return {
            latency: await this.measureLatency(activeInterface),
            packetLoss: await this.measurePacketLoss(activeInterface),
            throughput: await this.measureThroughput(activeInterface),
            jitter: await this.measureJitter(activeInterface),
            signalStrength: await this.measureSignalStrength(activeInterface),
            signalToNoiseRatio: await this.measureSNR(activeInterface),
            connectionStability: await this.assessConnectionStability(activeInterface),
            errorRate: await this.calculateErrorRate(activeInterface)
        };
    }
    
    async collectSystemMetrics() {
        return {
            cpuUsage: await this.getCPUUsage(),
            memoryUsage: await this.getMemoryUsage(),
            batteryLevel: await this.getBatteryLevel(),
            batteryDrainRate: await this.getBatteryDrainRate(),
            thermalState: await this.getThermalState(),
            diskSpace: await this.getDiskSpace(),
            processCount: await this.getActiveProcessCount()
        };
    }
    
    async collectQoEMetrics() {
        return {
            messageDeliveryRate: await this.calculateMessageDeliveryRate(),
            userSatisfactionScore: await this.calculateUserSatisfaction(),
            applicationResponseTime: await this.measureAppResponseTime(),
            serviceAvailability: await this.calculateServiceAvailability(),
            dataIntegrity: await this.verifyDataIntegrity()
        };
    }
}
```

### Predictive Failure Analysis
```javascript
class FailurePredictionEngine {
    constructor() {
        this.mlModel = new NetworkFailurePredictionModel();
        this.timeSeriesAnalyzer = new TimeSeriesAnalyzer();
        this.anomalyDetector = new AnomalyDetector();
    }
    
    async predictFailure(metricsHistory) {
        // Time series analysis for trend detection
        const trends = await this.timeSeriesAnalyzer.analyzeTrends(metricsHistory);
        
        // Anomaly detection for unusual patterns
        const anomalies = await this.anomalyDetector.detectAnomalies(metricsHistory);
        
        // ML-based failure prediction
        const mlPrediction = await this.mlModel.predict({
            trends: trends,
            anomalies: anomalies,
            currentMetrics: metricsHistory.last(),
            historicalContext: metricsHistory.last(60) // Last 60 data points
        });
        
        return {
            failureProbability: mlPrediction.probability,
            timeToFailure: mlPrediction.estimatedTime,
            failureType: mlPrediction.predictedFailureType,
            confidence: mlPrediction.confidence,
            contributingFactors: mlPrediction.factors,
            recommendedActions: this.generateRecommendations(mlPrediction)
        };
    }
    
    generateRecommendations(prediction) {
        const recommendations = [];
        
        if (prediction.probability > 0.7) {
            recommendations.push({
                action: 'immediate_backup_preparation',
                priority: 'high',
                description: 'Prepare backup layer immediately'
            });
        }
        
        if (prediction.probability > 0.5) {
            recommendations.push({
                action: 'performance_optimization',
                priority: 'medium',
                description: 'Optimize current layer performance'
            });
        }
        
        if (prediction.timeToFailure < 60000) { // Less than 1 minute
            recommendations.push({
                action: 'preemptive_failover',
                priority: 'critical',
                description: 'Consider preemptive failover to prevent service disruption'
            });
        }
        
        return recommendations;
    }
}
```

---

## ⚡ Failover Decision Engine

### Multi-Criteria Decision Making
```javascript
class FailoverDecisionEngine {
    constructor() {
        this.decisionMatrix = new FailoverDecisionMatrix();
        this.weightedCriteria = new WeightedFailoverCriteria();
        this.stateManager = new LayerStateManager();
    }
    
    async evaluateFailoverNeed(currentMetrics, prediction) {
        // Multi-criteria evaluation
        const criteria = {
            performance: this.evaluatePerformance(currentMetrics.network),
            reliability: this.evaluateReliability(currentMetrics.qoe),
            resources: this.evaluateResources(currentMetrics.system),
            environment: this.evaluateEnvironment(currentMetrics.environment),
            prediction: this.evaluatePrediction(prediction)
        };
        
        // Calculate weighted decision score
        const decisionScore = this.calculateDecisionScore(criteria);
        
        // Determine failover action
        const failoverDecision = await this.makeFailoverDecision(decisionScore, criteria);
        
        return {
            criteria: criteria,
            decisionScore: decisionScore,
            failoverDecision: failoverDecision,
            reasoning: this.generateReasoning(criteria, decisionScore),
            confidence: this.calculateConfidence(criteria)
        };
    }
    
    evaluatePerformance(networkMetrics) {
        const performanceScore = {
            latency: this.scoreLatency(networkMetrics.latency),
            packetLoss: this.scorePacketLoss(networkMetrics.packetLoss),
            throughput: this.scoreThroughput(networkMetrics.throughput),
            signalQuality: this.scoreSignalQuality(networkMetrics.signalStrength, networkMetrics.signalToNoiseRatio),
            stability: this.scoreStability(networkMetrics.connectionStability)
        };
        
        return {
            scores: performanceScore,
            overall: this.calculateOverallPerformance(performanceScore),
            failoverThreshold: 0.3, // Failover if score < 0.3
            degraded: this.calculateOverallPerformance(performanceScore) < 0.5
        };
    }
    
    scoreLatency(latency) {
        // Latency scoring function (lower is better)
        if (latency < 50) return 1.0;      // Excellent
        if (latency < 100) return 0.8;     // Good
        if (latency < 200) return 0.6;     // Fair
        if (latency < 500) return 0.4;     // Poor
        if (latency < 1000) return 0.2;    // Bad
        return 0.0;                        // Unacceptable
    }
    
    scorePacketLoss(packetLoss) {
        // Packet loss scoring function (lower is better)
        if (packetLoss < 0.1) return 1.0;  // Excellent
        if (packetLoss < 1) return 0.8;    // Good
        if (packetLoss < 3) return 0.6;    // Fair
        if (packetLoss < 5) return 0.4;    // Poor
        if (packetLoss < 10) return 0.2;   // Bad
        return 0.0;                        // Unacceptable
    }
    
    async makeFailoverDecision(decisionScore, criteria) {
        const currentLayer = await this.stateManager.getCurrentLayer();
        const availableLayers = await this.stateManager.getAvailableLayers();
        
        // Decision logic based on composite score
        if (decisionScore.composite < 0.2) {
            return {
                action: 'immediate_failover',
                targetLayer: this.selectNextBestLayer(currentLayer, availableLayers),
                urgency: 'critical',
                reason: 'performance_critical'
            };
        } else if (decisionScore.composite < 0.4) {
            return {
                action: 'prepare_failover',
                targetLayer: this.selectNextBestLayer(currentLayer, availableLayers),
                urgency: 'high',
                reason: 'performance_degraded'
            };
        } else if (decisionScore.composite < 0.6) {
            return {
                action: 'optimize_current',
                targetLayer: currentLayer,
                urgency: 'medium',
                reason: 'performance_suboptimal'
            };
        } else {
            return {
                action: 'monitor_continue',
                targetLayer: currentLayer,
                urgency: 'low',
                reason: 'performance_acceptable'
            };
        }
    }
}
```

### Layer Selection Algorithm
```javascript
class LayerSelectionAlgorithm {
    constructor() {
        this.layerCapabilities = new LayerCapabilityMatrix();
        this.selectionCriteria = new LayerSelectionCriteria();
    }
    
    selectNextBestLayer(currentLayer, availableLayers, context) {
        // Score each available layer based on current context
        const layerScores = availableLayers.map(layer => ({
            layer: layer,
            score: this.calculateLayerScore(layer, context),
            suitability: this.assessLayerSuitability(layer, context)
        }));
        
        // Filter out unsuitable layers
        const suitableLayers = layerScores.filter(ls => ls.suitability.suitable);
        
        if (suitableLayers.length === 0) {
            throw new Error('No suitable layers available for failover');
        }
        
        // Select highest scoring layer
        const selectedLayer = suitableLayers
            .sort((a, b) => b.score - a.score)[0];
        
        return {
            selectedLayer: selectedLayer.layer,
            score: selectedLayer.score,
            suitability: selectedLayer.suitability,
            alternativeLayers: suitableLayers.slice(1, 3), // Top 2 alternatives
            selectionReason: this.generateSelectionReason(selectedLayer, context)
        };
    }
    
    calculateLayerScore(layer, context) {
        const weights = this.getContextualWeights(context);
        
        const scores = {
            availability: this.scoreAvailability(layer),
            performance: this.scoreExpectedPerformance(layer, context),
            reliability: this.scoreReliability(layer),
            cost: this.scoreCost(layer),
            setupTime: this.scoreSetupTime(layer),
            coverage: this.scoreCoverage(layer, context)
        };
        
        return Object.keys(weights).reduce((total, criterion) => 
            total + (weights[criterion] * scores[criterion]), 0
        );
    }
    
    getContextualWeights(context) {
        // Adjust weights based on emergency context
        if (context.emergencyLevel === 'critical') {
            return {
                availability: 0.3,
                reliability: 0.3,
                setupTime: 0.2,
                performance: 0.15,
                coverage: 0.05,
                cost: 0.0
            };
        } else if (context.batteryLevel < 20) {
            return {
                availability: 0.25,
                reliability: 0.2,
                cost: 0.2, // Power efficiency becomes important
                setupTime: 0.15,
                performance: 0.15,
                coverage: 0.05
            };
        } else {
            return {
                performance: 0.3,
                reliability: 0.25,
                availability: 0.2,
                coverage: 0.15,
                setupTime: 0.05,
                cost: 0.05
            };
        }
    }
}
```

---

## 🔄 Failover Execution Engine

### Graceful Transition Management
```javascript
class FailoverExecutionEngine {
    constructor() {
        this.transitionManager = new LayerTransitionManager();
        this.connectionMigrator = new ConnectionMigrator();
        this.statePreserver = new StatePreserver();
    }
    
    async executeFailover(failoverDecision) {
        const executionPlan = await this.createExecutionPlan(failoverDecision);
        
        try {
            // Phase 1: Preparation
            await this.prepareFailover(executionPlan);
            
            // Phase 2: State preservation
            const preservedState = await this.statePreserver.preserveCurrentState();
            
            // Phase 3: New layer activation
            const newLayer = await this.activateNewLayer(executionPlan.targetLayer);
            
            // Phase 4: Connection migration
            const migrationResult = await this.connectionMigrator.migrateConnections({
                from: executionPlan.currentLayer,
                to: newLayer,
                preservedState: preservedState
            });
            
            // Phase 5: Verification
            const verification = await this.verifyFailover(newLayer, migrationResult);
            
            // Phase 6: Cleanup
            await this.cleanupOldLayer(executionPlan.currentLayer);
            
            return {
                success: true,
                executionTime: Date.now() - executionPlan.startTime,
                newActiveLayer: newLayer.type,
                migrationStats: migrationResult,
                verification: verification
            };
            
        } catch (error) {
            // Rollback on failure
            await this.rollbackFailover(executionPlan, error);
            throw new Error(`Failover execution failed: ${error.message}`);
        }
    }
    
    async createExecutionPlan(failoverDecision) {
        const currentLayer = await this.getCurrentActiveLayer();
        const targetLayer = failoverDecision.targetLayer;
        
        return {
            startTime: Date.now(),
            currentLayer: currentLayer,
            targetLayer: targetLayer,
            urgency: failoverDecision.urgency,
            reason: failoverDecision.reason,
            steps: await this.generateExecutionSteps(currentLayer, targetLayer),
            rollbackPlan: await this.createRollbackPlan(currentLayer, targetLayer),
            timeoutLimits: this.calculateTimeoutLimits(failoverDecision.urgency)
        };
    }
    
    async prepareFailover(executionPlan) {
        // Prepare target layer for activation
        await this.preActivateLayer(executionPlan.targetLayer);
        
        // Setup monitoring for transition
        await this.setupTransitionMonitoring(executionPlan);
        
        // Notify other system components
        await this.notifyFailoverStart(executionPlan);
        
        // Buffer critical messages
        await this.startMessageBuffering();
        
        return { preparationComplete: true };
    }
    
    async activateNewLayer(targetLayer) {
        const activationConfig = await this.getLayerActivationConfig(targetLayer);
        
        switch (targetLayer.type) {
            case 'infrastructure':
                return await this.activateInfrastructureLayer(activationConfig);
            case 'local_mesh':
                return await this.activateLocalMeshLayer(activationConfig);
            case 'extended_hardware':
                return await this.activateExtendedHardwareLayer(activationConfig);
            case 'manual_relay':
                return await this.activateManualRelayLayer(activationConfig);
            default:
                throw new Error(`Unknown layer type: ${targetLayer.type}`);
        }
    }
    
    async verifyFailover(newLayer, migrationResult) {
        const verificationTests = [
            this.verifyLayerConnectivity(newLayer),
            this.verifyMessageDelivery(newLayer),
            this.verifyPerformanceBaseline(newLayer),
            this.verifyStateMigration(migrationResult)
        ];
        
        const results = await Promise.all(verificationTests);
        
        const overallSuccess = results.every(result => result.success);
        
        return {
            success: overallSuccess,
            tests: results,
            confidence: this.calculateVerificationConfidence(results),
            issues: results.filter(r => !r.success)
        };
    }
}
```

### Connection Migration Strategy
```javascript
class ConnectionMigrator {
    constructor() {
        this.activeConnections = new Map();
        this.migrationStrategies = new MigrationStrategyRegistry();
    }
    
    async migrateConnections(migrationConfig) {
        const { from, to, preservedState } = migrationConfig;
        
        // Analyze existing connections
        const connections = await this.analyzeActiveConnections(from);
        
        // Group connections by migration strategy
        const migrationGroups = this.groupConnectionsByStrategy(connections, from, to);
        
        // Execute migration for each group
        const migrationResults = await Promise.all(
            migrationGroups.map(async group => ({
                strategy: group.strategy,
                connections: group.connections,
                result: await this.executeMigrationStrategy(group, to, preservedState)
            }))
        );
        
        return {
            totalConnections: connections.length,
            migrationGroups: migrationResults,
            successfulMigrations: migrationResults.reduce((sum, group) => 
                sum + group.result.successful.length, 0),
            failedMigrations: migrationResults.reduce((sum, group) => 
                sum + group.result.failed.length, 0),
            migrationTime: this.calculateTotalMigrationTime(migrationResults)
        };
    }
    
    groupConnectionsByStrategy(connections, fromLayer, toLayer) {
        return connections.reduce((groups, connection) => {
            const strategy = this.selectMigrationStrategy(connection, fromLayer, toLayer);
            
            let group = groups.find(g => g.strategy === strategy);
            if (!group) {
                group = { strategy, connections: [] };
                groups.push(group);
            }
            
            group.connections.push(connection);
            return groups;
        }, []);
    }
    
    selectMigrationStrategy(connection, fromLayer, toLayer) {
        // Direct migration: Same protocol on both layers
        if (this.isProtocolCompatible(connection.protocol, fromLayer, toLayer)) {
            return 'direct_migration';
        }
        
        // Protocol translation: Different protocols
        if (this.hasProtocolTranslator(fromLayer.protocol, toLayer.protocol)) {
            return 'protocol_translation';
        }
        
        // Session recreation: Complete session restart
        if (this.canRecreateSession(connection, toLayer)) {
            return 'session_recreation';
        }
        
        // Store and forward: Buffer messages for later delivery
        return 'store_and_forward';
    }
    
    async executeMigrationStrategy(group, targetLayer, preservedState) {
        const strategy = this.migrationStrategies.get(group.strategy);
        
        const results = await Promise.allSettled(
            group.connections.map(async connection => 
                await strategy.migrate(connection, targetLayer, preservedState)
            )
        );
        
        return {
            successful: results.filter(r => r.status === 'fulfilled').map(r => r.value),
            failed: results.filter(r => r.status === 'rejected').map(r => r.reason),
            executionTime: strategy.getExecutionTime()
        };
    }
}
```

---

## 📈 Adaptive Failover Optimization

### Machine Learning Integration
```javascript
class AdaptiveFailoverOptimizer {
    constructor() {
        this.learningEngine = new FailoverLearningEngine();
        this.optimizationEngine = new FailoverOptimizationEngine();
        this.experienceDB = new FailoverExperienceDatabase();
    }
    
    async optimizeFailoverParameters(historicalData) {
        // Analyze historical failover performance
        const analysis = await this.learningEngine.analyzeHistoricalPerformance(historicalData);
        
        // Identify optimization opportunities
        const opportunities = await this.identifyOptimizationOpportunities(analysis);
        
        // Generate optimized parameters
        const optimizedParams = await this.optimizationEngine.optimize({
            currentParameters: await this.getCurrentParameters(),
            historicalPerformance: analysis,
            optimizationTargets: opportunities
        });
        
        // Validate optimizations
        const validation = await this.validateOptimizations(optimizedParams);
        
        if (validation.safe) {
            await this.applyOptimizations(optimizedParams);
        }
        
        return {
            optimizationApplied: validation.safe,
            optimizedParameters: optimizedParams,
            expectedImprovement: validation.expectedImprovement,
            riskAssessment: validation.risks
        };
    }
    
    async learnFromFailoverExperience(failoverExperience) {
        // Store experience in database
        await this.experienceDB.store(failoverExperience);
        
        // Extract learnings
        const learnings = await this.learningEngine.extractLearnings(failoverExperience);
        
        // Update failover models
        await this.updateFailoverModels(learnings);
        
        return {
            experienceStored: true,
            learningsExtracted: learnings,
            modelUpdates: await this.getModelUpdateSummary()
        };
    }
}
```

### Self-Improving Thresholds
```javascript
class DynamicThresholdManager {
    constructor() {
        this.thresholdOptimizer = new ThresholdOptimizer();
        this.performanceTracker = new PerformanceTracker();
    }
    
    async adaptThresholds(performanceHistory) {
        // Analyze current threshold effectiveness
        const effectiveness = await this.analyzeThresholdEffectiveness(performanceHistory);
        
        // Calculate optimal thresholds
        const optimizedThresholds = await this.thresholdOptimizer.calculateOptimalThresholds({
            historical: performanceHistory,
            currentEffectiveness: effectiveness,
            targetMetrics: {
                falsePositiveRate: 0.05,  // 5% false positive target
                falseNegativeRate: 0.02,  // 2% false negative target
                responseTime: 5000        // 5 second response time target
            }
        });
        
        return {
            currentThresholds: await this.getCurrentThresholds(),
            optimizedThresholds: optimizedThresholds,
            expectedImprovement: this.calculateExpectedImprovement(optimizedThresholds),
            confidence: optimizedThresholds.confidence
        };
    }
}
```

---

## 🎯 Algorithm Performance Metrics

### Key Performance Indicators
```javascript
class FailoverPerformanceMetrics {
    constructor() {
        this.metricsCollector = new FailoverMetricsCollector();
    }
    
    async calculateKPIs() {
        return {
            // Speed Metrics
            failoverDetectionTime: await this.calculateAverageDetectionTime(),
            failoverExecutionTime: await this.calculateAverageExecutionTime(),
            totalFailoverTime: await this.calculateTotalFailoverTime(),
            
            // Accuracy Metrics
            falsePositiveRate: await this.calculateFalsePositiveRate(),
            falseNegativeRate: await this.calculateFalseNegativeRate(),
            predictionAccuracy: await this.calculatePredictionAccuracy(),
            
            // Success Metrics
            failoverSuccessRate: await this.calculateSuccessRate(),
            connectionMigrationSuccessRate: await this.calculateMigrationSuccessRate(),
            serviceContinuityScore: await this.calculateServiceContinuity(),
            
            // Efficiency Metrics
            resourceUtilization: await this.calculateResourceUtilization(),
            powerEfficiency: await this.calculatePowerEfficiency(),
            networkEfficiency: await this.calculateNetworkEfficiency()
        };
    }
}
```

### Success Criteria for Failover Algorithm
- **Detection Time**: <5 seconds for critical failures
- **Execution Time**: <30 seconds for layer switching
- **Success Rate**: >95% successful failovers
- **False Positive Rate**: <5% unnecessary failovers
- **Service Continuity**: >99% message delivery during transition
- **Prediction Accuracy**: >80% failure prediction accuracy

Bu otomatik failover algoritması, Cascading Network'ün akıllı karar verme sistemini oluşturur ve tüm katmanlar arasında sorunsuz geçişi sağlar.