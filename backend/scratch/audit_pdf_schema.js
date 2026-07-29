const pool = require("../src/config/db");

async function auditPdfSchema() {
    try {
        console.log("=== 1. HOMEWORK TABLE SCHEMA ===");
        const hwCols = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'homework'
        `);
        console.table(hwCols.rows);

        console.log("=== 2. HOMEWORK SUBMISSIONS TABLE SCHEMA ===");
        const hwSubCols = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'homework_submissions'
        `);
        console.table(hwSubCols.rows);

        console.log("=== 3. ASSIGNMENTS TABLE SCHEMA ===");
        const assignCols = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'assignments'
        `);
        console.table(assignCols.rows);

        console.log("=== 4. ASSIGNMENT SUBMISSIONS TABLE SCHEMA ===");
        const assignSubCols = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'assignment_submissions'
        `);
        console.table(assignSubCols.rows);

        console.log("\n=== RECENT HOMEWORK ROWS ===");
        const hwRows = await pool.query("SELECT id, title, attachment_path, file_path FROM homework ORDER BY id DESC LIMIT 5");
        console.table(hwRows.rows);

        console.log("\n=== RECENT HOMEWORK SUBMISSION ROWS ===");
        const hwSubRows = await pool.query("SELECT id, homework_id, student_id, submission_file_path, file_path FROM homework_submissions ORDER BY id DESC LIMIT 5");
        console.table(hwSubRows.rows);

        console.log("\n=== RECENT ASSIGNMENT ROWS ===");
        const assignRows = await pool.query("SELECT id, title, attachment_path, file_path FROM assignments ORDER BY id DESC LIMIT 5");
        console.table(assignRows.rows);

        console.log("\n=== RECENT ASSIGNMENT SUBMISSION ROWS ===");
        const assignSubRows = await pool.query("SELECT id, assignment_id, student_id, submission_file_path, file_path FROM assignment_submissions ORDER BY id DESC LIMIT 5");
        console.table(assignSubRows.rows);

    } catch (err) {
        console.error(err);
    } finally {
        await pool.end();
    }
}

auditPdfSchema();
