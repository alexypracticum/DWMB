-- =============================================================================
--  Workflow state for entities
--  Migration: 002_workflow.sql
-- =============================================================================

ALTER TABLE meta.entity ADD COLUMN IF NOT EXISTS workflow_state TEXT DEFAULT 'published';

-- Set existing entities to 'published'
UPDATE meta.entity SET workflow_state = 'published' WHERE workflow_state IS NULL;
