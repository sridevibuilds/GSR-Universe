// Presentation Layer - Progress Cards Page
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

class ProgressCardsPage extends StatefulWidget {
  const ProgressCardsPage({super.key});

  @override
  State<ProgressCardsPage> createState() => _ProgressCardsPageState();
}

class _ProgressCardsPageState extends State<ProgressCardsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  
  String _selectedClass = "Class 9";
  String _selectedSection = "A";
  int? _selectedStudentMappingId;
  File? _cardFile;

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
    context.read<FacultyCubit>().fetchProgressCards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _uploadCard(BuildContext context, int facultyId, int yearId) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudentMappingId == null) {
        AppNotifications.showError(context, "Please select a student.");
        return;
      }
      if (_cardFile == null) {
        AppNotifications.showError(context, "Please select a progress card PDF.");
        return;
      }

      context.read<FacultyCubit>().clearUploads();
      await context.read<FacultyCubit>().uploadHomeworkAttachment(_cardFile!);

      if (context.mounted) {
        final state = context.read<FacultyCubit>().state;
        if (state.uploadedFileUrl != null) {
          final payload = {
            "student_class_mapping_id": _selectedStudentMappingId!,
            "academic_year_id": yearId,
            "uploaded_by": facultyId,
            "file_name": state.uploadedFileName ?? "Progress Card.pdf",
            "file_path": state.uploadedFileUrl!,
            "remarks": _remarksController.text.trim().isEmpty ? "Progress Card" : _remarksController.text.trim(),
          };
          context.read<FacultyCubit>().uploadProgressCard(payload);
        }
      }
    }
  }

  void _confirmDeleteCard(Map<String, dynamic> card) {
    ConfirmationDialog.show(
      context,
      title: "Remove Progress Card",
      content: "Are you sure you want to delete the progress card file for ${card['student_name']}?",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeProgressCard(card['id']);
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
          "Progress Report Cards",
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
            Tab(icon: Icon(Icons.upload_file_outlined), text: "Upload Card"),
            Tab(icon: Icon(Icons.folder_open_outlined), text: "Report Feed"),
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
              if (state.successMessage!.contains("uploaded")) {
                _remarksController.clear();
                setState(() {
                  _cardFile = null;
                  _selectedStudentMappingId = null;
                });
                _tabController.animateTo(1);
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            // Filter class students locally
            final filteredStudents = state.studentsList.where((s) {
              return s['class_name'] == _selectedClass && s['section'] == _selectedSection;
            }).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Upload Card Form
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
                                  labelText: "Class Target",
                                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedClass = val;
                                        _selectedStudentMappingId = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedSection,
                                  labelText: "Section",
                                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedSection = val;
                                        _selectedStudentMappingId = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h12,
                          CustomDropdown<int>(
                            value: _selectedStudentMappingId,
                            labelText: "Select Student Profile",
                            prefixIcon: Icons.person_outline,
                            items: filteredStudents.map((s) {
                              return DropdownMenuItem<int>(
                                value: s['student_class_mapping_id'] as int,
                                child: Text(s['student_name'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedStudentMappingId = val),
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _remarksController,
                            labelText: "Remarks / Exam term description",
                            hintText: "e.g. Mid-Term Report Card",
                          ),
                          AppSpacing.h16,
                          FileUploader(
                            label: "Select Progress Card Document (PDF)",
                            onFileSelected: (file) {
                              setState(() => _cardFile = file);
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
                              onPressed: state.isLoading ? null : () => _uploadCard(context, facultyId, yearId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Upload Report Card", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Cards Feed
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<String>(
                                value: _selectedClass,
                                labelText: "Filter Class",
                                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedClass = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomDropdown<String>(
                                value: _selectedSection,
                                labelText: "Section",
                                items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSection = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: state.progressCardsList.isEmpty
                          ? const Center(
                              child: EmptyStateWidget(
                                title: "No Cards Uploaded",
                                message: "Report cards feed is currently empty.",
                              ),
                            )
                          : () {
                              final list = state.progressCardsList.where((c) {
                                final matchesClass = c['class_name'] == _selectedClass;
                                // In the progress report cards list API, check if section is present
                                final matchesSec = c['section'] == _selectedSection;
                                return matchesClass && matchesSec;
                              }).toList();

                              if (list.isEmpty) {
                                return const Center(
                                  child: EmptyStateWidget(
                                    title: "No Cards Found",
                                    message: "No report cards uploaded matching your filtered class parameters.",
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final card = list[index];
                                  final dateStr = card['uploaded_at'] != null
                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(card['uploaded_at']))
                                      : 'N/A';

                                  return Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    color: Colors.white,
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.success.withOpacity(0.1),
                                        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                      ),
                                      title: Text(
                                        card['student_name'] ?? 'Student Report Card',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      subtitle: Text(
                                        "Term: ${card['remarks'] ?? 'Report'} • Date: $dateStr",
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                        onPressed: () => _confirmDeleteCard(card),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }(),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
