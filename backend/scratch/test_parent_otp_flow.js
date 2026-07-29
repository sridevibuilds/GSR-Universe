const pool = require("../src/config/db");
const authController = require("../src/controllers/authController");

async function testParentOtpFlow() {
    try {
        console.log("=== Testing Parent OTP Generation & Verification Flow ===");

        // 1. Test sending OTP for registered mobile 9014561612 (with +91 formatting)
        let sendData = null;
        const mockResSend = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { sendData = data; }
        };

        await authController.parentSendOTP({ body: { mobile: "+919014561612" } }, mockResSend);

        console.log("Send OTP Response:", sendData);

        if (sendData && sendData.success && sendData.otp) {
            console.log(`✔ Send OTP Success! Generated OTP Code: ${sendData.otp}`);

            // 2. Test verifying OTP with the generated OTP
            let verifyData = null;
            const mockResVerify = {
                status: function(code) { this.statusCode = code; return this; },
                json: function(data) { verifyData = data; }
            };

            await authController.parentVerifyOTP({ body: { mobile: "9014561612", otp: sendData.otp } }, mockResVerify);
            console.log("\nVerify OTP Response:", verifyData);

            if (verifyData && verifyData.success) {
                console.log("✔ SUCCESS: Parent Login via OTP completed clean!");
            } else {
                console.error("❌ FAILED: Parent OTP verification failed!");
            }

        } else {
            console.error("❌ FAILED: Send OTP response missing success/otp!");
        }

    } catch (err) {
        console.error("Test error:", err);
    } finally {
        await pool.end();
    }
}

testParentOtpFlow();
