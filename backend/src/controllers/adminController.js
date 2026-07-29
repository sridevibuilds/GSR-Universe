const db = require("../config/db");
const bcrypt = require("bcrypt");
const generateToken = require("../utils/jwt");

// ----------------------
// Admin Login
// ----------------------
const adminLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and Password are required"
            });
        }

        const result = await db.query(
            "SELECT * FROM admins WHERE email = $1",
            [email]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: "Invalid Email"
            });
        }

        const admin = result.rows[0];

        const isMatch = await bcrypt.compare(
            password,
            admin.password_hash
        );

        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: "Invalid Password"
            });
        }

        const token = generateToken({
            id: admin.id,
            role: "admin"
        });

        res.json({
            success: true,
            message: "Login Successful",
            token,
            admin: {
                id: admin.id,
                admin_name: admin.admin_name,
                email: admin.email
            }
        });

    } catch (error) {
        console.log(error);
        res.status(500).json({
            success: false,
            message: "Server Error"
        });
    }
};

// ----------------------
// Admin Overview Metrics
// ----------------------
const getAdminOverview = async (req, res, next) => {
    try {
        // 1. Active Total Students Count from active mappings
        const studentRes = await db.query(`
            SELECT COUNT(DISTINCT scm.student_id)::int AS total_students
            FROM public.student_class_mapping scm
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            WHERE scm.is_current = true AND ay.is_current = true
        `);
        const totalStudents = parseInt(studentRes.rows[0]?.total_students || 0);

        // 2. Faculty Roster Stats
        const facultyRes = await db.query(`
            SELECT 
                COUNT(id)::int AS total_faculty,
                COUNT(CASE WHEN is_active = true THEN 1 END)::int AS active_faculty,
                COUNT(CASE WHEN is_active = false THEN 1 END)::int AS disabled_faculty
            FROM public.faculty
        `);
        const facultyStats = facultyRes.rows[0] || { total_faculty: 0, active_faculty: 0, disabled_faculty: 0 };

        // 3. System Fee Metrics across active student mappings
        const feeRes = await db.query(`
            SELECT 
                COALESCE(SUM(f.total_fee), 0)::numeric(12,2) AS total_fee_amount,
                COALESCE(SUM(f.paid_amount), 0)::numeric(12,2) AS collected_fee_amount,
                COALESCE(SUM(f.total_fee - f.paid_amount), 0)::numeric(12,2) AS outstanding_fee_amount
            FROM public.fees f
            JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            WHERE scm.is_current = true AND ay.is_current = true
        `);
        const feeStats = feeRes.rows[0] || { total_fee_amount: "0.00", collected_fee_amount: "0.00", outstanding_fee_amount: "0.00" };

        res.json({
            success: true,
            overview: {
                total_students: totalStudents,
                total_faculty: parseInt(facultyStats.total_faculty) || 0,
                active_faculty: parseInt(facultyStats.active_faculty) || 0,
                disabled_faculty: parseInt(facultyStats.disabled_faculty) || 0,
                total_fee_amount: parseFloat(feeStats.total_fee_amount || 0),
                collected_fee_amount: parseFloat(feeStats.collected_fee_amount || 0),
                outstanding_fee_amount: parseFloat(feeStats.outstanding_fee_amount || 0)
            }
        });
    } catch (error) {
        console.error("Admin Overview Error:", error);
        next(error);
    }
};

