const pool = require("../src/config/db");
const parentController = require("../src/controllers/parentController");

async function testDedup() {
    try {
        console.log("=== Testing Deduplicated Parent Notifications API ===");

        const req = {
            user: { id: 1, role: "PARENT" },
            query: {}
        };

        let jsonOutput = null;
        const res = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { jsonOutput = data; }
        };

        await parentController.getParentNotifications(req, res, (err) => console.error("Error:", err));

        if (jsonOutput && jsonOutput.success) {
            console.log(`Returned ${jsonOutput.count} unique notifications (unread: ${jsonOutput.unread_count}):`);
            console.table(jsonOutput.data);

            // Check if any keys are duplicated
            const keys = jsonOutput.data.map(d => `${d.type}_${d.title}_${d.reference_id}`);
            const uniqueSet = new Set(keys);
            if (keys.length === uniqueSet.size) {
                console.log("✔ SUCCESS: Zero duplicate notifications returned!");
            } else {
                console.error("❌ FAILED: Duplicate notifications found in response!");
            }
        }
    } catch (err) {
        console.error("Test error:", err);
    } finally {
        await pool.end();
    }
}

testDedup();
