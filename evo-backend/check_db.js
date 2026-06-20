const { query, pool } = require('./src/config/database');
async function run() {
  try {
    const { rows } = await query("SELECT id, email, phone, role, admin_role, status FROM users");
    console.log("USERS:", rows);
  } catch (err) {
    console.error("DB error:", err);
  } finally {
    await pool.end();
  }
}
run();
