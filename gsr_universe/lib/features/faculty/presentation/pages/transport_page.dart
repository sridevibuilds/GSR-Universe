// Presentation Layer - Transport Lookup Module (Read-only)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/faculty_cubit.dart';
import '../cubit/faculty_state.dart';

class TransportPage extends StatefulWidget {
  const TransportPage({super.key});

  @override
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  final _searchController = TextEditingController();
  String _selectedClass = "Class 9";
  String _selectedSection = "A";

  final List<String> _classes = [
    "Nursery", "LKG", "UKG", "Class 1", "Class 2", "Class 3", "Class 4", 
    "Class 5", "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];
  final List<String> _sections = ["A", "B", "C"];

  @override
  void initState() {
    super.initState();
    context.read<FacultyCubit>().fetchTransport();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          "Student Transport",
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
        child: BlocBuilder<FacultyCubit, FacultyState>(
          builder: (context, state) {
            final query = _searchController.text.toLowerCase();
            final filtered = state.transportList.where((t) {
              final matchesClass = _getCommonClassFormat(t['class_name']) == _getCommonClassFormat(_selectedClass);
              final matchesSec = t['section'] == _selectedSection;
              
              final name = (t['student_name'] ?? '').toString().toLowerCase();
              final bus = (t['bus_number'] ?? '').toString().toLowerCase();
              final route = (t['route_name'] ?? '').toString().toLowerCase();
              final matchesSearch = query.isEmpty || name.contains(query) || bus.contains(query) || route.contains(query);
              
              return matchesClass && matchesSec && matchesSearch;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                            hintText: "Search transport by student, bus no, route...",
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
                  child: state.isLoading && state.transportList.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? const Center(
                              child: EmptyStateWidget(
                                title: "No Transport Records",
                                message: "No active bus routes mapped to students in this class.",
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
                                      headingRowColor: MaterialStateProperty.all(AppColors.facultyPrimary.withOpacity(0.05)),
                                      columns: [
                                        DataColumn(label: Text("Student Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Class", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Sec", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Bus No", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Route Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Pickup Point", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text("Driver Phone", style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: filtered.map((route) {
                                        return DataRow(cells: [
                                          DataCell(Text(route['student_name'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                          DataCell(Text(route['class_name'] ?? 'N/A', style: GoogleFonts.inter())),
                                          DataCell(Text(route['section'] ?? 'N/A', style: GoogleFonts.inter())),
                                          DataCell(Text(route['bus_number'] ?? 'N/A', style: GoogleFonts.inter())),
                                          DataCell(Text(route['route_name'] ?? 'N/A', style: GoogleFonts.inter())),
                                          DataCell(Text(route['pickup_point'] ?? 'N/A', style: GoogleFonts.inter())),
                                          DataCell(Text(route['driver_mobile'] ?? 'N/A', style: GoogleFonts.inter())),
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
