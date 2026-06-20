const { query } = require('../config/database');
const logger = require('../utils/logger');

const listAdmins = async (req, res) => {
  try {
    const { rows } = await query(
      `SELECT id, full_name, email, phone, role, admin_role, status, last_login_at, created_at 
       FROM users WHERE role = 'admin' ORDER BY created_at DESC`
    );
    return res.json({ admins: rows });
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
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Use provided phone or generate one (phone is required in DB but not in admin form)
    const userPhone = phone || `ADMIN-${Date.now()}`;

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
    if (err.message.includes('unique_phone')) {
      return res.status(400).json({ error: 'Phone number already exists' });
    }
    return res.status(500).json({ error: 'Failed to create admin' });
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
