const express = require("express");

const router = express.Router();

const attendanceController = require("../controllers/attendanceController");

const verifyToken = require("../middleware/authMiddleware");

const roleMiddleware = require("../middleware/roleMiddleware");


// ==========================================
// MARK ATTENDANCE
// ==========================================

router.post(

    "/mark",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.markAttendance

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
// GET ATTENDANCE BY STUDENT
// ==========================================

router.get(

    "/student/:studentId",

    verifyToken,

    attendanceController.getAttendanceByStudent

);


// ==========================================
// UPDATE ATTENDANCE
// ==========================================

router.put(

    "/update/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.updateAttendance

);


// ==========================================
// DELETE ATTENDANCE
// ==========================================

router.delete(

    "/delete/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    attendanceController.deleteAttendance

);

module.exports = router;