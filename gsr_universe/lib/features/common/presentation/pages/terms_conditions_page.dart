// Presentation Layer - Terms & Conditions Page
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text("Terms & Conditions", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
                "GSR Universe Terms of Service",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                "Effective Date: July 2026",
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSection(
                "1. User Responsibilities",
                "Users must provide accurate registration details and maintain updated contact information. Unlawful activity, unauthorized data access, or misuse of the ERP system is strictly prohibited.",
              ),
              _buildSection(
                "2. Account Security",
                "You are responsible for keeping your login credentials, mobile OTPs, and authentication tokens secure. Do not share your login credentials with unauthorized individuals.",
              ),
              _buildSection(
                "3. Proper Use of Application",
                "The application must be used exclusively for school administrative, academic, attendance, homework, and fee management purposes authorized by Pippara E.M. High School.",
              ),
              _buildSection(
                "4. School Authority Rights",
                "Pippara E.M. High School management reserves full authority to manage user accounts, modify class mapping rosters, audit fee ledgers, and publish official notices.",
              ),
              _buildSection(
                "5. Intellectual Property",
                "All application software, brand assets, logos, design themes, and content belong exclusively to Universe Solutions.",
              ),
              _buildSection(
                "6. Limitation of Liability",
                "Universe Solutions is not liable for system interruptions caused by network connectivity failures, unauthorized local device access, or third-party telecommunication outages.",
              ),
              _buildSection(
                "7. Updates to Terms",
                "These Terms & Conditions may be updated periodically to reflect software enhancements. Continued use of the application constitutes acceptance of updated terms.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gradientStart)),
          const SizedBox(height: 4),
          Text(content, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark, height: 1.5)),
        ],
      ),
    );
  }
}
