const pool = require('../backend/src/config/db');

async function inspect() {
  try {
    const tables = ['students', 'parents', 'assessments', 'announcements', 'fees', 'classes', 'academic_years'];
    for (const t of tables) {
      const res = await pool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = $1
      `, [t]);
      console.log(`=== TABLE: ${t} ===`);
      console.log(res.rows.map(r => `${r.column_name} (${r.data_type})`).join(', '));
    }
  } catch (e) {
    console.error(e);
  } finally {
    process.exit(0);
  }
}

inspect();
