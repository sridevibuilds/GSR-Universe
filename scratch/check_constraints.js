const pool = require('./backend/src/config/db');

async function check() {
  try {
    const res = await pool.query(`
      SELECT conname, pg_get_constraintdef(oid) 
      FROM pg_constraint 
      WHERE conname LIKE '%holiday%' OR conname LIKE '%priority%' OR conname LIKE '%chk%'
    `);
    console.log("Constraints:", JSON.stringify(res.rows, null, 2));
  } catch (e) {
    console.error(e);
  } finally {
    process.exit(0);
  }
}

check();
