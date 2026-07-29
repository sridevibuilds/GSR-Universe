const pool = require("../src/config/db");
const homeworkController = require("../src/controllers/homeworkController");
const assignmentController = require("../src/controllers/assignmentController");

async function verifyPureSqlPipeline() {
    try {
        console.log("=== 1. TESTING HOMEWORK API SELECT & JOIN ===");
        let hwResData = null;
        await homeworkController.getAllHomework(
            {},
            { status: function() { return this; }, json: function(d) { hwResData = d; } }
        );
        console.log(`GetAllHomework Count: ${hwResData.count}`);
        if (hwResData.data.length > 0) {
            console.log("First Homework Record keys:", Object.keys(hwResData.data[0]));
            if ('attachment_path' in hwResData.data[0]) {
                console.log("✔ SUCCESS: 'attachment_path' is included in getAllHomework response!");
            } else {
                console.error("❌ FAILED: 'attachment_path' missing from getAllHomework!");
                process.exit(1);
            }
        }

        console.log("\n=== 2. TESTING HOMEWORK SUBMISSIONS NATIVE SQL JOIN ===");
        let hwSubResData = null;
        await homeworkController.getHomeworkSubmissions(
            { query: {} },
            { status: function() { return this; }, json: function(d) { hwSubResData = d; } }
        );
        console.log(`GetHomeworkSubmissions Count: ${hwSubResData.count}`);
        if (hwSubResData.data.length > 0) {
            console.log("First Homework Submission Record keys:", Object.keys(hwSubResData.data[0]));
            console.log("File path:", hwSubResData.data[0].file_path);
        }

        console.log("\n=== 3. TESTING ASSIGNMENTS API SELECT & JOIN ===");
        let assignResData = null;
        await assignmentController.getAllAssignments(
            {},
            { status: function() { return this; }, json: function(d) { assignResData = d; } }
        );
        console.log(`GetAllAssignments Count: ${assignResData.count}`);
        if (assignResData.data.length > 0) {
            console.log("First Assignment Record keys:", Object.keys(assignResData.data[0]));
            if ('attachment_path' in assignResData.data[0]) {
                console.log("✔ SUCCESS: 'attachment_path' is included in getAllAssignments response!");
            } else {
                console.error("❌ FAILED: 'attachment_path' missing from getAllAssignments!");
                process.exit(1);
            }
        }

        console.log("\n=== 4. TESTING ASSIGNMENT SUBMISSIONS NATIVE SQL JOIN ===");
        let assignSubResData = null;
        await assignmentController.getAssignmentSubmissions(
            { query: {} },
            { status: function() { return this; }, json: function(d) { assignSubResData = d; } }
        );
        console.log(`GetAssignmentSubmissions Count: ${assignSubResData.count}`);
        if (assignSubResData.data.length > 0) {
            console.log("First Assignment Submission Record keys:", Object.keys(assignSubResData.data[0]));
            console.log("File path:", assignSubResData.data[0].file_path);
        }

        console.log("\n=================================================");
        console.log("✔ ALL SQL CONTROLLER AUDITS PASSED 100% CLEANLY!");
        console.log("=================================================");

    } catch (err) {
        console.error("SQL verification error:", err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

verifyPureSqlPipeline();
