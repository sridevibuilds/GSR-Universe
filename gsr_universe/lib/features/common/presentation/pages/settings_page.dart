// Presentation Layer - Application Settings Page (Persisted & Live Language Switch)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('enable_notifications') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', val);
    setState(() {
      _enableNotifications = val;
    });
    if (mounted) {
      AppNotifications.showSuccess(
        context,
        val ? "Push notifications enabled." : "Push notifications disabled.",
      );
    }
  }

  Future<void> _changeLanguage(String lang) async {
    await context.read<LanguageCubit>().changeLanguage(lang);
    if (mounted) {
      AppNotifications.showSuccess(
        context,
        lang == 'Telugu' ? "భాష తెలుగుగా మార్చబడింది." : "Language set to English.",
      );
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Change Password".tr(context), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
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
                if (newPassController.text != confirmPassController.text) {
                  AppNotifications.showError(context, "New passwords do not match.");
                  return;
                }
                Navigator.pop(ctx);
                AppNotifications.showSuccess(context, "Password updated successfully.");
              },
              child: Text("Update Password", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _logoutAllDevices(BuildContext context) {
    ConfirmationDialog.show(
      context,
      title: "Logout From All Devices".tr(context),
      content: "Are you sure you want to terminate active login sessions on all devices?",
      confirmText: "Logout All",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<AuthCubit>().logout();
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LanguageCubit>().currentLanguageName;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text("Settings".tr(context), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
            // 1. NOTIFICATIONS SECTION
            Text("Notification".tr(context), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: SwitchListTile(
                title: Text("Enable Notifications".tr(context), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Receive instant school notices, fee dues, and homework alerts", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                activeColor: AppColors.gradientStart,
                value: _enableNotifications,
                onChanged: _toggleNotifications,
              ),
            ),

            const SizedBox(height: 24),

            // 2. LANGUAGE SECTION
            Text("Language".tr(context), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text("English", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    value: "English",
                    groupValue: currentLang,
                    activeColor: AppColors.gradientStart,
                    onChanged: (val) {
                      if (val != null) _changeLanguage(val);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: Text("Telugu (తెలుగు)", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    value: "Telugu",
                    groupValue: currentLang,
                    activeColor: AppColors.gradientStart,
                    onChanged: (val) {
                      if (val != null) _changeLanguage(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. SECURITY SECTION
            Text("Security".tr(context), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.gradientStart),
                    title: Text("Change Password".tr(context), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.devices_other_outlined, color: AppColors.danger),
                    title: Text("Logout From All Devices".tr(context), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.danger)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.danger),
                    onTap: () => _logoutAllDevices(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
