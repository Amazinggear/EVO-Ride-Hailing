-- ================================================
-- EVO Database Migrations v5
-- Admin referral system + driver work tracking
-- ================================================

-- Add registered_by to driver_profiles (which admin created this driver)
ALTER TABLE driver_profiles
  ADD COLUMN IF NOT EXISTS registered_by UUID REFERENCES users(id);

-- Add referral_code to users (unique link per admin)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS referral_code VARCHAR(12);

-- Make referral codes unique
ALTER TABLE users
  ADD CONSTRAINT IF NOT EXISTS unique_referral_code UNIQUE (referral_code);

-- Generate referral codes for existing admins
UPDATE users SET referral_code = CONCAT('EVO-', UPPER(LEFT(REPLACE(gen_random_uuid()::TEXT, '-', ''), 8)))
WHERE role = 'admin' AND referral_code IS NULL;

-- Add work tracking to driver_profiles
ALTER TABLE driver_profiles
  ADD COLUMN IF NOT EXISTS total_work_minutes INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;
