// lib/services/ai/smart_message_classifier.dart - Smart Message Classification Service
import 'dart:async';
import 'dart:math';
import 'package:meshnet_app/services/ai/emergency_detection_engine.dart';
import 'package:meshnet_app/utils/logger.dart';

/// Message classification categories
enum MessageCategory {
  emergency_critical,   // Life-threatening emergencies
  emergency_standard,   // Standard emergency situations
  urgent_request,       // Non-emergency urgent requests
  coordination,         // Emergency response coordination
  information,          // Information sharing
  status_update,        // Status reports
  social,              // Social communication
  technical,           // Technical/system messages
  spam,                // Spam or irrelevant content
  unknown,             // Unclassified
}

/// Message priority levels
enum MessagePriority {
  critical,    // Immediate attention required
  high,        // Should be handled soon
  medium,      // Normal priority
  low,         // Can be delayed
  background,  // Background processing
}

/// Message sentiment analysis
enum MessageSentiment {
  emergency,   // Emergency/panic
  urgent,      // Urgent need
  concerned,   // Worried/concerned
  neutral,     // Neutral tone
  positive,    // Positive/helpful
  frustrated,  // Frustrated/angry
}

/// Message classification result
class MessageClassificationResult {
  final String messageId;
  final MessageCategory category;
  final MessagePriority priority;
  final MessageSentiment sentiment;
  final double confidence;
  final DateTime timestamp;
  final Map<String, double> categoryScores;
  final List<String> detectedKeywords;
  final Map<String, dynamic> features;
  final bool isEmergencyRelated;
  final bool requiresImmediateAction;
  final Map<String, dynamic> metadata;

  MessageClassificationResult({
    required this.messageId,
    required this.category,
    required this.priority,
    required this.sentiment,
    required this.confidence,
    required this.timestamp,
    required this.categoryScores,
    required this.detectedKeywords,
    required this.features,
    required this.isEmergencyRelated,
    required this.requiresImmediateAction,
    required this.metadata,
  });

  factory MessageClassificationResult.create({
    required String messageId,
    required MessageCategory category,
    required MessagePriority priority,
    required MessageSentiment sentiment,
    required double confidence,
    Map<String, double>? categoryScores,
    List<String>? detectedKeywords,
    Map<String, dynamic>? features,
    Map<String, dynamic>? metadata,
  }) {
    return MessageClassificationResult(
      messageId: messageId,
      category: category,
      priority: priority,
      sentiment: sentiment,
      confidence: confidence,
      timestamp: DateTime.now(),
      categoryScores: categoryScores ?? {},
      detectedKeywords: detectedKeywords ?? [],
      features: features ?? {},
      isEmergencyRelated: _isEmergencyCategory(category),
      requiresImmediateAction: _requiresImmediateAction(category, priority),
      metadata: metadata ?? {},
    );
  }

  static bool _isEmergencyCategory(MessageCategory category) {
    return category == MessageCategory.emergency_critical ||
           category == MessageCategory.emergency_standard ||
           category == MessageCategory.urgent_request;
  }

  static bool _requiresImmediateAction(MessageCategory category, MessagePriority priority) {
    return category == MessageCategory.emergency_critical ||
           priority == MessagePriority.critical;
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'category': category.toString(),
      'priority': priority.toString(),
      'sentiment': sentiment.toString(),
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'categoryScores': categoryScores,
      'detectedKeywords': detectedKeywords,
      'features': features,
      'isEmergencyRelated': isEmergencyRelated,
      'requiresImmediateAction': requiresImmediateAction,
      'metadata': metadata,
    };
  }

  factory MessageClassificationResult.fromJson(Map<String, dynamic> json) {
    return MessageClassificationResult(
      messageId: json['messageId'],
      category: MessageCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => MessageCategory.unknown,
      ),
      priority: MessagePriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
      ),
      sentiment: MessageSentiment.values.firstWhere(
        (e) => e.toString() == json['sentiment'],
      ),
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
      categoryScores: Map<String, double>.from(json['categoryScores']),
      detectedKeywords: List<String>.from(json['detectedKeywords']),
      features: json['features'],
      isEmergencyRelated: json['isEmergencyRelated'],
      requiresImmediateAction: json['requiresImmediateAction'],
      metadata: json['metadata'],
    );
  }
}

