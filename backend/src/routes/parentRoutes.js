// Module 7 Parent Dashboard - Parent Routes

const express = require("express");
const router = express.Router();
const parentController = require("../controllers/parentController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification and PARENT / STUDENT role check globally for all routes in this file
router.use(verifyToken);
router.use(roleMiddleware("PARENT", "STUDENT", "ADMIN"));

// Parent Dashboard
router.get("/dashboard", parentController.getDashboard);

// Parent Profile Details
router.get("/profile", parentController.getProfile);

// Read-only Attendance logs
router.get("/attendance", parentController.getAttendance);

// Exam Marks
router.get("/marks", parentController.getMarks);

// Homework & Submissions
router.get("/homework", parentController.getHomework);
router.post("/homework/submit", parentController.submitHomework);
router.post("/homework/submissions/submit", parentController.submitHomework);
router.delete("/homework/submission/:id", parentController.deleteHomeworkSubmission);
router.delete("/homework/submissions/:id", parentController.deleteHomeworkSubmission);

// Assignments & Submissions
router.get("/assignments", parentController.getAssignments);
router.get("/assignment-marks", parentController.getAssignmentMarks);
router.post("/assignments/submit", parentController.submitAssignment);
router.post("/assignments/submissions/submit", parentController.submitAssignment);
router.delete("/assignments/submission/:id", parentController.deleteAssignmentSubmission);
router.delete("/assignments/submissions/:id", parentController.deleteAssignmentSubmission);

// Invoice list and Dues
router.get("/fees", parentController.getFees);

// Class Timetable
router.get("/timetable", parentController.getTimetable);

// System Announcements
router.get("/announcements", parentController.getAnnouncements);

// Upcoming Events
router.get("/events", parentController.getEvents);

// Holiday Announcements
router.get("/holidays", parentController.getHolidays);

// Downloadable Progress Card
router.get("/progress-card", parentController.getProgressCard);

// Notice Board
router.get("/notice-board", parentController.getNoticeBoard);

// Transport Details
router.get("/transport", parentController.getTransport);

// Parent Notifications
router.get("/notifications", parentController.getParentNotifications);
router.put("/notifications/:id/read", parentController.markParentNotificationAsRead);

module.exports = router;