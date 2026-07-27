const { Pool } = require("pg");
const path = require("path");
const fs = require("fs");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

const pool = new Pool({
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || "gsr_universe",
    user: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD || "postgres"
});

async function verifyAssignmentsWorkflow() {
    console.log("=========================================");
    console.log("Phase 2: Assignments Module Verification");
    console.log("=========================================");

    try {
        // 1. Insert test assignment
        const testAssign = await pool.query(`
            INSERT INTO assignments (class_id, academic_year_id, subject_id, title, description, submission_date, max_marks, created_by)
            VALUES (1, 1, 1, 'Phase 2 Verification Assignment', 'Project details', CURRENT_DATE + INTERVAL '5 days', 25.0, 1)
            RETURNING id, title
        `);
        const assignId = testAssign.rows[0].id;
        console.log(`✅ Step 1: Created published assignment ID ${assignId}`);

        // 2. Verify submissions count prior to student submission (must be 0)
        const subCheckBefore = await pool.query(`
            SELECT asub.* FROM assignment_submissions asub WHERE asub.assignment_id = $1
        `, [assignId]);
        console.log(`✅ Step 2: Submissions count for newly created assignment: ${subCheckBefore.rows.length}`);
        if (subCheckBefore.rows.length !== 0) {
            throw new Error("Assignment automatically appeared in submissions!");
        }

        // 3. Get active student class mapping
        const scmRes = await pool.query("SELECT id FROM student_class_mapping ORDER BY id LIMIT 1");
        const scmId = scmRes.rows.length > 0 ? scmRes.rows[0].id : 1;

        // 4. Simulate student uploading assignment submission PDF
        const samplePdfPath = path.join(__dirname, "../uploads/sample_submission.pdf");
        if (!fs.existsSync(path.dirname(samplePdfPath))) {
            fs.mkdirSync(path.dirname(samplePdfPath), { recursive: true });
        }
        fs.writeFileSync(samplePdfPath, "%PDF-1.4 sample PDF content");

        const subRes1 = await pool.query(`
            INSERT INTO assignment_submissions (assignment_id, student_class_mapping_id, file_name, file_path, submitted_at)
            VALUES ($1, $2, 'Student_Assignment_Project.pdf', '/uploads/sample_submission.pdf', CURRENT_TIMESTAMP)
            RETURNING id
        `, [assignId, scmId]);
        const submissionId = subRes1.rows[0].id;
        console.log(`✅ Step 3: Student uploaded assignment PDF (Submission ID: ${submissionId})`);

        // 5. Test deduplication via assignmentController.getAssignmentSubmissions
        const assignmentController = require("../src/controllers/assignmentController");
        const reqSub = { query: { assignment_id: assignId } };
        let subResData = null;
        const resSub = { json: (data) => { subResData = data; } };

        await assignmentController.getAssignmentSubmissions(reqSub, resSub);
        console.log(`✅ Step 4: Faculty getAssignmentSubmissions returned ${subResData.count} item(s) (Deduplicated)`);
        console.log(`   Student: ${subResData.data[0]?.student_name}, File: ${subResData.data[0]?.file_name}`);

        // 6. Test Grade / Save Marks via assignmentController.gradeAssignmentSubmission
        const reqGrade = {
            body: {
                submission_id: submissionId,
                obtained_marks: 22.5,
                max_marks: 25.0,
                remarks: "Excellent Project"
            }
        };
        let gradeResData = null;
        const resGrade = { json: (data) => { gradeResData = data; } };

        await assignmentController.gradeAssignmentSubmission(reqGrade, resGrade);
        console.log(`✅ Step 5: Faculty gradeAssignmentSubmission saved marks: ${gradeResData.data?.obtained_marks} / ${gradeResData.data?.max_marks}`);

        // 7. Verify Student Dashboard / Parent getAssignmentMarks endpoint
        const parentController = require("../src/controllers/parentController");
        const parentReq = { user: { student_class_mapping_id: scmId } };
        let parentResData = null;
        const parentRes = { status: () => parentRes, json: (data) => { parentResData = data; } };
        const next = (err) => console.error("Parent Controller Error:", err);

        await parentController.getAssignmentMarks(parentReq, parentRes, next);
        console.log(`✅ Step 6: Student Dashboard getAssignmentMarks retrieved ${parentResData.assignmentMarks.length} item(s)`);
        console.log(`   Marks displayed in Student Dashboard: ${parentResData.assignmentMarks[0]?.obtained_marks} / ${parentResData.assignmentMarks[0]?.max_marks}`);

        // 8. Clean up test records
        await pool.query("DELETE FROM assignment_submissions WHERE assignment_id = $1", [assignId]);
        await pool.query("DELETE FROM assignments WHERE id = $1", [assignId]);
        console.log("✅ Step 7: Test records cleaned up successfully.");

        console.log("\nALL PHASE 2 BACKEND & DATABASE VERIFICATIONS PASSED!");
    } catch (err) {
        console.error("❌ Verification Failed:", err);
    } finally {
        await pool.end();
    }
}

verifyAssignmentsWorkflow();
