-- =============================================================================
--  Add image_url to entity table
--  Migration: 004_entity_image.sql
-- =============================================================================

ALTER TABLE meta.entity ADD COLUMN IF NOT EXISTS image_url TEXT;
