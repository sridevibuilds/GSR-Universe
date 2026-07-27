const pool = require("../src/config/db");
const announcementController = require("../src/controllers/announcementController");

async function testCreateAnnouncementNotif() {
    try {
        console.log("--- Testing Announcement Creation & Notification Generation ---");
        
        const req = {
            body: {
                classes: ["Class 9"],
                sections: ["A"],
                announcement_date: "2026-07-27",
                academic_year_id: 1,
                title: "Exam Instructions Announcement",
                message: "Please bring hall tickets for unit test",
                priority: "Urgent",
                created_by: 1,
                target_scope: "CLASS"
            }
        };

        const res = {
            status: function(code) {
                this.statusCode = code;
                return this;
            },
            json: function(data) {
                console.log("API Response:", this.statusCode, data);
            }
        };

        await announcementController.createAnnouncement(req, res);

        const notifs = await pool.query("SELECT * FROM parent_notifications ORDER BY id DESC LIMIT 5");
        console.log("Recent Parent Notifications in DB:");
        console.table(notifs.rows);

    } catch (err) {
        console.error("Test Error:", err);
    } finally {
        await pool.end();
    }
}

testCreateAnnouncementNotif();
