// Admin Panel Dashboard State Model
import 'package:equatable/equatable.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<Map<String, dynamic>> facultyList;
  final Map<String, dynamic>? callSettings;
  final List<Map<String, dynamic>> callHistory;
  final List<Map<String, dynamic>> feeReports;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> meetingHistory;
  final Map<String, dynamic>? classReport;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.facultyList = const [],
    this.callSettings,
    this.callHistory = const [],
    this.feeReports = const [],
    this.notifications = const [],
    this.meetingHistory = const [],
    this.classReport,
  });

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<Map<String, dynamic>>? facultyList,
    Map<String, dynamic>? callSettings,
    List<Map<String, dynamic>>? callHistory,
    List<Map<String, dynamic>>? feeReports,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? meetingHistory,
    Map<String, dynamic>? classReport,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      facultyList: facultyList ?? this.facultyList,
      callSettings: callSettings ?? this.callSettings,
      callHistory: callHistory ?? this.callHistory,
      feeReports: feeReports ?? this.feeReports,
      notifications: notifications ?? this.notifications,
      meetingHistory: meetingHistory ?? this.meetingHistory,
      classReport: classReport ?? this.classReport,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        successMessage,
        facultyList,
        callSettings,
        callHistory,
        feeReports,
        notifications,
        meetingHistory,
        classReport,
      ];
}
