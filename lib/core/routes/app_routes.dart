import 'package:flutter/material.dart';
import 'package:emergency_mesh_network/features/splash/presentation/pages/splash_page.dart';
import 'package:emergency_mesh_network/features/home/presentation/pages/home_page.dart';
import 'package:emergency_mesh_network/features/messaging/presentation/pages/messaging_page.dart';
import 'package:emergency_mesh_network/features/network/presentation/pages/network_status_page.dart';
import 'package:emergency_mesh_network/features/emergency/presentation/pages/emergency_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String messaging = '/messaging';
  static const String networkStatus = '/network-status';
  static const String emergency = '/emergency';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case messaging:
        return MaterialPageRoute(builder: (_) => const MessagingPage());
      case networkStatus:
        return MaterialPageRoute(builder: (_) => const NetworkStatusPage());
      case emergency:
        return MaterialPageRoute(builder: (_) => const EmergencyPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Sayfa bulunamadı: ${settings.name}'),
            ),
          ),
        );
    }
  }
}