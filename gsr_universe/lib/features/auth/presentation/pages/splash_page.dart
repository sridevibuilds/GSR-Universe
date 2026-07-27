// Presentation Layer - Splash Screen Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routes/app_routes.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startSessionCheck();
  }

  void _startSessionCheck() {
    // Check auth status after splash delay (for branding showcase)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        context.read<AuthCubit>().checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Route based on decoded JWT token role parameter
          if (state.role == 'ADMIN') {
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          } else if (state.role == 'FACULTY') {
            Navigator.pushReplacementNamed(context, AppRoutes.facultyDashboard);
          } else if (state.role == 'PARENT') {
            Navigator.pushReplacementNamed(context, AppRoutes.parentDashboard);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Background Image (School Building)
            Image.asset(
              'assets/images/login-bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // 2. High-contrast Dark Blue Overlay Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF021B3A).withOpacity(0.85),
                    const Color(0xFF0F2C59).withOpacity(0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // 3. Center Logo & Branding content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 50),
                    
                    // Logo and Title Container
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dynamic Fade-in School Logo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // GSR UNIVERSE Typography
                        Text(
                          "GSR",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Text(
                          "UNIVERSE",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 8.0,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        // Dividing Line
                        Container(
                          width: 140,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle branding
                        Text(
                          "Smart School. Bright Future.",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // 4. Footer & Progress Loader
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Empowering Education, Enriching Lives.",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
