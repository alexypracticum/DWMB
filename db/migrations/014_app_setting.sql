-- Migration 014: Create app_setting table for runtime configuration
-- Stores API keys, email settings, security config in database

CREATE TABLE IF NOT EXISTS meta.app_setting (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT now(),
    updated_by TEXT
);

COMMENT ON TABLE meta.app_setting IS 'Runtime configuration settings (API keys, email, security)';
COMMENT ON COLUMN meta.app_setting.key IS 'Setting key (e.g. api_omdb_key, email_smtp_host)';
COMMENT ON COLUMN meta.app_setting.value IS 'Setting value as JSONB string';
