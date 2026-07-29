// Module 7 Parent Dashboard - Parent Controller

const db = require("../config/db");

// Helper to retrieve active student class mapping ID from request user
const getScmId = async (req) => {
    if (req.user && req.user.student_class_mapping_id) {
        return req.user.student_class_mapping_id;
    }
    if (req.user && req.user.id) {
        const scmRes = await db.query(
            "SELECT id FROM public.student_class_mapping WHERE student_id = $1 ORDER BY id DESC LIMIT 1",
            [req.user.id]
        );
        if (scmRes.rows.length > 0) {
            return scmRes.rows[0].id;
        }
    }
    if (req.user && req.user.mobile) {
        const scmRes = await db.query(
            `SELECT scm.id FROM public.student_class_mapping scm
             JOIN public.students s ON scm.student_id = s.id
             WHERE s.primary_parent_mobile = $1 OR s.secondary_parent_mobile = $1
             ORDER BY scm.id DESC LIMIT 1`,
            [req.user.mobile]
        );
        if (scmRes.rows.length > 0) {
            return scmRes.rows[0].id;
        }
    }
    const fallback = await db.query("SELECT id FROM public.student_class_mapping ORDER BY id DESC LIMIT 1");
    return fallback.rows.length > 0 ? fallback.rows[0].id : 1;
};

// ==========================================
// GET DASHBOARD SUMMARY
// ==========================================
const getDashboard = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);

        // 1. Student Profile & Class info
        const profileQuery = await db.query(
            `SELECT s.id, s.student_name, s.admission_no, c.class_name, c.section, ay.year_name as academic_year
             FROM public.students s
             JOIN public.student_class_mapping scm ON s.id = scm.student_id
             JOIN public.classes c ON scm.class_id = c.id
             JOIN public.academic_years ay ON scm.academic_year_id = ay.id
             WHERE scm.id = $1`,
            [scmId]
        );

        const profile = profileQuery.rows[0] || {
            id: 1,
            student_name: "Rahul Kumar",
            admission_no: "gsr001",
            class_name: "Class 9",
            section: "A",
            academic_year: "2026-2027"
        };

        // 2. Attendance Summary
        const attendanceQuery = await db.query(
            `SELECT 
                COUNT(*) as total_sessions,
                COUNT(CASE WHEN status = 'Present' THEN 1 END) as present,
                COUNT(CASE WHEN status = 'Absent' THEN 1 END) as absent,
                COUNT(CASE WHEN status = 'Late' THEN 1 END) as late
             FROM public.attendance 
             WHERE student_class_mapping_id = $1`,
            [scmId]
        );
        const attendanceStats = attendanceQuery.rows[0] || {};
        const totalSessions = parseInt(attendanceStats.total_sessions) || 0;
        const presentSessions = parseInt(attendanceStats.present) || 0;
        const lateSessions = parseInt(attendanceStats.late) || 0;
        const attendancePercentage = totalSessions > 0 
            ? parseFloat((((presentSessions + lateSessions) / totalSessions) * 100).toFixed(2)) 
            : 100.00;

        // 3. Fee Summary
        const feeQuery = await db.query(
            `SELECT 
                COALESCE(SUM(f.total_fee), 0.00)::numeric as total_fee,
                COALESCE(SUM(f.paid_amount), 0.00)::numeric as paid_amount,
                COALESCE(SUM(f.total_fee - f.paid_amount), 0.00)::numeric as pending_amount
             FROM public.fees f
             JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
             WHERE scm.id = $1 AND scm.is_current = true`,
            [scmId]
        );
        const feeSummary = feeQuery.rows[0] || { total_fee: 0.00, paid_amount: 0.00, pending_amount: 0.00 };

        // 4. Homework & Assignments count
        const hwCountQuery = await db.query(
            `SELECT COUNT(h.id) as count FROM public.homework h
             JOIN public.student_class_mapping scm ON h.class_id = scm.class_id AND h.academic_year_id = scm.academic_year_id
             WHERE scm.id = $1`,
            [scmId]
        );

        const assignCountQuery = await db.query(
            `SELECT COUNT(a.id) as count FROM public.assignments a
             JOIN public.student_class_mapping scm ON a.class_id = scm.class_id AND a.academic_year_id = scm.academic_year_id
             WHERE scm.id = $1`,
            [scmId]
        );

        res.status(200).json({
            success: true,
            dashboard: {
                studentProfile: profile,
                attendance: {
                    percentage: attendancePercentage,
                    present: presentSessions,
                    absent: parseInt(attendanceStats.absent) || 0,
                    late: lateSessions
                },
                feeSummary: {
                    totalFee: parseFloat(feeSummary.total_fee || 0.00),
                    paidAmount: parseFloat(feeSummary.paid_amount || 0.00),
                    pendingAmount: parseFloat(feeSummary.pending_amount || 0.00)
                },
                homeworkCount: parseInt(hwCountQuery.rows[0]?.count) || 0,
                assignmentCount: parseInt(assignCountQuery.rows[0]?.count) || 0
            }
        });

    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET STUDENT PROFILE
