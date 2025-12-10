-- Migration: Add new fields for enhanced signup process
-- Run with: wrangler d1 execute aurum-harmony-db --remote --file=worker/schema_migration_signup_improvements.sql

-- Add username/display_name field
ALTER TABLE users ADD COLUMN username TEXT;
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Add profile picture URL field
ALTER TABLE users ADD COLUMN profile_picture_url TEXT;

-- Add email verification fields
ALTER TABLE users ADD COLUMN email_verified INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE users ADD COLUMN email_verification_token TEXT;

-- Add terms accepted field
ALTER TABLE users ADD COLUMN terms_accepted INTEGER DEFAULT 0 NOT NULL;
ALTER TABLE users ADD COLUMN terms_accepted_at TEXT;

