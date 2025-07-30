// lib/main.dart - MESHNET Bluetooth Mesh Uygulaması
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'screens/emergency_location_screen.dart';
import 'screens/wifi_direct_screen.dart';
import 'screens/sdr_screen.dart';
import 'screens/ham_radio_screen.dart';
import 'screens/emergency_screen.dart';
import 'services/bluetooth_mesh_manager.dart';
import 'services/location_manager.dart';
import 'services/wifi_direct_manager.dart';
import 'services/sdr_manager.dart';
import 'services/ham_radio_manager.dart';
import 'services/emergency_manager.dart';

void main() {
  runApp(MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      child: Consumer<EmergencyManager>(
        builder: (context, emergencyManager, child) {
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
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
            ),
            home: MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    ChatScreen(),
    EmergencyLocationScreen(),
    WiFiDirectScreen(),
    SDRScreen(),
    EmergencyScreen(),
  ];
  
  final List<String> _titles = [
    'MESHNET Chat',
    'Acil Durum GPS',
    'WiFi Direct',
    'RF & SDR',
    'Emergency Control',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
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
        ],
      ),
    );
  }
}
