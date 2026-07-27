// Auth Cubit Manager for session checks & authentication flow
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/security/secure_storage.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SecureStorage _secureStorage;

  AuthCubit(this._secureStorage) : super(AuthInitial());

  /// Check secure storage on boot to verify session JWT token
  Future<void> checkAuthStatus() async {
    try {
      final token = await _secureStorage.getToken();
      
      if (token == null || token.isEmpty) {
        emit(AuthUnauthenticated());
        return;
      }

      // Check JWT validation expiration bounds
      if (JwtDecoder.isExpired(token)) {
        await _secureStorage.deleteToken();
        emit(AuthUnauthenticated());
        return;
      }

      // Decode payload details to resolve user role
      final Map<String, dynamic> payload = JwtDecoder.decode(token);
      final String role = (payload['role'] ?? '').toString().toUpperCase();

      emit(AuthAuthenticated(
        token: token,
        role: role,
        payload: payload,
      ));
    } catch (_) {
      // Fallback clean logout state on structural decoding failure
      await _secureStorage.deleteToken();
      emit(AuthUnauthenticated());
    }
  }

  /// Perform secure logout
  Future<void> logout() async {
    emit(AuthLoading());
    await _secureStorage.deleteToken();
    emit(AuthUnauthenticated());
  }

  /// Force authenticate session after login
  void authenticate(String token) {
    try {
      final Map<String, dynamic> payload = JwtDecoder.decode(token);
      final String role = (payload['role'] ?? '').toString().toUpperCase();
      emit(AuthAuthenticated(token: token, role: role, payload: payload));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }
}
