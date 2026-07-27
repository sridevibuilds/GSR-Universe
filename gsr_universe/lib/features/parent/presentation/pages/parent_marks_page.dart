// Presentation Layer - Parent View Student Exam Marks Screen
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentMarksPage extends StatelessWidget {
  const ParentMarksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Academic Performance",
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Performance introduction card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
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
                            const Icon(Icons.stars, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(
                              "Report Card summary",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        AppSpacing.h8,
                        Text(
                          "Monitor classroom test transcripts, unit exams, and teacher reviews regularly.",
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.h8,

                // List of marks
                Expanded(
                  child: state.marks.isEmpty
                      ? const Center(
                          child: EmptyStateWidget(
                            title: "No Scores Uploaded",
                            message: "Grading marks have not been published by the faculty yet.",
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.marks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final mark = state.marks[index];

                            // Safe double parser to prevent "type 'String' is not a subtype of type 'num?'" crash
                            double parseDouble(dynamic val, [double defaultValue = 0.0]) {
                              if (val == null) return defaultValue;
                              if (val is num) return val.toDouble();
                              if (val is String) {
                                return double.tryParse(val.trim()) ?? defaultValue;
                              }
                              return defaultValue;
                            }

                            final double obtained = parseDouble(mark['marks_obtained']);
                            final double total = parseDouble(mark['total_marks'] ?? mark['max_marks'], 100.0);
                            final double percentage = total > 0 ? (obtained / total) * 100 : 0.0;
                            
                            String getGrade(double pct) {
                              if (pct >= 95.0) return 'A+';
                              if (pct >= 90.0) return 'A';
                              if (pct >= 80.0) return 'B+';
                              if (pct >= 70.0) return 'B';
                              if (pct >= 60.0) return 'C';
                              return 'D';
                            }

                            String formatMarkVal(double val) {
                              if (val % 1 == 0) {
                                return val.toInt().toString();
                              }
                              return val.toString();
                            }

                            final String gradeStr = getGrade(percentage);

                            String dateStr = 'N/A';
                            final rawDate = mark['assessment_date'] ?? mark['date'];
                            if (rawDate != null) {
                              try {
                                dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(rawDate.toString()));
                              } catch (_) {}
                            }

                            // Determine status color based on percentage bounds
                            Color statusColor = AppColors.success;
                            if (percentage < 60.0) {
                              statusColor = AppColors.danger;
                            } else if (percentage < 80.0) {
                              statusColor = AppColors.warning;
                            }

                            final String assessmentName = mark['assessment_name'] ?? mark['assessment_type'] ?? mark['title'] ?? 'Unit Test';
                            final String description = mark['description'] ?? mark['remarks'] ?? '';

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
                                          color: AppColors.parentPrimary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          mark['subject_name'] ?? 'Subject',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.parentPrimary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Grade: $gradeStr",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.h12,
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              assessmentName,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                description,
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${formatMarkVal(obtained)} / ${formatMarkVal(total)}",
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${percentage.toStringAsFixed(0)}%",
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
