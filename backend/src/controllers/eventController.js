const pool = require("../config/db");

// ==========================================
// CREATE EVENT
// ==========================================
exports.createEvent = async (req, res) => {
    try {
        let {
            title,
            description,
            event_date,
            event_time,
            venue,
            attachment_name,
            attachment_path,
            created_by,
            event_status,
            target_scope
        } = req.body;

        // Map status to constraint values: 'Upcoming', 'Completed', 'Cancelled'
        let mappedStatus = 'Upcoming';
        if (event_status) {
            const statusUpper = event_status.trim().toUpperCase();
            if (statusUpper === 'COMPLETED') {
                mappedStatus = 'Completed';
            } else if (statusUpper === 'CANCELLED' || statusUpper === 'CANCELED') {
                mappedStatus = 'Cancelled';
            } else {
                mappedStatus = 'Upcoming'; // Default Scheduled/Upcoming to 'Upcoming'
            }
        }

        // Map target scope to constraint values: 'ALL', 'CLASS'
        const upperScope = (target_scope || 'ALL').toUpperCase() === 'CLASS' ? 'CLASS' : 'ALL';

        const result = await pool.query(
            `INSERT INTO events
            (
                title,
                description,
                event_date,
                event_time,
                venue,
                attachment_name,
                attachment_path,
                created_by,
                event_status,
                target_scope
            )
            VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
            RETURNING *`,
            [
                title,
                description,
                event_date,
                event_time,
                venue,
                attachment_name,
                attachment_path,
                created_by || 1,
                mappedStatus,
                upperScope
            ]
        );

        const newEvent = result.rows[0];

        // Insert single notification for all students
        try {
            await pool.query(
                `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                 VALUES (NULL, NULL, 'EVENT', $1::text, $2::text, $3::integer)`,
                [`Upcoming Event: ${title}`, description || `New event scheduled on ${event_date || 'upcoming dates'}.`, parseInt(newEvent.id, 10)]
            );
        } catch (e) {
            console.error("Failed to insert parent event notification:", e);
        }

        res.status(201).json({
            success: true,
            message: "Event created successfully",
            data: newEvent
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
// GET ALL EVENTS
// ==========================================
exports.getAllEvents = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                e.*,
                f.faculty_name AS created_by_name
            FROM events e
            JOIN faculty f
                ON e.created_by=f.id
            ORDER BY e.event_date DESC;
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
// GET EVENT BY ID
// ==========================================
exports.getEventById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM events WHERE id=$1",
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
// UPDATE EVENT
// ==========================================
exports.updateEvent = async (req, res) => {

    try {

        const { id } = req.params;

        let {
            title,
            description,
            event_date,
            event_time,
            venue,
            event_status,
            target_scope
        } = req.body;

        // Map status to constraint values: 'Upcoming', 'Completed', 'Cancelled'
        let mappedStatus = 'Upcoming';
        if (event_status) {
            const statusUpper = event_status.trim().toUpperCase();
            if (statusUpper === 'COMPLETED') {
                mappedStatus = 'Completed';
            } else if (statusUpper === 'CANCELLED' || statusUpper === 'CANCELED') {
                mappedStatus = 'Cancelled';
            } else {
                mappedStatus = 'Upcoming';
            }
        }

        // Map target scope to constraint values: 'ALL', 'CLASS'
        const upperScope = target_scope ? ((target_scope.toUpperCase() === 'CLASS' ? 'CLASS' : 'ALL')) : 'ALL';

        const result = await pool.query(
            `
            UPDATE events
            SET
                title=$1,
                description=$2,
                event_date=$3,
                event_time=$4,
                venue=$5,
                event_status=$6,
                target_scope=$7
            WHERE id=$8
            RETURNING *;
            `,
            [
                title,
                description,
                event_date,
                event_time,
                venue,
                mappedStatus,
                upperScope,
                id
            ]
        );

        res.json({
            success: true,
            message: "Event updated successfully",
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
// DELETE EVENT
// ==========================================
exports.deleteEvent = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM events WHERE id=$1",
            [id]
        );

        res.json({
            success: true,
            message: "Event deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};