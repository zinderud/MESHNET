import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:emergency_mesh_network/features/network/domain/usecases/initialize_network.dart';
import 'package:emergency_mesh_network/core/utils/logger.dart';

// Events
abstract class NetworkEvent extends Equatable {
  const NetworkEvent();
  
  @override
  List<Object> get props => [];
}

class NetworkInitializeEvent extends NetworkEvent {}
class NetworkSearchEvent extends NetworkEvent {}
class NetworkConnectEvent extends NetworkEvent {
  final String deviceId;
  const NetworkConnectEvent(this.deviceId);
  
  @override
  List<Object> get props => [deviceId];
}
class NetworkDisconnectEvent extends NetworkEvent {}

// States
abstract class NetworkState extends Equatable {
  const NetworkState();
  
  @override
  List<Object> get props => [];
}

class NetworkInitialState extends NetworkState {}
class NetworkSearchingState extends NetworkState {}
class NetworkConnectedState extends NetworkState {
  final List<String> connectedDevices;
  const NetworkConnectedState(this.connectedDevices);
  
  @override
  List<Object> get props => [connectedDevices];
}
class NetworkDisconnectedState extends NetworkState {}
class NetworkErrorState extends NetworkState {
  final String message;
  const NetworkErrorState(this.message);
  
  @override
  List<Object> get props => [message];
}

// Bloc
class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final InitializeNetwork _initializeNetwork;
  
  NetworkBloc(this._initializeNetwork) : super(NetworkInitialState()) {
    on<NetworkInitializeEvent>(_onInitialize);
    on<NetworkSearchEvent>(_onSearch);
    on<NetworkConnectEvent>(_onConnect);
    on<NetworkDisconnectEvent>(_onDisconnect);
  }
  
  Future<void> _onInitialize(
    NetworkInitializeEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      AppLogger.info('Network initialization started');
      emit(NetworkSearchingState());
      
      final result = await _initializeNetwork();
      
      result.fold(
        (failure) {
          AppLogger.error('Network initialization failed: ${failure.message}');
          emit(NetworkErrorState(failure.message));
        },
        (success) {
          AppLogger.info('Network initialized successfully');
          emit(NetworkConnectedState([]));
        },
      );
    } catch (e) {
      AppLogger.error('Network initialization error', e);
      emit(NetworkErrorState('Ağ başlatılamadı: $e'));
    }
  }
  
  Future<void> _onSearch(
    NetworkSearchEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(NetworkSearchingState());
    // TODO: Implement device search
    await Future.delayed(const Duration(seconds: 2));
    emit(NetworkConnectedState(['device1', 'device2']));
  }
  
  Future<void> _onConnect(
    NetworkConnectEvent event,
    Emitter<NetworkState> emit,
  ) async {
    // TODO: Implement device connection
    AppLogger.info('Connecting to device: ${event.deviceId}');
  }
  
  Future<void> _onDisconnect(
    NetworkDisconnectEvent event,
    Emitter<NetworkState> emit,
  ) async {
    emit(NetworkDisconnectedState());
    AppLogger.info('Network disconnected');
  }
}