/// Smart Message Classifier using AI/ML techniques
class SmartMessageClassifier {
  static SmartMessageClassifier? _instance;
  static SmartMessageClassifier get instance => _instance ??= SmartMessageClassifier._internal();
  
  SmartMessageClassifier._internal();

  final Logger _logger = Logger('SmartMessageClassifier');
  
  bool _isInitialized = false;
  Timer? _modelUpdateTimer;
  
  // Classification models and features
  final Map<MessageCategory, List<String>> _categoryKeywords = {};
  final Map<MessageSentiment, List<String>> _sentimentKeywords = {};
  final Map<String, double> _featureWeights = {};
  final List<MessageClassificationResult> _classificationHistory = [];
  
  // Performance metrics
  int _totalClassifications = 0;
  int _correctClassifications = 0;
  
  // Streaming controller for real-time classification
  final StreamController<MessageClassificationResult> _classificationController = 
      StreamController<MessageClassificationResult>.broadcast();

  bool get isInitialized => _isInitialized;
  Stream<MessageClassificationResult> get classificationStream => _classificationController.stream;
  List<MessageClassificationResult> get classificationHistory => List.unmodifiable(_classificationHistory);
  double get accuracy => _totalClassifications > 0 ? _correctClassifications / _totalClassifications : 0.0;

