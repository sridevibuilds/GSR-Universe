// Data Model Layer - Timetable Model with Safe Type Parsing
class TimetableModel {
  final int id;
  final String title;
  final String fileName;
  final String? filePath;
  final String uploadedAt;
  final String className;
  final String section;
  final String academicYear;
  final bool isPublished;
  final bool isVerified;

  TimetableModel({
    required this.id,
    required this.title,
    required this.fileName,
    this.filePath,
    required this.uploadedAt,
    required this.className,
    required this.section,
    required this.academicYear,
    this.isPublished = true,
    this.isVerified = true,
  });

  /// Safe boolean parser supporting bool, num (0/1), and string ("true"/"false"/"1"/"0")
  static bool parseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final str = value.trim().toLowerCase();
      if (str == 'true' || str == '1' || str == 'yes' || str == 't') return true;
      if (str == 'false' || str == '0' || str == 'no' || str == 'f') return false;
    }
    return defaultValue;
  }

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Class Timetable',
      fileName: json['file_name']?.toString() ?? json['filename']?.toString() ?? 'Class_Timetable.pdf',
      filePath: json['file_path']?.toString() ?? json['filepath']?.toString(),
      uploadedAt: json['uploaded_at']?.toString() ?? json['created_at']?.toString() ?? '',
      className: json['class_name']?.toString() ?? 'Class',
      section: json['section']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? json['year_name']?.toString() ?? '2026-2027',
      isPublished: parseBool(json['is_published'] ?? json['isPublished'] ?? json['published'], true),
      isVerified: parseBool(json['is_verified'] ?? json['isVerified'] ?? json['verified'], true),
    );
  }
}
