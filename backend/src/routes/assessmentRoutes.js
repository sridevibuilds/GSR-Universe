// Module 9 Route Security - Assessment Routes

const express = require("express");
const router = express.Router();
const assessmentController = require("../controllers/assessmentController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), assessmentController.createAssessment);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), assessmentController.updateAssessment);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), assessmentController.deleteAssessment);

// Fetching allowed for all authenticated users
router.get("/", assessmentController.getAllAssessments);
router.get("/:id", assessmentController.getAssessmentById);

module.exports = router;