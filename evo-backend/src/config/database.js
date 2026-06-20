const { Pool } = require('pg');
const logger = require('../utils/logger');

// ────────────────────────────────────────────
// PostgreSQL Connection Pool — Neon Cloud
// ────────────────────────────────────────────
// In production, we should ideally use env vars, but as a fallback for 1-click deployments, we provide the Neon DB URL
const connectionString = process.env.DATABASE_URL || 'postgresql://neondb_owner:npg_Pt3DRmLdsy8w@ep-square-bonus-atf93yt1-pooler.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

const pool = new Pool({
  connectionString: connectionString,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
  max: 20,                   // max connections in pool
  idleTimeoutMillis: 30000,  // close idle after 30s
  connectionTimeoutMillis: 5000,
});

pool.on('connect', () => {
  logger.info('✅ PostgreSQL (Neon) connected successfully');
});

pool.on('error', (err) => {
  logger.error('❌ PostgreSQL pool error:', err.message);
});

// Test connection removed for serverless compatibility

// ────────────────────────────────────────────
// Auto-migration: ensure password_hash column exists (awaited before first query)
// ────────────────────────────────────────────
let migrationReady;
const runMigration = async () => {
  try {
    await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT");
    await pool.query("UPDATE users SET password_hash = '123456' WHERE role = 'admin' AND password_hash IS NULL");
    // Track which admin registered each driver
    await pool.query("ALTER TABLE driver_profiles ADD COLUMN IF NOT EXISTS registered_by UUID REFERENCES users(id)");
    // Driver sessions for working hours / last seen
    await pool.query(`
      CREATE TABLE IF NOT EXISTS driver_sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(10) NOT NULL CHECK (status IN ('online','offline')),
        started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        ended_at TIMESTAMPTZ,
        duration_minutes INT GENERATED ALWAYS AS (
          CASE WHEN ended_at IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (ended_at - started_at)) / 60 
            ELSE NULL 
          END
        ) STORED
      )
    `);
    await pool.query("CREATE INDEX IF NOT EXISTS idx_driver_sessions_driver ON driver_sessions(driver_id)");
    await pool.query("CREATE INDEX IF NOT EXISTS idx_driver_sessions_status ON driver_sessions(status)");
    // Unique onboarding token for each driver
    await pool.query("ALTER TABLE driver_profiles ADD COLUMN IF NOT EXISTS onboarding_token TEXT UNIQUE");
    // Admin activity tracking (working hours, last page visit)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS admin_activity (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        admin_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        page VARCHAR(100),
        duration_seconds INT DEFAULT 0,
        visited_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);
    await pool.query("CREATE INDEX IF NOT EXISTS idx_admin_activity_admin ON admin_activity(admin_id)");
    logger.info('✅ Migrations v5 applied: registered_by, driver_sessions, onboarding_token, admin_activity');
  } catch (err) {
    logger.warn('⚠️ Migration v5 skipped:', err.message);
  }
};
migrationReady = runMigration();

// ────────────────────────────────────────────
// Query Helper
// ────────────────────────────────────────────
const query = async (text, params) => {
  await migrationReady;
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    if (duration > 1000) {
      logger.warn(`⚠️ Slow query (${duration}ms): ${text.substring(0, 100)}`);
    }
    return result;
  } catch (err) {
    logger.error('❌ Database query error:', {
      query: text.substring(0, 200),
      params,
      error: err.message,
    });
    throw err;
  }
};

const getClient = () => pool.connect();

module.exports = { query, getClient, pool };
