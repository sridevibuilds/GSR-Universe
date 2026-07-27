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

async function checkAnnouncementsTable() {
    try {
        const res = await pool.query(`
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'announcements'
        `);
        console.table(res.rows);

        const sample = await pool.query(`SELECT * FROM announcements LIMIT 3`);
        console.log("Sample announcements rows:", sample.rows);
    } catch (err) {
        console.error("DB Error:", err);
    } finally {
        await pool.end();
    }
}

checkAnnouncementsTable();
