const express = require("express");
const router = express.Router();
const meetingController = require("../controllers/meetingController");
const upload = require("../services/uploadService");

// Create Meeting Announcement (Admin)
router.post("/", upload.single("attachment"), meetingController.createMeetingAnnouncement);

// Get Published Meeting History (Admin & Faculty)
router.get("/history", meetingController.getMeetingHistory);

// Get Faculty Notifications (Faculty Only)
router.get("/faculty/notifications", meetingController.getFacultyNotifications);

// Mark Faculty Notification as Read
router.put("/notifications/:id/read", meetingController.markNotificationAsRead);

// View / Download Attachment
router.get("/attachments/:id/view", meetingController.getMeetingAttachment);
router.get("/attachments/:id/download", meetingController.getMeetingAttachment);

// Delete Meeting Announcement (Admin)
router.delete("/:id", meetingController.deleteMeetingAnnouncement);

module.exports = router;
