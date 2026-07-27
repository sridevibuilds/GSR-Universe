// Data Layer - Authentication Repository Implementation
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../../core/errors/exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<String> adminLogin(String email, String password) async {
    try {
      final res = await remoteDataSource.adminLogin(email, password);
      final token = res['token']?.toString() ?? '';
      
      // Save session credentials
      await secureStorage.saveToken(token);
      return token;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException("Unable to contact login services.");
    }
  }

  @override
  Future<String> facultyLogin(String email, String password) async {
    try {
      final res = await remoteDataSource.facultyLogin(email, password);
      final token = res['token']?.toString() ?? '';
      
      // Save session credentials
      await secureStorage.saveToken(token);
      return token;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException("Unable to contact login services.");
    }
  }

  @override
  Future<void> facultyForgotPassword(String email) async {
    try {
      await remoteDataSource.facultyForgotPassword(email);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException("Unable to dispatch password reset request.");
    }
  }

  @override
  Future<String?> parentSendOtp(String mobile) async {
    try {
      return await remoteDataSource.parentSendOtp(mobile);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException("Failed to dispatch mobile verification OTP.");
    }
  }

  @override
  Future<Map<String, dynamic>> parentVerifyOtp(String mobile, String otp) async {
    try {
      final res = await remoteDataSource.parentVerifyOtp(mobile, otp);
      final token = res['token']?.toString() ?? '';
      
      // Save session credentials
      await secureStorage.saveToken(token);
      return res;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException("Failed to verify mobile login credentials.");
    }
  }

  @override
  Future<String> parentSwitchChild(int studentId) async {
    try {
      final res = await remoteDataSource.parentSwitchChild(studentId);
      final token = res['token']?.toString() ?? '';
      
      // Update session credentials
      await secureStorage.saveToken(token);
      return token;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException("Failed to load selected child details.");
    }
  }
}
