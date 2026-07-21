-- =============================================================================
--  Migration 007: Replace language_code ENUM with language table
--  Date: 2026-07-21
-- =============================================================================

-- Step 1: Create meta.language table
CREATE TABLE IF NOT EXISTS meta.language (
    language_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(10) UNIQUE NOT NULL,
    name            VARCHAR(100) NOT NULL,
    native_name     VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Step 2: Insert base languages
INSERT INTO meta.language (code, name, native_name, sort_order) VALUES
    ('ru', 'Русский', 'Русский', 1),
    ('en', 'English', 'English', 2),
    ('de', 'Deutsch', 'Deutsch', 3),
    ('fr', 'Français', 'Français', 4),
    ('es', 'Español', 'Español', 5),
    ('zh', 'Chinese', '中文', 6),
    ('ja', 'Japanese', '日本語', 7)
ON CONFLICT (code) DO NOTHING;

-- Step 3: Add language_id columns (nullable first)
ALTER TABLE meta.entity_label
    ADD COLUMN IF NOT EXISTS language_id UUID REFERENCES meta.language(language_id);

ALTER TABLE meta.entity_kind_label
    ADD COLUMN IF NOT EXISTS language_id UUID REFERENCES meta.language(language_id);

ALTER TABLE meta.field_registry_label
    ADD COLUMN IF NOT EXISTS language_id UUID REFERENCES meta.language(language_id);

ALTER TABLE meta.user_account
    ADD COLUMN IF NOT EXISTS language_id UUID REFERENCES meta.language(language_id);

-- Step 4: Migrate data from ENUM to FK
-- entity_label
UPDATE meta.entity_label el
SET language_id = l.language_id
FROM meta.language l
WHERE el.language::text = l.code
  AND el.language_id IS NULL;

-- entity_kind_label
UPDATE meta.entity_kind_label ekl
SET language_id = l.language_id
FROM meta.language l
WHERE ekl.language::text = l.code
  AND ekl.language_id IS NULL;

-- field_registry_label
UPDATE meta.field_registry_label frl
SET language_id = l.language_id
FROM meta.language l
WHERE frl.language::text = l.code
  AND frl.language_id IS NULL;

-- user_account
UPDATE meta.user_account ua
SET language_id = l.language_id
FROM meta.language l
WHERE ua.language_preference::text = l.code
  AND ua.language_id IS NULL;

-- Step 5: Make language_id NOT NULL (after data migration)
ALTER TABLE meta.entity_label
    ALTER COLUMN language_id SET NOT NULL;

ALTER TABLE meta.entity_kind_label
    ALTER COLUMN language_id SET NOT NULL;

ALTER TABLE meta.field_registry_label
    ALTER COLUMN language_id SET NOT NULL;

-- Step 6: Drop old ENUM columns
ALTER TABLE meta.entity_label DROP COLUMN IF EXISTS language;
ALTER TABLE meta.entity_kind_label DROP COLUMN IF EXISTS language;
ALTER TABLE meta.field_registry_label DROP COLUMN IF EXISTS language;
ALTER TABLE meta.user_account DROP COLUMN IF EXISTS language_preference;

-- Step 7: Drop old composite PKs and recreate with language_id
-- entity_label: drop old PK, add new one
ALTER TABLE meta.entity_label DROP CONSTRAINT IF EXISTS entity_label_pkey;
ALTER TABLE meta.entity_label ADD PRIMARY KEY (entity_label_id);

-- entity_kind_label: drop old PK, add new one
ALTER TABLE meta.entity_kind_label DROP CONSTRAINT IF EXISTS entity_kind_label_pkey;
ALTER TABLE meta.entity_kind_label ADD PRIMARY KEY (kind_id, language_id);

-- field_registry_label: drop old PK, add new one
ALTER TABLE meta.field_registry_label DROP CONSTRAINT IF EXISTS field_registry_label_pkey;
ALTER TABLE meta.field_registry_label ADD PRIMARY KEY (field_id, language_id);

-- Step 8: Add unique constraints
ALTER TABLE meta.entity_label
    ADD CONSTRAINT uq_entity_label_entity_language
    UNIQUE (entity_id, language_id);

-- Step 9: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_entity_label_language_id ON meta.entity_label(language_id);
CREATE INDEX IF NOT EXISTS idx_entity_kind_label_language_id ON meta.entity_kind_label(language_id);
CREATE INDEX IF NOT EXISTS idx_field_registry_label_language_id ON meta.field_registry_label(language_id);
CREATE INDEX IF NOT EXISTS idx_user_account_language_id ON meta.user_account(language_id);
CREATE INDEX IF NOT EXISTS idx_language_code ON meta.language(code);

-- Step 10: Drop the old ENUM type (only if no other columns reference it)
-- NOTE: This may fail if other columns still reference the ENUM. 
-- In that case, skip this step and drop the ENUM manually later.
-- DROP TYPE IF EXISTS meta.language_code;

-- =============================================================================
-- VERIFICATION
-- =============================================================================
-- Run these to verify migration:
-- SELECT code, name, native_name FROM meta.language ORDER BY sort_order;
-- SELECT COUNT(*) as entity_labels_migrated FROM meta.entity_label WHERE language_id IS NOT NULL;
-- SELECT COUNT(*) as kind_labels_migrated FROM meta.entity_kind_label WHERE language_id IS NOT NULL;
-- SELECT COUNT(*) as field_labels_migrated FROM meta.field_registry_label WHERE language_id IS NOT NULL;
-- SELECT COUNT(*) as users_migrated FROM meta.user_account WHERE language_id IS NOT NULL;
