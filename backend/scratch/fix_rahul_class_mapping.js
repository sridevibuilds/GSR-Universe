const db = require("c:/UNIVERSE SOLUTIONS/GSR Universe/backend/src/config/db");

async function fixRahulClassMapping() {
  console.log("=== FIXING RAHUL KUMAR CLASS MAPPING & TIMETABLE ===");

  // 1. Set Rahul Kumar (student_id = 1) to Class 8 Section B (class_id = 19)
  await db.query("UPDATE public.student_class_mapping SET class_id = 19 WHERE student_id = 1");
  console.log("✅ Updated Rahul Kumar (student_id = 1) SCM records to class_id = 19 (Class 8 Section B).");

  // 2. Set Timetable ID 4 to class_id = 19 (Class 8 Section B)
  await db.query("UPDATE public.timetable SET class_id = 19 WHERE id = 4");
  console.log("✅ Updated Timetable ID 4 to class_id = 19 (Class 8 Section B).");

  process.exit(0);
}

fixRahulClassMapping();
