const pool = require("../src/config/db");
const announcementController = require("../src/controllers/announcementController");
const eventController = require("../src/controllers/eventController");
const holidayController = require("../src/controllers/holidayController");
const noticeBoardController = require("../src/controllers/noticeBoardController");

async function testAllNotificationFlows() {
    try {
        console.log("--- Comprehensive Notification Triggers Test ---");

        const mockRes = () => ({
            statusCode: 200,
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { console.log(`API ${this.statusCode}:`, data.message || "OK"); }
        });

        // 1. Test Announcement
        await announcementController.createAnnouncement({
            body: { title: "School Picnic", message: "Annual school picnic next Friday", target_scope: "ALL" }
        }, mockRes());

        // 2. Test Event
        await eventController.createEvent({
            body: { title: "Science Fair 2026", description: "Exhibition in Auditorium", event_date: "2026-08-10", venue: "Main Hall", target_scope: "ALL" }
        }, mockRes());

        // 3. Test Holiday
        await holidayController.createHoliday({
            body: { holiday_name: "Independence Day", description: "National Holiday", start_date: "2026-08-15", end_date: "2026-08-15", holiday_type: "General" }
        }, mockRes());

        // 4. Test Notice Board
        await noticeBoardController.createNotice({
            body: { title: "Uniform Policy", description: "Wear white uniform on Mondays", target_scope: "ALL" }
        }, mockRes());

        const notifs = await pool.query(`
            SELECT id, student_id, type, title, message, created_at 
            FROM parent_notifications 
            ORDER BY id DESC LIMIT 15
        `);

        console.log("\nGenerated Parent Notifications:");
        console.table(notifs.rows);

    } catch (err) {
        console.error("Test Error:", err);
    } finally {
        await pool.end();
    }
}

testAllNotificationFlows();
