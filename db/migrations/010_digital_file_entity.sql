-- =============================================================================
--  Migration 010: media_asset → entity kind='digital_file'
--  Date: 2026-07-21
--  Философия: media_asset остаётся как sidecar для производительности,
--  но CRUD идёт через entity interface
-- =============================================================================

-- Step 1: Create entity_kind 'digital_file'
INSERT INTO meta.entity_kind (kind_id, kind_code, description, is_abstract, sort_order, version_id)
SELECT gen_random_uuid(), 'digital_file', 'Файл хранения', false, 60, 1
WHERE NOT EXISTS (SELECT 1 FROM meta.entity_kind WHERE kind_code = 'digital_file');

-- Add labels for digital_file kind
INSERT INTO meta.entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id,
       CASE l.code WHEN 'ru' THEN 'Файл' WHEN 'en' THEN 'File' ELSE 'File' END,
       CASE l.code WHEN 'ru' THEN 'Файл хранения с метаданными' ELSE 'Storage file with metadata' END
FROM meta.entity_kind ek, meta.language l
WHERE ek.kind_code = 'digital_file'
  AND l.code IN ('ru', 'en')
  AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language_id = l.language_id);

-- Step 2: Create ontology_model 'storage'
INSERT INTO meta.ontology_model (model_id, model_code, domain, description, version_id)
SELECT gen_random_uuid(), 'storage', 'general', 'Модель мира для файлов хранения', 1
WHERE NOT EXISTS (SELECT 1 FROM meta.ontology_model WHERE model_code = 'storage');

-- Step 3: Create ontology_template for 'digital_file'
INSERT INTO meta.ontology_template (template_id, template_code, template_name, model_id, kind_id, schema_definition, is_active, version_id)
SELECT
    gen_random_uuid(),
    'digital_file_storage',
    'Файл хранилища',
    (SELECT model_id FROM meta.ontology_model WHERE model_code = 'storage'),
    (SELECT kind_id FROM meta.entity_kind WHERE kind_code = 'digital_file'),
    '{
        "properties": {
            "original_name": {"type": "string", "title": "Оригинальное имя"},
            "mime_type": {"type": "string", "title": "MIME тип"},
            "size_bytes": {"type": "integer", "title": "Размер (байты)"},
            "file_hash": {"type": "string", "title": "SHA256 хеш"},
            "storage_key": {"type": "string", "title": "Ключ хранилища"},
            "storage_backend": {"type": "string", "title": "Бэкенд хранилища", "enum": ["local", "nfs", "s3"]},
            "width": {"type": "integer", "title": "Ширина (px)"},
            "height": {"type": "integer", "title": "Высота (px)"},
            "duration_secs": {"type": "number", "title": "Длительность (сек)"},
            "is_processed": {"type": "boolean", "title": "Обработан", "default": false}
        }
    }'::jsonb,
    true,
    1
WHERE NOT EXISTS (SELECT 1 FROM meta.ontology_template WHERE template_code = 'digital_file_storage');

-- =============================================================================
-- VERIFICATION
-- =============================================================================
-- SELECT kind_code FROM meta.entity_kind WHERE kind_code = 'digital_file';
-- SELECT model_code FROM meta.ontology_model WHERE model_code = 'storage';
-- SELECT template_code FROM meta.ontology_template WHERE template_code = 'digital_file_storage';
