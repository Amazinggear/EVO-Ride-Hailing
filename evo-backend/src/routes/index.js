const express = require('express');
const { authenticate, requireRole } = require('../middleware/auth');
const { verifyOtp, refreshToken, updateProfile, getMe } = require('../controllers/authController');
const {
  registerStep1, registerStep2, registerStep3, registerStep4,
  submitRegistration, getRegistrationStatus,
  getPendingDrivers, approveDriver, rejectDriver, requestMoreInfo,
} = require('../controllers/driverRegistrationController');
const {
  getNearbyDrivers, estimateFare, requestRide,
  acceptRide, startRide, completeRide, getRideHistory,
} = require('../controllers/rideController');
const walletController = require('../controllers/walletController');
const chargingController = require('../controllers/chargingController');
const promoController = require('../controllers/promoController');
const adminController = require('../controllers/adminController');
const {
  adminRechargeWallet, adminGetAllBalances, adminGetDriverHistory,
} = require('../controllers/walletController');
const { getComplaints, updateComplaintStatus, assignComplaint } = require('../controllers/complaintsController');
const { sendMassNotification, getNotificationHistory } = require('../controllers/notificationsController');
const { listAdmins, createAdmin, updateAdminRole, deleteAdmin } = require('../controllers/adminRBACController');

const router = express.Router();

// ────────────────────────────────────────────
// AUTH (Public & Protected)
// ────────────────────────────────────────────
router.post('/auth/verify-otp', verifyOtp);
router.post('/auth/refresh-token', refreshToken);
router.get('/auth/me', authenticate, getMe);
router.patch('/auth/profile', authenticate, updateProfile);

// ────────────────────────────────────────────
// DRIVER REGISTRATION (requires auth)
// ────────────────────────────────────────────
router.post('/driver/register/step-1', authenticate, registerStep1);
router.post('/driver/register/step-2', authenticate, registerStep2);
router.post('/driver/register/step-3', authenticate, registerStep3);
router.post('/driver/register/step-4', authenticate, registerStep4);
router.post('/driver/register/submit', authenticate, submitRegistration);
router.get('/driver/register/status', authenticate, getRegistrationStatus);

// ────────────────────────────────────────────
// PASSENGER RIDES
// ────────────────────────────────────────────
router.get('/rides/nearby-drivers', authenticate, requireRole('passenger'), getNearbyDrivers);
router.post('/rides/estimate', authenticate, estimateFare);
router.post('/rides/request', authenticate, requireRole('passenger'), requestRide);
router.get('/rides/history', authenticate, getRideHistory);
router.patch('/rides/:id/cancel', authenticate, async (req, res) => {
  const { query } = require('../config/database');
  const { id } = req.params;
  const userId = req.user.id;
  const { reason } = req.body;
  const field = req.user.role === 'driver' ? 'driver_id' : 'passenger_id';
  await query(
    `UPDATE rides SET status = 'cancelled', cancelled_at = NOW(), cancelled_by = $1, cancellation_reason = $2
     WHERE id = $3 AND ${field} = $4 AND status NOT IN ('completed', 'cancelled')`,
    [req.user.role, reason || null, id, userId]
  );
  res.json({ success: true });
});

// ────────────────────────────────────────────
// DRIVER OPERATIONS
// ────────────────────────────────────────────
router.patch('/driver/toggle-online', authenticate, requireRole('driver'), async (req, res) => {
  const { setDriverOnline, setDriverOffline } = require('../config/redis');
  const { query } = require('../config/database');
  const { isOnline } = req.body;
  const userId = req.user.id;
  if (isOnline) {
    const { rows } = await query('SELECT car_type, approval_status FROM driver_profiles WHERE user_id = $1', [userId]);
    if (!rows[0] || rows[0].approval_status !== 'approved') {
      return res.status(403).json({ error: 'Account not approved', code: 'DRIVER_NOT_APPROVED' });
    }
    await setDriverOnline(userId, rows[0].car_type);
    await query('UPDATE driver_profiles SET is_online = true WHERE user_id = $1', [userId]);
    // Start new session
    await query("INSERT INTO driver_sessions (driver_id, status) VALUES ($1, 'online')", [userId]);
  } else {
    await setDriverOffline(userId);
    await query('UPDATE driver_profiles SET is_online = false WHERE user_id = $1', [userId]);
    // End latest open session
    await query(
      "UPDATE driver_sessions SET status = 'offline', ended_at = NOW() WHERE driver_id = $1 AND status = 'online' AND ended_at IS NULL",
      [userId]
    );
  }
  res.json({ success: true, isOnline });
});

