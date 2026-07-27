// Presentation Layer - Faculty Management CRUD Console
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/data_table_view.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class FacultyManagementPage extends StatefulWidget {
  const FacultyManagementPage({super.key});

  @override
  State<FacultyManagementPage> createState() => _FacultyManagementPageState();
}

class _FacultyManagementPageState extends State<FacultyManagementPage> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().fetchFaculty();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFacultyForm(BuildContext parentContext, {Map<String, dynamic>? faculty}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: faculty?['faculty_name']);
    final emailController = TextEditingController(text: faculty?['email']);
    final subjectController = TextEditingController(text: faculty?['subject']);
    final mobileController = TextEditingController(text: faculty?['mobile']);
    final passwordController = TextEditingController();
    String selectedStatus = faculty?['status'] ?? (faculty?['is_active'] == false ? 'INACTIVE' : 'ACTIVE');

    showDialog(
      context: parentContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                faculty == null ? "Register Faculty" : "Edit Faculty Details",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextField(
                        controller: nameController,
                        labelText: "Full Name",
                        prefixIcon: Icons.person_outline,
                        validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                      ),
                      AppSpacing.h12,
                      CustomTextField(
                        controller: emailController,
                        labelText: "Email Address",
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (val) => val == null || val.isEmpty ? "Email is required" : null,
                      ),
                      AppSpacing.h12,
                      CustomTextField(
                        controller: subjectController,
                        labelText: "Specialist Subject",
                        prefixIcon: Icons.book_outlined,
                        validator: (val) => val == null || val.isEmpty ? "Subject is required" : null,
                      ),
                      AppSpacing.h12,
                      CustomTextField(
                        controller: mobileController,
                        labelText: "Mobile Number",
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_outlined,
                        validator: (val) => val == null || val.isEmpty ? "Mobile number is required" : null,
                      ),
                      AppSpacing.h12,
                      if (faculty == null) ...[
                        CustomTextField(
                          controller: passwordController,
                          labelText: "Password",
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (val) => val == null || val.isEmpty ? "Password is required" : null,
                        ),
                        AppSpacing.h12,
                      ],
                      CustomDropdown<String>(
                        labelText: "Account Status",
                        initialValue: selectedStatus,
                        items: const [
                          DropdownMenuItem(value: "ACTIVE", child: Text("ACTIVE")),
                          DropdownMenuItem(value: "INACTIVE", child: Text("INACTIVE")),
                          DropdownMenuItem(value: "SUSPENDED", child: Text("SUSPENDED")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStatus = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.inter(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        "employee_id": faculty?['employee_id'] ?? "EMP${(1000 + (nameController.text.hashCode % 8999)).abs()}",
                        "faculty_name": nameController.text.trim(),
                        "email": emailController.text.trim(),
                        "subject": subjectController.text.trim(),
                        "mobile": mobileController.text.trim(),
                        "role": "FACULTY",
                        "status": selectedStatus,
                        "is_active": selectedStatus == "ACTIVE",
                      };
                      if (faculty == null) {
                        data["password"] = passwordController.text;
                        parentContext.read<AdminCubit>().addFaculty(data);
                      } else {
                        parentContext.read<AdminCubit>().editFaculty(faculty['id'], data);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "Save",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.danger),
          );
          context.read<AdminCubit>().clearMessages();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.success),
          );
          context.read<AdminCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final filteredList = state.facultyList.where((f) {
          final name = (f['faculty_name'] ?? '').toString().toLowerCase();
          final subject = (f['subject'] ?? '').toString().toLowerCase();
          final email = (f['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || subject.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

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
              "Faculty Management Roster",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textDark),
                onPressed: () => context.read<AdminCubit>().fetchFaculty(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.adminPrimary,
            onPressed: () => _showFacultyForm(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: ShimmerListLoader())
                        : filteredList.isEmpty
                            ? EmptyStateWidget(
                                title: "No Faculty Found",
                                message: _searchQuery.isEmpty
                                    ? "Get started by adding your school's first teacher."
                                    : "No records matched your search query.",
                                onAction: _searchQuery.isEmpty
                                    ? () => _showFacultyForm(context)
                                    : null,
                                actionLabel: "Add Faculty",
                              )
                            : SingleChildScrollView(
                                child: DataTableView(
                                  searchPlaceholder: "Search by name, subject, email...",
                                  searchController: _searchController,
                                  onSearchChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.toLowerCase();
                                    });
                                  },
                                  headers: const ['Photo', 'Faculty Name', 'Subject', 'Mobile', 'Status', 'Actions'],
                                  rows: filteredList.map((f) {
                                    final String status = f['status'] ?? (f['is_active'] == false ? 'INACTIVE' : 'ACTIVE');
                                    final String name = f['faculty_name'] ?? 'Faculty';
                                    final String email = f['email'] ?? '';
                                    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'F';

                                    Color statusColor = AppColors.success;
                                    if (status == 'INACTIVE') statusColor = AppColors.danger;
                                    if (status == 'SUSPENDED') statusColor = Colors.orange.shade800;

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.adminPrimary.withOpacity(0.12),
                                            child: Text(
                                              initial,
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.adminPrimary),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                                              Text(email, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(f['subject'] ?? '', style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(Text(f['mobile'] ?? '', style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              status,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, color: AppColors.gradientStart, size: 20),
                                                onPressed: () => _showFacultyForm(context, faculty: f),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  status == 'ACTIVE' ? Icons.block_outlined : Icons.check_circle_outline,
                                                  color: status == 'ACTIVE' ? Colors.orange.shade800 : AppColors.success,
                                                  size: 20,
                                                ),
                                                tooltip: status == 'ACTIVE' ? 'Disable' : 'Enable',
                                                onPressed: () {
                                                  final newStatus = status == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
                                                  context.read<AdminCubit>().editFaculty(f['id'], {
                                                    'status': newStatus,
                                                    'is_active': newStatus == 'ACTIVE'
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                                onPressed: () {
                                                  ConfirmationDialog.show(
                                                    context,
                                                    title: "Delete Faculty",
                                                    content: "Are you sure you want to remove $name from the school records?",
                                                    confirmText: "Delete",
                                                    confirmColor: AppColors.danger,
                                                    onConfirm: () {
                                                      context.read<AdminCubit>().removeFaculty(f['id']);
                                                    },
                                                  );
                                                },
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
