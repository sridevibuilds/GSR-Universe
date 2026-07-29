require('dotenv').config();
const jwt = require('../src/utils/jwt');

async function probeRenderRoutes() {
    console.log("=== PROBING DEPLOYED RENDER BACKEND WITH AUTH HEADER ===");
    const baseUrl = "https://gsr-universe.onrender.com";
    const token = jwt({ id: 1, role: "ADMIN" });

    const headers = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
    };

    const routesToTest = [
        { path: "/api/admin/overview", method: "GET" },
        { path: "/api/fees/calls/settings", method: "GET" },
        { path: "/api/auth/parent/send-otp", method: "POST", body: { mobile: "9014561612" } }
    ];

    for (const item of routesToTest) {
        try {
            const res = await fetch(`${baseUrl}${item.path}`, {
                method: item.method,
                headers,
                body: item.body ? JSON.stringify(item.body) : undefined
            });
            const data = await res.json().catch(() => null);
            console.log(`Route: ${item.path.padEnd(35)} | Status: ${res.status} | Response:`, JSON.stringify(data, null, 2));
        } catch (err) {
            console.log(`Route: ${item.path.padEnd(35)} | Error: ${err.message}`);
        }
    }
}

probeRenderRoutes();
