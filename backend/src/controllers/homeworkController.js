const pool = require("../config/db");
const fs = require("fs");
const path = require("path");

// ==========================================
// CREATE HOMEWORK
// ==========================================
exports.createHomework = async (req, res) => {
    try {
        let {
            class_id,
            academic_year_id,
            subject_id,
            title,
            description,
            due_date,
            attachment_name,
            attachment_path,
            created_by,
            // frontend format
            class_name,
            section,
            subject_name
        } = req.body;

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

        if (!created_by) created_by = 1;

        const result = await pool.query(
            `INSERT INTO homework
            (
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                due_date,
                attachment_name,
                attachment_path,
                created_by
            )
            VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9)
            RETURNING *`,
            [
                class_id,
                academic_year_id,
                subject_id,
                title,
                description,
                due_date,
                attachment_name,
                attachment_path,
                created_by
            ]
        );

        // Notify parents of students mapped to this class
        try {
            await pool.query(
                `INSERT INTO public.parent_notifications (student_id, class_id, type, title, message, reference_id)
                 VALUES (NULL, $1::integer, 'HOMEWORK', $2::text, $3::text, $4::integer)`,
                [
                    parseInt(class_id, 10),
                    `New Homework: ${subject_name || title || 'Homework'}`,
                    `Homework assigned for ${subject_name || 'Subject'}. Title: ${title}. Due Date: ${due_date || 'N/A'}.`,
                    parseInt(result.rows[0].id, 10)
                ]
            );
        } catch (e) {
            console.error("Failed to insert parent homework notification:", e);
        }

        res.status(201).json({
            success: true,
            message: "Homework created successfully",
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
// GET ALL HOMEWORK
// ==========================================
exports.getAllHomework = async (req, res) => {

    try {

        const result = await pool.query(`
            SELECT
                h.id,
                c.class_name,
                c.section,
                ay.year_name,
                s.subject_name,
                h.title,
                h.description,
                h.due_date,
                h.attachment_name,
                f.faculty_name AS created_by
            FROM homework h
            JOIN classes c ON h.class_id=c.id
            JOIN academic_years ay ON h.academic_year_id=ay.id
            JOIN subjects s ON h.subject_id=s.id
            JOIN faculty f ON h.created_by=f.id
            ORDER BY h.id DESC
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
// GET HOMEWORK BY ID
// ==========================================
exports.getHomeworkById = async(req,res)=>{

    try{

        const {id}=req.params;

        const result=await pool.query(
            "SELECT * FROM homework WHERE id=$1",
            [id]
        );

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
// UPDATE HOMEWORK
// ==========================================
exports.updateHomework=async(req,res)=>{

    try{

        const {id}=req.params;

        const {
            title,
            description,
            due_date
        }=req.body;

        const result=await pool.query(

            `UPDATE homework
            SET
            title=$1,
            description=$2,
            due_date=$3
            WHERE id=$4
            RETURNING *`,

            [
                title,
                description,
                due_date,
                id
            ]

        );

        res.json({
            success:true,
            message:"Homework updated successfully",
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
// DELETE HOMEWORK
// ==========================================
exports.deleteHomework=async(req,res)=>{

    try{

        const {id}=req.params;

        await pool.query(
            "DELETE FROM homework WHERE id=$1",
            [id]
        );

        res.json({
            success:true,
            message:"Homework deleted successfully"
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
// GET SUBMITTED HOMEWORK LIST FOR FACULTY
// ==========================================
exports.getHomeworkSubmissions = async (req, res) => {
    try {
        const { homework_id, class_name, section } = req.query;

        let query = `
            SELECT 
                hs.id,
                hs.homework_id,
                hs.file_name,
                hs.file_path,
                hs.submitted_at,
                s.id as student_id,
                s.student_name,
                s.admission_no,
                h.title as homework_title,
                sub.subject_name
            FROM homework_submissions hs
            JOIN student_class_mapping scm ON hs.student_class_mapping_id = scm.id
            JOIN students s ON scm.student_id = s.id
            JOIN homework h ON hs.homework_id = h.id
            JOIN subjects sub ON h.subject_id = sub.id
            JOIN classes c ON scm.class_id = c.id
            WHERE 1=1
        `;
        const params = [];

        if (homework_id) {
            params.push(homework_id);
            query += ` AND hs.homework_id = $${params.length}`;
        }
        if (class_name) {
            params.push(class_name.trim());
            query += ` AND (c.class_name = $${params.length} OR c.class_name = $${params.length} || 'th')`;
        }
        if (section) {
            params.push(section.trim());
            query += ` AND c.section = $${params.length}`;
        }

        query += ` ORDER BY hs.submitted_at DESC`;

        const result = await pool.query(query, params);

        // Deduplicate submissions so each student appears only once per homework submission
        const seen = new Set();
        const deduplicatedRows = [];
        for (const row of result.rows) {
            const key = `${row.student_id || row.admission_no}_${row.homework_id}`;
            if (!seen.has(key)) {
                seen.add(key);
                deduplicatedRows.push(row);
            }
        }

        res.json({
            success: true,
            count: deduplicatedRows.length,
            data: deduplicatedRows
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
// VIEW SUBMITTED HOMEWORK FILE
// ==========================================
exports.viewHomeworkSubmission = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            "SELECT file_name, file_path FROM homework_submissions WHERE id = $1",
            [id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Homework submission record not found." });
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
// DOWNLOAD SUBMITTED HOMEWORK FILE
// ==========================================
exports.downloadHomeworkSubmission = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query(
            "SELECT file_name, file_path FROM homework_submissions WHERE id = $1",
            [id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Homework submission record not found." });
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