import 'package:dartz/dartz.dart';
import 'package:emergency_mesh_network/core/error/failures.dart';
import 'package:emergency_mesh_network/features/network/domain/repositories/network_repository.dart';
import 'package:emergency_mesh_network/features/network/data/datasources/network_local_datasource.dart';

class NetworkRepositoryImpl implements NetworkRepository {
  final NetworkLocalDataSource localDataSource;
  
  NetworkRepositoryImpl(this.localDataSource);
  
  @override
  Future<Either<Failure, bool>> initializeNetwork() async {
    try {
      final result = await localDataSource.initializeNetwork();
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure('Ağ başlatılamadı: $e'));
    }
  }
  
  @override
  Future<Either<Failure, List<String>>> scanForDevices() async {
    try {
      final devices = await localDataSource.scanForDevices();
      return Right(devices);
    } catch (e) {
      return Left(NetworkFailure('Cihaz taraması başarısız: $e'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> connectToDevice(String deviceId) async {
    try {
      final result = await localDataSource.connectToDevice(deviceId);
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure('Cihaza bağlanılamadı: $e'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> disconnectFromDevice(String deviceId) async {
    try {
      final result = await localDataSource.disconnectFromDevice(deviceId);
      return Right(result);
    } catch (e) {
      return Left(NetworkFailure('Cihaz bağlantısı kesilemedi: $e'));
    }
  }
}