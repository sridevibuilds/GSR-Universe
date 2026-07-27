// Presentation Layer - Student Management Page (Faculty Version)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../../../core/widgets/data_table_view.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final _searchController = TextEditingController();
  String _selectedYear = "2026-2027";
  String _selectedClass = "Class 9";
  String _selectedSection = "A";

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

  String _getUIDisplayClass(String? val) {
    if (val == null) return 'Class 9';
    final normalized = val.trim().toLowerCase();
    if (normalized == '9th' || normalized == 'class 9') return 'Class 9';
    if (normalized == '10th' || normalized == 'class 10') return 'Class 10';
    if (normalized == '1st' || normalized == 'class 1') return 'Class 1';
    if (normalized == '2nd' || normalized == 'class 2') return 'Class 2';
    if (normalized == '3rd' || normalized == 'class 3') return 'Class 3';
    final numOnly = RegExp(r'\d+').stringMatch(normalized);
    if (numOnly != null) return 'Class $numOnly';
    return val;
  }

  final List<String> _academicYears = ["2024-2025", "2025-2026", "2026-2027"];
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditStudentDialog({Map<String, dynamic>? student}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: student?['student_name'] ?? '');
    final admController = TextEditingController(text: student?['admission_no'] ?? '');
    final parentController = TextEditingController(text: student?['primary_parent_name'] ?? '');
    final mobileController = TextEditingController(text: student?['primary_parent_mobile'] ?? '');
    final emailController = TextEditingController(text: student?['parent_email'] ?? '');
    final dobController = TextEditingController(text: student?['date_of_birth']?.split('T')[0] ?? '');
    final busController = TextEditingController(text: student?['bus_number'] ?? '');
    final routeController = TextEditingController(text: student?['route_name'] ?? '');
    final pickupController = TextEditingController(text: student?['pickup_point'] ?? '');
    final driverMobileController = TextEditingController(text: student?['driver_mobile'] ?? '');
    bool hasTransport = (student != null && student['bus_number'] != null && student['bus_number'].toString().isNotEmpty);
    String gender = student?['gender'] ?? 'Male';
    String status = student?['status'] ?? 'Active';
    String className = _getUIDisplayClass(student?['class_name'] ?? _selectedClass);
    String section = student?['section'] ?? _selectedSection;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                student == null ? "Add New Student" : "Edit Student Profile",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 450,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextField(
                          controller: nameController,
                          labelText: "Student Name",
                          prefixIcon: Icons.person_outline,
                          validator: (val) => val == null || val.isEmpty ? "Name required" : null,
                        ),
                        AppSpacing.h12,
                        if (student == null) ...[
                          CustomTextField(
                            controller: admController,
                            labelText: "Admission Number",
                            prefixIcon: Icons.badge_outlined,
                            validator: (val) => val == null || val.isEmpty ? "Admission number required" : null,
                          ),
                          AppSpacing.h12,
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<String>(
                                value: className,
                                labelText: "Class",
                                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => className = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomDropdown<String>(
                                value: section,
                                labelText: "Section",
                                items: _sections.map((s) => DropdownMenuItem(value: s, child: Text("Section $s"))).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => section = val);
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
                                value: gender,
                                labelText: "Gender",
                                items: ["Male", "Female", "Other"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => gender = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomDropdown<String>(
                                value: status,
                                labelText: "Status",
                                items: ["Active", "Inactive"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => status = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.h12,
                        CustomTextField(
                          controller: parentController,
                          labelText: "Parent / Guardian Name",
                          prefixIcon: Icons.family_restroom_outlined,
                          validator: (val) => val == null || val.isEmpty ? "Parent name required" : null,
                        ),
                        AppSpacing.h12,
                        CustomTextField(
                          controller: mobileController,
                          labelText: "Parent Mobile Number",
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (val) => val == null || val.length < 10 ? "Valid phone number required" : null,
                        ),
                        AppSpacing.h12,
                        CustomTextField(
                          controller: emailController,
                          labelText: "Parent Email",
                          prefixIcon: Icons.mail_outline,
                        ),
                        AppSpacing.h12,
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dobController.text.isNotEmpty 
                                  ? DateTime.tryParse(dobController.text) ?? DateTime(2015)
                                  : DateTime(2015),
                              firstDate: DateTime(1990),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: dobController,
                              labelText: "Date of Birth (Select Calendar)",
                              prefixIcon: Icons.calendar_today_outlined,
                              validator: (val) => val == null || val.isEmpty ? "Date of birth required" : null,
                            ),
                          ),
                        ),
                        AppSpacing.h12,
                        SwitchListTile(
                          activeColor: AppColors.facultyPrimary,
                          title: Text(
                            "Enable School Transport",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                          ),
                          value: hasTransport,
                          onChanged: (val) {
                            setDialogState(() {
                              hasTransport = val;
                            });
                          },
                        ),
                        if (hasTransport) ...[
                          AppSpacing.h12,
                          CustomTextField(
                            controller: busController,
                            labelText: "Bus Number",
                            prefixIcon: Icons.directions_bus_outlined,
                            validator: (val) => hasTransport && (val == null || val.isEmpty) ? "Bus Number required" : null,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: routeController,
                            labelText: "Route Name",
                            prefixIcon: Icons.alt_route_outlined,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: pickupController,
                            labelText: "Pickup Point",
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          AppSpacing.h12,
                          CustomTextField(
                            controller: driverMobileController,
                            labelText: "Driver Mobile Number",
                            prefixIcon: Icons.phone_android_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.facultyPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final payload = {
                        "student_name": nameController.text.trim(),
                        "class_name": className,
                        "section": section,
                        "primary_parent_name": parentController.text.trim(),
                        "primary_parent_mobile": mobileController.text.trim(),
                        "parent_email": emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                        "date_of_birth": dobController.text.trim().isEmpty ? null : dobController.text.trim(),
                        "gender": gender,
                        "status": status,
                        "bus_number": hasTransport ? busController.text.trim() : null,
                        "route_name": hasTransport ? routeController.text.trim() : null,
                        "pickup_point": hasTransport ? pickupController.text.trim() : null,
                        "driver_mobile": hasTransport ? driverMobileController.text.trim() : null,
                      };

                      if (student == null) {
                        payload["admission_no"] = admController.text.trim();
                        context.read<FacultyCubit>().addStudent(payload);
                      } else {
                        context.read<FacultyCubit>().editStudent(student['id'], payload);
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text(student == null ? "Create" : "Save Changes", style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteStudent(Map<String, dynamic> student) {
    ConfirmationDialog.show(
      context,
      title: "Delete Student Profile",
      content: "Are you sure you want to permanently delete the profile of ${student['student_name']}? This action removes all historical ledger links.",
      confirmText: "Delete",
      confirmColor: AppColors.danger,
      onConfirm: () {
        context.read<FacultyCubit>().removeStudent(student['id']);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          "Student Roster Management",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textDark),
            onPressed: () => context.read<FacultyCubit>().fetchStudents(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.facultyPrimary,
        onPressed: () => _showAddEditStudentDialog(),
        child: const Icon(Icons.add, color: Colors.white),
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
            // Apply filtering logic locally on state.studentsList
            final filteredList = state.studentsList.where((student) {
              // Filters
              final matchClass = _getCommonClassFormat(student['class_name']) == _getCommonClassFormat(_selectedClass);
              final matchSection = student['section'] == _selectedSection;
              final matchYear = student['academic_year'] == _selectedYear || student['academic_year'] == null;
              
              // Search Query
              final name = (student['student_name'] ?? '').toLowerCase();
              final adm = (student['admission_no'] ?? '').toLowerCase();
              final query = _searchController.text.toLowerCase();
              final matchSearch = query.isEmpty || name.contains(query) || adm.contains(query);

              return matchClass && matchSection && matchYear && matchSearch;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Filtering Panel
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 450) {
                                return Column(
                                  children: [
                                    CustomDropdown<String>(
                                      value: _selectedYear,
                                      labelText: "Academic Year",
                                      items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedYear = val);
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomDropdown<String>(
                                            value: _selectedClass,
                                            labelText: "Class",
                                            items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedClass = val);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: CustomDropdown<String>(
                                            value: _selectedSection,
                                            labelText: "Section",
                                            items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedSection = val);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: CustomDropdown<String>(
                                        value: _selectedYear,
                                        labelText: "Academic Year",
                                        items: _academicYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedYear = val);
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
                                          if (val != null) setState(() => _selectedClass = val);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomDropdown<String>(
                                        value: _selectedSection,
                                        labelText: "Section",
                                        items: _sections.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedSection = val);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Data Table List
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: state.isLoading && state.studentsList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : filteredList.isEmpty
                            ? const Center(
                                child: EmptyStateWidget(
                                  title: "No Students Found",
                                  message: "Try tweaking your filter selections or check database mappings.",
                                ),
                              )
                            : SingleChildScrollView(
                                child: DataTableView(
                                  searchPlaceholder: "Search by student name or admission no...",
                                  searchController: _searchController,
                                  onSearchChanged: (val) {
                                    setState(() {});
                                  },
                                  headers: const [
                                    'Photo', 
                                    'Student Name', 
                                    'Admission No', 
                                    'Parent Info', 
                                    'Attendance', 
                                    'Fee Dues', 
                                    'Transport', 
                                    'Status', 
                                    'Actions'
                                  ],
                                  rows: filteredList.map((student) {
                                    final bool isActive = (student['status'] ?? 'Active') == 'Active';
                                    final String name = student['student_name'] ?? 'Student Profile';
                                    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
                                    
                                    Color statusColor = isActive ? Colors.green : Colors.red;
                                    
                                    return DataRow(
                                      cells: [
                                        // 1. Photo
                                        DataCell(
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.facultyPrimary.withOpacity(0.12),
                                            child: Text(
                                              initial,
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.facultyPrimary),
                                            ),
                                          ),
                                        ),
                                        // 2. Student Name
                                        DataCell(
                                          Text(
                                            name,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                          ),
                                        ),
                                        // 3. Admission No
                                        DataCell(
                                          Text(
                                            student['admission_no'] ?? 'N/A',
                                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                                          ),
                                        ),
                                        // 4. Parent Info
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                student['primary_parent_name'] ?? 'N/A',
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                              ),
                                              Text(
                                                student['primary_parent_mobile'] ?? 'N/A',
                                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 5. Attendance
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.adminPrimary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "${double.tryParse(student['attendance_percentage']?.toString() ?? '100')?.toStringAsFixed(1)}%",
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.adminPrimary),
                                            ),
                                          ),
                                        ),
                                        // 6. Fee Dues
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "₹${student['pending_amount'] ?? '0'}",
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[850]),
                                            ),
                                          ),
                                        ),
                                        // 7. Transport
                                        DataCell(
                                          Text(
                                            (student['bus_number'] != null && student['bus_number'].toString().isNotEmpty)
                                                ? "Yes"
                                                : "No",
                                            style: GoogleFonts.inter(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.bold,
                                              color: (student['bus_number'] != null && student['bus_number'].toString().isNotEmpty)
                                                  ? Colors.green
                                                  : AppColors.textLight,
                                            ),
                                          ),
                                        ),
                                        // 8. Status
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isActive ? "ACTIVE" : "INACTIVE",
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // 9. Actions
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: AppColors.adminPrimary, size: 20),
                                                onPressed: () => _showAddEditStudentDialog(student: student),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                                onPressed: () => _confirmDeleteStudent(student),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
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
