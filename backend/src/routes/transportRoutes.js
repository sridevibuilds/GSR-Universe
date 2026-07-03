const express = require("express");

const router = express.Router();

const transportController = require("../controllers/transportController");

router.post("/", transportController.createTransport);

router.get("/", transportController.getAllTransport);

router.get("/:id", transportController.getTransportById);

router.put("/:id", transportController.updateTransport);

router.delete("/:id", transportController.deleteTransport);

module.exports = router;