import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String? adminName;
  final String? adminRole;

  const Authenticated({this.adminName, this.adminRole});

  @override
  List<Object?> get props => [adminName, adminRole];
}

class Unauthenticated extends AuthState {
  final String? savedUsername;
  final String? errorMessage;
  final int lockoutSeconds;

  const Unauthenticated({
    this.savedUsername,
    this.errorMessage,
    this.lockoutSeconds = 0,
  });

  @override
  List<Object?> get props => [savedUsername, errorMessage, lockoutSeconds];
}

class AuthExpired extends AuthState {}
