// Login Form State Model
import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class OtpSentSuccess extends LoginState {
  final String mobile;
  final String? otp;

  const OtpSentSuccess(this.mobile, [this.otp]);

  @override
  List<Object?> get props => [mobile, otp];
}

class LoginSuccess extends LoginState {
  final String role;
  final String token;
  final Map<String, dynamic>? payload;

  const LoginSuccess({
    required this.role,
    required this.token,
    this.payload,
  });

  @override
  List<Object?> get props => [role, token, payload];
}

class ForgotEmailSuccess extends LoginState {
  final String message;

  const ForgotEmailSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LoginFailure extends LoginState {
  final String message;

  const LoginFailure(this.message);

  @override
  List<Object?> get props => [message];
}
