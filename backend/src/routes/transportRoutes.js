// Module 9 Route Security - Transport Routes

const express = require("express");
const router = express.Router();
const transportController = require("../controllers/transportController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), transportController.createTransport);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), transportController.updateTransport);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), transportController.deleteTransport);

// Fetching allowed for all authenticated users
router.get("/", transportController.getAllTransport);
router.get("/:id", transportController.getTransportById);

module.exports = router;