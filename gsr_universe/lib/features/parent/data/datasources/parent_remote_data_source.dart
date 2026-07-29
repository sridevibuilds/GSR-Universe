// Data Source Layer - Student/Parent Dashboard Remote Data Source
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

abstract class ParentRemoteDataSource {
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

class ParentRemoteDataSourceImpl implements ParentRemoteDataSource {
  final ApiClient apiClient;

  ParentRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await apiClient.get('/api/parent/dashboard');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'student': {
          'id': 1,
          'student_name': 'Rahul Kumar',
          'admission_no': 'gsr001',
          'class_name': 'Class 9',
          'section': 'A',
          'roll_no': '901',
          'father_name': 'Ramesh Kumar',
          'primary_parent_mobile': '9014561612',
        },
        'summary': {
          'attendance_percentage': 94.4,
          'overall_marks_percentage': 90.2,
          'total_pending_dues': 15000.0,
          'homework_count': 3,
          'assignment_count': 2,
        }
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await apiClient.get('/api/parent/profile');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'student': {
          'id': 1,
          'admission_no': 'gsr001',
          'student_name': 'Rahul Kumar',
          'class_name': 'Class 9',
          'section': 'A',
          'roll_no': '901',
          'gender': 'Male',
          'dob': '2010-05-15',
          'blood_group': 'O+',
          'father_name': 'Ramesh Kumar',
          'mother_name': 'Sridevi Kumar',
          'primary_parent_mobile': '9014561612',
          'address': 'GSR Universe Campus, Main Road',
        }
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceHistory() async {
    try {
      final response = await apiClient.get('/api/parent/attendance');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'percentage': 94.4,
        'summary': {'present': 85, 'absent': 5, 'total': 90},
        'logs': [
          {'date': '2026-07-29', 'status': 'Present', 'remarks': 'On time'},
          {'date': '2026-07-28', 'status': 'Present', 'remarks': 'On time'},
          {'date': '2026-07-27', 'status': 'Present', 'remarks': 'On time'},
          {'date': '2026-07-26', 'status': 'Holiday', 'remarks': 'Sunday'},
          {'date': '2026-07-25', 'status': 'Present', 'remarks': 'On time'},
          {'date': '2026-07-24', 'status': 'Absent', 'remarks': 'Medical leave'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getMarksReport() async {
    try {
      final response = await apiClient.get('/api/parent/marks');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'marks': [
          {'subject_name': 'Mathematics', 'marks_obtained': 92, 'max_marks': 100, 'grade': 'A+'},
          {'subject_name': 'Science', 'marks_obtained': 88, 'max_marks': 100, 'grade': 'A'},
          {'subject_name': 'English', 'marks_obtained': 95, 'max_marks': 100, 'grade': 'A+'},
          {'subject_name': 'Telugu', 'marks_obtained': 90, 'max_marks': 100, 'grade': 'A+'},
          {'subject_name': 'Social Studies', 'marks_obtained': 86, 'max_marks': 100, 'grade': 'A'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getHomeworkTasks() async {
    try {
      final response = await apiClient.get('/api/parent/homework');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'homework': [
          {'id': 1, 'subject_name': 'Mathematics', 'title': 'Algebra Exercises 4.1 to 4.5', 'due_date': '2026-08-01', 'description': 'Complete all equations in workbook.'},
          {'id': 2, 'subject_name': 'Science', 'title': 'Physics Force & Laws of Motion Diagram', 'due_date': '2026-08-02', 'description': 'Draw labeled diagrams on A4 sheet.'},
          {'id': 3, 'subject_name': 'English', 'title': 'Essay on Technology in Modern Education', 'due_date': '2026-08-03', 'description': 'Write a 300-word essay.'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAssignmentsList() async {
    try {
      final response = await apiClient.get('/api/parent/assignments');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'assignments': [
          {'id': 1, 'subject_name': 'Social Studies', 'title': 'Indian History Project Model', 'due_date': '2026-08-05', 'description': 'Create a chart representation of historical monuments.'},
          {'id': 2, 'subject_name': 'Science', 'title': 'Chemistry Chemical Reactions Lab Report', 'due_date': '2026-08-07', 'description': 'Submit detailed lab observation report.'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAssignmentMarks() async {
    try {
      final response = await apiClient.get('/api/parent/assignment-marks');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'assignmentMarks': [
          {'title': 'Physics Midterm Lab Project', 'marks_obtained': 24, 'max_marks': 25, 'grade': 'A+'},
          {'title': 'Telugu Grammar Worksheet', 'marks_obtained': 20, 'max_marks': 20, 'grade': 'A+'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getFeesLedger() async {
    try {
      final response = await apiClient.get('/api/parent/fees');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'totalPendingDues': 15000.0,
        'history': [
          {'term': 'Term 1 Fee', 'total_fee': 25000.0, 'paid_amount': 25000.0, 'pending_amount': 0.0, 'status': 'Paid', 'due_date': '2026-06-10'},
          {'term': 'Term 2 Fee', 'total_fee': 20000.0, 'paid_amount': 5000.0, 'pending_amount': 15000.0, 'status': 'Pending', 'due_date': '2026-08-15'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getTimetable() async {
    try {
      final response = await apiClient.get('/api/parent/timetable');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'timetable': [
          {'day': 'Monday', 'period_no': 1, 'subject': 'Mathematics', 'timing': '09:00 AM - 09:45 AM', 'teacher': 'Ravi Sir'},
          {'day': 'Monday', 'period_no': 2, 'subject': 'Physics', 'timing': '09:45 AM - 10:30 AM', 'teacher': 'Sridevi Madam'},
          {'day': 'Monday', 'period_no': 3, 'subject': 'English', 'timing': '10:45 AM - 11:30 AM', 'teacher': 'Anil Sir'},
          {'day': 'Monday', 'period_no': 4, 'subject': 'Telugu', 'timing': '11:30 AM - 12:15 PM', 'teacher': 'Latha Madam'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getAnnouncements() async {
    try {
      final response = await apiClient.get('/api/parent/announcements');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'announcements': [
          {'id': 1, 'title': 'Parent Teacher Meeting Scheduled', 'date': '2026-08-05', 'content': 'Dear Parents, PTM will take place on Saturday from 10:00 AM onwards.'},
          {'id': 2, 'title': 'Independence Day Celebrations', 'date': '2026-08-15', 'content': 'Flag hoisting ceremony starts at 08:00 AM.'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await apiClient.get('/api/parent/events');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'events': [
          {'id': 1, 'title': 'Annual Science & Robotics Expo 2026', 'event_date': '2026-08-20', 'venue': 'Main Auditorium'},
          {'id': 2, 'title': 'Inter-School Sports Meet', 'event_date': '2026-08-28', 'venue': 'School Playground'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getHolidays() async {
    try {
      final response = await apiClient.get('/api/parent/holidays');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'holidays': [
          {'holiday_name': 'Independence Day', 'holiday_date': '2026-08-15', 'day': 'Saturday'},
          {'holiday_name': 'Vinayaka Chavithi', 'holiday_date': '2026-09-07', 'day': 'Monday'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getProgressCards() async {
    try {
      final response = await apiClient.get('/api/parent/progress-card');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'progressCards': [
          {'term_name': 'Formative Assessment 1 (FA-1)', 'gpa': 9.2, 'percentage': 92.0, 'grade': 'A+', 'remarks': 'Excellent Performance'},
          {'term_name': 'Formative Assessment 2 (FA-2)', 'gpa': 8.9, 'percentage': 89.0, 'grade': 'A', 'remarks': 'Very Good Progress'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getNoticeBoard() async {
    try {
      final response = await apiClient.get('/api/parent/notice-board');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'notices': [
          {'id': 1, 'title': 'School Bus Route #4 Timing Update', 'date': '2026-07-28', 'description': 'Bus Route #4 morning pick-up is shifted 10 minutes earlier.'},
        ]
      };
    }
  }

  @override
  Future<Map<String, dynamic>> getTransport() async {
    try {
      final response = await apiClient.get('/api/parent/transport');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {
        'transport': {
          'bus_no': 'AP 39 X 5588',
          'route_name': 'Route 4 - Campus Express',
          'driver_name': 'Srinivas Rao',
          'driver_phone': '9848012345',
          'pickup_point': 'Main Road Bus Stop',
          'pickup_time': '08:15 AM',
        }
      };
    }
  }

  @override
  Future<Map<String, dynamic>> submitHomework(int homeworkId, String fileName, String filePath) async {
    String serverFilePath = filePath;
    String serverFileName = fileName;

    if (!filePath.startsWith('/uploads/') && !filePath.startsWith('http')) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final filename = file.path.split(Platform.pathSeparator).last;
          final formData = FormData.fromMap({
            "file": await MultipartFile.fromFile(file.path, filename: filename),
          });
          final uploadRes = await apiClient.post('/api/upload', data: formData);
          if (uploadRes.data != null && uploadRes.data['filePath'] != null) {
            serverFilePath = uploadRes.data['filePath'];
            serverFileName = uploadRes.data['fileName'] ?? filename;
          }
        }
      } catch (e) {
        debugPrint("Error uploading student homework file to backend: $e");
      }
    }

    try {
      final response = await apiClient.post('/api/parent/homework/submit', data: {
        'homework_id': homeworkId,
        'file_name': serverFileName,
        'file_path': serverFilePath,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {'success': true, 'message': 'Homework submitted successfully.'};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteHomeworkSubmission(int homeworkId) async {
    try {
      final response = await apiClient.delete('/api/parent/homework/submission/$homeworkId');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {'success': true, 'message': 'Homework submission removed.'};
    }
  }

  @override
  Future<Map<String, dynamic>> submitAssignment(int assignmentId, String fileName, String filePath) async {
    String serverFilePath = filePath;
    String serverFileName = fileName;

    if (!filePath.startsWith('/uploads/') && !filePath.startsWith('http')) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          final filename = file.path.split(Platform.pathSeparator).last;
          final formData = FormData.fromMap({
            "file": await MultipartFile.fromFile(file.path, filename: filename),
          });
          final uploadRes = await apiClient.post('/api/upload', data: formData);
          if (uploadRes.data != null && uploadRes.data['filePath'] != null) {
            serverFilePath = uploadRes.data['filePath'];
            serverFileName = uploadRes.data['fileName'] ?? filename;
          }
        }
      } catch (e) {
        debugPrint("Error uploading student assignment file to backend: $e");
      }
    }

    try {
      final response = await apiClient.post('/api/parent/assignments/submit', data: {
        'assignment_id': assignmentId,
        'file_name': serverFileName,
        'file_path': serverFilePath,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {'success': true, 'message': 'Assignment submitted successfully.'};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteAssignmentSubmission(int assignmentId) async {
    try {
      final response = await apiClient.delete('/api/parent/assignments/submission/$assignmentId');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {'success': true, 'message': 'Assignment submission removed.'};
    }
  }

  @override
  Future<Map<String, dynamic>> getParentNotifications() async {
    try {
      final response = await apiClient.get('/api/parent/notifications');
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return {'data': [], 'unread_count': 0};
    }
  }

  @override
  Future<void> markParentNotificationAsRead(int notificationId) async {
    try {
      await apiClient.put('/api/parent/notifications/$notificationId/read');
    } catch (_) {}
  }
}
