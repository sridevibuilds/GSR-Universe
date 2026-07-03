const pool = require("../config/db");

// ===============================
// Create Assessment
// ===============================
exports.createAssessment = async (req, res) => {
    try {
        const {
            class_id,
            academic_year_id,
            subject_id,
            assessment_type,
            total_marks,
            assessment_date,
            created_by
        } = req.body;

        const query = `
            INSERT INTO assessments
            (
                class_id,
                academic_year_id,
                subject_id,
                assessment_type,
                total_marks,
                assessment_date,
                created_by
            )
            VALUES ($1,$2,$3,$4,$5,$6,$7)
            RETURNING *;
        `;

        const values = [
            class_id,
            academic_year_id,
            subject_id,
            assessment_type,
            total_marks,
            assessment_date,
            created_by
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: "Assessment created successfully",
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

// ===============================
// Get All Assessments
// ===============================
exports.getAllAssessments = async (req, res) => {
    try {

        const query = `
            SELECT
                a.id,
                c.class_name,
                c.section,
                ay.year_name,
                s.subject_name,
                a.assessment_type,
                a.total_marks,
                a.assessment_date,
                f.faculty_name AS created_by
            FROM assessments a
            JOIN classes c
                ON a.class_id = c.id
            JOIN academic_years ay
                ON a.academic_year_id = ay.id
            JOIN subjects s
                ON a.subject_id = s.id
            JOIN faculty f
                ON a.created_by = f.id
            ORDER BY a.id DESC;
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

// ===============================
// Get Assessment By ID
// ===============================
exports.getAssessmentById = async (req, res) => {

    try {

        const { id } = req.params;

        const result = await pool.query(
            "SELECT * FROM assessments WHERE id = $1",
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Assessment not found"
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

// ===============================
// Update Assessment
// ===============================
exports.updateAssessment = async (req, res) => {

    try {

        const { id } = req.params;

        const {
            class_id,
            academic_year_id,
            subject_id,
            assessment_type,
            total_marks,
            assessment_date
        } = req.body;

        const query = `
            UPDATE assessments
            SET
                class_id = $1,
                academic_year_id = $2,
                subject_id = $3,
                assessment_type = $4,
                total_marks = $5,
                assessment_date = $6
            WHERE id = $7
            RETURNING *;
        `;

        const values = [
            class_id,
            academic_year_id,
            subject_id,
            assessment_type,
            total_marks,
            assessment_date,
            id
        ];

        const result = await pool.query(query, values);

        res.json({
            success: true,
            message: "Assessment updated successfully",
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

// ===============================
// Delete Assessment
// ===============================
exports.deleteAssessment = async (req, res) => {

    try {

        const { id } = req.params;

        await pool.query(
            "DELETE FROM assessments WHERE id = $1",
            [id]
        );

        res.json({
            success: true,
            message: "Assessment deleted successfully"
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            message: err.message
        });

    }

};