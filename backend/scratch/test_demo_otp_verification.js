const pool = require("../src/config/db");
const authController = require("../src/controllers/authController");

async function testDemoOtpVerification() {
    try {
        console.log("=== Testing 123456 Universal Demo OTP Verification ===");

        let sendData = null;
        const mockResSend = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { sendData = data; }
        };

        await authController.parentSendOTP({ body: { mobile: "9014561612" } }, mockResSend);
        console.log("Send OTP Response:", sendData);

        // Test verifying with 123456
        let verifyData = null;
        const mockResVerify = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { verifyData = data; }
        };

        await authController.parentVerifyOTP({ body: { mobile: "9014561612", otp: "123456" } }, mockResVerify);
        console.log("\nVerify OTP Response (with 123456):", verifyData);

        if (verifyData && verifyData.success) {
            console.log("✔ SUCCESS: '123456' verified cleanly and returned Parent JWT Token & Students list!");
        } else {
            console.error("❌ FAILED:", verifyData);
            process.exit(1);
        }

    } catch (err) {
        console.error("Test error:", err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

testDemoOtpVerification();
