async function testRenderProductionBackend() {
    console.log("=================================================");
    console.log("TESTING LIVE DEPLOYED RENDER BACKEND PRODUCTION");
    console.log("Target URL: https://gsr-universe.onrender.com");
    console.log("=================================================\n");

    const baseUrl = "https://gsr-universe.onrender.com";

    // 1. Test Parent Send OTP on Render
    console.log("1. Testing Parent Send OTP (https://gsr-universe.onrender.com/api/auth/parent/send-otp)...");
    try {
        const sendRes = await fetch(`${baseUrl}/api/auth/parent/send-otp`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ mobile: "9014561612" })
        });
        const sendData = await sendRes.json();
        console.log("Render Send OTP Status  :", sendRes.status);
        console.log("Render Send OTP Response:", JSON.stringify(sendData, null, 2));

        // 2. Test Parent Verify OTP on Render
        console.log("\n2. Testing Parent Verify OTP (https://gsr-universe.onrender.com/api/auth/parent/verify-otp)...");
        const otpToVerify = sendData.otp || "123456";
        const verifyRes = await fetch(`${baseUrl}/api/auth/parent/verify-otp`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ mobile: "9014561612", otp: otpToVerify })
        });
        const verifyData = await verifyRes.json();
        console.log("Render Verify OTP Status  :", verifyRes.status);
        console.log("Render Verify OTP Response:", JSON.stringify(verifyData, null, 2));

        // 3. Test Admin Login on Render
        console.log("\n3. Testing Admin Login (https://gsr-universe.onrender.com/api/auth/admin/login)...");
        const adminLoginRes = await fetch(`${baseUrl}/api/auth/admin/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ email: "admin@gsruniverse.com", password: "Admin@123" })
        });
        const adminLoginData = await adminLoginRes.json();
        console.log("Render Admin Login Status  :", adminLoginRes.status);
        console.log("Render Admin Login Response:", JSON.stringify(adminLoginData, null, 2));

        if (adminLoginData.token) {
            const authHeaders = {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${adminLoginData.token}`
            };

            // 4. Test Admin Overview on Render
            console.log("\n4. Testing Admin Overview (https://gsr-universe.onrender.com/api/admin/overview)...");
            const overviewRes = await fetch(`${baseUrl}/api/admin/overview`, { headers: authHeaders });
            const overviewData = await overviewRes.json();
            console.log("Render Admin Overview Status  :", overviewRes.status);
            console.log("Render Admin Overview Response:", JSON.stringify(overviewData, null, 2));

            // 5. Test Call Settings on Render
            console.log("\n5. Testing Call Settings (https://gsr-universe.onrender.com/api/fees/calls/settings)...");
            const settingsRes = await fetch(`${baseUrl}/api/fees/calls/settings`, { headers: authHeaders });
            const settingsData = await settingsRes.json();
            console.log("Render Call Settings Status  :", settingsRes.status);
            console.log("Render Call Settings Response:", JSON.stringify(settingsData, null, 2));

            // 6. Test Call Trigger on Render
            console.log("\n6. Testing Call Reminders Trigger (https://gsr-universe.onrender.com/api/fees/calls/trigger)...");
            const triggerRes = await fetch(`${baseUrl}/api/fees/calls/trigger`, { method: "POST", headers: authHeaders });
            const triggerData = await triggerRes.json();
            console.log("Render Call Trigger Status  :", triggerRes.status);
            console.log("Render Call Trigger Response:", JSON.stringify(triggerData, null, 2));
        }

    } catch (err) {
        console.error("Render Backend Audit Error:", err);
    }
}

testRenderProductionBackend();
