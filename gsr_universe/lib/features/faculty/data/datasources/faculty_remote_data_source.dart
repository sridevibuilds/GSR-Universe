// Data Source Layer - Faculty Dashboard Remote Data Source
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

abstract class FacultyRemoteDataSource {
  // Student Operations
  Future<List<Map<String, dynamic>>> getAllStudents();
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> updateStudent(int id, Map<String, dynamic> payload);
  Future<void> deleteStudent(int id);
  
  // Attendance & Monitoring
  Future<Map<String, dynamic>> scanAttendance(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> getClassAttendanceReport(int classId, {String? date});
  
  // Student Promotions
  Future<void> promoteStudents(Map<String, dynamic> payload);
  Future<void> createAcademicYear(Map<String, dynamic> payload);

  // Assessments & Marks Entry
  Future<List<Map<String, dynamic>>> getAssessments();
  Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> updateAssessment(int id, Map<String, dynamic> payload);
  Future<void> deleteAssessment(int id);
  Future<void> submitMarks(Map<String, dynamic> payload);

  // Multipart File Upload Gateway
  Future<Map<String, dynamic>> uploadFile(File file);

  // Homework
  Future<void> createHomework(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getHomework();
  Future<List<Map<String, dynamic>>> getHomeworkSubmissions({String? className, String? section, int? homeworkId});
  Future<void> deleteHomework(int id);

  // Assignments (Phase 2)
  Future<void> createAssignment(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getAssignments();
  Future<List<Map<String, dynamic>>> getAssignmentSubmissions({String? className, String? section, int? assignmentId});
  Future<Map<String, dynamic>> updateAssignment(int id, Map<String, dynamic> payload);
  Future<void> gradeAssignment(Map<String, dynamic> payload);
  Future<void> deleteAssignment(int id);

  // Progress Cards (Phase 2)
  Future<void> createProgressCard(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getProgressCards();
  Future<void> deleteProgressCard(int id);

  // Timetable (Phase 2)
  Future<void> createTimetable(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getTimetables();
  Future<void> deleteTimetable(int id);

  // Announcements (Phase 3)
  Future<void> createAnnouncement(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getAnnouncements();
  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> payload);
  Future<void> deleteAnnouncement(int id);

  // Events (Phase 3)
  Future<void> createEvent(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getEvents();
  Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> payload);
  Future<void> deleteEvent(int id);

  // Holidays (Phase 3)
  Future<void> createHoliday(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getHolidays();
  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> payload);
  Future<void> deleteHoliday(int id);

  // Notice Board (Phase 3)
  Future<void> createNotice(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getNotices();
  Future<Map<String, dynamic>> updateNotice(int id, Map<String, dynamic> payload);
  Future<void> deleteNotice(int id);

  // Meeting Notifications
  Future<Map<String, dynamic>> getFacultyMeetingNotifications();
  Future<void> markMeetingNotificationAsRead(int notificationId);

  // Transport (Phase 3)
  Future<List<Map<String, dynamic>>> getTransport();

  // Fee Details (Phase 3)
  Future<List<Map<String, dynamic>>> getFeeDetails({String? className, String? section});
  Future<void> updateFeeByMapping(int scmId, Map<String, dynamic> payload);
}

class FacultyRemoteDataSourceImpl implements FacultyRemoteDataSource {
  final ApiClient apiClient;

  FacultyRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final response = await apiClient.get('/api/students/all');
    final List<dynamic> data = response.data['students'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/students/create', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> updateStudent(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/students/update/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> deleteStudent(int id) async {
    await apiClient.delete('/api/students/delete/$id');
  }

  @override
  Future<Map<String, dynamic>> scanAttendance(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/attendance/scan', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> getClassAttendanceReport(int classId, {String? date}) async {
    final queryParams = <String, String>{};
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    final response = await apiClient.get(
      '/api/attendance/report/class/$classId',
      queryParameters: queryParams,
    );
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> promoteStudents(Map<String, dynamic> payload) async {
    await apiClient.post('/api/students/promote', data: payload);
  }

  @override
  Future<void> createAcademicYear(Map<String, dynamic> payload) async {
    await apiClient.post('/api/students/academic-years', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getAssessments() async {
    final response = await apiClient.get('/api/assessments');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> payload) async {
    final response = await apiClient.post('/api/assessments', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<Map<String, dynamic>> updateAssessment(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/assessments/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> deleteAssessment(int id) async {
    await apiClient.delete('/api/assessments/$id');
  }

  @override
  Future<void> submitMarks(Map<String, dynamic> payload) async {
    await apiClient.post('/api/assessment-results', data: payload);
  }

  @override
  Future<Map<String, dynamic>> uploadFile(File file) async {
    final String filename = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: filename),
    });
    
    final response = await apiClient.post('/api/upload', data: formData);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> createHomework(Map<String, dynamic> payload) async {
    await apiClient.post('/api/homework/', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getHomework() async {
    final response = await apiClient.get('/api/homework');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> deleteHomework(int id) async {
    await apiClient.delete('/api/homework/$id');
  }

  @override
  Future<void> createAssignment(Map<String, dynamic> payload) async {
    await apiClient.post('/api/assignments', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getAssignments() async {
    final response = await apiClient.get('/api/assignments');
    final List<dynamic> data = response.data['data'] ?? response.data['assignments'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createProgressCard(Map<String, dynamic> payload) async {
    await apiClient.post('/api/progress-cards', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getProgressCards() async {
    final response = await apiClient.get('/api/progress-cards');
    final List<dynamic> data = response.data['data'] ?? response.data['progressCards'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createTimetable(Map<String, dynamic> payload) async {
    await apiClient.post('/api/timetable', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getTimetables() async {
    final response = await apiClient.get('/api/timetable');
    final List<dynamic> data = response.data['data'] ?? response.data['timetables'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createAnnouncement(Map<String, dynamic> payload) async {
    await apiClient.post('/api/announcements', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final response = await apiClient.get('/api/announcements');
    final List<dynamic> data = response.data['data'] ?? response.data['announcements'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createEvent(Map<String, dynamic> payload) async {
    await apiClient.post('/api/events', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getEvents() async {
    final response = await apiClient.get('/api/events');
    final List<dynamic> data = response.data['data'] ?? response.data['events'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createHoliday(Map<String, dynamic> payload) async {
    await apiClient.post('/api/holidays', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getHolidays() async {
    final response = await apiClient.get('/api/holidays');
    final List<dynamic> data = response.data['data'] ?? response.data['holidays'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> createNotice(Map<String, dynamic> payload) async {
    await apiClient.post('/api/notice-board', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getNotices() async {
    final response = await apiClient.get('/api/notice-board');
    final List<dynamic> data = response.data['data'] ?? response.data['notices'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTransport() async {
    final response = await apiClient.get('/api/transport');
    final List<dynamic> data = response.data['data'] ?? response.data['transports'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getFeeDetails({String? className, String? section}) async {
    final response = await apiClient.get('/api/fees');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<void> updateFeeByMapping(int scmId, Map<String, dynamic> payload) async {
    await apiClient.put('/api/fees/by-mapping/$scmId', data: payload);
  }

  @override
  Future<List<Map<String, dynamic>>> getHomeworkSubmissions({String? className, String? section, int? homeworkId}) async {
    final queryParams = <String, dynamic>{};
    if (className != null && className.isNotEmpty) queryParams['class_name'] = className;
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (homeworkId != null) queryParams['homework_id'] = homeworkId;

    final response = await apiClient.get('/api/homework/submissions/list', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAssignmentSubmissions({String? className, String? section, int? assignmentId}) async {
    final queryParams = <String, dynamic>{};
    if (className != null && className.isNotEmpty) queryParams['class_name'] = className;
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (assignmentId != null) queryParams['assignment_id'] = assignmentId;

    final response = await apiClient.get('/api/assignments/submissions/list', queryParameters: queryParams);
    final List<dynamic> data = response.data['data'] ?? response.data['submissions'] ?? [];
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Future<Map<String, dynamic>> updateAssignment(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/assignments/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> gradeAssignment(Map<String, dynamic> payload) async {
    await apiClient.post('/api/assignments/grade', data: payload);
  }

  @override
  Future<void> deleteAssignment(int id) async {
    await apiClient.delete('/api/assignments/$id');
  }

  @override
  Future<void> deleteProgressCard(int id) async {
    await apiClient.delete('/api/progress-cards/$id');
  }

  @override
  Future<void> deleteTimetable(int id) async {
    await apiClient.delete('/api/timetable/$id');
  }

  @override
  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/announcements/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> deleteAnnouncement(int id) async {
    await apiClient.delete('/api/announcements/$id');
  }

  @override
  Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/events/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> deleteEvent(int id) async {
    await apiClient.delete('/api/events/$id');
  }

  @override
  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/holidays/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> deleteHoliday(int id) async {
    await apiClient.delete('/api/holidays/$id');
  }

  @override
  Future<Map<String, dynamic>> updateNotice(int id, Map<String, dynamic> payload) async {
    final response = await apiClient.put('/api/notice-board/$id', data: payload);
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> deleteNotice(int id) async {
    await apiClient.delete('/api/notice-board/$id');
  }

  @override
  Future<Map<String, dynamic>> getFacultyMeetingNotifications() async {
    final response = await apiClient.get('/api/meetings/faculty/notifications');
    return Map<String, dynamic>.from(response.data);
  }

  @override
  Future<void> markMeetingNotificationAsRead(int notificationId) async {
    await apiClient.put('/api/meetings/notifications/$notificationId/read');
  }
}
