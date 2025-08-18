// lib/services/ai/emergency_detection_engine.dart - AI Emergency Detection Engine
import 'dart:async';
import 'dart:math';
import 'package:meshnet_app/utils/logger.dart';

/// Emergency types detected by AI
enum EmergencyType {
  medical,
  fire,
  accident,
  natural_disaster,
  security_threat,
  infrastructure_failure,
  search_rescue,
  chemical_hazard,
  unknown,
}

/// Emergency severity levels
enum EmergencySeverity {
  low,        // Information, non-urgent
  medium,     // Requires attention
  high,       // Urgent response needed
  critical,   // Life-threatening, immediate action
}

/// Detection confidence levels
enum DetectionConfidence {
  low,        // 0-40% confidence
  medium,     // 40-70% confidence
  high,       // 70-90% confidence
  certain,    // 90-100% confidence
}

/// Data source types for AI analysis
enum DataSourceType {
  text_message,
  voice_audio,
  sensor_data,
  location_data,
  network_pattern,
  user_behavior,
  environmental,
}

/// Emergency detection result
class EmergencyDetectionResult {
  final String id;
  final EmergencyType type;
  final EmergencySeverity severity;
  final DetectionConfidence confidence;
  final DateTime timestamp;
  final Map<String, dynamic> sourceData;
  final List<DataSourceType> dataSources;
  final Map<String, double> aiScores;
  final String description;
  final Map<String, dynamic> metadata;
  final List<String> keywords;
  final Map<String, dynamic> location;

  EmergencyDetectionResult({
    required this.id,
    required this.type,
    required this.severity,
    required this.confidence,
    required this.timestamp,
    required this.sourceData,
    required this.dataSources,
    required this.aiScores,
    required this.description,
    required this.metadata,
    required this.keywords,
    required this.location,
  });

  factory EmergencyDetectionResult.create({
    required EmergencyType type,
    required EmergencySeverity severity,
    required DetectionConfidence confidence,
    required Map<String, dynamic> sourceData,
    required List<DataSourceType> dataSources,
    Map<String, double>? aiScores,
    String? description,
    Map<String, dynamic>? metadata,
    List<String>? keywords,
    Map<String, dynamic>? location,
  }) {
    return EmergencyDetectionResult(
      id: _generateDetectionId(),
      type: type,
      severity: severity,
      confidence: confidence,
      timestamp: DateTime.now(),
      sourceData: sourceData,
      dataSources: dataSources,
      aiScores: aiScores ?? {},
      description: description ?? '',
      metadata: metadata ?? {},
      keywords: keywords ?? [],
      location: location ?? {},
    );
  }

  /// Check if detection is actionable (high confidence + medium+ severity)
  bool get isActionable {
    return (confidence == DetectionConfidence.high || confidence == DetectionConfidence.certain) &&
           (severity == EmergencySeverity.medium || 
            severity == EmergencySeverity.high || 
            severity == EmergencySeverity.critical);
  }

  /// Check if detection requires immediate response
  bool get requiresImmediateResponse {
    return severity == EmergencySeverity.critical && 
           (confidence == DetectionConfidence.high || confidence == DetectionConfidence.certain);
  }

  static String _generateDetectionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'det_${timestamp}_$random';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'severity': severity.toString(),
      'confidence': confidence.toString(),
      'timestamp': timestamp.toIso8601String(),
      'sourceData': sourceData,
      'dataSources': dataSources.map((e) => e.toString()).toList(),
      'aiScores': aiScores,
      'description': description,
      'metadata': metadata,
      'keywords': keywords,
      'location': location,
    };
  }

  factory EmergencyDetectionResult.fromJson(Map<String, dynamic> json) {
    return EmergencyDetectionResult(
      id: json['id'],
      type: EmergencyType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => EmergencyType.unknown,
      ),
      severity: EmergencySeverity.values.firstWhere(
        (e) => e.toString() == json['severity'],
      ),
      confidence: DetectionConfidence.values.firstWhere(
        (e) => e.toString() == json['confidence'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      sourceData: json['sourceData'],
      dataSources: (json['dataSources'] as List)
          .map((e) => DataSourceType.values.firstWhere(
                (type) => type.toString() == e,
              ))
          .toList(),
      aiScores: Map<String, double>.from(json['aiScores']),
      description: json['description'],
      metadata: json['metadata'],
      keywords: List<String>.from(json['keywords']),
      location: json['location'],
    );
  }
}

