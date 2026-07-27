// Reusable Widget - Responsive Paginated Data Table
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class DataTableView extends StatelessWidget {
  final String searchPlaceholder;
  final TextEditingController? searchController;
  final void Function(String)? onSearchChanged;
  final List<String> headers;
  final List<DataRow> rows;
  final VoidCallback? onFilterTap;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  const DataTableView({
    super.key,
    required this.searchPlaceholder,
    this.searchController,
    this.onSearchChanged,
    required this.headers,
    required this.rows,
    this.onFilterTap,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPrevPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search and filter header block
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: searchPlaceholder,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (onFilterTap != null) ...[
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.borderLight),
                    ),
                    icon: const Icon(Icons.filter_list, color: AppColors.gradientStart),
                    onPressed: onFilterTap,
                  ),
                ]
              ],
            ),
          ),

          // 2. Horizontal scroll wrapping DataTable to prevent layout overflows
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.pageBackground),
              columns: headers.map((header) {
                return DataColumn(
                  label: Text(
                    header,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
              rows: rows,
            ),
          ),

          // 3. Paginated controls footer
          if (totalPages > 1) ...[
            const Divider(color: AppColors.borderLight, height: 1.0),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Page $currentPage of $totalPages",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 1 ? onPrevPage : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: currentPage < totalPages ? onNextPage : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
