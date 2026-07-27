// Presentation Layer - Holidays Registry Page
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

class HolidaysPage extends StatefulWidget {
  const HolidaysPage({super.key});

  @override
  State<HolidaysPage> createState() => _HolidaysPageState();
}

class _HolidaysPageState extends State<HolidaysPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  String _holidayType = "General";
  String _targetScope = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FacultyCubit>().fetchHolidays();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startController.text = DateFormat('yyyy-MM-dd').format(picked);
        if (_endController.text.isEmpty) {
          _endController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startController.text.isNotEmpty 
          ? DateTime.parse(_startController.text) 
          : DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _create(BuildContext context, int facultyId) {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "holiday_name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "start_date": _startController.text.trim(),
        "end_date": _endController.text.trim(),
        "holiday_type": _holidayType,
        "created_by": facultyId,
        "target_scope": _targetScope,
      };

      context.read<FacultyCubit>().publishHoliday(payload);
    }
  }

  void _confirmDelete(Map<String, dynamic> item) {
    ConfirmationDialog.show(
      context,
      title: "Remove Holiday Record",
      content: "Are you sure you want to remove '${item['holiday_name']}' from the school calendar?",
      confirmText: "Remove",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeHoliday(item['id']);
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
          "School Holidays",
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
            Tab(icon: Icon(Icons.event_busy_outlined), text: "Create Holiday"),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: "Holidays Feed"),
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
              if (state.successMessage!.contains("created") || state.successMessage!.contains("Holiday")) {
                _nameController.clear();
                _descController.clear();
                _startController.clear();
                _endController.clear();
                _tabController.animateTo(1);
              }
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Create Holiday Form
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
                          CustomDropdown<String>(
                            value: _holidayType,
                            labelText: "Holiday Category Type",
                            prefixIcon: Icons.beach_access_outlined,
                            items: const [
                              DropdownMenuItem(value: "General", child: Text("General Holiday")),
                              DropdownMenuItem(value: "Festival", child: Text("Festival Holiday")),
                              DropdownMenuItem(value: "Vacation", child: Text("Vacation")),
                              DropdownMenuItem(value: "Emergency", child: Text("Emergency")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _holidayType = val);
                            },
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _nameController,
                            labelText: "Holiday Name",
                            hintText: "e.g. Independence Day",
                            validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: _descController,
                            labelText: "Holiday description details",
                            hintText: "Describe reason or message...",
                          ),
                          AppSpacing.h12,
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectStartDate(context),
                                  child: AbsorbPointer(
                                    child: CustomTextField(
                                      controller: _startController,
                                      labelText: "Start Date",
                                      prefixIcon: Icons.calendar_month_outlined,
                                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _selectEndDate(context),
                                  child: AbsorbPointer(
                                    child: CustomTextField(
                                      controller: _endController,
                                      labelText: "End Date",
                                      prefixIcon: Icons.calendar_month_outlined,
                                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                              onPressed: state.isLoading ? null : () => _create(context, facultyId),
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text("Register Calendar Holiday", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // TAB 2: Holidays Feed
                state.holidaysList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "No Holidays Mapped",
                          message: "School holiday feeds will appear here.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.holidaysList.length,
                        itemBuilder: (context, index) {
                          final h = state.holidaysList[index];
                          final startStr = h['start_date'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(h['start_date']))
                              : 'N/A';
                          final endStr = h['end_date'] != null
                              ? DateFormat('dd MMM yyyy').format(DateTime.parse(h['end_date']))
                              : 'N/A';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.success.withOpacity(0.1),
                                child: const Icon(Icons.beach_access, color: Colors.green),
                              ),
                              title: Text(
                                h['holiday_name'] ?? 'School Holiday',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    "Type: ${h['holiday_type'] ?? 'General'} • $startStr to $endStr",
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    h['description'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                onPressed: () => _confirmDelete(h),
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
