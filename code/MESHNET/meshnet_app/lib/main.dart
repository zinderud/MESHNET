// lib/main.dart - Emergency Mesh Network App with Advanced Features
import 'package:flutter/material.dart';
import 'package:meshnet_app/services/optimization_manager.dart';
import 'package:meshnet_app/services/blockchain/blockchain_manager.dart';
import 'package:meshnet_app/services/p2p/p2p_network_manager.dart';
import 'package:meshnet_app/services/security/advanced_security_service.dart';
import 'package:meshnet_app/providers/settings_provider.dart';
import 'package:meshnet_app/screens/chat_screen.dart';
import 'package:meshnet_app/screens/emergency_screen.dart';
import 'package:meshnet_app/screens/settings_screen.dart';
import 'package:meshnet_app/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger('Main');
  logger.info('Starting Emergency Mesh Network App with Advanced Features');
  
  // Initialize core services in sequence
  try {
    // 1. Initialize optimization services
    logger.info('Initializing optimization services...');
    await OptimizationManager.instance.initialize();
    
    // 2. Initialize security service
    logger.info('Initializing security service...');
    await AdvancedSecurityService.instance.initialize();
    
    // 3. Initialize blockchain
    logger.info('Initializing blockchain...');
    await BlockchainManager.instance.initialize();
    
    // 4. Initialize P2P network
    logger.info('Initializing P2P network...');
    await P2PNetworkManager.instance.initialize();
    
    logger.info('All services initialized successfully');
  } catch (e) {
    logger.severe('Failed to initialize services', e);
  }
  
  runApp(const MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  const MeshNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Mesh Network',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final Logger _logger = Logger('MainScreen');

  final List<Widget> _screens = [
    const ChatScreen(),
    const EmergencyScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _logger.info('Main screen initialized');
    _checkServiceStatus();
  }

  void _checkServiceStatus() {
    // Check all services are running
    final optimizationStatus = OptimizationManager.instance.isInitialized;
    final securityStatus = AdvancedSecurityService.instance.isInitialized;
    final blockchainStatus = BlockchainManager.instance.isInitialized;
    final p2pStatus = P2PNetworkManager.instance.isInitialized;
    
    _logger.info('Service Status - Optimization: $optimizationStatus, Security: $securityStatus, Blockchain: $blockchainStatus, P2P: $p2pStatus');
    
    if (!optimizationStatus || !securityStatus || !blockchainStatus || !p2pStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some services are not running properly'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 ? FloatingActionButton(
        onPressed: () {
          // Quick emergency alert
          _sendQuickEmergencyAlert();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.warning, color: Colors.white),
      ) : null,
    );
  }

  void _sendQuickEmergencyAlert() async {
    try {
      final success = await P2PNetworkManager.instance.sendEmergencyAlert(
        message: 'Quick emergency alert sent from mobile device',
        location: {
          'latitude': 0.0,
          'longitude': 0.0,
          'accuracy': 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        priority: 1,
        broadcast: true,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send emergency alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.severe('Failed to send quick emergency alert', e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending emergency alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
