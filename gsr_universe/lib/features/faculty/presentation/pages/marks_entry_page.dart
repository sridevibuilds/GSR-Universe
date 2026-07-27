// Presentation Layer - Assessment Marks Entry Console
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class MarksEntryPage extends StatefulWidget {
  const MarksEntryPage({super.key});

  @override
  State<MarksEntryPage> createState() => _MarksEntryPageState();
}

class _MarksEntryPageState extends State<MarksEntryPage> {
  int? _selectedClassId;
  int? _selectedAssessmentId;
  final Map<int, TextEditingController> _marksControllers = {};
  final Map<int, TextEditingController> _remarksControllers = {};

  @override
  void initState() {
    super.initState();
    // Fetch students roster list and assessment categories
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchAssessments();
  }

  @override
  void dispose() {
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    for (var controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveMarks(BuildContext context, int scmId, double maxMarks) {
    final marksStr = _marksControllers[scmId]?.text.trim() ?? '';
    final remarks = _remarksControllers[scmId]?.text.trim() ?? 'Good';
    
    if (marksStr.isEmpty) {
      AppNotifications.showError(context, "Please enter obtained marks.");
      return;
    }

    final marks = double.tryParse(marksStr);
    if (marks == null) {
      AppNotifications.showError(context, "Enter a valid numeric score.");
      return;
    }

    if (marks < 0 || marks > maxMarks) {
      AppNotifications.showError(context, "Obtained marks must be between 0 and $maxMarks.");
      return;
    }

    context.read<FacultyCubit>().submitStudentMarks(
          assessmentId: _selectedAssessmentId!,
          scmId: scmId,
          marks: marks,
          remarks: remarks,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FacultyCubit, FacultyState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppNotifications.showError(context, state.errorMessage!);
          context.read<FacultyCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          AppNotifications.showSuccess(context, state.successMessage!);
          context.read<FacultyCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        // Extract distinct classes dynamically from student mappings
        final Map<int, String> classes = {};
        for (var student in state.studentsList) {
          if (student['class_id'] != null) {
            classes[student['class_id']] = "Class ${student['class_name'] ?? ''} - ${student['section'] ?? ''}";
          }
        }

        // Fetch selected assessment parameters
        final selectedAssessment = state.assessmentsList.firstWhere(
          (a) => a['id'] == _selectedAssessmentId,
          orElse: () => {},
        );
        final double maxMarks = (selectedAssessment['max_marks'] as num? ?? 100).toDouble();

        // Filter students who are in the selected class
        final currentStudents = state.studentsList.where((s) {
          return s['class_id'] == _selectedClassId;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Assessments Marks Entry",
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
                // 1. Dropdown Selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      children: [
                        CustomDropdown<int>(
                          value: _selectedClassId,
                          labelText: "Select Class",
                          prefixIcon: Icons.school_outlined,
                          items: classes.entries.map((e) {
                            return DropdownMenuItem<int>(value: e.key, child: Text(e.value));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClassId = val;
                            });
                          },
                        ),
                        AppSpacing.h12,
                        CustomDropdown<int>(
                          value: _selectedAssessmentId,
                          labelText: "Select Assessment Category",
                          prefixIcon: Icons.assessment_outlined,
                          items: state.assessmentsList.map((a) {
                            return DropdownMenuItem<int>(
                              value: a['id'] as int,
                              child: Text("${a['title'] ?? 'Test'} (Max: ${a['max_marks'] ?? 100})"),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedAssessmentId = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Entry List
                Expanded(
                  child: _selectedClassId == null || _selectedAssessmentId == null
                      ? const Center(
                          child: EmptyStateWidget(
                            title: "Select Parameters",
                            message: "Please choose a Class and Assessment category to enter scores.",
                          ),
                        )
                      : currentStudents.isEmpty
                          ? const Center(
                              child: EmptyStateWidget(
                                title: "No Students Found",
                                message: "There are no students enrolled in the selected class.",
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: currentStudents.length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.borderLight, height: 1.0),
                              itemBuilder: (context, index) {
                                final student = currentStudents[index];
                                final int scmId = student['student_class_mapping_id'] ?? 0;

                                // Initialize controllers for this student row
                                if (!_marksControllers.containsKey(scmId)) {
                                  _marksControllers[scmId] = TextEditingController();
                                  _remarksControllers[scmId] = TextEditingController(text: "Good");
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['student_name'] ?? 'Student Profile',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Roll No: ${student['roll_no'] ?? 'N/A'} • Adm: ${student['admission_no'] ?? ''}",
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      
                                      // Marks Input box
                                      Expanded(
                                        flex: 1,
                                        child: SizedBox(
                                          height: 48,
                                          child: TextField(
                                            controller: _marksControllers[scmId],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              hintText: "/${maxMarks.toStringAsFixed(0)}",
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Remarks Input box
                                      Expanded(
                                        flex: 1,
                                        child: SizedBox(
                                          height: 48,
                                          child: TextField(
                                            controller: _remarksControllers[scmId],
                                            decoration: const InputDecoration(
                                              hintText: "Remarks",
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Save trigger button
                                      IconButton.filled(
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.facultyPrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                        onPressed: () => _saveMarks(context, scmId, maxMarks),
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
