// Module 5 Barcode Attendance & QR Scan - Attendance Controller

const db = require("../config/db");
const Joi = require("joi");

// Input validation schemas
const scanAttendanceSchema = Joi.object({
    barcode: Joi.string().trim().required(), // maps to students.admission_no
    session: Joi.string().valid("Morning", "Afternoon").default("Morning"),
    period_number: Joi.number().integer().default(1),
    subject: Joi.string().trim().default("Daily Attendance")
});

// ==========================================
// SCAN BARCODE ATTENDANCE
// ==========================================
const scanBarcodeAttendance = async (req, res, next) => {
    try {
        const { error, value } = scanAttendanceSchema.validate(req.body, { stripUnknown: true });
        if (error) {
            return res.status(400).json({
                success: false,
                message: `Validation Error: ${error.details.map(d => d.message).join(", ")}`
            });
        }

        const { barcode, session, period_number, subject } = value;
        const faculty_id = req.user.id; // Scanned by authenticated faculty member

        // 1. Find student by barcode (admission_no)
        const studentResult = await db.query(
            "SELECT id, student_name, admission_no FROM public.students WHERE admission_no = $1",
            [barcode]
        );

        if (studentResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: `Student with barcode '${barcode}' not found.`
            });
        }

        const student = studentResult.rows[0];

        // 2. Find active student-class mapping
        const mappingResult = await db.query(
            `SELECT id, class_id FROM public.student_class_mapping 
             WHERE student_id = $1 AND is_current = true`,
            [student.id]
        );

        if (mappingResult.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Student is registered but has no current active class mapping."
            });
        }

        const mapping = mappingResult.rows[0];
        const student_class_mapping_id = mapping.id;
        const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD local format

        // 3. Check if attendance has already been scanned/marked for this session today
        const alreadyMarked = await db.query(
            `SELECT id, status FROM public.attendance
             WHERE student_class_mapping_id = $1 
               AND attendance_date = $2 
               AND session = $3`,
            [student_class_mapping_id, today, session]
        );

        if (alreadyMarked.rows.length > 0) {
            return res.status(200).json({
                success: true,
                message: `Attendance already marked as '${alreadyMarked.rows[0].status}' for ${student.student_name} (${session} Session).`,
                student
            });
        }

        // 4. Mark attendance as Present
        const result = await db.query(
            `INSERT INTO public.attendance
            (
                student_class_mapping_id, attendance_date, period_number,
                subject, faculty_id, status, session, remarks
            )
            VALUES ($1, $2, $3, $4, $5, 'Present', $6, 'Auto Barcode/QR Scan')
            RETURNING *`,
            [student_class_mapping_id, today, period_number, subject, faculty_id, session]
        );

        res.status(201).json({
            success: true,
            message: `Attendance marked Present for ${student.student_name} (${session} Session)`,
            attendance: result.rows[0],
            student
        });

    } catch (error) {
        next(error);
    }
};

