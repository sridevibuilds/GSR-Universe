// Reusable Widget - ERP Specific Dropdown Selectors
import 'package:flutter/material.dart';
import 'custom_dropdown.dart';

class ClassSelector extends StatelessWidget {
  final String? selectedClass;
  final List<String> classes;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const ClassSelector({
    super.key,
    required this.selectedClass,
    required this.classes,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      value: selectedClass,
      labelText: "Select Class",
      prefixIcon: Icons.class_outlined,
      items: classes.map((c) {
        return DropdownMenuItem<String>(
          value: c,
          child: Text(c),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class SectionSelector extends StatelessWidget {
  final String? selectedSection;
  final List<String> sections;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const SectionSelector({
    super.key,
    required this.selectedSection,
    required this.sections,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      value: selectedSection,
      labelText: "Select Section",
      prefixIcon: Icons.grid_view_outlined,
      items: sections.map((s) {
        return DropdownMenuItem<String>(
          value: s,
          child: Text(s),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class AcademicYearSelector extends StatelessWidget {
  final String? selectedYear;
  final List<String> years;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const AcademicYearSelector({
    super.key,
    required this.selectedYear,
    required this.years,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      value: selectedYear,
      labelText: "Academic Year",
      prefixIcon: Icons.calendar_today_outlined,
      items: years.map((y) {
        return DropdownMenuItem<String>(
          value: y,
          child: Text(y),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
