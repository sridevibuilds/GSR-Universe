const pool = require("../src/config/db");

async function checkParentMobiles() {
    try {
        console.log("=== REGISTERED STUDENTS & PARENT MOBILES IN DB ===");
        const res = await pool.query(`
            SELECT id, student_name, admission_no, primary_parent_mobile, secondary_parent_mobile 
            FROM students
        `);
        console.table(res.rows);

        console.log("=== OTPS TABLE IN DB ===");
        const otps = await pool.query("SELECT * FROM otps ORDER BY id DESC LIMIT 10");
        console.table(otps.rows);

    } catch (err) {
        console.error("DB Error:", err);
    } finally {
        await pool.end();
    }
}

checkParentMobiles();
