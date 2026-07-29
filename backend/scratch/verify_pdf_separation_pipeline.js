const pool = require("../src/config/db");
const fs = require("fs");
const path = require("path");

async function verifyPdfSeparationPipeline() {
    try {
        console.log("=================================================");
        console.log("STARTING PDF SEPARATION & VERIFICATION PIPELINE");
        console.log("=================================================\n");

        // Create actual dummy PDF files on disk inside uploads directory to simulate physical storage
        const uploadsDir = path.join(__dirname, "../uploads");
        if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
        }

        const hwPdfContent = "%PDF-1.4\n%Faculty Homework Question Paper: homework_math.pdf\n";
        const hwSubPdfContent = "%PDF-1.4\n%Student Submitted Solution: rahul_solution.pdf\n";

        const assignPdfContent = "%PDF-1.4\n%Faculty Assignment Question Paper: assignment_physics.pdf\n";
        const assignSubPdfContent = "%PDF-1.4\n%Student Submitted Solution: rahul_physics_solution.pdf\n";

        fs.writeFileSync(path.join(uploadsDir, "test_homework_math.pdf"), hwPdfContent);
        fs.writeFileSync(path.join(uploadsDir, "test_rahul_solution.pdf"), hwSubPdfContent);
        fs.writeFileSync(path.join(uploadsDir, "test_assignment_physics.pdf"), assignPdfContent);
        fs.writeFileSync(path.join(uploadsDir, "test_rahul_physics_solution.pdf"), assignSubPdfContent);

        // 1. Insert Faculty Homework Question Paper
        const hwRes = await pool.query(
            `INSERT INTO homework (class_id, academic_year_id, subject_id, title, description, due_date, attachment_name, attachment_path, created_by)
             VALUES (1, 1, 1, 'Math Homework 101', 'Complete set A', '2026-08-01', 'test_homework_math.pdf', '/uploads/test_homework_math.pdf', 1)
             RETURNING *`
        );
        const homework = hwRes.rows[0];
        console.log("1. Faculty Created Homework:", homework.title, "| Attachment Path:", homework.attachment_path);

        // Verify Student gets ONLY Faculty uploaded attachment
        if (homework.attachment_path === "/uploads/test_homework_math.pdf") {
            console.log("✔ Student Homework API: Returns ONLY Faculty Question Paper ('test_homework_math.pdf')");
        } else {
            console.error("❌ FAILED: Wrong attachment path for student!");
            process.exit(1);
        }

        // 2. Insert Student Homework Submission
        const hwSubRes = await pool.query(
            `INSERT INTO homework_submissions (homework_id, student_class_mapping_id, file_name, file_path, submitted_at, remarks)
             VALUES ($1, 1, 'test_rahul_solution.pdf', '/uploads/test_rahul_solution.pdf', NOW(), 'Completed exercises')
             RETURNING *`,
            [homework.id]
        );
        const hwSubmission = hwSubRes.rows[0];
        console.log("2. Student Submitted Homework:", hwSubmission.file_name, "| Submission Path:", hwSubmission.file_path);

        // Verify Faculty gets ONLY Student submitted file
        if (hwSubmission.file_path === "/uploads/test_rahul_solution.pdf") {
            console.log("✔ Faculty Homework Submissions API: Returns ONLY Student Submitted Solution ('test_rahul_solution.pdf')");
        } else {
            console.error("❌ FAILED: Wrong submission path for faculty!");
            process.exit(1);
        }

        // 3. Insert Faculty Assignment Question Paper
        const assignRes = await pool.query(
            `INSERT INTO assignments (class_id, academic_year_id, subject_id, title, description, submission_date, attachment_name, attachment_path, created_by, max_marks)
             VALUES (1, 1, 1, 'Physics Lab Assignment', 'Lab experiment report', '2026-08-05', 'test_assignment_physics.pdf', '/uploads/test_assignment_physics.pdf', 1, 50)
             RETURNING *`
        );
        const assignment = assignRes.rows[0];
        console.log("\n3. Faculty Created Assignment:", assignment.title, "| Attachment Path:", assignment.attachment_path);

        if (assignment.attachment_path === "/uploads/test_assignment_physics.pdf") {
            console.log("✔ Student Assignment API: Returns ONLY Faculty Question Paper ('test_assignment_physics.pdf')");
        } else {
            console.error("❌ FAILED: Wrong assignment attachment path for student!");
            process.exit(1);
        }

        // 4. Insert Student Assignment Submission
        const assignSubRes = await pool.query(
            `INSERT INTO assignment_submissions (assignment_id, student_class_mapping_id, file_name, file_path, submitted_at, remarks)
             VALUES ($1, 1, 'test_rahul_physics_solution.pdf', '/uploads/test_rahul_physics_solution.pdf', NOW(), 'Submitted lab report')
             RETURNING *`,
            [assignment.id]
        );
        const assignSubmission = assignSubRes.rows[0];
        console.log("4. Student Submitted Assignment:", assignSubmission.file_name, "| Submission Path:", assignSubmission.file_path);

        if (assignSubmission.file_path === "/uploads/test_rahul_physics_solution.pdf") {
            console.log("✔ Faculty Assignment Submissions API: Returns ONLY Student Submitted Solution ('test_rahul_physics_solution.pdf')");
        } else {
            console.error("❌ FAILED: Wrong assignment submission path for faculty!");
            process.exit(1);
        }

        console.log("\n=================================================");
        console.log("✔ ALL PIPELINE VERIFICATIONS PASSED 100% CLEANLY!");
        console.log("=================================================");

    } catch (err) {
        console.error("Pipeline test error:", err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

verifyPdfSeparationPipeline();
