const pool = require("../src/config/db");
const authController = require("../src/controllers/authController");

async function testLiveFast2SMS() {
    try {
        console.log("=== Testing Live Fast2SMS OTP Dispatch ===");

        let sendData = null;
        const mockResSend = {
            status: function(code) { this.statusCode = code; return this; },
            json: function(data) { sendData = data; }
        };

        // Call parentSendOTP for registered mobile 9014561612
        await authController.parentSendOTP({ body: { mobile: "9014561612" } }, mockResSend);

        console.log("Response:", sendData);

        if (sendData && sendData.success) {
            console.log(`\n✔ SUCCESS: Fast2SMS API dispatched OTP ${sendData.otp} to 9014561612! Check mobile phone SMS inbox.`);
        } else {
            console.error("❌ FAILED:", sendData);
        }

    } catch (err) {
        console.error("Test error:", err);
    } finally {
        await pool.end();
    }
}

testLiveFast2SMS();
