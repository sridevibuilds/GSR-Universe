// Data Layer - Parent Repository Implementation with Offline Caching
import '../../domain/repositories/parent_repository.dart';
import '../datasources/parent_remote_data_source.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/offline_cache.dart';
import '../../../../core/network/connectivity_monitor.dart';
import '../../../../core/di/injection_container.dart';

class ParentRepositoryImpl implements ParentRepository {
  final ParentRemoteDataSource remoteDataSource;

  ParentRepositoryImpl({required this.remoteDataSource});

  /// Executes remote API calls caching data locally, falling back to cache when offline
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
        // Fallback to cache if remote call crashes on transient server errors
        final cached = cache.getCachedData(cacheKey);
        if (cached != null) {
          return cached as T;
        }
        rethrow;
      }
    } else {
      // Offline fallback
      final cached = cache.getCachedData(cacheKey);
      if (cached != null) {
        return cached as T;
      }
      throw ServerException("You are currently offline. Check your internet connection.");
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardSummary() {
    return _executeWithCache(
      cacheKey: 'parent_dashboard_summary',
      remoteCall: () => remoteDataSource.getDashboardSummary(),
    );
  }

  @override
  Future<Map<String, dynamic>> getProfile() {
    return _executeWithCache(
      cacheKey: 'parent_profile',
      remoteCall: () => remoteDataSource.getProfile(),
    );
  }

  @override
  Future<Map<String, dynamic>> getAttendanceHistory() {
    return _executeWithCache(
      cacheKey: 'parent_attendance',
      remoteCall: () => remoteDataSource.getAttendanceHistory(),
    );
  }

  @override
  Future<Map<String, dynamic>> getMarksReport() {
    return _executeWithCache(
      cacheKey: 'parent_marks',
      remoteCall: () => remoteDataSource.getMarksReport(),
    );
  }

  @override
  Future<Map<String, dynamic>> getHomeworkTasks() {
    return _executeWithCache(
      cacheKey: 'parent_homework',
      remoteCall: () => remoteDataSource.getHomeworkTasks(),
    );
  }

  @override
  Future<Map<String, dynamic>> getAssignmentsList() {
    return _executeWithCache(
      cacheKey: 'parent_assignments',
      remoteCall: () => remoteDataSource.getAssignmentsList(),
    );
  }

  @override
  Future<Map<String, dynamic>> getAssignmentMarks() {
    return _executeWithCache(
      cacheKey: 'parent_assignment_marks',
      remoteCall: () => remoteDataSource.getAssignmentMarks(),
    );
  }

  @override
  Future<Map<String, dynamic>> getFeesLedger() {
    return _executeWithCache(
      cacheKey: 'parent_fees',
      remoteCall: () => remoteDataSource.getFeesLedger(),
    );
  }

  @override
  Future<Map<String, dynamic>> getTimetable() {
    return _executeWithCache(
      cacheKey: 'parent_timetable',
      remoteCall: () => remoteDataSource.getTimetable(),
    );
  }

  @override
  Future<Map<String, dynamic>> getAnnouncements() {
    return _executeWithCache(
      cacheKey: 'parent_announcements',
      remoteCall: () => remoteDataSource.getAnnouncements(),
    );
  }

  @override
  Future<Map<String, dynamic>> getEvents() {
    return _executeWithCache(
      cacheKey: 'parent_events',
      remoteCall: () => remoteDataSource.getEvents(),
    );
  }

  @override
  Future<Map<String, dynamic>> getHolidays() {
    return _executeWithCache(
      cacheKey: 'parent_holidays',
      remoteCall: () => remoteDataSource.getHolidays(),
    );
  }

  @override
  Future<Map<String, dynamic>> getProgressCards() {
    return _executeWithCache(
      cacheKey: 'parent_progress_cards',
      remoteCall: () => remoteDataSource.getProgressCards(),
    );
  }

  @override
  Future<Map<String, dynamic>> getNoticeBoard() {
    return _executeWithCache(
      cacheKey: 'parent_notice_board',
      remoteCall: () => remoteDataSource.getNoticeBoard(),
    );
  }

  @override
  Future<Map<String, dynamic>> getTransport() {
    return _executeWithCache(
      cacheKey: 'parent_transport',
      remoteCall: () => remoteDataSource.getTransport(),
    );
  }

  @override
  Future<Map<String, dynamic>> submitHomework(int homeworkId, String fileName, String filePath) {
    return remoteDataSource.submitHomework(homeworkId, fileName, filePath);
  }

  @override
  Future<Map<String, dynamic>> deleteHomeworkSubmission(int homeworkId) {
    return remoteDataSource.deleteHomeworkSubmission(homeworkId);
  }

  @override
  Future<Map<String, dynamic>> submitAssignment(int assignmentId, String fileName, String filePath) {
    return remoteDataSource.submitAssignment(assignmentId, fileName, filePath);
  }

  @override
  Future<Map<String, dynamic>> deleteAssignmentSubmission(int assignmentId) {
    return remoteDataSource.deleteAssignmentSubmission(assignmentId);
  }

  @override
  Future<Map<String, dynamic>> getParentNotifications() {
    return remoteDataSource.getParentNotifications();
  }

  @override
  Future<void> markParentNotificationAsRead(int notificationId) {
    return remoteDataSource.markParentNotificationAsRead(notificationId);
  }
}
