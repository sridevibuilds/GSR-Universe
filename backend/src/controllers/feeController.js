const pool = require("../config/db");

// ==========================================
// CREATE FEE
// ==========================================
exports.createFee = async (req, res) => {

    try {

        const {
            student_class_mapping_id,
            academic_year_id,
            total_fee,
            paid_amount,
            pending_amount,
            due_date,
            updated_by,
            remarks
        } = req.body;

        const result = await pool.query(
            `
            INSERT INTO fees
            (
                student_class_mapping_id,
                academic_year_id,
                total_fee,
                paid_amount,
                pending_amount,
                due_date,
                updated_by,
                remarks
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *
            `,
            [
                student_class_mapping_id,
                academic_year_id,
                total_fee,
                paid_amount,
                pending_amount,
                due_date,
                updated_by,
                remarks
            ]
        );

        res.status(201).json({
            success: true,
            message: "Fee created successfully",
            data: result.rows[0]
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};

// ==========================================
// GET ALL FEES
// ==========================================
exports.getAllFees = async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT
                f.id,
                scm.id AS student_class_mapping_id,
                s.student_name,
                s.admission_no,
                COALESCE(s.primary_parent_mobile, s.secondary_parent_mobile, 'N/A') AS parent_mobile,
                COALESCE(c.class_name, '9th') AS class_name,
                COALESCE(c.section, 'A') AS section,
                COALESCE(ay.year_name, '2026-2027') AS year_name,
                COALESCE(f.total_fee, 0) AS total_fee,
                COALESCE(f.paid_amount, 0) AS paid_amount,
                COALESCE(f.pending_amount, 0) AS pending_amount,
                f.due_date,
                f.remarks
            FROM students s
            JOIN student_class_mapping scm ON s.id = scm.student_id AND scm.is_current = true
            LEFT JOIN classes c ON scm.class_id = c.id
            LEFT JOIN academic_years ay ON scm.academic_year_id = ay.id
            LEFT JOIN fees f ON f.student_class_mapping_id = scm.id
            ORDER BY s.student_name
        `);

        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// GET FEE BY ID
// ==========================================
exports.getFeeById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            "SELECT * FROM fees WHERE id=$1",
            [id]
        );
        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// UPDATE FEE
// ==========================================
exports.updateFee = async (req, res) => {
    try {
        const { id } = req.params;
        const { paid_amount, pending_amount, due_date, remarks } = req.body;

        const result = await pool.query(
            `UPDATE fees
             SET paid_amount=$1, pending_amount=$2, due_date=$3, remarks=$4
             WHERE id=$5
             RETURNING *`,
            [paid_amount, pending_amount, due_date, remarks, id]
        );

        res.json({
            success: true,
            message: "Fee updated successfully",
            data: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// DELETE FEE
// ==========================================
exports.deleteFee = async (req, res) => {
    try {
        const { id } = req.params;
        await pool.query(
            "DELETE FROM public.fees WHERE id=$1",
            [id]
        );
        res.json({
            success: true,
            message: "Fee deleted successfully"
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// ==========================================
// GET REMINDER CALL SETTINGS
// ==========================================
exports.getCallSettings = async (req, res, next) => {
    try {
        const result = await pool.query(
            "SELECT id, is_enabled, schedule_day_start, schedule_day_end, calling_number, twilio_account_sid, twilio_auth_token, caller_numbers FROM public.call_settings WHERE id = 1"
        );
        res.json({
            success: true,
            settings: result.rows[0] || null
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// UPDATE REMINDER CALL SETTINGS
// ==========================================
exports.updateCallSettings = async (req, res, next) => {
    try {
        let { is_enabled, schedule_day_start, schedule_day_end, calling_number, twilio_account_sid, twilio_auth_token, caller_numbers } = req.body;

        const isEnabledVal = is_enabled !== undefined ? Boolean(is_enabled) : true;
        const startDayVal = parseInt(schedule_day_start) || 1;
        const endDayVal = parseInt(schedule_day_end) || 28;

        let callerNumsArr = [];
        if (Array.isArray(caller_numbers) && caller_numbers.length > 0) {
            callerNumsArr = caller_numbers.map(n => String(n).trim()).filter(n => n.length > 0);
        }
        if (callerNumsArr.length === 0 && calling_number && String(calling_number).trim().length > 0) {
            callerNumsArr = [String(calling_number).trim()];
        }
        if (callerNumsArr.length === 0) {
            callerNumsArr = ["+16263851583"];
        }

        const mainCallingNumber = callerNumsArr[0];

        // Fetch existing settings to preserve SID / token if not provided in payload
        const existing = await pool.query("SELECT twilio_account_sid, twilio_auth_token FROM public.call_settings WHERE id = 1");
        const exRow = existing.rows[0] || {};

        const finalSid = (twilio_account_sid && String(twilio_account_sid).trim().length > 0) ? String(twilio_account_sid).trim() : (exRow.twilio_account_sid || '');
        const finalToken = (twilio_auth_token && String(twilio_auth_token).trim().length > 0) ? String(twilio_auth_token).trim() : (exRow.twilio_auth_token || '');

        const query = `
            UPDATE public.call_settings
            SET is_enabled = $1, 
                schedule_day_start = $2, 
                schedule_day_end = $3, 
                calling_number = $4, 
                caller_numbers = $5,
                twilio_account_sid = $6,
                twilio_auth_token = $7,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = 1 
            RETURNING id, is_enabled, schedule_day_start, schedule_day_end, calling_number, twilio_account_sid, twilio_auth_token, caller_numbers
        `;

        const result = await pool.query(query, [
            isEnabledVal,
            startDayVal,
            endDayVal,
            mainCallingNumber,
            callerNumsArr,
            finalSid,
            finalToken
        ]);

        res.json({
            success: true,
            message: "Call Settings updated successfully.",
            settings: result.rows[0]
        });
    } catch (error) {
        console.error("Error updating call settings:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// VIEW REMINDER CALL LOG HISTORY
// ==========================================
exports.getCallHistory = async (req, res, next) => {
    try {
        const result = await pool.query(
            `SELECT ch.*, s.student_name, s.admission_no, ay.year_name as academic_year
             FROM public.call_history ch
             JOIN public.students s ON ch.student_id = s.id
             JOIN public.academic_years ay ON ch.academic_year_id = ay.id
             ORDER BY ch.created_at DESC`
        );
        res.json({
            success: true,
            count: result.rows.length,
            history: result.rows
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// MANUAL TRIGGER FEE REMINDERS
// ==========================================
exports.triggerManualFeeReminders = async (req, res, next) => {
    try {
        const { runFeeRemindersCheck } = require("../services/reminderScheduler");
        await runFeeRemindersCheck(true);
        res.json({
            success: true,
            message: "Manual fee reminders trigger executed successfully."
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// PENDING FEE REPORT
// ==========================================
exports.getPendingFeeReport = async (req, res, next) => {
    try {
        const { class_name, section } = req.query;
        let query = `
            SELECT 
                s.id as student_id,
                s.student_name,
                s.admission_no,
                COALESCE(s.primary_parent_name, s.secondary_parent_name, 'Parent') as parent_name,
                COALESCE(s.primary_parent_mobile, s.parent_mobile, s.secondary_parent_mobile, 'N/A') as parent_mobile,
                COALESCE(c.class_name, s.class_name) as class_name,
                COALESCE(c.section, s.section) as section,
                COALESCE(f.total_fee, 15000.00) as total_fee,
                COALESCE(f.paid_amount, 0.00) as paid_fee,
                COALESCE(f.pending_amount, COALESCE(f.total_fee, 15000.00) - COALESCE(f.paid_amount, 0.00)) as pending_fee,
                CASE WHEN COALESCE(f.pending_amount, 15000.00) <= 0 THEN 'Paid' ELSE 'Pending' END as payment_status
            FROM public.students s
            LEFT JOIN public.student_class_mapping scm ON s.id = scm.student_id AND scm.is_current = true
            LEFT JOIN public.classes c ON scm.class_id = c.id
            LEFT JOIN public.fees f ON scm.id = f.student_class_mapping_id
            WHERE COALESCE(f.pending_amount, COALESCE(f.total_fee, 15000.00) - COALESCE(f.paid_amount, 0.00)) > 0
        `;
        const params = [];
        if (class_name && class_name.trim() !== '') {
            const rawClass = class_name.trim();
            const cleanClass = rawClass.replace(/Class\s*/i, '').replace(/th\s*/i, '').trim();
            params.push(rawClass);
            params.push(`Class ${cleanClass}`);
            params.push(`${cleanClass}th`);
            params.push(cleanClass);
            query += ` AND (c.class_name ILIKE $${params.length - 3} OR c.class_name ILIKE $${params.length - 2} OR c.class_name ILIKE $${params.length - 1} OR c.class_name ILIKE $${params.length} OR s.class_name ILIKE $${params.length - 3} OR s.class_name ILIKE $${params.length - 2} OR s.class_name ILIKE $${params.length - 1} OR s.class_name ILIKE $${params.length})`;
        }
        if (section && section.trim() !== '') {
            const rawSec = section.trim();
            const cleanSec = rawSec.replace(/Section\s*/i, '').replace(/Sec\s*/i, '').trim();
            params.push(rawSec);
            params.push(`Sec ${cleanSec}`);
            params.push(cleanSec);
            query += ` AND (c.section ILIKE $${params.length - 2} OR c.section ILIKE $${params.length - 1} OR c.section ILIKE $${params.length} OR s.section ILIKE $${params.length - 2} OR s.section ILIKE $${params.length - 1} OR s.section ILIKE $${params.length})`;
        }
        query += ` ORDER BY s.student_name ASC`;
        
        const result = await pool.query(query, params);
        res.json({
            success: true,
            count: result.rows.length,
            report: result.rows,
            data: result.rows
        });
    } catch (error) {
        console.error("Error fetching pending fee report:", error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==========================================
// UPDATE FEE BY STUDENT / MAPPING ID
// ==========================================
exports.updateFeeByMapping = async (req, res) => {
    try {
        let { scmId } = req.params;
        const { total_fee, paid_amount, pending_amount, remarks } = req.body;

        // 1. Check if scmId exists directly as mapping ID
        let mappingRes = await pool.query("SELECT id FROM student_class_mapping WHERE id = $1 LIMIT 1", [scmId]);
        
        if (mappingRes.rows.length === 0) {
            // Check if scmId is student_id
            mappingRes = await pool.query("SELECT id FROM student_class_mapping WHERE student_id = $1 AND is_current = true LIMIT 1", [scmId]);
            if (mappingRes.rows.length === 0) {
                mappingRes = await pool.query("SELECT id FROM student_class_mapping WHERE student_id = $1 ORDER BY id DESC LIMIT 1", [scmId]);
            }
        }

        if (mappingRes.rows.length === 0) {
            return res.status(400).json({
                success: false,
                message: "No class mapping found for student"
            });
        }

        const validScmId = mappingRes.rows[0].id;

        const checkQuery = await pool.query("SELECT id FROM fees WHERE student_class_mapping_id = $1 LIMIT 1", [validScmId]);
        let result;
        if (checkQuery.rows.length > 0) {
            result = await pool.query(
                `UPDATE fees
                 SET total_fee = $1, paid_amount = $2, pending_amount = $3, remarks = COALESCE($4, remarks)
                 WHERE student_class_mapping_id = $5 RETURNING *`,
                [total_fee, paid_amount, pending_amount, remarks, validScmId]
            );
        } else {
            const yearRes = await pool.query("SELECT id FROM academic_years WHERE is_current = true LIMIT 1");
            const yearId = yearRes.rows.length > 0 ? yearRes.rows[0].id : 1;
            result = await pool.query(
                `INSERT INTO fees (student_class_mapping_id, academic_year_id, total_fee, paid_amount, pending_amount, remarks, due_date, updated_by)
                 VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE + INTERVAL '30 days', 1) RETURNING *`,
                [validScmId, yearId, total_fee, paid_amount, pending_amount, remarks || 'Fee mapping initialized']
            );
        }

        res.json({
            success: true,
            message: "Fee details updated successfully",
            data: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};