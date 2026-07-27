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

async function debugAnnouncementNotifs() {
    try {
        console.log("--- Checking Students & Class Mappings ---");
        const scm = await pool.query(`
            SELECT scm.id as scm_id, scm.student_id, scm.class_id, c.class_name, c.section, s.student_name 
            FROM student_class_mapping scm
            LEFT JOIN classes c ON scm.class_id = c.id
            LEFT JOIN students s ON scm.student_id = s.id
        `);
        console.table(scm.rows);

        const classes = await pool.query(`SELECT * FROM classes`);
        console.log("Classes in DB:");
        console.table(classes.rows);

        console.log("--- Checking Parent Notifications ---");
        const notifs = await pool.query(`SELECT * FROM parent_notifications ORDER BY id DESC LIMIT 10`);
        console.table(notifs.rows);

    } catch (err) {
        console.error("Error:", err);
    } finally {
        await pool.end();
    }
}

debugAnnouncementNotifs();
