require('dotenv').config();

async function testFast2SMSOTPRoute() {
    const apiKey = process.env.FAST2SMS_API_KEY;
    const mobile = "9014561612";
    const otp = "847291";

    console.log("=== FAST2SMS OTP ROUTE LIVE TEST ===");
    console.log("API Key Present:", !!apiKey);
    if (apiKey) {
        console.log("Masked Key     :", `${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}`);
    }

    const url = "https://www.fast2sms.com/dev/bulkV2";
    
    // Fast2SMS dedicated OTP route bypassing DND filters
    const payload = {
        route: "otp",
        variables_values: otp,
        numbers: mobile
    };

    console.log("\nSending POST (route: 'otp') to Fast2SMS...");
    console.log("Payload:", JSON.stringify(payload, null, 2));

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "authorization": apiKey,
                "Content-Type": "application/json"
            },
            body: JSON.stringify(payload)
        });

        const resData = await response.json();
        console.log("\n--- Fast2SMS OTP Route Response ---");
        console.log("HTTP Status Code:", response.status);
        console.log("Response Body   :", JSON.stringify(resData, null, 2));
    } catch (err) {
        console.error("Fetch Error:", err);
    }
}

testFast2SMSOTPRoute();
