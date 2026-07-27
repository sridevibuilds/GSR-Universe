// Presentation Layer - Attendance QR/Barcode Scanning Console
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class AttendanceScanPage extends StatefulWidget {
  const AttendanceScanPage({super.key});

  @override
  State<AttendanceScanPage> createState() => _AttendanceScanPageState();
}

class _AttendanceScanPageState extends State<AttendanceScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
          context.read<FacultyCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "QR Attendance Scanner",
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
                icon: const Icon(Icons.flash_on, color: AppColors.textDark),
                onPressed: () => _scannerController.toggleTorch(),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Scanning Frame
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Stack(
                      children: [
                        if (_isScanning)
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final String? rawVal = barcode.rawValue;
                                if (rawVal != null) {
                                  // Temporarily pause camera scans
                                  setState(() {
                                    _isScanning = false;
                                  });
                                  context.read<FacultyCubit>().scanStudentAttendance(rawVal);
                                  
                                  // Resume scans after 2s delay
                                  Future.delayed(const Duration(seconds: 2), () {
                                    if (mounted) {
                                      setState(() {
                                        _isScanning = true;
                                      });
                                    }
                                  });
                                  break;
                                }
                              }
                            },
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        
                        // Scanner overlays (targeting box)
                        Center(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.facultyPrimary, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Scanned list header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    "Scanned This Session (${state.scannedStudents.length})",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ),

                // 3. Scanned Logs history list
                Expanded(
                  flex: 2,
                  child: state.scannedStudents.isEmpty
                      ? const Center(
                          child: EmptyStateWidget(
                            title: "No Scans Recorded",
                            message: "Aim the camera at the student barcode to register attendance.",
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.scannedStudents.length,
                          separatorBuilder: (context, index) => const Divider(color: AppColors.borderLight, height: 1.0),
                          itemBuilder: (context, index) {
                            final student = state.scannedStudents[index];
                            final timeStr = DateFormat('hh:mm a').format(DateTime.parse(student['scanned_at']));

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: AppColors.success, size: 18),
                              ),
                              title: Text(
                                student['student_name'] ?? 'Student Profile',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              subtitle: Text(
                                "Adm No: ${student['admission_no']}",
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                              ),
                              trailing: Text(
                                timeStr,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
