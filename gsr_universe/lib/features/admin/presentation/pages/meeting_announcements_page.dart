// Presentation Layer - Meeting Announcements Management Module
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class MeetingAnnouncementsPage extends StatefulWidget {
  const MeetingAnnouncementsPage({super.key});

  @override
  State<MeetingAnnouncementsPage> createState() => _MeetingAnnouncementsPageState();
}

class _MeetingAnnouncementsPageState extends State<MeetingAnnouncementsPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _venueController = TextEditingController();

  String _selectedPriority = 'Normal';
  final List<String> _priorities = ['Normal', 'Important', 'Urgent'];

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().fetchMeetingHistory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
        _timeController.text = DateFormat('hh:mm a').format(dt);
      });
    }
  }

  void _publishMeeting() {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "meeting_date": _dateController.text.trim(),
        "meeting_time": _timeController.text.trim(),
        "venue": _venueController.text.trim(),
        "priority": _selectedPriority,
      };

      context.read<AdminCubit>().publishMeetingAnnouncement(payload);

      // Reset form on publish
      _titleController.clear();
      _descriptionController.clear();
      _dateController.clear();
      _timeController.clear();
      _venueController.clear();
      setState(() {
        _selectedPriority = 'Normal';
      });
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.danger;
      case 'important':
        return Colors.orange.shade700;
      default:
        return AppColors.adminPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppNotifications.showError(context, state.errorMessage!);
          context.read<AdminCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          AppNotifications.showSuccess(context, state.successMessage!);
          context.read<AdminCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.pageBackground,
            appBar: AppBar(
              title: Text(
                "Meeting Announcements",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textDark),
                  onPressed: () {
                    context.read<AdminCubit>().fetchMeetingHistory();
                  },
                ),
              ],
              bottom: TabBar(
                labelColor: AppColors.adminPrimary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.adminPrimary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.add_circle_outline), text: "Create Meeting"),
                  Tab(icon: Icon(Icons.history_outlined), text: "History"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: CREATE MEETING
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                            Text(
                              "Publish New Staff Meeting",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                            ),
                            Text(
                              "Notifications will be automatically delivered to all Faculty accounts.",
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                            ),
                            AppSpacing.h20,

                            // Meeting Title
                            CustomTextField(
                              controller: _titleController,
                              labelText: "Meeting Title *",
                              hintText: "e.g. Monthly Staff Strategy Meeting",
                              prefixIcon: Icons.title_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return "Meeting Title is required";
                                return null;
                              },
                            ),
                            AppSpacing.h16,

                            // Meeting Description
                            CustomTextField(
                              controller: _descriptionController,
                              labelText: "Meeting Description",
                              hintText: "Provide agenda details or special instructions...",
                              prefixIcon: Icons.description_outlined,
                              maxLines: 3,
                            ),
                            AppSpacing.h16,

                            // Date & Time Selection Row
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _pickDate,
                                    child: AbsorbPointer(
                                      child: CustomTextField(
                                        controller: _dateController,
                                        labelText: "Meeting Date *",
                                        hintText: "YYYY-MM-DD",
                                        prefixIcon: Icons.calendar_today_outlined,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return "Required";
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                AppSpacing.w12,
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _pickTime,
                                    child: AbsorbPointer(
                                      child: CustomTextField(
                                        controller: _timeController,
                                        labelText: "Meeting Time *",
                                        hintText: "e.g. 04:00 PM",
                                        prefixIcon: Icons.access_time_outlined,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return "Required";
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.h16,

                            // Venue
                            CustomTextField(
                              controller: _venueController,
                              labelText: "Meeting Venue *",
                              hintText: "e.g. Main Conference Hall / Staff Room",
                              prefixIcon: Icons.location_on_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return "Venue is required";
                                return null;
                              },
                            ),
                            AppSpacing.h16,

                            // Priority Dropdown
                            CustomDropdown<String>(
                              labelText: "Priority Level",
                              value: _selectedPriority,
                              items: _priorities.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Icon(Icons.flag_outlined, size: 16, color: _getPriorityColor(p)),
                                      const SizedBox(width: 8),
                                      Text(p, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedPriority = val);
                                }
                              },
                            ),
                            AppSpacing.h24,

                            // Publish Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.adminPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                ),
                                onPressed: state.isLoading ? null : _publishMeeting,
                                icon: state.isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.send_outlined, color: Colors.white, size: 20),
                                label: Text(
                                  "Publish Meeting Announcement",
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // TAB 2: HISTORY
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Published Meetings History",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.adminPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${state.meetingHistory.length} Meetings",
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.adminPrimary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.h12,

                        state.isLoading && state.meetingHistory.isEmpty
                            ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                            : state.meetingHistory.isEmpty
                                ? const EmptyStateWidget(
                                    title: "No Meetings Published",
                                    message: "Published staff meeting announcements will appear here sorted with latest first.",
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.meetingHistory.length,
                                    separatorBuilder: (context, index) => AppSpacing.h12,
                                    itemBuilder: (context, index) {
                                      final item = state.meetingHistory[index];
                                      final int meetingId = item['id'] ?? 0;
                                      final String title = (item['title'] ?? 'Staff Meeting').toString();
                                      final String description = (item['description'] ?? '').toString();
                                      final String rawDate = (item['meeting_date'] ?? '').toString();
                                      final String meetingDate = rawDate.isNotEmpty ? (rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate) : 'N/A';
                                      final String time = (item['meeting_time'] ?? 'N/A').toString();
                                      final String venue = (item['venue'] ?? 'N/A').toString();
                                      final String priority = (item['priority'] ?? 'Normal').toString();
                                      final String rawCreated = (item['created_at'] ?? '').toString();
                                      final String publishedTime = rawCreated.isNotEmpty
                                          ? (DateTime.tryParse(rawCreated) != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(rawCreated)!) : rawCreated)
                                          : 'N/A';

                                      final color = _getPriorityColor(priority);

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
                                            // Priority Header Badge + Delete Button Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: color.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: color.withValues(alpha: 0.3)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.flag, size: 12, color: color),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              priority.toUpperCase(),
                                                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 10, color: color),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          "Published: $publishedTime",
                                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                                  tooltip: "Delete Meeting Announcement",
                                                  constraints: const BoxConstraints(),
                                                  padding: EdgeInsets.zero,
                                                  onPressed: () {
                                                    ConfirmationDialog.show(
                                                      context,
                                                      title: "Delete Meeting Announcement",
                                                      content: "Are you sure you want to delete '$title'?",
                                                      confirmText: "Delete",
                                                      confirmColor: AppColors.danger,
                                                      onConfirm: () {
                                                        context.read<AdminCubit>().deleteMeetingAnnouncement(meetingId);
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            AppSpacing.h12,

                                            // Meeting Title
                                            Text(
                                              title,
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                            ),
                                            if (description.isNotEmpty) ...[
                                              AppSpacing.h4,
                                              Text(
                                                description,
                                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                                              ),
                                            ],
                                            AppSpacing.h12,

                                            // Meeting Schedule Info (Date, Time, Venue)
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.pageBackground,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Wrap(
                                                spacing: 16,
                                                runSpacing: 8,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.adminPrimary),
                                                      const SizedBox(width: 6),
                                                      Text(meetingDate, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.access_time, size: 14, color: AppColors.adminPrimary),
                                                      const SizedBox(width: 6),
                                                      Text(time, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.location_on, size: 14, color: AppColors.adminPrimary),
                                                      const SizedBox(width: 6),
                                                      Text(venue, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
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
