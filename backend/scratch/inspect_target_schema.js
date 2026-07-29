const pool = require("../src/config/db");

async function inspectTargetTables() {
    const targetTables = [
        'academic_years', 'admins', 'assessments', 'assessment_results', 
        'students', 'student_class_mapping', 'classes', 'fees', 'attendance'
    ];
    
    for (const tableName of targetTables) {
        const columnsRes = await pool.query(`
            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = $1
            ORDER BY ordinal_position
        `, [tableName]);
        
        console.log(`\nTable: ${tableName}`);
        console.log(columnsRes.rows.map(c => `  - ${c.column_name} (${c.data_type})`).join("\n"));
    }
    
    // Also let's inspect actual row counts and sample values for current academic year & classes!
    console.log("\n=== DATA INSPECTION ===");
    const ayRes = await pool.query("SELECT * FROM public.academic_years");
    console.log("Academic Years:", ayRes.rows);
    
    const scmCount = await pool.query("SELECT COUNT(*) FROM public.student_class_mapping WHERE is_current = true");
    console.log("Active SCM Count:", scmCount.rows[0]);
    
    const studCount = await pool.query("SELECT COUNT(*) FROM public.students");
    console.log("Total Students in DB:", studCount.rows[0]);
    
    const feeTotals = await pool.query(`
        SELECT 
            COALESCE(SUM(f.total_fee), 0) as total_fee,
            COALESCE(SUM(f.paid_amount), 0) as paid_amount,
            COALESCE(SUM(f.total_fee - f.paid_amount), 0) as pending_fee
        FROM public.fees f
        JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
        WHERE scm.is_current = true
    `);
    console.log("Active Fee Totals from DB:", feeTotals.rows[0]);

    await pool.end();
}

inspectTargetTables();
