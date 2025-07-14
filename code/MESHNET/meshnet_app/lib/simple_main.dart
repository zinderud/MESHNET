// lib/simple_main.dart - Basit MESHNET Uygulaması
import 'package:flutter/material.dart';
import 'screens/simple_chat_screen.dart';

void main() {
  runApp(MeshNetApp());
}

class MeshNetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MESHNET',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SimpleChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
