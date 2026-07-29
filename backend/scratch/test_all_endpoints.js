const app = require("../src/app");
const http = require("http");
const jwt = require("jsonwebtoken");
const pool = require("../src/config/db");
require("dotenv").config();

async function testAllEndpoints() {
    const server = http.createServer(app);
    await new Promise(resolve => server.listen(0, resolve));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;

    console.log("Testing endpoints on", baseUrl);

    const adminToken = jwt.sign(
        { id: 1, role: "admin" },
        process.env.JWT_SECRET || "default_secret",
        { expiresIn: "1h" }
    );

    const endpoints = [
        "/api/admin/overview",
        "/api/fees/calls/settings",
        "/api/fees/calls/history",
        "/api/admin/class-reports?academic_year=2026-2027&class_name=Class%209&section=A&term=Annual",
        "/api/admin/system-notifications",
        "/api/faculty/"
    ];

    for (const ep of endpoints) {
        try {
            const res = await fetch(`${baseUrl}${ep}`, {
                headers: { "Authorization": `Bearer ${adminToken}` }
            });
            const data = await res.json();
            console.log(`Endpoint ${ep}: Status ${res.status}`, data);
        } catch (err) {
            console.error(`Endpoint ${ep} Error:`, err);
        }
    }

    server.close();
    await pool.end();
}

testAllEndpoints();
