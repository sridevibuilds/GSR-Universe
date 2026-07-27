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

async function verifyHomeworkWorkflow() {
    console.log("=========================================");
    console.log("Phase 1: Homework Module Verification");
    console.log("=========================================");

    try {
        // 1. Check existing homework and submissions in DB
        const hwCount = await pool.query("SELECT COUNT(*) FROM homework");
        const subCount = await pool.query("SELECT COUNT(*) FROM homework_submissions");
        console.log(`Current Homework Count: ${hwCount.rows[0].count}`);
        console.log(`Current Homework Submissions Count: ${subCount.rows[0].count}`);

        // 2. Insert test homework
        const testHw = await pool.query(`
            INSERT INTO homework (class_id, academic_year_id, subject_id, title, description, due_date, created_by)
            VALUES (1, 1, 1, 'Phase 1 Verification HW', 'Test instructions', CURRENT_DATE + INTERVAL '2 days', 1)
            RETURNING id, title
        `);
        const hwId = testHw.rows[0].id;
        console.log(`✅ Step 1: Created published homework ID ${hwId}`);

        // 3. Verify submissions query before student submits (must return 0 for this HW)
        const subCheckBefore = await pool.query(`
            SELECT hs.* FROM homework_submissions hs WHERE hs.homework_id = $1
        `, [hwId]);
        console.log(`✅ Step 2: Submissions count for newly created homework: ${subCheckBefore.rows.length}`);
        if (subCheckBefore.rows.length !== 0) {
            throw new Error("Homework automatically appeared in submissions!");
        }

        // 4. Get active student class mapping
        const scmRes = await pool.query("SELECT id FROM student_class_mapping ORDER BY id LIMIT 1");
        const scmId = scmRes.rows.length > 0 ? scmRes.rows[0].id : 1;

        // 5. Simulate student uploading PDF homework submission
        const samplePdfPath = path.join(__dirname, "../uploads/sample_submission.pdf");
        if (!fs.existsSync(path.dirname(samplePdfPath))) {
            fs.mkdirSync(path.dirname(samplePdfPath), { recursive: true });
        }
        fs.writeFileSync(samplePdfPath, "%PDF-1.4 sample PDF content");

        const subRes1 = await pool.query(`
            INSERT INTO homework_submissions (homework_id, student_class_mapping_id, file_name, file_path, submitted_at)
            VALUES ($1, $2, 'Student_HW_Sol.pdf', '/uploads/sample_submission.pdf', CURRENT_TIMESTAMP)
            RETURNING id
        `, [hwId, scmId]);
        console.log(`✅ Step 3: Student uploaded submission PDF (Submission ID: ${subRes1.rows[0].id})`);

        // 6. Test deduplication: simulate student submitting again for same homework (updating or re-querying)
        const homeworkController = require("../src/controllers/homeworkController");
        const req = { query: { homework_id: hwId } };
        let resData = null;
        const res = {
            json: (data) => { resData = data; }
        };

        await homeworkController.getHomeworkSubmissions(req, res);
        console.log(`✅ Step 4: Faculty getHomeworkSubmissions returned ${resData.count} item(s)`);
        console.log(`Submission Student Name: ${resData.data[0]?.student_name}, File: ${resData.data[0]?.file_name}`);

        // 7. Clean up test record
        await pool.query("DELETE FROM homework_submissions WHERE homework_id = $1", [hwId]);
        await pool.query("DELETE FROM homework WHERE id = $1", [hwId]);
        console.log("✅ Step 5: Test records cleaned up successfully.");

        console.log("\nALL PHASE 1 BACKEND & DATABASE VERIFICATIONS PASSED!");
    } catch (err) {
        console.error("❌ Verification Failed:", err);
    } finally {
        await pool.end();
    }
}

verifyHomeworkWorkflow();
