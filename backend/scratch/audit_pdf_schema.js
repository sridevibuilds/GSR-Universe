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

async function auditSchema() {
    try {
        console.log("=== HOMEWORK TABLE COLUMNS ===");
        const hwCols = await pool.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'homework'`);
        console.table(hwCols.rows);

        console.log("=== HOMEWORK SUBMISSIONS TABLE COLUMNS ===");
        const hwSubCols = await pool.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'homework_submissions'`);
        console.table(hwSubCols.rows);

        console.log("=== ASSIGNMENTS TABLE COLUMNS ===");
        const assignCols = await pool.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'assignments'`);
        console.table(assignCols.rows);

        console.log("=== ASSIGNMENT SUBMISSIONS TABLE COLUMNS ===");
        const assignSubCols = await pool.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'assignment_submissions'`);
        console.table(assignSubCols.rows);

        console.log("=== SAMPLE DATA ===");
        const hw = await pool.query(`SELECT id, title, file_name, file_path FROM homework LIMIT 3`);
        console.log("Homework:", hw.rows);

        const hwSub = await pool.query(`SELECT id, homework_id, student_id, file_name, file_path FROM homework_submissions LIMIT 3`);
        console.log("Homework Submissions:", hwSub.rows);

        const assign = await pool.query(`SELECT id, title, file_name, file_path FROM assignments LIMIT 3`);
        console.log("Assignments:", assign.rows);

        const assignSub = await pool.query(`SELECT id, assignment_id, student_id, file_name, file_path FROM assignment_submissions LIMIT 3`);
        console.log("Assignment Submissions:", assignSub.rows);

    } catch (err) {
        console.error("Audit error:", err);
    } finally {
        await pool.end();
    }
}

auditSchema();
