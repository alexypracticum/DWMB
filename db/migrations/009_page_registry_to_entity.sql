-- =============================================================================
--  Migration 009: page_registry → entity (kind='page')
--  Date: 2026-07-21
--  Философия: "Всё как сущность" — CMS страницы как сущности
-- =============================================================================

-- Step 1: Create entity_kind 'page'
INSERT INTO meta.entity_kind (kind_id, kind_code, description, is_abstract, sort_order, version_id)
SELECT gen_random_uuid(), 'page', 'CMS страница', false, 50, 1
WHERE NOT EXISTS (SELECT 1 FROM meta.entity_kind WHERE kind_code = 'page');

-- Add labels for page kind
INSERT INTO meta.entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id,
       CASE l.code WHEN 'ru' THEN 'Страница' WHEN 'en' THEN 'Page' ELSE 'Page' END,
       CASE l.code WHEN 'ru' THEN 'CMS страница для публикации контента' ELSE 'CMS page for content publishing' END
FROM meta.entity_kind ek, meta.language l
WHERE ek.kind_code = 'page'
  AND l.code IN ('ru', 'en')
  AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language_id = l.language_id);

-- Step 2: Create ontology_model 'cms'
INSERT INTO meta.ontology_model (model_id, model_code, domain, description, version_id)
SELECT gen_random_uuid(), 'cms', 'general', 'Модель мира для контент-страниц', 1
WHERE NOT EXISTS (SELECT 1 FROM meta.ontology_model WHERE model_code = 'cms');

-- Step 3: Create ontology_template for 'page'
INSERT INTO meta.ontology_template (template_id, template_code, template_name, model_id, kind_id, schema_definition, is_active, version_id)
SELECT
    gen_random_uuid(),
    'page_cms',
    'CMS Страница',
    (SELECT model_id FROM meta.ontology_model WHERE model_code = 'cms'),
    (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'page'),
    '{
        "properties": {
            "content": {"type": "object", "title": "Содержимое"},
            "template_name": {"type": "string", "title": "Шаблон", "default": "default"},
            "meta_title": {"type": "string", "title": "META заголовок"},
            "meta_description": {"type": "string", "title": "META описание"},
            "is_published": {"type": "boolean", "title": "Опубликована", "default": false},
            "sort_order": {"type": "integer", "title": "Порядок", "default": 0}
        }
    }'::jsonb,
    true,
    1
WHERE NOT EXISTS (SELECT 1 FROM meta.ontology_template WHERE template_code = 'page_cms');

-- Step 4: Migrate data from page_registry to entity
BEGIN;

-- 4.1 Create entities from page_registry
INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, owner_id, created_at, updated_at, version_id)
SELECT
    pr.page_id,
    pr.page_code,
    (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'page'),
    CASE WHEN pr.is_published THEN 'active'::meta.entity_status ELSE 'deprecated'::meta.entity_status END,
    pr.created_by,
    pr.created_at,
    pr.updated_at,
    1
FROM meta.page_registry pr;

-- 4.2 Create projections
INSERT INTO meta.entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, created_at, version_id)
SELECT
    gen_random_uuid(),
    pr.page_id,
    (SELECT model_id FROM meta.ontology_model WHERE model_code = 'cms'),
    'page_' || pr.page_code,
    pr.title,
    pr.created_at,
    1
FROM meta.page_registry pr;

-- 4.3 Migrate data to projection_state
INSERT INTO meta.projection_state (state_id, projection_id, state_data, state_hash, is_current, created_at, version_id)
SELECT
    gen_random_uuid(),
    (SELECT ep.projection_id FROM meta.entity_projection ep
     WHERE ep.entity_id = pr.page_id LIMIT 1),
    jsonb_build_object(
        'content', pr.content,
        'template_name', pr.template_name,
        'meta_title', pr.meta_title,
        'meta_description', pr.meta_description,
        'is_published', pr.is_published,
        'sort_order', pr.sort_order
    ),
    encode(sha256(
        (pr.content::text || pr.template_name || COALESCE(pr.meta_title, '') || COALESCE(pr.meta_description, '') || pr.is_published::text || pr.sort_order::text)::bytea
    ), 'hex'),
    true,
    pr.created_at,
    1
FROM meta.page_registry pr;

-- 4.4 Create entity_labels (Russian)
INSERT INTO meta.entity_label (entity_id, language_id, label, description, is_primary, owner_id, version_id)
SELECT
    pr.page_id,
    (SELECT language_id FROM meta.language WHERE code = 'ru'),
    pr.title,
    pr.meta_description,
    true,
    pr.created_by,
    1
FROM meta.page_registry pr
WHERE pr.title IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM meta.entity_label el
    WHERE el.entity_id = pr.page_id
      AND el.language_id = (SELECT language_id FROM meta.language WHERE code = 'ru')
  );

-- 4.5 Create entity_labels (English) if title_en exists
INSERT INTO meta.entity_label (entity_id, language_id, label, description, is_primary, owner_id, version_id)
SELECT
    pr.page_id,
    (SELECT language_id FROM meta.language WHERE code = 'en'),
    pr.title_en,
    pr.meta_description,
    false,
    pr.created_by,
    1
FROM meta.page_registry pr
WHERE pr.title_en IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM meta.entity_label el
    WHERE el.entity_id = pr.page_id
      AND el.language_id = (SELECT language_id FROM meta.language WHERE code = 'en')
  );

COMMIT;

-- =============================================================================
-- VERIFICATION
-- =============================================================================
-- SELECT COUNT(*) FROM meta.entity WHERE kind_id = (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'page');
-- SELECT COUNT(*) FROM meta.entity_projection ep
--   JOIN meta.entity e ON e.entity_id = ep.entity_id
--   WHERE e.kind_id = (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'page');
-- SELECT el.label, e.entity_code FROM meta.entity_label el
--   JOIN meta.entity e ON e.entity_id = el.entity_id
--   WHERE e.kind_id = (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'page')
--   AND el.is_primary = true;
