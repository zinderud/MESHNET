import 'package:dartz/dartz.dart';
import 'package:emergency_mesh_network/core/error/failures.dart';

abstract class NetworkRepository {
  Future<Either<Failure, bool>> initializeNetwork();
  Future<Either<Failure, List<String>>> scanForDevices();
  Future<Either<Failure, bool>> connectToDevice(String deviceId);
  Future<Either<Failure, bool>> disconnectFromDevice(String deviceId);
}