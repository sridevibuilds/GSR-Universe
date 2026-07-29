const pool = require("../src/config/db");

async function inspectSchema() {
    try {
        console.log("=== INSPECTING LIVE POSTGRESQL TABLES & COLUMNS ===");
        const tablesRes = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        `);
        
        for (const row of tablesRes.rows) {
            const tableName = row.table_name;
            const columnsRes = await pool.query(`
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = $1
                ORDER BY ordinal_position
            `, [tableName]);
            
            console.log(`\nTable: ${tableName}`);
            console.log(columnsRes.rows.map(c => `  - ${c.column_name} (${c.data_type})`).join("\n"));
        }
    } catch (err) {
        console.error("Schema inspection error:", err);
    } finally {
        await pool.end();
    }
}

inspectSchema();