// ----------------------
// Class Performance Analytics Report
// ----------------------
const getClassReport = async (req, res, next) => {
    try {
        const { academic_year, class_name, section, term } = req.query;

        // Build parameters and SQL WHERE clause with strict relational joins
        const params = [];
        let whereClause = ` WHERE scm.is_current = true`;

        if (academic_year && academic_year.trim() !== "" && academic_year.trim().toUpperCase() !== "ALL") {
            params.push(`%${academic_year.trim()}%`);
            whereClause += ` AND (ay.year_name ILIKE $${params.length} OR c.academic_year ILIKE $${params.length})`;
        }

        if (class_name && class_name.trim() !== "" && class_name.trim().toUpperCase() !== "ALL") {
            const rawClass = class_name.trim();
            const cleanClass = rawClass.replace(/Class\s*/i, "").replace(/th\s*/i, "").trim();
            params.push(`%${cleanClass}%`);
            whereClause += ` AND (c.class_name ILIKE $${params.length} OR s.class_name ILIKE $${params.length})`;
        }

        if (section && section.trim() !== "" && section.trim().toUpperCase() !== "ALL") {
            const rawSec = section.trim();
            const cleanSec = rawSec.replace(/Section\s*/i, "").replace(/Sec\s*/i, "").trim();
            params.push(`%${cleanSec}%`);
            whereClause += ` AND (c.section ILIKE $${params.length} OR s.section ILIKE $${params.length})`;
        }

        // 1. Total Students in selection
        const studentCountQuery = `
            SELECT COUNT(DISTINCT scm.student_id)::int AS total_students
            FROM public.student_class_mapping scm
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            ${whereClause}
        `;
        const studentCountRes = await db.query(studentCountQuery, params);
        const totalStudents = parseInt(studentCountRes.rows[0]?.total_students || 0);

        // 2. Fee Collection & Pending Fee in selection
        const feeQuery = `
            SELECT 
                COALESCE(SUM(f.paid_amount), 0)::numeric(10,2) AS fee_collection,
                COALESCE(SUM(f.total_fee - f.paid_amount), 0)::numeric(10,2) AS pending_fee
            FROM public.fees f
            JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            ${whereClause}
        `;
        const feeRes = await db.query(feeQuery, params);
        const feeCollection = parseFloat(feeRes.rows[0]?.fee_collection || 0);
        const pendingFee = parseFloat(feeRes.rows[0]?.pending_fee || 0);

        // 3. Assessment Average & Student Grade Classification
        const termParams = [...params];
        let termWhereClause = whereClause;
        if (term && term.trim() !== "" && term.trim().toUpperCase() !== "ALL" && term.trim() !== "Annual") {
            termParams.push(`%${term.trim()}%`);
            termWhereClause += ` AND a.assessment_type ILIKE $${termParams.length}`;
        }

        const assessmentAvgQuery = `
            SELECT COALESCE(AVG(
                CASE WHEN a.total_marks > 0 THEN (ar.marks_obtained / a.total_marks) * 100 ELSE 0 END
            ), 0)::numeric(5,2) AS assessment_performance_pct
            FROM public.assessment_results ar
            JOIN public.assessments a ON ar.assessment_id = a.id
            JOIN public.student_class_mapping scm ON ar.student_class_mapping_id = scm.id
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            ${termWhereClause}
        `;
        const assessmentAvgRes = await db.query(assessmentAvgQuery, termParams);
        const assessmentPerformancePct = Math.round(parseFloat(assessmentAvgRes.rows[0]?.assessment_performance_pct || 0));

        const gradeBreakdownQuery = `
            WITH student_scores AS (
                SELECT 
                    scm.student_id,
                    AVG(CASE WHEN a.total_marks > 0 THEN (ar.marks_obtained / a.total_marks) * 100 ELSE 0 END) AS avg_score
                FROM public.assessment_results ar
                JOIN public.assessments a ON ar.assessment_id = a.id
                JOIN public.student_class_mapping scm ON ar.student_class_mapping_id = scm.id
                JOIN public.students s ON scm.student_id = s.id
                JOIN public.classes c ON scm.class_id = c.id
                JOIN public.academic_years ay ON scm.academic_year_id = ay.id
                ${termWhereClause}
                GROUP BY scm.student_id
            )
            SELECT 
                COUNT(CASE WHEN avg_score >= 85 THEN 1 END)::int AS excellent_students,
                COUNT(CASE WHEN avg_score >= 60 AND avg_score < 85 THEN 1 END)::int AS average_students,
                COUNT(CASE WHEN avg_score < 60 THEN 1 END)::int AS needs_improvement
            FROM student_scores
        `;
        const gradeBreakdownRes = await db.query(gradeBreakdownQuery, termParams);
        const excellentStudents = parseInt(gradeBreakdownRes.rows[0]?.excellent_students || 0);
        const averageStudents = parseInt(gradeBreakdownRes.rows[0]?.average_students || 0);
        const needsImprovement = parseInt(gradeBreakdownRes.rows[0]?.needs_improvement || 0);

        // 4. Attendance Calculations (Daily, Monthly, Yearly)
        const dailyAttQuery = `
            SELECT 
                COUNT(*)::int AS total_sessions,
                COUNT(CASE WHEN att.status IN ('Present', 'Late') THEN 1 END)::int AS attended_sessions
            FROM public.attendance att
            JOIN public.student_class_mapping scm ON att.student_class_mapping_id = scm.id
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            ${whereClause} AND att.attendance_date = CURRENT_DATE
        `;
        let dailyAttRes = await db.query(dailyAttQuery, params);
        let dTotal = parseInt(dailyAttRes.rows[0]?.total_sessions || 0);
        let dAttended = parseInt(dailyAttRes.rows[0]?.attended_sessions || 0);

        if (dTotal === 0) {
            const latestDailyAttQuery = `
                SELECT 
                    COUNT(*)::int AS total_sessions,
                    COUNT(CASE WHEN att.status IN ('Present', 'Late') THEN 1 END)::int AS attended_sessions
                FROM public.attendance att
                JOIN public.student_class_mapping scm ON att.student_class_mapping_id = scm.id
                JOIN public.students s ON scm.student_id = s.id
                JOIN public.classes c ON scm.class_id = c.id
                JOIN public.academic_years ay ON scm.academic_year_id = ay.id
                ${whereClause} AND att.attendance_date = (
                    SELECT MAX(attendance_date) FROM public.attendance
                )
            `;
            dailyAttRes = await db.query(latestDailyAttQuery, params);
            dTotal = parseInt(dailyAttRes.rows[0]?.total_sessions || 0);
            dAttended = parseInt(dailyAttRes.rows[0]?.attended_sessions || 0);
        }
        const dailyAttPct = dTotal > 0 ? Math.round((dAttended / dTotal) * 100) : 100;

        const monthlyAttQuery = `
            SELECT 
                COUNT(*)::int AS total_sessions,
                COUNT(CASE WHEN att.status IN ('Present', 'Late') THEN 1 END)::int AS attended_sessions
            FROM public.attendance att
            JOIN public.student_class_mapping scm ON att.student_class_mapping_id = scm.id
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            ${whereClause} AND DATE_TRUNC('month', att.attendance_date) = DATE_TRUNC('month', CURRENT_DATE)
        `;
        const monthlyAttRes = await db.query(monthlyAttQuery, params);
        const mTotal = parseInt(monthlyAttRes.rows[0]?.total_sessions || 0);
        const mAttended = parseInt(monthlyAttRes.rows[0]?.attended_sessions || 0);
        const monthlyAttPct = mTotal > 0 ? Math.round((mAttended / mTotal) * 100) : 100;

        const yearlyAttQuery = `
            SELECT 
                COUNT(*)::int AS total_sessions,
                COUNT(CASE WHEN att.status IN ('Present', 'Late') THEN 1 END)::int AS attended_sessions
            FROM public.attendance att
            JOIN public.student_class_mapping scm ON att.student_class_mapping_id = scm.id
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            ${whereClause}
        `;
        const yearlyAttRes = await db.query(yearlyAttQuery, params);
        const yTotal = parseInt(yearlyAttRes.rows[0]?.total_sessions || 0);
        const yAttended = parseInt(yearlyAttRes.rows[0]?.attended_sessions || 0);
        const yearlyAttPct = yTotal > 0 ? Math.round((yAttended / yTotal) * 100) : 100;

        // 5. Individual student roster list matching filter
        const studentListQuery = `
            SELECT 
                s.id,
                s.student_name,
                s.admission_no,
                c.class_name,
                c.section,
                ay.year_name as academic_year,
                COALESCE(f.total_fee, 0.00)::numeric as total_fee,
                COALESCE(f.paid_amount, 0.00)::numeric as paid_fee,
                COALESCE(f.total_fee - f.paid_amount, 0.00)::numeric as pending_fee
            FROM public.students s
            JOIN public.student_class_mapping scm ON s.id = scm.student_id
            JOIN public.classes c ON scm.class_id = c.id
            JOIN public.academic_years ay ON scm.academic_year_id = ay.id
            LEFT JOIN public.fees f ON scm.id = f.student_class_mapping_id
            ${whereClause}
            ORDER BY s.student_name ASC
        `;
        const studentListRes = await db.query(studentListQuery, params);

        res.json({
            success: true,
            summary: {
                total_students: totalStudents,
                assessment_performance_pct: assessmentPerformancePct,
                fee_collection: feeCollection,
                pending_fee: pendingFee,
                excellent_students: excellentStudents,
                average_students: averageStudents,
                needs_improvement: needsImprovement,
                daily_attendance_pct: dailyAttPct,
                monthly_attendance_pct: monthlyAttPct,
                yearly_attendance_pct: yearlyAttPct
            },
            students: studentListRes.rows
        });
    } catch (error) {
        console.error("Get Class Report Error:", error);
        next(error);
    }
};

// ----------------------
// System Notifications
// ----------------------
const getSystemNotifications = async (req, res, next) => {
    try {
        const result = await db.query(`
            SELECT id, title, description, type, is_read, created_at 
            FROM public.system_notifications 
            ORDER BY created_at DESC 
            LIMIT 50
        `);
        res.json({
            success: true,
            notifications: result.rows
        });
    } catch (error) {
        console.error("System Notifications Error:", error);
        res.json({
            success: true,
            notifications: []
        });
    }
};

module.exports = {
    adminLogin,
    getAdminOverview,
    getClassReport,
    getSystemNotifications
};