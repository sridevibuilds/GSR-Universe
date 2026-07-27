const pool = require("../config/db");

const normalizeHolidayType = (type) => {
    if (!type) return 'General';
    const lower = type.toString().trim().toLowerCase();
    if (lower.includes('festiv')) return 'Festival';
    if (lower.includes('vacat') || lower.includes('summer') || lower.includes('winter')) return 'Vacation';
    if (lower.includes('emerg')) return 'Emergency';
    return 'General';
};

// ==========================================
// CREATE HOLIDAY
// ==========================================
exports.createHoliday = async (req, res) => {

    try {

        let {
            holiday_name,
            description,
            start_date,
            end_date,
            holiday_type,
            created_by,
            target_scope
        } = req.body;

        // Map target scope to constraint values: 'ALL', 'CLASS'
        const upperScope = (target_scope || 'ALL').toUpperCase() === 'CLASS' ? 'CLASS' : 'ALL';
        const cleanType = normalizeHolidayType(holiday_type);

        const result = await pool.query(
            `
            INSERT INTO holidays
            (
                holiday_name,
                description,
                start_date,
                end_date,
                holiday_type,
                created_by,
                target_scope
            )
            VALUES($1,$2,$3,$4,$5,$6,$7)
            RETURNING *;
            `,
            [
                holiday_name,
                description,
                start_date,
                end_date,
                cleanType,
                created_by || 1,
                upperScope
            ]
        );

        const newHoliday = result.rows[0];

        // Insert single notification for all students
        try {
            await pool.query(
                `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                 VALUES (NULL, NULL, 'HOLIDAY', $1::text, $2::text, $3::integer)`,
                [`Holiday: ${holiday_name}`, description || `Holiday declared from ${start_date} to ${end_date}`, parseInt(newHoliday.id, 10)]
            );
        } catch (e) {
            console.error("Failed to insert parent holiday notification:", e);
        }

        res.status(201).json({
            success: true,
            message: "Holiday created successfully",
            data: newHoliday
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
// GET ALL HOLIDAYS
// ==========================================
exports.getAllHolidays = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                h.*,
                f.faculty_name AS created_by_name
            FROM holidays h
            JOIN faculty f
                ON h.created_by=f.id
            ORDER BY h.start_date DESC;
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
// GET HOLIDAY BY ID
// ==========================================
exports.getHolidayById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM holidays WHERE id=$1",
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
// UPDATE HOLIDAY
// ==========================================
exports.updateHoliday = async (req, res) => {

    try {

        const { id } = req.params;

        let {
            holiday_name,
            description,
            start_date,
            end_date,
            holiday_type,
            target_scope
        } = req.body;

        // Map target scope to constraint values: 'ALL', 'CLASS'
        const upperScope = target_scope ? ((target_scope.toUpperCase() === 'CLASS' ? 'CLASS' : 'ALL')) : 'ALL';

        const result = await pool.query(
            `
            UPDATE holidays
            SET
                holiday_name=$1,
                description=$2,
                start_date=$3,
                end_date=$4,
                holiday_type=$5,
                target_scope=$6
            WHERE id=$7
            RETURNING *;
            `,
            [
                holiday_name,
                description,
                start_date,
                end_date,
                holiday_type || 'General',
                upperScope,
                id
            ]
        );

        res.json({
            success: true,
            message: "Holiday updated successfully",
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
// DELETE HOLIDAY
// ==========================================
exports.deleteHoliday = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM holidays WHERE id=$1",
            [id]
        );

        res.json({
            success: true,
            message: "Holiday deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};