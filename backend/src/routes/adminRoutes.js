const express = require("express");
const router = express.Router();
const adminController = require("../controllers/adminController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Public admin routes
router.post("/login", adminController.adminLogin);

// Protected admin routes
router.get("/overview", verifyToken, roleMiddleware("ADMIN"), adminController.getAdminOverview);
router.get("/class-reports", verifyToken, roleMiddleware("ADMIN", "FACULTY"), adminController.getClassReport);
router.get("/system-notifications", verifyToken, roleMiddleware("ADMIN"), adminController.getSystemNotifications);

module.exports = router;