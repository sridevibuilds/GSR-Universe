// Module 9 Route Security - Assessment Result Routes

const express = require("express");
const router = express.Router();
const assessmentResultController = require("../controllers/assessmentResultController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), assessmentResultController.createAssessmentResult);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), assessmentResultController.updateAssessmentResult);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), assessmentResultController.deleteAssessmentResult);

// Fetching allowed for all authenticated users
router.get("/", assessmentResultController.getAllAssessmentResults);
router.get("/:id", assessmentResultController.getAssessmentResultById);

module.exports = router;