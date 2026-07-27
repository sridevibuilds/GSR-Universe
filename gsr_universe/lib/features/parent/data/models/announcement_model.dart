import 'package:equatable/equatable.dart';

class AnnouncementModel extends Equatable {
  final int id;
  final String title;
  final String message;
  final String priority;
  final String createdByName;
  final String targetScope;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    required this.createdByName,
    required this.targetScope,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now();
      if (dateVal is DateTime) return dateVal;
      try {
        return DateTime.parse(dateVal.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return AnnouncementModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title']?.toString() ?? 'School Announcement',
      message: json['message']?.toString() ?? json['description']?.toString() ?? '',
      priority: (json['priority']?.toString() ?? 'Normal').toUpperCase(),
      createdByName: json['created_by_name']?.toString() ?? json['faculty_name']?.toString() ?? 'Faculty Teacher',
      targetScope: json['target_scope']?.toString() ?? 'CLASS',
      createdAt: parseDate(json['created_at'] ?? json['published_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'priority': priority,
      'created_by_name': createdByName,
      'target_scope': targetScope,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, message, priority, createdByName, targetScope, createdAt];
}
