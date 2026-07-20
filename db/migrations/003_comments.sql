-- =============================================================================
--  Comments table
--  Migration: 003_comments.sql
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.comment (
    comment_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id   UUID NOT NULL REFERENCES meta.entity(entity_id) ON DELETE CASCADE,
    user_id     UUID REFERENCES meta.user_account(user_id) ON DELETE SET NULL,
    parent_id   UUID REFERENCES meta.comment(comment_id) ON DELETE CASCADE,
    content     TEXT NOT NULL,
    is_approved BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_comment_entity ON meta.comment(entity_id);
CREATE INDEX IF NOT EXISTS idx_comment_user ON meta.comment(user_id);
CREATE INDEX IF NOT EXISTS idx_comment_parent ON meta.comment(parent_id);
