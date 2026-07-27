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

function createSimplePdf(filePath, textContent) {
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    const pdfContent = `%PDF-1.4
1 0 obj <</Type /Catalog /Pages 2 0 R>> endobj
2 0 obj <</Type /Pages /Kids [3 0 R] /Count 1>> endobj
3 0 obj <</Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R>> endobj
4 0 obj <</Length ${textContent.length + 45}>> stream
BT /F1 14 Tf 50 700 TD (${textContent}) Tj ET
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
300
%%EOF`;
    fs.writeFileSync(filePath, pdfContent);
}

async function fixStudentVsFacultyFiles() {
    try {
        console.log("==================================================");
        console.log("Separating Faculty Attachments and Student Submissions");
        console.log("==================================================");

        const uploadsDir = path.join(__dirname, "../src/uploads");

        // 1. Create distinct Faculty Attachment PDF
        const facultyPdfPath = path.join(uploadsDir, "faculty_question_paper.pdf");
        createSimplePdf(facultyPdfPath, "FACULTY PUBLISHED ASSIGNMENT & QUESTION PAPER");
        console.log("✅ Created Faculty Attachment PDF: faculty_question_paper.pdf");

        // 2. Create distinct Student Submission Solution PDF
        const studentPdfPath = path.join(uploadsDir, "student_submitted_solution.pdf");
        createSimplePdf(studentPdfPath, "STUDENT UPLOADED HOMEWORK & ASSIGNMENT SOLUTION SHEET");
        console.log("✅ Created Student Submission PDF: student_submitted_solution.pdf");

        // 3. Update homework table (Faculty attachment)
        await pool.query(`
            UPDATE homework 
            SET attachment_name = 'Faculty_Question_Paper.pdf', attachment_path = '/uploads/faculty_question_paper.pdf'
        `);
        console.log("✅ Updated homework table to point to Faculty Attachment PDF");

        // 4. Update assignments table (Faculty attachment)
        await pool.query(`
            UPDATE assignments 
            SET attachment_name = 'Faculty_Question_Paper.pdf', attachment_path = '/uploads/faculty_question_paper.pdf'
        `);
        console.log("✅ Updated assignments table to point to Faculty Attachment PDF");

        // 5. Update homework_submissions table (Student submission)
        await pool.query(`
            UPDATE homework_submissions 
            SET file_name = 'Student_Homework_Solution.pdf', file_path = '/uploads/student_submitted_solution.pdf'
        `);
        console.log("✅ Updated homework_submissions table to point to Student Solution PDF");

        // 6. Update assignment_submissions table (Student submission)
        await pool.query(`
            UPDATE assignment_submissions 
            SET file_name = 'Student_Assignment_Solution.pdf', file_path = '/uploads/student_submitted_solution.pdf'
        `);
        console.log("✅ Updated assignment_submissions table to point to Student Solution PDF");

        console.log("\n🎉 Database & Files updated cleanly!");
    } catch (err) {
        console.error("Error separating files:", err);
    } finally {
        await pool.end();
    }
}

fixStudentVsFacultyFiles();
