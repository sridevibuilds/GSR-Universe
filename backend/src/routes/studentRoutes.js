const express = require("express");

const router = express.Router();

const studentController = require("../controllers/studentController");

const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");


// ==========================================
// CREATE STUDENT
// ==========================================

router.post(

    "/create",

    verifyToken,

    roleMiddleware("FACULTY"),

    studentController.createStudent

);


// ==========================================
// GET ALL STUDENTS
// ==========================================

router.get(

    "/all",

    verifyToken,

    roleMiddleware("FACULTY"),

    studentController.getAllStudents

);


// ==========================================
// GET STUDENT BY ID
// ==========================================

router.get(

    "/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    studentController.getStudentById

);


// ==========================================
// UPDATE STUDENT
// ==========================================

router.put(

    "/update/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    studentController.updateStudent

);


// ==========================================
// DELETE STUDENT
// ==========================================

router.delete(

    "/delete/:id",

    verifyToken,

    roleMiddleware("FACULTY"),

    studentController.deleteStudent

);


module.exports = router;