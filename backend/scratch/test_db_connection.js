const pool = require("../src/config/db");
const { runFeeRemindersCheck } = require("../src/services/reminderScheduler");

async function testDbConnectionAndScheduler() {
    try {
        console.log("=== Testing Database Connection & Fee Reminders Sweep ===");
        const res = await pool.query("SELECT NOW()");
        console.log("Database connected successfully! Time:", res.rows[0].now);

        await runFeeRemindersCheck(true);
        console.log("✔ SUCCESS: Fee reminders check executed without SSL error!");
    } catch (err) {
        console.error("❌ Connection/Scheduler Error:", err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

testDbConnectionAndScheduler();