/// AI Emergency Detection Engine
class EmergencyDetectionEngine {
  static EmergencyDetectionEngine? _instance;
  static EmergencyDetectionEngine get instance => _instance ??= EmergencyDetectionEngine._internal();
  
  EmergencyDetectionEngine._internal();

  final Logger _logger = Logger('EmergencyDetectionEngine');
  
  bool _isInitialized = false;
  Timer? _trainingTimer;
  
  // AI Model weights and parameters (simplified)
  final Map<String, double> _modelWeights = {};
  final Map<String, List<String>> _emergencyKeywords = {};
  final Map<String, double> _contextualWeights = {};
  final List<EmergencyDetectionResult> _detectionHistory = [];
  
  // Streaming controllers for real-time detection
  final StreamController<EmergencyDetectionResult> _detectionController = 
      StreamController<EmergencyDetectionResult>.broadcast();
  
  bool get isInitialized => _isInitialized;
  Stream<EmergencyDetectionResult> get detectionStream => _detectionController.stream;
  List<EmergencyDetectionResult> get detectionHistory => List.unmodifiable(_detectionHistory);

  /// Initialize AI Emergency Detection Engine
  Future<bool> initialize() async {
    try {
      // Logging disabled;
      
      // Load pre-trained models and keywords
      await _loadEmergencyKeywords();
      await _loadModelWeights();
      await _loadContextualWeights();
      
      // Start background training
      _startBackgroundTraining();
      
      _isInitialized = true;
      // Logging disabled;
      return true;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Shutdown AI engine
  Future<void> shutdown() async {
    // Logging disabled;
    
    _trainingTimer?.cancel();
    await _detectionController.close();
    
    _isInitialized = false;
    // Logging disabled;
  }

  /// Analyze text message for emergency content
  Future<EmergencyDetectionResult?> analyzeTextMessage({
    required String message,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  }) async {
    if (!_isInitialized) {
      // Logging disabled;
      return null;
    }

    try {
      final analysisResult = await _performTextAnalysis(message, context, location);
      
      if (analysisResult != null) {
        await _addToDetectionHistory(analysisResult);
        _detectionController.add(analysisResult);
        
        if (analysisResult.isActionable) {
          // Logging disabled;
        }
      }
      
      return analysisResult;
    } catch (e) {
      // Logging disabled;
      return null;
    }
  }

  /// Analyze sensor data for emergency patterns
  Future<EmergencyDetectionResult?> analyzeSensorData({
    required Map<String, dynamic> sensorData,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  }) async {
    if (!_isInitialized) {
      // Logging disabled;
      return null;
    }

    try {
      final analysisResult = await _performSensorAnalysis(sensorData, context, location);
      
      if (analysisResult != null) {
        await _addToDetectionHistory(analysisResult);
        _detectionController.add(analysisResult);
        
        if (analysisResult.isActionable) {
          // Logging disabled;
        }
      }
      
      return analysisResult;
    } catch (e) {
      // Logging disabled;
      return null;
    }
  }

  /// Analyze behavioral patterns for emergency detection
  Future<EmergencyDetectionResult?> analyzeBehavioralPattern({
    required Map<String, dynamic> behaviorData,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  }) async {
    if (!_isInitialized) {
      // Logging disabled;
      return null;
    }

    try {
      final analysisResult = await _performBehaviorAnalysis(behaviorData, context, location);
      
      if (analysisResult != null) {
        await _addToDetectionHistory(analysisResult);
        _detectionController.add(analysisResult);
        
        if (analysisResult.isActionable) {
          // Logging disabled;
        }
      }
      
      return analysisResult;
    } catch (e) {
      // Logging disabled;
      return null;
    }
  }

  /// Analyze multi-modal data (text + sensor + behavior)
  Future<EmergencyDetectionResult?> analyzeMultiModalData({
    String? textMessage,
    Map<String, dynamic>? sensorData,
    Map<String, dynamic>? behaviorData,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  }) async {
    if (!_isInitialized) {
      // Logging disabled;
      return null;
    }

    try {
      final analysisResults = <EmergencyDetectionResult>[];
      
      // Analyze each data source
      if (textMessage != null) {
        final textResult = await analyzeTextMessage(
          message: textMessage,
          context: context,
          location: location,
        );
        if (textResult != null) analysisResults.add(textResult);
      }
      
      if (sensorData != null) {
        final sensorResult = await analyzeSensorData(
          sensorData: sensorData,
          context: context,
          location: location,
        );
        if (sensorResult != null) analysisResults.add(sensorResult);
      }
      
      if (behaviorData != null) {
        final behaviorResult = await analyzeBehavioralPattern(
          behaviorData: behaviorData,
          context: context,
          location: location,
        );
        if (behaviorResult != null) analysisResults.add(behaviorResult);
      }
      
      // Fusion analysis - combine results for higher confidence
      if (analysisResults.isNotEmpty) {
        return await _performFusionAnalysis(analysisResults, context, location);
      }
      
      return null;
    } catch (e) {
      // Logging disabled;
      return null;
    }
  }

  /// Get AI detection statistics
  Map<String, dynamic> getDetectionStatistics() {
    final totalDetections = _detectionHistory.length;
    final actionableDetections = _detectionHistory.where((d) => d.isActionable).length;
    final criticalDetections = _detectionHistory.where((d) => d.severity == EmergencySeverity.critical).length;
    
    final typeDistribution = <EmergencyType, int>{};
    final severityDistribution = <EmergencySeverity, int>{};
    final confidenceDistribution = <DetectionConfidence, int>{};
    
    for (final detection in _detectionHistory) {
      typeDistribution[detection.type] = (typeDistribution[detection.type] ?? 0) + 1;
      severityDistribution[detection.severity] = (severityDistribution[detection.severity] ?? 0) + 1;
      confidenceDistribution[detection.confidence] = (confidenceDistribution[detection.confidence] ?? 0) + 1;
    }
    
    return {
      'initialized': _isInitialized,
      'totalDetections': totalDetections,
      'actionableDetections': actionableDetections,
      'criticalDetections': criticalDetections,
      'accuracyRate': totalDetections > 0 ? actionableDetections / totalDetections : 0.0,
      'typeDistribution': typeDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'severityDistribution': severityDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'confidenceDistribution': confidenceDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'modelWeights': _modelWeights.length,
      'emergencyKeywords': _emergencyKeywords.values.fold<int>(0, (total, list) => total + list.length),
    };
  }

  /// Perform text analysis using AI models
  Future<EmergencyDetectionResult?> _performTextAnalysis(
    String message,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  ) async {
    final lowerMessage = message.toLowerCase();
    final words = lowerMessage.split(RegExp(r'\s+'));
    
    double maxScore = 0.0;
    EmergencyType detectedType = EmergencyType.unknown;
    final matchedKeywords = <String>[];
    final aiScores = <String, double>{};
    
    // Keyword-based detection
    for (final entry in _emergencyKeywords.entries) {
      final type = EmergencyType.values.firstWhere(
        (e) => e.toString().split('.').last == entry.key,
        orElse: () => EmergencyType.unknown,
      );
      
      double typeScore = 0.0;
      final typeKeywords = <String>[];
      
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          typeScore += _modelWeights[keyword] ?? 1.0;
          typeKeywords.add(keyword);
        }
      }
      
      // Contextual weight adjustment
      if (context != null) {
        typeScore *= _contextualWeights[entry.key] ?? 1.0;
      }
      
      aiScores[entry.key] = typeScore;
      
      if (typeScore > maxScore) {
        maxScore = typeScore;
        detectedType = type;
        matchedKeywords.clear();
        matchedKeywords.addAll(typeKeywords);
      }
    }
    
    // Determine severity and confidence
    final severity = _calculateSeverity(maxScore, matchedKeywords, context);
    final confidence = _calculateConfidence(maxScore, matchedKeywords.length);
    
    // Only return result if confidence is above threshold
    if (confidence == DetectionConfidence.low || maxScore < 0.3) {
      return null;
    }
    
    return EmergencyDetectionResult.create(
      type: detectedType,
      severity: severity,
      confidence: confidence,
      sourceData: {
        'message': message,
        'analysis_score': maxScore,
        'word_count': words.length,
      },
      dataSources: [DataSourceType.text_message],
      aiScores: aiScores,
      description: 'Emergency detected in text message',
      keywords: matchedKeywords,
      location: location,
      metadata: {
        'analysis_method': 'keyword_based',
        'matched_keywords_count': matchedKeywords.length,
        'message_length': message.length,
      },
    );
  }

