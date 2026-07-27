// Presentation Layer - Timetables Manager Page
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

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedClass = "Class 9";
  String _selectedSection = "A";
  File? _timetableFile;

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchTimetables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _uploadTimetable(BuildContext context, int facultyId, int yearId) async {
    if (_formKey.currentState!.validate()) {
      if (_timetableFile == null) {
        AppNotifications.showError(context, "Please select a timetable image or PDF.");
        return;
      }

      context.read<FacultyCubit>().clearUploads();
      await context.read<FacultyCubit>().uploadHomeworkAttachment(_timetableFile!);

      if (context.mounted) {
        final state = context.read<FacultyCubit>().state;
        if (state.uploadedFileUrl != null) {
          final payload = {
            "class_name": _selectedClass,
            "section": _selectedSection,
            "academic_year_id": yearId,
            "title": _titleController.text.trim(),
            "file_name": state.uploadedFileName ?? "Timetable.pdf",
            "file_path": state.uploadedFileUrl!,
            "uploaded_by": facultyId,
            "remarks": _remarksController.text.trim(),
          };
          context.read<FacultyCubit>().uploadTimetable(payload);
        }
      }
    }
  }

  void _confirmDeleteTimetable(Map<String, dynamic> timetable) {
    ConfirmationDialog.show(
      context,
      title: "Delete Timetable",
      content: "Are you sure you want to delete the class timetable '${timetable['title']}'?",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeTimetable(timetable['id']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    int facultyId = 1;
    if (authState is AuthAuthenticated) {
      facultyId = authState.payload['id'] ?? 1;
    }
    const int yearId = 1; // Term 2024-2025

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Timetable Manager",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.facultyPrimary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.facultyPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file_outlined), text: "Upload Timetable"),
            Tab(icon: Icon(Icons.calendar_view_day_outlined), text: "Timetables Log"),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<FacultyCubit, FacultyState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              AppNotifications.showError(context, state.errorMessage!);
              context.read<FacultyCubit>().clearMessages();
            }
            if (state.successMessage != null) {
              AppNotifications.showSuccess(context, state.successMessage!);
              if (state.successMessage!.contains("uploaded") || state.successMessage!.contains("Timetable")) {
                _titleController.clear();
                _remarksController.clear();
                 setState(() {
                  _timetableFile = null;
                });
                _tabController.animateTo(1);
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            // Extract distinct classes dynamically
            final Map<int, String> classMap = {};
            for (var student in state.studentsList) {
              if (student['class_id'] != null) {
                classMap[student['class_id']] = "Class ${student['class_name'] ?? ''} - ${student['section'] ?? ''}";
              }
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Upload Timetable Form
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(
                            children: [
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedClass,
                                  labelText: "Target Class",
                                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) => setState(() => _selectedClass = val ?? _classes.first),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedSection,
                                  labelText: "Section",
                                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                                  onChanged: (val) => setState(() => _selectedSection = val ?? _sections.first),
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Timetable Title / Version",
                            hintText: "e.g. Term 1 Class Timetable",
                            validator: (val) => val == null || val.isEmpty ? "Title required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _remarksController,
                            labelText: "Remarks / Additional Notes",
                            hintText: "e.g. Valid from July 2026",
                          ),
                          AppSpacing.h16,
                          FileUploader(
                            label: "Upload Timetable Document (PDF/Image)",
                            onFileSelected: (file) {
                              setState(() => _timetableFile = file);
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
                              onPressed: state.isLoading ? null : () => _uploadTimetable(context, facultyId, yearId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Upload Timetable File", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Timetables Log
                state.timetableList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "No Timetables Configured",
                          message: "Upload a new timetable file using the Upload tab.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.timetableList.length,
                        itemBuilder: (context, index) {
                          final t = state.timetableList[index];
                          final dateStr = t['uploaded_at'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(t['uploaded_at']))
                              : 'N/A';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.adminPrimary.withOpacity(0.1),
                                child: const Icon(Icons.calendar_month, color: AppColors.adminPrimary),
                              ),
                              title: Text(
                                t['title'] ?? 'Class Timetable',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              subtitle: Text(
                                "Target: Class ${t['class_name'] ?? ''} - ${t['section'] ?? ''} • uploaded: $dateStr\nNotes: ${t['remarks'] ?? 'None'}",
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: () => _confirmDeleteTimetable(t),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
