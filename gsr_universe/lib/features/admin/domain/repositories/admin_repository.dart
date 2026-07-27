// Domain Layer - Admin Repository Interface
abstract class AdminRepository {
  Future<List<Map<String, dynamic>>> getAllFaculty();
  Future<void> createFaculty(Map<String, dynamic> payload);
  Future<void> updateFaculty(int id, Map<String, dynamic> payload);
  Future<void> deleteFaculty(int id);
  
  Future<Map<String, dynamic>> getCallSettings();
  Future<void> updateCallSettings(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getCallHistory();
  Future<void> triggerManualReminders();

  Future<List<Map<String, dynamic>>> getPendingFeeReport({String? className, String? section});

  Future<Map<String, dynamic>> getClassReport({
    String? academicYear,
    String? className,
    String? section,
    String? term,
  });
  Future<List<Map<String, dynamic>>> getSystemNotifications();

  Future<void> publishMeetingAnnouncement(Map<String, dynamic> payload);
  Future<List<Map<String, dynamic>>> getMeetingHistory();
  Future<void> deleteMeetingAnnouncement(int id);
}
