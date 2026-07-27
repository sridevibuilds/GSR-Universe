// Presentation Layer - Parent View Tuition Fees Screen (Read-Only)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../data/models/fee_model.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentFeesPage extends StatelessWidget {
  const ParentFeesPage({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final rawHistory = state.feesHistory;
        final feesList = rawHistory.map((item) => FeeModel.fromJson(item)).toList();

        // Calculate total accumulated pending amount across all academic years
        double totalOutstandingDues = 0.0;
        if (feesList.isNotEmpty) {
          for (var fee in feesList) {
            totalOutstandingDues += fee.pendingAmount;
          }
        } else {
          totalOutstandingDues = FeeModel.parseNum(state.totalPendingDues);
        }

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Tuition Fees & Invoices",
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Outstanding Due Summary Card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: totalOutstandingDues > 0
                            ? [AppColors.danger, const Color(0xFFE53935)]
                            : [AppColors.success, const Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Outstanding Due",
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatCurrency(totalOutstandingDues),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Fee Summary Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                  child: Text(
                    "Fee Summary",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Fee Summary Year-Wise List
                Expanded(
                  child: feesList.isEmpty
                      ? const Center(
                          child: EmptyStateWidget(
                            title: "No Fee Records Found",
                            message: "Tuition fee records for your academic years will display here.",
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: feesList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final fee = feesList[index];
                            final bool isPending = fee.pendingAmount > 0;

                            return Container(
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
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.parentPrimary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Academic Year: ${fee.academicYear}",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.parentPrimary,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isPending ? AppColors.danger : AppColors.success).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPending ? "Pending" : "Paid",
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isPending ? AppColors.danger : AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        "Class:",
                                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        fee.className,
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Total Fee", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                                          const SizedBox(height: 2),
                                          Text(_formatCurrency(fee.totalFee), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Paid Amount", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                                          const SizedBox(height: 2),
                                          Text(_formatCurrency(fee.paidAmount), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.success)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Pending Amount", style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight)),
                                          const SizedBox(height: 2),
                                          Text(_formatCurrency(fee.pendingAmount), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isPending ? AppColors.danger : AppColors.textDark)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
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
