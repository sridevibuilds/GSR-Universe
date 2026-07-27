// Presentation Layer - Fee Details Page (Editable spreadsheet view)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class FeeDetailsPage extends StatefulWidget {
  const FeeDetailsPage({super.key});

  @override
  State<FeeDetailsPage> createState() => _FeeDetailsPageState();
}

class _FeeDetailsPageState extends State<FeeDetailsPage> {
  final _searchController = TextEditingController();
  String _selectedClass = "Class 9";
  String _selectedSection = "A";

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];

  final Map<int, TextEditingController> _totalFeeControllers = {};
  final Map<int, TextEditingController> _paidFeeControllers = {};
  final Map<int, TextEditingController> _pendingFeeControllers = {};

  @override
  void initState() {
    super.initState();
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchFeeDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var c in _totalFeeControllers.values) {
      c.dispose();
    }
    for (var c in _paidFeeControllers.values) {
      c.dispose();
    }
    for (var c in _pendingFeeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _getCommonClassFormat(dynamic val) {
    if (val == null) return '';
    String s = val.toString().trim();
    if (!s.toLowerCase().startsWith('class')) {
      s = 'Class $s';
    }
    return s.replaceAll(RegExp(r'th|st|nd|rd', caseSensitive: false), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Student Fee Details",
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
            if (state.successMessage != null) {
              AppNotifications.showSuccess(context, state.successMessage!);
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            final query = _searchController.text.toLowerCase();

            // Load students matching selected Class and Section
            final classStudents = state.studentsList.where((s) {
              final matchesClass = _getCommonClassFormat(s['class_name']) == _getCommonClassFormat(_selectedClass);
              final matchesSec = s['section'] == _selectedSection;
              final name = (s['student_name'] ?? '').toString().toLowerCase();
              final adm = (s['admission_no'] ?? '').toString().toLowerCase();
              final matchesSearch = query.isEmpty || name.contains(query) || adm.contains(query);
              return matchesClass && matchesSec && matchesSearch;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filters & Search Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<String>(
                                value: _selectedClass,
                                labelText: "Class Target",
                                prefixIcon: Icons.school_outlined,
                                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedClass = val;
                                      _totalFeeControllers.clear();
                                      _paidFeeControllers.clear();
                                      _pendingFeeControllers.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomDropdown<String>(
                                value: _selectedSection,
                                labelText: "Section",
                                prefixIcon: Icons.grid_view_outlined,
                                items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSection = val;
                                      _totalFeeControllers.clear();
                                      _paidFeeControllers.clear();
                                      _pendingFeeControllers.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Search students by name or admission no...",
                            prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                            filled: true,
                            fillColor: AppColors.pageBackground,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: state.isLoading && state.studentsList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : classStudents.isEmpty
                          ? const Center(
                              child: EmptyStateWidget(
                                title: "No Students Found",
                                message: "No enrolled students mapped to the selected class and section.",
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(AppColors.facultyPrimary.withOpacity(0.05)),
                                      columns: [
                                        DataColumn(label: Text("Student Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Admission No", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Parent Mobile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Total Fee (₹)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Fee Paid (₹)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Fee Pending (₹)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Action", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: classStudents.map((student) {
                                        final int scmId = student['student_class_mapping_id'] ?? student['id'] ?? 0;
                                        
                                        // Match existing fee record if available
                                        final feeRecord = state.feeRecords.firstWhere(
                                          (f) => f['student_class_mapping_id'] == scmId || f['admission_no'] == student['admission_no'],
                                          orElse: () => <String, dynamic>{},
                                        );

                                        if (!_totalFeeControllers.containsKey(scmId)) {
                                          _totalFeeControllers[scmId] = TextEditingController(text: (feeRecord['total_fee'] ?? 0).toString());
                                          _paidFeeControllers[scmId] = TextEditingController(text: (feeRecord['paid_amount'] ?? 0).toString());
                                          _pendingFeeControllers[scmId] = TextEditingController(text: (feeRecord['pending_amount'] ?? 0).toString());
                                        }

                                        final String parentMobile = (student['parent_mobile'] ??
                                                student['primary_parent_mobile'] ??
                                                student['secondary_parent_mobile'] ??
                                                feeRecord['parent_mobile'] ??
                                                'N/A')
                                            .toString();

                                        return DataRow(cells: [
                                          DataCell(Text(student['student_name'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                          DataCell(Text(student['admission_no'] ?? 'N/A', style: GoogleFonts.inter())),
                                          DataCell(Text(parentMobile, style: GoogleFonts.inter())),
                                          DataCell(
                                            SizedBox(
                                              width: 90,
                                              child: TextField(
                                                controller: _totalFeeControllers[scmId],
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                                style: GoogleFonts.inter(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 90,
                                              child: TextField(
                                                controller: _paidFeeControllers[scmId],
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                                style: GoogleFonts.inter(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 90,
                                              child: TextField(
                                                controller: _pendingFeeControllers[scmId],
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                                style: GoogleFonts.inter(fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.save_outlined, color: AppColors.facultyPrimary),
                                              onPressed: () {
                                                final double total = double.tryParse(_totalFeeControllers[scmId]?.text ?? '0') ?? 0;
                                                final double paid = double.tryParse(_paidFeeControllers[scmId]?.text ?? '0') ?? 0;
                                                final double pending = double.tryParse(_pendingFeeControllers[scmId]?.text ?? '0') ?? 0;
                                                
                                                context.read<FacultyCubit>().updateStudentFee(scmId, {
                                                  "total_fee": total,
                                                  "paid_amount": paid,
                                                  "pending_amount": pending,
                                                  "remarks": "Updated via Faculty Console"
                                                });
                                              },
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
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
