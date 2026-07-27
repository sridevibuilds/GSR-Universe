// Module 9 Route Security - Timetable Routes

const express = require("express");
const router = express.Router();
const timetableController = require("../controllers/timetableController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), timetableController.createTimetable);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), timetableController.updateTimetable);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), timetableController.deleteTimetable);

// Fetching allowed for all authenticated users
router.get("/", timetableController.getAllTimetables);
router.get("/:id", timetableController.getTimetableById);

module.exports = router;