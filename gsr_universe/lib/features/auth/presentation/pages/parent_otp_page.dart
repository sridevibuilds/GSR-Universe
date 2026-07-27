// Presentation Layer - Parent Mobile OTP Verification Login Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import 'child_selection_page.dart';

class ParentOtpPage extends StatefulWidget {
  const ParentOtpPage({super.key});

  @override
  State<ParentOtpPage> createState() => _ParentOtpPageState();
}

class _ParentOtpPageState extends State<ParentOtpPage> {
  final _mobileFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _otpSent = false;
  String _currentMobile = "";

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp(BuildContext context) {
    if (_mobileFormKey.currentState!.validate()) {
      final mobile = _mobileController.text.trim();
      _currentMobile = mobile;
      context.read<LoginCubit>().sendParentOtp(mobile);
    }
  }

  void _verifyOtp(BuildContext context) {
    if (_otpFormKey.currentState!.validate()) {
      final otp = _otpController.text.trim();
      context.read<LoginCubit>().verifyParentOtp(_currentMobile, otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is OtpSentSuccess) {
            final displayOtp = state.otp ?? "123456";
            setState(() {
              _otpSent = true;
              _otpController.text = displayOtp;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("OTP Sent Successfully! Verification Code: $displayOtp"),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 8),
              ),
            );
          }
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          if (state is LoginSuccess) {
            // Save token session details in AuthCubit
            context.read<AuthCubit>().authenticate(state.token);

            final Map<String, dynamic>? data = state.payload;
            final List<dynamic> studentsList = data?['students'] ?? [];

            if (studentsList.length > 1) {
              // Redirect to multiple child selector context screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildSelectionPage(
                    students: studentsList,
                    token: state.token,
                  ),
                ),
                (route) => false,
              );
            } else {
              // Direct route to Parent Dashboard
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.parentDashboard, (route) => false);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () {
                  if (_otpSent) {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                    });
                    context.read<LoginCubit>().resetForm();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Title Header Naming Consistent
                    Text(
                      "Parent Login",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.parentPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent
                          ? "Enter the 6-digit verification code sent to $_currentMobile."
                          : "Enter your registered mobile number to receive a secure OTP.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // OTP form state switch
                    if (!_otpSent) ...[
                      // Mobile Input Form
                      Form(
                        key: _mobileFormKey,
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Mobile Number",
                            prefixIcon: Icon(Icons.phone_android_outlined),
                            hintText: "Enter 10-digit number",
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return "Mobile number is required";
                            if (val.length < 10) return "Enter a valid mobile number";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.parentPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: state is LoginLoading ? null : () => _sendOtp(context),
                          child: state is LoginLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  "Send OTP",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      // OTP Verification Entry Form
                      Form(
                        key: _otpFormKey,
                        child: TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8.0,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Verification Code",
                            prefixIcon: Icon(Icons.lock_clock_outlined),
                            counterText: "",
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return "OTP is required";
                            if (val.length != 6) return "Enter 6-digit verification code";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Verify OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.parentPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: state is LoginLoading ? null : () => _verifyOtp(context),
                          child: state is LoginLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  "Verify & Login",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: state is LoginLoading
                              ? null
                              : () => context.read<LoginCubit>().sendParentOtp(_currentMobile),
                          child: Text(
                            "Resend OTP",
                            style: GoogleFonts.inter(
                              color: AppColors.parentPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
