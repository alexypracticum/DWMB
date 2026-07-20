-- =============================================================================
--  Language and Classifier entities
--  Migration: 006_languages.sql
-- =============================================================================

-- Create language entity kind if not exists
INSERT INTO meta.entity_kind (kind_id, kind_code, description, is_abstract, sort_order, version_id)
SELECT gen_random_uuid(), 'language', 'Язык', false, 50, 1
WHERE NOT EXISTS (SELECT 1 FROM meta.entity_kind WHERE kind_code = 'language');

-- Create classifier entity kind if not exists
INSERT INTO meta.entity_kind (kind_id, kind_code, description, is_abstract, sort_order, version_id)
SELECT gen_random_uuid(), 'classifier', 'Классификатор', false, 51, 1
WHERE NOT EXISTS (SELECT 1 FROM meta.entity_kind WHERE kind_code = 'classifier');

-- Add language labels
INSERT INTO meta.entity_kind_label (kind_id, language, label, description)
SELECT ek.kind_id, 'ru', 'Язык', 'Язык'
FROM meta.entity_kind ek WHERE ek.kind_code = 'language'
AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language = 'ru');

INSERT INTO meta.entity_kind_label (kind_id, language, label, description)
SELECT ek.kind_id, 'en', 'Language', 'Language'
FROM meta.entity_kind ek WHERE ek.kind_code = 'language'
AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language = 'en');

INSERT INTO meta.entity_kind_label (kind_id, language, label, description)
SELECT ek.kind_id, 'ru', 'Классификатор', 'Классификатор'
FROM meta.entity_kind ek WHERE ek.kind_code = 'classifier'
AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language = 'ru');

INSERT INTO meta.entity_kind_label (kind_id, language, label, description)
SELECT ek.kind_id, 'en', 'Classifier', 'Classifier'
FROM meta.entity_kind ek WHERE ek.kind_code = 'classifier'
AND NOT EXISTS (SELECT 1 FROM meta.entity_kind_label WHERE kind_id = ek.kind_id AND language = 'en');

-- Create classifier entities
INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
SELECT gen_random_uuid(), 'iso_639_1', ek.kind_id, 'active', 1
FROM meta.entity_kind ek WHERE ek.kind_code = 'classifier'
AND NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'iso_639_1');

INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
SELECT gen_random_uuid(), 'iso_639_2', ek.kind_id, 'active', 1
FROM meta.entity_kind ek WHERE ek.kind_code = 'classifier'
AND NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'iso_639_2');

INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
SELECT gen_random_uuid(), 'gost_7.75', ek.kind_id, 'active', 1
FROM meta.entity_kind ek WHERE ek.kind_code = 'classifier'
AND NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'gost_7.75');

-- Create labels for classifiers
INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
SELECT e.entity_id, 'ru', 'ISO 639-1', 'Двухбуквенные коды языков', true, 1
FROM meta.entity e WHERE e.entity_code = 'iso_639_1'
AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');

INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
SELECT e.entity_id, 'en', 'ISO 639-1', 'Two-letter language codes', true, 1
FROM meta.entity e WHERE e.entity_code = 'iso_639_1'
AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');

INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
SELECT e.entity_id, 'ru', 'ISO 639-2', 'Трёхбуквенные коды языков', true, 1
FROM meta.entity e WHERE e.entity_code = 'iso_639_2'
AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');

INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
SELECT e.entity_id, 'en', 'ISO 639-2', 'Three-letter language codes', true, 1
FROM meta.entity e WHERE e.entity_code = 'iso_639_2'
AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');

INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
SELECT e.entity_id, 'ru', 'ГОСТ 7.75-97', 'Российский стандарт кодов языков', true, 1
FROM meta.entity e WHERE e.entity_code = 'gost_7.75'
AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');

INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
SELECT e.entity_id, 'en', 'GOST 7.75-97', 'Russian language code standard', true, 1
FROM meta.entity e WHERE e.entity_code = 'gost_7.75'
AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');

-- Create language entities (main languages)
DO $$
DECLARE
    lang_kind_id UUID;
    classifier_iso639_1_id UUID;
BEGIN
    SELECT kind_id INTO lang_kind_id FROM meta.entity_kind WHERE kind_code = 'language';
    SELECT entity_id INTO classifier_iso639_1_id FROM meta.entity WHERE entity_code = 'iso_639_1';
    
    -- Russian
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_ru', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Русский язык', 'Государственный язык Российской Федерации', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_ru'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'Russian', 'State language of the Russian Federation', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_ru'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
    
    -- English
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_en', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_en');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Английский язык', 'Международный язык общения', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_en'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'English', 'International language of communication', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_en'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
    
    -- German
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_de', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_de');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Немецкий язык', 'Официальный язык Германии', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_de'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'German', 'Official language of Germany', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_de'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
    
    -- French
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_fr', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_fr');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Французский язык', 'Официальный язык Франции', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_fr'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'French', 'Official language of France', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_fr'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
    
    -- Spanish
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_es', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_es');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Испанский язык', 'Официальный язык Испании', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_es'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'Spanish', 'Official language of Spain', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_es'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
    
    -- Chinese
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_zh', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_zh');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Китайский язык', 'Государственный язык Китая', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_zh'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'Chinese', 'State language of China', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_zh'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
    
    -- Japanese
    INSERT INTO meta.entity (entity_id, entity_code, kind_id, status, version_id)
    SELECT gen_random_uuid(), 'lang_ja', lang_kind_id, 'active', 1
    WHERE NOT EXISTS (SELECT 1 FROM meta.entity WHERE entity_code = 'lang_ja');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'ru', 'Японский язык', 'Государственный язык Японии', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_ja'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'ru');
    
    INSERT INTO meta.entity_label (entity_id, language, label, description, is_primary, version_id)
    SELECT e.entity_id, 'en', 'Japanese', 'State language of Japan', true, 1
    FROM meta.entity e WHERE e.entity_code = 'lang_ja'
    AND NOT EXISTS (SELECT 1 FROM meta.entity_label WHERE entity_id = e.entity_id AND language = 'en');
END $$;
