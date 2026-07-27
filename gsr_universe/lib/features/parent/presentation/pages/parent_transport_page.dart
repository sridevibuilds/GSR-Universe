// Presentation Layer - Parent View Transport Screen (Read-Only)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentTransportPage extends StatelessWidget {
  const ParentTransportPage({super.key});

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor, bool isHighlight = false}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.parentPrimary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.parentPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight ? AppColors.parentPrimary : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final transport = state.transportDetails;

        final String studentName = (transport?['student_name'] ?? state.profileData?['student_name'] ?? 'Student').toString();
        final String admissionNo = (transport?['admission_no'] ?? state.profileData?['admission_no'] ?? '').toString();
        final String className = (transport?['class_name'] ?? state.profileData?['class_name'] ?? '').toString().replaceAll('Class ', '');
        final String section = (transport?['section'] ?? state.profileData?['section'] ?? '').toString();
        final String busNumber = (transport?['bus_number'] ?? transport?['bus_no'] ?? '').toString();
        final String route = (transport?['route'] ?? transport?['route_name'] ?? '').toString();
        final String pickupPoint = (transport?['pickup_point'] ?? transport?['stop_name'] ?? '').toString();
        final String driverMobile = (transport?['driver_mobile'] ?? transport?['driver_phone'] ?? '').toString();

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Transport Details",
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Header Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.parentPrimary, AppColors.parentPrimary.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${admissionNo.isNotEmpty ? 'Adm No: $admissionNo  •  ' : ''}Class ${className.isNotEmpty ? className : '8'} - ${section.isNotEmpty ? section : 'B'}",
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Transport Information List Card
                  Container(
                    padding: const EdgeInsets.all(18),
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
                          "Transport Details",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        _buildInfoRow(Icons.person, "Student Name", studentName),
                        _buildInfoRow(Icons.badge_outlined, "Admission Number", admissionNo),
                        _buildInfoRow(Icons.class_outlined, "Class", className),
                        _buildInfoRow(Icons.domain_outlined, "Section", section),
                        _buildInfoRow(Icons.directions_bus_filled, "Bus Number", busNumber, isHighlight: true),
                        _buildInfoRow(Icons.route, "Route", route),
                        _buildInfoRow(Icons.pin_drop, "Pickup Point", pickupPoint),
                        _buildInfoRow(Icons.phone, "Driver Mobile Number", driverMobile, iconColor: AppColors.success),
                      ],
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
