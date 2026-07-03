const express = require("express");

const router = express.Router();

const progressCardController = require("../controllers/progressCardController");

router.post("/", progressCardController.createProgressCard);

router.get("/", progressCardController.getAllProgressCards);

router.get("/:id", progressCardController.getProgressCardById);

router.put("/:id", progressCardController.updateProgressCard);

router.delete("/:id", progressCardController.deleteProgressCard);

module.exports = router;