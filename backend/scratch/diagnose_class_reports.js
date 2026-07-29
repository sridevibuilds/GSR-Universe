const pool = require("../src/config/db");

async function diagnoseClassReportQuery() {
    console.log("=== DIAGNOSING STUDENT CLASS MAPPINGS & CLASSES ===");

    const mappings = await pool.query(`
        SELECT 
            scm.id as mapping_id,
            scm.student_id,
            s.student_name,
            s.class_name as student_class,
            s.section as student_sec,
            c.id as class_id,
            c.class_name as c_class_name,
            c.section as c_section,
            ay.id as ay_id,
            ay.year_name as ay_year_name,
            scm.is_current
        FROM public.student_class_mapping scm
        JOIN public.students s ON scm.student_id = s.id
        LEFT JOIN public.classes c ON scm.class_id = c.id
        LEFT JOIN public.academic_years ay ON scm.academic_year_id = ay.id
    `);

    console.log("Student Class Mappings:", mappings.rows);

    await pool.end();
}

diagnoseClassReportQuery();
