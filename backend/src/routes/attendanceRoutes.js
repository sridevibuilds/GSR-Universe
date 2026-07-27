const express = require("express");

const router = express.Router();

const attendanceController = require("../controllers/attendanceController");

const verifyToken = require("../middleware/authMiddleware");

const roleMiddleware = require("../middleware/roleMiddleware");


// ==========================================
// MARK & SCAN ATTENDANCE
// ==========================================

router.post(

    "/mark",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.markAttendance

);

router.post(

    "/scan",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.scanBarcodeAttendance

);


// ==========================================
// GET ALL ATTENDANCE
// ==========================================

router.get(

    "/all",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.getAllAttendance

);


// ==========================================
// GET ATTENDANCE BY STUDENT (Raw list)
// ==========================================

router.get(

    "/student/:studentId",

    verifyToken,

    attendanceController.getAttendanceByStudent

);


// ==========================================
// REPORTS & ANALYTICS (Class & Student Summaries)
// ==========================================

router.get(

    "/report/class/:classId",

    verifyToken,

    roleMiddleware("FACULTY", "ADMIN"),

    attendanceController.getClassAttendanceReport

);

router.get(

    "/report/student/:studentId",

    verifyToken,

    attendanceController.getStudentAttendanceSummary

);


// ==========================================
// UPDATE & DELETE ATTENDANCE
// ==========================================

router.put(

    "/update/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.updateAttendance

);

router.delete(

    "/delete/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.deleteAttendance

);


module.exports = router;