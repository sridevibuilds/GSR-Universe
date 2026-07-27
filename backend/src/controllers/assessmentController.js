const pool = require("../config/db");

// ===============================
// Create Assessment
// ===============================
exports.createAssessment = async (req, res) => {
    const client = await pool.connect();
    try {
        await client.query("BEGIN");

        let {
            class_id,
            academic_year_id,
            subject_id,
            assessment_type,
            total_marks,
            assessment_date,
            created_by,
            // frontend payload parameters
            title,
            subject,
            max_marks,
            class_name,
            section,
            student_marks // Array of { student_class_mapping_id, marks_obtained, remarks }
        } = req.body;

        // Map frontend fields
        if (title) assessment_type = title;
        if (max_marks) total_marks = max_marks;

        // Resolve academic_year_id
        if (!academic_year_id) {
            const yearRes = await client.query("SELECT id FROM academic_years WHERE is_current = true LIMIT 1");
            if (yearRes.rows.length > 0) {
                academic_year_id = yearRes.rows[0].id;
            } else {
                academic_year_id = 1;
            }
        }

        // Resolve class_id using class_name and section
        if (!class_id && class_name) {
            const cleanClassName = class_name.trim();
            const cleanSection = (section || 'A').trim();
            let classRes = await client.query(
                "SELECT id FROM classes WHERE (class_name = $1 OR class_name = $2) AND section = $3 LIMIT 1",
                [cleanClassName, cleanClassName.replace("Class ", "") + "th", cleanSection]
            );
            if (classRes.rows.length > 0) {
                class_id = classRes.rows[0].id;
            } else {
                const insertClass = await client.query(
                    "INSERT INTO classes (class_name, section, academic_year) VALUES ($1, $2, (SELECT year_name FROM academic_years WHERE id = $3)) RETURNING id",
                    [cleanClassName, cleanSection, academic_year_id]
                );
                class_id = insertClass.rows[0].id;
            }
        }

        // Resolve subject_id using subject
        if (!subject_id && subject) {
            const cleanSub = subject.trim();
            let subRes = await client.query("SELECT id FROM subjects WHERE subject_name ILIKE $1 LIMIT 1", [cleanSub]);
            if (subRes.rows.length > 0) {
                subject_id = subRes.rows[0].id;
            } else {
                const insertSub = await client.query("INSERT INTO subjects (subject_name) VALUES ($1) RETURNING id", [cleanSub]);
                subject_id = insertSub.rows[0].id;
            }
        }

        if (!created_by) created_by = 1;

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
            RETURNING id;
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

        const result = await client.query(query, values);
        const newId = result.rows[0].id;

        // Save student marks if provided
        if (student_marks && Array.isArray(student_marks)) {
            for (let sm of student_marks) {
                let obtained = parseFloat(sm.marks_obtained);
                if (isNaN(obtained) || obtained < 0) obtained = 0;
                if (obtained > total_marks) obtained = total_marks;

                await client.query(
                    `INSERT INTO assessment_results (assessment_id, student_class_mapping_id, marks_obtained, remarks)
                     VALUES ($1, $2, $3, $4)
                     ON CONFLICT (assessment_id, student_class_mapping_id)
                     DO UPDATE SET marks_obtained = EXCLUDED.marks_obtained, remarks = EXCLUDED.remarks`,
                    [newId, sm.student_class_mapping_id, obtained, sm.remarks || 'Good']
                );
            }
        }

        await client.query("COMMIT");

        const details = await pool.query(`
            SELECT
                a.id,
                COALESCE(c.class_name, '9th') AS class_name,
                COALESCE(c.section, 'A') AS section,
                COALESCE(ay.year_name, '2026-2027') AS year_name,
                COALESCE(s.subject_name, 'General') AS subject_name,
                COALESCE(s.subject_name, 'General') AS subject,
                COALESCE(a.assessment_type, 'Assessment Test') AS assessment_type,
                COALESCE(a.assessment_type, 'Assessment Test') AS title,
                COALESCE(a.total_marks, 50) AS total_marks,
                COALESCE(a.total_marks, 50) AS max_marks,
                a.assessment_date,
                a.created_at,
                COALESCE(f.faculty_name, 'Faculty') AS created_by
            FROM assessments a
            LEFT JOIN classes c ON a.class_id = c.id
            LEFT JOIN academic_years ay ON a.academic_year_id = ay.id
            LEFT JOIN subjects s ON a.subject_id = s.id
            LEFT JOIN faculty f ON a.created_by = f.id
            WHERE a.id = $1
        `, [newId]);

        res.status(201).json({
            success: true,
            message: "Assessment and marks saved successfully",
            data: details.rows[0]
        });

    } catch (err) {
        await client.query("ROLLBACK");
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    } finally {
        client.release();
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
                COALESCE(c.class_name, '9th') AS class_name,
                COALESCE(c.section, 'A') AS section,
                COALESCE(ay.year_name, '2026-2027') AS year_name,
                COALESCE(s.subject_name, 'General') AS subject_name,
                COALESCE(s.subject_name, 'General') AS subject,
                COALESCE(a.assessment_type, 'Assessment Test') AS assessment_type,
                COALESCE(a.assessment_type, 'Assessment Test') AS title,
                COALESCE(a.total_marks, 50) AS total_marks,
                COALESCE(a.total_marks, 50) AS max_marks,
                a.assessment_date,
                a.created_at,
                COALESCE(f.faculty_name, 'Faculty') AS created_by
            FROM assessments a
            LEFT JOIN classes c ON a.class_id = c.id
            LEFT JOIN academic_years ay ON a.academic_year_id = ay.id
            LEFT JOIN subjects s ON a.subject_id = s.id
            LEFT JOIN faculty f ON a.created_by = f.id
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

        let {
            class_id,
            academic_year_id,
            subject_id,
            assessment_type,
            total_marks,
            assessment_date,
            // frontend payload parameters
            title,
            subject,
            max_marks,
            class_name,
            section
        } = req.body;

        // Map frontend fields
        if (title) assessment_type = title;
        if (max_marks) total_marks = max_marks;

        // Resolve academic_year_id
        if (!academic_year_id) {
            const yearRes = await pool.query("SELECT id FROM academic_years WHERE is_current = true LIMIT 1");
            if (yearRes.rows.length > 0) {
                academic_year_id = yearRes.rows[0].id;
            } else {
                academic_year_id = 1;
            }
        }

        // Resolve class_id using class_name and section
        if (!class_id && class_name) {
            const cleanClassName = class_name.trim();
            const cleanSection = (section || 'A').trim();
            let classRes = await pool.query(
                "SELECT id FROM classes WHERE (class_name = $1 OR class_name = $2) AND section = $3 LIMIT 1",
                [cleanClassName, cleanClassName.replace("Class ", "") + "th", cleanSection]
            );
            if (classRes.rows.length > 0) {
                class_id = classRes.rows[0].id;
            } else {
                const insertClass = await pool.query(
                    "INSERT INTO classes (class_name, section, academic_year) VALUES ($1, $2, (SELECT year_name FROM academic_years WHERE id = $3)) RETURNING id",
                    [cleanClassName, cleanSection, academic_year_id]
                );
                class_id = insertClass.rows[0].id;
            }
        }

        // Resolve subject_id using subject
        if (!subject_id && subject) {
            const cleanSub = subject.trim();
            let subRes = await pool.query("SELECT id FROM subjects WHERE subject_name ILIKE $1 LIMIT 1", [cleanSub]);
            if (subRes.rows.length > 0) {
                subject_id = subRes.rows[0].id;
            } else {
                const insertSub = await pool.query("INSERT INTO subjects (subject_name) VALUES ($1) RETURNING id", [cleanSub]);
                subject_id = insertSub.rows[0].id;
            }
        }

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

        const details = await pool.query(`
            SELECT
                a.id,
                c.class_name,
                c.section,
                ay.year_name,
                s.subject_name,
                s.subject_name AS subject,
                a.assessment_type,
                a.assessment_type AS title,
                a.total_marks,
                a.total_marks AS max_marks,
                a.assessment_date,
                a.created_at,
                f.faculty_name AS created_by
            FROM assessments a
            JOIN classes c ON a.class_id = c.id
            JOIN academic_years ay ON a.academic_year_id = ay.id
            JOIN subjects s ON a.subject_id = s.id
            JOIN faculty f ON a.created_by = f.id
            WHERE a.id = $1
        `, [id]);

        res.json({
            success: true,
            message: "Assessment updated successfully",
            data: details.rows[0]
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
    const client = await pool.connect();
    try {
        const { id } = req.params;
        await client.query("BEGIN");
        await client.query("DELETE FROM assessment_results WHERE assessment_id = $1", [id]);
        await client.query("DELETE FROM assessments WHERE id = $1", [id]);
        await client.query("COMMIT");

        res.json({
            success: true,
            message: "Assessment and student marks deleted successfully"
        });
    } catch (err) {
        await client.query("ROLLBACK");
        console.error(err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    } finally {
        client.release();
    }
};