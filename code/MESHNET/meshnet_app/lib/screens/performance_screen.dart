// lib/screens/performance_screen.dart - Performans İzleme Ekranı
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:meshnet_app/services/optimization_manager.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/utils/logger.dart';

class PerformanceScreen extends StatefulWidget {
  @override
  _PerformanceScreenState createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> with TickerProviderStateMixin {
  final OptimizationManager _optimizationManager = OptimizationManager();
  Timer? _updateTimer;
  Map<String, dynamic> _performanceStats = {};
  List<String> _recommendations = [];
  bool _isOptimizing = false;
  
  late AnimationController _gaugeAnimationController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _gaugeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gaugeAnimationController, curve: Curves.easeInOut),
    );
    
    _startPerformanceMonitoring();
    _gaugeAnimationController.forward();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _gaugeAnimationController.dispose();
    super.dispose();
  }

  void _startPerformanceMonitoring() {
    _updateStats();
    _updateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _updateStats();
    });
  }

  void _updateStats() {
    setState(() {
      _performanceStats = _optimizationManager.getComprehensiveStats();
      _recommendations = _optimizationManager.getAllOptimizationRecommendations();
    });
  }

  Future<void> _performOptimization(OptimizationLevel level) async {
    setState(() {
      _isOptimizing = true;
    });

    try {
      await _optimizationManager.setOptimizationLevel(level);
      _showOptimizationResult(true, 'Optimizasyon başarıyla uygulandı');
    } catch (e) {
      _showOptimizationResult(false, 'Optimizasyon hatası: $e');
    } finally {
      setState(() {
        _isOptimizing = false;
      });
    }
  }

  void _showOptimizationResult(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Performans İzleme'),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _updateStats,
              ),
              IconButton(
                icon: Icon(Icons.auto_fix_high),
                onPressed: _isOptimizing
                    ? null
                    : () => _performOptimization(OptimizationLevel.moderate),
              ),
            ],
          ),
          body: _performanceStats.isEmpty
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStatsCard(),
                      SizedBox(height: 16),
                      _buildPerformanceGauges(),
                      SizedBox(height: 16),
                      _buildOptimizationControls(),
                      SizedBox(height: 16),
                      _buildDetailedStatsCard(),
                      SizedBox(height: 16),
                      _buildRecommendationsCard(),
                      SizedBox(height: 16),
                      _buildOptimizationHistoryCard(),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildQuickStatsCard() {
    final summary = _performanceStats['summary'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anlık Performans',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildQuickStatItem(
                  'Bellek',
                  '${(summary['memory_usage_mb'] ?? 0).toStringAsFixed(1)} MB',
                  Icons.memory,
                  _getMemoryColor(summary['memory_usage_mb'] ?? 0),
                ),
                _buildQuickStatItem(
                  'CPU',
                  '${(summary['cpu_usage_percent'] ?? 0).toStringAsFixed(1)}%',
                  Icons.speed,
                  _getCpuColor(summary['cpu_usage_percent'] ?? 0),
                ),
                _buildQuickStatItem(
                  'FPS',
                  '${(60000 / (summary['frame_time_ms'] ?? 16.67)).round()} FPS',
                  Icons.timeline,
                  _getFpsColor(summary['frame_time_ms'] ?? 16.67),
                ),
                _buildQuickStatItem(
                  'Batarya',
                  '${summary['battery_level'] ?? 100}%',
                  Icons.battery_full,
                  _getBatteryColor(summary['battery_level'] ?? 100),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGauges() {
    final summary = _performanceStats['summary'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performans Göstergeleri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AnimatedBuilder(
              animation: _gaugeAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    _buildGauge(
                      'Bellek Kullanımı',
                      (summary['memory_usage_mb'] ?? 0) / 1024, // Convert to GB for display
                      1.0, // Max 1GB for mobile
                      _getMemoryColor(summary['memory_usage_mb'] ?? 0),
                    ),
                    SizedBox(height: 16),
                    _buildGauge(
                      'CPU Kullanımı',
                      (summary['cpu_usage_percent'] ?? 0) / 100,
                      1.0,
                      _getCpuColor(summary['cpu_usage_percent'] ?? 0),
                    ),
                    SizedBox(height: 16),
                    _buildGauge(
                      'Frame Time',
                      ((summary['frame_time_ms'] ?? 16.67) - 16.67) / 16.67,
                      2.0, // Max 2x target frame time
                      _getFpsColor(summary['frame_time_ms'] ?? 16.67),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(String label, double value, double maxValue, Color color) {
    final normalizedValue = (value / maxValue).clamp(0.0, 1.0);
    final animatedValue = normalizedValue * _gaugeAnimation.value;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${(value * (label.contains('CPU') ? 100 : 1)).toStringAsFixed(1)}${label.contains('CPU') ? '%' : (label.contains('Bellek') ? 'GB' : 'ms')}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: animatedValue,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildOptimizationControls() {
    final currentLevel = _performanceStats['current_level']?.toString() ?? 'moderate';
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimizasyon Kontrolleri',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Mevcut Seviye: ${_getOptimizationLevelName(currentLevel)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildOptimizationButton(
                  'Performans',
                  OptimizationLevel.basic,
                  Icons.speed,
                  Colors.green,
                ),
                _buildOptimizationButton(
                  'Dengeli',
                  OptimizationLevel.moderate,
                  Icons.balance,
                  Colors.blue,
                ),
                _buildOptimizationButton(
                  'Batarya',
                  OptimizationLevel.aggressive,
                  Icons.battery_saver,
                  Colors.orange,
                ),
                _buildOptimizationButton(
                  'Acil Durum',
                  OptimizationLevel.emergency,
                  Icons.emergency,
                  Colors.red,
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOptimizing
                    ? null
                    : () => _optimizationManager.performManualOptimization(),
                icon: _isOptimizing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.auto_fix_high),
                label: Text(_isOptimizing ? 'Optimizasyon Yapılıyor...' : 'Manuel Optimizasyon'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationButton(
    String label,
    OptimizationLevel level,
    IconData icon,
    Color color,
  ) {
    final isSelected = _performanceStats['current_level']?.toString().contains(level.toString().split('.').last) ?? false;
    
    return ElevatedButton.icon(
      onPressed: _isOptimizing ? null : () => _performOptimization(level),
      icon: Icon(icon, size: 18),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.2),
        foregroundColor: isSelected ? Colors.white : color,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDetailedStatsCard() {
    final detailedStats = _performanceStats['detailed_stats'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detaylı İstatistikler',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...detailedStats.entries.map((entry) {
              if (entry.value is Map) {
                return ExpansionTile(
                  title: Text(_getStatCategoryName(entry.key)),
                  children: [
                    ...((entry.value as Map).entries.map((subEntry) {
                      return ListTile(
                        dense: true,
                        title: Text(_getStatDisplayName(subEntry.key)),
                        trailing: Text(
                          _formatStatValue(subEntry.value),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList()),
                  ],
                );
              }
              return Container();
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Optimizasyon Önerileri',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_recommendations.isEmpty)
              Text(
                'Harika! Şu anda optimizasyon önerisi bulunmuyor.',
                style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
              )
            else
              ..._recommendations.map((recommendation) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_right, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationHistoryCard() {
    final history = _performanceStats['optimization_history'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimizasyon Geçmişi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (history.isEmpty)
              Text(
                'Henüz optimizasyon geçmişi bulunmuyor.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              ...history.entries.take(5).map((entry) {
                final result = entry.value as Map<String, dynamic>;
                final timestamp = DateTime.parse(entry.key);
                final success = result['success'] ?? false;
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: success ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  title: Text(
                    _getOptimizationLevelName(result['level']?.toString() ?? ''),
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: success
                      ? null
                      : Icon(Icons.warning, color: Colors.amber, size: 16),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getMemoryColor(double memoryMB) {
    if (memoryMB > 800) return Colors.red;
    if (memoryMB > 500) return Colors.orange;
    if (memoryMB > 300) return Colors.yellow;
    return Colors.green;
  }

  Color _getCpuColor(double cpuPercent) {
    if (cpuPercent > 80) return Colors.red;
    if (cpuPercent > 60) return Colors.orange;
    if (cpuPercent > 40) return Colors.yellow;
    return Colors.green;
  }

  Color _getFpsColor(double frameTime) {
    if (frameTime > 33) return Colors.red; // < 30 FPS
    if (frameTime > 20) return Colors.orange; // < 50 FPS
    if (frameTime > 16.67) return Colors.yellow; // < 60 FPS
    return Colors.green; // >= 60 FPS
  }

  Color _getBatteryColor(int batteryLevel) {
    if (batteryLevel < 15) return Colors.red;
    if (batteryLevel < 30) return Colors.orange;
    if (batteryLevel < 50) return Colors.yellow;
    return Colors.green;
  }

  String _getOptimizationLevelName(String level) {
    switch (level.toLowerCase()) {
      case 'disabled': return 'Devre Dışı';
      case 'basic': return 'Temel';
      case 'moderate': return 'Orta';
      case 'aggressive': return 'Agresif';
      case 'emergency': return 'Acil Durum';
      default: return level;
    }
  }

  String _getStatCategoryName(String category) {
    switch (category) {
      case 'performance': return 'Performans';
      case 'memory': return 'Bellek';
      case 'cpu': return 'İşlemci';
      case 'network': return 'Ağ';
      case 'battery': return 'Batarya';
      default: return category;
    }
  }

  String _getStatDisplayName(String stat) {
    // Convert snake_case to readable format
    return stat.replaceAll('_', ' ').split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatStatValue(dynamic value) {
    if (value is double) {
      return value.toStringAsFixed(2);
    } else if (value is int) {
      return value.toString();
    } else if (value is bool) {
      return value ? 'Evet' : 'Hayır';
    }
    return value?.toString() ?? 'N/A';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}
