// Presentation Layer - Attendance Monitoring Page (Device Sync Visualizer)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class AttendanceMonitoringPage extends StatefulWidget {
  const AttendanceMonitoringPage({super.key});

  @override
  State<AttendanceMonitoringPage> createState() => _AttendanceMonitoringPageState();
}

class _AttendanceMonitoringPageState extends State<AttendanceMonitoringPage> {
  String _selectedYear = "2026-2027";
  String _selectedClass = "Class 9";
  String _selectedSection = "A";
  String _selectedSession = "Morning"; // Morning or Afternoon
  DateTime _selectedDate = DateTime.now();

  final List<String> _academicYears = ["2024-2025", "2025-2026", "2026-2027"];
  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];
  final List<String> _sessions = ["Morning", "Afternoon"];

  @override
  void initState() {
    super.initState();
    // Load student database to resolve class mappings
    context.read<FacultyCubit>().fetchStudents();
  }

  void _loadAttendance(List<Map<String, dynamic>> students) {
    final int? classId = _getClassId(students);
    if (classId != null) {
      final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      context.read<FacultyCubit>().fetchClassAttendanceReport(classId, date: dateStr);
    }
  }

  int? _getClassId(List<Map<String, dynamic>> students) {
    for (var s in students) {
      if (s['class_name'] == _selectedClass && s['section'] == _selectedSection) {
        return s['class_id'] as int?;
      }
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, List<Map<String, dynamic>> students) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendance(students);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Device Attendance Monitor",
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
        child: BlocConsumer<FacultyCubit, FacultyState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              AppNotifications.showError(context, state.errorMessage!);
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            // Trigger loading once studentsList is retrieved if classAttendanceReport is empty
            final classId = _getClassId(state.studentsList);
            final report = state.classAttendanceReport;
            final bool isReportLoaded = report.isNotEmpty && report['classId'] == classId;

            if (state.studentsList.isNotEmpty && !isReportLoaded && !state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadAttendance(state.studentsList);
              });
            }

            final List<dynamic> attendanceList = report['students'] ?? [];
            final totalStudents = report['totalStudents'] ?? attendanceList.length;

            // Calculate current session present/absent
            int presentCount = 0;
            int absentCount = 0;
            for (var item in attendanceList) {
              final status = _selectedSession == "Morning" ? item['morning_status'] : item['afternoon_status'];
              if (status == "Present") {
                presentCount++;
              } else {
                absentCount++;
              }
            }

            final double pct = totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Selector Config Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedYear,
                                  labelText: "Academic Year",
                                  items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedYear = val);
                                      _loadAttendance(state.studentsList);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedClass,
                                  labelText: "Class",
                                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedClass = val);
                                      _loadAttendance(state.studentsList);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedSection,
                                  labelText: "Section",
                                  items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedSection = val);
                                      _loadAttendance(state.studentsList);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomDropdown<String>(
                                  value: _selectedSession,
                                  labelText: "Session",
                                  items: _sessions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedSession = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Date Picker button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: AppColors.borderLight),
                            ),
                            icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.adminPrimary),
                            label: Text(
                              "Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            onPressed: () => _selectDate(context, state.studentsList),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Summary stats header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Total",
                          value: totalStudents.toString(),
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Present",
                          value: presentCount.toString(),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Absent",
                          value: absentCount.toString(),
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Rate",
                          value: "${pct.toStringAsFixed(1)}%",
                          color: AppColors.facultyPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 3. Attendance Roster Table List
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : attendanceList.isEmpty
                          ? const Center(
                              child: EmptyStateWidget(
                                title: "No Device Logs Today",
                                message: "No sync data received from physical Barcode/QR device for this parameters combination.",
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: attendanceList.length,
                              itemBuilder: (context, index) {
                                final student = attendanceList[index];
                                final mStatus = student['morning_status'] ?? 'Absent';
                                final aStatus = student['afternoon_status'] ?? 'Absent';
                                final currentStatus = _selectedSession == "Morning" ? mStatus : aStatus;
                                final bool isPresent = currentStatus == 'Present';

                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: Colors.white,
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      child: Text(
                                        "${student['class_roll_number'] ?? (index + 1)}",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: isPresent ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      student['student_name'] ?? 'Student Profile',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                    subtitle: Text(
                                      "Adm No: ${student['admission_no']} • Morn: ${mStatus == 'Present' ? '✔' : '✖'} • Aft: ${aStatus == 'Present' ? '✔' : '✖'}",
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPresent ? Icons.check : Icons.close,
                                        color: isPresent ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 9, color: AppColors.textLight, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
