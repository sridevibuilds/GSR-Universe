// Data Model Layer - Homework Model with Safe Type Parsing
class HomeworkModel {
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

  HomeworkModel({
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

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    final bool submittedBool = json['submitted_at'] != null ||
        parseBool(json['is_submitted']) ||
        parseBool(json['submitted']);

    // Student submission file (ONLY from submission_file / submission_file_path)
    final String? subFile = json['submission_file']?.toString();
    String? subPath = json['submission_file_path']?.toString() ?? json['submission_path']?.toString();
    if ((subPath == null || subPath.isEmpty) && subFile != null && subFile.isNotEmpty) {
      subPath = subFile.startsWith('/') || subFile.startsWith('uploads') ? subFile : '/uploads/$subFile';
    }

    // Faculty question paper attachment (ONLY from attachment_name / attachment_path)
    final String? attName = json['attachment_name']?.toString() ?? json['homework_file']?.toString();
    String? attPath = json['attachment_path']?.toString() ?? json['homework_path']?.toString();
    if ((attPath == null || attPath.isEmpty) && attName != null && attName.isNotEmpty) {
      attPath = attName.startsWith('/') || attName.startsWith('uploads') ? attName : '/uploads/$attName';
    }

    return HomeworkModel(
      id: parseInt(json['homework_id'] ?? json['id']),
      title: parseString(json['title'], 'Homework Assignment'),
      description: parseString(json['description'], 'Complete reading and homework exercises.'),
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
    );
  }
}
