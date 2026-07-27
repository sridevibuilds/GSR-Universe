// Presentation Layer - Login Role Selection Page
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'login_credentials_page.dart';
import 'parent_otp_page.dart';

class LoginSelectionPage extends StatelessWidget {
  const LoginSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Curved Header Card (School Branding & Welcome Back Greeting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.elliptical(450, 100),
                ),
              ),
              child: Column(
                children: [
                  // School logo image
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "GSR UNIVERSE",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Text(
                    "Smart School. Bright Future.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Welcome Back!",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sign in to continue to GSR Universe",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Dots Slider Indicator (Matches Reference Image 2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildIndicatorDot(Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      _buildIndicatorDot(Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      _buildIndicatorDot(Colors.white.withOpacity(0.4)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Choose Your Login Type Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.gradientStart,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Choose Your Login Type",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gradientStart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Role 1: Admin Login Card
                  _buildRoleCard(
                    context,
                    title: "Admin Login",
                    subtitle: "Access admin dashboard",
                    icon: Icons.admin_panel_settings,
                    themeColor: AppColors.adminPrimary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginCredentialsPage(role: 'ADMIN'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Role 2: Faculty Login Card
                  _buildRoleCard(
                    context,
                    title: "Faculty Login",
                    subtitle: "Access faculty dashboard",
                    icon: Icons.school,
                    themeColor: AppColors.facultyPrimary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginCredentialsPage(role: 'FACULTY'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Role 3: Parent Login Card (Naming Consistent)
                  _buildRoleCard(
                    context,
                    title: "Parent Login",
                    subtitle: "Access your child's information",
                    icon: Icons.people_alt,
                    themeColor: AppColors.parentPrimary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentOtpPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),

                  // 3. Security Banner (Padlock icon + copies)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFB3E5FC).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF0288D1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Secure & Trusted",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF01579B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Your data is safe with us. We ensure top-notch security and privacy.",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF0277BD),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. Copyrights Footer Text
                  Text(
                    "© 2025 GSR Universe. All Rights Reserved.",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            // Circular role icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColor.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: themeColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow suffix icon
            Icon(
              Icons.chevron_right,
              color: AppColors.textLight.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
