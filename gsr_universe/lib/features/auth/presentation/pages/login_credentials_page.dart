// Presentation Layer - Credentials Login Page (Admin / Faculty)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginCredentialsPage extends StatefulWidget {
  final String role; // 'ADMIN' or 'FACULTY'

  const LoginCredentialsPage({super.key, required this.role});

  @override
  State<LoginCredentialsPage> createState() => _LoginCredentialsPageState();
}

class _LoginCredentialsPageState extends State<LoginCredentialsPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      if (widget.role == 'ADMIN') {
        context.read<LoginCubit>().loginAdmin(email, password);
      } else {
        context.read<LoginCubit>().loginFaculty(email, password);
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext parentContext) {
    final emailResetController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Reset Password",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter your registered faculty email to receive a password reset link.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailResetController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Email is required";
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: AppColors.textLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.facultyPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final email = emailResetController.text.trim();
                  Navigator.pop(context);
                  parentContext.read<LoginCubit>().forgotFacultyPassword(email);
                }
              },
              child: Text(
                "Send Link",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = widget.role == 'ADMIN' ? AppColors.adminPrimary : AppColors.facultyPrimary;
    final String roleName = widget.role == 'ADMIN' ? "Admin" : "Faculty";

    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // Register token in AuthCubit
            context.read<AuthCubit>().authenticate(state.token);
            
            // Route to appropriate dashboard
            if (widget.role == 'ADMIN') {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminDashboard, (route) => false);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.facultyDashboard, (route) => false);
            }
          }
          if (state is LoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          if (state is ForgotEmailSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Title section
                      Text(
                        "$roleName Login",
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please sign in with your registered school credentials.",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email input box
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: "example@gsruniverse.com",
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Email address is required";
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password input box
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Password is required";
                          if (val.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),

                      // Forgot password alignment (Only for Faculty)
                      if (widget.role == 'FACULTY') ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => _showForgotPasswordDialog(context),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: roleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Submit/Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roleColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: state is LoginLoading ? null : () => _submitLogin(context),
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
                                  "Login",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
