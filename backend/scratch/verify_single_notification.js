const pool = require("../src/config/db");
const holidayController = require("../src/controllers/holidayController");
const announcementController = require("../src/controllers/announcementController");
const eventController = require("../src/controllers/eventController");
const parentController = require("../src/controllers/parentController");

async function verifySingleNotification() {
    try {
        console.log("=== CLEARING EXISTING PARENT NOTIFICATIONS ===");
        await pool.query("DELETE FROM public.parent_notifications");

        const mockRes = (label) => ({
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { console.log(`[${label}] Status ${this.statusCode}:`, data.message || "OK"); }
        });

        console.log("\n--- 1. Creating Holiday ---");
        await holidayController.createHoliday({
            body: { holiday_name: "Ganesh Chaturthi", description: "Festival holiday", start_date: "2026-09-10", end_date: "2026-09-10", holiday_type: "Festival" }
        }, mockRes("Holiday"));

        console.log("\n--- 2. Creating Announcement ---");
        await announcementController.createAnnouncement({
            body: { title: "Parent Teacher Meeting", message: "PTM scheduled for Saturday", target_scope: "ALL" }
        }, mockRes("Announcement"));

        console.log("\n--- 3. Creating Event ---");
        await eventController.createEvent({
            body: { title: "Sports Day 2026", description: "Annual Sports Meet", event_date: "2026-10-15", venue: "Ground", target_scope: "ALL" }
        }, mockRes("Event"));

        console.log("\n=== DB ROWS CREATED IN parent_notifications TABLE ===");
        const dbRows = await pool.query("SELECT id, student_id, class_id, type, title FROM public.parent_notifications ORDER BY id ASC");
        console.table(dbRows.rows);

        if (dbRows.rows.length === 3) {
            console.log("✔ DB VERIFICATION SUCCESS: Exactly 3 notification rows in DB (1 per upload)!");
        } else {
            console.error(`❌ DB VERIFICATION FAILED: Found ${dbRows.rows.length} rows instead of 3!`);
            process.exit(1);
        }

        console.log("\n=== STUDENT API NOTIFICATIONS RECEIVED ===");
        let apiData = null;
        await parentController.getParentNotifications(
            { user: { id: 1, role: "PARENT" }, query: {} },
            { status: function() { return this; }, json: function(d) { apiData = d; } },
            (e) => console.error(e)
        );

        console.table(apiData.data);
        if (apiData.data.length === 3) {
            console.log("✔ API VERIFICATION SUCCESS: Student received EXACTLY 3 single notifications (1 per item, ZERO duplicates)!");
        } else {
            console.error(`❌ API VERIFICATION FAILED: Student received ${apiData.data.length} notifications!`);
            process.exit(1);
        }

    } catch (err) {
        console.error("Verification error:", err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

verifySingleNotification();
