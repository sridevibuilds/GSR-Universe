// Presentation Layer - Main Admin Dashboard Portal
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_drawer.dart';
import '../../../../core/widgets/welcome_card.dart';
import '../../../../core/widgets/stats_card.dart';
import '../../../../core/widgets/module_card.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import 'faculty_management_page.dart';
import 'call_settings_page.dart';
import 'meeting_announcements_page.dart';
import '../../../common/presentation/pages/profile_page.dart';
import '../../../common/presentation/pages/settings_page.dart';
import '../../../common/presentation/pages/help_support_page.dart';
import '../../../common/presentation/pages/privacy_policy_page.dart';
import '../../../common/presentation/pages/terms_conditions_page.dart';
import '../../../common/presentation/pages/about_page.dart';
import '../../../../core/localization/app_translations.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load dashboard metrics on entry
    context.read<AdminCubit>().fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppNotifications.showError(context, state.errorMessage!);
          context.read<AdminCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        // Metrics dynamically loaded from PostgreSQL via overview API
        final overview = state.overviewMetrics;
        int totalStudents = int.tryParse(overview?['total_students']?.toString() ?? '0') ?? 0;
        double totalPaid = double.tryParse(overview?['collected_fee_amount']?.toString() ?? '0') ?? 0.0;
        double totalDue = double.tryParse(overview?['outstanding_fee_amount']?.toString() ?? '0') ?? 0.0;

        if (overview == null && state.feeReports.isNotEmpty) {
          for (var report in state.feeReports) {
            final int students =
                int.tryParse(report['total_students']?.toString() ?? '0') ?? 0;
            final double paid =
                double.tryParse(report['total_fees_paid']?.toString() ?? '0') ?? 0.0;
            final double due =
                double.tryParse(report['total_fees_due']?.toString() ?? '0') ?? 0.0;
            totalStudents += students;
            totalPaid += paid;
            totalDue += due;
          }
        }

        final bool callsActive = state.callSettings?['is_enabled'] ?? false;

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: const CustomAppBar(
            profileName: "Administrator",
            profileRole: "Admin Portal",
          ),
          drawer: CustomDrawer(
            userName: "School Administrator",
            userRole: "ADMIN",
            items: [
              DrawerItem(
                title: "Dashboard",
                icon: Icons.dashboard_outlined,
                onTap: () {},
              ),
              DrawerItem(
                title: "Faculty Management",
                icon: Icons.people_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FacultyManagementPage()),
                  );
                },
              ),
              DrawerItem(
                title: "Student Management",
                icon: Icons.school_outlined,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.studentManagement);
                },
              ),
              DrawerItem(
                title: "IVR Reminders",
                icon: Icons.phone_callback_outlined,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.callSettings);
                },
              ),
              DrawerItem(
                title: "Meeting Announcements",
                icon: Icons.campaign_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MeetingAnnouncementsPage()),
                  );
                },
              ),
              DrawerItem(
                title: "System Notifications",
                icon: Icons.notifications_none_outlined,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              DrawerItem(
                title: "Profile",
                icon: Icons.person_outline,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                },
              ),
              DrawerItem(
                title: "Settings",
                icon: Icons.settings_outlined,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                },
              ),
              DrawerItem(
                title: "Help & Support",
                icon: Icons.help_outline,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                },
              ),
              DrawerItem(
                title: "Privacy Policy",
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
                },
              ),
              DrawerItem(
                title: "Terms & Conditions",
                icon: Icons.gavel_outlined,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsPage()));
                },
              ),
              DrawerItem(
                title: "About App",
                icon: Icons.info_outline,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
            ],
            onLogout: () {
              ConfirmationDialog.show(
                context,
                title: "Logout Session",
                content: "Are you sure you want to end your administrator session?",
                confirmText: "Logout",
                confirmColor: AppColors.danger,
                onConfirm: () {
                  context.read<AuthCubit>().logout();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                },
              );
            },
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<AdminCubit>().fetchDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Hero greeting
                  const WelcomeCard(
                    userName: "Administrator",
                    customMessage: "GSR Universe ERP provides unified control for Pippara E.M. High School operations.",
                  ),
                  AppSpacing.h20,

                  // 2. Metrics summary
                  Text(
                    "Overview Metrics",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  AppSpacing.h8,
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      StatsCard(
                        title: "Total Students".tr(context),
                        value: totalStudents.toString(),
                        label: "Registered profiles",
                        icon: Icons.group_outlined,
                        themeColor: AppColors.success,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.studentManagement);
                        },
                      ),
                      StatsCard(
                        title: "Fees Outstandings".tr(context),
                        value: "₹${(totalDue / 1000).toStringAsFixed(1)}K",
                        label: "Collected: ₹${(totalPaid / 1000).toStringAsFixed(1)}K",
                        icon: Icons.currency_rupee_outlined,
                        themeColor: AppColors.danger,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.callSettings);
                        },
                      ),
                      StatsCard(
                        title: "IVR Reminders".tr(context),
                        value: callsActive ? "ACTIVE" : "DISABLED",
                        label: callsActive ? "Monthly Sweep ON" : "Monthly Sweep OFF",
                        icon: Icons.ring_volume_outlined,
                        themeColor: AppColors.adminPrimary,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.callSettings);
                        },
                      ),
                      StatsCard(
                        title: "Faculty Management".tr(context),
                        value: state.facultyList.isEmpty ? "View" : state.facultyList.length.toString(),
                        label: "Active roster",
                        icon: Icons.person_search_outlined,
                        themeColor: AppColors.facultyPrimary,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.facultyManagement);
                        },
                      ),
                    ],
                  ),
                  AppSpacing.h24,

                  // 3. Quick actions
                  Text(
                    "Management Modules".tr(context),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  AppSpacing.h8,
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      ModuleCard(
                        title: "Faculty CRUD Roster".tr(context),
                        icon: Icons.people_outline,
                        iconColor: Colors.white,
                        iconBackgroundColor: AppColors.facultyPrimary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FacultyManagementPage()),
                          );
                        },
                      ),
                      ModuleCard(
                        title: "Call Settings Configuration".tr(context),
                        icon: Icons.phone_callback_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: AppColors.adminPrimary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CallSettingsPage()),
                          );
                        },
                      ),
                      ModuleCard(
                        title: "Meeting Announcements".tr(context),
                        icon: Icons.campaign_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.orange.shade800,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MeetingAnnouncementsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
