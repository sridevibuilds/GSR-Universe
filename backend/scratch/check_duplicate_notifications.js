const pool = require("../src/config/db");

async function checkDuplicates() {
    try {
        const res = await pool.query(`
            SELECT id, student_id, class_id, type, title, message, reference_id, created_at 
            FROM parent_notifications 
            ORDER BY id DESC
        `);
        console.log("All parent_notifications in DB:");
        console.table(res.rows);
    } catch (err) {
        console.error(err);
    } finally {
        await pool.end();
    }
}

checkDuplicates();
