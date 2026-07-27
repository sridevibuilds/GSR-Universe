const pool = require("../src/config/db");
const fs = require("fs");
const path = require("path");
const homeworkController = require("../src/controllers/homeworkController");
const assignmentController = require("../src/controllers/assignmentController");

async function verifyPdfSeparationPipeline() {
    try {
        console.log("=== STARTING COMPLETE ROOT CAUSE PDF SEPARATION PIPELINE TEST ===");

        // Ensure test PDF files physically exist in backend/uploads
        const uploadsDir = path.join(__dirname, "../uploads");
        if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

        const hwFacultyPdfPath = path.join(uploadsDir, "homework_math.pdf");
        const hwStudentPdfPath = path.join(uploadsDir, "rahul_solution.pdf");
        const assignFacultyPdfPath = path.join(uploadsDir, "assignment_physics.pdf");
        const assignStudentPdfPath = path.join(uploadsDir, "rahul_assignment_solution.pdf");

        const samplePdfContent = `%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kinds [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /Resources <<>> >> endobj
xref
0 4
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
trailer << /Size 4 /Root 1 0 R >>
startxref
178
%%EOF`;

        fs.writeFileSync(hwFacultyPdfPath, samplePdfContent + "\n% FACULTY_MATH");
        fs.writeFileSync(hwStudentPdfPath, samplePdfContent + "\n% RAHUL_SOLUTION");
        fs.writeFileSync(assignFacultyPdfPath, samplePdfContent + "\n% FACULTY_PHYSICS");
        fs.writeFileSync(assignStudentPdfPath, samplePdfContent + "\n% RAHUL_ASSIGNMENT_SOLUTION");

        // 1. Faculty uploads Homework
        const hwRes = await pool.query(
            `INSERT INTO homework (class_id, academic_year_id, subject_id, title, description, due_date, attachment_name, attachment_path, created_by, status)
             VALUES (1, 1, 1, 'Math Homework 101', 'Solve section A', '2026-08-01', 'homework_math.pdf', '/uploads/homework_math.pdf', 1, 'published')
             RETURNING id`
        );
        const hwId = hwRes.rows[0].id;
        console.log(`1. Faculty Created Homework ID: ${hwId} with attachment: /uploads/homework_math.pdf`);

        // 2. Student Submits Homework
        const hwSubRes = await pool.query(
            `INSERT INTO homework_submissions (homework_id, student_class_mapping_id, file_name, file_path, submitted_at)
             VALUES ($1, 1, 'rahul_solution.pdf', '/uploads/rahul_solution.pdf', NOW())
             RETURNING id`,
            [hwId]
        );
        const hwSubId = hwSubRes.rows[0].id;
        console.log(`2. Student Submits Homework Submission ID: ${hwSubId} with file: /uploads/rahul_solution.pdf`);

        // 3. Verify Faculty View Submission API for Homework
        let servedContent = "";
        const mockResView = {
            setHeader: function(k, v) { console.log(`[Header] ${k}: ${v}`); },
            sendFile: function(filePath) {
                servedContent = fs.readFileSync(filePath, "utf8");
                console.log(`[sendFile] Served file: ${filePath}`);
            },
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { console.log("JSON:", data); }
        };

        await homeworkController.viewHomeworkSubmission({ params: { id: hwSubId } }, mockResView);

        if (servedContent.includes("% RAHUL_SOLUTION") && !servedContent.includes("% FACULTY_MATH")) {
            console.log("✔ SUCCESS: Faculty Submission API returned ONLY Student Submitted PDF (rahul_solution.pdf)!");
        } else {
            console.error("❌ FAILED: Faculty Submission API returned WRONG file!");
            process.exit(1);
        }

        // 4. Faculty Uploads Assignment
        const assignRes = await pool.query(
            `INSERT INTO assignments (class_id, academic_year_id, subject_id, title, description, submission_date, attachment_name, attachment_path, created_by, max_marks)
             VALUES (1, 1, 1, 'Physics Lab Project', 'Complete lab report', '2026-08-05', 'assignment_physics.pdf', '/uploads/assignment_physics.pdf', 1, 50.00)
             RETURNING id`
        );
        const assignId = assignRes.rows[0].id;
        console.log(`\n4. Faculty Created Assignment ID: ${assignId} with attachment: /uploads/assignment_physics.pdf`);

        // 5. Student Submits Assignment
        const assignSubRes = await pool.query(
            `INSERT INTO assignment_submissions (assignment_id, student_class_mapping_id, file_name, file_path, submitted_at, submission_status)
             VALUES ($1, 1, 'rahul_assignment_solution.pdf', '/uploads/rahul_assignment_solution.pdf', NOW(), 'Submitted')
             RETURNING id`,
            [assignId]
        );
        const assignSubId = assignSubRes.rows[0].id;
        console.log(`5. Student Submits Assignment Submission ID: ${assignSubId} with file: /uploads/rahul_assignment_solution.pdf`);

        // 6. Verify Faculty View Submission API for Assignment
        let servedAssignContent = "";
        const mockAssignResView = {
            setHeader: function(k, v) { console.log(`[Header] ${k}: ${v}`); },
            sendFile: function(filePath) {
                servedAssignContent = fs.readFileSync(filePath, "utf8");
                console.log(`[sendFile] Served file: ${filePath}`);
            },
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { console.log("JSON:", data); }
        };

        await assignmentController.viewAssignmentSubmission({ params: { id: assignSubId } }, mockAssignResView);

        if (servedAssignContent.includes("% RAHUL_ASSIGNMENT_SOLUTION") && !servedAssignContent.includes("% FACULTY_PHYSICS")) {
            console.log("✔ SUCCESS: Faculty Assignment Submission API returned ONLY Student Submitted PDF (rahul_assignment_solution.pdf)!");
        } else {
            console.error("❌ FAILED: Faculty Assignment Submission API returned WRONG file!");
            process.exit(1);
        }

        console.log("\n=== ALL ROOT CAUSE PDF SEPARATION PIPELINE TESTS PASSED CLEANLY! ===");

    } catch (err) {
        console.error("Pipeline test error:", err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

verifyPdfSeparationPipeline();
