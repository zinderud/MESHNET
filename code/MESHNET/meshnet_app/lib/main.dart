// lib/main.dart - MESHNET Bluetooth Mesh Uygulaması
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'screens/network_status_screen.dart';
import 'screens/emergency_location_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/performance_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/network_provider.dart';
import 'providers/location_provider.dart';
import 'providers/emergency_provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/wifi_direct_provider.dart';
import 'providers/sdr_provider.dart';
import 'services/optimization_manager.dart';
import 'services/performance_monitor.dart';
import 'services/memory_optimizer.dart';
import 'services/cpu_optimizer.dart';
import 'services/network_optimizer.dart';
import 'services/battery_optimizer.dart';
import 'utils/logger.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize optimization services
  await _initializeOptimizationServices();
  
  runApp(MeshNetApp());
}

Future<void> _initializeOptimizationServices() async {
  final logger = Logger('OptimizationServices');
  try {
    logger.info('Initializing optimization services...');
    
    // Initialize the optimization manager which handles all performance services
    final optimizationManager = OptimizationManager();
    await optimizationManager.initialize();
    
    // Set initial optimization level to moderate
    await optimizationManager.setOptimizationLevel(OptimizationLevel.moderate);
    
    logger.info('Optimization services initialized successfully');
  } catch (e) {
    logger.severe('Failed to initialize optimization services', e);
  }
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Settings Provider
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        
        // Core Service Managers
        ChangeNotifierProvider(create: (_) {
          final manager = BluetoothMeshManager();
          manager.initialize(); // Auto-initialize
          return manager;
        }),
        ChangeNotifierProvider(create: (_) {
          final manager = LocationManager();
          manager.initialize(); // Auto-initialize
          return manager;
        }),
        ChangeNotifierProvider(create: (_) {
          final manager = WiFiDirectManager();
          manager.initialize(); // Auto-initialize
          return manager;
        }),
        ChangeNotifierProvider(create: (_) {
          final manager = SDRManager();
          manager.initialize(); // Auto-initialize
          return manager;
        }),
        ChangeNotifierProvider(create: (_) {
          final manager = HamRadioManager();
          manager.initialize(); // Auto-initialize
          return manager;
        }),
        ChangeNotifierProvider(create: (_) {
          final manager = EmergencyManager();
          manager.initialize(); // Auto-initialize
          return manager;
        }),
      ],
      child: Consumer2<EmergencyManager, SettingsProvider>(
        builder: (context, emergencyManager, settingsProvider, child) {
          // Connect other providers to emergency manager
          final bluetoothManager = Provider.of<BluetoothMeshManager>(context, listen: false);
          final locationManager = Provider.of<LocationManager>(context, listen: false);
          final wifiManager = Provider.of<WiFiDirectManager>(context, listen: false);
          final sdrManager = Provider.of<SDRManager>(context, listen: false);
          final hamRadioManager = Provider.of<HamRadioManager>(context, listen: false);
          
          // Set manager references for emergency coordination
          emergencyManager.setManagers(
            bluetoothManager: bluetoothManager,
            locationManager: locationManager,
            wifiManager: wifiManager,
            sdrManager: sdrManager,
            hamRadioManager: hamRadioManager,
          );
          
          return MaterialApp(
            title: 'MESHNET - Emergency Mesh Network',
            theme: _buildTheme(settingsProvider, false),
            darkTheme: _buildTheme(settingsProvider, true),
            themeMode: settingsProvider.themeMode,
            home: MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(SettingsProvider settings, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: settings.primaryColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: settings.fontFamily,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(settings.borderRadius),
          ),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(settings.borderRadius),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  OptimizationManager? _optimizationManager;
  
  final List<Widget> _screens = [
    HomeScreen(),
    ChatScreen(),
    EmergencyLocationScreen(),
    WiFiDirectScreen(),
    SDRScreen(),
    EmergencyScreen(),
    SettingsScreen(),
  ];
  
  final List<String> _titles = [
    'Ana Sayfa',
    'MESHNET Chat',
    'Acil Durum GPS',
    'WiFi Direct',
    'RF & SDR',
    'Emergency Control',
    'Ayarlar',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _optimizationManager = OptimizationManager();
    _initializePerformanceOptimizations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializePerformanceOptimizations() {
    // Schedule background optimizations
    _optimizationManager?.scheduleBackgroundTask(
      id: 'routine_optimization',
      task: () => _optimizationManager?.performManualOptimization(),
      interval: Duration(minutes: 5),
      priority: 3,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background - optimize for battery
        _optimizationManager?.optimizeForBattery();
        break;
      case AppLifecycleState.resumed:
        // App is active - optimize for performance
        _optimizationManager?.optimizeForPerformance();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _optimizationManager?.dispose();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            selectedItemColor: settings.primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emergency_share),
                label: 'Acil GPS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wifi),
                label: 'WiFi Direct',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.radio),
                label: 'RF & SDR',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emergency),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Ayarlar',
              ),
            ],
          );
        },
      ),
    );
  }
}
