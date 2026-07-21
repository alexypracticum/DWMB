-- =============================================================================
--  Migration 008: UI String Entities for Multilingual Interface
--  Date: 2026-07-21
-- =============================================================================

-- Step 1: Create ui_string entity kind
INSERT INTO meta.entity_kind (kind_id, kind_code, description, is_abstract, sort_order, version_id)
SELECT gen_random_uuid(), 'ui_string', 'UI строка для интерфейса', false, 100, 1
WHERE NOT EXISTS (SELECT 1 FROM meta.entity_kind WHERE kind_code = 'ui_string');

-- Add labels for ui_string kind
INSERT INTO meta.entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 
       CASE l.code WHEN 'ru' THEN 'UI строка' WHEN 'en' THEN 'UI String' ELSE 'UI String' END,
       CASE l.code WHEN 'ru' THEN 'Строка интерфейса для мультиязычности' ELSE 'Interface string for multilingualism' END
FROM meta.entity_kind ek, meta.language l
WHERE ek.kind_code = 'ui_string'
  AND l.code IN ('ru', 'en')
  AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language_id = l.language_id);

-- Step 2: Create language ontology model (if not exists)
INSERT INTO meta.ontology_model (model_id, model_code, model_name, description, version_id)
SELECT gen_random_uuid(), 'language', 'Язык', 'Модель мира для языковых проекций', 1
WHERE NOT EXISTS (SELECT 1 FROM meta.ontology_model WHERE model_code = 'language');

-- Step 3: Create ui_translation template
INSERT INTO meta.ontology_template (template_id, template_code, template_name, model_id, kind_id, schema_definition, is_active, version_id)
SELECT 
    gen_random_uuid(),
    'ui_translation',
    'UI Перевод',
    (SELECT model_id FROM meta.ontology_model WHERE model_code = 'language'),
    (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'ui_string'),
    '{"properties": {"key": {"type": "string", "title": "Ключ"}, "value": {"type": "string", "title": "Значение"}}, "required": ["key", "value"]}'::jsonb,
    true,
    1
WHERE NOT EXISTS (SELECT 1 FROM meta.ontology_template WHERE template_code = 'ui_translation');

-- Step 4: Create default context (if not exists)
INSERT INTO meta.context (context_id, context_code, context_name, description, rules, version_id)
SELECT gen_random_uuid(), 'default', 'Default', 'Default context', '{}'::jsonb, 1
WHERE NOT EXISTS (SELECT 1 FROM meta.context WHERE context_code = 'default');

-- =============================================================================
-- VERIFICATION
-- =============================================================================
-- SELECT kind_code FROM meta.entity_kind WHERE kind_code = 'ui_string';
-- SELECT model_code FROM meta.ontology_model WHERE model_code = 'language';
-- SELECT template_code FROM meta.ontology_template WHERE template_code = 'ui_translation';
