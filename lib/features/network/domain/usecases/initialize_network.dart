import 'package:dartz/dartz.dart';
import 'package:emergency_mesh_network/core/error/failures.dart';
import 'package:emergency_mesh_network/features/network/domain/repositories/network_repository.dart';

class InitializeNetwork {
  final NetworkRepository repository;
  
  InitializeNetwork(this.repository);
  
  Future<Either<Failure, bool>> call() async {
    return await repository.initializeNetwork();
  }
}