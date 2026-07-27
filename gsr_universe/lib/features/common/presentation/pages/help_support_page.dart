// Presentation Layer - Help & Support Page (FAQs, Contact & Report Issue)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../../core/widgets/file_uploader.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _screenshotPath;

  void _submitIssue() {
    if (_formKey.currentState!.validate()) {
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _screenshotPath = null;
      });
      AppNotifications.showSuccess(context, "Issue reported successfully. Support team will contact you.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text("Help & Support", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FREQUENTLY ASKED QUESTIONS SECTION
            Text("Frequently Asked Questions", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  _buildFaqTile(
                    "How to submit homework?",
                    "Open the Homework module on your Dashboard, select your subject, tap 'Submit Homework', pick your homework file or document, and confirm submission.",
                  ),
                  const Divider(height: 1),
                  _buildFaqTile(
                    "How to submit assignments?",
                    "Navigate to Assignments & Projects from your Dashboard, choose your subject filter, click 'Submit Assignment', select your file attachment, and tap submit.",
                  ),
                  const Divider(height: 1),
                  _buildFaqTile(
                    "How to download report card?",
                    "Open the Progress Cards module on your Dashboard. You can view your uploaded progress card details and click 'Download Progress Card' to save the official PDF.",
                  ),
                  const Divider(height: 1),
                  _buildFaqTile(
                    "How to view attendance?",
                    "Tap on the Attendance module to view monthly attendance percentages, daily present/absent logs, and leave summaries.",
                  ),
                  const Divider(height: 1),
                  _buildFaqTile(
                    "How to contact school?",
                    "Use the Contact Support section below to reach Pippara E.M. High School administration directly via phone call or email.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. CONTACT SUPPORT SECTION
            Text("Contact Support", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.gradientStart,
                    child: Icon(Icons.email, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Support Email", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                      Text("support@universesolutions.com", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. REPORT AN ISSUE SECTION
            Text("Report an Issue", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      validator: (val) => val == null || val.trim().isEmpty ? "Please enter issue title" : null,
                      decoration: InputDecoration(
                        labelText: "Issue Title",
                        hintText: "Brief summary of the issue",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty ? "Please enter issue description" : null,
                      decoration: InputDecoration(
                        labelText: "Description",
                        hintText: "Describe the issue in detail...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FileUploader(
                      label: "Upload Screenshot (Optional)",
                      onFileSelected: (file) {
                        setState(() {
                          _screenshotPath = file?.path;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gradientStart,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _submitIssue,
                        child: Text("Submit Issue", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
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

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
          child: Text(answer, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, height: 1.4)),
        ),
      ],
    );
  }
}
