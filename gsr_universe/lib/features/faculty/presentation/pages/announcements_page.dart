// Presentation Layer - Announcements Console
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _msgController = TextEditingController();

  String _priority = "Normal"; // Normal, Important, Urgent
  List<String> _selectedClasses = [];
  List<String> _selectedSections = ["A", "B", "C"];
  DateTime _announcementDate = DateTime.now();

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
    context.read<FacultyCubit>().fetchAnnouncements();
    _selectedClasses = [_classes.last]; // Default to Class 10th
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _publish(BuildContext context, int facultyId, int yearId) {
    if (_formKey.currentState!.validate()) {
      if (_selectedClasses.isEmpty) {
        AppNotifications.showError(context, "Select at least one class to target.");
        return;
      }
      if (_selectedSections.isEmpty) {
        AppNotifications.showError(context, "Select at least one section to target.");
        return;
      }

      final payload = {
        "classes": _selectedClasses,
        "sections": _selectedSections,
        "announcement_date": DateFormat('yyyy-MM-dd').format(_announcementDate),
        "academic_year_id": yearId,
        "title": _titleController.text.trim(),
        "message": _msgController.text.trim(),
        "priority": _priority,
        "created_by": facultyId,
        "target_scope": _selectedClasses.length == _classes.length ? "ALL" : "CLASS",
      };

      context.read<FacultyCubit>().publishAnnouncement(payload);
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    ConfirmationDialog.show(
      context,
      title: "Delete Announcement",
      content: "Are you sure you want to delete this announcement?",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeAnnouncement(item['id']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    int facultyId = 1;
    String userRole = 'FACULTY';
    if (authState is AuthAuthenticated) {
      facultyId = authState.payload['id'] ?? 1;
      userRole = (authState.payload['role'] ?? 'FACULTY').toString().toUpperCase();
    }
    final bool isParent = userRole == 'PARENT';
    const int yearId = 1;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Announcements",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: isParent
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.facultyPrimary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.facultyPrimary,
                tabs: const [
                  Tab(icon: Icon(Icons.campaign_outlined), text: "Publish Circular"),
                  Tab(icon: Icon(Icons.history_outlined), text: "Past Registry"),
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
              if (state.successMessage!.contains("published") || state.successMessage!.contains("Announcement")) {
                _titleController.clear();
                _msgController.clear();
                setState(() {
                  _selectedClasses = [_classes.last];
                });
                _tabController.animateTo(1);
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Publish Announcement
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
                          Row(
                            children: [
                              Text("Target Sections", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                              const Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_selectedSections.length == _sections.length) {
                                      _selectedSections.clear();
                                    } else {
                                      _selectedSections = List.from(_sections);
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedSections.length == _sections.length ? "Deselect All" : "Select All",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.facultyPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8.0,
                            children: _sections.map((sec) {
                              final isSelected = _selectedSections.contains(sec);
                              return FilterChip(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                label: Text("Sec $sec", style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : AppColors.textDark)),
                                selected: isSelected,
                                selectedColor: AppColors.facultyPrimary,
                                checkmarkColor: Colors.white,
                                backgroundColor: Colors.grey[200],
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSections.add(sec);
                                    } else {
                                      _selectedSections.remove(sec);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          AppSpacing.h12,
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _announcementDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _announcementDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: "Date for Announcement",
                                prefixIcon: Icon(Icons.calendar_month_outlined, color: AppColors.facultyPrimary),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_announcementDate),
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              ),
                            ),
                          ),
                          AppSpacing.h12,
                          CustomDropdown<String>(
                            value: _priority,
                            labelText: "Notification Priority",
                            prefixIcon: Icons.priority_high,
                            items: const [
                              DropdownMenuItem(value: "Normal", child: Text("Normal")),
                              DropdownMenuItem(value: "Important", child: Text("Important")),
                              DropdownMenuItem(value: "Urgent", child: Text("Urgent")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Announcement Title",
                            hintText: "e.g. Annual Sport Meet Circular",
                            validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _msgController,
                            labelText: "Circular Body Message",
                            hintText: "Enter official circular announcement description...",
                            validator: (val) => val == null || val.isEmpty ? "Message body is required" : null,
                          ),
                          AppSpacing.h20,
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.facultyPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: state.isLoading ? null : () => _publish(context, facultyId, yearId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Publish Announcement", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Past Registry
                state.announcementsList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "No Announcements Found",
                          message: "Previously broadcast circulars will appear here.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.announcementsList.length,
                        itemBuilder: (context, index) {
                          final item = state.announcementsList[index];
                          final priority = item['priority'] ?? 'Normal';
                          final Color chipColor = priority == 'Urgent'
                              ? AppColors.danger
                              : priority == 'Important'
                                  ? AppColors.warning
                                  : AppColors.facultyPrimary;

                          final dateStr = item['created_at'] != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(item['created_at']))
                              : 'N/A';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          color: chipColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          priority.toUpperCase(),
                                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: chipColor),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                      ),
                                      if (!isParent)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                          onPressed: () => _confirmDelete(item),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['title'] ?? 'Announcement',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['message'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Target: ${item['target_classes'] ?? 'All Classes'}",
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
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
