// Module 8 Automated Fee Reminders - Fee Routes

const express = require("express");
const router = express.Router();
const feeController = require("../controllers/feeController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally on all fee routes
router.use(verifyToken);

// ==========================================
// ADMIN REMINDER VOICE CALL CONFIGS & REPORTS
// ==========================================

router.get(
    "/calls/settings",
    roleMiddleware("ADMIN"),
    feeController.getCallSettings
);

router.put(
    "/calls/settings",
    roleMiddleware("ADMIN"),
    feeController.updateCallSettings
);

router.get(
    "/calls/history",
    roleMiddleware("ADMIN"),
    feeController.getCallHistory
);

router.post(
    "/calls/trigger",
    roleMiddleware("ADMIN"),
    feeController.triggerManualFeeReminders
);

router.get(
    "/reports/pending",
    roleMiddleware("ADMIN", "FACULTY"),
    feeController.getPendingFeeReport
);

// ==========================================
// STANDARD FEE CRUD (Faculty & Admin)
// ==========================================

router.get(
    "/",
    roleMiddleware("ADMIN", "FACULTY"),
    feeController.getAllFees
);

router.get(
    "/:id",
    roleMiddleware("ADMIN", "FACULTY"),
    feeController.getFeeById
);

router.post(
    "/",
    roleMiddleware("ADMIN", "FACULTY"),
    feeController.createFee
);

router.put(
    "/:id",
    roleMiddleware("ADMIN", "FACULTY"),
    feeController.updateFee
);

router.delete(
    "/:id",
    roleMiddleware("ADMIN"),
    feeController.deleteFee
);

router.put(
    "/by-mapping/:scmId",
    roleMiddleware("ADMIN", "FACULTY"),
    feeController.updateFeeByMapping
);

module.exports = router;