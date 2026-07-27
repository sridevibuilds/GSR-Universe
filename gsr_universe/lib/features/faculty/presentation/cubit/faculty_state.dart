// Presentation Controller Layer - Faculty Dashboard State Model
import 'package:equatable/equatable.dart';

class FacultyState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<Map<String, dynamic>> studentsList;
  final List<Map<String, dynamic>> assessmentsList;
  final List<Map<String, dynamic>> homeworkList;
  final List<Map<String, dynamic>> scannedStudents;
  final String? uploadedFileUrl;
  final String? uploadedFileName;

  // New ERP State Fields
  final List<Map<String, dynamic>> assignmentsList;
  final List<Map<String, dynamic>> assignmentSubmissions;
  final List<Map<String, dynamic>> homeworkSubmissions;
  final List<Map<String, dynamic>> progressCardsList;
  final List<Map<String, dynamic>> timetableList;
  final List<Map<String, dynamic>> announcementsList;
  final List<Map<String, dynamic>> eventsList;
  final List<Map<String, dynamic>> holidaysList;
  final List<Map<String, dynamic>> noticesList;
  final List<Map<String, dynamic>> transportList;
  final List<Map<String, dynamic>> feeRecords;
  final List<Map<String, dynamic>> meetingNotifications;
  final int unreadMeetingCount;
  final Map<String, dynamic> classAttendanceReport;

  const FacultyState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.studentsList = const [],
    this.assessmentsList = const [],
    this.homeworkList = const [],
    this.scannedStudents = const [],
    this.uploadedFileUrl,
    this.uploadedFileName,
    this.assignmentsList = const [],
    this.assignmentSubmissions = const [],
    this.homeworkSubmissions = const [],
    this.progressCardsList = const [],
    this.timetableList = const [],
    this.announcementsList = const [],
    this.eventsList = const [],
    this.holidaysList = const [],
    this.noticesList = const [],
    this.transportList = const [],
    this.feeRecords = const [],
    this.meetingNotifications = const [],
    this.unreadMeetingCount = 0,
    this.classAttendanceReport = const {},
  });

  FacultyState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<Map<String, dynamic>>? studentsList,
    List<Map<String, dynamic>>? assessmentsList,
    List<Map<String, dynamic>>? homeworkList,
    List<Map<String, dynamic>>? scannedStudents,
    String? uploadedFileUrl,
    String? uploadedFileName,
    List<Map<String, dynamic>>? assignmentsList,
    List<Map<String, dynamic>>? assignmentSubmissions,
    List<Map<String, dynamic>>? homeworkSubmissions,
    List<Map<String, dynamic>>? progressCardsList,
    List<Map<String, dynamic>>? timetableList,
    List<Map<String, dynamic>>? announcementsList,
    List<Map<String, dynamic>>? eventsList,
    List<Map<String, dynamic>>? holidaysList,
    List<Map<String, dynamic>>? noticesList,
    List<Map<String, dynamic>>? transportList,
    List<Map<String, dynamic>>? feeRecords,
    List<Map<String, dynamic>>? meetingNotifications,
    int? unreadMeetingCount,
    Map<String, dynamic>? classAttendanceReport,
  }) {
    return FacultyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      studentsList: studentsList ?? this.studentsList,
      assessmentsList: assessmentsList ?? this.assessmentsList,
      homeworkList: homeworkList ?? this.homeworkList,
      scannedStudents: scannedStudents ?? this.scannedStudents,
      uploadedFileUrl: uploadedFileUrl ?? this.uploadedFileUrl,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
      assignmentsList: assignmentsList ?? this.assignmentsList,
      assignmentSubmissions: assignmentSubmissions ?? this.assignmentSubmissions,
      homeworkSubmissions: homeworkSubmissions ?? this.homeworkSubmissions,
      progressCardsList: progressCardsList ?? this.progressCardsList,
      timetableList: timetableList ?? this.timetableList,
      announcementsList: announcementsList ?? this.announcementsList,
      eventsList: eventsList ?? this.eventsList,
      holidaysList: holidaysList ?? this.holidaysList,
      noticesList: noticesList ?? this.noticesList,
      transportList: transportList ?? this.transportList,
      feeRecords: feeRecords ?? this.feeRecords,
      meetingNotifications: meetingNotifications ?? this.meetingNotifications,
      unreadMeetingCount: unreadMeetingCount ?? this.unreadMeetingCount,
      classAttendanceReport: classAttendanceReport ?? this.classAttendanceReport,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        successMessage,
        studentsList,
        assessmentsList,
        homeworkList,
        scannedStudents,
        uploadedFileUrl,
        uploadedFileName,
        assignmentsList,
        assignmentSubmissions,
        homeworkSubmissions,
        progressCardsList,
        timetableList,
        announcementsList,
        eventsList,
        holidaysList,
        noticesList,
        transportList,
        feeRecords,
        meetingNotifications,
        unreadMeetingCount,
        classAttendanceReport,
      ];
}
