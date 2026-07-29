const db = require('../src/config/db');

async function inspectDB() {
    console.log("=== COMPREHENSIVE POSTGRESQL DB AUDIT ===");

    try {
        const tables = await db.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema='public' 
            ORDER BY table_name;
        `);
        console.log("Public Tables Found:", tables.rows.map(r => r.table_name));

        console.log("\n--- Students Table ---");
        const students = await db.query(`SELECT id, admission_no, student_name, primary_parent_mobile, secondary_parent_mobile FROM public.students;`);
        console.table(students.rows);

        console.log("\n--- Student Class Mapping ---");
        const scm = await db.query(`
            SELECT scm.id, scm.student_id, s.student_name, scm.class_id, c.class_name, c.section, scm.academic_year_id, scm.is_current 
            FROM public.student_class_mapping scm
            JOIN public.students s ON scm.student_id = s.id
            JOIN public.classes c ON scm.class_id = c.id;
        `);
        console.table(scm.rows);

        console.log("\n--- Admins Table ---");
        const admins = await db.query(`SELECT id, admin_name, email FROM public.admins;`);
        console.table(admins.rows);

        console.log("\n--- Faculty Table ---");
        const faculty = await db.query(`SELECT id, employee_id, faculty_name, email, is_active FROM public.faculty;`);
        console.table(faculty.rows);

        console.log("\n--- Fees Table Summary ---");
        const fees = await db.query(`
            SELECT f.id, f.student_class_mapping_id, s.student_name, f.total_fee, f.paid_amount, f.pending_amount 
            FROM public.fees f
            JOIN public.student_class_mapping scm ON f.student_class_mapping_id = scm.id
            JOIN public.students s ON scm.student_id = s.id;
        `);
        console.table(fees.rows);

        console.log("\n--- Attendance Logs Summary ---");
        const att = await db.query(`
            SELECT student_class_mapping_id, status, COUNT(*) as count 
            FROM public.attendance 
            GROUP BY student_class_mapping_id, status;
        `);
        console.table(att.rows);

        console.log("\n--- Call Settings ---");
        const cs = await db.query(`SELECT * FROM public.call_settings;`);
        console.table(cs.rows);

        process.exit(0);
    } catch (err) {
        console.error("DB Audit Error:", err);
        process.exit(1);
    }
}

inspectDB();
