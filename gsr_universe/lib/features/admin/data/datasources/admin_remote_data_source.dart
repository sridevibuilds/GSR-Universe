// Data Source Layer - Admin Dashboard Remote Data Source
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

abstract class AdminRemoteDataSource {
  // Faculty CRUD Operations
  Future<List<Map<String, dynamic>>> getAllFaculty();
  Future<void> createFaculty(Map<String, dynamic> payload);
  Future<void> updateFaculty(int id, Map<String, dynamic> payload);
  Future<void> deleteFaculty(int id);

  // Reminders Voice Calls Configuration
  Future<Map<String, dynamic>> getCallSettings();
  Future<void> updateCallSettings(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getCallHistory();
  Future<void> triggerManualReminders();

  // Collections analytics
  Future<List<Map<String, dynamic>>> getPendingFeeReport({String? className, String? section});

  // Class Analytics Reports & Notifications
  Future<Map<String, dynamic>> getClassReport({
    String? academicYear,
    String? className,
    String? section,
    String? term,
  });
  Future<List<Map<String, dynamic>>> getSystemNotifications();

  // Meeting Announcements
  Future<void> publishMeetingAnnouncement(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getMeetingHistory();
  Future<void> deleteMeetingAnnouncement(int id);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<Map<String, dynamic>>> getAllFaculty() async {
    final response = await apiClient.get('/api/faculty/');
    final List<dynamic> data = response.data['faculty'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createFaculty(Map<String, dynamic> payload) async {
    await apiClient.post('/api/faculty/create', data: payload);
  }

  @override
  Future<void> updateFaculty(int id, Map<String, dynamic> payload) async {
    await apiClient.put('/api/faculty/$id', data: payload);
  }

  @override
  Future<void> deleteFaculty(int id) async {
    await apiClient.delete('/api/faculty/$id');
  }

  @override
  Future<Map<String, dynamic>> getCallSettings() async {
    final response = await apiClient.get('/api/fees/calls/settings');
    return Map<String, dynamic>.from(response.data['settings'] ?? {});
  }

  @override
  Future<void> updateCallSettings(Map<String, dynamic> payload) async {
    await apiClient.put('/api/fees/calls/settings', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getCallHistory() async {
    final response = await apiClient.get('/api/fees/calls/history');
    final List<dynamic> data = response.data['history'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> triggerManualReminders() async {
    await apiClient.post('/api/fees/calls/trigger');
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingFeeReport({String? className, String? section}) async {
    final queryParams = <String, String>{};
    if (className != null && className.isNotEmpty) queryParams['class_name'] = className;
    if (section != null && section.isNotEmpty) queryParams['section'] = section;

    final response = await apiClient.get('/api/fees/reports/pending', queryParameters: queryParams);
    final List<dynamic> data = response.data['report'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<Map<String, dynamic>> getClassReport({
    String? academicYear,
    String? className,
    String? section,
    String? term,
  }) async {
    final queryParams = <String, String>{};
    if (academicYear != null && academicYear.isNotEmpty) queryParams['academic_year'] = academicYear;
    if (className != null && className.isNotEmpty) queryParams['class_name'] = className;
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (term != null && term.isNotEmpty) queryParams['term'] = term;

    final response = await apiClient.get(
      '/api/admin/class-reports',
      queryParameters: queryParams,
    );
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getSystemNotifications() async {
    final response = await apiClient.get('/api/admin/system-notifications');
    final List<dynamic> data = response.data['notifications'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> publishMeetingAnnouncement(Map<String, dynamic> payload) async {
    if (payload['attachment_file'] != null && payload['attachment_file'] is File) {
      final File file = payload['attachment_file'] as File;
      final formData = FormData.fromMap({
        'title': payload['title'],
        'description': payload['description'],
        'meeting_date': payload['meeting_date'],
        'meeting_time': payload['meeting_time'],
        'venue': payload['venue'],
        'priority': payload['priority'],
        'attachment': await MultipartFile.fromFile(
          file.path,
          filename: payload['attachment_name'] ?? file.path.split('/').last,
        ),
      });
      await apiClient.post('/api/meetings/', data: formData);
    } else {
      await apiClient.post('/api/meetings/', data: payload);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMeetingHistory() async {
    final response = await apiClient.get('/api/meetings/history');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> deleteMeetingAnnouncement(int id) async {
    await apiClient.delete('/api/meetings/$id');
  }
}
