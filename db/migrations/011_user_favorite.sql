-- Migration 011: Create user_favorite table for personal dashboard
CREATE TABLE IF NOT EXISTS meta.user_favorite (
    favorite_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES meta.user_account(user_id) ON DELETE CASCADE,
    entity_id UUID NOT NULL REFERENCES meta.entity(entity_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT uq_user_favorite UNIQUE (user_id, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_user_favorite_user ON meta.user_favorite(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorite_entity ON meta.user_favorite(entity_id);
