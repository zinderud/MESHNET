import 'package:get_it/get_it.dart';
import 'package:emergency_mesh_network/features/network/data/datasources/network_local_datasource.dart';
import 'package:emergency_mesh_network/features/network/data/repositories/network_repository_impl.dart';
import 'package:emergency_mesh_network/features/network/domain/repositories/network_repository.dart';
import 'package:emergency_mesh_network/features/network/domain/usecases/initialize_network.dart';
import 'package:emergency_mesh_network/features/network/presentation/bloc/network_bloc.dart';
import 'package:emergency_mesh_network/features/messaging/data/datasources/messaging_local_datasource.dart';
import 'package:emergency_mesh_network/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:emergency_mesh_network/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:emergency_mesh_network/features/messaging/domain/usecases/send_message.dart';
import 'package:emergency_mesh_network/features/messaging/presentation/bloc/messaging_bloc.dart';
import 'package:emergency_mesh_network/features/emergency/data/datasources/emergency_local_datasource.dart';
import 'package:emergency_mesh_network/features/emergency/data/repositories/emergency_repository_impl.dart';
import 'package:emergency_mesh_network/features/emergency/domain/repositories/emergency_repository.dart';
import 'package:emergency_mesh_network/features/emergency/domain/usecases/trigger_emergency.dart';
import 'package:emergency_mesh_network/features/emergency/presentation/bloc/emergency_bloc.dart';

final getIt = GetIt.instance;

class DependencyInjection {
  static Future<void> init() async {
    // Data Sources
    getIt.registerLazySingleton<NetworkLocalDataSource>(
      () => NetworkLocalDataSourceImpl(),
    );
    getIt.registerLazySingleton<MessagingLocalDataSource>(
      () => MessagingLocalDataSourceImpl(),
    );
    getIt.registerLazySingleton<EmergencyLocalDataSource>(
      () => EmergencyLocalDataSourceImpl(),
    );

    // Repositories
    getIt.registerLazySingleton<NetworkRepository>(
      () => NetworkRepositoryImpl(getIt()),
    );
    getIt.registerLazySingleton<MessagingRepository>(
      () => MessagingRepositoryImpl(getIt()),
    );
    getIt.registerLazySingleton<EmergencyRepository>(
      () => EmergencyRepositoryImpl(getIt()),
    );

    // Use Cases
    getIt.registerLazySingleton(() => InitializeNetwork(getIt()));
    getIt.registerLazySingleton(() => SendMessage(getIt()));
    getIt.registerLazySingleton(() => TriggerEmergency(getIt()));

    // Blocs
    getIt.registerFactory(() => NetworkBloc(getIt()));
    getIt.registerFactory(() => MessagingBloc(getIt()));
    getIt.registerFactory(() => EmergencyBloc(getIt()));
  }
}