// Presentation Layer - About Page (With Quick Contact & Updated Details)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text("About App", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. APP HEADER BRAND CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: const Icon(Icons.school, size: 42, color: AppColors.gradientStart),
                  ),
                  const SizedBox(height: 12),
                  Text("GSR Universe", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("v1.0.0", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "School ERP Management System",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. DESCRIPTION & DETAILS CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Platform Description", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text(
                    '"A complete School ERP platform for administration, faculty, parents, and students."',
                    style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textLight, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  _buildDetailRow(Icons.domain, "School Name", "Pippara E.M. High School"),
                  _buildDetailRow(Icons.person, "Chairman", "Pippara High School Chairman"),
                  _buildDetailRow(Icons.business, "Developed By", "Universe Solutions"),
                  _buildDetailRow(Icons.email, "Support Email", "support@universesolutions.com"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. QUICK CONTACT CARD (Replaces Technology Stack)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Contact",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),

                  _buildQuickContactRow(
                    Icons.chevron_right,
                    "+91 9491336446 / 9290541105",
                  ),
                  const SizedBox(height: 14),

                  _buildQuickContactRow(
                    Icons.chevron_right,
                    "pipparaemhs@gmail.com",
                  ),
                  const SizedBox(height: 14),

                  _buildQuickContactRow(
                    Icons.chevron_right,
                    "Pippara, Attili - Tadepalligudem Road,\n534197 Ganapavaram Mandal, W.G.Dt,A.P.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "PIPPARA E.M.HIGH SCHOOL © 2026 || All Rights Reserved",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gradientStart),
          const SizedBox(width: 10),
          Text("$label: ", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactRow(IconData prefixIcon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(prefixIcon, size: 20, color: AppColors.gradientStart),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.4),
          ),
        ),
      ],
    );
  }
}
