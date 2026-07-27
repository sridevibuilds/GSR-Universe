// Presentation Controller Layer - Parent Cubit State Manager
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/parent_repository.dart';
import 'parent_state.dart';
import '../../../../core/errors/exceptions.dart';

class ParentCubit extends Cubit<ParentState> {
  final ParentRepository parentRepository;

  ParentCubit(this.parentRepository) : super(const ParentState());

  /// Load all child indicators concurrently with fault isolation
  Future<void> loadAllChildData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    Map<String, dynamic> summary = {};
    Map<String, dynamic> profile = {};
    Map<String, dynamic> attendance = {};
    Map<String, dynamic> marks = {};
    Map<String, dynamic> homework = {};
    Map<String, dynamic> assignments = {};
    Map<String, dynamic> assignMarks = {};
    Map<String, dynamic> fees = {};
    Map<String, dynamic> timetable = {};
    Map<String, dynamic> announcements = {};
    Map<String, dynamic> events = {};
    Map<String, dynamic> holidays = {};
    Map<String, dynamic> progress = {};
    Map<String, dynamic> noticeBoard = {};
    Map<String, dynamic> transport = {};
    Map<String, dynamic> notifsRes = {};

    try { summary = await parentRepository.getDashboardSummary(); } catch (_) {}
    try { profile = await parentRepository.getProfile(); } catch (_) {}
    try { attendance = await parentRepository.getAttendanceHistory(); } catch (_) {}
    try { marks = await parentRepository.getMarksReport(); } catch (_) {}
    try { homework = await parentRepository.getHomeworkTasks(); } catch (_) {}
    try { assignments = await parentRepository.getAssignmentsList(); } catch (_) {}
    try { assignMarks = await parentRepository.getAssignmentMarks(); } catch (_) {}
    try { fees = await parentRepository.getFeesLedger(); } catch (_) {}
    try { timetable = await parentRepository.getTimetable(); } catch (_) {}
    try { announcements = await parentRepository.getAnnouncements(); } catch (_) {}
    try { events = await parentRepository.getEvents(); } catch (_) {}
    try { holidays = await parentRepository.getHolidays(); } catch (_) {}
    try { progress = await parentRepository.getProgressCards(); } catch (_) {}
    try { noticeBoard = await parentRepository.getNoticeBoard(); } catch (_) {}
    try { transport = await parentRepository.getTransport(); } catch (_) {}
    try { notifsRes = await parentRepository.getParentNotifications(); } catch (_) {}

    // Extract raw lists safely
    final List<dynamic> attendanceList = attendance['logs'] ?? [];
    final List<dynamic> marksList = marks['marks'] ?? [];
    final List<dynamic> homeworkList = homework['homework'] ?? [];
    final List<dynamic> assignmentsList = assignments['assignments'] ?? [];
    final List<dynamic> assignMarksList = assignMarks['assignmentMarks'] ?? [];
    final List<dynamic> feesHistoryList = fees['history'] ?? [];
    final List<dynamic> announcementsList = announcements['announcements'] ?? [];
    final List<dynamic> eventsList = events['events'] ?? [];
    final List<dynamic> holidaysList = holidays['holidays'] ?? [];
    final List<dynamic> progressList = progress['progressCards'] ?? [];
    final List<dynamic> noticeBoardList = noticeBoard['notices'] ?? noticeBoard['data'] ?? [];
    final List<dynamic> notifsList = notifsRes['data'] ?? [];
    final int unreadNotifCount = notifsRes['unread_count'] ?? 0;

    emit(state.copyWith(
      isLoading: false,
      dashboardData: summary,
      profileData: profile,
      attendanceLogs: attendanceList.map((e) => Map<String, dynamic>.from(e)).toList(),
      attendancePercentage: (attendance['percentage'] as num? ?? 100.0).toDouble(),
      attendanceSummary: attendance['summary'],
      marks: marksList.map((e) => Map<String, dynamic>.from(e)).toList(),
      homework: homeworkList.map((e) => Map<String, dynamic>.from(e)).toList(),
      assignments: assignmentsList.map((e) => Map<String, dynamic>.from(e)).toList(),
      assignmentMarks: assignMarksList.map((e) => Map<String, dynamic>.from(e)).toList(),
      feesHistory: feesHistoryList.map((e) => Map<String, dynamic>.from(e)).toList(),
      totalPendingDues: (fees['totalPendingDues'] as num? ?? 0.0).toDouble(),
      timetable: timetable['timetable'],
      announcements: announcementsList.map((e) => Map<String, dynamic>.from(e)).toList(),
      events: eventsList.map((e) => Map<String, dynamic>.from(e)).toList(),
      holidays: holidaysList.map((e) => Map<String, dynamic>.from(e)).toList(),
      progressCards: progressList.map((e) => Map<String, dynamic>.from(e)).toList(),
      notices: noticeBoardList.map((e) => Map<String, dynamic>.from(e)).toList(),
      transportDetails: transport['transport'] != null ? Map<String, dynamic>.from(transport['transport']) : null,
      parentNotifications: notifsList.map((e) => Map<String, dynamic>.from(e)).toList(),
      unreadParentNotificationCount: unreadNotifCount,
      errorMessage: null,
    ));
  }

  /// Clear active error warning parameters
  void clearErrorMessage() {
    emit(state.copyWith(errorMessage: null));
  }

  Future<void> submitHomework(int homeworkId, String fileName, String filePath) async {
    try {
      await parentRepository.submitHomework(homeworkId, fileName, filePath);
      await loadAllChildData();
    } on ServerException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: "Failed to submit homework."));
    }
  }

  Future<void> deleteHomeworkSubmission(int homeworkId) async {
    try {
      await parentRepository.deleteHomeworkSubmission(homeworkId);
      await loadAllChildData();
    } on ServerException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: "Failed to delete homework submission."));
    }
  }

  Future<void> submitAssignment(int assignmentId, String fileName, String filePath) async {
    try {
      await parentRepository.submitAssignment(assignmentId, fileName, filePath);
      await loadAllChildData();
    } on ServerException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: "Failed to submit assignment."));
    }
  }

  Future<void> deleteAssignmentSubmission(int assignmentId) async {
    try {
      await parentRepository.deleteAssignmentSubmission(assignmentId);
      await loadAllChildData();
    } on ServerException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(errorMessage: "Failed to delete assignment submission."));
    }
  }

  /// Fetch Parent Notifications
  Future<void> fetchParentNotifications() async {
    try {
      final res = await parentRepository.getParentNotifications();
      final List<dynamic> data = res['data'] ?? [];
      final int unreadCount = res['unread_count'] ?? 0;
      emit(state.copyWith(
        parentNotifications: data.map((e) => Map<String, dynamic>.from(e)).toList(),
        unreadParentNotificationCount: unreadCount,
      ));
    } catch (_) {}
  }

  /// Mark Parent Notification as Read
  Future<void> markParentNotificationAsRead(int notificationId) async {
    try {
      await parentRepository.markParentNotificationAsRead(notificationId);
      await fetchParentNotifications();
    } catch (_) {}
  }
}
