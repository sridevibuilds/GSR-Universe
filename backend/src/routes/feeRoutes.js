const express = require("express");

const router = express.Router();

const feeController = require("../controllers/feeController");

router.post("/", feeController.createFee);

router.get("/", feeController.getAllFees);

router.get("/:id", feeController.getFeeById);

router.put("/:id", feeController.updateFee);

router.delete("/:id", feeController.deleteFee);

module.exports = router;