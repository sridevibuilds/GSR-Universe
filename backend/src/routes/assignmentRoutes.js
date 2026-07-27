// Module 9 Route Security - Assignment Routes

const express = require("express");
const router = express.Router();
const assignmentController = require("../controllers/assignmentController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete, Grade restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), assignmentController.createAssignment);
router.post("/grade", roleMiddleware("FACULTY", "ADMIN"), assignmentController.gradeAssignmentSubmission);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), assignmentController.updateAssignment);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), assignmentController.deleteAssignment);

// Fetching allowed for all authenticated users
router.get("/", assignmentController.getAllAssignments);
router.get("/submissions/list", roleMiddleware("FACULTY", "ADMIN"), assignmentController.getAssignmentSubmissions);
router.get("/:assignment_id/submissions", roleMiddleware("FACULTY", "ADMIN"), assignmentController.getAssignmentSubmissions);
router.get("/submissions/:id/view", roleMiddleware("FACULTY", "ADMIN"), assignmentController.viewAssignmentSubmission);
router.get("/submissions/:id/download", roleMiddleware("FACULTY", "ADMIN"), assignmentController.downloadAssignmentSubmission);
router.get("/:id", assignmentController.getAssignmentById);

module.exports = router;