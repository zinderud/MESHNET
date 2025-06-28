import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class MessagingFailure extends Failure {
  const MessagingFailure(String message) : super(message);
}

class EmergencyFailure extends Failure {
  const EmergencyFailure(String message) : super(message);
}