router.patch('/rides/:id/accept', authenticate, requireRole('driver'), acceptRide);
router.patch('/rides/:id/arrive', authenticate, requireRole('driver'), async (req, res) => {
  const { query } = require('../config/database');
  await query(`UPDATE rides SET status = 'arrived', arrived_at = NOW() WHERE id = $1 AND driver_id = $2`, [req.params.id, req.user.id]);
  res.json({ success: true, status: 'arrived' });
});
router.patch('/rides/:id/start', authenticate, requireRole('driver'), startRide);
router.patch('/rides/:id/complete', authenticate, requireRole('driver'), completeRide);

// ────────────────────────────────────────────
// WALLET (Driver - Prepaid System)
// ────────────────────────────────────────────
router.get('/wallet/balance', authenticate, requireRole('driver'), walletController.getBalance);
router.get('/wallet/transactions', authenticate, requireRole('driver'), walletController.getTransactions);
// ❌ REMOVED: /wallet/redeem-voucher (scratch cards cancelled)
// ❌ REMOVED: /wallet/withdraw (no bank payouts)

// ────────────────────────────────────────────
// CHARGING STATIONS
// ────────────────────────────────────────────
router.get('/charging-stations', authenticate, chargingController.getNearbyStations);
router.get('/charging-stations/:id', authenticate, chargingController.getStationById);

// ────────────────────────────────────────────
// PROMO CODES
// ────────────────────────────────────────────
router.post('/promo/validate', authenticate, promoController.validatePromo);

// ────────────────────────────────────────────
// ADMIN ROUTES
// ────────────────────────────────────────────
const adminRouter = express.Router();

adminRouter.post('/login', async (req, res) => {
  const { query } = require('../config/database');
  const { email, password } = req.body;
  
  const { rows } = await query(
    "SELECT id, full_name, role, admin_role, status, COALESCE(password_hash, '123456') as password_hash FROM users WHERE email = $1 AND role = 'admin'",
    [email]
  );
  if (!rows[0] || rows[0].status === 'suspended') {
    return res.status(401).json({ error: 'الحساب غير موجود أو موقوف' });
  }
  
  if (password !== rows[0].password_hash) {
    return res.status(401).json({ error: 'كلمة المرور أو البريد الإلكتروني غير صحيح' });
  }
  
  await query('UPDATE users SET last_login_at = NOW() WHERE id = $1', [rows[0].id]);
  
  const jwt = require('jsonwebtoken');
  const jwtSecret = process.env.JWT_SECRET || 'evo-jwt-secret-145555-594162-change-in-production';
  const token = jwt.sign({ userId: rows[0].id, role: 'admin' }, jwtSecret, { expiresIn: '1d' });
  return res.json({ accessToken: token, user: rows[0] });
});

// ────────────────────────────────────────────
// Role-based access: which admin_role can access which route groups
// ────────────────────────────────────────────
const ALL_ADMIN_ROLES = ['super_admin', 'operations', 'finance', 'support'];

adminRouter.use(authenticate, requireRole('admin'));

// Helper: gate routes to specific admin roles (super_admin always passes)
const gate = (...roles) => requireRole('super_admin', ...roles);

adminRouter.get('/dashboard/stats', adminController.getDashboardStats);
adminRouter.get('/stats', adminController.getDashboardStats); // alias

// Users
adminRouter.get('/users', gate('operations', 'support'), adminController.listUsers);
adminRouter.get('/users/:id', gate('operations', 'support'), adminController.getUserDetails);
adminRouter.patch('/users/:id/status', gate('operations', 'support'), adminController.updateUserStatus);

