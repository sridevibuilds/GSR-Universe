const { Pool } = require("pg");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

const pool = new Pool({
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || "gsr_universe",
    user: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD || "postgres"
});

async function checkDbSubmissions() {
    try {
        console.log("=== HOMEWORK SUBMISSIONS ===");
        const hwSubs = await pool.query(`
            SELECT hs.id, hs.homework_id, hs.student_class_mapping_id, hs.file_name, hs.file_path, hs.submitted_at, s.student_name 
            FROM homework_submissions hs
            LEFT JOIN student_class_mapping scm ON hs.student_class_mapping_id = scm.id
            LEFT JOIN students s ON scm.student_id = s.id
            ORDER BY hs.id DESC LIMIT 10
        `);
        console.table(hwSubs.rows);

        console.log("\n=== ASSIGNMENT SUBMISSIONS ===");
        const assignSubs = await pool.query(`
            SELECT asub.id, asub.assignment_id, asub.student_class_mapping_id, asub.file_name, asub.file_path, asub.submitted_at, asub.obtained_marks, s.student_name 
            FROM assignment_submissions asub
            LEFT JOIN student_class_mapping scm ON asub.student_class_mapping_id = scm.id
            LEFT JOIN students s ON scm.student_id = s.id
            ORDER BY asub.id DESC LIMIT 10
        `);
        console.table(assignSubs.rows);

        console.log("\n=== HOMEWORK TASKS ===");
        const hwTasks = await pool.query(`
            SELECT id, title, attachment_name, attachment_path, created_at FROM homework ORDER BY id DESC LIMIT 5
        `);
        console.table(hwTasks.rows);

        console.log("\n=== ASSIGNMENTS ===");
        const assignTasks = await pool.query(`
            SELECT id, title, attachment_name, attachment_path, created_at FROM assignments ORDER BY id DESC LIMIT 5
        `);
        console.table(assignTasks.rows);

    } catch (err) {
        console.error("DB Check Error:", err);
    } finally {
        await pool.end();
    }
}

checkDbSubmissions();
