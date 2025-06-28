import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergency_mesh_network/core/app.dart';
import 'package:emergency_mesh_network/core/di/dependency_injection.dart';
import 'package:emergency_mesh_network/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger
  AppLogger.init();
  
  // Initialize dependencies
  await DependencyInjection.init();
  
  // Run app
  runApp(const EmergencyMeshApp());
}