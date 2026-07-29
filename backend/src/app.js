const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const path = require("path");
const errorHandler = require("./middleware/errorMiddleware");
const verifyToken = require("./middleware/authMiddleware");

const app = express();

// =======================================
// MIDDLEWARE & SECURITY
// =======================================

// Set security HTTP headers
app.use(helmet());

// Configure CORS securely (allow headers and expose authorizations)
app.use(cors({
    origin: "*", // Adjust this to specific domains in production
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"]
}));

// Express built-in body parsers
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Static Serving of Uploaded Assets (PDFs/Images)
app.use("/uploads", express.static(path.join(__dirname, "../uploads")));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Rate Limiter: Max 200 requests per 15 minutes per IP
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200,
    message: {
        success: false,
        message: "Too many requests from this IP, please try again after 15 minutes."
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Apply rate limiter to all API routes
app.use("/api", apiLimiter);

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
const parentRoutes = require("./routes/parentRoutes");
const meetingRoutes = require("./routes/meetingRoutes");
const adminRoutes = require("./routes/adminRoutes");


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

// File Upload Route
const upload = require("./services/uploadService");
app.post("/api/upload", upload.single("file"), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: "No file uploaded" });
    }
    res.status(200).json({
        success: true,
        filePath: `/uploads/${req.file.filename}`,
        fileName: req.file.originalname
    });
});

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
app.use("/api/v1/homework", homeworkRoutes);

app.use("/api/assignments", assignmentRoutes);
app.use("/api/v1/assignments", assignmentRoutes);

app.use("/api/fees", feeRoutes);
app.use("/api/v1/fees", feeRoutes);

app.use("/api/progress-cards", progressCardRoutes);
app.use("/api/v1/progress-cards", progressCardRoutes);

app.use("/api/announcements", announcementRoutes);
app.use("/api/v1/announcements", announcementRoutes);

app.use("/api/events", eventRoutes);
app.use("/api/v1/events", eventRoutes);

app.use("/api/holidays", holidayRoutes);
app.use("/api/v1/holidays", holidayRoutes);

app.use("/api/notice-board", noticeBoardRoutes);
app.use("/api/v1/notice-board", noticeBoardRoutes);

app.use("/api/transport", transportRoutes);
app.use("/api/v1/transport", transportRoutes);

app.use("/api/timetable", timetableRoutes);
app.use("/api/v1/timetable", timetableRoutes);

app.use("/api/parent", parentRoutes);
app.use("/api/v1/parent", parentRoutes);
app.use("/parent", parentRoutes);
app.use("/v1/parent", parentRoutes);
app.use("/api/student", parentRoutes);
app.use("/api/v1/student", parentRoutes);
app.use("/student", parentRoutes);
app.use("/v1/student", parentRoutes);

app.use("/api/meetings", meetingRoutes);
app.use("/api/v1/meetings", meetingRoutes);

app.use("/api/admin", adminRoutes);
app.use("/api/v1/admin", adminRoutes);

// Direct Admin endpoints for guaranteed resolution
const adminController = require("./controllers/adminController");
const roleMiddleware = require("./middleware/roleMiddleware");
app.get("/api/admin/overview", verifyToken, roleMiddleware("ADMIN"), adminController.getAdminOverview);
app.get("/api/v1/admin/overview", verifyToken, roleMiddleware("ADMIN"), adminController.getAdminOverview);
app.get("/api/admin/class-reports", verifyToken, roleMiddleware("ADMIN", "FACULTY"), adminController.getClassReport);
app.get("/api/v1/admin/class-reports", verifyToken, roleMiddleware("ADMIN", "FACULTY"), adminController.getClassReport);
app.get("/api/admin/system-notifications", verifyToken, roleMiddleware("ADMIN"), adminController.getSystemNotifications);
app.get("/api/v1/admin/system-notifications", verifyToken, roleMiddleware("ADMIN"), adminController.getSystemNotifications);

// Direct submission file view and download endpoints
const homeworkController = require("./controllers/homeworkController");
const assignmentController = require("./controllers/assignmentController");

app.get(["/api/homework-submissions/:id/view", "/api/v1/homework-submissions/:id/view"], homeworkController.viewHomeworkSubmission);
app.get(["/api/homework-submissions/:id/download", "/api/v1/homework-submissions/:id/download"], homeworkController.downloadHomeworkSubmission);

app.get(["/api/assignment-submissions/:id/view", "/api/v1/assignment-submissions/:id/view"], assignmentController.viewAssignmentSubmission);
app.get(["/api/assignment-submissions/:id/download", "/api/v1/assignment-submissions/:id/download"], assignmentController.downloadAssignmentSubmission);

const parentController = require("./controllers/parentController");

app.post(["/api/homework/submit", "/api/v1/homework/submit", "/api/parent/homework/submit", "/api/v1/parent/homework/submit"], verifyToken, parentController.submitHomework);
app.delete(["/api/homework/submission/:id", "/api/v1/homework/submission/:id", "/api/homework/submissions/:id", "/api/v1/homework/submissions/:id", "/api/parent/homework/submission/:id", "/api/v1/parent/homework/submission/:id"], verifyToken, parentController.deleteHomeworkSubmission);

app.post(["/api/assignments/submit", "/api/v1/assignments/submit", "/api/parent/assignments/submit", "/api/v1/parent/assignments/submit"], verifyToken, parentController.submitAssignment);
app.delete(["/api/assignments/submission/:id", "/api/v1/assignments/submission/:id", "/api/assignments/submissions/:id", "/api/v1/assignments/submissions/:id", "/api/parent/assignments/submission/:id", "/api/v1/parent/assignments/submission/:id"], verifyToken, parentController.deleteAssignmentSubmission);

// =======================================
// 404 HANDLER
// =======================================

app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        message: "API Route Not Found"
    });
});

// =======================================
// GLOBAL ERROR HANDLER
// =======================================

app.use(errorHandler);

// =======================================
// EXPORT
// =======================================

module.exports = app;