// Core Secure Storage Utility
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage(this._storage);

  static const String _tokenKey = 'GSR_JWT_TOKEN';

  /// Persist the authentication token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve the active token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete the token on logout or session expiry
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
