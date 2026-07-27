const { Pool } = require("pg");
const path = require("path");
const fs = require("fs");
require("dotenv").config({ path: path.join(__dirname, "../.env") });

const pool = new Pool({
    host: process.env.DB_HOST || "localhost",
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || "gsr_universe",
    user: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD || "postgres"
});

async function fixExistingDbPaths() {
    try {
        const srcUploads = path.join(__dirname, "../src/uploads");
        const pdfFiles = fs.readdirSync(srcUploads)
            .filter(f => f.endsWith(".pdf") && f !== "sample_submission.pdf")
            .map(f => ({
                name: f,
                time: fs.statSync(path.join(srcUploads, f)).mtimeMs
            }))
            .sort((a, b) => b.time - a.time);

        console.log("Found uploaded PDF files in src/uploads (most recent first):", pdfFiles);

        if (pdfFiles.length > 0) {
            const latestPdfPath = `/uploads/${pdfFiles[0].name}`;
            
            // Update homework_submissions where file_path does not exist on disk
            const hwSubs = await pool.query("SELECT id, file_path FROM homework_submissions");
            for (const row of hwSubs.rows) {
                const fullPath = path.join(srcUploads, path.basename(row.file_path));
                if (!fs.existsSync(fullPath)) {
                    console.log(`Fixing homework submission ID ${row.id}: ${row.file_path} -> ${latestPdfPath}`);
                    await pool.query("UPDATE homework_submissions SET file_path = $1 WHERE id = $2", [latestPdfPath, row.id]);
                }
            }

            // Update assignment_submissions where file_path does not exist on disk
            const assignSubs = await pool.query("SELECT id, file_path FROM assignment_submissions");
            for (const row of assignSubs.rows) {
                const fullPath = path.join(srcUploads, path.basename(row.file_path));
                if (!fs.existsSync(fullPath)) {
                    console.log(`Fixing assignment submission ID ${row.id}: ${row.file_path} -> ${latestPdfPath}`);
                    await pool.query("UPDATE assignment_submissions SET file_path = $1 WHERE id = $2", [latestPdfPath, row.id]);
                }
            }
        }

        console.log("DB paths update completed!");
    } catch (err) {
        console.error("Error fixing DB paths:", err);
    } finally {
        await pool.end();
    }
}

fixExistingDbPaths();
