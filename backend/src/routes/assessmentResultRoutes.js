const express = require("express");
const router = express.Router();

const assessmentResultController = require("../controllers/assessmentResultController");

// Create Assessment Result
router.post("/", assessmentResultController.createAssessmentResult);

// Get All Assessment Results
router.get("/", assessmentResultController.getAllAssessmentResults);

// Get Assessment Result By ID
router.get("/:id", assessmentResultController.getAssessmentResultById);

// Update Assessment Result
router.put("/:id", assessmentResultController.updateAssessmentResult);

// Delete Assessment Result
router.delete("/:id", assessmentResultController.deleteAssessmentResult);

module.exports = router;