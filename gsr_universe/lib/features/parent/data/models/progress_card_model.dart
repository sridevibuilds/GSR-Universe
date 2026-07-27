// Data Model Layer - Progress Card Model with Safe Type Parsing
class ProgressCardModel {
  final int id;
  final String fileName;
  final String? filePath;
  final String uploadedAt;
  final String academicYear;
  final String uploadedByName;
  final String remarks;
  final bool isPublished;
  final bool isVerified;

  ProgressCardModel({
    required this.id,
    required this.fileName,
    this.filePath,
    required this.uploadedAt,
    required this.academicYear,
    required this.uploadedByName,
    required this.remarks,
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

  factory ProgressCardModel.fromJson(Map<String, dynamic> json) {
    return ProgressCardModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fileName: json['file_name']?.toString() ?? json['filename']?.toString() ?? 'Progress_Card.pdf',
      filePath: json['file_path']?.toString() ?? json['filepath']?.toString(),
      uploadedAt: json['uploaded_at']?.toString() ?? json['created_at']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? json['year_name']?.toString() ?? '2026-2027',
      uploadedByName: json['uploaded_by_name']?.toString() ?? json['uploaded_by']?.toString() ?? 'Class Teacher',
      remarks: json['remarks']?.toString() ?? '',
      isPublished: parseBool(json['is_published'] ?? json['isPublished'] ?? json['published'], true),
      isVerified: parseBool(json['is_verified'] ?? json['isVerified'] ?? json['verified'], true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'uploaded_at': uploadedAt,
      'academic_year': academicYear,
      'uploaded_by_name': uploadedByName,
      'remarks': remarks,
      'is_published': isPublished,
      'is_verified': isVerified,
    };
  }
}
