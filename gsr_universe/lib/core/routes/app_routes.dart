// Core Navigation Routing Gateway
import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_selection_page.dart';
import '../../features/auth/presentation/pages/child_selection_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/faculty/presentation/pages/faculty_dashboard_page.dart';
import '../../features/parent/presentation/pages/parent_dashboard_page.dart';

import '../../features/admin/presentation/pages/faculty_management_page.dart';
import '../../features/admin/presentation/pages/call_settings_page.dart';
import '../../features/admin/presentation/pages/student_management_page.dart';
import '../../features/admin/presentation/pages/notifications_page.dart';

// Faculty ERP Module Imports
import '../../features/faculty/presentation/pages/student_management_page.dart' as fac_student;
import '../../features/faculty/presentation/pages/attendance_monitoring_page.dart' as fac_attend;
import '../../features/faculty/presentation/pages/assessments_page.dart' as fac_assess;
import '../../features/faculty/presentation/pages/homework_page.dart' as fac_hw;
import '../../features/faculty/presentation/pages/assignments_page.dart' as fac_assign;
import '../../features/faculty/presentation/pages/progress_cards_page.dart' as fac_progress;
import '../../features/faculty/presentation/pages/timetable_page.dart' as fac_timetable;
import '../../features/faculty/presentation/pages/announcements_page.dart' as fac_ann;
import '../../features/faculty/presentation/pages/events_page.dart' as fac_event;
import '../../features/faculty/presentation/pages/holidays_page.dart' as fac_holiday;
import '../../features/faculty/presentation/pages/notice_board_page.dart' as fac_notice;
import '../../features/faculty/presentation/pages/transport_page.dart' as fac_transport;
import '../../features/faculty/presentation/pages/student_promotion_page.dart' as fac_promo;
import '../../features/faculty/presentation/pages/fee_details_page.dart' as fac_fee;

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String childSelection = '/child-selection';
  static const String adminDashboard = '/admin-dashboard';
  static const String facultyDashboard = '/faculty-dashboard';
  static const String parentDashboard = '/parent-dashboard';
  static const String facultyManagement = '/faculty-management';
  static const String callSettings = '/call-settings';
  static const String studentManagement = '/student-management';
  static const String notifications = '/notifications';

  // Faculty ERP Named Routes
  static const String facStudentManagement = '/faculty/student-management';
  static const String facAttendance = '/faculty/attendance';
  static const String facAssessments = '/faculty/assessments';
  static const String facHomework = '/faculty/homework';
  static const String facAssignments = '/faculty/assignments';
  static const String facProgressCards = '/faculty/progress-cards';
  static const String facTimetable = '/faculty/timetable';
  static const String facAnnouncements = '/faculty/announcements';
  static const String facEvents = '/faculty/events';
  static const String facHolidays = '/faculty/holidays';
  static const String facNoticeBoard = '/faculty/notice-board';
  static const String facTransport = '/faculty/transport';
  static const String facStudentPromotion = '/faculty/student-promotion';
  static const String facFeeDetails = '/faculty/fee-details';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginSelectionPage());
      case childSelection:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ChildSelectionPage(
            students: args['students'] ?? [],
            token: args['token'] ?? '',
          ),
        );
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
      case facultyDashboard:
        return MaterialPageRoute(builder: (_) => const FacultyDashboardPage());
      case parentDashboard:
        return MaterialPageRoute(builder: (_) => const ParentDashboardPage());
      case facultyManagement:
        return MaterialPageRoute(builder: (_) => const FacultyManagementPage());
      case callSettings:
        return MaterialPageRoute(builder: (_) => const CallSettingsPage());
      case studentManagement:
        return MaterialPageRoute(builder: (_) => const StudentManagementPage());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsPage());

      // Faculty ERP Route Mappings
      case facStudentManagement:
        return MaterialPageRoute(builder: (_) => const fac_student.StudentManagementPage());
      case facAttendance:
        return MaterialPageRoute(builder: (_) => const fac_attend.AttendanceMonitoringPage());
      case facAssessments:
        return MaterialPageRoute(builder: (_) => const fac_assess.AssessmentsPage());
      case facHomework:
        return MaterialPageRoute(builder: (_) => const fac_hw.HomeworkPage());
      case facAssignments:
        return MaterialPageRoute(builder: (_) => const fac_assign.AssignmentsPage());
      case facProgressCards:
        return MaterialPageRoute(builder: (_) => const fac_progress.ProgressCardsPage());
      case facTimetable:
        return MaterialPageRoute(builder: (_) => const fac_timetable.TimetablePage());
      case facAnnouncements:
        return MaterialPageRoute(builder: (_) => const fac_ann.AnnouncementsPage());
      case facEvents:
        return MaterialPageRoute(builder: (_) => const fac_event.EventsPage());
      case facHolidays:
        return MaterialPageRoute(builder: (_) => const fac_holiday.HolidaysPage());
      case facNoticeBoard:
        return MaterialPageRoute(builder: (_) => const fac_notice.NoticeBoardPage());
      case facTransport:
        return MaterialPageRoute(builder: (_) => const fac_transport.TransportPage());
      case facStudentPromotion:
        return MaterialPageRoute(builder: (_) => const fac_promo.StudentPromotionPage());
      case facFeeDetails:
        return MaterialPageRoute(builder: (_) => const fac_fee.FeeDetailsPage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
