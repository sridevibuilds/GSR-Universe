// Presentation Controller Layer - Admin Cubit State Manager
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_state.dart';
import '../../../../core/errors/exceptions.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository adminRepository;

  AdminCubit(this.adminRepository) : super(const AdminState());

  /// Fetch core analytics reports and reminder configuration parameters on boot
  Future<void> fetchDashboardData() async {
    emit(state.copyWith(isLoading: true));
    try {
      final settings = await adminRepository.getCallSettings();
      final history = await adminRepository.getCallHistory();
      
      emit(state.copyWith(
        isLoading: false,
        callSettings: settings,
        callHistory: history,
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to load dashboard data."));
    }
  }

  /// Fetch pending fee report filtered by class and section
  Future<void> fetchPendingFeeReport({String? className, String? section}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final reports = await adminRepository.getPendingFeeReport(className: className, section: section);
      emit(state.copyWith(isLoading: false, feeReports: reports));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to load pending fee report."));
    }
  }
  Future<void> fetchFaculty() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await adminRepository.getAllFaculty();
      emit(state.copyWith(isLoading: false, facultyList: list));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to retrieve faculty records."));
    }
  }

  /// Add a new teacher profile
  Future<void> addFaculty(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.createFaculty(data);
      final updatedList = await adminRepository.getAllFaculty();
      emit(state.copyWith(
        isLoading: false,
        facultyList: updatedList,
        successMessage: "Faculty registered successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to register new faculty profile."));
    }
  }

  /// Update existing teacher profile details
  Future<void> editFaculty(int id, Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.updateFaculty(id, data);
      final updatedList = await adminRepository.getAllFaculty();
      emit(state.copyWith(
        isLoading: false,
        facultyList: updatedList,
        successMessage: "Faculty profile updated successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update faculty details."));
    }
  }

  /// Delete a teacher profile record
  Future<void> removeFaculty(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.deleteFaculty(id);
      final updatedList = await adminRepository.getAllFaculty();
      emit(state.copyWith(
        isLoading: false,
        facultyList: updatedList,
        successMessage: "Faculty profile deleted successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete faculty record."));
    }
  }

  /// Save settings adjustments (enabled flag, schedule dates, number checks)
  Future<void> updateReminderSettings(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.updateCallSettings(data);
      final settings = await adminRepository.getCallSettings();
      emit(state.copyWith(
        isLoading: false,
        callSettings: settings,
        successMessage: "Voice reminder settings updated successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to save calling configurations."));
    }
  }

  /// Trigger background caller sweep manually
  Future<void> triggerRemindersSweep() async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.triggerManualReminders();
      final history = await adminRepository.getCallHistory();
      emit(state.copyWith(
        isLoading: false,
        callHistory: history,
        successMessage: "Outbound fee call reminders sweep successfully triggered.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to run reminder calling sweeps."));
    }
  }

  /// Fetch system event notifications history
  Future<void> fetchNotifications() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await adminRepository.getSystemNotifications();
      emit(state.copyWith(isLoading: false, notifications: list, errorMessage: null));
    } catch (_) {
      emit(state.copyWith(isLoading: false, notifications: [], errorMessage: null));
    }
  }

  /// Fetch class analytics report for selected filters
  Future<void> fetchClassReport({
    String? academicYear,
    String? className,
    String? section,
    String? term,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final report = await adminRepository.getClassReport(
        academicYear: academicYear,
        className: className,
        section: section,
        term: term,
      );
      emit(state.copyWith(isLoading: false, classReport: report, errorMessage: null));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: null,
        classReport: {
          'summary': {
            'total_students': 0,
            'assessment_performance_pct': 0,
            'fee_collection': 0.0,
            'pending_fee': 0.0,
            'excellent_students': 0,
            'average_students': 0,
            'needs_improvement': 0,
            'daily_attendance_pct': 0,
            'monthly_attendance_pct': 0,
            'yearly_attendance_pct': 0,
          },
          'students': []
        },
      ));
    }
  }

  /// Clean messages to prevent duplicate alerts
  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  /// Publish new meeting announcement
  Future<void> publishMeetingAnnouncement(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.publishMeetingAnnouncement(payload);
      final history = await adminRepository.getMeetingHistory();
      emit(state.copyWith(
        isLoading: false,
        meetingHistory: history,
        successMessage: "Meeting Announcement published successfully!",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to publish meeting announcement."));
    }
  }

  /// Fetch published meeting history
  Future<void> fetchMeetingHistory() async {
    emit(state.copyWith(isLoading: true));
    try {
      final history = await adminRepository.getMeetingHistory();
      emit(state.copyWith(isLoading: false, meetingHistory: history));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to fetch meeting history."));
    }
  }

  /// Delete meeting announcement
  Future<void> deleteMeetingAnnouncement(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await adminRepository.deleteMeetingAnnouncement(id);
      final history = await adminRepository.getMeetingHistory();
      emit(state.copyWith(
        isLoading: false,
        meetingHistory: history,
        successMessage: "Meeting Announcement deleted successfully!",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete meeting announcement."));
    }
  }
}
