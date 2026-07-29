// Data Layer - Admin Repository Implementation with Offline Caching
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/offline_cache.dart';
import '../../../../core/network/connectivity_monitor.dart';
import '../../../../core/di/injection_container.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

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
          return _castCachedData<T>(cached);
        }
        rethrow;
      }
    } else {
      final cached = cache.getCachedData(cacheKey);
      if (cached != null) {
        return _castCachedData<T>(cached);
      }
      throw ServerException("You are currently offline. Check your internet connection.");
    }
  }

  T _castCachedData<T>(dynamic cached) {
    if (cached is T) return cached;
    if (cached is List) {
      return cached.map((e) => Map<String, dynamic>.from(e as Map)).toList() as T;
    }
    if (cached is Map) {
      return Map<String, dynamic>.from(cached) as T;
    }
    return cached as T;
  }

  @override
  Future<Map<String, dynamic>> getAdminOverview() async {
    return _executeWithCache(
      cacheKey: 'admin_overview_metrics',
      remoteCall: () => remoteDataSource.getAdminOverview(),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getAllFaculty() async {
    return _executeWithCache(
      cacheKey: 'admin_faculty_records',
      remoteCall: () => remoteDataSource.getAllFaculty(),
    );
  }

  @override
  Future<void> createFaculty(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.createFaculty(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to submit new faculty record.");
    }
  }

  @override
  Future<void> updateFaculty(int id, Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.updateFaculty(id, payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update faculty record.");
    }
  }

  @override
  Future<void> deleteFaculty(int id) async {
    try {
      await remoteDataSource.deleteFaculty(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete faculty record.");
    }
  }

  @override
  Future<Map<String, dynamic>> getCallSettings() async {
    return _executeWithCache(
      cacheKey: 'admin_call_settings',
      remoteCall: () => remoteDataSource.getCallSettings(),
    );
  }

  @override
  Future<void> updateCallSettings(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.updateCallSettings(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to update voice reminder settings.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCallHistory() async {
    return _executeWithCache(
      cacheKey: 'admin_call_logs',
      remoteCall: () => remoteDataSource.getCallHistory(),
    );
  }

  @override
  Future<void> triggerManualReminders() async {
    try {
      await remoteDataSource.triggerManualReminders();
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to trigger manual reminder sweep.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingFeeReport({String? className, String? section}) async {
    try {
      return await remoteDataSource.getPendingFeeReport(className: className, section: section);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to fetch pending fee report.");
    }
  }

  @override
  Future<Map<String, dynamic>> getClassReport({
    String? academicYear,
    String? className,
    String? section,
    String? term,
  }) async {
    try {
      return await remoteDataSource.getClassReport(
        academicYear: academicYear,
        className: className,
        section: section,
        term: term,
      );
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to generate class report.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSystemNotifications() async {
    return _executeWithCache(
      cacheKey: 'admin_system_notifications',
      remoteCall: () => remoteDataSource.getSystemNotifications(),
    );
  }

  @override
  Future<void> publishMeetingAnnouncement(Map<String, dynamic> payload) async {
    try {
      await remoteDataSource.publishMeetingAnnouncement(payload);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to publish meeting announcement.");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMeetingHistory() async {
    try {
      return await remoteDataSource.getMeetingHistory();
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to fetch meeting history.");
    }
  }

  @override
  Future<void> deleteMeetingAnnouncement(int id) async {
    try {
      await remoteDataSource.deleteMeetingAnnouncement(id);
    } on ServerException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw ServerException("Failed to delete meeting announcement.");
    }
  }
}
