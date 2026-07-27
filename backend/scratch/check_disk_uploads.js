const path = require("path");
const fs = require("fs");

function checkDiskUploads() {
    const srcUploads = path.join(__dirname, "../src/uploads");
    const rootUploads = path.join(__dirname, "../uploads");

    console.log("=== src/uploads ===");
    if (fs.existsSync(srcUploads)) {
        console.log(fs.readdirSync(srcUploads));
    } else {
        console.log("Directory src/uploads does NOT exist!");
    }

    console.log("\n=== uploads (root) ===");
    if (fs.existsSync(rootUploads)) {
        console.log(fs.readdirSync(rootUploads));
    } else {
        console.log("Directory uploads (root) does NOT exist!");
    }
}

checkDiskUploads();
