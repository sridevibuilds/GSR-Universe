// Presentation Layer - Main Faculty Dashboard Portal
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
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

import '../../../common/presentation/pages/profile_page.dart';
import '../../../common/presentation/pages/settings_page.dart';
import '../../../common/presentation/pages/help_support_page.dart';
import '../../../common/presentation/pages/privacy_policy_page.dart';
import '../../../common/presentation/pages/terms_conditions_page.dart';
import '../../../common/presentation/pages/about_page.dart';
import '../../../../core/localization/app_translations.dart';

class FacultyDashboardPage extends StatefulWidget {
  const FacultyDashboardPage({super.key});

  @override
  State<FacultyDashboardPage> createState() => _FacultyDashboardPageState();
}

class _FacultyDashboardPageState extends State<FacultyDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load state feed
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchHomework();
    context.read<FacultyCubit>().fetchFacultyMeetingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FacultyCubit, FacultyState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppNotifications.showError(context, state.errorMessage!);
          context.read<FacultyCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        // Compute stats for overview metrics
        final int totalStudentsCount = state.studentsList.length;
        final int homeworkPendingCount = state.homeworkList.where((h) {
          final due = h['due_date'] != null ? DateTime.tryParse(h['due_date']) : null;
          return due != null && due.isAfter(DateTime.now().subtract(const Duration(days: 1)));
        }).length;
        
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: CustomAppBar(
            profileName: "Faculty Portal",
            profileRole: "Teacher Dashboard",
            notificationCount: state.unreadMeetingCount,
            onNotificationTap: () => _showMeetingNotificationsModal(context, state.meetingNotifications),
          ),
          drawer: CustomDrawer(
            userName: "Faculty Teacher",
            userRole: "FACULTY",
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
                content: "Are you sure you want to end your teacher session?",
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
              context.read<FacultyCubit>().fetchStudents();
              context.read<FacultyCubit>().fetchHomework();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome Card Banner
                  const WelcomeCard(
                    userName: "Teacher Portal",
                    customMessage: "Submit assessments, manage student rosters, schedule exams, and audit class fee ledgers.",
                  ),
                  AppSpacing.h20,

                  // 2. Metrics summary
                  Text(
                    "Teacher Overview".tr(context),
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
                    childAspectRatio: 1.5,
                    children: [
                      StatsCard(
                        title: "Total Students".tr(context),
                        value: totalStudentsCount.toString(),
                        label: "Roster enrolled",
                        icon: Icons.group_outlined,
                        themeColor: AppColors.success,
                      ),
                      StatsCard(
                        title: "Homework Pending".tr(context),
                        value: homeworkPendingCount.toString(),
                        label: "Active tasks",
                        icon: Icons.assignment_outlined,
                        themeColor: AppColors.facultyPrimary,
                      ),
                      StatsCard(
                        title: "Attendance Today".tr(context),
                        value: "95%",
                        label: "Synced devices rate",
                        icon: Icons.check_circle_outline,
                        themeColor: AppColors.warning,
                      ),
                      StatsCard(
                        title: "Academic Year".tr(context),
                        value: "2026-2027",
                        label: "Active term",
                        icon: Icons.calendar_today_outlined,
                        themeColor: AppColors.adminPrimary,
                      ),
                    ],
                  ),
                  AppSpacing.h24,

                  // 3. Grid Shortcuts (14 modules)
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
                        title: "Student Management".tr(context),
                        icon: Icons.people_outline,
                        iconColor: Colors.white,
                        iconBackgroundColor: AppColors.facultyPrimary,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facStudentManagement),
                      ),
                      ModuleCard(
                        title: "Attendance".tr(context),
                        icon: Icons.fact_check_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: AppColors.adminPrimary,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facAttendance),
                      ),
                      ModuleCard(
                        title: "Assessments".tr(context),
                        icon: Icons.grade_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.amber[700]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facAssessments),
                      ),
                      ModuleCard(
                        title: "Homework".tr(context),
                        icon: Icons.assignment_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.teal[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facHomework),
                      ),
                      ModuleCard(
                        title: "Assignments".tr(context),
                        icon: Icons.task_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.purple[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facAssignments),
                      ),
                      ModuleCard(
                        title: "Progress Cards".tr(context),
                        icon: Icons.badge_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.orange[700]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facProgressCards),
                      ),
                      ModuleCard(
                        title: "Timetable".tr(context),
                        icon: Icons.calendar_view_day_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.blue[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facTimetable),
                      ),
                      ModuleCard(
                        title: "Announcements".tr(context),
                        icon: Icons.campaign_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.red[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facAnnouncements),
                      ),
                      ModuleCard(
                        title: "School Events".tr(context),
                        icon: Icons.event_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.indigo[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facEvents),
                      ),
                      ModuleCard(
                        title: "Holidays".tr(context),
                        icon: Icons.beach_access_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.green[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facHolidays),
                      ),
                      ModuleCard(
                        title: "Notice Board".tr(context),
                        icon: Icons.note_alt_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.cyan[700]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facNoticeBoard),
                      ),
                      ModuleCard(
                        title: "Transport".tr(context),
                        icon: Icons.directions_bus_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.deepOrange[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facTransport),
                      ),
                      ModuleCard(
                        title: "Promotion".tr(context),
                        icon: Icons.trending_up_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.blueGrey[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facStudentPromotion),
                      ),
                      ModuleCard(
                        title: "Fee Details".tr(context),
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.white,
                        iconBackgroundColor: Colors.pink[600]!,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.facFeeDetails),
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

  void _showMeetingNotificationsModal(BuildContext context, List<Map<String, dynamic>> notifications) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Staff Meeting Notifications", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Text("No new meeting notifications", style: GoogleFonts.inter(color: AppColors.textLight)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => AppSpacing.h12,
                        itemBuilder: (context, idx) {
                          final notif = notifications[idx];
                          final int notifId = notif['notification_id'] ?? 0;
                          final bool isRead = notif['is_read'] == true || notif['is_read'] == 'true' || notif['is_read'] == 't' || notif['is_read'] == 1;
                          final String title = notif['notif_title'] ?? 'Staff Meeting';
                          final String msg = notif['notif_message'] ?? '';
                          final String desc = notif['description'] ?? '';
                          final String date = notif['meeting_date'] ?? '';
                          final String time = notif['meeting_time'] ?? '';
                          final String priority = notif['priority'] ?? 'Normal';

                          Color pColor = AppColors.facultyPrimary;
                          if (priority.toLowerCase() == 'urgent') pColor = AppColors.danger;
                          if (priority.toLowerCase() == 'important') pColor = Colors.orange.shade800;

                          return GestureDetector(
                            onTap: () {
                              if (!isRead && notifId > 0) {
                                context.read<FacultyCubit>().markMeetingNotificationAsRead(notifId);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.grey.shade50 : AppColors.facultyPrimary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isRead ? AppColors.borderLight : AppColors.facultyPrimary.withValues(alpha: 0.3)),
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
                                  if (desc.isNotEmpty) ...[
                                    AppSpacing.h4,
                                    Text(desc, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                                  ],
                                  AppSpacing.h8,
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: pColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(priority.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: pColor)),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textLight),
                                      const SizedBox(width: 4),
                                      Text(date, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
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
          ),
        );
      },
    );
  }
}
