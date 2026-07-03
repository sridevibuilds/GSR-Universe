const pool = require("../config/db");

// ==========================================
// CREATE ANNOUNCEMENT
// ==========================================
exports.createAnnouncement = async (req, res) => {
    try {
        const {
            class_id,
            academic_year_id,
            title,
            message,
            priority,
            created_by,
            target_scope
        } = req.body;

        const result = await pool.query(
            `
            INSERT INTO announcements
            (
                class_id,
                academic_year_id,
                title,
                message,
                priority,
                created_by,
                target_scope
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7)
            RETURNING *;
            `,
            [
                class_id,
                academic_year_id,
                title,
                message,
                priority,
                created_by,
                target_scope
            ]
        );

        res.status(201).json({
            success: true,
            message: "Announcement created successfully",
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
// GET ALL ANNOUNCEMENTS
// ==========================================
exports.getAllAnnouncements = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                a.id,
                c.class_name,
                c.section,
                ay.year_name,
                a.title,
                a.message,
                a.priority,
                a.target_scope,
                a.created_at,
                f.faculty_name AS created_by

            FROM announcements a

            JOIN classes c
                ON a.class_id = c.id

            JOIN academic_years ay
                ON a.academic_year_id = ay.id

            JOIN faculty f
                ON a.created_by = f.id

            ORDER BY a.id DESC
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
// GET ANNOUNCEMENT BY ID
// ==========================================
exports.getAnnouncementById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM announcements WHERE id=$1",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Announcement not found"
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
// UPDATE ANNOUNCEMENT
// ==========================================
exports.updateAnnouncement = async (req, res) => {

    try {

        const { id } = req.params;

        const {
            title,
            message,
            priority,
            target_scope
        } = req.body;

        const result = await pool.query(
            `
            UPDATE announcements
            SET
                title=$1,
                message=$2,
                priority=$3,
                target_scope=$4
            WHERE id=$5
            RETURNING *;
            `,
            [
                title,
                message,
                priority,
                target_scope,
                id
            ]
        );

        res.json({
            success: true,
            message: "Announcement updated successfully",
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
// DELETE ANNOUNCEMENT
// ==========================================
exports.deleteAnnouncement = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM announcements WHERE id=$1",
            [id]
        );

        res.json({
            success: true,
            message: "Announcement deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};