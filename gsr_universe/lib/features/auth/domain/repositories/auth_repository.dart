// Domain Layer - Authentication Repository Interface
abstract class AuthRepository {
  Future<String> adminLogin(String email, String password);
  Future<String> facultyLogin(String email, String password);
  Future<void> facultyForgotPassword(String email);
  Future<void> parentSendOtp(String mobile);
  Future<Map<String, dynamic>> parentVerifyOtp(String mobile, String otp);
  Future<String> parentSwitchChild(int studentId);
}
