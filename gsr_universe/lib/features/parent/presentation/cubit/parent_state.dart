// Presentation Controller Layer - Parent Dashboard State Model
import 'package:equatable/equatable.dart';

class ParentState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic>? profileData;
  final List<Map<String, dynamic>> attendanceLogs;
  final double attendancePercentage;
  final Map<String, dynamic>? attendanceSummary;
  final List<Map<String, dynamic>> marks;
  final List<Map<String, dynamic>> homework;
  final List<Map<String, dynamic>> assignments;
  final List<Map<String, dynamic>> assignmentMarks;
  final List<Map<String, dynamic>> feesHistory;
  final double totalPendingDues;
  final Map<String, dynamic>? timetable;
  final List<Map<String, dynamic>> announcements;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> holidays;
  final List<Map<String, dynamic>> progressCards;
  final List<Map<String, dynamic>> notices;
  final Map<String, dynamic>? transportDetails;
  final List<Map<String, dynamic>> parentNotifications;
  final int unreadParentNotificationCount;

  const ParentState({
    this.isLoading = false,
    this.errorMessage,
    this.dashboardData,
    this.profileData,
    this.attendanceLogs = const [],
    this.attendancePercentage = 100.00,
    this.attendanceSummary,
    this.marks = const [],
    this.homework = const [],
    this.assignments = const [],
    this.assignmentMarks = const [],
    this.feesHistory = const [],
    this.totalPendingDues = 0.00,
    this.timetable,
    this.announcements = const [],
    this.events = const [],
    this.holidays = const [],
    this.progressCards = const [],
    this.notices = const [],
    this.transportDetails,
    this.parentNotifications = const [],
    this.unreadParentNotificationCount = 0,
  });

  ParentState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? dashboardData,
    Map<String, dynamic>? profileData,
    List<Map<String, dynamic>>? attendanceLogs,
    double? attendancePercentage,
    Map<String, dynamic>? attendanceSummary,
    List<Map<String, dynamic>>? marks,
    List<Map<String, dynamic>>? homework,
    List<Map<String, dynamic>>? assignments,
    List<Map<String, dynamic>>? assignmentMarks,
    List<Map<String, dynamic>>? feesHistory,
    double? totalPendingDues,
    Map<String, dynamic>? timetable,
    List<Map<String, dynamic>>? announcements,
    List<Map<String, dynamic>>? events,
    List<Map<String, dynamic>>? holidays,
    List<Map<String, dynamic>>? progressCards,
    List<Map<String, dynamic>>? notices,
    Map<String, dynamic>? transportDetails,
    List<Map<String, dynamic>>? parentNotifications,
    int? unreadParentNotificationCount,
  }) {
    return ParentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      dashboardData: dashboardData ?? this.dashboardData,
      profileData: profileData ?? this.profileData,
      attendanceLogs: attendanceLogs ?? this.attendanceLogs,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      attendanceSummary: attendanceSummary ?? this.attendanceSummary,
      marks: marks ?? this.marks,
      homework: homework ?? this.homework,
      assignments: assignments ?? this.assignments,
      assignmentMarks: assignmentMarks ?? this.assignmentMarks,
      feesHistory: feesHistory ?? this.feesHistory,
      totalPendingDues: totalPendingDues ?? this.totalPendingDues,
      timetable: timetable ?? this.timetable,
      announcements: announcements ?? this.announcements,
      events: events ?? this.events,
      holidays: holidays ?? this.holidays,
      progressCards: progressCards ?? this.progressCards,
      notices: notices ?? this.notices,
      transportDetails: transportDetails ?? this.transportDetails,
      parentNotifications: parentNotifications ?? this.parentNotifications,
      unreadParentNotificationCount: unreadParentNotificationCount ?? this.unreadParentNotificationCount,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        dashboardData,
        profileData,
        attendanceLogs,
        attendancePercentage,
        attendanceSummary,
        marks,
        homework,
        assignments,
        assignmentMarks,
        feesHistory,
        totalPendingDues,
        timetable,
        announcements,
        events,
        holidays,
        progressCards,
        notices,
        transportDetails,
        parentNotifications,
        unreadParentNotificationCount,
      ];
}
