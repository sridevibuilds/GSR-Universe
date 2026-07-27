// Presentation Layer - Parent View Holidays Screen (Read-Only)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentHolidaysPage extends StatelessWidget {
  const ParentHolidaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final holidays = List<Map<String, dynamic>>.from(state.holidays);

        // Sort upcoming holidays first
        holidays.sort((a, b) {
          final da = DateTime.tryParse((a['start_date'] ?? '').toString()) ?? DateTime.now();
          final db = DateTime.tryParse((b['start_date'] ?? '').toString()) ?? DateTime.now();
          return da.compareTo(db);
        });

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "School Holidays",
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
            child: holidays.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      title: "No Holidays Listed",
                      message: "School and academic holidays will appear here.",
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: holidays.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = holidays[index];
                      final String name = item['holiday_name'] ?? item['title'] ?? item['name'] ?? 'School Holiday';
                      final String category = item['category'] ?? item['holiday_type'] ?? 'National';
                      final String description = item['description'] ?? '';

                      String startDateStr = 'N/A';
                      if (item['start_date'] != null) {
                        try {
                          startDateStr = DateFormat('dd-MMM-yyyy').format(
                            DateTime.parse(item['start_date'].toString()),
                          );
                        } catch (_) {
                          startDateStr = item['start_date'].toString();
                        }
                      }

                      String endDateStr = startDateStr;
                      if (item['end_date'] != null) {
                        try {
                          endDateStr = DateFormat('dd-MMM-yyyy').format(
                            DateTime.parse(item['end_date'].toString()),
                          );
                        } catch (_) {
                          endDateStr = item['end_date'].toString();
                        }
                      }

                      final bool isMultiDay = startDateStr != endDateStr;

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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.beach_access, color: AppColors.success, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.date_range, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  isMultiDay ? "From: $startDateStr To: $endDateStr" : "Date: $startDateStr",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
