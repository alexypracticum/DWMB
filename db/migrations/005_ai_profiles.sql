-- =============================================================================
--  AI Config Profiles
--  Migration: 005_ai_profiles.sql
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.ai_config_profile (
    profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    provider TEXT NOT NULL DEFAULT 'openai',
    model_embedding TEXT NOT NULL DEFAULT 'text-embedding-3-small',
    model_chat TEXT NOT NULL DEFAULT 'gpt-4o-mini',
    api_key_enc BYTEA,
    api_base_url TEXT DEFAULT 'https://api.openai.com/v1',
    max_tokens INT NOT NULL DEFAULT 4096,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_profile_active ON meta.ai_config_profile(is_active);