  /// Perform sensor data analysis
  Future<EmergencyDetectionResult?> _performSensorAnalysis(
    Map<String, dynamic> sensorData,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  ) async {
    double emergencyScore = 0.0;
    EmergencyType detectedType = EmergencyType.unknown;
    final aiScores = <String, double>{};
    
    // Temperature analysis
    if (sensorData.containsKey('temperature')) {
      final temp = sensorData['temperature'] as double?;
      if (temp != null) {
        if (temp > 50.0) { // High temperature = potential fire
          emergencyScore += 0.7;
          detectedType = EmergencyType.fire;
          aiScores['temperature_fire'] = 0.7;
        } else if (temp < -10.0) { // Extreme cold
          emergencyScore += 0.4;
          detectedType = EmergencyType.natural_disaster;
          aiScores['temperature_cold'] = 0.4;
        }
      }
    }
    
    // Accelerometer analysis (accident detection)
    if (sensorData.containsKey('acceleration')) {
      final accel = sensorData['acceleration'] as Map<String, dynamic>?;
      if (accel != null) {
        final magnitude = _calculateAccelerationMagnitude(accel);
        if (magnitude > 20.0) { // High G-force = potential accident
          emergencyScore += 0.8;
          detectedType = EmergencyType.accident;
          aiScores['acceleration_impact'] = 0.8;
        }
      }
    }
    
    // Sound level analysis
    if (sensorData.containsKey('sound_level')) {
      final soundLevel = sensorData['sound_level'] as double?;
      if (soundLevel != null && soundLevel > 85.0) { // Loud noise
        emergencyScore += 0.5;
        if (detectedType == EmergencyType.unknown) {
          detectedType = EmergencyType.accident;
        }
        aiScores['sound_level'] = 0.5;
      }
    }
    
    // Air quality analysis
    if (sensorData.containsKey('air_quality')) {
      final airQuality = sensorData['air_quality'] as double?;
      if (airQuality != null && airQuality > 200.0) { // Poor air quality
        emergencyScore += 0.6;
        detectedType = EmergencyType.chemical_hazard;
        aiScores['air_quality'] = 0.6;
      }
    }
    
    if (emergencyScore < 0.4) return null;
    
    final severity = _calculateSeverityFromScore(emergencyScore);
    final confidence = _calculateConfidenceFromScore(emergencyScore);
    
    return EmergencyDetectionResult.create(
      type: detectedType,
      severity: severity,
      confidence: confidence,
      sourceData: sensorData,
      dataSources: [DataSourceType.sensor_data],
      aiScores: aiScores,
      description: 'Emergency detected from sensor data',
      location: location,
      metadata: {
        'analysis_method': 'sensor_based',
        'total_score': emergencyScore,
        'sensor_count': sensorData.length,
      },
    );
  }

