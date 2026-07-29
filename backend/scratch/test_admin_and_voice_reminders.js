require('dotenv').config();
const jwt = require('../src/utils/jwt');

async function testAdminAndVoiceReminders() {
    console.log("=== TESTING ADMIN OVERVIEW & VOICE REMINDERS API WITH JWT ===");

    const token = jwt({ id: 1, role: "ADMIN" });
    const headers = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
    };

    // 1. Test Admin Overview
    const overviewRes = await fetch("http://localhost:5000/api/admin/overview", { headers });
    const overviewData = await overviewRes.json();
    console.log("Admin Overview Status:", overviewRes.status);
    console.log("Admin Overview Response:", JSON.stringify(overviewData, null, 2));

    // 2. Test Call Settings
    const settingsRes = await fetch("http://localhost:5000/api/fees/calls/settings", { headers });
    const settingsData = await settingsRes.json();
    console.log("Call Settings Status:", settingsRes.status);
    console.log("Call Settings Response:", JSON.stringify(settingsData, null, 2));

    // 3. Test Manual Call Reminders Trigger
    const triggerRes = await fetch("http://localhost:5000/api/fees/calls/trigger", { method: "POST", headers });
    const triggerData = await triggerRes.json();
    console.log("Call Trigger Status:", triggerRes.status);
    console.log("Call Trigger Response:", JSON.stringify(triggerData, null, 2));
}

testAdminAndVoiceReminders();
