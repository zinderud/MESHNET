// lib/main.dart - BitChat'teki BitChatApp.swift'ten çevrildi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/bluetooth_manager.dart';
import 'services/mesh_network_manager.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
        ChangeNotifierProvider(create: (_) => MeshNetworkManager()),
      ],
      child: MaterialApp(
        title: 'MESHNET',
        theme: ThemeData.dark().copyWith(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
          ),
        ),
        home: ChatScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
