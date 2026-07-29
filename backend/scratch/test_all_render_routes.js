async function probeRenderRoutes() {
    console.log("=== PROBING ALL RENDER BACKEND ROUTES ===");
    const baseUrl = "https://gsr-universe.onrender.com";

    const routesToTest = [
        "/",
        "/api/auth/parent/send-otp",
        "/api/auth/admin/login",
        "/api/admin/overview",
        "/api/v1/admin/overview",
        "/admin/overview",
        "/api/admin/login",
        "/api/fees/calls/settings"
    ];

    for (const route of routesToTest) {
        try {
            const res = await fetch(`${baseUrl}${route}`, {
                method: route.includes("login") || route.includes("send-otp") ? "POST" : "GET",
                headers: { "Content-Type": "application/json" }
            });
            const data = await res.json().catch(() => null);
            console.log(`Route: ${route.padEnd(35)} | Status: ${res.status} | Response:`, JSON.stringify(data));
        } catch (err) {
            console.log(`Route: ${route.padEnd(35)} | Error: ${err.message}`);
        }
    }
}

probeRenderRoutes();
