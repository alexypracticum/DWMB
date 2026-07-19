-- =============================================================================
--  META-SYSTEM: инициализация базы данных
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS vector;

CREATE SCHEMA IF NOT EXISTS meta;
SET search_path TO meta, public;

-- =============================================================================
--  ПЕРЕЧИСЛЕНИЯ (ENUMS)
-- =============================================================================

CREATE TYPE language_code AS ENUM ('en', 'ru', 'de', 'fr', 'es', 'zh', 'ja');
CREATE TYPE relation_direction AS ENUM ('directed', 'undirected');
CREATE TYPE entity_status AS ENUM ('active', 'deprecated', 'deleted');
CREATE TYPE event_kind AS ENUM ('create', 'update', 'delete', 'merge', 'split', 'state_transition', 'relation_change');
CREATE TYPE storage_backend AS ENUM ('local', 'nfs', 's3');

-- =============================================================================
--  1. VERSION REGISTRY
-- =============================================================================

CREATE TABLE version_registry (
    version_id      BIGSERIAL PRIMARY KEY,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by      TEXT NOT NULL DEFAULT 'system',
    description     TEXT
);

-- =============================================================================
--  2. SOURCE SYSTEM
-- =============================================================================

CREATE TABLE source_system (
    source_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_code     TEXT NOT NULL UNIQUE,
    description     TEXT,
    is_trusted      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  3. IMPORT BATCH
-- =============================================================================

CREATE TABLE import_batch (
    batch_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id       UUID NOT NULL REFERENCES source_system(source_id),
    batch_code      TEXT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at     TIMESTAMPTZ,
    items_total     INT,
    items_success   INT,
    items_failed    INT,
    error_log       JSONB DEFAULT '[]'::jsonb
);

-- =============================================================================
--  4. USER ACCOUNT
-- =============================================================================

CREATE TABLE user_account (
    user_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username        TEXT NOT NULL UNIQUE,
    email           TEXT,
    display_name    TEXT,
    password_hash   TEXT,
    auth_provider   TEXT NOT NULL DEFAULT 'local',
    external_id     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    is_admin        BOOLEAN NOT NULL DEFAULT false,
    phone           TEXT,
    bio             TEXT,
    avatar_url      TEXT,
    language_preference language_code DEFAULT 'ru',
    theme_id        UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  5. CONTEXT
-- =============================================================================

CREATE TABLE context (
    context_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_context_id   UUID REFERENCES context(context_id),
    context_code        TEXT NOT NULL UNIQUE,
    context_name        TEXT,
    description         TEXT,
    rules               JSONB NOT NULL DEFAULT '{}'::jsonb,
    valid_from          TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to            TIMESTAMPTZ,
    version_id          BIGINT NOT NULL
);

-- =============================================================================
--  6. ENTITY KIND (справочник типов)
-- =============================================================================

CREATE TABLE entity_kind (
    kind_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind_code       TEXT NOT NULL UNIQUE,
    parent_kind_id  UUID REFERENCES entity_kind(kind_id),
    description     TEXT,
    is_abstract     BOOLEAN NOT NULL DEFAULT false,
    sort_order      INT NOT NULL DEFAULT 0,
    version_id      BIGINT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE entity_kind_label (
    kind_id         UUID NOT NULL REFERENCES entity_kind(kind_id) ON DELETE CASCADE,
    language        language_code NOT NULL,
    label           TEXT NOT NULL,
    description     TEXT,
    PRIMARY KEY (kind_id, language)
);

CREATE TABLE entity_kind_relation_constraint (
    constraint_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_kind_id    UUID NOT NULL REFERENCES entity_kind(kind_id),
    relation_code   TEXT NOT NULL,
    to_kind_id      UUID NOT NULL REFERENCES entity_kind(kind_id),
    is_allowed      BOOLEAN NOT NULL DEFAULT true,
    description     TEXT,
    UNIQUE(from_kind_id, relation_code, to_kind_id),
    CHECK (from_kind_id <> to_kind_id)
);

CREATE INDEX idx_kind_parent ON entity_kind(parent_kind_id);
CREATE INDEX idx_kind_constraint_from ON entity_kind_relation_constraint(from_kind_id);
CREATE INDEX idx_kind_constraint_to ON entity_kind_relation_constraint(to_kind_id);

-- =============================================================================
--  7. ENTITY
-- =============================================================================

CREATE TABLE entity (
    entity_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_code     TEXT NOT NULL,
    kind_id         UUID NOT NULL REFERENCES entity_kind(kind_id),
    status          entity_status NOT NULL DEFAULT 'active',
    source_id       UUID REFERENCES source_system(source_id),
    batch_id        UUID REFERENCES import_batch(batch_id),
    owner_id        UUID REFERENCES user_account(user_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to        TIMESTAMPTZ,
    version_id      BIGINT NOT NULL
);

CREATE INDEX idx_entity_kind ON entity(kind_id);
CREATE INDEX idx_entity_status ON entity(status);
CREATE INDEX idx_entity_source ON entity(source_id);
CREATE INDEX idx_entity_owner ON entity(owner_id) WHERE owner_id IS NOT NULL;
CREATE INDEX idx_entity_updated ON entity(updated_at DESC);
CREATE INDEX idx_entity_code ON entity(entity_code);

-- =============================================================================
--  8. ENTITY LABEL
-- =============================================================================

CREATE TABLE entity_label (
    entity_label_id     BIGSERIAL PRIMARY KEY,
    entity_id           UUID NOT NULL REFERENCES entity(entity_id) ON DELETE CASCADE,
    language            language_code NOT NULL,
    label               TEXT NOT NULL,
    description         TEXT,
    content             TEXT,
    is_primary          BOOLEAN NOT NULL DEFAULT false,
    owner_id            UUID REFERENCES user_account(user_id),
    version_id          BIGINT NOT NULL,
    UNIQUE(entity_id, language, label)
);

CREATE INDEX idx_label_entity ON entity_label(entity_id);
CREATE INDEX idx_label_language ON entity_label(language);
CREATE INDEX idx_label_fts_en ON entity_label
    USING gin(to_tsvector('english', label || ' ' || COALESCE(description, '') || ' ' || COALESCE(content, '')));
CREATE INDEX idx_label_fts_ru ON entity_label
    USING gin(to_tsvector('russian', label || ' ' || COALESCE(description, '') || ' ' || COALESCE(content, '')));
CREATE INDEX idx_label_trgm ON entity_label USING gin(label gin_trgm_ops);

-- =============================================================================
--  9. ONTOLOGY MODEL
-- =============================================================================

CREATE TABLE ontology_model (
    model_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_code      TEXT NOT NULL UNIQUE,
    domain          TEXT NOT NULL,
    description     TEXT,
    version_id      BIGINT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  10. ONTOLOGY TEMPLATE
-- =============================================================================

CREATE TABLE ontology_template (
    template_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id                UUID NOT NULL REFERENCES ontology_model(model_id),
    kind_id                 UUID REFERENCES entity_kind(kind_id),
    template_code           TEXT NOT NULL UNIQUE,
    template_name           TEXT NOT NULL,
    description             TEXT,
    schema_definition       JSONB NOT NULL,
    layout_definition       JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active               BOOLEAN NOT NULL DEFAULT true,
    constraints_definition  JSONB NOT NULL DEFAULT '{}'::jsonb,
    version_id              BIGINT NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  11. ENTITY TEMPLATE ASSIGNMENT
-- =============================================================================

CREATE TABLE entity_template_assignment (
    assignment_id   BIGSERIAL PRIMARY KEY,
    entity_id       UUID NOT NULL REFERENCES entity(entity_id) ON DELETE CASCADE,
    template_id     UUID NOT NULL REFERENCES ontology_template(template_id),
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to        TIMESTAMPTZ,
    version_id      BIGINT NOT NULL,
    UNIQUE(entity_id, template_id)
);

-- =============================================================================
--  12. ENTITY PROJECTION
-- =============================================================================

CREATE TABLE entity_projection (
    projection_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id           UUID NOT NULL REFERENCES entity(entity_id) ON DELETE CASCADE,
    model_id            UUID NOT NULL REFERENCES ontology_model(model_id),
    template_id         UUID REFERENCES ontology_template(template_id),
    context_id          UUID REFERENCES context(context_id),
    projection_code     TEXT NOT NULL UNIQUE,
    projection_name     TEXT,
    confidence          NUMERIC(5,4) CHECK (confidence >= 0 AND confidence <= 1),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from          TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to            TIMESTAMPTZ,
    version_id          BIGINT NOT NULL
);

CREATE INDEX idx_proj_entity ON entity_projection(entity_id);
CREATE INDEX idx_proj_model ON entity_projection(model_id);
CREATE INDEX idx_proj_context ON entity_projection(context_id);
CREATE INDEX idx_proj_entity_model ON entity_projection(entity_id, model_id);

-- =============================================================================
--  13. PROJECTION STATE
-- =============================================================================

CREATE TABLE projection_state (
    state_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    projection_id   UUID NOT NULL REFERENCES entity_projection(projection_id) ON DELETE CASCADE,
    state_data      JSONB NOT NULL,
    state_hash      TEXT,
    embedding       vector(384),
    is_current      BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to        TIMESTAMPTZ,
    version_id      BIGINT NOT NULL
);

CREATE INDEX idx_state_projection ON projection_state(projection_id);
CREATE INDEX idx_state_current ON projection_state(projection_id) WHERE is_current = true;
CREATE INDEX idx_state_jsonb ON projection_state USING gin(state_data jsonb_path_ops);
CREATE INDEX idx_state_embedding ON projection_state USING hnsw (embedding vector_cosine_ops);

-- =============================================================================
--  14. RELATION TYPE
-- =============================================================================

CREATE TABLE relation_type (
    relation_type_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    relation_code       TEXT NOT NULL UNIQUE,
    relation_name       TEXT NOT NULL,
    description         TEXT,
    from_kind_id        UUID REFERENCES entity_kind(kind_id),
    to_kind_id          UUID REFERENCES entity_kind(kind_id),
    directionality      relation_direction NOT NULL,
    transitive_relation BOOLEAN NOT NULL DEFAULT false,
    symmetric_relation  BOOLEAN NOT NULL DEFAULT false,
    inverse_type_id     UUID REFERENCES relation_type(relation_type_id),
    version_id          BIGINT NOT NULL
);

-- =============================================================================
--  15. SEMANTIC RELATION
-- =============================================================================

CREATE TABLE semantic_relation (
    relation_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_projection_id    UUID NOT NULL REFERENCES entity_projection(projection_id) ON DELETE CASCADE,
    relation_type_id        UUID NOT NULL REFERENCES relation_type(relation_type_id),
    target_projection_id    UUID NOT NULL REFERENCES entity_projection(projection_id) ON DELETE CASCADE,
    context_id              UUID REFERENCES context(context_id),
    weight                  NUMERIC(6,5) CHECK (weight >= 0 AND weight <= 1),
    confidence              NUMERIC(6,5) CHECK (confidence >= 0 AND confidence <= 1),
    metadata                JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from              TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to                TIMESTAMPTZ,
    version_id              BIGINT NOT NULL,
    CHECK (source_projection_id <> target_projection_id)
);

CREATE INDEX idx_rel_source ON semantic_relation(source_projection_id);
CREATE INDEX idx_rel_target ON semantic_relation(target_projection_id);
CREATE INDEX idx_rel_type ON semantic_relation(relation_type_id);
CREATE INDEX idx_rel_source_type ON semantic_relation(source_projection_id, relation_type_id);

-- =============================================================================
--  16. MEDIA ASSET
-- =============================================================================

CREATE TABLE media_asset (
    asset_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID REFERENCES entity(entity_id),
    original_name   TEXT NOT NULL,
    mime_type       TEXT NOT NULL,
    size_bytes      BIGINT,
    file_hash       TEXT NOT NULL,
    storage_backend storage_backend NOT NULL DEFAULT 'local',
    storage_key     TEXT NOT NULL,
    width           INT,
    height          INT,
    duration_secs   NUMERIC(10,3),
    metadata        JSONB DEFAULT '{}'::jsonb,
    is_processed    BOOLEAN NOT NULL DEFAULT false,
    processing_log  TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    version_id      BIGINT NOT NULL,
    UNIQUE(file_hash)
);

CREATE INDEX idx_media_entity ON media_asset(entity_id);
CREATE INDEX idx_media_hash ON media_asset(file_hash);
CREATE INDEX idx_media_mime ON media_asset(mime_type);

-- =============================================================================
--  17. EVENT LOG
-- =============================================================================

CREATE TABLE event_log (
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID REFERENCES entity(entity_id),
    projection_id   UUID REFERENCES entity_projection(projection_id),
    relation_id     UUID REFERENCES semantic_relation(relation_id),
    asset_id        UUID REFERENCES media_asset(asset_id),
    event_type      event_kind NOT NULL,
    payload         JSONB NOT NULL DEFAULT '{}'::jsonb,
    caused_by       TEXT,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    version_id      BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_event_entity ON event_log(entity_id);
CREATE INDEX IF NOT EXISTS idx_event_type ON event_log(event_type);
CREATE INDEX IF NOT EXISTS idx_event_time ON event_log(occurred_at DESC);

-- =============================================================================
--  FIELD REGISTRY (справочник полей данных)
-- =============================================================================

CREATE TABLE IF NOT EXISTS field_registry (
    field_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_key       TEXT NOT NULL UNIQUE,
    field_label     TEXT NOT NULL,
    field_type      TEXT NOT NULL DEFAULT 'string',
    category        TEXT NOT NULL DEFAULT 'common',
    default_value   TEXT,
    options         JSONB DEFAULT '[]'::jsonb,
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO field_registry (field_key, field_label, field_type, category, sort_order) VALUES
    ('title', 'Название', 'string', 'common', 1),
    ('description', 'Описание', 'textarea', 'common', 2),
    ('year', 'Год', 'integer', 'common', 3),
    ('genre', 'Жанр', 'string', 'common', 4),
    ('rating', 'Рейтинг', 'number', 'common', 5),
    ('country', 'Страна', 'string', 'common', 6),
    ('language', 'Язык', 'string', 'common', 7),
    ('budget_mln', 'Бюджет (млн)', 'currency', 'common', 8),
    ('duration_min', 'Длительность (мин)', 'integer', 'common', 9),
    ('author', 'Автор', 'string', 'common', 10),
    ('pages', 'Страниц', 'integer', 'common', 11),
    ('isbn', 'ISBN', 'string', 'common', 12),
    ('artist', 'Исполнитель', 'string', 'music', 13),
    ('album', 'Альбом', 'string', 'music', 14),
    ('bpm', 'BPM', 'integer', 'music', 15),
    ('release_date', 'Дата выхода', 'date', 'common', 16),
    ('start_date', 'Дата начала', 'date', 'common', 17),
    ('end_date', 'Дата окончания', 'date', 'common', 18),
    ('price', 'Цена', 'currency', 'common', 19),
    ('website', 'Сайт', 'url', 'common', 20),
    ('email', 'Email', 'email', 'common', 21),
    ('content', 'Контент (Markdown)', 'textarea', 'common', 22),
    ('poster_url', 'Постер', 'image', 'media', 23),
    ('images', 'Изображения', 'gallery', 'media', 24),
    ('video_url', 'Видео', 'video', 'media', 25),
    ('audio_url', 'Аудио', 'audio', 'media', 26),
    ('file_url', 'Файл', 'file', 'media', 27),
    ('file_title', 'Название файла', 'string', 'media', 28),
    ('imdb_id', 'IMDb ID', 'string', 'cinema', 29),
    ('tmdb_id', 'TMDb ID', 'string', 'cinema', 30),
    ('runtime', 'Хронометраж (мин)', 'integer', 'cinema', 31),
    ('mpaa_rating', 'Рейтинг MPAA', 'select', 'cinema', 32),
    ('budget', 'Бюджет', 'currency', 'cinema', 33),
    ('revenue', 'Сборы', 'currency', 'cinema', 34),
    ('filming_locations', 'Места съёмок', 'textarea', 'cinema', 35),
    ('production_companies', 'Продюсерские компании', 'textarea', 'cinema', 36),
    ('tagline', 'Слоган', 'string', 'cinema', 37),
    ('vote_count', 'Количество голосов', 'integer', 'cinema', 38),
    ('isrc', 'ISRC', 'string', 'music', 39),
    ('iswc', 'ISWC', 'string', 'music', 40),
    ('track_number', 'Номер трека', 'integer', 'music', 41),
    ('disc_number', 'Номер диска', 'integer', 'music', 42),
    ('explicit', 'Есть нецензурный контент', 'boolean', 'music', 43),
    ('key_signature', 'Тональность', 'string', 'music', 44),
    ('time_signature', 'Размерность', 'string', 'music', 45),
    ('label_name', 'Лейбл', 'string', 'music', 46),
    ('publisher', 'Издатель', 'string', 'literature', 47),
    ('publication_city', 'Город издания', 'string', 'literature', 48),
    ('edition', 'Издание', 'string', 'literature', 49),
    ('translator', 'Переводчик', 'string', 'literature', 50),
    ('original_language', 'Язык оригинала', 'string', 'literature', 51),
    ('dewey_decimal', 'Десятичный код Дьюи', 'string', 'literature', 52),
    ('electron_configuration', 'Электронная конфигурация', 'string', 'science', 53),
    ('oxidation_states', 'Степени окисления', 'string', 'science', 54),
    ('electronegativity', 'Электроотрицательность', 'number', 'science', 55),
    ('density', 'Плотность', 'number', 'science', 56),
    ('melting_point', 'Температура плавления', 'number', 'science', 57),
    ('boiling_point', 'Температура кипения', 'number', 'science', 58),
    ('discovery_year', 'Год открытия', 'integer', 'science', 59),
    ('first_name', 'Имя', 'string', 'people', 60),
    ('last_name', 'Фамилия', 'string', 'people', 61),
    ('patronymic', 'Отчество', 'string', 'people', 62),
    ('birth_date', 'Дата рождения', 'date', 'people', 63),
    ('birth_place', 'Место рождения', 'string', 'people', 64),
    ('death_date', 'Дата смерти', 'date', 'people', 65),
    ('death_place', 'Место смерти', 'string', 'people', 66),
    ('height_cm', 'Рост (см)', 'integer', 'people', 67),
    ('nationality', 'Национальность', 'string', 'people', 68),
    ('occupation', 'Профессия', 'string', 'people', 69),
    ('latitude', 'Широта', 'number', 'geography', 70),
    ('longitude', 'Долгота', 'number', 'geography', 71),
    ('elevation_m', 'Высота (м)', 'number', 'geography', 72),
    ('timezone', 'Часовой пояс', 'string', 'geography', 73),
    ('area_km2', 'Площадь (км²)', 'number', 'geography', 74),
    ('population', 'Население', 'integer', 'geography', 75),
    ('postal_code', 'Почтовый индекс', 'string', 'geography', 76),
    ('iso_code', 'ISO код', 'string', 'geography', 77),
    ('founding_date', 'Дата основания', 'date', 'organization', 78),
    ('dissolution_date', 'Дата роспуска', 'date', 'organization', 79),
    ('founder', 'Основатель', 'string', 'organization', 80),
    ('industry', 'Отрасль', 'string', 'organization', 81),
    ('employee_count', 'Число сотрудников', 'integer', 'organization', 82),
    ('headquarters', 'Штаб-квартира', 'string', 'organization', 83),
    ('event_date', 'Дата события', 'date', 'events', 84),
    ('event_end_date', 'Дата окончания', 'date', 'events', 85),
    ('venue', 'Место проведения', 'string', 'events', 86),
    ('organizer', 'Организатор', 'string', 'events', 87),
    ('attendee_count', 'Число участников', 'integer', 'events', 88),
    ('ticket_price', 'Цена билета', 'currency', 'events', 89),
    ('version', 'Версия', 'string', 'digital', 90),
    ('license', 'Лицензия', 'string', 'digital', 91),
    ('repository_url', 'URL репозитория', 'url', 'digital', 92),
    ('programming_language', 'Язык программирования', 'string', 'digital', 93),
    ('platform', 'Платформа', 'string', 'digital', 94),
    ('developer', 'Разработчик', 'string', 'digital', 95),
    ('game_engine', 'Игровой движок', 'string', 'gaming', 96),
    ('platform_list', 'Платформы', 'textarea', 'gaming', 97),
    ('player_count', 'Кол-во игроков', 'string', 'gaming', 98),
    ('esrb_rating', 'Рейтинг ESRB', 'select', 'gaming', 99),
    ('episode_number', 'Номер эпизода', 'integer', 'media', 100),
    ('season_number', 'Номер сезона', 'integer', 'media', 101),
    ('podcast_url', 'URL подкаста', 'url', 'media', 102),
    ('channel_url', 'URL канала', 'url', 'media', 103);

-- =============================================================================
--  20. FIELD REGISTRY LABEL (мультиязычные описания полей)
-- =============================================================================

CREATE TABLE IF NOT EXISTS field_registry_label (
    field_id    UUID NOT NULL REFERENCES field_registry(field_id) ON DELETE CASCADE,
    language    language_code NOT NULL,
    label       TEXT NOT NULL,
    description TEXT,
    PRIMARY KEY (field_id, language)
);

INSERT INTO field_registry_label (field_id, language, label, description) VALUES
    ((SELECT field_id FROM field_registry WHERE field_key = 'title'), 'ru', 'Название', 'Основное название сущности'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'title'), 'en', 'Title', 'Main title of the entity'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'description'), 'ru', 'Описание', 'Подробное описание'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'description'), 'en', 'Description', 'Detailed description'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'year'), 'ru', 'Год', 'Год создания или события'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'year'), 'en', 'Year', 'Year of creation or event'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'genre'), 'ru', 'Жанр', 'Творческое направление'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'genre'), 'en', 'Genre', 'Creative direction'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'rating'), 'ru', 'Рейтинг', 'Оценка от 0 до 10'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'rating'), 'en', 'Rating', 'Score from 0 to 10'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'country'), 'ru', 'Страна', 'Страна происхождения'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'country'), 'en', 'Country', 'Country of origin'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'language'), 'ru', 'Язык', 'Язык произведения'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'language'), 'en', 'Language', 'Language of the work'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'imdb_id'), 'ru', 'IMDb ID', 'Идентификатор в базе IMDb'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'imdb_id'), 'en', 'IMDb ID', 'IMDb database identifier'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'runtime'), 'ru', 'Хронометраж', 'Длительность в минутах'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'runtime'), 'en', 'Runtime', 'Duration in minutes'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'budget'), 'ru', 'Бюджет', 'Бюджет производства'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'budget'), 'en', 'Budget', 'Production budget'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'revenue'), 'ru', 'Сборы', 'Прокатные сборы'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'revenue'), 'en', 'Revenue', 'Box office revenue'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'isrc'), 'ru', 'ISRC', 'Международный стандартный код записи'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'isrc'), 'en', 'ISRC', 'International Standard Recording Code'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'publisher'), 'ru', 'Издатель', 'Издательство'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'publisher'), 'en', 'Publisher', 'Publishing house'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'first_name'), 'ru', 'Имя', 'Личное имя'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'first_name'), 'en', 'First Name', 'Given name'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'last_name'), 'ru', 'Фамилия', 'Фамилия'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'last_name'), 'en', 'Last Name', 'Family name'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'birth_date'), 'ru', 'Дата рождения', 'Дата рождения'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'birth_date'), 'en', 'Birth Date', 'Date of birth'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'latitude'), 'ru', 'Широта', 'Географическая широта'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'latitude'), 'en', 'Latitude', 'Geographic latitude'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'longitude'), 'ru', 'Долгота', 'Географическая долгота'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'longitude'), 'en', 'Longitude', 'Geographic longitude'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'founding_date'), 'ru', 'Дата основания', 'Дата основания организации'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'founding_date'), 'en', 'Founding Date', 'Organization founding date'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'event_date'), 'ru', 'Дата события', 'Дата проведения события'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'event_date'), 'en', 'Event Date', 'Date of the event'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'version'), 'ru', 'Версия', 'Номер версии'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'version'), 'en', 'Version', 'Version number'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'license'), 'ru', 'Лицензия', 'Тип лицензии'),
    ((SELECT field_id FROM field_registry WHERE field_key = 'license'), 'en', 'License', 'License type');

