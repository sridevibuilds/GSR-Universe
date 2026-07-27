// Data Model Layer - Assignment Model with Safe Type Parsing
class AssignmentModel {
  final int id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final String section;
  final String? attachmentName;
  final String? attachmentPath;
  final String? submissionFile;
  final String? submissionPath;
  final String? dueDate;
  final String? publishedDate;
  final String? submittedAt;
  final bool isSubmitted;
  final bool isGraded;
  final double? marksObtained;
  final double? maxMarks;
  final String? grade;
  final String? feedback;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.section,
    this.attachmentName,
    this.attachmentPath,
    this.submissionFile,
    this.submissionPath,
    this.dueDate,
    this.publishedDate,
    this.submittedAt,
    required this.isSubmitted,
    required this.isGraded,
    this.marksObtained,
    this.maxMarks,
    this.grade,
    this.feedback,
  });

  /// Safe boolean parser supporting bool, num (0/1), and string ("true"/"false"/"1"/"0")
  static bool parseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return defaultValue;
  }

  /// Safe numeric parser supporting double, int, num, String, or null
  static double? parseNumNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '').trim();
      return double.tryParse(cleaned);
    }
    return null;
  }

  static double parseNum(dynamic value, [double defaultValue = 0.0]) {
    return parseNumNullable(value) ?? defaultValue;
  }

  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ?? defaultValue;
    }
    return defaultValue;
  }

  static String parseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final bool submittedBool = json['submitted_at'] != null ||
        parseBool(json['is_submitted']) ||
        parseBool(json['submitted']);

    // Student submission file (ONLY from submission_file / submission_file_path / file_name / file_path)
    final String? subFile = json['submission_file']?.toString() ?? json['file_name']?.toString();
    String? subPath = json['submission_file_path']?.toString() ?? json['submission_path']?.toString() ?? json['file_path']?.toString();
    if ((subPath == null || subPath.isEmpty) && subFile != null && subFile.isNotEmpty) {
      subPath = subFile.startsWith('/') || subFile.startsWith('uploads') ? subFile : '/uploads/$subFile';
    }

    // Faculty question paper attachment (ONLY from attachment_name / attachment_path)
    final String? attName = json['attachment_name']?.toString() ?? json['assignment_file']?.toString();
    String? attPath = json['attachment_path']?.toString() ?? json['assignment_path']?.toString();
    if ((attPath == null || attPath.isEmpty) && attName != null && attName.isNotEmpty) {
      attPath = attName.startsWith('/') || attName.startsWith('uploads') ? attName : '/uploads/$attName';
    }

    return AssignmentModel(
      id: parseInt(json['assignment_id'] ?? json['id']),
      title: parseString(json['title'], 'Assignment Task'),
      description: parseString(json['description'], 'Complete the assigned project work.'),
      subject: parseString(json['subject_name'] ?? json['subject'], 'General'),
      className: parseString(json['class_name'], '8').replaceAll('Class ', ''),
      section: parseString(json['section'], 'B'),
      attachmentName: attName,
      attachmentPath: attPath,
      submissionFile: subFile,
      submissionPath: subPath,
      dueDate: json['due_date']?.toString() ?? json['submission_date']?.toString(),
      publishedDate: json['published_date']?.toString() ?? json['created_at']?.toString(),
      submittedAt: json['submitted_at']?.toString(),
      isSubmitted: submittedBool,
      isGraded: parseBool(json['is_graded']) || parseBool(json['graded']),
      marksObtained: parseNumNullable(json['marks_obtained'] ?? json['marks']),
      maxMarks: parseNumNullable(json['max_marks'] ?? json['total_marks']),
      grade: json['grade']?.toString(),
      feedback: json['feedback']?.toString() ?? json['remarks']?.toString(),
    );
  }
}
