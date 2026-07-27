// Data Model Layer - Notice Board Model with Safe Type Parsing
class NoticeModel {
  final int id;
  final String title;
  final String description;
  final String date;
  final String? attachmentName;
  final String? attachmentPath;
  final String createdByName;
  final List<String> images;
  final bool isPinned;
  final bool isPublished;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.attachmentName,
    this.attachmentPath,
    required this.createdByName,
    this.images = const [],
    this.isPinned = false,
    this.isPublished = true,
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

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] is List) {
      parsedImages = (json['images'] as List).map((e) => e.toString()).toList();
    } else if (json['images'] is String && (json['images'] as String).isNotEmpty) {
      parsedImages = [json['images'].toString()];
    }

    return NoticeModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? json['notice_title']?.toString() ?? 'School Notice',
      description: json['content']?.toString() ?? json['description']?.toString() ?? '',
      date: json['created_at']?.toString() ?? json['date']?.toString() ?? json['published_date']?.toString() ?? '',
      attachmentName: json['attachment_name']?.toString() ?? json['file_name']?.toString(),
      attachmentPath: json['attachment_path']?.toString() ?? json['file_path']?.toString() ?? json['image_url']?.toString(),
      createdByName: json['created_by_name']?.toString() ?? json['faculty_name']?.toString() ?? 'School Management',
      images: parsedImages,
      isPinned: parseBool(json['is_pinned'] ?? json['pinned'] ?? json['isPinned'], false),
      isPublished: parseBool(json['is_published'] ?? json['published'] ?? json['isPublished'], true),
    );
  }
}
