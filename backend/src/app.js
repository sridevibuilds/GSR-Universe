const express = require("express");
const cors = require("cors");

const app = express();

// =======================================
// MIDDLEWARE
// =======================================

app.use(cors());
app.use(express.json());

// =======================================
// ROUTE IMPORTS
// =======================================

const authRoutes = require("./routes/authRoutes");
const facultyRoutes = require("./routes/facultyRoutes");
const studentRoutes = require("./routes/studentRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
const assessmentRoutes = require("./routes/assessmentRoutes");
const assessmentResultRoutes = require("./routes/assessmentResultRoutes");
const homeworkRoutes = require("./routes/homeworkRoutes");
const assignmentRoutes=require("./routes/assignmentRoutes");
const feeRoutes = require("./routes/feeRoutes");
const progressCardRoutes = require("./routes/progressCardRoutes");
const announcementRoutes = require("./routes/announcementRoutes");
const eventRoutes = require("./routes/eventRoutes");
const holidayRoutes = require("./routes/holidayRoutes");
const noticeBoardRoutes = require("./routes/noticeBoardRoutes");
const transportRoutes = require("./routes/transportRoutes");
const timetableRoutes = require("./routes/timetableRoutes");


// =======================================
// HOME ROUTE
// =======================================

app.get("/", (req, res) => {
    res.send("🚀 GSR Universe Backend Running");
});

// =======================================
// API ROUTES
// =======================================

console.log("authRoutes:", typeof authRoutes);
console.log("facultyRoutes:", typeof facultyRoutes);
console.log("studentRoutes:", typeof studentRoutes);
console.log("attendanceRoutes:", typeof attendanceRoutes);
console.log("assessmentRoutes:", typeof assessmentRoutes);

// Authentication
app.use("/api/auth", authRoutes);

// Faculty
app.use("/api/faculty", facultyRoutes);

// Students
app.use("/api/students", studentRoutes);

// Attendance
app.use("/api/attendance", attendanceRoutes);

app.use("/api/assessments", assessmentRoutes);

app.use("/api/assessment-results", assessmentResultRoutes);

app.use("/api/homework", homeworkRoutes);

app.use("/api/assignments",assignmentRoutes);

app.use("/api/fees", feeRoutes);

app.use("/api/progress-cards", progressCardRoutes);

app.use("/api/announcements", announcementRoutes);

app.use("/api/events", eventRoutes);

app.use("/api/holidays", holidayRoutes);

app.use("/api/notice-board", noticeBoardRoutes);

app.use("/api/transport", transportRoutes);

app.use("/api/timetable", timetableRoutes);

// =======================================
// 404 HANDLER
// =======================================

app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: "API Route Not Found"
    });
});

// =======================================
// EXPORT
// =======================================

module.exports = app;