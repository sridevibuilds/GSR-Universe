async function verifyRenderAdminOverview() {
    console.log("=== TESTING ALL ADMIN ROUTES ON RENDER ===");
    const baseUrl = "https://gsr-universe.onrender.com";

    // 1. Admin Login on Render
    const loginRes = await fetch(`${baseUrl}/api/auth/admin/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "admin@gsruniverse.com", password: "Admin@123" })
    });

    const loginData = await loginRes.json();
    console.log("1. Admin Login Status:", loginRes.status);
    if (!loginData.token) {
        console.error("Login Failed:", loginData);
        process.exit(1);
    }

    const headers = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${loginData.token}`
    };

    // 2. Test GET /api/admin/overview
    const overviewRes = await fetch(`${baseUrl}/api/admin/overview`, { method: "GET", headers });
    const overviewData = await overviewRes.json();
    console.log("2. GET /api/admin/overview Status:", overviewRes.status, "Data:", JSON.stringify(overviewData));

    // 3. Test GET /api/admin/class-reports
    const classRes = await fetch(`${baseUrl}/api/admin/class-reports`, { method: "GET", headers });
    const classData = await classRes.json();
    console.log("3. GET /api/admin/class-reports Status:", classRes.status, "Data:", JSON.stringify(classData));

    // 4. Test GET /api/admin/system-notifications
    const notifRes = await fetch(`${baseUrl}/api/admin/system-notifications`, { method: "GET", headers });
    const notifData = await notifRes.json();
    console.log("4. GET /api/admin/system-notifications Status:", notifRes.status, "Data:", JSON.stringify(notifData));
}

verifyRenderAdminOverview();
