const express = require("express");

const router = express.Router();

const timetableController = require("../controllers/timetableController");

router.post("/", timetableController.createTimetable);

router.get("/", timetableController.getAllTimetables);

router.get("/:id", timetableController.getTimetableById);

router.put("/:id", timetableController.updateTimetable);

router.delete("/:id", timetableController.deleteTimetable);

module.exports = router;