// Presentation Layer - Parent View Homework Screen (Two Tabs - Fixed Local/Network File Viewer & Interactive Full Screen Preview)
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../../core/widgets/file_uploader.dart';
import '../../data/models/homework_model.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentHomeworkPage extends StatefulWidget {
  const ParentHomeworkPage({super.key});

  @override
  State<ParentHomeworkPage> createState() => _ParentHomeworkPageState();
}

class _ParentHomeworkPageState extends State<ParentHomeworkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSubject = 'All Subjects';

  final List<String> _subjectsList = [
    'All Subjects',
    'Telugu',
    'Hindi',
    'English',
    'Sanskrit',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Zoology',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _resolveFileUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return '';
    final cleanPath = rawPath.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    if (cleanPath.startsWith('/data/') ||
        cleanPath.startsWith('/storage/') ||
        cleanPath.contains('file_picker') ||
        cleanPath.contains('cache') ||
        File(cleanPath).existsSync()) {
      return cleanPath;
    }
    final serverBaseUrl = sl<ApiClient>().baseUrl.replaceAll(RegExp(r'/+$'), '');
    final relPath = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
    return '$serverBaseUrl$relPath';
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

  /// Real PDF & Image Opener / Viewer
  Future<void> _openOrDownloadFile(BuildContext context, String? fileName, String? filePath) async {
    if (filePath == null || filePath.trim().isEmpty) {
      AppNotifications.showError(context, "No attachment file available.");
      return;
    }

    final String cleanPath = filePath.trim();
    final String cleanName = fileName ?? cleanPath.split('/').last.split('\\').last;
    final bool isPdf = cleanName.toLowerCase().endsWith('.pdf') || cleanPath.toLowerCase().endsWith('.pdf');

    AppNotifications.showSuccess(context, "Loading ${isPdf ? 'PDF' : 'Attachment'} $cleanName...");

    Uint8List? bytes;

    final dioClient = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    // 1. Try reading directly from local device filesystem (Android cache / file_picker)
    try {
      final localFile = File(cleanPath);
      if (await localFile.exists()) {
        bytes = await localFile.readAsBytes();
      }
    } catch (_) {}

    // 2. If not local, fetch network URL via Dio
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
      AppNotifications.showError(context, "Unable to load attachment file.");
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





  void _showSubmitDialog(BuildContext context, int homeworkId, String title, {bool isReplace = false}) {
    String? filePath;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isReplace ? "Replace Submission" : "Submit Homework",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 16),
                  FileUploader(
                    label: "Select Homework File / Document",
                    onFileSelected: (file) {
                      setModalState(() {
                        if (file != null) {
                          filePath = file.path;
                          fileName = file.path.split('/').last.split('\\').last;
                        } else {
                          filePath = null;
                          fileName = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.parentPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: filePath == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              context.read<ParentCubit>().submitHomework(homeworkId, fileName!, filePath!);
                              AppNotifications.showSuccess(
                                context,
                                isReplace ? "Submission replaced successfully." : "Homework submitted successfully.",
                              );
                            },
                      child: Text(
                        isReplace ? "Confirm & Replace" : "Submit Homework",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteSubmission(BuildContext context, int homeworkId) {
    ConfirmationDialog.show(
      context,
      title: "Delete Submission",
      content: "Are you sure you want to delete your submitted homework file?",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<ParentCubit>().deleteHomeworkSubmission(homeworkId);
        AppNotifications.showSuccess(context, "Submission deleted successfully.");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final rawHomework = state.homework;
        final allHomework = rawHomework.map((item) => HomeworkModel.fromJson(item)).toList();

        // Subject filtering logic
        final filteredList = allHomework.where((item) {
          if (_selectedSubject == 'All Subjects') return true;
          return item.subject.toLowerCase().contains(_selectedSubject.toLowerCase());
        }).toList();

        // History tab items
        final historyList = allHomework.where((item) => item.isSubmitted).toList();

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Homework Management",
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
              indicatorColor: AppColors.parentPrimary,
              labelColor: AppColors.parentPrimary,
              unselectedLabelColor: AppColors.textLight,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: "Homework"),
                Tab(text: "Homework History"),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: HOMEWORK
                _buildHomeworkTab(context, filteredList),

                // TAB 2: HOMEWORK HISTORY
                _buildHistoryTab(context, historyList),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeworkTab(BuildContext context, List<HomeworkModel> homeworkList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subject Filter Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppColors.softShadow,
            ),
            child: Row(
              children: [
                Text(
                  "Subject Filter:",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      isExpanded: true,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.parentPrimary),
                      items: _subjectsList.map((String subject) {
                        return DropdownMenuItem<String>(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSubject = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Homework Feed Cards
        Expanded(
          child: homeworkList.isEmpty
              ? const Center(
                  child: EmptyStateWidget(
                    title: "No Homework Found",
                    message: "There are no homework tasks assigned for the selected subject.",
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: homeworkList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = homeworkList[index];
                    final bool hasFacultyFile = item.attachmentPath != null && item.attachmentPath!.isNotEmpty;
                    final bool hasSubmissionFile = item.isSubmitted && item.submissionPath != null && item.submissionPath!.isNotEmpty;

                    String dueDateStr = 'N/A';
                    if (item.dueDate != null && item.dueDate!.isNotEmpty) {
                      try {
                        dueDateStr = DateFormat('dd-MMM-yyyy').format(DateTime.parse(item.dueDate!));
                      } catch (_) {
                        dueDateStr = item.dueDate!;
                      }
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.parentPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.subject,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.isSubmitted ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isSubmitted ? "Submitted" : "Pending",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.isSubmitted ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Text(
                            item.title,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, height: 1.4),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(Icons.event_note, size: 14, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                "Due Date: $dueDateStr",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                              ),
                            ],
                          ),

                          // 1. FACULTY UPLOADED ATTACHMENT CARD
                          if (hasFacultyFile) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => _openOrDownloadFile(context, item.attachmentName, item.attachmentPath),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.parentPrimary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: AppColors.parentPrimary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Faculty PDF Attachment",
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                                          ),
                                          Text(
                                            item.attachmentName ?? 'Faculty_Homework.pdf',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "View / Download",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // 2. STUDENT SUBMISSION FILE CARD
                          if (hasSubmissionFile) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _openOrDownloadFile(context, item.submissionFile, item.submissionPath),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.task_outlined, color: AppColors.success, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Your Submission File",
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                          ),
                                          Text(
                                            item.submissionFile ?? 'Homework_Submission.pdf',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "View / Download",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (item.isSubmitted) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(color: AppColors.danger),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.delete_outline, size: 14),
                                    label: Text("Delete", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _confirmDeleteSubmission(context, item.id),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: item.isSubmitted ? AppColors.success : AppColors.parentPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: Icon(item.isSubmitted ? Icons.edit : Icons.upload_file, size: 14, color: Colors.white),
                                  label: Text(
                                    item.isSubmitted ? "Replace Homework" : "Submit Homework",
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  onPressed: () => _showSubmitDialog(context, item.id, item.title, isReplace: item.isSubmitted),
                                ),
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
  }

  Widget _buildHistoryTab(BuildContext context, List<HomeworkModel> historyList) {
    if (historyList.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: "No Homework Submissions",
          message: "Submitted homework tasks will be listed here.",
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: historyList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = historyList[index];
        final String fileName = item.submissionFile ?? item.attachmentName ?? 'Homework_Submission.pdf';
        final String? filePath = item.submissionPath ?? item.attachmentPath;

        String submittedDateStr = 'N/A';
        if (item.submittedAt != null && item.submittedAt!.isNotEmpty) {
          try {
            submittedDateStr = DateFormat('dd-MMM-yyyy').format(DateTime.parse(item.submittedAt!));
          } catch (_) {
            submittedDateStr = item.submittedAt!;
          }
        }

        String dueDateStr = 'N/A';
        if (item.dueDate != null && item.dueDate!.isNotEmpty) {
          try {
            dueDateStr = DateFormat('dd-MMM-yyyy').format(DateTime.parse(item.dueDate!));
          } catch (_) {
            dueDateStr = item.dueDate!;
          }
        }

        return GestureDetector(
          onTap: () => _openOrDownloadFile(context, fileName, filePath),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                        color: AppColors.parentPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.subject,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Submitted",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fileName,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "Submitted: $submittedDateStr",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    Text(
                      "Due: $dueDateStr",
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
