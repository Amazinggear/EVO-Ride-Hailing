const { query } = require('../config/database');
const logger = require('../utils/logger');

const listAdmins = async (req, res) => {
  try {
    const { rows } = await query(
      `SELECT u.id, u.full_name, u.email, u.phone, u.role, u.admin_role, u.status, u.last_login_at, u.created_at,
              COALESCE(act.total_visits, 0) as total_page_visits,
              COALESCE(act.total_seconds, 0) as total_seconds,
              act.last_activity as last_page_visit
       FROM users u
       LEFT JOIN (
         SELECT admin_id,
                COUNT(*) as total_visits,
                COALESCE(SUM(duration_seconds), 0) as total_seconds,
                MAX(visited_at) as last_activity
         FROM admin_activity
         GROUP BY admin_id
       ) act ON act.admin_id = u.id
       WHERE u.role = 'admin'
       ORDER BY u.created_at DESC`
    );
    const admins = rows.map(r => ({
      ...r,
      total_hours: Math.round((parseInt(r.total_seconds) || 0) / 36) / 100, // seconds → hours with 2 decimals
      total_visits: parseInt(r.total_page_visits) || 0,
      last_seen: r.last_page_visit || r.last_login_at,
    }));
    return res.json({ admins });
  } catch (err) {
    logger.error('listAdmins error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch admins' });
  }
};

const createAdmin = async (req, res) => {
  try {
    const { fullName, email, phone, adminRole, password } = req.body;
    
    if (req.user.admin_role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admins can create new admins' });
    }

    if (!password || password.length < 6) {
      return res.status(400).json({ error: 'يجب أن تكون كلمة المرور 6 أحرف على الأقل' });
    }

    if (!fullName || !email) {
      return res.status(400).json({ error: 'الاسم والبريد الإلكتروني مطلوبان' });
    }

    // Check if email already exists
    const { rows: existing } = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'البريد الإلكتروني مستخدم مسبقاً' });
    }

    // Use provided phone or generate a unique one
    const crypto = require('crypto');
    const userPhone = phone || `09${crypto.randomBytes(4).toString('hex')}`;

    const { rows } = await query(
      `INSERT INTO users (full_name, email, phone, role, admin_role, status, password_hash)
       VALUES ($1, $2, $3, 'admin', $4, 'active', $5) RETURNING id, full_name, admin_role`,
      [fullName, email, userPhone, adminRole, password]
    );

    await query(
      `INSERT INTO admin_audit_logs (admin_id, action, target_type, target_id, details)
       VALUES ($1, 'create_admin', 'user', $2, $3)`,
      [req.user.id, rows[0].id, JSON.stringify({ adminRole })]
    );

    return res.status(201).json({ success: true, admin: rows[0] });
  } catch (err) {
    logger.error('createAdmin error:', err.message, err.stack);
    if (err.message.includes('unique_phone')) {
      return res.status(400).json({ error: 'رقم الهاتف مستخدم مسبقاً' });
    }
    if (err.message.includes('unique_email') || err.constraint === 'users_email_key') {
      return res.status(400).json({ error: 'البريد الإلكتروني مستخدم مسبقاً' });
    }
    return res.status(500).json({ error: 'فشل إنشاء الموظف. تأكد من صحة البيانات المدخلة.' });
  }
};

const updateAdminRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { adminRole, status } = req.body;

    if (req.user.admin_role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admins can modify admins' });
    }

    const updates = [];
    const values = [];
    let i = 1;

    if (adminRole) { updates.push(`admin_role = $${i++}`); values.push(adminRole); }
    if (status) { updates.push(`status = $${i++}`); values.push(status); }

    if (updates.length === 0) return res.status(400).json({ error: 'No fields to update' });

    values.push(id);
    const { rows } = await query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${i} AND role = 'admin' RETURNING id, full_name, admin_role, status`,
      values
    );

    if (!rows[0]) return res.status(404).json({ error: 'Admin not found' });

    return res.json({ success: true, admin: rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to update admin' });
  }
};

const deleteAdmin = async (req, res) => {
  try {
    const { id } = req.params;

    if (req.user.admin_role !== 'super_admin') {
      return res.status(403).json({ error: 'Only Super Admins can delete admins' });
    }

    // Don't allow self-deletion
    if (id === req.user.id) {
      return res.status(400).json({ error: 'Cannot delete your own account' });
    }

    const { rows: adminRows } = await query(
      "SELECT id, full_name, admin_role FROM users WHERE id = $1 AND role = 'admin'",
      [id]
    );
    if (!adminRows[0]) {
      return res.status(404).json({ error: 'Admin not found' });
    }

    // Don't allow deleting the last super_admin
    if (adminRows[0].admin_role === 'super_admin') {
      const { rows: superCount } = await query(
        "SELECT COUNT(*) as count FROM users WHERE admin_role = 'super_admin' AND role = 'admin'"
      );
      if (parseInt(superCount[0].count) <= 1) {
        return res.status(400).json({ error: 'Cannot delete the last Super Admin' });
      }
    }

    await query("DELETE FROM users WHERE id = $1 AND role = 'admin'", [id]);

    await query(
      `INSERT INTO admin_audit_logs (admin_id, action, target_type, target_id, details)
       VALUES ($1, 'delete_admin', 'user', $2, $3)`,
      [req.user.id, id, JSON.stringify({ fullName: adminRows[0].full_name, adminRole: adminRows[0].admin_role })]
    );

    return res.json({ success: true, message: `Admin ${adminRows[0].full_name} removed` });
  } catch (err) {
    logger.error('deleteAdmin error:', err.message);
    return res.status(500).json({ error: 'Failed to delete admin' });
  }
};

module.exports = { listAdmins, createAdmin, updateAdminRole, deleteAdmin };
