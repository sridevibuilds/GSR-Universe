const express = require("express");

const router = express.Router();

const facultyController = require("../controllers/facultyController");

const verifyToken = require("../middleware/authMiddleware");

const roleMiddleware = require("../middleware/roleMiddleware");

// ==========================================
// CREATE FACULTY
// ==========================================

router.post(

    "/create",

    verifyToken,

    roleMiddleware("ADMIN"),

    facultyController.createFaculty

);

// ==========================================
// GET ALL FACULTY
// ==========================================

router.get(

    "/",

    verifyToken,

    roleMiddleware("ADMIN"),

    facultyController.getAllFaculty

);
// ==========================================
// FACULTY PROFILE
// ==========================================

router.get(

    "/profile",

    verifyToken,

    facultyController.getFacultyProfile

);

// ==========================================
// GET FACULTY BY ID
// ==========================================

router.get(

    "/:id",

    verifyToken,

    roleMiddleware("ADMIN"),

    facultyController.getFacultyById

);

// ==========================================
// UPDATE FACULTY
// ==========================================

router.put(

    "/:id",

    verifyToken,

    roleMiddleware("ADMIN"),

    facultyController.updateFaculty

);
// ==========================================
// DELETE FACULTY
// ==========================================

router.delete(

    "/:id",

    verifyToken,

    roleMiddleware("ADMIN"),

    facultyController.deleteFaculty

);

// ==========================================
// EXPORT
// ==========================================

module.exports = router;