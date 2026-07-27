const pool = require("../src/config/db");

async function checkRamzanNotif() {
    try {
        console.log("=== RECENT HOLIDAYS IN DB ===");
        const holidays = await pool.query("SELECT * FROM holidays ORDER BY id DESC LIMIT 5");
        console.table(holidays.rows);

        console.log("=== RECENT PARENT NOTIFICATIONS IN DB ===");
        const notifs = await pool.query("SELECT * FROM parent_notifications ORDER BY id DESC LIMIT 10");
        console.table(notifs.rows);

        console.log("=== STUDENT CLASS MAPPINGS IN DB ===");
        const scm = await pool.query("SELECT * FROM student_class_mapping");
        console.table(scm.rows);

        console.log("=== USERS IN DB ===");
        const users = await pool.query("SELECT id, name, mobile, role FROM users LIMIT 10");
        console.table(users.rows);

    } catch (err) {
        console.error(err);
    } finally {
        await pool.end();
    }
}

checkRamzanNotif();
