-- Migration 012: Add email verification fields to user_account
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS verification_token VARCHAR;
CREATE INDEX IF NOT EXISTS idx_user_account_verification_token ON meta.user_account(verification_token);
