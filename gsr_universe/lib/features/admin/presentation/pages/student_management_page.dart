// Presentation Layer - Student Management Analytics & PDF Reporting Console
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/stats_card.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  String _selectedYear = '2026-2027';
  String _selectedClass = 'Class 10';
  String _selectedSection = 'A';
  String _selectedTerm = 'Annual';

  final List<String> _academicYears = ['2026-2027', '2025-2026', '2024-2025'];
  final List<String> _classes = [
    'Nursery',
    'LKG',
    'UKG',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10'
  ];
  final List<String> _sections = ['A', 'B', 'C'];
  final List<String> _terms = ['Annual', 'Term 1', 'Term 2', 'Quarterly', 'Half-Yearly'];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    context.read<AdminCubit>().fetchClassReport(
      academicYear: _selectedYear,
      className: _selectedClass,
      section: _selectedSection,
      term: _selectedTerm,
    );
  }

  Future<void> _exportPdfReport(Map<String, dynamic> summary) async {
    final pdf = pw.Document();
    final String generatedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "PIPPARA E.M. HIGH SCHOOL",
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Class Performance Analytics Report",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "Report Generated Date:",
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          generatedDate,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 12),

                // Report Parameters Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Text("Academic Year: $_selectedYear", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text("Class: $_selectedClass", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text("Section: $_selectedSection", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text("Term: $_selectedTerm", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Summary Data Table
                pw.TableHelper.fromTextArray(
                  headers: ['Performance Metric Name', 'Metric Value / Details'],
                  data: [
                    ['Total Students', '${summary['total_students'] ?? 0}'],
                    ['Assessment Performance Avg', '${summary['assessment_performance_pct'] ?? 0}%'],
                    ['Fee Collection Amount', 'Rs. ${summary['fee_collection'] ?? 0}'],
                    ['Pending Fee Amount', 'Rs. ${summary['pending_fee'] ?? 0}'],
                    ['Excellent Students (> 85% Marks)', '${summary['excellent_students'] ?? 0}'],
                    ['Average Students (60-85% Marks)', '${summary['average_students'] ?? 0}'],
                    ['Students Needing Improvement (< 60% Marks)', '${summary['needs_improvement'] ?? 0}'],
                    ['Daily Attendance Rate', '${summary['daily_attendance_pct'] ?? 0}%'],
                    ['Monthly Attendance Rate', '${summary['monthly_attendance_pct'] ?? 0}%'],
                    ['Yearly Attendance Rate', '${summary['yearly_attendance_pct'] ?? 0}%'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  cellHeight: 28,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 30),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "Authorized System Generated Report",
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Class_Report_${_selectedClass}_Section_$_selectedSection.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Student Management & Analytics",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderLight, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Filter selection card
            Container(
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
                  Text(
                    "Report Parameters Selection",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  AppSpacing.h12,
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<String>(
                          labelText: "Academic Year",
                          value: _selectedYear,
                          items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedYear = val);
                              _loadReport();
                            }
                          },
                        ),
                      ),
                      AppSpacing.w12,
                      Expanded(
                        child: CustomDropdown<String>(
                          labelText: "Class",
                          value: _selectedClass,
                          items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedClass = val);
                              _loadReport();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h12,
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<String>(
                          labelText: "Section",
                          value: _selectedSection,
                          items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Section $s"))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSection = val);
                              _loadReport();
                            }
                          },
                        ),
                      ),
                      AppSpacing.w12,
                      Expanded(
                        child: CustomDropdown<String>(
                          labelText: "Term",
                          value: _selectedTerm,
                          items: _terms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTerm = val);
                              _loadReport();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.h20,

            // 2. Report Overview Metrics
            BlocBuilder<AdminCubit, AdminState>(
              builder: (context, state) {
                if (state.isLoading && state.classReport == null) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                final summary = state.classReport?['summary'] ?? {};
                final int totalStudents = summary['total_students'] ?? 0;
                final int perfPct = summary['assessment_performance_pct'] ?? 0;
                final double collection = (summary['fee_collection'] as num? ?? 0.0).toDouble();
                final double pending = (summary['pending_fee'] as num? ?? 0.0).toDouble();
                final int excellent = summary['excellent_students'] ?? 0;
                final int needsImp = summary['needs_improvement'] ?? 0;
                final int dailyAtt = summary['daily_attendance_pct'] ?? 0;
                final int yearlyAtt = summary['yearly_attendance_pct'] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Class Performance Overview",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => _exportPdfReport(summary),
                          borderRadius: BorderRadius.circular(12),
                          child: Tooltip(
                            message: "Download PDF Report",
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.adminPrimary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppColors.softShadow,
                              ),
                              child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h12,

                    // Summary metric cards grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        StatsCard(
                          title: "Total Students",
                          value: totalStudents.toString(),
                          label: "$_selectedClass - $_selectedSection",
                          icon: Icons.groups_outlined,
                          themeColor: AppColors.gradientStart,
                        ),
                        StatsCard(
                          title: "Assessment Avg",
                          value: "$perfPct%",
                          label: "Term: $_selectedTerm",
                          icon: Icons.grade_outlined,
                          themeColor: AppColors.success,
                        ),
                        StatsCard(
                          title: "Fee Collection",
                          value: "₹${(collection / 1000).toStringAsFixed(1)}K",
                          label: "Collected Amount",
                          icon: Icons.account_balance_wallet_outlined,
                          themeColor: Colors.teal,
                        ),
                        StatsCard(
                          title: "Pending Fee",
                          value: "₹${(pending / 1000).toStringAsFixed(1)}K",
                          label: "Outstanding Dues",
                          icon: Icons.money_off_outlined,
                          themeColor: AppColors.danger,
                        ),
                        StatsCard(
                          title: "Excellent Students",
                          value: excellent.toString(),
                          label: "> 85% Marks",
                          icon: Icons.star_outline,
                          themeColor: Colors.amber.shade800,
                        ),
                        StatsCard(
                          title: "Needs Improvement",
                          value: needsImp.toString(),
                          label: "< 60% Marks",
                          icon: Icons.warning_amber_outlined,
                          themeColor: AppColors.danger,
                        ),
                        StatsCard(
                          title: "Daily Attendance",
                          value: "$dailyAtt%",
                          label: "Today's Rate",
                          icon: Icons.today_outlined,
                          themeColor: Colors.indigo,
                        ),
                        StatsCard(
                          title: "Yearly Attendance",
                          value: "$yearlyAtt%",
                          label: "Academic Year Avg",
                          icon: Icons.date_range_outlined,
                          themeColor: AppColors.adminPrimary,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
