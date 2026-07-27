// Presentation Layer - Parent View Announcements Screen (Read-Only)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../data/models/announcement_model.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentAnnouncementsPage extends StatelessWidget {
  const ParentAnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final announcements = state.announcements;

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Announcements",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: announcements.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      title: "No Announcements",
                      message: "School announcements and notifications published for your class will appear here.",
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: announcements.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final rawItem = announcements[index];
                      final AnnouncementModel model = rawItem is AnnouncementModel
                          ? (rawItem as AnnouncementModel)
                          : AnnouncementModel.fromJson(Map<String, dynamic>.from(rawItem as Map));

                      final String title = model.title;
                      final String message = model.message;
                      final String priority = model.priority;
                      final String facultyName = model.createdByName;
                      final String dateStr = DateFormat('dd-MMM-yyyy hh:mm a').format(model.createdAt);

                      Color priorityColor = AppColors.parentPrimary;
                      if (priority == 'URGENT' || priority == 'HIGH') {
                        priorityColor = AppColors.danger;
                      } else if (priority == 'MEDIUM') {
                        priorityColor = AppColors.warning;
                      }

                      return Container(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    priority,
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.campaign, size: 18, color: priorityColor),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                            ),
                            if (message.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  facultyName,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                ),
                                const Spacer(),
                                Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
