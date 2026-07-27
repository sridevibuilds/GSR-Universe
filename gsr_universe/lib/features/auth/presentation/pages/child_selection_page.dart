// Presentation Layer - Child Selection Page (Parent Role Multi-Child Selector)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class ChildSelectionPage extends StatefulWidget {
  final List<dynamic> students; // List of student records linked to parent mobile
  final String token;

  const ChildSelectionPage({
    super.key,
    required this.students,
    required this.token,
  });

  @override
  State<ChildSelectionPage> createState() => _ChildSelectionPageState();
}

class _ChildSelectionPageState extends State<ChildSelectionPage> {
  int? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LoginCubit>(),
      child: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            // Update AuthCubit and redirect to dashboard
            context.read<AuthCubit>().authenticate(state.token);
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.parentDashboard, (route) => false);
          }
          if (state is LoginFailure) {
            setState(() {
              _selectedStudentId = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          // If state is loading, show progress indicator overlays
          final bool isSwitching = state is LoginLoading;

          return Scaffold(
            backgroundColor: AppColors.pageBackground,
            appBar: AppBar(
              title: Text(
                "Select Child",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Associated Profiles",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Multiple student profiles are associated with your phone number. Select one to proceed to the portal.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Render list of associated children profiles
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.students.length,
                        itemBuilder: (context, index) {
                          final Map<String, dynamic> student = Map<String, dynamic>.from(widget.students[index]);
                          final bool isSelected = _selectedStudentId == student['id'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildStudentCard(
                              context,
                              student: student,
                              isSelected: isSelected,
                              isSwitching: isSwitching && isSelected,
                              onTap: isSwitching
                                  ? () {}
                                  : () {
                                      setState(() {
                                        _selectedStudentId = student['id'];
                                      });
                                      context.read<LoginCubit>().switchParentChild(student['id']);
                                    },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context, {
    required Map<String, dynamic> student,
    required bool isSelected,
    required bool isSwitching,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.parentPrimary : AppColors.borderLight,
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar graphic placeholder
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.parentPrimary.withOpacity(0.08),
                  ),
                  child: const Icon(
                    Icons.face_outlined,
                    color: AppColors.parentPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Child parameters
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['student_name'] ?? 'Student Profile',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Class ${student['class_name'] ?? 'N/A'} - ${student['section'] ?? ''}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Adm: ${student['admission_no'] ?? ''}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing loading or pointer
                if (isSwitching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.parentPrimary),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
