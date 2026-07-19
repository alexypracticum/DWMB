-- =============================================================================
--  Миграция: Добавление таблиц AI, Тем, Страниц, Меню, field_registry_label
--  Дата: 2026-07-17
-- =============================================================================

BEGIN;

-- =============================================================================
--  1. field_registry_label (мультиязычные описания полей)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.field_registry_label (
    field_id    UUID NOT NULL REFERENCES meta.field_registry(field_id) ON DELETE CASCADE,
    language    language_code NOT NULL,
    label       TEXT NOT NULL,
    description TEXT,
    PRIMARY KEY (field_id, language)
);

-- =============================================================================
--  2. user_theme (пользовательские темы)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.user_theme (
    theme_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES meta.user_account(user_id) ON DELETE CASCADE,
    theme_name  TEXT NOT NULL,
    is_dark     BOOLEAN NOT NULL DEFAULT false,
    is_active   BOOLEAN NOT NULL DEFAULT false,
    colors      JSONB NOT NULL DEFAULT '{
        "primary": "#3b82f6",
        "secondary": "#6366f1",
        "accent": "#f59e0b",
        "background": "#ffffff",
        "surface": "#f9fafb",
        "text": "#111827",
        "text_secondary": "#6b7280",
        "border": "#e5e7eb",
        "error": "#ef4444",
        "success": "#10b981"
    }'::jsonb,
    fonts       JSONB NOT NULL DEFAULT '{
        "heading": "Inter, sans-serif",
        "body": "Inter, sans-serif",
        "mono": "JetBrains Mono, monospace",
        "heading_size": "1.5rem",
        "body_size": "0.875rem"
    }'::jsonb,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  3. ai_config (настройки AI)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.ai_config (
    config_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider        TEXT NOT NULL DEFAULT 'openai',
    model_embedding TEXT NOT NULL DEFAULT 'text-embedding-3-small',
    model_chat      TEXT NOT NULL DEFAULT 'gpt-4o-mini',
    api_key_enc     BYTEA,
    api_base_url    TEXT DEFAULT 'https://api.openai.com/v1',
    max_tokens      INT NOT NULL DEFAULT 4096,
    is_active       BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  4. ai_task_log (лог AI-запросов)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.ai_task_log (
    task_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_type       TEXT NOT NULL,
    model_used      TEXT,
    input_tokens    INT DEFAULT 0,
    output_tokens   INT DEFAULT 0,
    cost_usd        NUMERIC(10,6) DEFAULT 0,
    duration_ms     INT,
    entity_id       UUID REFERENCES meta.entity(entity_id),
    status          TEXT NOT NULL DEFAULT 'pending',
    error_message   TEXT,
    payload         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_task_type ON meta.ai_task_log(task_type);
CREATE INDEX IF NOT EXISTS idx_ai_task_time ON meta.ai_task_log(created_at DESC);

-- =============================================================================
--  5. ai_suggestion (AI-предложения)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.ai_suggestion (
    suggestion_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID NOT NULL REFERENCES meta.entity(entity_id) ON DELETE CASCADE,
    suggestion_type TEXT NOT NULL,
    field_key       TEXT,
    suggested_value JSONB NOT NULL,
    confidence      NUMERIC(5,4) CHECK (confidence >= 0 AND confidence <= 1),
    is_accepted     BOOLEAN,
    reviewed_by     UUID REFERENCES meta.user_account(user_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_sug_entity ON meta.ai_suggestion(entity_id);
CREATE INDEX IF NOT EXISTS idx_ai_sug_type ON meta.ai_suggestion(suggestion_type);

-- =============================================================================
--  6. page_registry (реестр страниц)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.page_registry (
    page_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_code       TEXT NOT NULL UNIQUE,
    title           TEXT NOT NULL,
    title_en        TEXT,
    template_name   TEXT NOT NULL DEFAULT 'default',
    content         JSONB NOT NULL DEFAULT '{}'::jsonb,
    meta_title      TEXT,
    meta_description TEXT,
    is_published    BOOLEAN NOT NULL DEFAULT false,
    sort_order      INT NOT NULL DEFAULT 0,
    created_by      UUID REFERENCES meta.user_account(user_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  7. menu_item (элементы меню)
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.menu_item (
    menu_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id       UUID REFERENCES meta.menu_item(menu_id) ON DELETE CASCADE,
    menu_code       TEXT NOT NULL DEFAULT 'main',
    label           TEXT NOT NULL,
    label_en        TEXT,
    url             TEXT,
    icon            TEXT,
    sort_order      INT NOT NULL DEFAULT 0,
    is_visible      BOOLEAN NOT NULL DEFAULT true,
    required_role   TEXT,
    css_class       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menu_parent ON meta.menu_item(parent_id);
CREATE INDEX IF NOT EXISTS idx_menu_code ON meta.menu_item(menu_code);

-- =============================================================================
--  8. Изменения в существующих таблицах
-- =============================================================================

-- Увеличить embedding до 1536 (OpenAI text-embedding-3-small)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'meta' AND table_name = 'projection_state' AND column_name = 'embedding' AND udt_name = 'vector') THEN
        -- Проверяем размер vector
        PERFORM 1 FROM pg_attribute WHERE attname = 'embedding' AND atttypid = (SELECT oid FROM pg_type WHERE typname = 'vector');
    END IF;
END $$;

-- Пересоздать индекс embedding с новым размером
DROP INDEX IF EXISTS meta.idx_state_embedding;
-- Внимание: это работает только если таблица projection_state пуста или embedding уже vector(1536)
-- Для продакшена нужна миграция с ALTER COLUMN
CREATE INDEX IF NOT EXISTS idx_state_embedding ON meta.projection_state USING hnsw (embedding vector_cosine_ops);

-- user_account: добавить новые колонки
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS language_preference language_code DEFAULT 'ru';
ALTER TABLE meta.user_account ADD COLUMN IF NOT EXISTS theme_id UUID REFERENCES meta.user_theme(theme_id);

COMMIT;