  /// Perform behavioral pattern analysis
  Future<EmergencyDetectionResult?> _performBehaviorAnalysis(
    Map<String, dynamic> behaviorData,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  ) async {
    double emergencyScore = 0.0;
    EmergencyType detectedType = EmergencyType.unknown;
    final aiScores = <String, double>{};
    
    // Rapid message sending pattern
    if (behaviorData.containsKey('message_frequency')) {
      final frequency = behaviorData['message_frequency'] as double?;
      if (frequency != null && frequency > 10.0) { // Many messages in short time
        emergencyScore += 0.5;
        aiScores['message_frequency'] = 0.5;
      }
    }
    
    // Location change pattern
    if (behaviorData.containsKey('location_changes')) {
      final changes = behaviorData['location_changes'] as int?;
      if (changes != null && changes > 5) { // Rapid location changes
        emergencyScore += 0.4;
        detectedType = EmergencyType.search_rescue;
        aiScores['location_instability'] = 0.4;
      }
    }
    
    // Network connectivity pattern
    if (behaviorData.containsKey('network_instability')) {
      final instability = behaviorData['network_instability'] as double?;
      if (instability != null && instability > 0.7) {
        emergencyScore += 0.3;
        detectedType = EmergencyType.infrastructure_failure;
        aiScores['network_instability'] = 0.3;
      }
    }
    
    // Emergency contact attempts
    if (behaviorData.containsKey('emergency_contacts_tried')) {
      final attempts = behaviorData['emergency_contacts_tried'] as int?;
      if (attempts != null && attempts > 0) {
        emergencyScore += 0.8;
        detectedType = EmergencyType.medical;
        aiScores['emergency_contacts'] = 0.8;
      }
    }
    
    if (emergencyScore < 0.3) return null;
    
    final severity = _calculateSeverityFromScore(emergencyScore);
    final confidence = _calculateConfidenceFromScore(emergencyScore);
    
    return EmergencyDetectionResult.create(
      type: detectedType,
      severity: severity,
      confidence: confidence,
      sourceData: behaviorData,
      dataSources: [DataSourceType.user_behavior],
      aiScores: aiScores,
      description: 'Emergency detected from behavioral patterns',
      location: location,
      metadata: {
        'analysis_method': 'behavior_based',
        'total_score': emergencyScore,
        'pattern_count': behaviorData.length,
      },
    );
  }

