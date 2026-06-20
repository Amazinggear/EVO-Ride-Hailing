-- ================================================
-- EVO Database Migrations v4
-- Adds password_hash for per-admin login credentials
-- ================================================

-- Add password_hash column to users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Set default password for existing admins
UPDATE users SET password_hash = '123456' WHERE role = 'admin' AND password_hash IS NULL;
