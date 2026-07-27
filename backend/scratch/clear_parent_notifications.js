const pool = require("../src/config/db");

async function clearParentNotifications() {
    try {
        console.log("=== CLEARING ALL PARENT NOTIFICATIONS ===");
        const res = await pool.query("DELETE FROM public.parent_notifications");
        console.log(`Deleted ${res.rowCount} records from parent_notifications table.`);
        
        const countRes = await pool.query("SELECT COUNT(*) FROM public.parent_notifications");
        console.log("Current parent_notifications count:", countRes.rows[0].count);
        console.log("SUCCESS: All student notifications cleared!");
    } catch (err) {
        console.error("Error clearing notifications:", err);
    } finally {
        await pool.end();
    }
}

clearParentNotifications();
