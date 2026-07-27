// Module 9 Route Security - Progress Card Routes

const express = require("express");
const router = express.Router();
const progressCardController = require("../controllers/progressCardController");
const verifyToken = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// Enforce token verification globally
router.use(verifyToken);

// Create, Update, Delete restricted to Faculty and Admin
router.post("/", roleMiddleware("FACULTY", "ADMIN"), progressCardController.createProgressCard);
router.put("/:id", roleMiddleware("FACULTY", "ADMIN"), progressCardController.updateProgressCard);
router.delete("/:id", roleMiddleware("FACULTY", "ADMIN"), progressCardController.deleteProgressCard);

// Fetching allowed for all authenticated users
router.get("/", progressCardController.getAllProgressCards);
router.get("/:id", progressCardController.getProgressCardById);

module.exports = router;