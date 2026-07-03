const express = require("express");
const router = express.Router();

const assessmentController = require("../controllers/assessmentController");

// Create Assessment
router.post("/", assessmentController.createAssessment);

// Get All Assessments
router.get("/", assessmentController.getAllAssessments);

// Get Assessment By ID
router.get("/:id", assessmentController.getAssessmentById);

// Update Assessment
router.put("/:id", assessmentController.updateAssessment);

// Delete Assessment
router.delete("/:id", assessmentController.deleteAssessment);

module.exports = router;