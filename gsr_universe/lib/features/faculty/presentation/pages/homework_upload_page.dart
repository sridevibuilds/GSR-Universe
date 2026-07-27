// Presentation Layer - Homework Assignment Console
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/file_uploader.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class HomeworkUploadPage extends StatefulWidget {
  const HomeworkUploadPage({super.key});

  @override
  State<HomeworkUploadPage> createState() => _HomeworkUploadPageState();
}

class _HomeworkUploadPageState extends State<HomeworkUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  
  int? _selectedClassId;
  int? _selectedSubjectId = 1; // Default Subject ID 1 (Mathematics)
  File? _attachmentFile;

  @override
  void initState() {
    super.initState();
    // Fetch students roster list and active homework entries
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchHomework();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.facultyPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _publish(BuildContext context, int facultyId, int yearId, Map<int, String> classes) async {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text.trim();
      final String desc = _descController.text.trim();
      final String dueDate = _dateController.text.trim();

      // Clear previous upload states
      context.read<FacultyCubit>().clearUploads();

      // If attachment exists, upload it first
      if (_attachmentFile != null) {
        await context.read<FacultyCubit>().uploadHomeworkAttachment(_attachmentFile!);
      }

      final classString = classes[_selectedClassId!];
      String className = "Class 9";
      String section = "A";
      if (classString != null) {
        final parts = classString.split(" - ");
        if (parts.length == 2) {
          className = parts[0];
          section = parts[1];
        }
      }

      final Map<int, String> subjects = {
        1: "Mathematics",
        2: "General Science",
        3: "English",
      };
      final String subjectName = subjects[_selectedSubjectId!] ?? "Mathematics";

      // Submit homework details with resolved attachment paths
      if (context.mounted) {
        context.read<FacultyCubit>().publishHomework(
              className: className,
              section: section,
              subjectName: subjectName,
              title: title,
              description: desc,
              dueDate: dueDate,
              facultyId: facultyId,
              yearId: yearId,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    int facultyId = 1;
    if (authState is AuthAuthenticated) {
      facultyId = authState.payload['id'] ?? 1;
    }
    final int yearId = 1; // Default Academic Year 2024-2025 (ID 1)

    return BlocConsumer<FacultyCubit, FacultyState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppNotifications.showError(context, state.errorMessage!);
          context.read<FacultyCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          AppNotifications.showSuccess(context, state.successMessage!);
          
          if (state.successMessage!.contains("assigned")) {
            _titleController.clear();
            _descController.clear();
            _dateController.clear();
            setState(() {
              _attachmentFile = null;
            });
          }
          context.read<FacultyCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        // Extract distinct classes dynamically
        final Map<int, String> classes = {};
        for (var student in state.studentsList) {
          if (student['class_id'] != null) {
            classes[student['class_id']] = "Class ${student['class_name'] ?? ''} - ${student['section'] ?? ''}";
          }
        }

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Assign Homework",
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Publishing form card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_outlined, color: AppColors.facultyPrimary),
                              const SizedBox(width: 8),
                              Text(
                                "Publish Parameters",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          AppSpacing.h16,
                          Row(
                            children: [
                              Expanded(
                                child: CustomDropdown<int>(
                                  value: _selectedClassId,
                                  labelText: "Target Class",
                                  items: classes.entries.map((e) {
                                    return DropdownMenuItem<int>(value: e.key, child: Text(e.value));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedClassId = val),
                                  validator: (val) => val == null ? "Required" : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomDropdown<int>(
                                  value: _selectedSubjectId,
                                  labelText: "Subject",
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text("Mathematics")),
                                    DropdownMenuItem(value: 2, child: Text("General Science")),
                                    DropdownMenuItem(value: 3, child: Text("English")),
                                  ],
                                  onChanged: (val) => setState(() => _selectedSubjectId = val),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Homework Title",
                            hintText: "e.g. Algebra Exercise 4.2",
                            validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _descController,
                            labelText: "Detailed Instructions",
                            hintText: "Specify questions, formulas, or reading pages...",
                            validator: (val) => val == null || val.isEmpty ? "Instructions are required" : null,
                          ),
                          AppSpacing.h12,
                          GestureDetector(
                            onTap: () => _selectDueDate(context),
                            child: AbsorbPointer(
                              child: CustomTextField(
                                controller: _dateController,
                                labelText: "Submission Deadline",
                                prefixIcon: Icons.calendar_month_outlined,
                                validator: (val) => val == null || val.isEmpty ? "Submission due date is required" : null,
                              ),
                            ),
                          ),
                          AppSpacing.h16,
                          
                          // Custom File Uploader from component library
                          FileUploader(
                            label: "Reference Document / Image (Optional)",
                            onFileSelected: (file) {
                              setState(() {
                                _attachmentFile = file;
                              });
                            },
                          ),
                          AppSpacing.h20,

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.facultyPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: state.isLoading ? null : () => _publish(context, facultyId, yearId, classes),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text(
                                      "Publish Assignment",
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.h24,

                  // 2. Published log feed list
                  Text(
                    "Published Assignments Feed",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                  ),
                  AppSpacing.h12,
                  state.homeworkList.isEmpty
                      ? const EmptyStateWidget(
                          title: "No Homework Assigned",
                          message: "Your assigned tasks will list here.",
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.homeworkList.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.borderLight, height: 1.0),
                          itemBuilder: (context, index) {
                            final hw = state.homeworkList[index];
                            final String dateStr = hw['due_date'] != null
                                ? DateFormat('dd MMM yyyy').format(DateTime.parse(hw['due_date']))
                                : 'N/A';
                            final hasAttachment = hw['attachment_name'] != null && hw['attachment_name'].toString().isNotEmpty;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.facultyPrimary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          "Class ${hw['class_name'] ?? ''} - ${hw['section'] ?? ''}",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.facultyPrimary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "Due: $dateStr",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppSpacing.h12,
                                  Text(
                                    hw['title'] ?? 'Homework Task',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                  ),
                                  AppSpacing.h4,
                                  Text(
                                    hw['description'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                                  ),
                                  if (hasAttachment) ...[
                                    AppSpacing.h12,
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.pageBackground,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.borderLight),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.attachment, size: 16, color: AppColors.textLight),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              hw['attachment_name'] ?? 'attachment',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
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
