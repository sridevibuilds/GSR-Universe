const pool = require("../src/config/db");
const holidayController = require("../src/controllers/holidayController");
const parentController = require("../src/controllers/parentController");

async function testLiveHolidayNotification() {
    try {
        console.log("=== Testing Live Holiday Notification Creation & Retrieval ===");

        // 1. Create a fresh Holiday from Faculty side
        const reqCreate = {
            body: {
                holiday_name: "Ramzan Festival Holiday",
                description: "Official holiday declared for Ramzan festival",
                start_date: "2026-07-28",
                end_date: "2026-07-28",
                holiday_type: "Festival",
                created_by: 1,
                target_scope: "ALL"
            }
        };

        let createResData = null;
        const resCreate = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { createResData = data; console.log(`Holiday API ${this.statusCode}:`, data.message || "Created"); }
        };

        await holidayController.createHoliday(reqCreate, resCreate);

        // 2. Fetch Notifications from Student/Parent side
        const reqFetch = {
            user: { id: 1, role: "PARENT" },
            query: {}
        };

        let fetchResData = null;
        const resFetch = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { fetchResData = data; }
        };

        await parentController.getParentNotifications(reqFetch, resFetch, (err) => console.error("Error:", err));

        if (fetchResData && fetchResData.success) {
            console.log(`\nStudent Notifications Received (${fetchResData.count} items, unread: ${fetchResData.unread_count}):`);
            console.table(fetchResData.data);

            const ramzanNotif = fetchResData.data.find(n => n.title.includes("Ramzan Festival Holiday"));
            if (ramzanNotif) {
                console.log("✔ SUCCESS: 'Ramzan Festival Holiday' notification arrived in Student Notifications!");
            } else {
                console.error("❌ FAILED: Holiday notification missing!");
            }
        }

    } catch (err) {
        console.error("Test error:", err);
    } finally {
        await pool.end();
    }
}

testLiveHolidayNotification();