  /// Perform fusion analysis combining multiple detection results
  Future<EmergencyDetectionResult?> _performFusionAnalysis(
    List<EmergencyDetectionResult> results,
    Map<String, dynamic>? context,
    Map<String, dynamic>? location,
  ) async {
    if (results.isEmpty) return null;
    
    // Weighted fusion based on data source reliability
    final sourceWeights = {
      DataSourceType.text_message: 0.8,
      DataSourceType.sensor_data: 0.9,
      DataSourceType.user_behavior: 0.7,
      DataSourceType.location_data: 0.6,
      DataSourceType.voice_audio: 0.8,
    };
    
    double totalScore = 0.0;
    double totalWeight = 0.0;
    final combinedScores = <String, double>{};
    final combinedKeywords = <String>[];
    final combinedSources = <DataSourceType>[];
    
    // Find most frequent emergency type
    final typeFrequency = <EmergencyType, int>{};
    for (final result in results) {
      typeFrequency[result.type] = (typeFrequency[result.type] ?? 0) + 1;
      
      // Combine scores
      for (final source in result.dataSources) {
        final weight = sourceWeights[source] ?? 0.5;
        totalScore += weight;
        totalWeight += weight;
        
        if (!combinedSources.contains(source)) {
          combinedSources.add(source);
        }
      }
      
      // Combine AI scores
      for (final entry in result.aiScores.entries) {
        combinedScores[entry.key] = (combinedScores[entry.key] ?? 0.0) + entry.value;
      }
      
      // Combine keywords
      combinedKeywords.addAll(result.keywords);
    }
    
    final mostFrequentType = typeFrequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final averageScore = totalWeight > 0 ? totalScore / totalWeight : 0.0;
    final fusionConfidence = _calculateConfidenceFromFusion(results.length, averageScore);
    final fusionSeverity = _calculateSeverityFromScore(averageScore);
    
    return EmergencyDetectionResult.create(
      type: mostFrequentType,
      severity: fusionSeverity,
      confidence: fusionConfidence,
      sourceData: {
        'fusion_analysis': true,
        'source_count': results.length,
        'average_score': averageScore,
      },
      dataSources: combinedSources,
      aiScores: combinedScores,
      description: 'Emergency detected through multi-modal fusion analysis',
      keywords: combinedKeywords.toSet().toList(),
      location: location,
      metadata: {
        'analysis_method': 'fusion_based',
        'individual_results': results.length,
        'fusion_score': averageScore,
      },
    );
  }

