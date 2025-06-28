import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergency_mesh_network/core/di/dependency_injection.dart';
import 'package:emergency_mesh_network/core/theme/app_theme.dart';
import 'package:emergency_mesh_network/core/routes/app_routes.dart';
import 'package:emergency_mesh_network/features/network/presentation/bloc/network_bloc.dart';
import 'package:emergency_mesh_network/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:emergency_mesh_network/features/emergency/presentation/bloc/emergency_bloc.dart';

class EmergencyMeshApp extends StatelessWidget {
  const EmergencyMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkBloc>(
          create: (context) => getIt<NetworkBloc>()..add(NetworkInitializeEvent()),
        ),
        BlocProvider<MessagingBloc>(
          create: (context) => getIt<MessagingBloc>(),
        ),
        BlocProvider<EmergencyBloc>(
          create: (context) => getIt<EmergencyBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Acil Durum Mesh Network',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: AppRoutes.splash,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}