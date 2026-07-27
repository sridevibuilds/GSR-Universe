// Auth State definition for bloc/cubit
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final String role;
  final Map<String, dynamic> payload;

  const AuthAuthenticated({
    required this.token,
    required this.role,
    required this.payload,
  });

  @override
  List<Object?> get props => [token, role, payload];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
