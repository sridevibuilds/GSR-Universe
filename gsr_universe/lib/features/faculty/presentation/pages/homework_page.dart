// Presentation Layer - Homework Management Console (Draft, Published, Expired)
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

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedClass = "Class 9";
  String _selectedSection = "A";
  String _selectedSubject = "Maths";
  File? _attachmentFile;
  String _homeworkStatus = "Published"; // Published or Draft

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];
  final List<String> _subjects = [
    "Telugu", "Sanskrit", "Hindi", "English", "Maths", "Biology", "Physics", "Zoology", "Social"
  ];


  String _subClass = "Class 9";
  String _subSection = "A";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchHomework();
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

  void _submitHomework(BuildContext context, int facultyId, int yearId) async {
    if (_formKey.currentState!.validate()) {
      final String title = _titleController.text.trim();
      final String desc = _descController.text.trim();
      final String dueDate = _dateController.text.trim();

      context.read<FacultyCubit>().clearUploads();

      if (_attachmentFile != null) {
        await context.read<FacultyCubit>().uploadHomeworkAttachment(_attachmentFile!);
      }

      if (context.mounted) {
        context.read<FacultyCubit>().publishHomework(
              className: _selectedClass,
              section: _selectedSection,
              subjectName: _selectedSubject,
              yearId: yearId,
              title: title,
              description: desc,
              dueDate: dueDate,
              facultyId: facultyId,
              status: _homeworkStatus,
            );
      }
    }
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
        final endpoint = "${ApiClient.defaultBaseUrl}/api/homework/submissions/$submissionId/view";
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
        debugPrint("Backend Homework Submission View API error: $e");
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



    if (bytes != null && bytes.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
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

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    int facultyId = 1;
    if (authState is AuthAuthenticated) {
      facultyId = authState.payload['id'] ?? 1;
    }
    const int yearId = 1; // 2024-2025 (ID 1)

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Homework",
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
            Tab(icon: Icon(Icons.file_download_done_outlined), text: "Submitted Homework"),
            Tab(icon: Icon(Icons.check_circle_outline), text: "Published"),
            Tab(icon: Icon(Icons.drafts_outlined), text: "Drafts"),
            Tab(icon: Icon(Icons.history_toggle_off_outlined), text: "Expired"),
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
              if (state.successMessage!.contains("assigned") || state.successMessage!.contains("Homework")) {
                _titleController.clear();
                _descController.clear();
                _dateController.clear();
                setState(() {
                  _attachmentFile = null;
                });
                if (_homeworkStatus == "Draft") {
                  _tabController.animateTo(3); // Jump to Drafts
                } else {
                  _tabController.animateTo(2); // Jump to Published
                }
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            // Distinct classes from student mappings
            final Map<int, String> classMap = {};
            for (var student in state.studentsList) {
              if (student['class_id'] != null) {
                classMap[student['class_id']] = "Class ${student['class_name'] ?? ''} - ${student['section'] ?? ''}";
              }
            }

            final publishedHw = state.homeworkList.where((h) {
              final due = h['due_date'] != null ? DateTime.tryParse(h['due_date']) : null;
              final isExpired = due != null && due.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              return (h['status'] == 'Published' || h['status'] == null) && !isExpired;
            }).toList();

            final draftHw = state.homeworkList.where((h) => h['status'] == 'Draft').toList();

            final expiredHw = state.homeworkList.where((h) {
              final due = h['due_date'] != null ? DateTime.tryParse(h['due_date']) : null;
              final isExpired = due != null && due.isBefore(DateTime.now().subtract(const Duration(days: 1)));
              return isExpired && (h['status'] == 'Published' || h['status'] == null);
            }).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Assign Homework Form
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
                          CustomDropdown<String>(
                            value: _selectedSubject,
                            labelText: "Subject Target",
                            items: _subjects.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                            onChanged: (val) => setState(() => _selectedSubject = val ?? _subjects.first),
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Homework Title",
                            hintText: "e.g. Geometry Exercise 1.1",
                            validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _descController,
                            labelText: "Detailed Instructions",
                            hintText: "Instructions or questions...",
                            validator: (val) => val == null || val.isEmpty ? "Instructions are required" : null,
                          ),
                          AppSpacing.h12,
                          GestureDetector(
                            onTap: () => _selectDueDate(context),
                            child: AbsorbPointer(
                              child: CustomTextField(
                                controller: _dateController,
                                labelText: "Submission Due Date",
                                prefixIcon: Icons.calendar_month_outlined,
                                validator: (val) => val == null || val.isEmpty ? "Due date required" : null,
                              ),
                            ),
                          ),
                          AppSpacing.h12,
                          FileUploader(
                            label: "Reference Document / Image (Optional)",
                            onFileSelected: (file) {
                              setState(() {
                                _attachmentFile = file;
                              });
                            },
                          ),
                          AppSpacing.h16,
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(color: AppColors.facultyPrimary),
                                  ),
                                  onPressed: state.isLoading
                                      ? null
                                      : () {
                                          setState(() => _homeworkStatus = "Draft");
                                          _submitHomework(context, facultyId, yearId);
                                        },
                                  child: Text("Save as Draft", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.facultyPrimary)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.facultyPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: state.isLoading
                                      ? null
                                      : () {
                                          setState(() => _homeworkStatus = "Published");
                                          _submitHomework(context, facultyId, yearId);
                                        },
                                  child: state.isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                      : Text("Publish Task", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Submitted Homework Tracker
                _SubmittedHomeworkTab(
                  classes: _classes,
                  sections: _sections,
                  selectedClass: _subClass,
                  selectedSection: _subSection,
                  onClassChanged: (val) => setState(() => _subClass = val),
                  onSectionChanged: (val) => setState(() => _subSection = val),
                ),

                // TAB 3: Published Feed
                _HomeworkFeedList(list: publishedHw),

                // TAB 4: Drafts Feed
                _HomeworkFeedList(list: draftHw),

                // TAB 5: Expired Feed
                _HomeworkFeedList(list: expiredHw),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeworkFeedList extends StatelessWidget {
  final List<Map<String, dynamic>> list;

  const _HomeworkFeedList({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: "Feed is Empty",
          message: "No homework tasks found under this category.",
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final hw = list[index];
        final String dateStr = hw['due_date'] != null
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(hw['due_date']))
            : 'N/A';
        final hasAttachment = hw['attachment_name'] != null && hw['attachment_name'].toString().isNotEmpty;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.facultyPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Class ${hw['class_name'] ?? ''} - ${hw['section'] ?? ''}",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.facultyPrimary,
                        ),
                      ),
                    ),
                    if (hw['subject_name'] != null && hw['subject_name'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hw['subject_name'],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      "Due: $dateStr",
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                      onPressed: () {
                        ConfirmationDialog.show(
                          context,
                          title: "Delete Homework",
                          content: "Are you sure you want to permanently delete this homework assignment?",
                          confirmText: "Delete",
                          confirmColor: AppColors.danger,
                          onConfirm: () {
                            context.read<FacultyCubit>().removeHomework(hw['id']);
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hw['title'] ?? 'Homework Assignment',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  hw['description'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                ),
                if (hasAttachment) ...[
                  const SizedBox(height: 12),
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
                            hw['attachment_name'] ?? 'attachment.pdf',
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
          ),
        );
      },
    );
  }
}

class _SubmittedHomeworkTab extends StatefulWidget {
  final List<String> classes;
  final List<String> sections;
  final String selectedClass;
  final String selectedSection;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onSectionChanged;

  const _SubmittedHomeworkTab({
    super.key,
    required this.classes,
    required this.sections,
    required this.selectedClass,
    required this.selectedSection,
    required this.onClassChanged,
    required this.onSectionChanged,
  });

  @override
  State<_SubmittedHomeworkTab> createState() => _SubmittedHomeworkTabState();
}

class _SubmittedHomeworkTabState extends State<_SubmittedHomeworkTab> {
  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void didUpdateWidget(covariant _SubmittedHomeworkTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedClass != widget.selectedClass || oldWidget.selectedSection != widget.selectedSection) {
      _loadSubmissions();
    }
  }

  void _loadSubmissions() {
    context.read<FacultyCubit>().fetchHomeworkSubmissions(
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
          title: Text("Submitted File Preview", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                  color: AppColors.facultyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: AppColors.facultyPrimary),
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
                final pageState = context.findAncestorStateOfType<_HomeworkPageState>();
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
        // Use real backend homework submissions strictly
        final List<Map<String, dynamic>> sourceList = state.homeworkSubmissions;

        // Deduplicate submissions list by student and homework
        final Map<String, Map<String, dynamic>> uniqueMap = {};
        for (var s in sourceList) {
          final studentKey = s['student_id'] ?? s['admission_no'] ?? 'student';
          final hwKey = s['homework_id'] ?? s['homework_title'] ?? 'hw';
          final key = "${studentKey}_$hwKey";
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
                            message: "Select a class and section to view submitted student homework.",
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: students.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final int? submissionId = student['id'] is int ? student['id'] as int : int.tryParse(student['id']?.toString() ?? '');
                            final String fileName = student['file_name'] ?? "Homework_Solution_${student['admission_no'] ?? '101'}.pdf";
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
                                        backgroundColor: AppColors.facultyPrimary.withValues(alpha: 0.1),
                                        child: Text(
                                          (student['student_name'] ?? 'S')[0],
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.facultyPrimary),
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
                                      const Icon(Icons.description_outlined, size: 16, color: AppColors.facultyPrimary),
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
                                          final pageState = context.findAncestorStateOfType<_HomeworkPageState>();
                                          pageState?._openOrDownloadFile(context, fileName: fileName, filePath: filePath, submissionId: submissionId);
                                        },
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
        );
      },
    );
  }
}
