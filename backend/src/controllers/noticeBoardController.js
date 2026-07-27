const pool = require("../config/db");

// ==========================================
// CREATE NOTICE
// ==========================================
exports.createNotice = async (req, res) => {

    try {

        let {
            title,
            description,
            attachment_name,
            attachment_path,
            created_by,
            target_scope
        } = req.body;

        const upperScope = (target_scope || 'ALL').toUpperCase() === 'CLASS' ? 'CLASS' : 'ALL';

        const result = await pool.query(
            `
            INSERT INTO notice_board
            (
                title,
                description,
                attachment_name,
                attachment_path,
                created_by,
                target_scope
            )
            VALUES($1,$2,$3,$4,$5,$6)
            RETURNING *;
            `,
            [
                title,
                description,
                attachment_name,
                attachment_path,
                created_by || 1,
                upperScope
            ]
        );

        const newNotice = result.rows[0];

        // Insert single notification for all students
        try {
            await pool.query(
                `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                 VALUES (NULL, NULL, 'NOTICE', $1::text, $2::text, $3::integer)`,
                [`Notice: ${title}`, description || 'New official notice posted on notice board.', parseInt(newNotice.id, 10)]
            );
        } catch (e) {
            console.error("Failed to insert parent notice notification:", e);
        }

        res.status(201).json({
            success: true,
            message: "Notice created successfully",
            data: newNotice
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
// GET ALL NOTICES
// ==========================================
exports.getAllNotices = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                n.*,
                f.faculty_name AS created_by_name
            FROM notice_board n
            JOIN faculty f
                ON n.created_by = f.id
            ORDER BY n.created_at DESC;
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
// GET NOTICE BY ID
// ==========================================
exports.getNoticeById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM notice_board WHERE id=$1",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Notice not found"
            });
        }

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
// UPDATE NOTICE
// ==========================================
exports.updateNotice = async (req, res) => {

    try {

        const { id } = req.params;

        let {
            title,
            description,
            attachment_name,
            attachment_path,
            target_scope
        } = req.body;

        const upperScope = target_scope ? ((target_scope.toUpperCase() === 'CLASS' ? 'CLASS' : 'ALL')) : 'ALL';

        const result = await pool.query(
            `
            UPDATE notice_board
            SET
                title=$1,
                description=$2,
                attachment_name=$3,
                attachment_path=$4,
                target_scope=$5
            WHERE id=$6
            RETURNING *;
            `,
            [
                title,
                description,
                attachment_name,
                attachment_path,
                upperScope,
                id
            ]
        );

        res.json({
            success: true,
            message: "Notice updated successfully",
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
// DELETE NOTICE
// ==========================================
exports.deleteNotice = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM notice_board WHERE id=$1",
            [id]
        );

        res.json({
            success: true,
            message: "Notice deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};