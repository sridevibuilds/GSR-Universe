const pool = require("../config/db");

// ==========================================
// CREATE ASSESSMENT RESULT
// ==========================================
exports.createAssessmentResult = async (req, res) => {
    try {

        const {
            assessment_id,
            student_class_mapping_id,
            marks_obtained,
            remarks
        } = req.body;

        const query = `
            INSERT INTO assessment_results
            (
                assessment_id,
                student_class_mapping_id,
                marks_obtained,
                remarks
            )
            VALUES ($1,$2,$3,$4)
            RETURNING *;
        `;

        const values = [
            assessment_id,
            student_class_mapping_id,
            marks_obtained,
            remarks
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: "Assessment result created successfully",
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
// GET ALL ASSESSMENT RESULTS
// ==========================================
exports.getAllAssessmentResults = async (req, res) => {

    try {

        const query = `
            SELECT
                ar.id,
                s.student_name,
                c.class_name,
                c.section,
                sub.subject_name,
                a.assessment_type,
                a.total_marks,
                ar.marks_obtained,
                ar.remarks
            FROM assessment_results ar

            JOIN assessments a
                ON ar.assessment_id = a.id

            JOIN student_class_mapping scm
                ON ar.student_class_mapping_id = scm.id

            JOIN students s
                ON scm.student_id = s.id

            JOIN classes c
                ON scm.class_id = c.id

            JOIN subjects sub
                ON a.subject_id = sub.id

            ORDER BY ar.id DESC;
        `;

        const result = await pool.query(query);

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
// GET RESULT BY ID
// ==========================================
exports.getAssessmentResultById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM assessment_results WHERE id = $1",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Assessment result not found"
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
// UPDATE RESULT
// ==========================================
exports.updateAssessmentResult = async (req, res) => {

    try {

        const { id } = req.params;

        const {
            marks_obtained,
            remarks
        } = req.body;

        const result = await pool.query(
            `
            UPDATE assessment_results
            SET
                marks_obtained=$1,
                remarks=$2
            WHERE id=$3
            RETURNING *;
            `,
            [
                marks_obtained,
                remarks,
                id
            ]
        );

        res.json({
            success: true,
            message: "Assessment result updated successfully",
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
// DELETE RESULT
// ==========================================
exports.deleteAssessmentResult = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM assessment_results WHERE id=$1",
            [id]
        );

        res.json({
            success: true,
            message: "Assessment result deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};