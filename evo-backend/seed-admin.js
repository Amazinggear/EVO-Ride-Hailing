const { query } = require('./src/config/database');

const seedAdminUser = async () => {
  try {
    console.log('🌱 Seeding admin user...');
    
    // Check if admin already exists
    const { rows } = await query(
      "SELECT id FROM users WHERE email = $1 AND role = 'admin'",
      ['admin@evo.jo']
    );
    
    if (rows[0]) {
      console.log('✅ Admin user already exists');
      return;
    }
    
    // Create admin user
    const adminId = `admin-${Date.now()}`;
    await query(
      `INSERT INTO users (id, phone, full_name, email, role, admin_role, status, preferred_language, firebase_uid, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())`,
      [
        adminId,
        '+962791234567',
        'الإدارة العامة',
        'admin@evo.jo',
        'admin',
        'super_admin',
        'active',
        'ar',
        `firebase-uid-${Date.now()}`
      ]
    );
    
    console.log('✅ Admin user created successfully');
    console.log('📧 Email: admin@evo.jo');
    console.log('🔐 Password: 123456');
  } catch (err) {
    console.error('❌ Error seeding admin:', err.message);
  } finally {
    process.exit(0);
  }
};

seedAdminUser();
