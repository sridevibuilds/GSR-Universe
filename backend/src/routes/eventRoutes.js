// Module 9 Route Security - Event Routes

const express = require("express");
const router = express.Router();
const eventController = require("../controllers/eventController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), eventController.createEvent);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), eventController.updateEvent);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), eventController.deleteEvent);

// Fetching allowed for all authenticated users
router.get("/", eventController.getAllEvents);
router.get("/:id", eventController.getEventById);

module.exports = router;