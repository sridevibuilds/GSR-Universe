// Presentation Layer - Assessments Management Console (CRUD & Marks Entry)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class AssessmentsPage extends StatefulWidget {
  const AssessmentsPage({super.key});

  @override
  State<AssessmentsPage> createState() => _AssessmentsPageState();
}

class _AssessmentsPageState extends State<AssessmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers
  String _selectedClass = "Class 9";
  String _selectedSection = "A";
  String _selectedSubject = "Mathematics";
  final _assessmentNameController = TextEditingController();
  final _maxMarksController = TextEditingController();
  final _assessmentDateController = TextEditingController();
  final _descController = TextEditingController();

  // Student Marks controllers
  final Map<int, TextEditingController> _marksControllers = {};

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];
  final List<String> _subjects = [
    "Telugu", "English", "Hindi", "Mathematics", "Physics", "Chemistry", "Biology", "Social", "Computer", "General Knowledge"
  ];

  String _getCommonClassFormat(String? val) {
    if (val == null) return '';
    final normalized = val.trim().toLowerCase();
    if (normalized == '9th' || normalized == 'class 9') return '9';
    if (normalized == '10th' || normalized == 'class 10') return '10';
    if (normalized == '1st' || normalized == 'class 1') return '1';
    if (normalized == '2nd' || normalized == 'class 2') return '2';
    if (normalized == '3rd' || normalized == 'class 3') return '3';
    final numOnly = RegExp(r'\d+').stringMatch(normalized);
    if (numOnly != null) return numOnly;
    return normalized;
  }

  String _getCleanClassDisplay(dynamic val) {
    if (val == null) return '';
    String s = val.toString().trim();
    if (s.toLowerCase().startsWith('class')) {
      return s;
    }
    return "Class $s";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<FacultyCubit>().fetchStudents();
    context.read<FacultyCubit>().fetchAssessments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assessmentNameController.dispose();
    _maxMarksController.dispose();
    _assessmentDateController.dispose();
    _descController.dispose();
    for (var controller in _marksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onClassSectionChanged() {
    setState(() {
      _marksControllers.clear();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _assessmentDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitAssessment(BuildContext context, int facultyId, int yearId) {
    if (!_formKey.currentState!.validate()) {
      AppNotifications.showError(context, "Please fill all required fields correctly.");
      return;
    }

    final String name = _assessmentNameController.text.trim();
    final String maxMarksStr = _maxMarksController.text.trim();
    final String date = _assessmentDateController.text.trim();
    final String desc = _descController.text.trim();

    final maxMarks = int.tryParse(maxMarksStr);
    if (maxMarks == null || maxMarks <= 0) {
      AppNotifications.showError(context, "Maximum Marks must be a valid positive integer.");
      return;
    }

    final state = context.read<FacultyCubit>().state;
    final classStudents = state.studentsList.where((s) {
      return _getCommonClassFormat(s['class_name']) == _getCommonClassFormat(_selectedClass) &&
          s['section'] == _selectedSection;
    }).toList();

    if (classStudents.isEmpty) {
      AppNotifications.showError(context, "No students are enrolled in the selected class and section.");
      return;
    }

    final List<Map<String, dynamic>> studentMarks = [];
    for (var student in classStudents) {
      final int scmId = student['student_class_mapping_id'] ?? 0;
      final String marksStr = _marksControllers[scmId]?.text.trim() ?? '';

      if (marksStr.isEmpty) {
        AppNotifications.showError(context, "Please enter marks for all students.");
        return;
      }

      final obtained = double.tryParse(marksStr);
      if (obtained == null || obtained < 0) {
        AppNotifications.showError(context, "Obtained marks must be a valid non-negative number.");
        return;
      }

      if (obtained > maxMarks) {
        AppNotifications.showError(context, "Obtained marks for ${student['student_name']} cannot exceed maximum marks ($maxMarks).");
        return;
      }

      studentMarks.add({
        "student_class_mapping_id": scmId,
        "marks_obtained": obtained,
        "remarks": "Good",
      });
    }

    final payload = {
      "class_name": _selectedClass,
      "section": _selectedSection,
      "subject": _selectedSubject,
      "title": name,
      "max_marks": maxMarks,
      "assessment_date": date.isEmpty ? null : date,
      "academic_year_id": yearId,
      "created_by": facultyId,
      "student_marks": studentMarks,
      "description": desc,
    };

    context.read<FacultyCubit>().addAssessment(payload);
  }

  String _safeString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null' || str == 'N/A') return fallback;
    return str;
  }

  void _confirmDeleteAssessment(Map<String, dynamic> exam) {
    final String title = (exam['title'] ?? exam['assessment_type'] ?? 'this assessment').toString();
    ConfirmationDialog.show(
      context,
      title: "Delete Assessment Record",
      content: "Are you sure you want to delete '$title' and all recorded student marks? This action cannot be undone.",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeAssessment(exam['id']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Assessments Portal",
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
            Tab(icon: Icon(Icons.assessment_outlined), text: "Assessment Registry"),
            Tab(icon: Icon(Icons.history_outlined), text: "Assessment History"),
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
              AppNotifications.showSuccess(context, "Assessment and student marks submitted successfully!");
              
              // Clear fields on success
              _assessmentNameController.clear();
              _maxMarksController.clear();
              _assessmentDateController.clear();
              _descController.clear();
              _marksControllers.clear();
              
              // Switch to History
              _tabController.animateTo(1);
              context.read<FacultyCubit>().clearMessages();
            }
          },
          builder: (context, state) {
            // Find active Auth details
            int facultyId = 1;
            int yearId = 1;
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthAuthenticated) {
              facultyId = authState.payload['id'] ?? 1;
              yearId = authState.payload['academic_year_id'] ?? 1;
            }

            // Filter students for current class & section selections
            final classStudents = state.studentsList.where((s) {
              return _getCommonClassFormat(s['class_name']) == _getCommonClassFormat(_selectedClass) &&
                  s['section'] == _selectedSection;
            }).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Assessment Registry (Form & Student Marks Sheet)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
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
                              Text(
                                "Define Assessment Details",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomDropdown<String>(
                                      value: _selectedClass,
                                      labelText: "Class Target",
                                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedClass = val);
                                          _onClassSectionChanged();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomDropdown<String>(
                                      value: _selectedSection,
                                      labelText: "Section",
                                      items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedSection = val);
                                          _onClassSectionChanged();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              CustomDropdown<String>(
                                value: _selectedSubject,
                                labelText: "Subject",
                                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSubject = val);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _assessmentNameController,
                                labelText: "Assessment Name",
                                hintText: "e.g. Quarterly Exam / Slip Test 1",
                                validator: (val) => val == null || val.trim().isEmpty ? "Required" : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _maxMarksController,
                                      labelText: "Maximum Marks",
                                      hintText: "e.g. 50 or 100",
                                      keyboardType: TextInputType.number,
                                      validator: (val) => val == null || val.trim().isEmpty ? "Required" : null,
                                      onChanged: (val) {
                                        // Refresh student list error styling if max marks changes
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _selectDate(context),
                                      child: AbsorbPointer(
                                        child: CustomTextField(
                                          controller: _assessmentDateController,
                                          labelText: "Assessment Date",
                                          prefixIcon: Icons.calendar_month_outlined,
                                          validator: (val) => val == null || val.trim().isEmpty ? "Required" : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                controller: _descController,
                                labelText: "Description (Optional)",
                                hintText: "e.g. Topics covered: Chapter 1 & 2",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Student Marks List",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      classStudents.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Center(
                                child: Text(
                                  "No students found in the selected class and section.",
                                  style: GoogleFonts.inter(color: AppColors.textLight),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Column(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        dividerColor: AppColors.borderLight,
                                      ),
                                      child: DataTable(
                                        headingRowColor: WidgetStateProperty.all(AppColors.facultyPrimary.withOpacity(0.05)),
                                        columns: [
                                          DataColumn(label: Text("Student Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                          DataColumn(label: Text("Obtained Marks", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        ],
                                        rows: classStudents.map((student) {
                                          final int scmId = student['student_class_mapping_id'] ?? 0;
                                          if (!_marksControllers.containsKey(scmId)) {
                                            _marksControllers[scmId] = TextEditingController();
                                          }
                                          return DataRow(cells: [
                                            DataCell(Text(
                                              student['student_name'] ?? 'Student Profile',
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                            )),
                                            DataCell(
                                              SizedBox(
                                                width: 80,
                                                height: 38,
                                                child: TextField(
                                                  controller: _marksControllers[scmId],
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(fontSize: 13),
                                                  decoration: const InputDecoration(
                                                    hintText: "Score",
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.facultyPrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: state.isLoading ? null : () => _submitAssessment(context, facultyId, yearId),
                                        child: state.isLoading
                                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                            : Text("Submit Marks", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),

                // TAB 2: Assessment History (Read-only view of previously submitted assessments)
                state.assessmentsList.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: "No History Found",
                          message: "Previously submitted assessments will appear here.",
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.assessmentsList.length,
                        itemBuilder: (context, index) {
                          final exam = state.assessmentsList[index];
                          final String title = _safeString(exam['title'] ?? exam['assessment_type'], 'Assessment Test');
                          final String subject = _safeString(exam['subject'] ?? exam['subject_name'], 'General');
                          final String maxMarks = _safeString(exam['max_marks'] ?? exam['total_marks'], '50');
                          final String dateStr = _safeString(exam['assessment_date']?.toString().split('T')[0], 'N/A');
                          
                          String submissionDateStr = 'N/A';
                          if (exam['created_at'] != null && exam['created_at'].toString().toLowerCase() != 'null') {
                            try {
                              submissionDateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(exam['created_at'].toString()));
                            } catch (_) {
                              submissionDateStr = dateStr;
                            }
                          } else {
                            submissionDateStr = dateStr;
                          }

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.facultyPrimary.withOpacity(0.1),
                                child: const Icon(Icons.assignment_turned_in_outlined, color: AppColors.facultyPrimary),
                              ),
                              title: Text(
                                title,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              subtitle: Text(
                                "$title — $subject — ${_getCleanClassDisplay(exam['class_name'])} ${exam['section'] ?? ''}\n"
                                "Max Marks: $maxMarks • Test Date: $dateStr\n"
                                "Submitted on: $submissionDateStr",
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight, height: 1.4),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
                                tooltip: "Delete Assessment Marks",
                                onPressed: () => _confirmDeleteAssessment(exam),
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
