// Presentation Layer - Notice Board Page
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/file_uploader.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class NoticeBoardPage extends StatefulWidget {
  const NoticeBoardPage({super.key});

  @override
  State<NoticeBoardPage> createState() => _NoticeBoardPageState();
}

class _NoticeBoardPageState extends State<NoticeBoardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _noticeFile;
  List<String> _selectedClasses = [];

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FacultyCubit>().fetchNotices();
    _selectedClasses = List.from(_classes); // Default to all classes selected
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _publish(BuildContext context, int facultyId) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedClasses.isEmpty) {
        AppNotifications.showError(context, "Please select at least one target class.");
        return;
      }

      context.read<FacultyCubit>().clearUploads();

      if (_noticeFile != null) {
        await context.read<FacultyCubit>().uploadHomeworkAttachment(_noticeFile!); // Uses same file upload gateway
      }

      if (context.mounted) {
        final state = context.read<FacultyCubit>().state;
        final payload = {
          "title": _titleController.text.trim(),
          "description": "[Target Classes: ${_selectedClasses.join(', ')}]\n\n${_descController.text.trim()}",
          "created_by": facultyId,
          "target_scope": _selectedClasses.length == _classes.length ? "ALL" : "CLASS",
        };

        if (state.uploadedFileUrl != null) {
          payload["attachment_name"] = state.uploadedFileName ?? "Notice attachment";
          payload["attachment_path"] = state.uploadedFileUrl!;
        }

        context.read<FacultyCubit>().publishNotice(payload);
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    ConfirmationDialog.show(
      context,
      title: "Delete Pinned Notice",
      content: "Are you sure you want to delete and unpin notice '${item['title']}'?",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeNotice(item['id']);
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

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Notice Board",
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
            Tab(icon: Icon(Icons.push_pin_outlined), text: "Pin Circular Notice"),
            Tab(icon: Icon(Icons.grid_view), text: "Notice Board Feed"),
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
              if (state.successMessage!.contains("updated") || state.successMessage!.contains("Notice")) {
                _titleController.clear();
                _descController.clear();
                setState(() => _noticeFile = null);
                _tabController.animateTo(1);
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Pin Notice Form
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
                              Text("Target Classes", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                              const Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_selectedClasses.length == _classes.length) {
                                      _selectedClasses.clear();
                                    } else {
                                      _selectedClasses = List.from(_classes);
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedClasses.length == _classes.length ? "Deselect All" : "Select All",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.facultyPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 0.0,
                            children: _classes.map((className) {
                              final isSelected = _selectedClasses.contains(className);
                              return FilterChip(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                label: Text(className, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : AppColors.textDark)),
                                selected: isSelected,
                                selectedColor: AppColors.facultyPrimary,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.grey[200],
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedClasses.add(className);
                                    } else {
                                      _selectedClasses.remove(className);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Notice Board Title",
                            hintText: "e.g. Science Exhibition Registration Open",
                            validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _descController,
                            labelText: "Description text",
                            hintText: "Type description guidelines...",
                            validator: (val) => val == null || val.isEmpty ? "Description is required" : null,
                          ),
                          AppSpacing.h12,
                          FileUploader(
                            label: "Upload Circular PDF / Flyer Image (Optional)",
                            onFileSelected: (file) {
                              setState(() => _noticeFile = file);
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
                              onPressed: state.isLoading ? null : () => _publish(context, facultyId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Pin to Board", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Notice Board Feed
                state.noticesList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "Notice Board Empty",
                          message: "Any circulars pinned to the board will appear here.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.noticesList.length,
                        itemBuilder: (context, index) {
                          final notice = state.noticesList[index];
                          final dateStr = notice['created_at'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(notice['created_at']))
                              : 'N/A';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.adminPrimary.withOpacity(0.1),
                                child: const Icon(Icons.push_pin, color: AppColors.adminPrimary),
                              ),
                              title: Text(
                                notice['title'] ?? 'Board Notice',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Audience: ${notice['target_scope'] ?? 'All'} • Pinned: $dateStr",
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notice['description'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: () => _confirmDelete(notice),
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
