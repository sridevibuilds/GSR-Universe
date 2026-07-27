// Data Source Layer - Student/Parent Dashboard Remote Data Source
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

abstract class ParentRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardSummary();
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> getAttendanceHistory();
  Future<Map<String, dynamic>> getMarksReport();
  Future<Map<String, dynamic>> getHomeworkTasks();
  Future<Map<String, dynamic>> getAssignmentsList();
  Future<Map<String, dynamic>> getAssignmentMarks();
  Future<Map<String, dynamic>> getFeesLedger();
  Future<Map<String, dynamic>> getTimetable();
  Future<Map<String, dynamic>> getAnnouncements();
  Future<Map<String, dynamic>> getEvents();
  Future<Map<String, dynamic>> getHolidays();
  Future<Map<String, dynamic>> getProgressCards();
  Future<Map<String, dynamic>> getNoticeBoard();
  Future<Map<String, dynamic>> getTransport();
  Future<Map<String, dynamic>> submitHomework(int homeworkId, String fileName, String filePath);
  Future<Map<String, dynamic>> deleteHomeworkSubmission(int homeworkId);
  Future<Map<String, dynamic>> submitAssignment(int assignmentId, String fileName, String filePath);
  Future<Map<String, dynamic>> deleteAssignmentSubmission(int assignmentId);
  Future<Map<String, dynamic>> getParentNotifications();
  Future<void> markParentNotificationAsRead(int notificationId);
}

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  final ApiClient apiClient;

  ParentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await apiClient.get('/api/parent/dashboard');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await apiClient.get('/api/parent/profile');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getAttendanceHistory() async {
    final response = await apiClient.get('/api/parent/attendance');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getMarksReport() async {
    final response = await apiClient.get('/api/parent/marks');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getHomeworkTasks() async {
    final response = await apiClient.get('/api/parent/homework');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getAssignmentsList() async {
    final response = await apiClient.get('/api/parent/assignments');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getAssignmentMarks() async {
    final response = await apiClient.get('/api/parent/assignment-marks');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getFeesLedger() async {
    final response = await apiClient.get('/api/parent/fees');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getTimetable() async {
    final response = await apiClient.get('/api/parent/timetable');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getAnnouncements() async {
    final response = await apiClient.get('/api/parent/announcements');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getEvents() async {
    final response = await apiClient.get('/api/parent/events');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getHolidays() async {
    final response = await apiClient.get('/api/parent/holidays');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getProgressCards() async {
    final response = await apiClient.get('/api/parent/progress-card');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getNoticeBoard() async {
    final response = await apiClient.get('/api/parent/notice-board');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getTransport() async {
    final response = await apiClient.get('/api/parent/transport');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> submitHomework(int homeworkId, String fileName, String filePath) async {
    String serverFilePath = filePath;
    String serverFileName = fileName;

    if (!filePath.startsWith('/uploads/') && !filePath.startsWith('http')) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final filename = file.path.split(Platform.pathSeparator).last;
          final formData = FormData.fromMap({
            "file": await MultipartFile.fromFile(file.path, filename: filename),
          });
          final uploadRes = await apiClient.post('/api/upload', data: formData);
          if (uploadRes.data != null && uploadRes.data['filePath'] != null) {
            serverFilePath = uploadRes.data['filePath'];
            serverFileName = uploadRes.data['fileName'] ?? filename;
          }
        }
      } catch (e) {
        debugPrint("Error uploading student homework file to backend: $e");
      }
    }

    final response = await apiClient.post('/api/parent/homework/submit', data: {
      'homework_id': homeworkId,
      'file_name': serverFileName,
      'file_path': serverFilePath,
    });
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> deleteHomeworkSubmission(int homeworkId) async {
    final response = await apiClient.delete('/api/parent/homework/submission/$homeworkId');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> submitAssignment(int assignmentId, String fileName, String filePath) async {
    String serverFilePath = filePath;
    String serverFileName = fileName;

    if (!filePath.startsWith('/uploads/') && !filePath.startsWith('http')) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final filename = file.path.split(Platform.pathSeparator).last;
          final formData = FormData.fromMap({
            "file": await MultipartFile.fromFile(file.path, filename: filename),
          });
          final uploadRes = await apiClient.post('/api/upload', data: formData);
          if (uploadRes.data != null && uploadRes.data['filePath'] != null) {
            serverFilePath = uploadRes.data['filePath'];
            serverFileName = uploadRes.data['fileName'] ?? filename;
          }
        }
      } catch (e) {
        debugPrint("Error uploading student assignment file to backend: $e");
      }
    }

    final response = await apiClient.post('/api/parent/assignments/submit', data: {
      'assignment_id': assignmentId,
      'file_name': serverFileName,
      'file_path': serverFilePath,
    });
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> deleteAssignmentSubmission(int assignmentId) async {
    final response = await apiClient.delete('/api/parent/assignments/submission/$assignmentId');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getParentNotifications() async {
    final response = await apiClient.get('/api/parent/notifications');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> markParentNotificationAsRead(int notificationId) async {
    await apiClient.put('/api/parent/notifications/$notificationId/read');
  }
}
