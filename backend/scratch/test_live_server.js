const jwt = require("jsonwebtoken");
require("dotenv").config();

async function testLiveServer() {
    const adminToken = jwt.sign(
        { id: 1, role: "admin" },
        process.env.JWT_SECRET || "default_secret",
        { expiresIn: "1h" }
    );

    try {
        const res = await fetch("http://localhost:5000/api/admin/overview", {
            headers: { "Authorization": `Bearer ${adminToken}` }
        });
        const data = await res.json();
        console.log("Live Server Response for /api/admin/overview:", res.status, data);
    } catch (err) {
        console.error("Live Server test error:", err);
    }
}

testLiveServer();
