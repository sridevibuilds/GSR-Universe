// Presentation Layer - Student Promotion Console
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class StudentPromotionPage extends StatefulWidget {
  const StudentPromotionPage({super.key});

  @override
  State<StudentPromotionPage> createState() => _StudentPromotionPageState();
}

class _StudentPromotionPageState extends State<StudentPromotionPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedSourceClass = "Class 9";
  String _selectedSourceSection = "A";
  int? _sourceYearId;

  String _selectedDestClass = "Class 10";
  String _selectedDestSection = "A";
  int? _destYearId;

  final List<int> _selectedStudentIds = [];

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];

  @override
  void initState() {
    super.initState();
    context.read<FacultyCubit>().fetchStudents();
  }

  String _getCommonClassFormat(dynamic val) {
    if (val == null) return '';
    String s = val.toString().trim();
    if (!s.toLowerCase().startsWith('class')) {
      s = 'Class $s';
    }
    return s.replaceAll(RegExp(r'th|st|nd|rd', caseSensitive: false), '').trim();
  }

  void _triggerPromotions() {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudentIds.isEmpty) {
        AppNotifications.showError(context, "Select at least one student to promote.");
        return;
      }
      if (_selectedDestClass == _selectedSourceClass && 
          _selectedDestSection == _selectedSourceSection && 
          _destYearId == _sourceYearId) {
        AppNotifications.showError(context, "Destination Class and Year cannot be identical to Source.");
        return;
      }

      final firstStudent = context.read<FacultyCubit>().state.studentsList.firstWhere(
        (s) => s['id'] == _selectedStudentIds.first,
        orElse: () => <String, dynamic>{},
      );
      final int? sourceClassId = firstStudent['class_id'];
      if (sourceClassId == null) {
        AppNotifications.showError(context, "Cannot find source class mapping.");
        return;
      }

      ConfirmationDialog.show(
        context,
        title: "Promote Students",
        content: "Are you sure you want to promote ${_selectedStudentIds.length} students? This transaction is permanent and creates new academic mappings.",
        confirmText: "Promote",
        onConfirm: () {
          context.read<FacultyCubit>().promoteClassStudents(
                currentYearId: _sourceYearId!,
                destinationYearId: _destYearId!,
                currentClassId: sourceClassId,
                destinationClassName: _selectedDestClass,
                destinationSection: _selectedDestSection,
                studentIds: _selectedStudentIds,
              );
        },
      );
    }
  }

  void _showCreateYearDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Create Academic Year", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: "Academic Year Name (YYYY-YYYY)",
              hintText: "e.g. 2027-2028",
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final val = controller.text.trim();
                if (RegExp(r'^\d{4}-\d{4}$').hasMatch(val)) {
                  context.read<FacultyCubit>().addAcademicYear(val);
                  Navigator.pop(ctx);
                } else {
                  AppNotifications.showError(context, "Invalid format. Use YYYY-YYYY (e.g. 2027-2028).");
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FacultyCubit, FacultyState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppNotifications.showError(context, state.errorMessage!);
          context.read<FacultyCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          AppNotifications.showSuccess(context, state.successMessage!);
          setState(() {
            _selectedStudentIds.clear();
          });
          context.read<FacultyCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final Map<int, String> years = {};
        final Set<String> seenYearNames = {};

        for (var student in state.studentsList) {
          final int? yId = student['academic_year_id'];
          final String? yName = student['academic_year'];
          if (yId != null && yName != null && !seenYearNames.contains(yName)) {
            years[yId] = yName;
            seenYearNames.add(yName);
          }
        }

        final List<Map<String, dynamic>> standardYears = [
          {"id": 1, "name": "2026-2027"},
          {"id": 2, "name": "2027-2028"},
        ];
        for (var y in standardYears) {
          if (!seenYearNames.contains(y['name'])) {
            years[y['id']] = y['name'];
            seenYearNames.add(y['name']);
          }
        }

        if (_sourceYearId == null && years.isNotEmpty) {
          _sourceYearId = years.keys.first;
        }
        if (_destYearId == null && years.isNotEmpty) {
          _destYearId = years.keys.length > 1 ? years.keys.elementAt(1) : years.keys.first;
        }

        final currentStudents = state.studentsList.where((s) {
          return _getCommonClassFormat(s['class_name']) == _getCommonClassFormat(_selectedSourceClass) &&
                 s['section'] == _selectedSourceSection &&
                 s['academic_year_id'] == _sourceYearId;
        }).toList();

        // Build clean Dropdown items with 'Create New Academic Year' option for BOTH Source & Destination dropdowns
        List<DropdownMenuItem<int>> buildYearItems(String label) {
          final List<DropdownMenuItem<int>> items = years.entries.map((e) {
            return DropdownMenuItem<int>(value: e.key, child: Text(e.value));
          }).toList();

          items.add(
            DropdownMenuItem<int>(
              value: -1,
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppColors.facultyPrimary, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Create New Academic Year",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.facultyPrimary),
                    ),
                  ),
                ],
              ),
            ),
          );
          return items;
        }

        final sourceYearItems = buildYearItems("Source");
        final destYearItems = buildYearItems("Destination");

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Student Promotion Portal",
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
            child: state.isLoading && state.studentsList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
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
                                  "Class & Term Parameters",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                ),
                                AppSpacing.h16,
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomDropdown<String>(
                                        value: _selectedSourceClass,
                                        labelText: "Source Class",
                                        prefixIcon: Icons.school_outlined,
                                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedSourceClass = val;
                                              _selectedStudentIds.clear();
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomDropdown<String>(
                                        value: _selectedSourceSection,
                                        labelText: "Section",
                                        prefixIcon: Icons.grid_view_outlined,
                                        items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedSourceSection = val;
                                              _selectedStudentIds.clear();
                                            });
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
                                      child: CustomDropdown<int>(
                                        value: _sourceYearId,
                                        labelText: "Source Year",
                                        prefixIcon: Icons.calendar_today_outlined,
                                        items: sourceYearItems,
                                        onChanged: (val) {
                                          if (val == -1) {
                                            _showCreateYearDialog();
                                          } else {
                                            setState(() {
                                              _sourceYearId = val;
                                              _selectedStudentIds.clear();
                                            });
                                          }
                                        },
                                        validator: (val) => val == null ? "Required" : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomDropdown<int>(
                                        value: _destYearId,
                                        labelText: "Destination Year",
                                        prefixIcon: Icons.calendar_month_outlined,
                                        items: destYearItems,
                                        onChanged: (val) {
                                          if (val == -1) {
                                            _showCreateYearDialog();
                                          } else {
                                            setState(() => _destYearId = val);
                                          }
                                        },
                                        validator: (val) => val == null ? "Required" : null,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.h12,
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomDropdown<String>(
                                        value: _selectedDestClass,
                                        labelText: "Destination Class",
                                        prefixIcon: Icons.arrow_forward_outlined,
                                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedDestClass = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomDropdown<String>(
                                        value: _selectedDestSection,
                                        labelText: "Section",
                                        prefixIcon: Icons.grid_view_outlined,
                                        items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Sec $s"))).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedDestSection = val;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Students Roster (${currentStudents.length})",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                              ),
                              if (currentStudents.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_selectedStudentIds.length == currentStudents.length) {
                                        _selectedStudentIds.clear();
                                      } else {
                                        _selectedStudentIds.clear();
                                        _selectedStudentIds.addAll(currentStudents.map((s) => s['id'] as int));
                                      }
                                    });
                                  },
                                  child: Text(
                                    _selectedStudentIds.length == currentStudents.length ? "Deselect All" : "Select All",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.facultyPrimary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: currentStudents.isEmpty
                              ? const Center(
                                  child: EmptyStateWidget(
                                    title: "No Students Found",
                                    message: "Please choose class parameters to view student profiles.",
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: currentStudents.length,
                                  separatorBuilder: (context, index) => const Divider(color: AppColors.borderLight, height: 1.0),
                                  itemBuilder: (context, index) {
                                    final student = currentStudents[index];
                                    final bool isChecked = _selectedStudentIds.contains(student['id']);

                                    return CheckboxListTile(
                                      activeColor: AppColors.facultyPrimary,
                                      title: Text(
                                        student['student_name'] ?? 'Student Profile',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        "Admission No: ${student['admission_no'] ?? 'N/A'} • Class: ${student['class_name'] ?? _selectedSourceClass} ${student['section'] ?? _selectedSourceSection}",
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                      ),
                                      value: isChecked,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedStudentIds.add(student['id']);
                                          } else {
                                            _selectedStudentIds.remove(student['id']);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.facultyPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: state.isLoading ? null : _triggerPromotions,
                              child: state.isLoading
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                  : Text(
                                      "Promote Selected (${_selectedStudentIds.length})",
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
