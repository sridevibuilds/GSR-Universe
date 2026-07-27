// Module 9 Route Security - Holiday Routes

const express = require("express");
const router = express.Router();
const holidayController = require("../controllers/holidayController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), holidayController.createHoliday);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), holidayController.updateHoliday);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), holidayController.deleteHoliday);

// Fetching allowed for all authenticated users
router.get("/", holidayController.getAllHolidays);
router.get("/:id", holidayController.getHolidayById);

module.exports = router;