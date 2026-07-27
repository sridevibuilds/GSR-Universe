require("dotenv").config();

const app = require("./src/app");

require("./src/config/db");

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);

    // Schedule automated fee reminder calls check
    const { runFeeRemindersCheck } = require("./src/services/reminderScheduler");
    
    // Execute check 5 seconds after server startup
    setTimeout(() => {
        runFeeRemindersCheck().catch(err => console.error("Initial reminder check failed:", err));
    }, 5000);

    // Re-check every 24 hours
    setInterval(() => {
        runFeeRemindersCheck().catch(err => console.error("Interval reminder check failed:", err));
    }, 24 * 60 * 60 * 1000);
});