// Driver Approval
adminRouter.get('/drivers/pending', gate('operations'), getPendingDrivers);
adminRouter.get('/drivers/:id/documents', gate('operations'), adminController.getDriverDocuments);
adminRouter.post('/drivers/:id/approve', gate('operations'), approveDriver);
adminRouter.post('/drivers/:id/reject', gate('operations'), rejectDriver);
adminRouter.post('/drivers/:id/request-info', gate('operations'), requestMoreInfo);

// Captain Management (Create/Delete)
adminRouter.post('/drivers', gate('operations'), adminController.createDriver);
adminRouter.delete('/drivers/:id', gate('operations'), adminController.deleteDriver);

// ── Driver Onboarding (public link — no auth, uses token) ──
router.get('/admin/drivers/onboarding/:token', async (req, res) => {
  const { query } = require('../config/database');
  try {
    const { rows } = await query(
      `SELECT u.full_name, u.phone, u.email,
              dp.car_type, dp.car_model, dp.car_plate, dp.approval_status,
              dp.national_id_front_url, dp.national_id_back_url,
              dp.personal_photo_url, dp.license_photo_url, dp.criminal_clearance_url
       FROM driver_profiles dp
       JOIN users u ON u.id = dp.user_id
       WHERE dp.onboarding_token = $1`,
      [req.params.token]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Invalid or expired link' });
    return res.json({ driver: rows[0] });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to load driver' });
  }
});

router.post('/admin/drivers/onboarding/:token', async (req, res) => {
  const { query } = require('../config/database');
  try {
    const { national_id_front, national_id_back, personal_photo, license_photo, criminal_clearance } = req.body;
    // Validate at least one file uploaded
    if (!national_id_front && !national_id_back && !personal_photo && !license_photo && !criminal_clearance) {
      return res.status(400).json({ error: 'يرجى رفع مستند واحد على الأقل' });
    }
    const updates = [];
    const values = [];
    let i = 1;
    if (national_id_front) { updates.push(`national_id_front_url = $${i++}`); values.push(national_id_front); }
    if (national_id_back) { updates.push(`national_id_back_url = $${i++}`); values.push(national_id_back); }
    if (personal_photo) { updates.push(`personal_photo_url = $${i++}`); values.push(personal_photo); }
    if (license_photo) { updates.push(`license_photo_url = $${i++}`); values.push(license_photo); }
    if (criminal_clearance) { updates.push(`criminal_clearance_url = $${i++}`); values.push(criminal_clearance); }
    values.push(req.params.token);
    const { rows } = await query(
      `UPDATE driver_profiles SET ${updates.join(', ')} WHERE onboarding_token = $${i} RETURNING user_id`,
      values
    );
    if (!rows[0]) return res.status(404).json({ error: 'Invalid token' });
    return res.json({ success: true, message: 'Documents uploaded successfully' });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to upload documents' });
  }
});

// Live tracking
adminRouter.get('/rides/live', gate('operations'), adminController.getLiveRides);

// Admin rides list (paginated)
adminRouter.get('/rides', gate('operations'), async (req, res) => {
  const { query } = require('../config/database');
  try {
    const { status, from, to, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const conditions = [];
    const values = [];
    let i = 1;

    if (status) { conditions.push(`r.status = $${i++}`); values.push(status); }
    if (from) { conditions.push(`r.created_at >= $${i++}`); values.push(from); }
    if (to) { conditions.push(`r.created_at <= $${i++}`); values.push(to + ' 23:59:59'); }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const { rows } = await query(
      `SELECT r.id, r.status, r.car_type, r.distance_km, r.total_fare, r.commission_amount,
              r.created_at, r.completed_at,
              pu.full_name as passenger_name,
              du.full_name as driver_name,
              dp.car_plate, dp.car_model,
              r.pickup_address as pickup_area, r.dropoff_address as dropoff_area
       FROM rides r
       JOIN users pu ON pu.id = r.passenger_id
       LEFT JOIN users du ON du.id = r.driver_id
       LEFT JOIN driver_profiles dp ON dp.user_id = r.driver_id
       ${where}
       ORDER BY r.created_at DESC
       LIMIT $${i++} OFFSET $${i}`,
      [...values, limit, offset]
    );

    const { rows: countRows } = await query(
      `SELECT
        COUNT(*) as total,
        COALESCE(SUM(CASE WHEN r.status='completed' THEN r.total_fare ELSE 0 END), 0) as total_revenue,
        COALESCE(SUM(CASE WHEN r.status='completed' THEN r.commission_amount ELSE 0 END), 0) as total_commission
       FROM rides r ${where}`,
      values
    );

    const total = parseInt(countRows[0].total);
    const formattedRides = rows.map(r => ({
      ...r,
      ride_number: `EVO-${r.id.toString().slice(0, 5).toUpperCase()}`,
      fare: parseFloat(r.total_fare) || 0,
      commission: parseFloat(r.commission_amount) || parseFloat((r.total_fare * 0.13).toFixed(3)),
      distance_km: parseFloat(r.distance_km) || 0,
    }));

    return res.json({
      rides: formattedRides,
      total,
      page: parseInt(page),
      total_pages: Math.ceil(total / limit),
      summary: {
        total_rides: total,
        total_revenue: parseFloat(countRows[0].total_revenue),
        total_commission: parseFloat(countRows[0].total_commission),
      },
    });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch rides', details: err.message });
  }
});

// Admin drivers list — filtered by registered_by for non-super_admin
adminRouter.get('/drivers', gate('operations'), async (req, res) => {
  const { query } = require('../config/database');
  try {
    const { status, search } = req.query;
    const conditions = [];
    const values = [];
    let i = 1;

    if (status && status !== 'all') { conditions.push(`dp.approval_status = $${i++}`); values.push(status); }
    if (search) { conditions.push(`(u.full_name ILIKE $${i} OR u.phone ILIKE $${i} OR dp.car_plate ILIKE $${i})`); values.push(`%${search}%`); i++; }
    // Non-super_admin sees only their own registered drivers
    if (req.user.admin_role !== 'super_admin') {
      conditions.push(`dp.registered_by = $${i++}`); values.push(req.user.id);
    }

    const where = conditions.length ? `AND ${conditions.join(' AND ')}` : '';

    const { rows } = await query(
      `SELECT u.id, u.full_name, u.phone, u.last_login_at,
              dp.car_type, dp.car_model, dp.car_plate, dp.approval_status,
              dp.rating, dp.wallet_balance, dp.total_rides, dp.cliq_alias,
              dp.national_id_number, dp.license_number,
              dp.national_id_front_url, dp.national_id_back_url,
              dp.personal_photo_url, dp.license_photo_url, dp.criminal_clearance_url,
              dp.registered_by, dp.onboarding_token,
              adm.full_name as registered_by_name,
              u.created_at,
              COALESCE(ds.total_hours, 0) as working_hours,
              GREATEST(u.last_login_at, ds.last_online) as last_seen
       FROM users u
       JOIN driver_profiles dp ON dp.user_id = u.id
       LEFT JOIN users adm ON adm.id = dp.registered_by
       LEFT JOIN (
         SELECT driver_id,
                ROUND(SUM(EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - started_at)) / 3600)::numeric, 1) as total_hours,
                MAX(started_at) as last_online
         FROM driver_sessions
         GROUP BY driver_id
       ) ds ON ds.driver_id = u.id
       WHERE u.role = 'driver' ${where}
       ORDER BY u.created_at DESC`,
      values
    );

    const formatted = rows.map(r => ({
      id: r.id,
      full_name: r.full_name,
      phone: r.phone,
      car_type: r.car_type,
      car_model: r.car_model,
      car_plate: r.car_plate,
      approval_status: r.approval_status,
      rating: parseFloat(r.rating) || 0,
      wallet_balance: parseFloat(r.wallet_balance) || 0,
      total_rides: parseInt(r.total_rides) || 0,
      cliq_alias: r.cliq_alias,
      national_id_number: r.national_id_number,
      license_number: r.license_number,
      national_id_front_url: r.national_id_front_url,
      national_id_back_url: r.national_id_back_url,
      personal_photo_url: r.personal_photo_url,
      license_photo_url: r.license_photo_url,
      criminal_clearance_url: r.criminal_clearance_url,
      registered_by: r.registered_by,
      registered_by_name: r.registered_by_name,
      onboarding_token: r.onboarding_token,
      working_hours: parseFloat(r.working_hours) || 0,
      last_seen: r.last_seen || r.last_login_at,
      created_at: r.created_at,
    }));

    return res.json({ drivers: formatted, total: formatted.length });
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch drivers', details: err.message });
  }
});

// Pricing
adminRouter.get('/pricing', gate('finance'), adminController.getPricing);
adminRouter.patch('/pricing/:carType', gate('finance'), adminController.updatePricing);

// Surge zones
adminRouter.get('/surge-zones', gate('operations'), adminController.getSurgeZones);
adminRouter.post('/surge-zones', gate('operations'), adminController.createSurgeZone);
adminRouter.patch('/surge-zones/:id', gate('operations'), adminController.updateSurgeZone);

// Promo codes
adminRouter.get('/promo-codes', gate('finance'), adminController.listPromoCodes);
adminRouter.post('/promo-codes', gate('finance'), adminController.createPromoCode);
adminRouter.patch('/promo-codes/:id', gate('finance'), adminController.updatePromoCode);
adminRouter.delete('/promo-codes/:id', gate('finance'), adminController.deletePromoCode);

// Wallet Management (Admin recharges driver wallets by plate number)
adminRouter.post('/wallet/recharge', gate('finance'), adminRechargeWallet);
adminRouter.get('/wallet/balances', gate('finance'), adminGetAllBalances);
adminRouter.get('/wallet/history/:driverId', gate('finance'), adminGetDriverHistory);

// Charging stations
adminRouter.get('/charging-stations', gate('operations'), chargingController.adminListAllStations);
adminRouter.post('/charging-stations', gate('operations'), chargingController.adminAddStation);
adminRouter.patch('/charging-stations/:id', gate('operations'), chargingController.adminUpdateStation);
adminRouter.delete('/charging-stations/:id', gate('operations'), chargingController.adminDeleteStation);
adminRouter.post('/charging-stations/sync', gate('operations'), chargingController.adminSyncFromOCM);

// Financials
adminRouter.get('/financials/summary', gate('finance'), adminController.getFinancialSummary);
adminRouter.get('/financials/transactions', gate('finance'), adminController.getAllTransactions);
// ❌ REMOVED: /payouts/process (no bank payouts)
adminRouter.get('/audit-logs', gate('support'), adminController.getAuditLogs);

// Complaints
adminRouter.get('/complaints', gate('support'), getComplaints);
adminRouter.patch('/complaints/:id/status', gate('support'), updateComplaintStatus);
adminRouter.patch('/complaints/:id/assign', gate('support'), assignComplaint);

// Notifications
adminRouter.post('/notifications/send', gate('support'), sendMassNotification);
adminRouter.get('/notifications/history', gate('support'), getNotificationHistory);

// Admin Management (RBAC) — super_admin only
adminRouter.get('/admins', gate('super_admin'), listAdmins);
adminRouter.post('/admins', gate('super_admin'), createAdmin);
adminRouter.patch('/admins/:id/role', gate('super_admin'), updateAdminRole);
adminRouter.delete('/admins/:id', gate('super_admin'), deleteAdmin);

// Admin activity tracking — ping endpoint
adminRouter.post('/activity/ping', async (req, res) => {
  const { query } = require('../config/database');
  try {
    const { page } = req.body;
    await query(
      "INSERT INTO admin_activity (admin_id, page) VALUES ($1, $2)",
      [req.user.id, page || '/']
    );
    return res.json({ ok: true });
  } catch {
    return res.json({ ok: false });
  }
});

// Backup
adminRouter.get('/backup/export', async (req, res) => {
  const { performBackup } = require('../utils/backupService');
  try {
    if (req.user.admin_role !== 'super_admin' && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    const data = await performBackup();
    res.setHeader('Content-disposition', 'attachment; filename=evo_backup.json');
    res.setHeader('Content-type', 'application/json');
    res.send(JSON.stringify(data, null, 2));
  } catch (err) {
    res.status(500).json({ error: 'Backup failed' });
  }
});

router.use('/admin', adminRouter);

module.exports = router;
