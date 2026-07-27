// Presentation Layer - Parent View Attendance Logs Screen (Responsive Table)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentAttendancePage extends StatefulWidget {
  const ParentAttendancePage({super.key});

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> {
  String _selectedFilterView = 'Today'; // Options: 'Today', 'Till Now'
  DateTime? _fromDate;
  DateTime? _toDate;

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime initial = _fromDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.parentPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime initial = _toDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.parentPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  void _resetDates() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final profile = state.profileData ?? {};
        final String studentName = profile['student_name'] ?? 'Rahul Kumar';
        final List<dynamic> allLogs = state.attendanceLogs;
        final DateTime now = DateTime.now();
        final String todayFormattedDate = DateFormat('dd-MM-yyyy').format(now);

        final bool hasCustomDateRange = _fromDate != null || _toDate != null;

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Attendance Logs",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. FILTER ROW SECTION
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Filter View Dropdown ('Today', 'Till Now')
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.parentPrimary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.2)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFilterView,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.parentPrimary, size: 20),
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.parentPrimary, fontSize: 13),
                                    items: const [
                                      DropdownMenuItem(value: 'Today', child: Text("Today")),
                                      DropdownMenuItem(value: 'Till Now', child: Text("Till Now")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedFilterView = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // From Date Picker
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _selectFromDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.parentPrimary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _fromDate != null ? DateFormat('dd-MM-yyyy').format(_fromDate!) : "From Date",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: _fromDate != null ? FontWeight.bold : FontWeight.w500,
                                            color: _fromDate != null ? AppColors.textDark : AppColors.textLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // To Date Picker
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () => _selectToDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.parentPrimary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _toDate != null ? DateFormat('dd-MM-yyyy').format(_toDate!) : "To Date",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: _toDate != null ? FontWeight.bold : FontWeight.w500,
                                            color: _toDate != null ? AppColors.textDark : AppColors.textLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasCustomDateRange) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.clear, size: 14, color: AppColors.danger),
                                label: Text(
                                  "Clear Date Filter",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                                ),
                                onPressed: _resetDates,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. ATTENDANCE TABLE DISPLAY
                  if (!hasCustomDateRange && _selectedFilterView == 'Today') ...[
                    // TODAY TABLE VIEW
                    _buildTodayAttendanceTable(
                      studentName: studentName,
                      todayDateStr: todayFormattedDate,
                      allLogs: allLogs,
                      today: now,
                    ),
                  ] else ...[
                    // TILL NOW / DATE RANGE PERCENTAGE TABLE VIEW
                    _buildPercentageAttendanceTable(
                      studentName: studentName,
                      allLogs: allLogs,
                      fromDate: _fromDate,
                      toDate: _toDate,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // WIDGET 1: TODAY ATTENDANCE TABLE
  Widget _buildTodayAttendanceTable({
    required String studentName,
    required String todayDateStr,
    required List<dynamic> allLogs,
    required DateTime today,
  }) {
    // Find today's logs from backend
    final todayLogs = allLogs.where((log) {
      final dStr = log['attendance_date']?.toString();
      if (dStr == null) return false;
      final DateTime dt = DateTime.tryParse(dStr) ?? DateTime.now();
      return dt.year == today.year && dt.month == today.month && dt.day == today.day;
    }).toList();

    String morningStatus = "Absent";
    String afternoonStatus = "Absent";

    for (final log in todayLogs) {
      final String session = log['session']?.toString() ?? 'Morning';
      final String status = log['status']?.toString() ?? 'Absent';

      if (session.contains('Morning') || session.contains('Daily')) {
        morningStatus = (status == 'Present' || status == 'Late') ? status : 'Absent';
      }
      if (session.contains('Afternoon')) {
        afternoonStatus = (status == 'Present' || status == 'Late') ? status : 'Absent';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.parentPrimary,
            child: Row(
              children: [
                const Icon(Icons.today, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Today's Attendance ($todayDateStr)",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
              ],
            ),
          ),

          // Responsive Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.parentPrimary.withValues(alpha: 0.06)),
              columnSpacing: 24,
              horizontalMargin: 16,
              columns: [
                DataColumn(
                  label: Text(
                    "Student Name",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Date",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Morning Session",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Afternoon Session",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                  ),
                ),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        studentName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                    DataCell(
                      Text(
                        todayDateStr,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                      ),
                    ),
                    DataCell(
                      _buildStatusBadge(morningStatus),
                    ),
                    DataCell(
                      _buildStatusBadge(afternoonStatus),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET 2: PERCENTAGE ATTENDANCE TABLE (TILL NOW / DATE RANGE)
  Widget _buildPercentageAttendanceTable({
    required String studentName,
    required List<dynamic> allLogs,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    // Filter logs between fromDate and toDate if set
    final filteredLogs = allLogs.where((log) {
      final dStr = log['attendance_date']?.toString();
      if (dStr == null) return false;
      final DateTime dt = DateTime.tryParse(dStr) ?? DateTime.now();

      if (fromDate != null) {
        final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
        if (dt.isBefore(start)) return false;
      }
      if (toDate != null) {
        final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);
        if (dt.isAfter(end)) return false;
      }
      return true;
    }).toList();

    int presentCount = 0;
    int totalCount = filteredLogs.length;

    for (final log in filteredLogs) {
      final status = log['status']?.toString() ?? 'Absent';
      if (status == 'Present' || status == 'Late') {
        presentCount++;
      }
    }

    final double percentage = totalCount > 0 ? ((presentCount / totalCount) * 100) : 100.0;
    final String pctStr = "${percentage.toStringAsFixed(0)}%";

    String rangeLabel = "Till Now Cumulative Attendance";
    if (fromDate != null && toDate != null) {
      rangeLabel = "${DateFormat('dd-MM-yyyy').format(fromDate)} to ${DateFormat('dd-MM-yyyy').format(toDate)}";
    } else if (fromDate != null) {
      rangeLabel = "From ${DateFormat('dd-MM-yyyy').format(fromDate)} onwards";
    } else if (toDate != null) {
      rangeLabel = "Up to ${DateFormat('dd-MM-yyyy').format(toDate)}";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: AppColors.parentPrimary,
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rangeLabel,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Responsive Data Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.parentPrimary.withValues(alpha: 0.06)),
              columnSpacing: 48,
              horizontalMargin: 24,
              columns: [
                DataColumn(
                  label: Text(
                    "Student Name",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Attendance %",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                  ),
                ),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        studentName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          pctStr,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATUS BADGE HELPER
  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.danger.withValues(alpha: 0.1);
    Color fg = AppColors.danger;
    IconData icon = Icons.close;

    if (status == 'Present') {
      bg = AppColors.success.withValues(alpha: 0.1);
      fg = AppColors.success;
      icon = Icons.check_circle_outline;
    } else if (status == 'Late') {
      bg = AppColors.warning.withValues(alpha: 0.1);
      fg = AppColors.warning;
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
