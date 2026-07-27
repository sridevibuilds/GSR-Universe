const pool = require("../config/db");
const fs = require("fs");
const path = require("path");

// ==========================================
// CREATE ASSIGNMENT
// ==========================================
exports.createAssignment = async (req, res) => {
    try {

        let {
            class_id,
            academic_year_id,
            subject_id,
            title,
            description,
            submission_date,
            max_marks,
            attachment_name,
            attachment_path,
            created_by,
            class_name,
            section,
            subject_name
        } = req.body;

        const maxMarksVal = parseFloat(max_marks) || 20.00;

        if (!academic_year_id) {
            const yearRes = await pool.query("SELECT id FROM academic_years WHERE is_current = true LIMIT 1");
            academic_year_id = yearRes.rows.length > 0 ? yearRes.rows[0].id : 1;
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

        // Resolve subject_id using subject_name
        if (!subject_id && subject_name) {
            const cleanSub = subject_name.trim();
            let subRes = await pool.query("SELECT id FROM subjects WHERE subject_name ILIKE $1 LIMIT 1", [cleanSub]);
            if (subRes.rows.length > 0) {
                subject_id = subRes.rows[0].id;
            } else {
                const insertSub = await pool.query("INSERT INTO subjects (subject_name) VALUES ($1) RETURNING id", [cleanSub]);
                subject_id = insertSub.rows[0].id;
            }
        }

        const result = await pool.query(
            `
            INSERT INTO assignments
            (
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                submission_date,
                max_marks,
                attachment_name,
                attachment_path,
                created_by
            )
            VALUES
            ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
            RETURNING *;
            `,
            [
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                submission_date,
                maxMarksVal,
                attachment_name,
                attachment_path,
                created_by || 1
            ]
        );

        // Notify parents of students mapped to this class
        try {
            await pool.query(
                `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                 VALUES (NULL, $1::integer, 'ASSIGNMENT', $2::text, $3::text, $4::integer)`,
                [
                    parseInt(class_id, 10),
                    `New Assignment: ${title || 'Assignment'}`,
                    `New assignment published for ${subject_name || 'Subject'}. Submission Date: ${submission_date || 'N/A'}. Max Marks: ${maxMarksVal}.`,
                    parseInt(result.rows[0].id, 10)
                ]
            );
        } catch (e) {
            console.error("Failed to insert parent assignment notification:", e);
        }

        res.status(201).json({
            success: true,
            message: "Assignment created successfully",
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
// GET ALL ASSIGNMENTS
// ==========================================
exports.getAllAssignments = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                a.id,
                c.class_name,
                c.section,
                ay.year_name,
                s.subject_name,
                a.title,
                a.description,
                a.submission_date,
                a.attachment_name,
                a.attachment_path,
                COALESCE(f.faculty_name, 'Faculty') AS created_by
            FROM assignments a
            LEFT JOIN classes c ON a.class_id = c.id
            LEFT JOIN academic_years ay ON a.academic_year_id = ay.id
            LEFT JOIN subjects s ON a.subject_id = s.id
            LEFT JOIN faculty f ON a.created_by = f.id
            ORDER BY a.id DESC
        `);

        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });

    } catch(err){

        console.error(err);

        res.status(500).json({
            success:false,
            message:err.message
        });

    }

};

// ==========================================
// GET ASSIGNMENT BY ID
// ==========================================
exports.getAssignmentById = async(req,res)=>{

    try{

        const {id}=req.params;

        const result=await pool.query(
            "SELECT * FROM assignments WHERE id=$1",
            [id]
        );

        if(result.rows.length===0){

            return res.status(404).json({
                success:false,
                message:"Assignment not found"
            });

        }

        res.json({
            success:true,
            data:result.rows[0]
        });

    }catch(err){

        console.error(err);

        res.status(500).json({
            success:false,
            message:err.message
        });

    }

};

// ==========================================
// UPDATE ASSIGNMENT
// ==========================================
exports.updateAssignment=async(req,res)=>{

    try{

        const {id}=req.params;

        const {
            class_id,
            academic_year_id,
            subject_id,
            title,
            description,
            submission_date,
            attachment_name,
            attachment_path,
            max_marks
        }=req.body;

        const result=await pool.query(
            `UPDATE assignments
            SET
                class_id=$1,
                academic_year_id=$2,
                subject_id=$3,
                title=$4,
                description=$5,
                submission_date=$6,
                attachment_name=$7,
                attachment_path=$8,
                max_marks=$9
            WHERE id=$10
            RETURNING *`,
            [
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                submission_date,
                attachment_name,
                attachment_path,
                max_marks,
                id
            ]
        );

        res.json({
            success:true,
            message:"Assignment updated successfully",
            data:result.rows[0]
        });

    }catch(err){

        console.error(err);

        res.status(500).json({
            success:false,
            message:err.message
        });

    }

};

// ==========================================
// DELETE ASSIGNMENT
// ==========================================
exports.deleteAssignment=async(req,res)=>{

    try{

        const{id}=req.params;

        await pool.query(
            "DELETE FROM assignments WHERE id=$1",
            [id]
        );

        res.json({
            success:true,
            message:"Assignment deleted successfully"
        });

    }catch(err){

        console.error(err);

        res.status(500).json({
            success:false,
            message:err.message
        });

    }

};

// ==========================================
// GET SUBMITTED ASSIGNMENTS LIST FOR FACULTY
// ==========================================
exports.getAssignmentSubmissions = async (req, res) => {
    try {
        const { assignment_id, class_name, section } = req.query;

        let query = `
            SELECT 
                asub.id,
                asub.assignment_id,
                asub.file_name,
                asub.file_path,
                asub.submitted_at,
                asub.submission_status,
                asub.obtained_marks,
                COALESCE(asub.max_marks, a.max_marks, 20.00) as max_marks,
                s.id as student_id,
                s.student_name,
                s.admission_no,
                a.title as assignment_title,
                sub.subject_name
            FROM assignment_submissions asub
            JOIN student_class_mapping scm ON asub.student_class_mapping_id = scm.id AND scm.is_current = true
            JOIN students s ON scm.student_id = s.id
            JOIN assignments a ON asub.assignment_id = a.id
            LEFT JOIN subjects sub ON a.subject_id = sub.id
            LEFT JOIN classes c ON scm.class_id = c.id
            WHERE 1=1
        `;
        const params = [];

        if (assignment_id) {
            params.push(assignment_id);
            query += ` AND asub.assignment_id = $${params.length}`;
        }
        if (class_name) {
            params.push(class_name.trim());
            query += ` AND (c.class_name = $${params.length} OR c.class_name = $${params.length} || 'th')`;
        }
        if (section) {
            params.push(section.trim());
            query += ` AND c.section = $${params.length}`;
        }

        query += ` ORDER BY asub.submitted_at DESC`;

        const result = await pool.query(query, params);

        res.json({
            success: true,
            count: result.rows.length,
            data: result.rows
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, message: err.message });
    }
};

// ==========================================
// GRADE ASSIGNMENT SUBMISSION (FACULTY)
// ==========================================
exports.gradeAssignmentSubmission = async (req, res) => {
    try {
        let { submission_id, student_id, student_class_mapping_id, assignment_id, obtained_marks, max_marks, remarks, graded_by } = req.body;

        const numObtained = parseFloat(obtained_marks);
        const numMax = parseFloat(max_marks) || 20.0;

        if (isNaN(numObtained)) {
            return res.status(400).json({ success: false, message: "Valid obtained_marks is required" });
        }

        let targetSubmissionId = submission_id;

        if (!targetSubmissionId) {
            let scmId = student_class_mapping_id;
            if (!scmId && student_id) {
                const scmRes = await pool.query(
                    `SELECT id FROM student_class_mapping WHERE student_id = $1 ORDER BY id DESC LIMIT 1`,
                    [student_id]
                );
                if (scmRes.rows.length > 0) {
                    scmId = scmRes.rows[0].id;
                }
            }

            if (scmId && assignment_id) {
                const existingRes = await pool.query(
                    `SELECT id FROM assignment_submissions WHERE assignment_id = $1 AND student_class_mapping_id = $2`,
                    [assignment_id, scmId]
                );
                if (existingRes.rows.length > 0) {
                    targetSubmissionId = existingRes.rows[0].id;
                } else {
                    const insertRes = await pool.query(
                        `INSERT INTO assignment_submissions (assignment_id, student_class_mapping_id, submission_status, obtained_marks, max_marks, remarks, graded_by, graded_at)
                         VALUES ($1, $2, 'Graded', $3, $4, $5, $6, CURRENT_TIMESTAMP)
                         RETURNING *`,
                        [assignment_id, scmId, numObtained, numMax, remarks || 'Graded by Faculty', graded_by || 1]
                    );
                    return res.json({
                        success: true,
                        message: "Assignment marks saved successfully",
                        data: insertRes.rows[0]
                    });
                }
            }
        }

        if (!targetSubmissionId) {
            return res.status(400).json({ success: false, message: "submission_id or (student_id & assignment_id) is required" });
        }

        const result = await pool.query(
            `UPDATE public.assignment_submissions 
             SET obtained_marks = $1, max_marks = $2, remarks = COALESCE($3, remarks), submission_status = 'Graded', graded_by = $4, graded_at = CURRENT_TIMESTAMP 
             WHERE id = $5
             RETURNING *`,
            [
                numObtained,
                numMax,
                remarks || null,
                graded_by || 1,
                targetSubmissionId
            ]
        );

        res.json({
            success: true,
            message: "Assignment marks saved successfully",
            data: result.rows[0]
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, message: err.message });
    }
};

const ensureFallbackPdf = () => {
    const fallbackPath = path.join(__dirname, "../uploads/sample_submission.pdf");
    if (!fs.existsSync(fallbackPath)) {
        const uploadDir = path.dirname(fallbackPath);
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        const samplePdfContent = `%PDF-1.4
1 0 obj <</Type /Catalog /Pages 2 0 R>> endobj
2 0 obj <</Type /Pages /Kids [3 0 R] /Count 1>> endobj
3 0 obj <</Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R>> endobj
4 0 obj <</Length 55>> stream
BT /F1 12 Tf 100 700 TD (GSR Universe Student Submission Document) Tj ET
endstream endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000206 00000 n 
trailer <</Size 5 /Root 1 0 R>>
startxref
312
%%EOF`;
        fs.writeFileSync(fallbackPath, samplePdfContent);
    }
    return fallbackPath;
};

const resolveFilePath = (filePath) => {
    if (!filePath || typeof filePath !== 'string' || !filePath.trim()) return null;
    const clean = filePath.trim();
    if (path.isAbsolute(clean) && fs.existsSync(clean)) return clean;

    const baseName = path.basename(clean);
    const relativePath = clean.startsWith('/') ? clean.slice(1) : clean;

    const candidates = [
        path.join(__dirname, "../uploads", baseName),
        path.join(__dirname, "uploads", baseName),
        path.join(process.cwd(), "src/uploads", baseName),
        path.join(process.cwd(), "uploads", baseName),
        path.join(__dirname, "..", relativePath),
        path.join(process.cwd(), relativePath)
    ];

    for (const cand of candidates) {
        if (cand && fs.existsSync(cand)) {
            return cand;
        }
    }
    return null;
};

// ==========================================
// VIEW SUBMITTED ASSIGNMENT FILE
// ==========================================
exports.viewAssignmentSubmission = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            "SELECT file_name, file_path FROM assignment_submissions WHERE id = $1",
            [id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Assignment submission record not found." });
        }
        const submission = result.rows[0];
        const absolutePath = resolveFilePath(submission.file_path);

        if (!absolutePath) {
            return res.status(404).json({ success: false, message: "Student submitted PDF file not found on server." });
        }

        res.setHeader("Content-Type", "application/pdf");
        res.setHeader("Content-Disposition", `inline; filename="${submission.file_name || 'submission.pdf'}"`);
        res.sendFile(absolutePath);
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, message: err.message });
    }
};

// ==========================================
// DOWNLOAD SUBMITTED ASSIGNMENT FILE
// ==========================================
exports.downloadAssignmentSubmission = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            "SELECT file_name, file_path FROM assignment_submissions WHERE id = $1",
            [id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Assignment submission record not found." });
        }
        const submission = result.rows[0];
        const absolutePath = resolveFilePath(submission.file_path);

        if (!absolutePath) {
            return res.status(404).json({ success: false, message: "Student submitted PDF file not found on server." });
        }

        res.download(absolutePath, submission.file_name || path.basename(absolutePath));
    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, message: err.message });
    }
};