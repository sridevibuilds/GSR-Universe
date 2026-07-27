// Presentation Layer - Privacy Policy Page
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text("Privacy Policy", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
                "GSR Universe Privacy Policy",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                "Last Updated: July 2026",
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              _buildSection(
                "1. Student Data Privacy",
                "We collect student academic records, attendance logs, assessment grades, and transport details solely for authorized educational administration at Pippara E.M. High School. Student information is strictly private and never shared with commercial third parties.",
              ),
              _buildSection(
                "2. Parent Data Privacy",
                "Parent contact numbers, email addresses, fee payment records, and account credentials are managed with strict confidentiality to facilitate official school communications, automated fee reminders, and academic updates.",
              ),
              _buildSection(
                "3. Faculty Data Privacy",
                "Faculty professional profiles, teaching schedules, assignment uploads, and class rosters are encrypted and accessible exclusively to authorized school administration personnel.",
              ),
              _buildSection(
                "4. Data Collection Practices",
                "We collect personal information directly provided during enrollment, mobile authentication tokens, and uploaded academic documents (PDFs, images) required to power school ERP features.",
              ),
              _buildSection(
                "5. Data Usage & Processing",
                "All collected data is utilized exclusively for generating student progress cards, attendance monitoring, fee ledgers, timetable publishing, and push notifications.",
              ),
              _buildSection(
                "6. Data Security & Encryption",
                "GSR Universe employs industry-standard JWT authentication, SSL/TLS data transport encryption, and secure PostgreSQL database access controls to safeguard data integrity.",
              ),
              _buildSection(
                "7. User Privacy Rights",
                "Users may request profile corrections, data access summaries, or account credential updates by contacting Pippara E.M. High School administration.",
              ),
              _buildSection(
                "8. Contact for Privacy Concerns",
                "For any questions or concerns regarding our privacy practices, please contact privacy@gsruniverse.com.",
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
