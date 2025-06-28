import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:emergency_mesh_network/core/routes/app_routes.dart';
import 'package:emergency_mesh_network/core/theme/app_theme.dart';
import 'package:emergency_mesh_network/features/network/presentation/bloc/network_bloc.dart';
import 'package:emergency_mesh_network/features/emergency/presentation/bloc/emergency_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acil Durum Mesh Network'),
        actions: [
          BlocBuilder<NetworkBloc, NetworkState>(
            builder: (context, state) {
              Color statusColor = AppTheme.disconnectedRed;
              IconData statusIcon = Icons.signal_cellular_off;
              
              if (state is NetworkConnectedState) {
                statusColor = AppTheme.connectedGreen;
                statusIcon = Icons.signal_cellular_4_bar;
              } else if (state is NetworkSearchingState) {
                statusColor = AppTheme.searchingYellow;
                statusIcon = Icons.search;
              }
              
              return IconButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.networkStatus),
                icon: Icon(statusIcon, color: statusColor),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Emergency Button
            BlocBuilder<EmergencyBloc, EmergencyState>(
              builder: (context, state) {
                bool isEmergencyActive = state is EmergencyActiveState;
                
                return Container(
                  width: double.infinity,
                  height: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isEmergencyActive) {
                        context.read<EmergencyBloc>().add(DeactivateEmergencyEvent());
                      } else {
                        Navigator.pushNamed(context, AppRoutes.emergency);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmergencyActive 
                          ? AppTheme.warningOrange 
                          : AppTheme.emergencyRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEmergencyActive ? Icons.stop : Icons.emergency,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEmergencyActive ? 'ACİL DURUMU DURDUR' : 'ACİL DURUM',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEmergencyActive 
                              ? 'Acil durum aktif - Durdurmak için dokunun'
                              : 'Acil durum bildirimi için dokunun',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Feature Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    context,
                    'Mesajlaşma',
                    Icons.message,
                    AppTheme.infoBlue,
                    () => Navigator.pushNamed(context, AppRoutes.messaging),
                  ),
                  _buildFeatureCard(
                    context,
                    'Ağ Durumu',
                    Icons.network_check,
                    AppTheme.safeGreen,
                    () => Navigator.pushNamed(context, AppRoutes.networkStatus),
                  ),
                  _buildFeatureCard(
                    context,
                    'Konum Paylaş',
                    Icons.location_on,
                    AppTheme.warningOrange,
                    () {
                      // TODO: Implement location sharing
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konum paylaşımı yakında...')),
                      );
                    },
                  ),
                  _buildFeatureCard(
                    context,
                    'Ayarlar',
                    Icons.settings,
                    Colors.grey,
                    () {
                      // TODO: Implement settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ayarlar yakında...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}