// Presentation Layer - Automated Call Reminders & Pending Fee Reports
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../../core/widgets/data_table_view.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class CallSettingsPage extends StatefulWidget {
  const CallSettingsPage({super.key});

  @override
  State<CallSettingsPage> createState() => _CallSettingsPageState();
}

class _CallSettingsPageState extends State<CallSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEnabled = true;
  final _startDayController = TextEditingController(text: "1");
  final _endDayController = TextEditingController(text: "7");
  final _twilioSidController = TextEditingController();
  final _twilioTokenController = TextEditingController();
  final List<String> _callerNumbersList = ["+18005550199"];

  String _selectedFeeClass = 'Class 8';
  String _selectedFeeSection = 'B';
  String _feeSearchQuery = "";
  String _logSearchQuery = "";

  final List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'
  ];
  final List<String> _sections = ['A', 'B', 'C'];

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().fetchDashboardData();
    _loadFeeReport();
  }

  @override
  void dispose() {
    _startDayController.dispose();
    _endDayController.dispose();
    _twilioSidController.dispose();
    _twilioTokenController.dispose();
    super.dispose();
  }

  void _loadFeeReport() {
    context.read<AdminCubit>().fetchPendingFeeReport(
      className: _selectedFeeClass,
      section: _selectedFeeSection,
    );
  }

  void _addCallerNumber() {
    final numController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Add Caller Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: CustomTextField(
            controller: numController,
            labelText: "Phone Number (+1800...)",
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminPrimary),
              onPressed: () {
                final txt = numController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    if (!_callerNumbersList.contains(txt)) _callerNumbersList.add(txt);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final payload = {
        "is_enabled": _isEnabled,
        "schedule_day_start": int.parse(_startDayController.text.trim()),
        "schedule_day_end": int.parse(_endDayController.text.trim()),
        "calling_number": _callerNumbersList.isNotEmpty ? _callerNumbersList[0] : '+18005550199',
        "caller_numbers": _callerNumbersList,
        "twilio_account_sid": _twilioSidController.text.trim(),
        "twilio_auth_token": _twilioTokenController.text.trim(),
      };
      context.read<AdminCubit>().updateReminderSettings(payload);
    }
  }

  void _triggerManualSweep() {
    context.read<AdminCubit>().triggerRemindersSweep();
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
        if (state.callSettings != null) {
          setState(() {
            _isEnabled = state.callSettings!['is_enabled'] ?? true;
            _startDayController.text = (state.callSettings!['schedule_day_start'] ?? 1).toString();
            _endDayController.text = (state.callSettings!['schedule_day_end'] ?? 7).toString();
            _twilioSidController.text = state.callSettings!['twilio_account_sid'] ?? '';
            _twilioTokenController.text = state.callSettings!['twilio_auth_token'] ?? '';
            final List<dynamic> nums = state.callSettings!['caller_numbers'] ?? [];
            if (nums.isNotEmpty) {
              _callerNumbersList.clear();
              _callerNumbersList.addAll(nums.map((e) => e.toString()));
            }
          });
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.pageBackground,
            appBar: AppBar(
              title: Text(
                "IVR Fee Reminders Management",
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
                    context.read<AdminCubit>().fetchDashboardData();
                    _loadFeeReport();
                  },
                ),
              ],
              bottom: TabBar(
                labelColor: AppColors.adminPrimary,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.adminPrimary,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.table_chart_outlined), text: "Pending Dues"),
                  Tab(icon: Icon(Icons.history_outlined), text: "Call Logs"),
                  Tab(icon: Icon(Icons.settings_phone_outlined), text: "Schedule"),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: PENDING FEE REPORT
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Class & Section Filter
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomDropdown<String>(
                                  labelText: "Class",
                                  value: _selectedFeeClass,
                                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedFeeClass = val);
                                      _loadFeeReport();
                                    }
                                  },
                                ),
                              ),
                              AppSpacing.w12,
                              Expanded(
                                child: CustomDropdown<String>(
                                  labelText: "Section",
                                  value: _selectedFeeSection,
                                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Section $s"))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedFeeSection = val);
                                      _loadFeeReport();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.h16,

                        // Pending Fee Table
                        () {
                          final filteredReports = state.feeReports.where((item) {
                            if (_feeSearchQuery.isEmpty) return true;
                            final q = _feeSearchQuery.toLowerCase();
                            final sName = (item['student_name'] ?? item['studentName'] ?? item['name'] ?? item['student'] ?? '').toString().toLowerCase();
                            final admNo = (item['admission_no'] ?? item['admissionNo'] ?? item['adm_no'] ?? item['admNo'] ?? '').toString().toLowerCase();
                            final pName = (item['parent_name'] ?? item['parentName'] ?? item['primary_parent_name'] ?? '').toString().toLowerCase();
                            final mobile = (item['parent_mobile'] ?? item['parentMobile'] ?? item['primary_parent_mobile'] ?? item['mobile'] ?? '').toString().toLowerCase();
                            return sName.contains(q) || admNo.contains(q) || pName.contains(q) || mobile.contains(q);
                          }).toList();

                          return state.isLoading && state.feeReports.isEmpty
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ))
                              : filteredReports.isEmpty
                                  ? const EmptyStateWidget(
                                      title: "No Pending Students",
                                      message: "No pending fee records match the selected class and section.",
                                    )
                                  : DataTableView(
                                      searchPlaceholder: "Search student, adm no, or parent...",
                                      onSearchChanged: (val) => setState(() => _feeSearchQuery = val.trim()),
                                      headers: const ['Student Name', 'Adm No', 'Parent Name', 'Parent Mobile Number', 'Class', 'Section', 'Total Fee', 'Paid Fee', 'Pending Fee', 'Due Date', 'Status'],
                                      rows: filteredReports.map((item) {
                                        final String studentName = (item['student_name'] ?? item['studentName'] ?? item['name'] ?? item['student'] ?? 'Student').toString();
                                        final String admissionNo = (item['admission_no'] ?? item['admissionNo'] ?? item['adm_no'] ?? item['admNo'] ?? 'N/A').toString();
                                        final String parentName = (item['parent_name'] ?? item['parentName'] ?? item['primary_parent_name'] ?? item['primaryParentName'] ?? 'Parent').toString();
                                        final String mobile = (item['parent_mobile'] ?? item['parentMobile'] ?? item['primary_parent_mobile'] ?? item['primaryParentMobile'] ?? item['mobile'] ?? 'N/A').toString();
                                        final String className = (item['class_name'] ?? item['className'] ?? item['class'] ?? _selectedFeeClass).toString();
                                        final String section = (item['section'] ?? _selectedFeeSection).toString();
                                        final double total = double.tryParse((item['total_fee'] ?? item['totalFee'] ?? item['total'] ?? '0').toString()) ?? 0.0;
                                        final double paid = double.tryParse((item['paid_fee'] ?? item['paidFee'] ?? item['paid_amount'] ?? item['paidAmount'] ?? item['paid'] ?? '0').toString()) ?? 0.0;
                                        final double pending = double.tryParse((item['pending_fee'] ?? item['pendingFee'] ?? item['pending_amount'] ?? item['pendingAmount'] ?? item['pending'] ?? '0').toString()) ?? 0.0;
                                        final String rawDueDate = (item['due_date'] ?? item['dueDate'] ?? '').toString();
                                        final String dueDate = rawDueDate.isNotEmpty ? (rawDueDate.length >= 10 ? rawDueDate.substring(0, 10) : rawDueDate) : 'N/A';
                                        final String status = (item['payment_status'] ?? item['paymentStatus'] ?? item['status'] ?? (pending <= 0 ? 'Paid' : 'Pending')).toString();

                                        final bool isPaid = status.toLowerCase() == 'paid';

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(studentName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                            DataCell(Text(admissionNo, style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(Text(parentName, style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(Text(mobile, style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(Text(className, style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(Text(section, style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(Text("₹${total.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(Text("₹${paid.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold))),
                                            DataCell(Text("₹${pending.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold))),
                                            DataCell(Text(dueDate, style: GoogleFonts.inter(fontSize: 12))),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: (isPaid ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: isPaid ? AppColors.success : AppColors.danger,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    );
                        }(),
                      ],
                    ),
                  ),
                ),

                // TAB 2: IVR CALL LOGS HISTORY
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        () {
                          final filteredLogs = state.callHistory.where((log) {
                            if (_logSearchQuery.isEmpty) return true;
                            final q = _logSearchQuery.toLowerCase();
                            final sName = (log['student_name'] ?? '').toString().toLowerCase();
                            final pName = (log['parent_name'] ?? '').toString().toLowerCase();
                            final mobile = (log['parent_mobile'] ?? '').toString().toLowerCase();
                            return sName.contains(q) || pName.contains(q) || mobile.contains(q);
                          }).toList();

                          return filteredLogs.isEmpty
                              ? const EmptyStateWidget(
                                  title: "No Call Logs Found",
                                  message: "No automated IVR reminder calls have been logged yet.",
                                )
                              : DataTableView(
                                  searchPlaceholder: "Search call logs...",
                                  onSearchChanged: (val) => setState(() => _logSearchQuery = val.trim()),
                                  headers: const ['Student Name', 'Parent Name', 'Mobile Number', 'Pending Amount', 'Call Date & Time', 'Call Status'],
                                  rows: filteredLogs.map((log) {
                                    final String studentName = (log['student_name'] ?? 'Student').toString();
                                    final String parentName = (log['parent_name'] ?? 'Parent').toString();
                                    final String mobile = (log['parent_mobile'] ?? 'N/A').toString();
                                    final double amount = double.tryParse(log['amount_due']?.toString() ?? '0') ?? 0.0;
                                    final String rawDate = (log['call_date'] ?? log['created_at'] ?? '').toString();
                                    final String callDateStr = rawDate.isNotEmpty
                                        ? (DateTime.tryParse(rawDate) != null ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(rawDate)!) : rawDate)
                                        : 'N/A';
                                    final String status = (log['status'] ?? log['call_status'] ?? 'Initiated').toString();

                                    final bool isSuccess = status.toLowerCase().contains('success') || status.toLowerCase().contains('initiated') || status.toLowerCase().contains('completed');

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(studentName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataCell(Text(parentName, style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(Text(mobile, style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(Text("₹${amount.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold))),
                                        DataCell(Text(callDateStr, style: GoogleFonts.inter(fontSize: 11))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (isSuccess ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: isSuccess ? AppColors.success : AppColors.danger,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                );
                        }(),
                      ],
                    ),
                  ),
                ),

                // TAB 3: SCHEDULE & SETTINGS
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                            Row(
                              children: [
                                const Icon(Icons.settings_phone_outlined, color: AppColors.adminPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Automatic Calling Schedule",
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Switch(
                                  value: _isEnabled,
                                  onChanged: (val) {
                                    setState(() {
                                      _isEnabled = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            AppSpacing.h16,
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _startDayController,
                                    labelText: "Start Day of Month",
                                    keyboardType: TextInputType.number,
                                    hintText: "1",
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return "Required";
                                      final day = int.tryParse(val);
                                      if (day == null || day < 1 || day > 28) return "1-28 bounds";
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _endDayController,
                                    labelText: "End Day of Month",
                                    keyboardType: TextInputType.number,
                                    hintText: "7",
                                    validator: (val) {
                                      if (val == null || val.isEmpty) return "Required";
                                      final day = int.tryParse(val);
                                      if (day == null || day < 1 || day > 28) return "1-28 bounds";
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.h12,

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Outgoing Phone Numbers Pool",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _addCallerNumber,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text("Add Number"),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _callerNumbersList.map((numStr) {
                                return Chip(
                                  avatar: const Icon(Icons.phone, size: 14, color: AppColors.adminPrimary),
                                  label: Text(numStr, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onDeleted: () {
                                    setState(() {
                                      _callerNumbersList.remove(numStr);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            AppSpacing.h16,

                            // Twilio Gateway Configuration Section
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              initiallyExpanded: false,
                              leading: const Icon(Icons.security, color: AppColors.adminPrimary, size: 20),
                              title: Text(
                                "Twilio Voice API Credentials (Optional)",
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                                  child: Column(
                                    children: [
                                      CustomTextField(
                                        controller: _twilioSidController,
                                        labelText: "Twilio Account SID",
                                        hintText: "ACa1b2c3d4...",
                                        prefixIcon: Icons.key_outlined,
                                      ),
                                      AppSpacing.h12,
                                      CustomTextField(
                                        controller: _twilioTokenController,
                                        labelText: "Twilio Auth Token",
                                        hintText: "Your secret auth token",
                                        obscureText: true,
                                        prefixIcon: Icons.lock_outline,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.h24,

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.adminPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _saveSettings,
                                icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                                label: Text(
                                  "Save Settings",
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            AppSpacing.h12,

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.adminPrimary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _triggerManualSweep,
                                icon: const Icon(Icons.play_arrow_outlined, color: AppColors.adminPrimary, size: 18),
                                label: Text(
                                  "Trigger Manual Reminders Sweep Now",
                                  style: GoogleFonts.inter(color: AppColors.adminPrimary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