  /// Calculate emergency severity
  EmergencySeverity _calculateSeverity(
    double score,
    List<String> keywords,
    Map<String, dynamic>? context,
  ) {
    // High severity keywords
    final criticalKeywords = ['emergency', 'help', 'urgent', 'critical', 'dying', 'fire', 'accident'];
    final hasCriticalKeywords = keywords.any((k) => criticalKeywords.contains(k));
    
    if (hasCriticalKeywords || score > 0.8) {
      return EmergencySeverity.critical;
    } else if (score > 0.6) {
      return EmergencySeverity.high;
    } else if (score > 0.4) {
      return EmergencySeverity.medium;
    } else {
      return EmergencySeverity.low;
    }
  }

  /// Calculate detection confidence
  DetectionConfidence _calculateConfidence(double score, int keywordCount) {
    if (score > 0.9 && keywordCount > 2) {
      return DetectionConfidence.certain;
    } else if (score > 0.7 || keywordCount > 1) {
      return DetectionConfidence.high;
    } else if (score > 0.4) {
      return DetectionConfidence.medium;
    } else {
      return DetectionConfidence.low;
    }
  }

  /// Calculate severity from numerical score
  EmergencySeverity _calculateSeverityFromScore(double score) {
    if (score > 0.8) return EmergencySeverity.critical;
    if (score > 0.6) return EmergencySeverity.high;
    if (score > 0.4) return EmergencySeverity.medium;
    return EmergencySeverity.low;
  }

  /// Calculate confidence from numerical score
  DetectionConfidence _calculateConfidenceFromScore(double score) {
    if (score > 0.9) return DetectionConfidence.certain;
    if (score > 0.7) return DetectionConfidence.high;
    if (score > 0.5) return DetectionConfidence.medium;
    return DetectionConfidence.low;
  }

  /// Calculate confidence from fusion analysis
  DetectionConfidence _calculateConfidenceFromFusion(int sourceCount, double averageScore) {
    final fusionBonus = sourceCount > 1 ? 0.1 * (sourceCount - 1) : 0.0;
    final adjustedScore = (averageScore + fusionBonus).clamp(0.0, 1.0);
    return _calculateConfidenceFromScore(adjustedScore);
  }

  /// Calculate acceleration magnitude
  double _calculateAccelerationMagnitude(Map<String, dynamic> accel) {
    final x = accel['x'] as double? ?? 0.0;
    final y = accel['y'] as double? ?? 0.0;
    final z = accel['z'] as double? ?? 0.0;
    return sqrt(x * x + y * y + z * z);
  }

