// Module 9 Route Security - Notice Board Routes

const express = require("express");
const router = express.Router();
const noticeBoardController = require("../controllers/noticeBoardController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), noticeBoardController.createNotice);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), noticeBoardController.updateNotice);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), noticeBoardController.deleteNotice);

// Fetching allowed for all authenticated users
router.get("/", noticeBoardController.getAllNotices);
router.get("/:id", noticeBoardController.getNoticeById);

module.exports = router;