// lib/main.dart - MESHNET Bluetooth Mesh Uygulaması
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'screens/emergency_location_screen.dart';
import 'screens/wifi_direct_screen.dart';
import 'services/bluetooth_mesh_manager.dart';
import 'services/location_manager.dart';
import 'services/wifi_direct_manager.dart';

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
      ],
      child: MaterialApp(
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
  ];
  
  final List<String> _titles = [
    'MESHNET Chat',
    'Acil Durum GPS',
    'WiFi Direct',
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
        ],
      ),
    );
  }
}
