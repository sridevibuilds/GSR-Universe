// Domain Layer - Parent Repository Interface
abstract class ParentRepository {
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