  /// Initialize smart message classifier
  Future<bool> initialize() async {
    try {
      // Logging disabled;
      
      // Load classification models
      await _loadCategoryKeywords();
      await _loadSentimentKeywords();
      await _loadFeatureWeights();
      
      // Start model update timer
      _startModelUpdateTimer();
      
      _isInitialized = true;
      // Logging disabled;
      return true;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Shutdown classifier
  Future<void> shutdown() async {
    // Logging disabled;
    
    _modelUpdateTimer?.cancel();
    await _classificationController.close();
    
    _isInitialized = false;
    // Logging disabled;
  }

  /// Classify a message
  Future<MessageClassificationResult?> classifyMessage({
    required String messageId,
    required String message,
    Map<String, dynamic>? context,
    String? senderId,
    DateTime? timestamp,
  }) async {
    if (!_isInitialized) {
      // Logging disabled;
      return null;
    }

    try {
      // Extract features from message
      final features = await _extractFeatures(message, context);
      
      // Classify category
      final categoryResult = await _classifyCategory(message, features);
      
      // Classify priority
      final priority = await _classifyPriority(message, categoryResult.category, features);
      
      // Analyze sentiment
      final sentiment = await _analyzeSentiment(message, features);
      
      // Calculate overall confidence
      final confidence = _calculateOverallConfidence(categoryResult.confidence, features);
      
      // Detect keywords
      final keywords = _detectKeywords(message);
      
      final result = MessageClassificationResult.create(
        messageId: messageId,
        category: categoryResult.category,
        priority: priority,
        sentiment: sentiment,
        confidence: confidence,
        categoryScores: categoryResult.scores,
        detectedKeywords: keywords,
        features: features,
        metadata: {
          'senderId': senderId,
          'timestamp': timestamp?.toIso8601String(),
          'message_length': message.length,
          'word_count': message.split(RegExp(r'\s+')).length,
        },
      );
      
      // Add to history and stream
      await _addToClassificationHistory(result);
      _classificationController.add(result);
      
      // Log significant classifications
      if (result.isEmergencyRelated || result.requiresImmediateAction) {
        // Logging disabled;
      }
      
      return result;
    } catch (e) {
      // Logging disabled;
      return null;
    }
  }

  /// Classify multiple messages in batch
  Future<List<MessageClassificationResult>> classifyBatch({
    required List<Map<String, dynamic>> messages,
    Map<String, dynamic>? globalContext,
  }) async {
    if (!_isInitialized) {
      // Logging disabled;
      return [];
    }

    final results = <MessageClassificationResult>[];
    
    for (final messageData in messages) {
      final result = await classifyMessage(
        messageId: messageData['id'],
        message: messageData['message'],
        context: {...?globalContext, ...?messageData['context']},
        senderId: messageData['senderId'],
        timestamp: messageData['timestamp'] != null 
            ? DateTime.parse(messageData['timestamp']) 
            : null,
      );
      
      if (result != null) {
        results.add(result);
      }
    }
    
    // Logging disabled;
    return results;
  }

  /// Re-classify message with user feedback for learning
  Future<bool> reclassifyWithFeedback({
    required String messageId,
    required MessageCategory correctCategory,
    required MessagePriority correctPriority,
    required MessageSentiment correctSentiment,
  }) async {
    if (!_isInitialized) return false;

    try {
      // Find original classification
      final originalResult = _classificationHistory
          .where((r) => r.messageId == messageId)
          .lastOrNull;
      
      if (originalResult == null) {
        // Logging disabled;
        return false;
      }
      
      // Update performance metrics
      _totalClassifications++;
      if (originalResult.category == correctCategory &&
          originalResult.priority == correctPriority &&
          originalResult.sentiment == correctSentiment) {
        _correctClassifications++;
      }
      
      // Update model weights based on feedback
      await _updateModelWeights(originalResult, correctCategory, correctPriority, correctSentiment);
      
      // Logging disabled;
      return true;
    } catch (e) {
      // Logging disabled;
      return false;
    }
  }

  /// Get classification statistics
  Map<String, dynamic> getClassificationStatistics() {
    final categoryDistribution = <MessageCategory, int>{};
    final priorityDistribution = <MessagePriority, int>{};
    final sentimentDistribution = <MessageSentiment, int>{};
    
    for (final result in _classificationHistory) {
      categoryDistribution[result.category] = (categoryDistribution[result.category] ?? 0) + 1;
      priorityDistribution[result.priority] = (priorityDistribution[result.priority] ?? 0) + 1;
      sentimentDistribution[result.sentiment] = (sentimentDistribution[result.sentiment] ?? 0) + 1;
    }
    
    final emergencyCount = _classificationHistory.where((r) => r.isEmergencyRelated).length;
    final immediateActionCount = _classificationHistory.where((r) => r.requiresImmediateAction).length;
    
    return {
      'initialized': _isInitialized,
      'totalClassifications': _classificationHistory.length,
      'accuracy': accuracy,
      'emergencyMessages': emergencyCount,
      'immediateActionRequired': immediateActionCount,
      'categoryDistribution': categoryDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'priorityDistribution': priorityDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'sentimentDistribution': sentimentDistribution.map((k, v) => MapEntry(k.toString(), v)),
      'averageConfidence': _classificationHistory.isNotEmpty
          ? _classificationHistory.map((r) => r.confidence).reduce((a, b) => a + b) / _classificationHistory.length
          : 0.0,
    };
  }

  /// Extract features from message text
  Future<Map<String, dynamic>> _extractFeatures(
    String message,
    Map<String, dynamic>? context,
  ) async {
    final lowerMessage = message.toLowerCase();
    final words = lowerMessage.split(RegExp(r'\s+'));
    
    // Basic text features
    final features = <String, dynamic>{
      'length': message.length,
      'word_count': words.length,
      'sentence_count': message.split(RegExp(r'[.!?]+')).length,
      'has_caps': message.contains(RegExp(r'[A-Z]{2,}')),
      'has_exclamation': message.contains('!'),
      'has_question': message.contains('?'),
      'has_numbers': message.contains(RegExp(r'\d')),
    };
    
    // Emergency indicators
    features['emergency_keywords'] = _countEmergencyKeywords(lowerMessage);
    features['urgent_keywords'] = _countUrgentKeywords(lowerMessage);
    features['time_keywords'] = _countTimeKeywords(lowerMessage);
    features['location_keywords'] = _countLocationKeywords(lowerMessage);
    
    // Linguistic features
    features['repeat_chars'] = _countRepeatChars(message);
    features['all_caps_ratio'] = _calculateCapsRatio(message);
    features['punctuation_ratio'] = _calculatePunctuationRatio(message);
    
    // Context features
    if (context != null) {
      features['has_location'] = context.containsKey('location');
      features['sender_history'] = context['sender_message_count'] ?? 0;
      features['time_of_day'] = DateTime.now().hour;
    }
    
    return features;
  }

  /// Classify message category
  Future<({MessageCategory category, double confidence, Map<String, double> scores})> _classifyCategory(
    String message,
    Map<String, dynamic> features,
  ) async {
    final lowerMessage = message.toLowerCase();
    final categoryScores = <String, double>{};
    
    // Score each category
    for (final entry in _categoryKeywords.entries) {
      double score = 0.0;
      
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          score += _featureWeights[keyword] ?? 1.0;
        }
      }
      
      // Apply feature-based adjustments
      score = _adjustScoreWithFeatures(score, entry.key, features);
      
      categoryScores[entry.key.toString()] = score;
    }
    
    // Find highest scoring category
    var maxScore = 0.0;
    var bestCategory = MessageCategory.unknown;
    
    for (final entry in categoryScores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        bestCategory = MessageCategory.values.firstWhere(
          (e) => e.toString() == entry.key,
          orElse: () => MessageCategory.unknown,
        );
      }
    }
    
