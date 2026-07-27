// Data Source Layer - Remote Authentication DataSource
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> adminLogin(String email, String password);
  Future<Map<String, dynamic>> facultyLogin(String email, String password);
  Future<void> facultyForgotPassword(String email);
  Future<String?> parentSendOtp(String mobile);
  Future<Map<String, dynamic>> parentVerifyOtp(String mobile, String otp);
  Future<Map<String, dynamic>> parentSwitchChild(int studentId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final response = await apiClient.post('/api/auth/admin/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> facultyLogin(String email, String password) async {
    final response = await apiClient.post('/api/auth/faculty/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  @override
  Future<void> facultyForgotPassword(String email) async {
    await apiClient.post('/api/auth/faculty/forgot-password', data: {
      'email': email,
    });
  }

  @override
  Future<String?> parentSendOtp(String mobile) async {
    final response = await apiClient.post('/api/auth/parent/send-otp', data: {
      'mobile': mobile,
    });
    if (response.data != null && response.data['otp'] != null) {
      return response.data['otp'].toString();
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> parentVerifyOtp(String mobile, String otp) async {
    final response = await apiClient.post('/api/auth/parent/verify-otp', data: {
      'mobile': mobile,
      'otp': otp,
    });
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> parentSwitchChild(int studentId) async {
    final response = await apiClient.post('/api/auth/parent/switch-child', data: {
      'studentId': studentId,
    });
    return response.data;
  }
}
