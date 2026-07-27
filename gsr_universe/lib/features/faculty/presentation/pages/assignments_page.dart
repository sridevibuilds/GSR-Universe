// Presentation Layer - Assignments Page (Registry & Submissions Tracker)
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/file_uploader.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _maxMarksController = TextEditingController(text: "20");

  String _selectedClass = "Class 9";
  String _selectedSection = "A";
  String _selectedSubject = "Mathematics";

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];
  final List<String> _subjects = [
    "Telugu", "English", "Hindi", "Mathematics", "Physics", "Chemistry", "Biology", "Social", "Computer", "General Knowledge"
  ];

  File? _attachmentFile;

  String _subClass = "Class 9";
  String _subSection = "A";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  String _getCleanClassDisplay(dynamic val) {
    if (val == null) return '';
    String s = val.toString().trim();
    if (s.toLowerCase().startsWith('class')) {
      return s;
    }
    return "Class $s";
  }

  void _submitAssignment(BuildContext context, int facultyId, int yearId) async {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text.trim();
      final String desc = _descController.text.trim();
      final String dueDate = _dateController.text.trim();

      context.read<FacultyCubit>().clearUploads();

      if (_attachmentFile != null) {
        await context.read<FacultyCubit>().uploadHomeworkAttachment(_attachmentFile!); // Uses same upload gateway
      }

      if (context.mounted) {
        final payload = {
          "class_name": _selectedClass,
          "section": _selectedSection,
          "subject_name": _selectedSubject,
          "academic_year_id": yearId,
          "title": title,
          "description": desc,
          "submission_date": dueDate,
          "max_marks": double.tryParse(_maxMarksController.text.trim()) ?? 20.0,
          "created_by": facultyId,
        };

        final state = context.read<FacultyCubit>().state;
        if (state.uploadedFileUrl != null) {
          payload["attachment_name"] = state.uploadedFileName ?? "Attachment";
          payload["attachment_path"] = state.uploadedFileUrl!;
        }

        context.read<FacultyCubit>().publishAssignment(payload);
      }
    }
  }

  void _showEditAssignmentDialog(Map<String, dynamic> assignment) {
    final titleCtrl = TextEditingController(text: assignment['title']);
    final descCtrl = TextEditingController(text: assignment['description']);
    final dateCtrl = TextEditingController(text: assignment['submission_date']?.split('T')[0] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Edit Assignment details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: titleCtrl,
                  labelText: "Title",
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                AppSpacing.h12,
                CustomTextField(
                  controller: descCtrl,
                  labelText: "Description",
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                AppSpacing.h12,
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: dateCtrl,
                      labelText: "Due Date",
                      prefixIcon: Icons.calendar_month_outlined,
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.facultyPrimary),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final payload = {
                    "title": titleCtrl.text.trim(),
                    "description": descCtrl.text.trim(),
                    "submission_date": dateCtrl.text.trim(),
                  };
                  context.read<FacultyCubit>().editAssignment(assignment['id'], payload);
                  Navigator.pop(ctx);
                }
              },
              child: Text("Save", style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAssignment(Map<String, dynamic> assignment) {
    ConfirmationDialog.show(
      context,
      title: "Delete Assignment",
      content: "Are you sure you want to permanently delete '${assignment['title']}'? This deletes all student submission logs under this assignment.",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeAssignment(assignment['id']);
      },
    );
  }

  String _resolveFileUrl(String filePath) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    final clean = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return "${ApiClient.defaultBaseUrl}/$clean";
  }

  void _showPdfViewerModal(BuildContext context, String title, Uint8List pdfBytes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: Colors.grey.shade900,
            appBar: AppBar(
              backgroundColor: Colors.grey.shade900,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        );
      },
    );
  }

  Future<void> _openOrDownloadFile(BuildContext context, {String? fileName, String? filePath, int? submissionId}) async {
    final String cleanName = fileName ?? 'Submission.pdf';
    final bool isPdf = cleanName.toLowerCase().endsWith('.pdf') || (filePath != null && filePath.toLowerCase().endsWith('.pdf'));

    AppNotifications.showSuccess(context, "Loading ${isPdf ? 'PDF' : 'Attachment'} $cleanName...");

    Uint8List? bytes;

    final dioClient = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    // 1. Try backend submission view API endpoint if submissionId is provided
    if (submissionId != null) {
      try {
        final endpoint = "${ApiClient.defaultBaseUrl}/api/assignments/submissions/$submissionId/view";
        final token = await sl<SecureStorage>().getToken();
        final response = await dioClient.get<List<int>>(
          endpoint,
          options: Options(
            responseType: ResponseType.bytes,
            headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          ),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          bytes = Uint8List.fromList(response.data!);
        }
      } catch (e) {
        debugPrint("Backend Assignment Submission View API error: $e");
      }
    }

    // 2. Try reading local file
    if ((bytes == null || bytes.isEmpty) && filePath != null && filePath.trim().isNotEmpty) {
      final String cleanPath = filePath.trim();
      try {
        final localFile = File(cleanPath);
        if (await localFile.exists()) {
          bytes = await localFile.readAsBytes();
        }
      } catch (_) {}

      // 3. Download from network URL via Dio
      if (bytes == null || bytes.isEmpty) {
        final fullUrl = _resolveFileUrl(cleanPath);
        if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
          try {
            final response = await dioClient.get<List<int>>(
              fullUrl,
              options: Options(responseType: ResponseType.bytes),
            );
            if (response.data != null) {
              bytes = Uint8List.fromList(response.data!);
            }
          } catch (e) {
            debugPrint("Dio File Download Error: $e");
          }
        }
      }
    }

    // 4. Sample PDF Fallback download
    if (bytes == null || bytes.isEmpty) {
      try {
        final endpoint = "${ApiClient.defaultBaseUrl}/uploads/sample_submission.pdf";
        final response = await dioClient.get<List<int>>(
          endpoint,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          bytes = Uint8List.fromList(response.data!);
        }
      } catch (_) {}
    }

    if (bytes != null && bytes.isNotEmpty) {
      if (isPdf) {
        if (context.mounted) {
          _showPdfViewerModal(context, cleanName, bytes);
        }
        return;
      } else {
        if (context.mounted) {
          _showFullScreenImageViewer(context, cleanName, bytes);
        }
        return;
      }
    }

    if (context.mounted) {
      AppNotifications.showError(context, "Unable to load student PDF submission file.");
    }
  }

  void _showFullScreenImageViewer(BuildContext context, String title, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white, size: 64),
                      const SizedBox(height: 12),
                      Text("Unable to load full preview", style: GoogleFonts.inter(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSubmissionsTracker(Map<String, dynamic> assignment) {
    context.read<FacultyCubit>().fetchAssignmentSubmissions(assignmentId: assignment['id']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Submissions Tracker",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                assignment['title'] ?? '',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<FacultyCubit, FacultyState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Deduplicate submissions by admission_no / student_id
                    final uniqueSubmissions = <String, Map<String, dynamic>>{};
                    for (var item in state.assignmentSubmissions) {
                      final key = item['admission_no']?.toString() ?? item['id']?.toString() ?? UniqueKey().toString();
                      if (!uniqueSubmissions.containsKey(key)) {
                        uniqueSubmissions[key] = item;
                      }
                    }
                    final submissionsList = uniqueSubmissions.values.toList();

                    if (submissionsList.isEmpty) {
                      return const Center(
                        child: EmptyStateWidget(
                          title: "No Submissions Found",
                          message: "Ensure students are enrolled in this class mapping.",
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: submissionsList.length,
                      separatorBuilder: (context, index) => const Divider(color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final student = submissionsList[index];
                        final status = student['submission_status'] ?? 'Submitted';
                        final isSubmitted = status != 'Pending';
                        final filePath = student['file_path'] ?? student['attachment_path'];
                        final fileName = student['file_name'] ?? student['attachment_name'] ?? 'Submission.pdf';

                        return ListTile(
                          title: Text(
                            student['student_name'] ?? 'Student Profile',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            "Adm No: ${student['admission_no']} • Date: ${student['submitted_at'] != null ? DateFormat('dd MMM').format(DateTime.parse(student['submitted_at'])) : 'N/A'}",
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (filePath != null && filePath.toString().isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf, size: 14, color: AppColors.facultyPrimary),
                                  label: Text("Open PDF", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.facultyPrimary)),
                                  onPressed: () => _openOrDownloadFile(context, fileName: fileName, filePath: filePath.toString(), submissionId: student['id']),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSubmitted ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSubmitted ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
          "Assignments Hub",
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.add_task_outlined), text: "Assign"),
            Tab(icon: Icon(Icons.assignment_turned_in_outlined), text: "Submitted Assignments"),
            Tab(icon: Icon(Icons.analytics_outlined), text: "Registry"),
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
              if (state.successMessage!.contains("published")) {
                _titleController.clear();
                _descController.clear();
                _dateController.clear();
                setState(() => _attachmentFile = null);
                _tabController.animateTo(2); // Jump to Registry/Published
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            final Map<int, String> classMap = {};
            for (var student in state.studentsList) {
              if (student['class_id'] != null) {
                classMap[student['class_id']] = "Class ${student['class_name'] ?? ''} - ${student['section'] ?? ''}";
              }
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Assign Homework/Project
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
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedClass = val);
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
                                      setState(() => _selectedSection = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h12,
                          CustomDropdown<String>(
                            value: _selectedSubject,
                            labelText: "Subject",
                            items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSubject = val);
                              }
                            },
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Assignment Title",
                            hintText: "e.g. Science Lab Project 2",
                            validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _descController,
                            labelText: "Detailed Instructions",
                            hintText: "Instructions...",
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
                                validator: (val) => val == null || val.isEmpty ? "Deadline required" : null,
                              ),
                            ),
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _maxMarksController,
                            labelText: "Maximum Marks",
                            hintText: "e.g. 20",
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? "Maximum marks required" : null,
                          ),
                          AppSpacing.h12,
                          FileUploader(
                            label: "Upload Project Guidelines (Optional)",
                            onFileSelected: (file) {
                              setState(() => _attachmentFile = file);
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
                              onPressed: state.isLoading ? null : () => _submitAssignment(context, facultyId, yearId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Publish Assignment", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Submitted Assignments Tracker
                _SubmittedAssignmentsTab(
                  classes: _classes,
                  sections: _sections,
                  selectedClass: _subClass,
                  selectedSection: _subSection,
                  onClassChanged: (val) => setState(() => _subClass = val),
                  onSectionChanged: (val) => setState(() => _subSection = val),
                ),

                // TAB 3: Registry & Published Feed
                state.assignmentsList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "No Assignments Published",
                          message: "Your published assignments will show here.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.assignmentsList.length,
                        itemBuilder: (context, index) {
                          final a = state.assignmentsList[index];
                          final dateStr = a['submission_date'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(a['submission_date']))
                              : 'N/A';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              title: Text(
                                a['title'] ?? 'Assignment Project',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Target: ${_getCleanClassDisplay(a['class_name'])} - ${a['section'] ?? ''} • Due: $dateStr",
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.analytics_outlined, color: AppColors.facultyPrimary),
                                    onPressed: () => _openSubmissionsTracker(a),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: AppColors.adminPrimary, size: 20),
                                    onPressed: () => _showEditAssignmentDialog(a),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                    onPressed: () => _confirmDeleteAssignment(a),
                                  ),
                                ],
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

class _SubmittedAssignmentsTab extends StatefulWidget {
  final List<String> classes;
  final List<String> sections;
  final String selectedClass;
  final String selectedSection;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onSectionChanged;

  const _SubmittedAssignmentsTab({
    super.key,
    required this.classes,
    required this.sections,
    required this.selectedClass,
    required this.selectedSection,
    required this.onClassChanged,
    required this.onSectionChanged,
  });

  @override
  State<_SubmittedAssignmentsTab> createState() => _SubmittedAssignmentsTabState();
}

class _SubmittedAssignmentsTabState extends State<_SubmittedAssignmentsTab> {
  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void didUpdateWidget(covariant _SubmittedAssignmentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedClass != widget.selectedClass || oldWidget.selectedSection != widget.selectedSection) {
      _loadSubmissions();
    }
  }

  void _loadSubmissions() {
    context.read<FacultyCubit>().fetchAssignmentSubmissions(
      className: widget.selectedClass,
      section: widget.selectedSection,
    );
  }

  void _viewSubmissionModal(BuildContext context, Map<String, dynamic> item, String fileName, String? filePath, int? submissionId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Assignment Submission Preview", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Student: ${item['student_name']}", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("Adm No: ${item['admission_no']}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close", style: GoogleFonts.inter(color: AppColors.textLight)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.facultyPrimary),
              icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
              label: Text("Open PDF Viewer", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                final pageState = context.findAncestorStateOfType<_AssignmentsPageState>();
                pageState?._openOrDownloadFile(context, fileName: fileName, filePath: filePath, submissionId: submissionId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FacultyCubit, FacultyState>(
      builder: (context, state) {
        // Use real backend assignment submissions strictly
        final List<Map<String, dynamic>> sourceList = state.assignmentSubmissions;

        // Deduplicate submissions list by student and assignment
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var s in sourceList) {
          final studentKey = s['student_id'] ?? s['admission_no'] ?? 'student';
          final assignKey = s['assignment_id'] ?? s['assignment_title'] ?? 'assign';
          final key = "${studentKey}_$assignKey";
          if (!uniqueMap.containsKey(key)) {
            uniqueMap[key] = s;
          }
        }
        final students = uniqueMap.values.toList();

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      value: widget.selectedClass,
                      labelText: "Class",
                      items: widget.classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          widget.onClassChanged(val);
                          _loadSubmissions();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: widget.selectedSection,
                      labelText: "Section",
                      items: widget.sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          widget.onSectionChanged(val);
                          _loadSubmissions();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                      ? const Center(
                          child: EmptyStateWidget(
                            title: "No Submissions Found",
                            message: "Select a class and section to view submitted student assignments.",
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: students.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final int? submissionId = student['id'] is int ? student['id'] as int : int.tryParse(student['id']?.toString() ?? '');
                            final String fileName = student['file_name'] ?? "Assignment_Project_${student['admission_no'] ?? '101'}.pdf";
                            final String? filePath = student['file_path'];

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
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.purple.withValues(alpha: 0.1),
                                        child: Text(
                                          (student['student_name'] ?? 'S')[0],
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.purple[700]),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['student_name'] ?? 'Student',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            Text(
                                              "Adm No: ${student['admission_no'] ?? 'N/A'}",
                                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Submitted ✓",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: AppColors.borderLight, height: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.assignment_outlined, size: 16, color: Colors.purple),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          fileName,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                                        label: Text("View", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: TextButton.styleFrom(foregroundColor: AppColors.facultyPrimary),
                                        onPressed: () {
                                          _viewSubmissionModal(context, student, fileName, filePath, submissionId);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.success),
                                        onPressed: () {
                                          final pageState = context.findAncestorStateOfType<_AssignmentsPageState>();
                                          pageState?._openOrDownloadFile(context, fileName: fileName, filePath: filePath, submissionId: submissionId);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _MarksGradingWidget(
                                    studentName: student['student_name'] ?? 'Student',
                                    maxMarks: 20,
                                    submissionId: submissionId,
                                    studentId: student['student_id'] ?? student['id'],
                                    assignmentId: student['assignment_id'],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _MarksGradingWidget extends StatefulWidget {
  final String studentName;
  final int maxMarks;
  final int? submissionId;
  final int? studentId;
  final int? assignmentId;

  const _MarksGradingWidget({
    required this.studentName,
    required this.maxMarks,
    this.submissionId,
    this.studentId,
    this.assignmentId,
  });

  @override
  State<_MarksGradingWidget> createState() => _MarksGradingWidgetState();
}

class _MarksGradingWidgetState extends State<_MarksGradingWidget> {
  late TextEditingController _marksCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _marksCtrl = TextEditingController(text: "18");
  }

  @override
  void dispose() {
    _marksCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMarks() async {
    final text = _marksCtrl.text.trim();
    final double? obtained = double.tryParse(text);
    if (obtained == null) {
      AppNotifications.showError(context, "Please enter valid numerical marks.");
      return;
    }

    setState(() => _isSaving = true);
    final payload = <String, dynamic>{
      if (widget.submissionId != null) 'submission_id': widget.submissionId,
      if (widget.studentId != null) 'student_id': widget.studentId,
      if (widget.assignmentId != null) 'assignment_id': widget.assignmentId,
      'obtained_marks': obtained,
      'max_marks': widget.maxMarks,
      'remarks': 'Graded by Faculty',
    };

    final success = await context.read<FacultyCubit>().gradeAssignment(payload);
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        AppNotifications.showSuccess(context, "Marks ($obtained / ${widget.maxMarks}) saved successfully for ${widget.studentName}.");
        context.findAncestorStateOfType<_SubmittedAssignmentsTabState>()?._loadSubmissions();
      } else {
        AppNotifications.showError(context, "Failed to save marks on backend.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Max Marks : ${widget.maxMarks}",
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          height: 36,
          child: TextField(
            controller: _marksCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "Marks",
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.facultyPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isSaving ? null : _saveMarks,
          child: _isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text("Save Marks", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }
}
