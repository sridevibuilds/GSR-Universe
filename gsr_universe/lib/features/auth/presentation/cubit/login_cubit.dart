// Presentation Controller Layer - Login Form Cubit State Manager
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_state.dart';
import '../../../../core/errors/exceptions.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit(this.authRepository) : super(LoginInitial());

  /// Log in as ERP Admin
  Future<void> loginAdmin(String email, String password) async {
    emit(LoginLoading());
    try {
      final String token = await authRepository.adminLogin(email, password);
      emit(LoginSuccess(role: 'ADMIN', token: token));
    } on ServerException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("Connection failure. Check if server is running."));
    }
  }

  /// Log in as Faculty
  Future<void> loginFaculty(String email, String password) async {
    emit(LoginLoading());
    try {
      final String token = await authRepository.facultyLogin(email, password);
      emit(LoginSuccess(role: 'FACULTY', token: token));
    } on ServerException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("Connection failure. Check if server is running."));
    }
  }

  /// Request password reset link for Faculty
  Future<void> forgotFacultyPassword(String email) async {
    emit(LoginLoading());
    try {
      await authRepository.facultyForgotPassword(email);
      emit(const ForgotEmailSuccess("Instructions to reset password have been sent to your email."));
    } on ServerException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("Failed to dispatch password reset request."));
    }
  }

  /// Request parent verification code
  Future<void> sendParentOtp(String mobile) async {
    emit(LoginLoading());
    try {
      await authRepository.parentSendOtp(mobile);
      emit(OtpSentSuccess(mobile));
    } on ServerException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("Failed to send OTP. Check mobile connectivity."));
    }
  }

  /// Verify parent code
  Future<void> verifyParentOtp(String mobile, String otp) async {
    emit(LoginLoading());
    try {
      final Map<String, dynamic> res = await authRepository.parentVerifyOtp(mobile, otp);
      final String token = res['token']?.toString() ?? '';
      emit(LoginSuccess(role: 'PARENT', token: token, payload: res));
    } on ServerException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("OTP verification failed. Please try again."));
    }
  }

  /// Switch context to another child mapping
  Future<void> switchParentChild(int studentId) async {
    emit(LoginLoading());
    try {
      final String newToken = await authRepository.parentSwitchChild(studentId);
      emit(LoginSuccess(role: 'PARENT', token: newToken));
    } on ServerException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(const LoginFailure("Failed to load selected child details."));
    }
  }

  /// Reset form state
  void resetForm() {
    emit(LoginInitial());
  }
}
