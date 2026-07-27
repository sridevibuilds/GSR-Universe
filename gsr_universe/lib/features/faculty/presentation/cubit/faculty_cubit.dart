// Presentation Controller Layer - Faculty Cubit State Manager
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/faculty_repository.dart';
import 'faculty_state.dart';
import '../../../../core/errors/exceptions.dart';

class FacultyCubit extends Cubit<FacultyState> {
  final FacultyRepository facultyRepository;

  FacultyCubit(this.facultyRepository) : super(const FacultyState());

  /// Load complete list of registered students
  Future<void> fetchStudents() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getAllStudents();
      emit(state.copyWith(isLoading: false, studentsList: list));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to load students roster."));
    }
  }

  /// Create student record
  Future<void> addStudent(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createStudent(payload);
      final list = await facultyRepository.getAllStudents();
      emit(state.copyWith(
        isLoading: false,
        studentsList: list,
        successMessage: "Student created successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to create student."));
    }
  }

  /// Update student details
  Future<void> editStudent(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateStudent(id, payload);
      final list = await facultyRepository.getAllStudents();
      emit(state.copyWith(
        isLoading: false,
        studentsList: list,
        successMessage: "Student details updated successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update student details."));
    }
  }

  /// Delete student profile
  Future<void> removeStudent(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteStudent(id);
      final list = await facultyRepository.getAllStudents();
      emit(state.copyWith(
        isLoading: false,
        studentsList: list,
        successMessage: "Student profile deleted successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete student."));
    }
  }

  /// Scan student attendance (Legacy/Device verification fallback)
  Future<void> scanStudentAttendance(String barcode, {String session = "Morning"}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = {
        "barcode": barcode,
        "session": session,
        "period_number": 1,
        "subject": "Daily Attendance",
      };
      final res = await facultyRepository.scanAttendance(payload);
      final scannedInfo = Map<String, dynamic>.from(res['data'] ?? {});
      final updatedScanned = List<Map<String, dynamic>>.from(state.scannedStudents);
      
      if (!updatedScanned.any((s) => s['id'] == scannedInfo['id'])) {
        updatedScanned.insert(0, {
          'id': scannedInfo['student_id'] ?? scannedInfo['id'] ?? 0,
          'student_name': scannedInfo['student_name'] ?? 'Student Profile',
          'admission_no': barcode,
          'scanned_at': DateTime.now().toIso8601String(),
        });
      }

      emit(state.copyWith(
        isLoading: false,
        scannedStudents: updatedScanned,
        successMessage: "Attendance recorded for ${scannedInfo['student_name'] ?? barcode}.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Attendance scan processing failed."));
    }
  }

  /// Fetch class-wise attendance report details
  Future<void> fetchClassAttendanceReport(int classId, {String? date}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final report = await facultyRepository.getClassAttendanceReport(classId, date: date);
      emit(state.copyWith(isLoading: false, classAttendanceReport: report));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message, classAttendanceReport: const {}));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to retrieve class attendance report.", classAttendanceReport: const {}));
    }
  }

  /// Bulk promote selected students
  Future<void> promoteClassStudents({
    required int currentYearId,
    required int destinationYearId,
    required int currentClassId,
    int? destinationClassId,
    String? destinationClassName,
    String? destinationSection,
    required List<int> studentIds,
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = {
        "current_academic_year_id": currentYearId,
        "destination_academic_year_id": destinationYearId,
        "current_class_id": currentClassId,
        "destination_class_id": destinationClassId,
        "destination_class_name": destinationClassName,
        "destination_section": destinationSection,
        "student_ids": studentIds,
      };
      await facultyRepository.promoteStudents(payload);
      final list = await facultyRepository.getAllStudents();
      emit(state.copyWith(
        isLoading: false,
        studentsList: list,
        successMessage: "Successfully promoted ${studentIds.length} students to the destination class.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to promote students."));
    }
  }

  /// Create a new academic year term
  Future<void> addAcademicYear(String yearName) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = {
        "year_name": yearName,
      };
      await facultyRepository.createAcademicYear(payload);
      final list = await facultyRepository.getAllStudents();
      emit(state.copyWith(
        isLoading: false,
        studentsList: list,
        successMessage: "Academic Year $yearName created successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to create academic year."));
    }
  }

  /// Load list of active assessments
  Future<void> fetchAssessments() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getAssessments();
      emit(state.copyWith(isLoading: false, assessmentsList: list));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to load assessment schedules."));
    }
  }

  /// Create assessment schedule
  Future<void> addAssessment(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createAssessment(payload);
      final list = await facultyRepository.getAssessments();
      emit(state.copyWith(
        isLoading: false,
        assessmentsList: list,
        successMessage: "Assessment published successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to schedule assessment."));
    }
  }

  /// Update assessment details
  Future<void> editAssessment(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateAssessment(id, payload);
      final list = await facultyRepository.getAssessments();
      emit(state.copyWith(
        isLoading: false,
        assessmentsList: list,
        successMessage: "Assessment updated successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update assessment."));
    }
  }

  /// Delete assessment details
  Future<void> removeAssessment(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteAssessment(id);
      final list = await facultyRepository.getAssessments();
      emit(state.copyWith(
        isLoading: false,
        assessmentsList: list,
        successMessage: "Assessment deleted successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete assessment."));
    }
  }

  /// Upload assessment score for a specific mapping
  Future<void> submitStudentMarks({
    required int assessmentId,
    required int scmId,
    required double marks,
    String remarks = "Good",
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = {
        "assessment_id": assessmentId,
        "student_class_mapping_id": scmId,
        "marks_obtained": marks,
        "remarks": remarks,
      };
      await facultyRepository.submitMarks(payload);
      emit(state.copyWith(
        isLoading: false,
        successMessage: "Assessment score uploaded successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to upload marks."));
    }
  }

  /// Upload attachment file (PDF/Image) to backend uploads storage
  Future<void> uploadHomeworkAttachment(File file) async {
    emit(state.copyWith(isLoading: true));
    try {
      final res = await facultyRepository.uploadFile(file);
      emit(state.copyWith(
        isLoading: false,
        uploadedFileUrl: res['filePath'],
        uploadedFileName: res['fileName'],
        successMessage: "Attachment uploaded successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Attachment upload failed."));
    }
  }

  /// Publish homework assignment
  Future<void> publishHomework({
    required String className,
    required String section,
    required String subjectName,
    required int yearId,
    required String title,
    required String description,
    required String dueDate,
    required int facultyId,
    String status = "Published",
  }) async {
    emit(state.copyWith(isLoading: true));
    try {
      final payload = {
        "class_name": className,
        "section": section,
        "subject_name": subjectName,
        "academic_year_id": yearId,
        "title": title,
        "description": description,
        "due_date": dueDate,
        "attachment_name": state.uploadedFileName ?? "",
        "attachment_path": state.uploadedFileUrl ?? "",
        "created_by": facultyId,
        "status": status,
      };
      await facultyRepository.createHomework(payload);
      final homework = await facultyRepository.getHomework();
      emit(state.copyWith(
        isLoading: false,
        homeworkList: homework,
        uploadedFileUrl: null,
        uploadedFileName: null,
        successMessage: "Homework assigned successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to publish homework."));
    }
  }

  /// Delete homework assignment
  Future<void> removeHomework(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteHomework(id);
      final homework = await facultyRepository.getHomework();
      emit(state.copyWith(
        isLoading: false,
        homeworkList: homework,
        successMessage: "Homework deleted successfully.",
      ));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete homework."));
    }
  }

  /// Load published homework entries log
  Future<void> fetchHomework() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getHomework();
      emit(state.copyWith(isLoading: false, homeworkList: list));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to retrieve homework log."));
    }
  }

  Future<void> fetchHomeworkSubmissions({String? className, String? section, int? homeworkId}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getHomeworkSubmissions(className: className, section: section, homeworkId: homeworkId);
      emit(state.copyWith(isLoading: false, homeworkSubmissions: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false, homeworkSubmissions: []));
    }
  }

  // --- Phase 2 Actions ---

  Future<void> fetchAssignments() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getAssignments();
      emit(state.copyWith(isLoading: false, assignmentsList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<bool> gradeAssignment(Map<String, dynamic> payload) async {
    try {
      await facultyRepository.gradeAssignment(payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> publishAssignment(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createAssignment(payload);
      final list = await facultyRepository.getAssignments();
      emit(state.copyWith(isLoading: false, assignmentsList: list, successMessage: "Assignment published successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to publish assignment."));
    }
  }

  Future<void> editAssignment(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateAssignment(id, payload);
      final list = await facultyRepository.getAssignments();
      emit(state.copyWith(isLoading: false, assignmentsList: list, successMessage: "Assignment updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update assignment."));
    }
  }

  Future<void> removeAssignment(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteAssignment(id);
      final list = await facultyRepository.getAssignments();
      emit(state.copyWith(isLoading: false, assignmentsList: list, successMessage: "Assignment deleted successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete assignment."));
    }
  }

  Future<void> fetchAssignmentSubmissions({String? className, String? section, int? assignmentId}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getAssignmentSubmissions(className: className, section: section, assignmentId: assignmentId);
      emit(state.copyWith(isLoading: false, assignmentSubmissions: list));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to load submission report."));
    }
  }

  Future<void> fetchProgressCards() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getProgressCards();
      emit(state.copyWith(isLoading: false, progressCardsList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> uploadProgressCard(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createProgressCard(payload);
      final list = await facultyRepository.getProgressCards();
      emit(state.copyWith(isLoading: false, progressCardsList: list, successMessage: "Progress card uploaded successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to upload progress card."));
    }
  }

  Future<void> removeProgressCard(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteProgressCard(id);
      final list = await facultyRepository.getProgressCards();
      emit(state.copyWith(isLoading: false, progressCardsList: list, successMessage: "Progress card removed successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete progress card."));
    }
  }

  Future<void> fetchTimetables() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getTimetables();
      emit(state.copyWith(isLoading: false, timetableList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> uploadTimetable(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createTimetable(payload);
      final list = await facultyRepository.getTimetables();
      emit(state.copyWith(isLoading: false, timetableList: list, successMessage: "Timetable uploaded successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to upload timetable."));
    }
  }

  Future<void> removeTimetable(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteTimetable(id);
      final list = await facultyRepository.getTimetables();
      emit(state.copyWith(isLoading: false, timetableList: list, successMessage: "Timetable deleted successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete timetable."));
    }
  }

  // --- Phase 3 Actions ---

  Future<void> fetchAnnouncements() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getAnnouncements();
      emit(state.copyWith(isLoading: false, announcementsList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> publishAnnouncement(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createAnnouncement(payload);
      final list = await facultyRepository.getAnnouncements();
      emit(state.copyWith(isLoading: false, announcementsList: list, successMessage: "Announcement published successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to publish announcement."));
    }
  }

  Future<void> editAnnouncement(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateAnnouncement(id, payload);
      final list = await facultyRepository.getAnnouncements();
      emit(state.copyWith(isLoading: false, announcementsList: list, successMessage: "Announcement updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update announcement."));
    }
  }

  Future<void> removeAnnouncement(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteAnnouncement(id);
      final list = await facultyRepository.getAnnouncements();
      emit(state.copyWith(isLoading: false, announcementsList: list, successMessage: "Announcement deleted successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete announcement."));
    }
  }

  Future<void> fetchEvents() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getEvents();
      emit(state.copyWith(isLoading: false, eventsList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> publishEvent(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createEvent(payload);
      final list = await facultyRepository.getEvents();
      emit(state.copyWith(isLoading: false, eventsList: list, successMessage: "Event scheduled successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to schedule event."));
    }
  }

  Future<void> editEvent(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateEvent(id, payload);
      final list = await facultyRepository.getEvents();
      emit(state.copyWith(isLoading: false, eventsList: list, successMessage: "Event updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update event."));
    }
  }

  Future<void> removeEvent(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteEvent(id);
      final list = await facultyRepository.getEvents();
      emit(state.copyWith(isLoading: false, eventsList: list, successMessage: "Event deleted successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete event."));
    }
  }

  Future<void> fetchHolidays() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getHolidays();
      emit(state.copyWith(isLoading: false, holidaysList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> publishHoliday(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createHoliday(payload);
      final list = await facultyRepository.getHolidays();
      emit(state.copyWith(isLoading: false, holidaysList: list, successMessage: "Holiday created successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to create holiday."));
    }
  }

  Future<void> editHoliday(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateHoliday(id, payload);
      final list = await facultyRepository.getHolidays();
      emit(state.copyWith(isLoading: false, holidaysList: list, successMessage: "Holiday updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update holiday."));
    }
  }

  Future<void> removeHoliday(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteHoliday(id);
      final list = await facultyRepository.getHolidays();
      emit(state.copyWith(isLoading: false, holidaysList: list, successMessage: "Holiday deleted successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete holiday."));
    }
  }

  Future<void> fetchNotices() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getNotices();
      emit(state.copyWith(isLoading: false, noticesList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> publishNotice(Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.createNotice(payload);
      final list = await facultyRepository.getNotices();
      emit(state.copyWith(isLoading: false, noticesList: list, successMessage: "Notice board updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update notice board."));
    }
  }

  Future<void> editNotice(int id, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateNotice(id, payload);
      final list = await facultyRepository.getNotices();
      emit(state.copyWith(isLoading: false, noticesList: list, successMessage: "Notice updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update notice."));
    }
  }

  Future<void> removeNotice(int id) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.deleteNotice(id);
      final list = await facultyRepository.getNotices();
      emit(state.copyWith(isLoading: false, noticesList: list, successMessage: "Notice deleted successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to delete notice."));
    }
  }

  Future<void> fetchTransport() async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getTransport();
      emit(state.copyWith(isLoading: false, transportList: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> fetchFeeDetails({String? className, String? section}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await facultyRepository.getFeeDetails(className: className, section: section);
      emit(state.copyWith(isLoading: false, feeRecords: list));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> updateStudentFee(int scmId, Map<String, dynamic> payload) async {
    emit(state.copyWith(isLoading: true));
    try {
      await facultyRepository.updateFeeByMapping(scmId, payload);
      final list = await facultyRepository.getFeeDetails();
      final students = await facultyRepository.getAllStudents();
      emit(state.copyWith(isLoading: false, feeRecords: list, studentsList: students, successMessage: "Fee details updated successfully."));
    } on ServerException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: "Failed to update student fee."));
    }
  }

  /// Clear file upload path cached details
  void clearUploads() {
    emit(state.copyWith(uploadedFileUrl: null, uploadedFileName: null));
  }

  /// Clear messages to prevent toast triggers
  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  /// Fetch meeting notifications for Faculty
  Future<void> fetchFacultyMeetingNotifications() async {
    try {
      final res = await facultyRepository.getFacultyMeetingNotifications();
      final List<dynamic> data = res['data'] ?? [];
      final int unreadCount = res['unread_count'] ?? 0;

      final List<Map<String, dynamic>> rawList = data.map((e) => Map<String, dynamic>.from(e)).toList();
      final Map<int, Map<String, dynamic>> uniqueMap = {};
      for (final item in rawList) {
        final int meetingId = item['meeting_id'] ?? item['notification_id'] ?? 0;
        if (!uniqueMap.containsKey(meetingId)) {
          uniqueMap[meetingId] = item;
        }
      }

      emit(state.copyWith(
        meetingNotifications: uniqueMap.values.toList(),
        unreadMeetingCount: unreadCount,
      ));
    } catch (_) {
      // Silent error handling for background notification sweeps
    }
  }

  /// Mark specific meeting notification as read
  Future<void> markMeetingNotificationAsRead(int notificationId) async {
    try {
      await facultyRepository.markMeetingNotificationAsRead(notificationId);
      await fetchFacultyMeetingNotifications();
    } catch (_) {}
  }
}
