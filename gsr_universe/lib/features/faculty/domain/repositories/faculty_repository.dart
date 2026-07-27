// Domain Layer - Faculty Repository Interface
import 'dart:io';

abstract class FacultyRepository {
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

  // Transport (Phase 3)
  Future<List<Map<String, dynamic>>> getTransport();

  // Fee Details (Phase 3)
  Future<List<Map<String, dynamic>>> getFeeDetails({String? className, String? section});
  Future<void> updateFeeByMapping(int scmId, Map<String, dynamic> payload);

  // Meeting Notifications
  Future<Map<String, dynamic>> getFacultyMeetingNotifications();
  Future<void> markMeetingNotificationAsRead(int notificationId);
}