-- =============================================================================
--  21. USER THEME (пользовательские темы)
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_theme (
    theme_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES user_account(user_id) ON DELETE CASCADE,
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
--  22. AI CONFIG (настройки AI)
-- =============================================================================

CREATE TABLE IF NOT EXISTS ai_config (
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
--  23. AI TASK LOG (лог AI-запросов)
-- =============================================================================

CREATE TABLE IF NOT EXISTS ai_task_log (
    task_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_type       TEXT NOT NULL,
    model_used      TEXT,
    input_tokens    INT DEFAULT 0,
    output_tokens   INT DEFAULT 0,
    cost_usd        NUMERIC(10,6) DEFAULT 0,
    duration_ms     INT,
    entity_id       UUID REFERENCES entity(entity_id),
    status          TEXT NOT NULL DEFAULT 'pending',
    error_message   TEXT,
    payload         JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_task_type ON ai_task_log(task_type);
CREATE INDEX IF NOT EXISTS idx_ai_task_time ON ai_task_log(created_at DESC);

-- =============================================================================
--  24. AI SUGGESTION (AI-предложения)
-- =============================================================================

CREATE TABLE IF NOT EXISTS ai_suggestion (
    suggestion_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID NOT NULL REFERENCES entity(entity_id) ON DELETE CASCADE,
    suggestion_type TEXT NOT NULL,
    field_key       TEXT,
    suggested_value JSONB NOT NULL,
    confidence      NUMERIC(5,4) CHECK (confidence >= 0 AND confidence <= 1),
    is_accepted     BOOLEAN,
    reviewed_by     UUID REFERENCES user_account(user_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_sug_entity ON ai_suggestion(entity_id);
CREATE INDEX IF NOT EXISTS idx_ai_sug_type ON ai_suggestion(suggestion_type);

-- =============================================================================
--  25. PAGE REGISTRY (реестр страниц)
-- =============================================================================

CREATE TABLE IF NOT EXISTS page_registry (
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
    created_by      UUID REFERENCES user_account(user_id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
--  26. MENU ITEM (элементы меню)
-- =============================================================================

CREATE TABLE IF NOT EXISTS menu_item (
    menu_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id       UUID REFERENCES menu_item(menu_id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_menu_parent ON menu_item(parent_id);
CREATE INDEX IF NOT EXISTS idx_menu_code ON menu_item(menu_code);

-- =============================================================================
--  НАЧАЛЬНЫЕ ДАННЫЕ
-- =============================================================================

-- Users will be created by Python seed script with proper bcrypt hashing

-- Users
INSERT INTO user_account (user_id, username, display_name, password_hash, is_admin, is_active) VALUES
    ('a1000000-0000-0000-0000-000000000001', 'admin', 'Administrator', '$2b$12$HSJOBFaP9ckt9WT3WNqJcuRJLiQXrDnP4gufdD7NvZXp7fLbxTz9y', true, true);

-- Base themes
INSERT INTO user_theme (theme_id, user_id, theme_name, is_dark, is_active, colors, fonts) VALUES
    ('e0000001-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Светлая', false, true,
     '{"primary": "#3b82f6", "secondary": "#6366f1", "accent": "#f59e0b", "background": "#ffffff", "surface": "#f9fafb", "text": "#111827", "text_secondary": "#6b7280", "border": "#e5e7eb", "error": "#ef4444", "success": "#10b981"}'::jsonb,
     '{"heading": "Inter, sans-serif", "body": "Inter, sans-serif", "mono": "JetBrains Mono, monospace", "heading_size": "1.5rem", "body_size": "0.875rem"}'::jsonb),
    ('e0000002-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Тёмная', true, false,
     '{"primary": "#7c3aed", "secondary": "#a78bfa", "accent": "#fbbf24", "background": "#1a1b26", "surface": "#24283b", "text": "#c0caf5", "text_secondary": "#737aa2", "border": "#3b4261", "error": "#f7768e", "success": "#9ece6a"}'::jsonb,
     '{"heading": "Inter, sans-serif", "body": "Inter, sans-serif", "mono": "JetBrains Mono, monospace", "heading_size": "1.5rem", "body_size": "0.875rem"}'::jsonb);

-- Update admin user to use light theme
UPDATE user_account SET theme_id = 'e0000001-0000-0000-0000-000000000001' WHERE user_id = 'a1000000-0000-0000-0000-000000000001';

INSERT INTO source_system (source_code, description, is_trusted) VALUES
    ('manual', 'Ручной ввод через интерфейс', true),
    ('system', 'Системная запись', true),
    ('import', 'Импорт из внешнего источника', false);

INSERT INTO context (context_code, context_name, description, rules, version_id) VALUES
    ('default', 'Общий контекст', 'Контекст по умолчанию для всех данных', '{}'::jsonb, 1),
    ('physics', 'Физика', 'Физические процессы и явления', '{}'::jsonb, 1),
    ('biology', 'Биология', 'Живые организмы и процессы', '{}'::jsonb, 1),
    ('chemistry', 'Химия', 'Химические элементы и соединения', '{}'::jsonb, 1),
    ('cinema', 'Кинематограф', 'Фильмы, актёры, режиссёры', '{}'::jsonb, 1),
    ('music', 'Музыка', 'Песни, альбомы, исполнители', '{}'::jsonb, 1),
    ('literature', 'Литература', 'Книги, статьи, авторы', '{}'::jsonb, 1),
    ('geography', 'География', 'Города, страны, места', '{}'::jsonb, 1),
    ('economy', 'Экономика', 'Экономические процессы', '{}'::jsonb, 1),
    ('history', 'История', 'Исторические события и периоды', '{}'::jsonb, 1);

INSERT INTO ontology_model (model_code, domain, description, version_id) VALUES
    ('default', 'general', 'Базовая модель', 1),
    ('cinema', 'art', 'Кинематограф', 1),
    ('music', 'art', 'Музыка', 1),
    ('literature', 'art', 'Литература', 1),
    ('science', 'science', 'Наука', 1),
    ('geography', 'social', 'География', 1),
    ('history', 'social', 'История', 1),
    ('technology', 'digital', 'Технологии', 1);

-- Entity kinds ( справочник типов сущностей )
INSERT INTO entity_kind (kind_id, kind_code, description, is_abstract, sort_order, version_id) VALUES
    -- Cinema
    ('a0000000-0000-0000-0000-000000000001', 'movie', 'Фильм', false, 1, 1),
    ('a0000000-0000-0000-0000-000000000002', 'actor', 'Актёр', false, 2, 1),
    ('a0000000-0000-0000-0000-000000000003', 'director', 'Режиссёр', false, 3, 1),
    -- Music
    ('a0000000-0000-0000-0000-000000000004', 'song', 'Песня', false, 4, 1),
    ('a0000000-0000-0000-0000-000000000005', 'musician', 'Музыкант', false, 5, 1),
    ('a0000000-0000-0000-0000-000000000006', 'album', 'Альбом', false, 6, 1),
    -- Literature
    ('a0000000-0000-0000-0000-000000000007', 'book', 'Книга', false, 7, 1),
    ('a0000000-0000-0000-0000-000000000008', 'writer', 'Писатель', false, 8, 1),
    -- Geography
    ('a0000000-0000-0000-0000-000000000009', 'place', 'Место', false, 9, 1),
    -- Science
    ('a0000000-0000-0000-0000-000000000010', 'chemical_element', 'Химический элемент', false, 10, 1),
    ('a0000000-0000-0000-0000-000000000011', 'animal', 'Животное', false, 11, 1),
    ('a0000000-0000-0000-0000-000000000012', 'plant', 'Растение', false, 12, 1),
    -- Default
    ('a0000000-0000-0000-0000-000000000013', 'concept', 'Концепция', false, 13, 1),
    ('a0000000-0000-0000-0000-000000000014', 'genre', 'Жанр', false, 14, 1),
    ('a0000000-0000-0000-0000-000000000015', 'phenomenon', 'Явление', false, 15, 1),
    ('a0000000-0000-0000-0000-000000000016', 'period', 'Эпоха', false, 16, 1),
    ('a0000000-0000-0000-0000-000000000017', 'digital_file', 'Файл', false, 17, 1),
    ('a0000000-0000-0000-0000-000000000018', 'movement', 'Движение', false, 18, 1),
    ('a0000000-0000-0000-0000-000000000019', 'classifier', 'Классификатор', false, 19, 1),
    ('a0000000-0000-0000-0000-000000000020', 'physical_item', 'Предмет', false, 20, 1),
    ('a0000000-0000-0000-0000-000000000021', 'photo', 'Фото', false, 21, 1),
    ('a0000000-0000-0000-0000-000000000022', 'article', 'Статья', false, 22, 1),
    ('a0000000-0000-0000-0000-000000000023', 'human', 'Человек', false, 23, 1),
    ('a0000000-0000-0000-0000-000000000024', 'artist', 'Художник', false, 24, 1),
    ('a0000000-0000-0000-0000-000000000025', 'scientist', 'Учёный', false, 25, 1),
    -- New entity kinds (added 2026-07-17)
    ('b0000000-0000-0000-0000-000000000001', 'organization', 'Организация', false, 26, 1),
    ('b0000000-0000-0000-0000-000000000002', 'event', 'Событие', false, 27, 1),
    ('b0000000-0000-0000-0000-000000000003', 'award', 'Награда', false, 28, 1),
    ('b0000000-0000-0000-0000-000000000004', 'collection', 'Коллекция', false, 29, 1),
    ('b0000000-0000-0000-0000-000000000005', 'tag', 'Тег', false, 30, 1),
    ('b0000000-0000-0000-0000-000000000006', 'language_entity', 'Язык', false, 31, 1),
    ('b0000000-0000-0000-0000-000000000007', 'currency', 'Валюта', false, 32, 1),
    ('b0000000-0000-0000-0000-000000000008', 'unit', 'Единица измерения', false, 33, 1),
    ('b0000000-0000-0000-0000-000000000009', 'formula', 'Формула', false, 34, 1),
    ('b0000000-0000-0000-0000-000000000010', 'theorem', 'Теорема', false, 35, 1),
    ('b0000000-0000-0000-0000-000000000011', 'software', 'Программа', false, 36, 1),
    ('b0000000-0000-0000-0000-000000000012', 'game', 'Игра', false, 37, 1),
    ('b0000000-0000-0000-0000-000000000013', 'podcast', 'Подкаст', false, 38, 1),
    ('b0000000-0000-0000-0000-000000000014', 'channel', 'Канал', false, 39, 1),
    ('b0000000-0000-0000-0000-000000000015', 'label_entity', 'Лейбл', false, 40, 1);

-- Entity kind labels
INSERT INTO entity_kind_label (kind_id, language, label, description) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'ru', 'Фильм', 'Кинофильм'),
    ('a0000000-0000-0000-0000-000000000001', 'en', 'Movie', 'Film'),
    ('a0000000-0000-0000-0000-000000000002', 'ru', 'Актёр', 'Актёр кино и театра'),
    ('a0000000-0000-0000-0000-000000000002', 'en', 'Actor', 'Film and stage actor'),
    ('a0000000-0000-0000-0000-000000000003', 'ru', 'Режиссёр', 'Режиссёр кино'),
    ('a0000000-0000-0000-0000-000000000003', 'en', 'Director', 'Film director'),
    ('a0000000-0000-0000-0000-000000000004', 'ru', 'Песня', 'Музыкальное произведение'),
    ('a0000000-0000-0000-0000-000000000004', 'en', 'Song', 'Musical composition'),
    ('a0000000-0000-0000-0000-000000000005', 'ru', 'Музыкант', 'Исполнитель музыки'),
    ('a0000000-0000-0000-0000-000000000005', 'en', 'Musician', 'Music performer'),
    ('a0000000-0000-0000-0000-000000000006', 'ru', 'Альбом', 'Музыкальный альбом'),
    ('a0000000-0000-0000-0000-000000000006', 'en', 'Album', 'Music album'),
    ('a0000000-0000-0000-0000-000000000007', 'ru', 'Книга', 'Книжное издание'),
    ('a0000000-0000-0000-0000-000000000007', 'en', 'Book', 'Book publication'),
    ('a0000000-0000-0000-0000-000000000008', 'ru', 'Писатель', 'Автор книг'),
    ('a0000000-0000-0000-0000-000000000008', 'en', 'Writer', 'Book author'),
    ('a0000000-0000-0000-0000-000000000009', 'ru', 'Место', 'Географическое место'),
    ('a0000000-0000-0000-0000-000000000009', 'en', 'Place', 'Geographic place'),
    ('a0000000-0000-0000-0000-000000000010', 'ru', 'Химический элемент', 'Элемент периодической таблицы'),
    ('a0000000-0000-0000-0000-000000000010', 'en', 'Chemical Element', 'Periodic table element'),
    ('a0000000-0000-0000-0000-000000000011', 'ru', 'Животное', 'Живое существо'),
    ('a0000000-0000-0000-0000-000000000011', 'en', 'Animal', 'Living creature'),
    ('a0000000-0000-0000-0000-000000000012', 'ru', 'Растение', 'Растительный организм'),
    ('a0000000-0000-0000-0000-000000000012', 'en', 'Plant', 'Plant organism'),
    ('a0000000-0000-0000-0000-000000000013', 'ru', 'Концепция', 'Абстрактная идея'),
    ('a0000000-0000-0000-0000-000000000013', 'en', 'Concept', 'Abstract idea'),
    ('a0000000-0000-0000-0000-000000000014', 'ru', 'Жанр', 'Творческое направление'),
    ('a0000000-0000-0000-0000-000000000014', 'en', 'Genre', 'Creative direction'),
    ('a0000000-0000-0000-0000-000000000015', 'ru', 'Явление', 'Наблюдаемый процесс'),
    ('a0000000-0000-0000-0000-000000000015', 'en', 'Phenomenon', 'Observable process'),
    ('a0000000-0000-0000-0000-000000000016', 'ru', 'Эпоха', 'Исторический период'),
    ('a0000000-0000-0000-0000-000000000016', 'en', 'Period', 'Historical era'),
    ('a0000000-0000-0000-0000-000000000017', 'ru', 'Файл', 'Цифровой файл'),
    ('a0000000-0000-0000-0000-000000000017', 'en', 'Digital File', 'Digital file'),
    ('a0000000-0000-0000-0000-000000000018', 'ru', 'Движение', 'Социальное или культурное движение'),
    ('a0000000-0000-0000-0000-000000000018', 'en', 'Movement', 'Social or cultural movement'),
    ('a0000000-0000-0000-0000-000000000019', 'ru', 'Классификатор', 'Система классификации'),
    ('a0000000-0000-0000-0000-000000000019', 'en', 'Classifier', 'Classification system'),
    ('a0000000-0000-0000-0000-000000000020', 'ru', 'Предмет', 'Физический объект'),
    ('a0000000-0000-0000-0000-000000000020', 'en', 'Physical Item', 'Physical object'),
    ('a0000000-0000-0000-0000-000000000021', 'ru', 'Фото', 'Фотография'),
    ('a0000000-0000-0000-0000-000000000021', 'en', 'Photo', 'Photograph'),
    ('a0000000-0000-0000-0000-000000000022', 'ru', 'Статья', 'Опубликованная статья'),
    ('a0000000-0000-0000-0000-000000000022', 'en', 'Article', 'Published article'),
    ('a0000000-0000-0000-0000-000000000023', 'ru', 'Человек', 'Персона'),
    ('a0000000-0000-0000-0000-000000000023', 'en', 'Human', 'Person'),
    ('a0000000-0000-0000-0000-000000000024', 'ru', 'Художник', 'Творец изобразительного искусства'),
    ('a0000000-0000-0000-0000-000000000024', 'en', 'Artist', 'Visual art creator'),
    ('a0000000-0000-0000-0000-000000000025', 'ru', 'Учёный', 'Исследователь'),
    ('a0000000-0000-0000-0000-000000000025', 'en', 'Scientist', 'Researcher'),
    -- New entity kind labels (added 2026-07-17)
    ('b0000000-0000-0000-0000-000000000001', 'ru', 'Организация', 'Организация или компания'),
    ('b0000000-0000-0000-0000-000000000001', 'en', 'Organization', 'Organization or company'),
    ('b0000000-0000-0000-0000-000000000002', 'ru', 'Событие', 'Событие или мероприятие'),
    ('b0000000-0000-0000-0000-000000000002', 'en', 'Event', 'Event or occurrence'),
    ('b0000000-0000-0000-0000-000000000003', 'ru', 'Награда', 'Награда или премия'),
    ('b0000000-0000-0000-0000-000000000003', 'en', 'Award', 'Award or prize'),
    ('b0000000-0000-0000-0000-000000000004', 'ru', 'Коллекция', 'Коллекция или подборка'),
    ('b0000000-0000-0000-0000-000000000004', 'en', 'Collection', 'Collection or compilation'),
    ('b0000000-0000-0000-0000-000000000005', 'ru', 'Тег', 'Тег или метка'),
    ('b0000000-0000-0000-0000-000000000005', 'en', 'Tag', 'Tag or label'),
    ('b0000000-0000-0000-0000-000000000006', 'ru', 'Язык', 'Язык программирования или общения'),
    ('b0000000-0000-0000-0000-000000000006', 'en', 'Language', 'Programming or natural language'),
    ('b0000000-0000-0000-0000-000000000007', 'ru', 'Валюта', 'Денежная единица'),
    ('b0000000-0000-0000-0000-000000000007', 'en', 'Currency', 'Monetary unit'),
    ('b0000000-0000-0000-0000-000000000008', 'ru', 'Единица измерения', 'Единица измерения'),
    ('b0000000-0000-0000-0000-000000000008', 'en', 'Unit of Measurement', 'Unit of measurement'),
    ('b0000000-0000-0000-0000-000000000009', 'ru', 'Формула', 'Научная формула'),
    ('b0000000-0000-0000-0000-000000000009', 'en', 'Formula', 'Scientific formula'),
    ('b0000000-0000-0000-0000-000000000010', 'ru', 'Теорема', 'Математическая или научная теорема'),
    ('b0000000-0000-0000-0000-000000000010', 'en', 'Theorem', 'Mathematical or scientific theorem'),
    ('b0000000-0000-0000-0000-000000000011', 'ru', 'Программа', 'Программное обеспечение'),
    ('b0000000-0000-0000-0000-000000000011', 'en', 'Software', 'Software application'),
    ('b0000000-0000-0000-0000-000000000012', 'ru', 'Игра', 'Видеоигра или настольная игра'),
    ('b0000000-0000-0000-0000-000000000012', 'en', 'Game', 'Video or board game'),
    ('b0000000-0000-0000-0000-000000000013', 'ru', 'Подкаст', 'Аудиоподкаст'),
    ('b0000000-0000-0000-0000-000000000013', 'en', 'Podcast', 'Audio podcast'),
    ('b0000000-0000-0000-0000-000000000014', 'ru', 'Канал', 'Видео- или аудиоканал'),
    ('b0000000-0000-0000-0000-000000000014', 'en', 'Channel', 'Video or audio channel'),
    ('b0000000-0000-0000-0000-000000000015', 'ru', 'Лейбл', 'Музыкальный или издательский лейбл'),
    ('b0000000-0000-0000-0000-000000000015', 'en', 'Label', 'Music or publishing label');

-- =============================================================================
--  RELATION TYPES (типы связей)
-- =============================================================================

INSERT INTO relation_type (relation_type_id, relation_code, relation_name, directionality, version_id) VALUES
    ('c0000000-0000-0000-0000-000000000001', 'performed_in', 'Исполнил в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000002', 'directed_by', 'Режиссёр', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000003', 'wrote', 'Написал', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000004', 'composed_by', 'Композитор', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000005', 'produced_by', 'Продюсер', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000006', 'acted_in', 'Сыграл в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000007', 'narrated_by', 'Озвучил', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000008', 'based_on', 'Основано на', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000009', 'sequel_of', 'Сиквел', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000010', 'prequel_of', 'Приквел', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000011', 'spin_off_of', 'Спин-офф', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000012', 'adaptation_of', 'Экранизация', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000013', 'influenced_by', 'Под влиянием', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000014', 'member_of', 'Член', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000015', 'founded', 'Основал', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000016', 'located_in', 'Расположен в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000017', 'born_in', 'Родился в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000018', 'died_in', 'Умер в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000019', 'has_genre', 'Жанр', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000020', 'has_theme', 'Тема', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000021', 'related_to', 'Связано с', 'undirected', 1),
    ('c0000000-0000-0000-0000-000000000022', 'part_of', 'Часть', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000023', 'contains', 'Содержит', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000024', 'references', 'Упоминает', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000025', 'has_asset', 'Имеет файл', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000026', 'won_award', 'Победил в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000027', 'nominated_for', 'Номинирован на', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000028', 'distributed_by', 'Дистрибьютор', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000029', 'published_by', 'Издатель', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000030', 'similar_to', 'Похоже на', 'undirected', 1),
    ('c0000000-0000-0000-0000-000000000031', 'alternative_title', 'Альтернативное название', 'undirected', 1),
    ('c0000000-0000-0000-0000-000000000032', 'covers', 'Кавер', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000033', 'remix_of', 'Ремикс', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000034', 'sampled_in', 'Сэмпл в', 'directed', 1),
    ('c0000000-0000-0000-0000-000000000035', 'developed_by', 'Разработчик', 'directed', 1);