// ==========================================
// MARK ATTENDANCE (Manual/Bulk)
// ==========================================
const markAttendance = async (req, res, next) => {
    try {
        const {
            student_class_mapping_id,
            attendance_date,
            period_number,
            subject,
            status,
            session,
            remarks
        } = req.body;

        const faculty_id = req.user.id;

        if (!student_class_mapping_id || !attendance_date || !status) {
            return res.status(400).json({
                success: false,
                message: "student_class_mapping_id, attendance_date, and status are required."
            });
        }

        const alreadyMarked = await db.query(
            `SELECT id FROM public.attendance
             WHERE student_class_mapping_id = $1 
               AND attendance_date = $2 
               AND session = $3`,
            [student_class_mapping_id, attendance_date, session || "Morning"]
        );

        if (alreadyMarked.rows.length > 0) {
            return res.status(400).json({
                success: false,
                message: "Attendance already marked for this student, date, and session."
            });
        }

        const result = await db.query(
            `INSERT INTO public.attendance
            (
                student_class_mapping_id, attendance_date, period_number,
                subject, faculty_id, status, session, remarks
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *`,
            [
                student_class_mapping_id,
                attendance_date,
                period_number || 1,
                subject || "Daily Attendance",
                faculty_id,
                status,
                session || "Morning",
                remarks
            ]
        );

        res.status(201).json({
            success: true,
            message: "Attendance Marked Successfully",
            attendance: result.rows[0]
        });

    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ALL ATTENDANCE
// ==========================================
const getAllAttendance = async (req, res, next) => {
    try {
        const result = await db.query(
            `SELECT a.*, s.student_name, s.admission_no
             FROM public.attendance a
             JOIN public.student_class_mapping scm ON a.student_class_mapping_id = scm.id
             JOIN public.students s ON scm.student_id = s.id
             ORDER BY a.attendance_date DESC, a.id DESC`
        );

        res.json({
            success: true,
            total: result.rows.length,
            attendance: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ATTENDANCE BY STUDENT ID (For summaries)
// ==========================================
const getAttendanceByStudent = async (req, res, next) => {
    try {
        const studentId = req.params.studentId;
        const result = await db.query(
            `SELECT a.*
             FROM public.attendance a
             JOIN public.student_class_mapping scm ON a.student_class_mapping_id = scm.id
             WHERE scm.student_id = $1
             ORDER BY a.attendance_date DESC`,
            [studentId]
        );

        res.json({
            success: true,
            total: result.rows.length,
            attendance: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// UPDATE ATTENDANCE
// ==========================================
const updateAttendance = async (req, res, next) => {
    try {
        const id = req.params.id;
        const { status, remarks } = req.body;

        const result = await db.query(
            `UPDATE public.attendance
             SET status = $1, remarks = $2
             WHERE id = $3
             RETURNING *`,
            [status, remarks, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Attendance record not found."
            });
        }

        res.json({
            success: true,
            message: "Attendance Updated Successfully",
            attendance: result.rows[0]
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// DELETE ATTENDANCE
// ==========================================
const deleteAttendance = async (req, res, next) => {
    try {
        const id = req.params.id;
        const result = await db.query(
            "DELETE FROM public.attendance WHERE id = $1 RETURNING *",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Attendance record not found."
            });
        }

        res.json({
            success: true,
            message: "Attendance Deleted Successfully"
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// CLASS-WISE ATTENDANCE REPORT & ANALYTICS
// ==========================================
const getClassAttendanceReport = async (req, res, next) => {
    try {
        const { classId } = req.params;
        const { date } = req.query; // optional date filter, defaults to today
        const queryDate = date || new Date().toISOString().split("T")[0];

        // 1. Get total students mapped in this class
        const studentsQuery = await db.query(
            `SELECT COUNT(id) as total_students 
             FROM public.student_class_mapping 
             WHERE class_id = $1 AND is_current = true`,
            [classId]
        );
        const totalStudents = parseInt(studentsQuery.rows[0].total_students) || 0;

        // 2. Query morning and afternoon present/absent stats
        const statsQuery = await db.query(
            `SELECT 
                session,
                COUNT(CASE WHEN status = 'Present' THEN 1 END) as present_count,
                COUNT(CASE WHEN status = 'Absent' THEN 1 END) as absent_count
             FROM public.attendance a
             JOIN public.student_class_mapping scm ON a.student_class_mapping_id = scm.id
             WHERE scm.class_id = $1 AND a.attendance_date = $2
             GROUP BY session`,
            [classId, queryDate]
        );

        // 3. Fetch detailed student attendance table
        const detailsQuery = await db.query(
            `SELECT 
                s.id as student_id,
                s.student_name,
                s.admission_no,
                scm.class_roll_number,
                COALESCE(am.status, 'Absent') as morning_status,
                COALESCE(aa.status, 'Absent') as afternoon_status
             FROM public.student_class_mapping scm
             JOIN public.students s ON scm.student_id = s.id
             LEFT JOIN public.attendance am 
                ON scm.id = am.student_class_mapping_id 
                AND am.attendance_date = $2 
                AND am.session = 'Morning'
             LEFT JOIN public.attendance aa 
                ON scm.id = aa.student_class_mapping_id 
                AND aa.attendance_date = $2 
                AND aa.session = 'Afternoon'
             WHERE scm.class_id = $1 AND scm.is_current = true
             ORDER BY scm.class_roll_number`,
            [classId, queryDate]
        );

        res.status(200).json({
            success: true,
            classId: parseInt(classId),
            date: queryDate,
            totalStudents,
            sessions: statsQuery.rows,
            students: detailsQuery.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// STUDENT-WISE ATTENDANCE SUMMARY (Percentages)
// ==========================================
const getStudentAttendanceSummary = async (req, res, next) => {
    try {
        const { studentId } = req.params;

        // Verify student mapping exists
        const mappingResult = await db.query(
            "SELECT id FROM public.student_class_mapping WHERE student_id = $1 AND is_current = true",
            [studentId]
        );

        if (mappingResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "No current active mapping found for this student."
            });
        }

        const mappingId = mappingResult.rows[0].id;

        // Query attendance aggregations
        const result = await db.query(
            `SELECT 
                COUNT(*) as total_sessions,
                COUNT(CASE WHEN status = 'Present' THEN 1 END) as present_sessions,
                COUNT(CASE WHEN status = 'Absent' THEN 1 END) as absent_sessions,
                COUNT(CASE WHEN status = 'Late' THEN 1 END) as late_sessions
             FROM public.attendance 
             WHERE student_class_mapping_id = $1`,
            [mappingId]
        );

        const stats = result.rows[0];
        const total = parseInt(stats.total_sessions) || 0;
        const present = parseInt(stats.present_sessions) || 0;
        const late = parseInt(stats.late_sessions) || 0;
        
        // Present rate calculation (treating Late as present for percentage)
        const attendancePercentage = total > 0 ? (((present + late) / total) * 100).toFixed(2) : "100.00";

        res.status(200).json({
            success: true,
            studentId: parseInt(studentId),
            summary: {
                totalSessions: total,
                present: present,
                absent: parseInt(stats.absent_sessions) || 0,
                late: late,
                attendancePercentage: parseFloat(attendancePercentage)
            }
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    markAttendance,
    scanBarcodeAttendance,
    getAllAttendance,
    getAttendanceByStudent,
    updateAttendance,
    deleteAttendance,
    getClassAttendanceReport,
    getStudentAttendanceSummary
};