  /// Load emergency keywords for different types
  Future<void> _loadEmergencyKeywords() async {
    _emergencyKeywords.clear();
    
    _emergencyKeywords['medical'] = [
      'help', 'emergency', 'medical', 'doctor', 'hospital', 'ambulance', 'injury', 'pain',
      'bleeding', 'unconscious', 'heart attack', 'stroke', 'dying', 'critical', 'urgent'
    ];
    
    _emergencyKeywords['fire'] = [
      'fire', 'smoke', 'burning', 'flames', 'evacuation', 'firefighter', 'extinguisher'
    ];
    
    _emergencyKeywords['accident'] = [
      'accident', 'crash', 'collision', 'injury', 'trapped', 'vehicle', 'road', 'emergency'
    ];
    
    _emergencyKeywords['natural_disaster'] = [
      'earthquake', 'flood', 'hurricane', 'tornado', 'storm', 'disaster', 'evacuation',
      'landslide', 'tsunami', 'volcanic'
    ];
    
    _emergencyKeywords['security_threat'] = [
      'threat', 'danger', 'attack', 'weapon', 'violence', 'security', 'police', 'crime'
    ];
    
    _emergencyKeywords['search_rescue'] = [
      'lost', 'missing', 'search', 'rescue', 'stranded', 'location', 'find', 'help'
    ];
    
    _emergencyKeywords['chemical_hazard'] = [
      'chemical', 'toxic', 'gas', 'leak', 'hazard', 'poison', 'contamination', 'exposure'
    ];
    
    // Logging disabled;
  }

  /// Load AI model weights
  Future<void> _loadModelWeights() async {
    _modelWeights.clear();
    
    // Assign weights to different keywords (simplified)
    const highWeight = 2.0;
    const mediumWeight = 1.5;
    const lowWeight = 1.0;
    
    // Critical keywords get higher weights
    for (final keyword in ['emergency', 'help', 'urgent', 'critical', 'dying']) {
      _modelWeights[keyword] = highWeight;
    }
    
    // Medical keywords
    for (final keyword in ['medical', 'doctor', 'hospital', 'ambulance', 'injury']) {
      _modelWeights[keyword] = mediumWeight;
    }
    
    // General emergency keywords
    for (final keyword in ['fire', 'accident', 'disaster', 'danger']) {
      _modelWeights[keyword] = mediumWeight;
    }
    
    // Logging disabled;
  }

  /// Load contextual weights for different emergency types
  Future<void> _loadContextualWeights() async {
    _contextualWeights.clear();
    
    _contextualWeights['medical'] = 1.2;
    _contextualWeights['fire'] = 1.3;
    _contextualWeights['accident'] = 1.1;
    _contextualWeights['natural_disaster'] = 1.4;
    _contextualWeights['security_threat'] = 1.2;
    _contextualWeights['search_rescue'] = 1.0;
    _contextualWeights['chemical_hazard'] = 1.3;
    
    // Logging disabled;
  }

  /// Add detection to history
  Future<void> _addToDetectionHistory(EmergencyDetectionResult result) async {
    _detectionHistory.add(result);
    
    // Keep only last 1000 detections
    if (_detectionHistory.length > 1000) {
      _detectionHistory.removeAt(0);
    }
  }

  /// Start background training to improve models
  void _startBackgroundTraining() {
    _trainingTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      await _performBackgroundTraining();
    });
  }

  /// Perform background training to improve AI models
  Future<void> _performBackgroundTraining() async {
    if (_detectionHistory.length < 10) return;
    
    try {
      // Analyze recent detections to improve model weights
      final recentDetections = _detectionHistory.skip(max(0, _detectionHistory.length - 100));
      
      // Update keyword weights based on successful detections
      for (final detection in recentDetections) {
        if (detection.isActionable) {
          for (final keyword in detection.keywords) {
            _modelWeights[keyword] = (_modelWeights[keyword] ?? 1.0) * 1.01;
          }
        }
      }
      
      // Logging disabled;
    } catch (e) {
      // Logging disabled;
    }
  }
}
