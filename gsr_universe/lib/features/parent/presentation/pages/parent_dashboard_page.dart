// Presentation Layer - Main Student/Parent Dashboard Portal
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
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/cubit/login_cubit.dart';
import '../../../auth/presentation/cubit/login_state.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';
import 'parent_attendance_page.dart';
import 'parent_marks_page.dart';
import 'parent_homework_page.dart';
import 'parent_assignments_page.dart';
import 'parent_fees_page.dart';
import 'parent_progress_card_page.dart';
import 'parent_timetable_page.dart';
import 'parent_announcements_page.dart';
import 'parent_events_page.dart';
import 'parent_holidays_page.dart';
import 'parent_notice_board_page.dart';
import 'parent_transport_page.dart';
import '../../../common/presentation/pages/profile_page.dart';
import '../../../common/presentation/pages/settings_page.dart';
import '../../../common/presentation/pages/help_support_page.dart';
import '../../../common/presentation/pages/privacy_policy_page.dart';
import '../../../common/presentation/pages/terms_conditions_page.dart';
import '../../../common/presentation/pages/about_page.dart';
import '../../../../core/localization/app_translations.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load student/parent indicators
    context.read<ParentCubit>().loadAllChildData();
  }

  void _showChildSwitcher(BuildContext context, List<dynamic> children) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Switch Active Child Profile",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
              ),
              AppSpacing.h12,
              if (children.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "No additional children mapped to this parent account.",
                    style: GoogleFonts.inter(color: AppColors.textLight),
                  ),
                )
              else
                ...children.map((child) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.parentPrimary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      child['student_name'] ?? 'Child Profile',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      "Class: ${child['class_name'] ?? ''} - ${child['section'] ?? ''}",
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Trigger child context switch
                      context.read<LoginCubit>().switchParentChild(child['student_id'] ?? child['id']);
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showParentNotificationsModal(BuildContext context, List<Map<String, dynamic>> notifications) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, color: AppColors.parentPrimary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Updates & Notifications",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textLight),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: notifications.isEmpty
                      ? Center(
                          child: Text("No new notifications from faculty", style: GoogleFonts.inter(color: AppColors.textLight)),
                        )
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => AppSpacing.h12,
                          itemBuilder: (context, idx) {
                            final notif = notifications[idx];
                            final int notifId = notif['id'] ?? 0;
                            final bool isRead = notif['is_read'] == true || notif['is_read'] == 'true' || notif['is_read'] == 't' || notif['is_read'] == 1;
                            final String title = notif['title'] ?? 'Faculty Update';
                            final String msg = notif['message'] ?? '';
                            final String time = notif['formatted_time'] ?? '';
                            final String type = (notif['type'] ?? 'notice').toString().toUpperCase();

                            Color badgeColor = AppColors.parentPrimary;
                            if (type == 'HOMEWORK') badgeColor = Colors.orange.shade800;
                            if (type == 'ASSIGNMENT') badgeColor = Colors.purple.shade700;
                            if (type == 'PROGRESS') badgeColor = AppColors.success;

                            return GestureDetector(
                              onTap: () {
                                if (!isRead && notifId > 0) {
                                  context.read<ParentCubit>().markParentNotificationAsRead(notifId);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.grey.shade50 : AppColors.parentPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isRead ? AppColors.borderLight : AppColors.parentPrimary.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                                        ),
                                        if (!isRead)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                                            child: Text("NEW", style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    AppSpacing.h4,
                                    Text(msg, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w500)),
                                    AppSpacing.h8,
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text(type, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: badgeColor)),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.access_time, size: 12, color: AppColors.textLight),
                                        const SizedBox(width: 4),
                                        Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    List<dynamic> children = [];
    if (authState is AuthAuthenticated) {
      children = authState.payload['children'] ?? [];
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<LoginCubit, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              context.read<AuthCubit>().authenticate(state.token);
              
              // Reload all dashboard endpoints for the newly active student class mapping ID
              context.read<ParentCubit>().loadAllChildData();
              AppNotifications.showSuccess(context, "Switched child profile successfully.");
            }
            if (state is LoginFailure) {
              AppNotifications.showError(context, state.message);
            }
          },
        ),
        BlocListener<ParentCubit, ParentState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              AppNotifications.showError(context, state.errorMessage!);
              context.read<ParentCubit>().clearErrorMessage();
            }
          },
        ),
      ],
      child: BlocBuilder<ParentCubit, ParentState>(
        builder: (context, state) {
          final profile = state.profileData ?? {};
          final dashboard = state.dashboardData ?? {};
          final attendance = dashboard['attendance'] ?? {};
          final feeSummary = dashboard['feeSummary'] ?? {};

          final studentName = profile['student_name'] ?? 'Student';
          final className = profile['class_name'] ?? '';
          final section = profile['section'] ?? '';
          final rollNo = profile['class_roll_number'] ?? 'N/A';

          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            appBar: CustomAppBar(
              profileName: studentName,
              profileRole: "Class $className - $section (Roll: $rollNo)",
              notificationCount: state.unreadParentNotificationCount,
              onNotificationTap: () => _showParentNotificationsModal(context, state.parentNotifications),
            ),
            drawer: CustomDrawer(
              userName: studentName,
              userRole: "PARENT",
              items: [
                DrawerItem(
                  title: "Dashboard",
                  icon: Icons.dashboard_outlined,
                  onTap: () {},
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
                  content: "Are you sure you want to end your parent session?",
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
              onRefresh: () async {
                await context.read<ParentCubit>().loadAllChildData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Welcome Card
                    WelcomeCard(
                      userName: studentName,
                      customMessage: "Welcome to GSR Universe ERP portal.",
                    ),
                    AppSpacing.h12,

                    // 2. Child Switcher Card
                    if (children.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InkWell(
                          onTap: () => _showChildSwitcher(context, children),
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.parentPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_outline, color: AppColors.parentPrimary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Multiple Children Mapped",
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.parentPrimary),
                                      ),
                                      Text(
                                        "Tap here to switch context to another child.",
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.parentPrimary),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 3. Stats Section
                    Text(
                      "Student Overview".tr(context),
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
                          title: "Attendance".tr(context),
                          value: "${(attendance['percentage'] as num? ?? 100.0).toStringAsFixed(0)}%",
                          label: "Check-in Average".tr(context),
                          icon: Icons.check_circle_outline,
                          themeColor: AppColors.success,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentAttendancePage()),
                            );
                          },
                        ),
                        StatsCard(
                          title: "Pending Dues".tr(context),
                          value: "₹${(feeSummary['pendingAmount'] as num? ?? 0.0).toStringAsFixed(0)}",
                          label: "Outstanding Fee".tr(context),
                          icon: Icons.currency_rupee_outlined,
                          themeColor: AppColors.danger,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentFeesPage()),
                            );
                          },
                        ),
                        StatsCard(
                          title: "Homework Tasks".tr(context),
                          value: (dashboard['homeworkCount'] ?? 0).toString(),
                          label: "Assigned Roster".tr(context),
                          icon: Icons.assignment_outlined,
                          themeColor: AppColors.parentPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentHomeworkPage()),
                            );
                          },
                        ),
                        StatsCard(
                          title: "Progress Card".tr(context),
                          value: "Report Card".tr(context),
                          label: "Click to view".tr(context),
                          icon: Icons.badge_outlined,
                          themeColor: AppColors.warning,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentProgressCardPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    AppSpacing.h24,

                    // 4. Management Modules Section (Matching Faculty Dashboard layout & design)
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
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                      children: [
                        ModuleCard(
                          title: "Attendance".tr(context),
                          icon: Icons.fact_check_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: AppColors.adminPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentAttendancePage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Assessments".tr(context),
                          icon: Icons.grade_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.amber[700]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentMarksPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Homework".tr(context),
                          icon: Icons.assignment_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.teal[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentHomeworkPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Assignments".tr(context),
                          icon: Icons.task_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.purple[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentAssignmentsPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Progress Cards".tr(context),
                          icon: Icons.badge_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.orange[700]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentProgressCardPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Timetable".tr(context),
                          icon: Icons.calendar_view_day_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.blue[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentTimetablePage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Announcements".tr(context),
                          icon: Icons.campaign_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.red[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentAnnouncementsPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "School Events".tr(context),
                          icon: Icons.event_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.indigo[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentEventsPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Holidays".tr(context),
                          icon: Icons.beach_access_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.green[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentHolidaysPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Notice Board".tr(context),
                          icon: Icons.note_alt_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.cyan[700]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentNoticeBoardPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Transport".tr(context),
                          icon: Icons.directions_bus_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.deepOrange[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentTransportPage()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: "Fee Details".tr(context),
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: Colors.white,
                          iconBackgroundColor: Colors.pink[600]!,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ParentFeesPage()),
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
      ),
    );
  }
}