    // Calculate confidence
    final confidence = _calculateCategoryConfidence(maxScore, categoryScores.values.toList());
    
    return (
      category: bestCategory,
      confidence: confidence,
      scores: categoryScores,
    );
  }

  /// Classify message priority
  Future<MessagePriority> _classifyPriority(
    String message,
    MessageCategory category,
    Map<String, dynamic> features,
  ) async {
    // Category-based priority
    switch (category) {
      case MessageCategory.emergency_critical:
        return MessagePriority.critical;
      case MessageCategory.emergency_standard:
        return MessagePriority.high;
      case MessageCategory.urgent_request:
        return MessagePriority.high;
      case MessageCategory.coordination:
        return MessagePriority.medium;
      case MessageCategory.information:
        return MessagePriority.medium;
      case MessageCategory.status_update:
        return MessagePriority.low;
      case MessageCategory.social:
        return MessagePriority.low;
      case MessageCategory.technical:
        return MessagePriority.low;
      case MessageCategory.spam:
        return MessagePriority.background;
      default:
        break;
    }
    
    // Feature-based priority adjustment
    if (features['has_caps'] == true || features['has_exclamation'] == true) {
      return MessagePriority.high;
    }
    
    if (features['emergency_keywords'] > 0) {
      return MessagePriority.critical;
    }
    
    if (features['urgent_keywords'] > 0) {
      return MessagePriority.high;
    }
    
    return MessagePriority.medium;
  }

  /// Analyze message sentiment
  Future<MessageSentiment> _analyzeSentiment(
    String message,
    Map<String, dynamic> features,
  ) async {
    final lowerMessage = message.toLowerCase();
    final sentimentScores = <MessageSentiment, double>{};
    
    // Score each sentiment
    for (final entry in _sentimentKeywords.entries) {
      double score = 0.0;
      
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword)) {
          score += 1.0;
        }
      }
      
      sentimentScores[entry.key] = score;
    }
    
    // Feature-based sentiment adjustment
    if (features['has_caps'] == true) {
      sentimentScores[MessageSentiment.emergency] = 
          (sentimentScores[MessageSentiment.emergency] ?? 0.0) + 1.0;
    }
    
    if (features['has_exclamation'] == true) {
      sentimentScores[MessageSentiment.urgent] = 
          (sentimentScores[MessageSentiment.urgent] ?? 0.0) + 0.5;
    }
    
    // Find highest scoring sentiment
    var maxScore = 0.0;
    var bestSentiment = MessageSentiment.neutral;
    
    for (final entry in sentimentScores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        bestSentiment = entry.key;
      }
    }
    
    return bestSentiment;
  }

  /// Calculate overall confidence
  double _calculateOverallConfidence(double categoryConfidence, Map<String, dynamic> features) {
    double confidence = categoryConfidence;
    
    // Boost confidence for clear indicators
    if (features['emergency_keywords'] > 0) confidence += 0.2;
    if (features['has_caps'] == true) confidence += 0.1;
    if (features['has_exclamation'] == true) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Detect important keywords in message
  List<String> _detectKeywords(String message) {
    final lowerMessage = message.toLowerCase();
    final keywords = <String>[];
    
    // Check all category keywords
    for (final categoryKeywords in _categoryKeywords.values) {
      for (final keyword in categoryKeywords) {
        if (lowerMessage.contains(keyword)) {
          keywords.add(keyword);
        }
      }
    }
    
    return keywords.toSet().toList();
  }

  /// Count emergency keywords
  int _countEmergencyKeywords(String message) {
    const emergencyWords = ['emergency', 'help', 'urgent', 'critical', 'asap'];
    return emergencyWords.where((word) => message.contains(word)).length;
  }

  /// Count urgent keywords
  int _countUrgentKeywords(String message) {
    const urgentWords = ['urgent', 'asap', 'immediately', 'now', 'quick'];
    return urgentWords.where((word) => message.contains(word)).length;
  }

  /// Count time-related keywords
  int _countTimeKeywords(String message) {
    const timeWords = ['now', 'immediate', 'asap', 'today', 'tonight'];
    return timeWords.where((word) => message.contains(word)).length;
  }

  /// Count location-related keywords
  int _countLocationKeywords(String message) {
    const locationWords = ['here', 'location', 'address', 'coordinates', 'gps'];
    return locationWords.where((word) => message.contains(word)).length;
  }

  /// Count repeated characters
  int _countRepeatChars(String message) {
    int count = 0;
    for (int i = 0; i < message.length - 2; i++) {
      if (message[i] == message[i + 1] && message[i] == message[i + 2]) {
        count++;
      }
    }
    return count;
  }

  /// Calculate ratio of capital letters
  double _calculateCapsRatio(String message) {
    if (message.isEmpty) return 0.0;
    final capsCount = message.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
    return capsCount / message.length;
  }

  /// Calculate punctuation ratio
  double _calculatePunctuationRatio(String message) {
    if (message.isEmpty) return 0.0;
    final punctCount = message.split('').where((c) => '!@#\$%^&*(),.?":{}|<>'.contains(c)).length;
    return punctCount / message.length;
  }

  /// Adjust category score with features
  double _adjustScoreWithFeatures(double baseScore, MessageCategory category, Map<String, dynamic> features) {
    double adjustedScore = baseScore;
    
    switch (category) {
      case MessageCategory.emergency_critical:
        if (features['has_caps'] == true) adjustedScore *= 1.5;
        if (features['emergency_keywords'] > 0) adjustedScore *= 2.0;
        break;
      case MessageCategory.emergency_standard:
        if (features['urgent_keywords'] > 0) adjustedScore *= 1.3;
        break;
      case MessageCategory.spam:
        if (features['repeat_chars'] > 3) adjustedScore *= 2.0;
        break;
      default:
        break;
    }
    
    return adjustedScore;
  }

  /// Calculate category confidence
  double _calculateCategoryConfidence(double maxScore, List<double> allScores) {
    if (allScores.isEmpty || maxScore == 0) return 0.0;
    
    final sumOtherScores = allScores.where((s) => s != maxScore).fold<double>(0.0, (sum, score) => sum + score);
    final totalScore = allScores.fold<double>(0.0, (sum, score) => sum + score);
    
    if (totalScore == 0) return 0.0;
    
    return maxScore / totalScore;
  }

  /// Load category keywords
  Future<void> _loadCategoryKeywords() async {
    _categoryKeywords.clear();
    
    _categoryKeywords[MessageCategory.emergency_critical] = [
      'emergency', 'help', 'urgent', 'critical', 'dying', 'life', 'death', 'danger',
      'fire', 'explosion', 'attack', 'threat', 'injured', 'bleeding', 'unconscious'
    ];
    
    _categoryKeywords[MessageCategory.emergency_standard] = [
      'accident', 'medical', 'hospital', 'ambulance', 'police', 'rescue', 'evacuation',
      'disaster', 'storm', 'flood', 'earthquake'
    ];
    
    _categoryKeywords[MessageCategory.urgent_request] = [
      'urgent', 'asap', 'immediate', 'quick', 'hurry', 'rush', 'priority'
    ];
    
    _categoryKeywords[MessageCategory.coordination] = [
      'coordinate', 'organize', 'plan', 'team', 'group', 'response', 'strategy'
    ];
    
    _categoryKeywords[MessageCategory.information] = [
      'info', 'update', 'news', 'report', 'status', 'situation', 'details'
    ];
    
    _categoryKeywords[MessageCategory.status_update] = [
      'status', 'update', 'progress', 'situation', 'condition', 'state'
    ];
    
    _categoryKeywords[MessageCategory.social] = [
      'hello', 'hi', 'how', 'what', 'when', 'where', 'thanks', 'please'
    ];
    
    _categoryKeywords[MessageCategory.technical] = [
      'system', 'error', 'bug', 'issue', 'problem', 'fix', 'technical', 'network'
    ];
    
    _categoryKeywords[MessageCategory.spam] = [
      'win', 'free', 'offer', 'deal', 'promotion', 'click', 'buy', 'sale'
    ];
    
    // Logging disabled;
  }

  /// Load sentiment keywords
  Future<void> _loadSentimentKeywords() async {
    _sentimentKeywords.clear();
    
    _sentimentKeywords[MessageSentiment.emergency] = [
      'panic', 'terror', 'fear', 'scared', 'terrified', 'emergency', 'help'
    ];
    
    _sentimentKeywords[MessageSentiment.urgent] = [
      'urgent', 'hurry', 'quick', 'fast', 'immediately', 'asap', 'rush'
    ];
    
    _sentimentKeywords[MessageSentiment.concerned] = [
      'worried', 'concerned', 'anxious', 'nervous', 'uneasy', 'troubled'
    ];
    
    _sentimentKeywords[MessageSentiment.neutral] = [
      'ok', 'fine', 'normal', 'regular', 'standard', 'usual'
    ];
    
    _sentimentKeywords[MessageSentiment.positive] = [
      'good', 'great', 'excellent', 'wonderful', 'amazing', 'perfect', 'happy'
    ];
    
    _sentimentKeywords[MessageSentiment.frustrated] = [
      'angry', 'frustrated', 'annoyed', 'mad', 'upset', 'irritated'
    ];
    
    // Logging disabled;
  }

  /// Load feature weights
  Future<void> _loadFeatureWeights() async {
    _featureWeights.clear();
    
    // Emergency keywords get highest weights
    const criticalWords = ['emergency', 'help', 'urgent', 'critical', 'dying'];
    for (final word in criticalWords) {
      _featureWeights[word] = 3.0;
    }
    
    // Important words get medium weights
    const importantWords = ['fire', 'accident', 'medical', 'danger', 'threat'];
    for (final word in importantWords) {
      _featureWeights[word] = 2.0;
    }
    
    // Logging disabled;
  }

  /// Add classification to history
  Future<void> _addToClassificationHistory(MessageClassificationResult result) async {
    _classificationHistory.add(result);
    
    // Keep only last 1000 classifications
    if (_classificationHistory.length > 1000) {
      _classificationHistory.removeAt(0);
    }
  }

  /// Update model weights based on feedback
  Future<void> _updateModelWeights(
    MessageClassificationResult originalResult,
    MessageCategory correctCategory,
    MessagePriority correctPriority,
    MessageSentiment correctSentiment,
  ) async {
    // Adjust feature weights based on correct classification
    for (final keyword in originalResult.detectedKeywords) {
      if (originalResult.category != correctCategory) {
        // Reduce weight for incorrectly classified keywords
        _featureWeights[keyword] = (_featureWeights[keyword] ?? 1.0) * 0.95;
      } else {
        // Increase weight for correctly classified keywords
        _featureWeights[keyword] = (_featureWeights[keyword] ?? 1.0) * 1.05;
      }
    }
  }

  /// Start model update timer
  void _startModelUpdateTimer() {
    _modelUpdateTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      await _performModelUpdate();
    });
  }

  /// Perform periodic model updates
  Future<void> _performModelUpdate() async {
    if (_classificationHistory.length < 50) return;
    
    try {
      // Analyze recent classifications for pattern learning
      final recentClassifications = _classificationHistory.skip(max(0, _classificationHistory.length - 200));
      
      // Update keyword weights based on usage patterns
      final keywordFrequency = <String, int>{};
      for (final result in recentClassifications) {
        for (final keyword in result.detectedKeywords) {
          keywordFrequency[keyword] = (keywordFrequency[keyword] ?? 0) + 1;
        }
      }
      
      // Adjust weights for frequently used keywords
      for (final entry in keywordFrequency.entries) {
        if (entry.value > 10) { // Frequently used
          _featureWeights[entry.key] = (_featureWeights[entry.key] ?? 1.0) * 1.02;
        }
      }
      
      // Logging disabled;
    } catch (e) {
      // Logging disabled;
    }
  }
}
