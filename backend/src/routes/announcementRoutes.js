// Module 9 Route Security - Announcement Routes

const express = require("express");
const router = express.Router();
const announcementController = require("../controllers/announcementController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), announcementController.createAnnouncement);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), announcementController.updateAnnouncement);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), announcementController.deleteAnnouncement);

// Fetching allowed for all authenticated users
router.get("/", announcementController.getAllAnnouncements);
router.get("/:id", announcementController.getAnnouncementById);

module.exports = router;