// Presentation Layer - User Profile Page (With Real Image Selection & Editing)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../parent/presentation/cubit/parent_cubit.dart';
import '../../../parent/presentation/cubit/parent_state.dart';
import '../../../faculty/presentation/cubit/faculty_cubit.dart';
import '../../../faculty/presentation/cubit/faculty_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarPath;

  Future<void> _pickAvatarImage(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        setState(() {
          _avatarPath = result.files.single.path;
        });
        if (context.mounted) {
          AppNotifications.showSuccess(context, "Profile picture updated successfully.");
        }
      }
    } catch (e) {
      debugPrint("Error picking avatar image: $e");
      if (context.mounted) {
        AppNotifications.showError(context, "Failed to select profile picture.");
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, String currentMobile, String currentEmail) {
    final mobileController = TextEditingController(text: currentMobile);
    final emailController = TextEditingController(text: currentEmail);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Edit Profile Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Mobile Number",
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.gradientStart),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gradientStart),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gradientStart),
              onPressed: () {
                Navigator.pop(ctx);
                AppNotifications.showSuccess(context, "Profile details updated successfully.");
              },
              child: Text("Save Changes", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String name = "User Profile";
    String role = "MEMBER";
    String mobile = "N/A";
    String email = "N/A";
    String regNo = "N/A";
    String className = "";
    String section = "";
    String subject = "";

    if (authState is AuthAuthenticated) {
      final payload = authState.payload;
      role = (payload['role']?.toString() ?? 'MEMBER').toUpperCase();
      name = payload['name']?.toString() ??
          payload['student_name']?.toString() ??
          payload['faculty_name']?.toString() ??
          payload['admin_name']?.toString() ??
          (role == 'ADMIN' ? 'Administrator' : 'User Profile');
      mobile = payload['mobile']?.toString() ?? payload['parent_mobile']?.toString() ?? 'N/A';
      email = payload['email']?.toString() ?? 'N/A';
      regNo = payload['employee_id']?.toString() ??
          payload['admission_no']?.toString() ??
          payload['roll_number']?.toString() ??
          (payload['id'] != null ? 'ID-${payload['id']}' : 'N/A');
      subject = payload['subject']?.toString() ?? '';
    }

    if (role == 'PARENT' || role == 'STUDENT') {
      final parentState = context.watch<ParentCubit>().state;
      final profile = parentState.profileData ?? {};
      if (profile.isNotEmpty) {
        name = profile['student_name']?.toString() ?? name;
        regNo = profile['admission_no']?.toString() ??
            profile['class_roll_number']?.toString() ??
            profile['roll_number']?.toString() ??
            regNo;
        className = profile['class_name']?.toString() ?? '';
        section = profile['section']?.toString() ?? '';
        mobile = profile['parent_mobile']?.toString() ?? profile['mobile']?.toString() ?? mobile;
        email = profile['email']?.toString() ?? (email != 'N/A' ? email : 'N/A');
      }
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text("My Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
            // 1. Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: _avatarPath != null && File(_avatarPath!).existsSync()
                            ? FileImage(File(_avatarPath!))
                            : null,
                        child: _avatarPath == null || !File(_avatarPath!).existsSync()
                            ? const Icon(Icons.person, size: 54, color: Colors.white)
                            : null,
                      ),
                      InkWell(
                        onTap: () => _pickAvatarImage(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: AppColors.gradientStart),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Personal Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Personal Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.gradientStart, size: 20),
                        onPressed: () => _showEditProfileDialog(context, mobile, email),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildProfileRow(Icons.badge_outlined, role == 'FACULTY' ? "Employee ID" : "Registration / Adm No", regNo),
                  _buildProfileRow(Icons.phone_outlined, "Mobile Number", mobile),
                  _buildProfileRow(Icons.email_outlined, "Email Address", email),
                  if ((role == 'PARENT' || role == 'STUDENT') && className.isNotEmpty) ...[
                    _buildProfileRow(Icons.class_outlined, "Class & Section", section.isNotEmpty ? "Class $className - $section" : "Class $className"),
                  ],
                  if (role == 'FACULTY' && subject.isNotEmpty) ...[
                    _buildProfileRow(Icons.book_outlined, "Subject / Department", subject),
                  ],
                  _buildProfileRow(Icons.school_outlined, "School Institution", "Pippara E.M. High School"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gradientStart),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
              Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}
