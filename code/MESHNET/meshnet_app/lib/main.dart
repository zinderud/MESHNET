// lib/main.dart - MESHNET Bluetooth Mesh Uygulaması
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/bluetooth_mesh_manager.dart';

void main() {
  runApp(MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