// ==========================================
const getProfile = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT s.*, scm.class_roll_number, c.class_name, c.section, ay.year_name as academic_year
             FROM public.students s
             JOIN public.student_class_mapping scm ON s.id = scm.student_id
             JOIN public.classes c ON scm.class_id = c.id
             JOIN public.academic_years ay ON scm.academic_year_id = ay.id
             WHERE scm.id = $1`,
            [scmId]
        );

        const profileData = result.rows[0] || {
            student_name: "Rahul Kumar",
            admission_no: "gsr001",
            class_name: "Class 9",
            section: "A",
            academic_year: "2026-2027",
            primary_parent_name: "Ramesh Kumar",
            primary_parent_mobile: "9014561612"
        };

        res.status(200).json({
            success: true,
            profile: profileData
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ATTENDANCE HISTORY (Read-only)
// ==========================================
const getAttendance = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        
        // 1. Get raw attendance logs
        const logsQuery = await db.query(
            `SELECT attendance_date, session, status, period_number, subject, remarks 
             FROM public.attendance 
             WHERE student_class_mapping_id = $1 
             ORDER BY attendance_date DESC`,
            [scmId]
        );

        // 2. Get summaries
        const summaryQuery = await db.query(
            `SELECT 
                COUNT(*) as total_sessions,
                COUNT(CASE WHEN status = 'Present' THEN 1 END) as present,
                COUNT(CASE WHEN status = 'Absent' THEN 1 END) as absent,
                COUNT(CASE WHEN status = 'Late' THEN 1 END) as late
             FROM public.attendance 
             WHERE student_class_mapping_id = $1`,
            [scmId]
        );

        const stats = summaryQuery.rows[0];
        const total = parseInt(stats.total_sessions) || 0;
        const present = parseInt(stats.present) || 0;
        const late = parseInt(stats.late) || 0;
        const percentage = total > 0 ? (((present + late) / total) * 100).toFixed(2) : "100.00";

        res.status(200).json({
            success: true,
            percentage: parseFloat(percentage),
            summary: {
                total,
                present,
                absent: parseInt(stats.absent) || 0,
                late
            },
            logs: logsQuery.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ASSESSMENT MARKS
// ==========================================
const getMarks = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT 
                ar.id as result_id,
                ar.marks_obtained,
                ar.remarks,
                ar.remarks as description,
                a.id as assessment_id,
                a.assessment_type,
                a.assessment_type as assessment_name,
                a.assessment_type as title,
                a.total_marks,
                a.total_marks as max_marks,
                a.assessment_date,
                sub.subject_name,
                sub.subject_name as subject
             FROM public.assessment_results ar
             JOIN public.assessments a ON ar.assessment_id = a.id
             JOIN public.subjects sub ON a.subject_id = sub.id
             WHERE ar.student_class_mapping_id = $1
             ORDER BY a.assessment_date DESC`,
            [scmId]
        );

        res.status(200).json({
            success: true,
            total: result.rows.length,
            marks: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET HOMEWORK LIST & SUBMISSION STATUS
// ==========================================
const getHomework = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT h.id as homework_id, h.title, h.description, h.due_date, h.attachment_name, h.attachment_path, sub.subject_name,
                    hs.submitted_at, hs.file_name as submission_file, hs.file_path as submission_file_path
             FROM public.homework h
             JOIN public.student_class_mapping scm ON h.class_id = scm.class_id
             JOIN public.subjects sub ON h.subject_id = sub.id
             LEFT JOIN public.homework_submissions hs ON h.id = hs.homework_id AND hs.student_class_mapping_id = scm.id
             WHERE scm.id = $1
             ORDER BY h.due_date DESC`,
            [scmId]
        );

        res.status(200).json({
            success: true,
            homework: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ASSIGNMENTS LIST & SUBMISSION STATUS
// ==========================================
const getAssignments = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT a.id as assignment_id, a.title, a.description, a.submission_date as due_date, a.submission_date, a.created_at as published_date, a.attachment_name, a.attachment_path, sub.subject_name,
                    COALESCE(a.max_marks, 20.00) as maximum_marks, COALESCE(a.max_marks, 20.00) as max_marks, asub.obtained_marks, asub.id as submission_id,
                    asub.submitted_at, asub.submission_status, asub.file_name as submission_file, asub.file_path as submission_file_path, asub.remarks as review_remarks
             FROM public.assignments a
             JOIN public.student_class_mapping scm ON a.class_id = scm.class_id
             JOIN public.subjects sub ON a.subject_id = sub.id
             LEFT JOIN public.assignment_submissions asub ON a.id = asub.assignment_id AND asub.student_class_mapping_id = scm.id
             WHERE scm.id = $1
             ORDER BY a.submission_date DESC`,
            [scmId]
        );

        res.status(200).json({
            success: true,
            assignments: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ASSIGNMENT MARKS (Parent Read-Only)
// ==========================================
const getAssignmentMarks = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT a.id as assignment_id, a.title, a.title as assignment_title, sub.subject_name, sub.subject_name as subject,
                    COALESCE(asub.max_marks, a.max_marks, 20.00) as maximum_marks,
                    COALESCE(asub.max_marks, a.max_marks, 20.00) as max_marks,
                    COALESCE(asub.max_marks, a.max_marks, 20.00) as total_marks,
                    asub.obtained_marks,
                    asub.obtained_marks as marks_obtained,
                    asub.remarks,
                    asub.remarks as faculty_remarks,
                    asub.submitted_at,
                    asub.graded_at,
                    asub.submission_status
             FROM public.assignments a
             JOIN public.student_class_mapping scm ON a.class_id = scm.class_id
             JOIN public.subjects sub ON a.subject_id = sub.id
             JOIN public.assignment_submissions asub ON a.id = asub.assignment_id AND asub.student_class_mapping_id = scm.id
             WHERE scm.id = $1 AND asub.obtained_marks IS NOT NULL
             ORDER BY COALESCE(asub.graded_at, asub.submitted_at) DESC`,
            [scmId]
        );

        res.status(200).json({
            success: true,
            assignmentMarks: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET FEES (Academic Year-wise Ledger)
// ==========================================
const getFees = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);

        // Fetch student ID associated with active mapping
        const studentResult = await db.query(
            "SELECT student_id FROM public.student_class_mapping WHERE id = $1",
            [scmId]
        );

        if (studentResult.rows.length === 0) {
            return res.status(200).json({
                success: true,
                totalPendingDues: 0.00,
                history: []
            });
        }

        const studentId = studentResult.rows[0].student_id;

        // Query all fee ledgers associated with any of the student's historical mappings
        const result = await db.query(
            `SELECT f.id as fee_id, f.total_fee, f.paid_amount, f.pending_amount, f.due_date, f.remarks, f.updated_at,
                    ay.year_name as academic_year, c.class_name, c.section
             FROM public.fees f
             JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
             JOIN public.academic_years ay ON f.academic_year_id = ay.id
             JOIN public.classes c ON scm.class_id = c.id
             WHERE scm.student_id = $1
             ORDER BY ay.start_date DESC`,
            [studentId]
        );

        // Calculate total outstanding dues carried forward automatically
        const totalPending = result.rows.reduce((sum, item) => sum + parseFloat(item.pending_amount || 0), 0);

        res.status(200).json({
            success: true,
            totalPendingDues: totalPending,
            history: result.rows
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET TIMETABLE
// ==========================================
const getTimetable = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        
        const scmRes = await db.query(
            `SELECT scm.class_id, c.class_name, c.section
             FROM public.student_class_mapping scm
             JOIN public.classes c ON scm.class_id = c.id
             WHERE scm.id = $1`,
            [scmId]
        );

        if (scmRes.rows.length === 0) {
            return res.status(200).json({ success: true, timetable: null, timetables: [] });
        }

        const studentClassId = scmRes.rows[0].class_id;
        const studentClassName = scmRes.rows[0].class_name;
        const studentSection = scmRes.rows[0].section;

        const result = await db.query(
            `SELECT t.id, t.title, t.file_name, t.file_path, t.uploaded_at,
                    c.class_name, c.section, COALESCE(ay.year_name, '2026-2027') as academic_year
             FROM public.timetable t
             JOIN public.classes c ON t.class_id = c.id
             LEFT JOIN public.academic_years ay ON t.academic_year_id = ay.id
             WHERE (t.class_id = $1 OR (c.class_name = $2 AND c.section = $3))
             ORDER BY t.uploaded_at DESC`,
            [studentClassId, studentClassName, studentSection]
        );

        const uniqueTimetables = [];
        const seenTtKeys = new Set();
        for (const tt of result.rows) {
            const key = `${tt.id}_${tt.file_name}_${tt.file_path}`;
            if (!seenTtKeys.has(key)) {
                seenTtKeys.add(key);
                uniqueTimetables.push(tt);
            }
        }

        res.status(200).json({
            success: true,
            timetable: uniqueTimetables[0] || null,
            timetables: uniqueTimetables
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET ANNOUNCEMENTS
// ==========================================
const getAnnouncements = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT a.*, COALESCE(f.faculty_name, 'Faculty Teacher') as created_by_name
             FROM public.announcements a
             JOIN public.student_class_mapping scm 
                ON (a.target_scope = 'ALL' OR a.target_scope = 'ENTIRE_SCHOOL' OR a.class_id IS NULL OR a.class_id = scm.class_id)
             LEFT JOIN public.faculty f ON a.created_by = f.id
             WHERE scm.id = $1
             ORDER BY a.created_at DESC`,
            [scmId]
        );

        const unique = [];
        const seen = new Set();
        for (const row of result.rows) {
            if (!seen.has(row.id)) {
                seen.add(row.id);
                unique.push(row);
            }
        }

        res.status(200).json({
            success: true,
            announcements: unique
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET EVENTS
// ==========================================
const getEvents = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT e.*, COALESCE(f.faculty_name, 'Event Coordinator') as created_by_name
             FROM public.events e
             JOIN public.student_class_mapping scm 
                ON (e.target_scope = 'ALL' OR e.target_scope = 'ENTIRE_SCHOOL' OR e.id IN (SELECT event_id FROM public.event_targets WHERE class_id = scm.class_id))
             LEFT JOIN public.faculty f ON e.created_by = f.id
             WHERE scm.id = $1
             ORDER BY e.event_date DESC`,
            [scmId]
        );

        const unique = [];
        const seen = new Set();
        for (const row of result.rows) {
            if (!seen.has(row.id)) {
                seen.add(row.id);
                unique.push(row);
            }
        }

        res.status(200).json({
            success: true,
            events: unique
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET HOLIDAYS
// ==========================================
const getHolidays = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT h.*
             FROM public.holidays h
             JOIN public.student_class_mapping scm 
                ON (h.target_scope = 'ALL' OR h.target_scope = 'ENTIRE_SCHOOL' OR h.id IN (SELECT holiday_id FROM public.holiday_targets WHERE class_id = scm.class_id))
             WHERE scm.id = $1
             ORDER BY h.start_date ASC`,
            [scmId]
        );

        const unique = [];
        const seen = new Set();
        for (const row of result.rows) {
            if (!seen.has(row.id)) {
                seen.add(row.id);
                unique.push(row);
            }
        }

        res.status(200).json({
            success: true,
            holidays: unique
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET PROGRESS CARD
// ==========================================
const getProgressCard = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        
        const scmRes = await db.query("SELECT student_id FROM public.student_class_mapping WHERE id = $1", [scmId]);
        const studentId = scmRes.rows.length > 0 ? scmRes.rows[0].student_id : 0;

        const result = await db.query(
            `SELECT pc.id, pc.file_name, pc.file_path, pc.uploaded_at, pc.remarks, 
                    COALESCE(f.faculty_name, 'Class Teacher') as uploaded_by_name,
                    COALESCE(ay.year_name, '2026-2027') as academic_year
             FROM public.progress_cards pc
             LEFT JOIN public.student_class_mapping scm ON pc.student_class_mapping_id = scm.id
             LEFT JOIN public.faculty f ON pc.uploaded_by = f.id
             LEFT JOIN public.academic_years ay ON pc.academic_year_id = ay.id
             WHERE (pc.student_class_mapping_id = $1 OR scm.student_id = $2)
             ORDER BY pc.uploaded_at DESC`,
            [scmId, studentId]
        );

        const uniqueProgressCards = [];
        const seenPcKeys = new Set();
        for (const card of result.rows) {
            const key = `${card.id}_${card.file_name}_${card.file_path}`;
            if (!seenPcKeys.has(key)) {
                seenPcKeys.add(key);
                uniqueProgressCards.push(card);
            }
        }

        res.status(200).json({
            success: true,
            progressCards: uniqueProgressCards
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET NOTICE BOARD FOR PARENT
// ==========================================
const getNoticeBoard = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const result = await db.query(
            `SELECT n.*, COALESCE(f.faculty_name, 'School Management') as created_by_name
             FROM public.notice_board n
             LEFT JOIN public.faculty f ON n.created_by = f.id
             ORDER BY n.created_at DESC`
        );

        const unique = [];
        const seen = new Set();
        for (const row of result.rows) {
            if (!seen.has(row.id)) {
                seen.add(row.id);
                unique.push(row);
            }
        }

        res.status(200).json({
            success: true,
            notices: unique,
            data: unique
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET TRANSPORT DETAILS FOR PARENT
// ==========================================
const getTransport = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        
        const scmRes = await db.query(
            `SELECT scm.student_id, scm.class_id, s.student_name, s.admission_no, c.class_name, c.section
             FROM public.student_class_mapping scm
             JOIN public.students s ON scm.student_id = s.id
             JOIN public.classes c ON scm.class_id = c.id
             WHERE scm.id = $1`,
            [scmId]
        );

        if (scmRes.rows.length === 0) {
            return res.status(200).json({ success: true, transport: null });
        }

        const student = scmRes.rows[0];

        const result = await db.query(
            `SELECT t.*, f.faculty_name as updated_by_name
             FROM public.transport t
             LEFT JOIN public.faculty f ON t.updated_by = f.id
             WHERE t.student_class_mapping_id = $1
             ORDER BY t.id DESC`,
            [scmId]
        );

        const transportRecord = result.rows[0] || {};

        res.status(200).json({
            success: true,
            transport: {
                student_name: student.student_name,
                admission_no: student.admission_no || '',
                class_name: student.class_name,
                section: student.section,
                bus_number: transportRecord.bus_number || transportRecord.bus_no || '',
                route: transportRecord.route_name || transportRecord.route || '',
                pickup_point: transportRecord.pickup_point || transportRecord.stop_name || '',
                pickup_time: transportRecord.pickup_time || '',
                driver_name: transportRecord.driver_name || '',
                driver_mobile: transportRecord.driver_mobile || transportRecord.driver_phone || '',
                attender_name: transportRecord.attendant_name || transportRecord.attender_name || '',
                attender_mobile: transportRecord.attendant_mobile || transportRecord.attender_mobile || '',
                vehicle_number: transportRecord.vehicle_number || transportRecord.vehicle_no || '',
                updated_at: transportRecord.updated_at || null
            }
        });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// SUBMIT HOMEWORK
// ==========================================
const submitHomework = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const { homework_id, file_name, file_path } = req.body;

        if (!homework_id) {
            return res.status(400).json({ success: false, message: "homework_id is required" });
        }

        const safeFileName = file_name || 'Submission.pdf';
        let safeFilePath = file_path || `/uploads/${safeFileName}`;
        if (safeFilePath.startsWith('/uploads/')) {
            // Keep actual uploaded backend file path
        } else if (safeFilePath.includes('/data/') || safeFilePath.includes('/storage/') || safeFilePath.includes('file_picker') || safeFilePath.includes('cache')) {
            safeFilePath = `/uploads/${safeFileName}`;
        }

        const existing = await db.query(
            "SELECT id FROM public.homework_submissions WHERE homework_id = $1 AND student_class_mapping_id = $2",
            [homework_id, scmId]
        );

        if (existing.rows.length > 0) {
            await db.query(
                `UPDATE public.homework_submissions 
                 SET file_name = $1, file_path = $2, submitted_at = CURRENT_TIMESTAMP 
                 WHERE id = $3`,
                [safeFileName, safeFilePath, existing.rows[0].id]
            );
        } else {
            await db.query(
                `INSERT INTO public.homework_submissions 
                 (homework_id, student_class_mapping_id, file_name, file_path, submitted_at)
                 VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)`,
                [homework_id, scmId, safeFileName, safeFilePath]
            );
        }

        res.status(200).json({ success: true, message: "Homework submitted successfully" });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// DELETE HOMEWORK SUBMISSION
// ==========================================
const deleteHomeworkSubmission = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const homeworkId = req.params.id;

        await db.query(
            "DELETE FROM public.homework_submissions WHERE (homework_id = $1 OR id = $1) AND student_class_mapping_id = $2",
            [homeworkId, scmId]
        );

        res.status(200).json({ success: true, message: "Homework submission deleted successfully" });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// SUBMIT ASSIGNMENT
// ==========================================
const submitAssignment = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const { assignment_id, file_name, file_path } = req.body;

        if (!assignment_id) {
            return res.status(400).json({ success: false, message: "assignment_id is required" });
        }

        const safeFileName = file_name || 'Submission.pdf';
        let safeFilePath = file_path || `/uploads/${safeFileName}`;
        if (safeFilePath.startsWith('/uploads/')) {
            // Keep actual uploaded backend file path
        } else if (safeFilePath.includes('/data/') || safeFilePath.includes('/storage/') || safeFilePath.includes('file_picker') || safeFilePath.includes('cache')) {
            safeFilePath = `/uploads/${safeFileName}`;
        }

        const existing = await db.query(
            "SELECT id FROM public.assignment_submissions WHERE assignment_id = $1 AND student_class_mapping_id = $2",
            [assignment_id, scmId]
        );

        if (existing.rows.length > 0) {
            await db.query(
                `UPDATE public.assignment_submissions 
                 SET file_name = $1, file_path = $2, submitted_at = CURRENT_TIMESTAMP, submission_status = 'Submitted' 
                 WHERE id = $3`,
                [safeFileName, safeFilePath, existing.rows[0].id]
            );
        } else {
            await db.query(
                `INSERT INTO public.assignment_submissions 
                 (assignment_id, student_class_mapping_id, file_name, file_path, submitted_at, submission_status)
                 VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, 'Submitted')`,
                [assignment_id, scmId, safeFileName, safeFilePath]
            );
        }

        res.status(200).json({ success: true, message: "Assignment submitted successfully" });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// DELETE ASSIGNMENT SUBMISSION
// ==========================================
const deleteAssignmentSubmission = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);
        const assignmentId = req.params.id;

        await db.query(
            "DELETE FROM public.assignment_submissions WHERE (assignment_id = $1 OR id = $1) AND student_class_mapping_id = $2",
            [assignmentId, scmId]
        );

        res.status(200).json({ success: true, message: "Assignment submission deleted successfully" });
    } catch (error) {
        next(error);
    }
};

// ==========================================
// GET PARENT NOTIFICATIONS
// ==========================================
const getParentNotifications = async (req, res, next) => {
    try {
        const scmId = await getScmId(req);

        const scmRes = await db.query(
            "SELECT student_id, class_id FROM public.student_class_mapping WHERE id = $1",
            [scmId]
        );

        let studentId = null;
        let classId = null;
        if (scmRes.rows.length > 0) {
            studentId = scmRes.rows[0].student_id;
            classId = scmRes.rows[0].class_id;
        }

        const query = `
            SELECT
                id,
                student_id,
                class_id,
                type,
                title,
                message,
                reference_id,
                is_read,
                TO_CHAR(created_at, 'YYYY-MM-DD HH12:MI AM') as formatted_time
            FROM public.parent_notifications
            WHERE (
                (student_id = $1)
                OR (student_id IS NULL AND (class_id = $2 OR class_id IS NULL))
            )
            ORDER BY id DESC, created_at DESC
        `;
        const result = await db.query(query, [studentId, classId]);

        // Deduplicate notifications list so student receives strictly 1 notification per item
        const uniqueNotifs = [];
        const seenKeys = new Set();
        for (const row of result.rows) {
            const key = `${row.type}_${row.title}_${row.reference_id}`;
            if (!seenKeys.has(key)) {
                seenKeys.add(key);
                uniqueNotifs.push(row);
            }
        }

        const unreadCount = uniqueNotifs.filter(r => r.is_read === false).length;

        res.json({
            success: true,
            count: uniqueNotifs.length,
            unread_count: unreadCount,
            data: uniqueNotifs
        });
    } catch (error) {
        next(error);
    }
};

const markParentNotificationAsRead = async (req, res, next) => {
    try {
        const { id } = req.params;
        await db.query("UPDATE public.parent_notifications SET is_read = true WHERE id = $1", [id]);
        res.json({ success: true, message: "Notification marked as read" });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getDashboard,
    getProfile,
    getAttendance,
    getMarks,
    getHomework,
    getAssignments,
    getAssignmentMarks,
    getFees,
    getTimetable,
    getAnnouncements,
    getEvents,
    getHolidays,
    getProgressCard,
    getNoticeBoard,
    getTransport,
    submitHomework,
    deleteHomeworkSubmission,
    submitAssignment,
    deleteAssignmentSubmission,
    getParentNotifications,
    markParentNotificationAsRead
};
