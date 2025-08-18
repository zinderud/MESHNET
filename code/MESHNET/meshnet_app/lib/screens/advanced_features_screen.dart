// lib/screens/advanced_features_screen.dart - Advanced Features Dashboard
import 'package:flutter/material.dart';
import 'package:meshnet_app/services/blockchain/blockchain_manager.dart';
import 'package:meshnet_app/services/p2p/p2p_network_manager.dart';
import 'package:meshnet_app/services/security/advanced_security_service.dart';
import 'package:meshnet_app/services/optimization_manager.dart';
import 'package:meshnet_app/utils/logger.dart';

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({super.key});

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final Logger _logger = Logger('AdvancedFeaturesScreen');
  
  Map<String, dynamic> _blockchainStats = {};
  Map<String, dynamic> _p2pStats = {};
  Map<String, dynamic> _securityStats = {};
  Map<String, dynamic> _optimizationStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  void _loadStatistics() {
    setState(() {
      _blockchainStats = BlockchainManager.instance.getStatistics();
      _p2pStats = P2PNetworkManager.instance.getNetworkStatistics();
      _securityStats = AdvancedSecurityService.instance.getSecurityStatistics();
      _optimizationStats = OptimizationManager.instance.getStatistics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Features'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStatistics();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBlockchainSection(),
            const SizedBox(height: 16),
            _buildP2PNetworkSection(),
            const SizedBox(height: 16),
            _buildSecuritySection(),
            const SizedBox(height: 16),
            _buildOptimizationSection(),
            const SizedBox(height: 16),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockchainSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Blockchain',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  _blockchainStats['initialized'] == true 
                    ? Icons.check_circle 
                    : Icons.error,
                  color: _blockchainStats['initialized'] == true 
                    ? Colors.green 
                    : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_blockchainStats['initialized'] == true) ...[
              _buildStatRow('Blocks', _blockchainStats['blockCount']?.toString() ?? '0'),
              _buildStatRow('Transactions', _blockchainStats['totalTransactions']?.toString() ?? '0'),
              _buildStatRow('Pending', _blockchainStats['pendingTransactions']?.toString() ?? '0'),
              _buildStatRow('Node Balance', _blockchainStats['nodeBalance']?.toString() ?? '0.0'),
              _buildStatRow('Chain Valid', _blockchainStats['isChainValid']?.toString() ?? 'false'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _forceMining,
                child: const Text('Force Mining'),
              ),
            ] else ...[
              const Text('Blockchain not initialized'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializeBlockchain,
                child: const Text('Initialize Blockchain'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildP2PNetworkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.device_hub, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'P2P Network',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  _p2pStats['initialized'] == true 
                    ? Icons.check_circle 
                    : Icons.error,
                  color: _p2pStats['initialized'] == true 
                    ? Colors.green 
                    : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_p2pStats['initialized'] == true) ...[
              _buildStatRow('Connected Peers', P2PNetworkManager.instance.connectedPeers.length.toString()),
              _buildStatRow('Trusted Peers', P2PNetworkManager.instance.trustedPeers.length.toString()),
              _buildStatRow('Emergency Alerts', _p2pStats['emergency_alerts_sent']?.toString() ?? '0'),
              _buildStatRow('Chat Messages', _p2pStats['chat_messages_sent']?.toString() ?? '0'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _emergencyDiscovery,
                      child: const Text('Emergency Discovery'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _syncBlockchain,
                      child: const Text('Sync Blockchain'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('P2P Network not initialized'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializeP2P,
                child: const Text('Initialize P2P'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Security',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  _securityStats['initialized'] == true 
                    ? Icons.check_circle 
                    : Icons.error,
                  color: _securityStats['initialized'] == true 
                    ? Colors.green 
                    : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_securityStats['initialized'] == true) ...[
              _buildStatRow('Security Level', _securityStats['securityLevel']?.toString() ?? 'unknown'),
              _buildStatRow('Node Fingerprint', _truncateFingerprint(_securityStats['nodeFingerprint']?.toString())),
              _buildStatRow('Shared Secrets', _securityStats['activeSharedSecrets']?.toString() ?? '0'),
              _buildStatRow('Session Keys', _securityStats['activeSessionKeys']?.toString() ?? '0'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _rotateKeys,
                      child: const Text('Rotate Keys'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _setEmergencySecurity,
                      child: const Text('Emergency Mode'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Text('Security service not initialized'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _initializeSecurity,
                child: const Text('Initialize Security'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Performance Optimization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  _optimizationStats['initialized'] == true 
                    ? Icons.check_circle 
                    : Icons.error,
                  color: _optimizationStats['initialized'] == true 
                    ? Colors.green 
                    : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_optimizationStats['initialized'] == true) ...[
              _buildStatRow('Optimization Level', _optimizationStats['currentLevel']?.toString() ?? 'unknown'),
              _buildStatRow('Memory Usage', '${_optimizationStats['memoryUsage'] ?? 0}%'),
              _buildStatRow('CPU Usage', '${_optimizationStats['cpuUsage'] ?? 0}%'),
              _buildStatRow('Battery Level', '${_optimizationStats['batteryLevel'] ?? 0}%'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _optimizePerformance,
                child: const Text('Optimize Now'),
              ),
            ] else ...[
              const Text('Optimization service not initialized'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.build, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'System Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _initializeAllServices,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Initialize All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shutdownAllServices,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Shutdown All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendTestEmergency,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Send Test Emergency Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value ?? 'N/A', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String? _truncateFingerprint(String? fingerprint) {
    if (fingerprint == null || fingerprint.length <= 16) return fingerprint;
    return '${fingerprint.substring(0, 8)}...${fingerprint.substring(fingerprint.length - 8)}';
  }

  // Action methods
  void _initializeBlockchain() async {
    try {
      final success = await BlockchainManager.instance.initialize();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blockchain initialized successfully')),
        );
        _loadStatistics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize blockchain')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _initializeP2P() async {
    try {
      final success = await P2PNetworkManager.instance.initialize();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('P2P network initialized successfully')),
        );
        _loadStatistics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize P2P network')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _initializeSecurity() async {
    try {
      final success = await AdvancedSecurityService.instance.initialize();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Security service initialized successfully')),
        );
        _loadStatistics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize security service')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _forceMining() async {
    try {
      final success = await BlockchainManager.instance.forceMine();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mining completed successfully')),
        );
        _loadStatistics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to mine')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _emergencyDiscovery() async {
    try {
      final success = await P2PNetworkManager.instance.emergencyPeerDiscovery();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency discovery initiated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate emergency discovery')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _syncBlockchain() async {
    try {
      // Sync with first available peer
      final peers = P2PNetworkManager.instance.connectedPeers;
      if (peers.isNotEmpty) {
        final success = await P2PNetworkManager.instance.requestBlockchainSync(peers.first.nodeId);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Blockchain sync requested')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to request blockchain sync')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No peers available for sync')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _rotateKeys() async {
    try {
      final success = await AdvancedSecurityService.instance.rotateKeys();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keys rotated successfully')),
        );
        _loadStatistics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to rotate keys')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }

  void _setEmergencySecurity() async {
    try {
      await AdvancedSecurityService.instance.setSecurityLevel(SecurityLevel.emergency);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency security mode activated')),
      );
      _loadStatistics();
    } catch (e) {
      // Logging disabled;
    }
  }

  void _optimizePerformance() async {
    try {
      await OptimizationManager.instance.optimizeNow();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Performance optimization completed')),
      );
      _loadStatistics();
    } catch (e) {
      // Logging disabled;
    }
  }

  void _initializeAllServices() async {
    try {
      await AdvancedSecurityService.instance.initialize();
      await BlockchainManager.instance.initialize();
      await P2PNetworkManager.instance.initialize();
      await OptimizationManager.instance.initialize();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All services initialized')),
      );
      _loadStatistics();
    } catch (e) {
      // Logging disabled;
    }
  }

  void _shutdownAllServices() async {
    try {
      await P2PNetworkManager.instance.shutdown();
      await BlockchainManager.instance.shutdown();
      await AdvancedSecurityService.instance.shutdown();
      await OptimizationManager.instance.shutdown();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All services shut down')),
      );
      _loadStatistics();
    } catch (e) {
      // Logging disabled;
    }
  }

  void _sendTestEmergency() async {
    try {
      final success = await P2PNetworkManager.instance.sendEmergencyAlert(
        message: 'Test emergency alert from advanced features dashboard',
        location: {
          'latitude': 41.0082,
          'longitude': 28.9784,
          'accuracy': 10.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: 3,
        broadcast: true,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test emergency alert sent')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send test emergency alert')),
        );
      }
    } catch (e) {
      // Logging disabled;
    }
  }
}
