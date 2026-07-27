// Module 9 Route Security - Homework Routes

const express = require("express");
const router = express.Router();
const homeworkController = require("../controllers/homeworkController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), homeworkController.createHomework);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), homeworkController.updateHomework);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), homeworkController.deleteHomework);

// Fetching allowed for all authenticated users (Faculty, Parents, etc.)
router.get("/", homeworkController.getAllHomework);
router.get("/submissions/list", roleMiddleware("FACULTY", "ADMIN"), homeworkController.getHomeworkSubmissions);
router.get("/:homework_id/submissions", roleMiddleware("FACULTY", "ADMIN"), homeworkController.getHomeworkSubmissions);
router.get("/submissions/:id/view", roleMiddleware("FACULTY", "ADMIN"), homeworkController.viewHomeworkSubmission);
router.get("/submissions/:id/download", roleMiddleware("FACULTY", "ADMIN"), homeworkController.downloadHomeworkSubmission);
router.get("/:id", homeworkController.getHomeworkById);

module.exports = router;