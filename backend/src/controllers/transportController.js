const pool = require("../config/db");

// ==========================================
// CREATE TRANSPORT
// ==========================================
exports.createTransport = async (req, res) => {

    try {

        const {
            student_class_mapping_id,
            bus_number,
            route_name,
            pickup_point,
            drop_point,
            driver_name,
            driver_mobile,
            attendant_name,
            attendant_mobile,
            remarks,
            updated_by
        } = req.body;

        const result = await pool.query(
            `
            INSERT INTO transport
            (
                student_class_mapping_id,
                bus_number,
                route_name,
                pickup_point,
                drop_point,
                driver_name,
                driver_mobile,
                attendant_name,
                attendant_mobile,
                remarks,
                updated_by
            )
            VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
            RETURNING *;
            `,
            [
                student_class_mapping_id,
                bus_number,
                route_name,
                pickup_point,
                drop_point,
                driver_name,
                driver_mobile,
                attendant_name,
                attendant_mobile,
                remarks,
                updated_by
            ]
        );

        res.status(201).json({
            success: true,
            message: "Transport details saved successfully",
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
// GET ALL TRANSPORT DETAILS
// ==========================================
exports.getAllTransport = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                t.*,
                s.student_name,
                c.class_name,
                c.section,
                f.faculty_name AS updated_by_name
            FROM transport t

            JOIN student_class_mapping scm
                ON t.student_class_mapping_id = scm.id

            JOIN students s
                ON scm.student_id = s.id

            JOIN classes c
                ON scm.class_id = c.id

            JOIN faculty f
                ON t.updated_by = f.id

            ORDER BY t.id DESC;
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
// GET TRANSPORT BY ID
// ==========================================
exports.getTransportById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM transport WHERE id=$1",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Transport record not found"
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
// UPDATE TRANSPORT
// ==========================================
exports.updateTransport = async (req, res) => {

    try {

        const { id } = req.params;

        const {
            bus_number,
            route_name,
            pickup_point,
            drop_point,
            driver_name,
            driver_mobile,
            attendant_name,
            attendant_mobile,
            remarks
        } = req.body;

        const result = await pool.query(
            `
            UPDATE transport
            SET
                bus_number=$1,
                route_name=$2,
                pickup_point=$3,
                drop_point=$4,
                driver_name=$5,
                driver_mobile=$6,
                attendant_name=$7,
                attendant_mobile=$8,
                remarks=$9,
                updated_at=NOW()
            WHERE id=$10
            RETURNING *;
            `,
            [
                bus_number,
                route_name,
                pickup_point,
                drop_point,
                driver_name,
                driver_mobile,
                attendant_name,
                attendant_mobile,
                remarks,
                id
            ]
        );

        res.json({
            success: true,
            message: "Transport updated successfully",
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
// DELETE TRANSPORT
// ==========================================
exports.deleteTransport = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM transport WHERE id=$1",
            [id]
        );

        res.json({
            success: true,
            message: "Transport deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};