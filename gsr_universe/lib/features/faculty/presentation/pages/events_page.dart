// Presentation Layer - Events Scheduler Page
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

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _venueController = TextEditingController();

  File? _flyerFile;
  String _targetScope = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FacultyCubit>().fetchEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _schedule(BuildContext context, int facultyId) async {
    if (_formKey.currentState!.validate()) {
      context.read<FacultyCubit>().clearUploads();

      if (_flyerFile != null) {
        await context.read<FacultyCubit>().uploadHomeworkAttachment(_flyerFile!); // Same upload gateway
      }

      if (context.mounted) {
        final state = context.read<FacultyCubit>().state;
        final payload = {
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          "event_date": _dateController.text.trim(),
          "event_time": _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
          "venue": _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
          "created_by": facultyId,
          "event_status": "Scheduled",
          "target_scope": _targetScope,
        };

        if (state.uploadedFileUrl != null) {
          payload["attachment_name"] = state.uploadedFileName ?? "Flyer";
          payload["attachment_path"] = state.uploadedFileUrl!;
        }

        context.read<FacultyCubit>().publishEvent(payload);
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    ConfirmationDialog.show(
      context,
      title: "Remove Event",
      content: "Are you sure you want to cancel and remove event '${item['title']}'?",
      confirmText: "Remove",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeEvent(item['id']);
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
          "Events Scheduler",
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
            Tab(icon: Icon(Icons.event_note_outlined), text: "Schedule Event"),
            Tab(icon: Icon(Icons.event_outlined), text: "Events Registry"),
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
              if (state.successMessage!.contains("scheduled") || state.successMessage!.contains("Event")) {
                _titleController.clear();
                _descController.clear();
                _dateController.clear();
                _timeController.clear();
                _venueController.clear();
                setState(() => _flyerFile = null);
                _tabController.animateTo(1);
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Schedule Event Form
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
                          CustomTextField(
                            controller: _titleController,
                            labelText: "Event Title",
                            hintText: "e.g. Science Fair 2026",
                            validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _descController,
                            labelText: "Event description details",
                            hintText: "Describe the event schedules or programs...",
                            validator: (val) => val == null || val.isEmpty ? "Description is required" : null,
                          ),
                          AppSpacing.h12,
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectDate(context),
                                  child: AbsorbPointer(
                                    child: CustomTextField(
                                      controller: _dateController,
                                      labelText: "Event Date",
                                      prefixIcon: Icons.calendar_today_outlined,
                                      validator: (val) => val == null || val.isEmpty ? "Date required" : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomTextField(
                                  controller: _timeController,
                                  labelText: "Time (e.g. 10:00 AM)",
                                  prefixIcon: Icons.access_time_outlined,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _venueController,
                            labelText: "Venue details",
                            prefixIcon: Icons.location_on_outlined,
                            hintText: "e.g. Auditorium / Playground",
                          ),
                          AppSpacing.h12,
                          FileUploader(
                            label: "Upload Event Flyer / Guideline PDF (Optional)",
                            onFileSelected: (file) {
                              setState(() => _flyerFile = file);
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
                              onPressed: state.isLoading ? null : () => _schedule(context, facultyId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Schedule Event Now", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Events Registry
                state.eventsList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "No Events Configured",
                          message: "Any scheduled events will appear in this timeline scroll feed.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.eventsList.length,
                        itemBuilder: (context, index) {
                          final event = state.eventsList[index];
                          final dateStr = event['event_date'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(event['event_date']))
                              : 'N/A';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.facultyPrimary.withOpacity(0.1),
                                child: const Icon(Icons.festival, color: AppColors.facultyPrimary),
                              ),
                              title: Text(
                                event['title'] ?? 'School Event',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Venue: ${event['venue'] ?? 'Campus'} • Date: $dateStr • ${event['event_time'] ?? ''}",
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    event['description'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: () => _confirmDelete(event),
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
