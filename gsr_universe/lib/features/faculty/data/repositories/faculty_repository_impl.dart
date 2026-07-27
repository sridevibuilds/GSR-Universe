// Data Layer - Faculty Repository Implementation with Offline Caching
import 'dart:io';
import '../../domain/repositories/faculty_repository.dart';
import '../datasources/faculty_remote_data_source.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/offline_cache.dart';
import '../../../../core/network/connectivity_monitor.dart';
import '../../../../core/di/injection_container.dart';

class FacultyRepositoryImpl implements FacultyRepository {
  final FacultyRemoteDataSource remoteDataSource;

  FacultyRepositoryImpl({required this.remoteDataSource});

  /// Executes remote read API calls caching data locally, falling back to cache when offline
  Future<T> _executeWithCache<T>({
    required String cacheKey,
    required Future<T> Function() remoteCall,
  }) async {
    final connectivity = sl<ConnectivityMonitor>();
    final cache = sl<OfflineCache>();

    if (await connectivity.isConnected) {
      try {
        final data = await remoteCall();
        await cache.cacheData(cacheKey, data);
        return data;
      } catch (err) {
        final cached = cache.getCachedData(cacheKey);
        if (cached != null) {
          return cached as T;
        }
        rethrow;
      }
    } else {
      final cached = cache.getCachedData(cacheKey);
      if (cached != null) {
        return cached as T;
      }
      throw ServerException("You are currently offline. Check your internet connection.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    return _executeWithCache(
      cacheKey: 'faculty_students_list',
      remoteCall: () => remoteDataSource.getAllStudents(),
    );
  }

  @override
  Future<Map<String, dynamic>> createStudent(Map<String, dynamic> payload) async {
    try {
      final data = await remoteDataSource.createStudent(payload);
      await sl<OfflineCache>().clearCache('faculty_students_list');
      return data;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to create student record.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateStudent(int id, Map<String, dynamic> payload) async {
    try {
      final data = await remoteDataSource.updateStudent(id, payload);
      await sl<OfflineCache>().clearCache('faculty_students_list');
      return data;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update student record.");
    }
  }

  @override
  Future<void> deleteStudent(int id) async {
    try {
      await remoteDataSource.deleteStudent(id);
      await sl<OfflineCache>().clearCache('faculty_students_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete student record.");
    }
  }

  @override
  Future<Map<String, dynamic>> scanAttendance(Map<String, dynamic> payload) async {
    try {
      return await remoteDataSource.scanAttendance(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to register attendance scan.");
    }
  }

  @override
  Future<Map<String, dynamic>> getClassAttendanceReport(int classId, {String? date}) async {
    try {
      return await remoteDataSource.getClassAttendanceReport(classId, date: date);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to load class attendance report.");
    }
  }

  @override
  Future<void> promoteStudents(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.promoteStudents(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to execute class promotions transaction.");
    }
  }

  @override
  Future<void> createAcademicYear(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createAcademicYear(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to create academic year.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAssessments() async {
    try {
      final list = await remoteDataSource.getAssessments();
      await sl<OfflineCache>().cacheData('faculty_assessments_list', list);
      return list;
    } catch (_) {
      final cached = sl<OfflineCache>().getCachedData('faculty_assessments_list');
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createAssessment(Map<String, dynamic> payload) async {
    try {
      final res = await remoteDataSource.createAssessment(payload);
      await sl<OfflineCache>().clearCache('faculty_assessments_list');
      return res;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to create assessment entry.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateAssessment(int id, Map<String, dynamic> payload) async {
    try {
      final res = await remoteDataSource.updateAssessment(id, payload);
      await sl<OfflineCache>().clearCache('faculty_assessments_list');
      return res;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update assessment details.");
    }
  }

  @override
  Future<void> deleteAssessment(int id) async {
    try {
      await remoteDataSource.deleteAssessment(id);
      await sl<OfflineCache>().clearCache('faculty_assessments_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete assessment details.");
    }
  }

  @override
  Future<void> submitMarks(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.submitMarks(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to upload assessment marks.");
    }
  }

  @override
  Future<Map<String, dynamic>> uploadFile(File file) async {
    try {
      return await remoteDataSource.uploadFile(file);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to upload file attachment.");
    }
  }

  @override
  Future<void> createHomework(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createHomework(payload);
      await sl<OfflineCache>().clearCache('faculty_homework_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to publish homework assignment.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHomework() async {
    return _executeWithCache(
      cacheKey: 'faculty_homework_list',
      remoteCall: () => remoteDataSource.getHomework(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getHomeworkSubmissions({String? className, String? section, int? homeworkId}) async {
    try {
      return await remoteDataSource.getHomeworkSubmissions(className: className, section: section, homeworkId: homeworkId);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> deleteHomework(int id) async {
    try {
      await remoteDataSource.deleteHomework(id);
      await sl<OfflineCache>().clearCache('faculty_homework_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete homework assignment.");
    }
  }

  @override
  Future<void> createAssignment(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createAssignment(payload);
      await sl<OfflineCache>().clearCache('faculty_assignments_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to publish assignment.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAssignments() async {
    return _executeWithCache(
      cacheKey: 'faculty_assignments_list',
      remoteCall: () => remoteDataSource.getAssignments(),
    );
  }

  @override
  Future<void> gradeAssignment(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.gradeAssignment(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to save assignment marks.");
    }
  }

  @override
  Future<void> createProgressCard(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createProgressCard(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to upload progress card.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProgressCards() async {
    return _executeWithCache(
      cacheKey: 'faculty_progress_cards',
      remoteCall: () => remoteDataSource.getProgressCards(),
    );
  }

  @override
  Future<void> createTimetable(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createTimetable(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to configure timetable.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTimetables() async {
    return _executeWithCache(
      cacheKey: 'faculty_timetables',
      remoteCall: () => remoteDataSource.getTimetables(),
    );
  }

  @override
  Future<void> createAnnouncement(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createAnnouncement(payload);
      await sl<OfflineCache>().clearCache('faculty_announcements_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to publish school announcement.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final list = await remoteDataSource.getAnnouncements();
      await sl<OfflineCache>().cacheData('faculty_announcements_list', list);
      return list;
    } catch (_) {
      final cached = sl<OfflineCache>().getCachedData('faculty_announcements_list');
      if (cached != null) return List<Map<String, dynamic>>.from(cached);
      rethrow;
    }
  }

  @override
  Future<void> createEvent(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createEvent(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to publish event schedule.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEvents() async {
    return _executeWithCache(
      cacheKey: 'faculty_events',
      remoteCall: () => remoteDataSource.getEvents(),
    );
  }

  @override
  Future<void> createHoliday(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createHoliday(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to configure holiday calendar.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHolidays() async {
    return _executeWithCache(
      cacheKey: 'faculty_holidays',
      remoteCall: () => remoteDataSource.getHolidays(),
    );
  }

  @override
  Future<void> createNotice(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createNotice(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to register public notice.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNotices() async {
    return _executeWithCache(
      cacheKey: 'faculty_notices',
      remoteCall: () => remoteDataSource.getNotices(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getTransport() async {
    return _executeWithCache(
      cacheKey: 'faculty_transport',
      remoteCall: () => remoteDataSource.getTransport(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getFeeDetails({String? className, String? section}) async {
    try {
      return await remoteDataSource.getFeeDetails(className: className, section: section);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to load school fee details.");
    }
  }

  @override
  Future<void> updateFeeByMapping(int scmId, Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.updateFeeByMapping(scmId, payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update student fee details.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAssignmentSubmissions({String? className, String? section, int? assignmentId}) async {
    try {
      return await remoteDataSource.getAssignmentSubmissions(className: className, section: section, assignmentId: assignmentId);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to load assignment submissions list.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateAssignment(int id, Map<String, dynamic> payload) async {
    try {
      final res = await remoteDataSource.updateAssignment(id, payload);
      await sl<OfflineCache>().clearCache('faculty_assignments_list');
      return res;
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update assignment details.");
    }
  }

  @override
  Future<void> deleteAssignment(int id) async {
    try {
      await remoteDataSource.deleteAssignment(id);
      await sl<OfflineCache>().clearCache('faculty_assignments_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete assignment record.");
    }
  }

  @override
  Future<void> deleteProgressCard(int id) async {
    try {
      await remoteDataSource.deleteProgressCard(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to remove progress card.");
    }
  }

  @override
  Future<void> deleteTimetable(int id) async {
    try {
      await remoteDataSource.deleteTimetable(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete timetable entry.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateAnnouncement(int id, Map<String, dynamic> payload) async {
    try {
      return await remoteDataSource.updateAnnouncement(id, payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update announcement.");
    }
  }

  @override
  Future<void> deleteAnnouncement(int id) async {
    try {
      await remoteDataSource.deleteAnnouncement(id);
      await sl<OfflineCache>().clearCache('faculty_announcements_list');
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete announcement.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> payload) async {
    try {
      return await remoteDataSource.updateEvent(id, payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update event.");
    }
  }

  @override
  Future<void> deleteEvent(int id) async {
    try {
      await remoteDataSource.deleteEvent(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete event.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateHoliday(int id, Map<String, dynamic> payload) async {
    try {
      return await remoteDataSource.updateHoliday(id, payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update holiday.");
    }
  }

  @override
  Future<void> deleteHoliday(int id) async {
    try {
      await remoteDataSource.deleteHoliday(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete holiday.");
    }
  }

  @override
  Future<Map<String, dynamic>> updateNotice(int id, Map<String, dynamic> payload) async {
    try {
      return await remoteDataSource.updateNotice(id, payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update notice.");
    }
  }

  @override
  Future<void> deleteNotice(int id) async {
    try {
      await remoteDataSource.deleteNotice(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete notice.");
    }
  }

  @override
  Future<Map<String, dynamic>> getFacultyMeetingNotifications() async {
    try {
      return await remoteDataSource.getFacultyMeetingNotifications();
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to fetch meeting notifications.");
    }
  }

  @override
  Future<void> markMeetingNotificationAsRead(int notificationId) async {
    try {
      await remoteDataSource.markMeetingNotificationAsRead(notificationId);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to mark notification as read.");
    }
  }
}
