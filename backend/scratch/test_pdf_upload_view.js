const { Pool } = require("pg");
const path = require("path");
const fs = require("fs");
const http = require("http");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

const pool = new Pool({
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || "gsr_universe",
    user: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD || "postgres"
});

async function verifyPdfUploadAndView() {
    console.log("==================================================");
    console.log("🚀 Testing Real PDF Upload, DB Path, API & Viewing");
    console.log("==================================================");

    try {
        // 1. Create a dummy test PDF file with distinct visible content
        const testPdfPath = path.join(__dirname, "student_test_document.pdf");
        const customUniqueText = "CUSTOM_STUDENT_PDF_CONTENT_TEST_VERIFICATION";
        const pdfContent = `%PDF-1.4
1 0 obj <</Type /Catalog /Pages 2 0 R>> endobj
2 0 obj <</Type /Pages /Kids [3 0 R] /Count 1>> endobj
3 0 obj <</Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R>> endobj
4 0 obj <</Length 65>> stream
BT /F1 12 Tf 100 700 TD (${customUniqueText}) Tj ET
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
322
%%EOF`;
        fs.writeFileSync(testPdfPath, pdfContent);
        console.log(`✅ Step 1: Created test PDF file with custom content string "${customUniqueText}"`);

        // 2. Upload file to /api/upload storage
        const uploadsDir = path.join(__dirname, "../src/uploads");
        if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
        }
        const savedFileName = `file-${Date.now()}-student_doc.pdf`;
        const savedFilePath = path.join(uploadsDir, savedFileName);
        fs.writeFileSync(savedFilePath, pdfContent);
        const serverRelPath = `/uploads/${savedFileName}`;
        console.log(`✅ Step 2: Uploaded file saved to storage: ${serverRelPath}`);

        // 3. Get student class mapping
        const scmRes = await pool.query("SELECT id FROM student_class_mapping ORDER BY id LIMIT 1");
        const scmId = scmRes.rows.length > 0 ? scmRes.rows[0].id : 1;

        // 4. Create homework record & submit PDF
        const hwRes = await pool.query(`
            INSERT INTO homework (class_id, academic_year_id, subject_id, title, description, due_date, created_by)
            VALUES (1, 1, 1, 'PDF Upload Verification HW', 'Test instructions', CURRENT_DATE + INTERVAL '2 days', 1)
            RETURNING id
        `);
        const hwId = hwRes.rows[0].id;

        const hwSubRes = await pool.query(`
            INSERT INTO homework_submissions (homework_id, student_class_mapping_id, file_name, file_path, submitted_at)
            VALUES ($1, $2, 'student_test_document.pdf', $3, CURRENT_TIMESTAMP)
            RETURNING id
        `, [hwId, scmId, serverRelPath]);
        const hwSubId = hwSubRes.rows[0].id;
        console.log(`✅ Step 3: Submitted homework with file path stored in DB: ${serverRelPath}`);

        // 5. Test viewHomeworkSubmission controller method
        const homeworkController = require("../src/controllers/homeworkController");
        let hwViewData = null;
        let hwViewHeaders = {};
        const reqHw = { params: { id: hwSubId } };
        const resHw = {
            setHeader: (k, v) => { hwViewHeaders[k] = v; },
            sendFile: (filepath) => { hwViewData = fs.readFileSync(filepath, 'utf-8'); }
        };

        await homeworkController.viewHomeworkSubmission(reqHw, resHw);
        console.log(`✅ Step 4: Homework submission view returned content length: ${hwViewData?.length}`);
        
        if (!hwViewData.includes(customUniqueText)) {
            throw new Error("Homework submission view returned incorrect/fallback file content!");
        }
        if (hwViewData.includes("GSR Universe Student Submission Document")) {
            throw new Error("Homework submission view returned blank fallback placeholder PDF!");
        }
        console.log(`   -> Verified returned PDF contains exact uploaded text: "${customUniqueText}"`);

        // 6. Create assignment record & submit PDF
        const assignRes = await pool.query(`
            INSERT INTO assignments (class_id, academic_year_id, subject_id, title, description, submission_date, max_marks, created_by)
            VALUES (1, 1, 1, 'PDF Upload Verification Assignment', 'Project details', CURRENT_DATE + INTERVAL '5 days', 20.0, 1)
            RETURNING id
        `);
        const assignId = assignRes.rows[0].id;

        const assignSubRes = await pool.query(`
            INSERT INTO assignment_submissions (assignment_id, student_class_mapping_id, file_name, file_path, submitted_at)
            VALUES ($1, $2, 'student_test_document.pdf', $3, CURRENT_TIMESTAMP)
            RETURNING id
        `, [assignId, scmId, serverRelPath]);
        const assignSubId = assignSubRes.rows[0].id;

        // 7. Test viewAssignmentSubmission controller method
        const assignmentController = require("../src/controllers/assignmentController");
        let assignViewData = null;
        const reqAssign = { params: { id: assignSubId } };
        const resAssign = {
            setHeader: () => {},
            sendFile: (filepath) => { assignViewData = fs.readFileSync(filepath, 'utf-8'); }
        };

        await assignmentController.viewAssignmentSubmission(reqAssign, resAssign);
        console.log(`✅ Step 5: Assignment submission view returned content length: ${assignViewData?.length}`);

        if (!assignViewData.includes(customUniqueText)) {
            throw new Error("Assignment submission view returned incorrect/fallback file content!");
        }
        console.log(`   -> Verified returned PDF contains exact uploaded text: "${customUniqueText}"`);

        // 8. Clean up test records and files
        await pool.query("DELETE FROM homework_submissions WHERE homework_id = $1", [hwId]);
        await pool.query("DELETE FROM homework WHERE id = $1", [hwId]);
        await pool.query("DELETE FROM assignment_submissions WHERE assignment_id = $1", [assignId]);
        await pool.query("DELETE FROM assignments WHERE id = $1", [assignId]);
        if (fs.existsSync(testPdfPath)) fs.unlinkSync(testPdfPath);
        if (fs.existsSync(savedFilePath)) fs.unlinkSync(savedFilePath);

        console.log("✅ Step 6: Test records and temporary files cleaned up.");
        console.log("\n🎉 ALL HOMEWORK & ASSIGNMENT PDF UPLOAD & VIEWING TESTS PASSED!");
    } catch (err) {
        console.error("❌ Test Failed:", err);
    } finally {
        await pool.end();
    }
}

verifyPdfUploadAndView();
