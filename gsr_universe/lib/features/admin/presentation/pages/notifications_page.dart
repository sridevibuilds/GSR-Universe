// Presentation Layer - System Notifications History Page
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().fetchNotifications();
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'FACULTY':
        return AppColors.facultyPrimary;
      case 'FEE':
        return AppColors.success;
      case 'CALL':
        return AppColors.adminPrimary;
      case 'STUDENT':
        return Colors.indigo;
      case 'EVENT':
        return Colors.purple;
      default:
        return AppColors.gradientStart;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'FACULTY':
        return Icons.person_outline;
      case 'FEE':
        return Icons.account_balance_wallet_outlined;
      case 'CALL':
        return Icons.phone_callback_outlined;
      case 'STUDENT':
        return Icons.school_outlined;
      case 'EVENT':
        return Icons.event_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "System Notifications",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderLight, height: 1.0),
        ),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state.isLoading && state.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = state.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textLight.withValues(alpha: 0.5)),
                  AppSpacing.h12,
                  Text(
                    "No notifications available",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  AppSpacing.h4,
                  Text(
                    "System event logs will appear here.",
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<AdminCubit>().fetchNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => AppSpacing.h12,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final String type = item['type'] ?? 'SYSTEM';
                final String title = item['title'] ?? 'Notification';
                final String desc = item['description'] ?? '';
                final String rawDate = item['created_at']?.toString() ?? '';

                String dateStr = 'Recent';
                String timeStr = '';
                if (rawDate.isNotEmpty) {
                  try {
                    final dt = DateTime.parse(rawDate).toLocal();
                    dateStr = "${dt.day}/${dt.month}/${dt.year}";
                    timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                  } catch (_) {}
                }

                final Color typeColor = _getTypeColor(type);
                final IconData typeIcon = _getTypeIcon(type);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: typeColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 20),
                      ),
                      AppSpacing.w12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    type.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: typeColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeStr.isNotEmpty ? "$dateStr $timeStr" : dateStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.h8,
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            AppSpacing.h4,
                            Text(
                              desc,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textDark.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
