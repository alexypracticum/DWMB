-- =============================================================================
--  Миграция: Добавление entity_kind_ontology + дополнение field_registry_label
--  Дата: 2026-07-18
-- =============================================================================

BEGIN;

-- =============================================================================
--  1. entity_kind_ontology — связь типов сущностей с онтологиями
-- =============================================================================

CREATE TABLE IF NOT EXISTS meta.entity_kind_ontology (
    kind_id     UUID NOT NULL REFERENCES meta.entity_kind(kind_id) ON DELETE CASCADE,
    model_id    UUID NOT NULL REFERENCES meta.ontology_model(model_id) ON DELETE CASCADE,
    is_primary  BOOLEAN DEFAULT false,
    PRIMARY KEY (kind_id, model_id)
);

CREATE INDEX IF NOT EXISTS idx_kind_ontology_kind ON meta.entity_kind_ontology(kind_id);
CREATE INDEX IF NOT EXISTS idx_kind_ontology_model ON meta.entity_kind_ontology(model_id);

-- =============================================================================
--  2. Связь типов сущностей с онтологиями (seed data)
-- =============================================================================

-- Cinema domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='movie'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='cinema'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='actor'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='cinema'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='director'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='cinema'), false);

-- Music domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='song'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='music'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='musician'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='music'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='album'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='music'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='label_entity'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='music'), false);

-- Literature domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='book'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='literature'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='writer'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='literature'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='article'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='literature'), false);

-- Science domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='chemical_element'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='science'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='formula'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='science'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='theorem'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='science'), true);

-- Geography domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='place'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='geography'), true);

-- History domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='period'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='history'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='event'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='history'), false);

-- Technology domain
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='software'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='technology'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='game'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='technology'), false);

-- Default domain (универсальные типы)
INSERT INTO meta.entity_kind_ontology (kind_id, model_id, is_primary) VALUES
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='human'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='organization'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='concept'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='genre'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='tag'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='collection'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='award'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='digital_file'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='photo'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='physical_item'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='plant'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='animal'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='artist'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='scientist'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='phenomenon'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='movement'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='classifier'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='currency'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='unit'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='language_entity'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), true),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='podcast'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false),
    ((SELECT kind_id FROM meta.entity_kind WHERE kind_code='channel'),
     (SELECT model_id FROM meta.ontology_model WHERE model_code='default'), false);

-- =============================================================================
--  3. Дополнение field_registry_label (недостающие описания на Ru/En)
-- =============================================================================

-- Основные поля — Ru + En (если ещё не добавлены)
DO $$
DECLARE
    f_id UUID;
BEGIN
    -- rating
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='rating';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Рейтинг', 'Оценка от 0 до 10'),
            (f_id, 'en', 'Rating', 'Score from 0 to 10')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- year
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='year';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Год', 'Год создания или события'),
            (f_id, 'en', 'Year', 'Year of creation or event')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- genre
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='genre';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Жанр', 'Творческое направление'),
            (f_id, 'en', 'Genre', 'Creative direction')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- country
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='country';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Страна', 'Страна происхождения'),
            (f_id, 'en', 'Country', 'Country of origin')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- language
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='language';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Язык', 'Язык произведения'),
            (f_id, 'en', 'Language', 'Language of the work')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- imdb_id
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='imdb_id';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'IMDb ID', 'Идентификатор в базе IMDb'),
            (f_id, 'en', 'IMDb ID', 'IMDb database identifier')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- runtime
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='runtime';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Хронометраж', 'Длительность в минутах'),
            (f_id, 'en', 'Runtime', 'Duration in minutes')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- budget
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='budget';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Бюджет', 'Бюджет производства'),
            (f_id, 'en', 'Budget', 'Production budget')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- revenue
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='revenue';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Сборы', 'Прокатные сборы'),
            (f_id, 'en', 'Revenue', 'Box office revenue')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- isrc
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='isrc';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'ISRC', 'Международный стандартный код записи'),
            (f_id, 'en', 'ISRC', 'International Standard Recording Code')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- publisher
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='publisher';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Издатель', 'Издательство'),
            (f_id, 'en', 'Publisher', 'Publishing house')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- first_name
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='first_name';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Имя', 'Личное имя'),
            (f_id, 'en', 'First Name', 'Given name')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- last_name
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='last_name';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Фамилия', 'Фамилия'),
            (f_id, 'en', 'Last Name', 'Family name')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- birth_date
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='birth_date';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Дата рождения', 'Дата рождения'),
            (f_id, 'en', 'Birth Date', 'Date of birth')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- latitude
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='latitude';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Широта', 'Географическая широта'),
            (f_id, 'en', 'Latitude', 'Geographic latitude')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- longitude
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='longitude';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Долгота', 'Географическая долгота'),
            (f_id, 'en', 'Longitude', 'Geographic longitude')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- founding_date
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='founding_date';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Дата основания', 'Дата основания организации'),
            (f_id, 'en', 'Founding Date', 'Organization founding date')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- event_date
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='event_date';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Дата события', 'Дата проведения события'),
            (f_id, 'en', 'Event Date', 'Date of the event')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- version
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='version';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Версия', 'Номер версии'),
            (f_id, 'en', 'Version', 'Version number')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;

    -- license
    SELECT field_id INTO f_id FROM meta.field_registry WHERE field_key='license';
    IF f_id IS NOT NULL THEN
        INSERT INTO meta.field_registry_label (field_id, language, label, description) VALUES
            (f_id, 'ru', 'Лицензия', 'Тип лицензии'),
            (f_id, 'en', 'License', 'License type')
        ON CONFLICT (field_id, language) DO NOTHING;
    END IF;
END $$;

-- =============================================================================
--  4. Дополнительные поля в field_registry (если отсутствуют)
-- =============================================================================

INSERT INTO meta.field_registry (field_key, field_label, field_type, category, sort_order) VALUES
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
    ('tmdb_id', 'TMDb ID', 'string', 'cinema', 30),
    ('mpaa_rating', 'Рейтинг MPAA', 'select', 'cinema', 32),
    ('filming_locations', 'Места съёмок', 'textarea', 'cinema', 35),
    ('production_companies', 'Продюсерские компании', 'textarea', 'cinema', 36),
    ('tagline', 'Слоган', 'string', 'cinema', 37),
    ('vote_count', 'Количество голосов', 'integer', 'cinema', 38),
    ('iswc', 'ISWC', 'string', 'music', 40),
    ('track_number', 'Номер трека', 'integer', 'music', 41),
    ('disc_number', 'Номер диска', 'integer', 'music', 42),
    ('explicit', 'Есть нецензурный контент', 'boolean', 'music', 43),
    ('key_signature', 'Тональность', 'string', 'music', 44),
    ('time_signature', 'Размерность', 'string', 'music', 45),
    ('label_name', 'Лейбл', 'string', 'music', 46),
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
    ('patronymic', 'Отчество', 'string', 'people', 62),
    ('birth_place', 'Место рождения', 'string', 'people', 64),
    ('death_date', 'Дата смерти', 'date', 'people', 65),
    ('death_place', 'Место смерти', 'string', 'people', 66),
    ('height_cm', 'Рост (см)', 'integer', 'people', 67),
    ('nationality', 'Национальность', 'string', 'people', 68),
    ('occupation', 'Профессия', 'string', 'people', 69),
    ('elevation_m', 'Высота (м)', 'number', 'geography', 72),
    ('timezone', 'Часовой пояс', 'string', 'geography', 73),
    ('area_km2', 'Площадь (км²)', 'number', 'geography', 74),
    ('population', 'Население', 'integer', 'geography', 75),
    ('postal_code', 'Почтовый индекс', 'string', 'geography', 76),
    ('iso_code', 'ISO код', 'string', 'geography', 77),
    ('dissolution_date', 'Дата роспуска', 'date', 'organization', 79),
    ('founder', 'Основатель', 'string', 'organization', 80),
    ('industry', 'Отрасль', 'string', 'organization', 81),
    ('employee_count', 'Число сотрудников', 'integer', 'organization', 82),
    ('headquarters', 'Штаб-квартира', 'string', 'organization', 83),
    ('event_end_date', 'Дата окончания', 'date', 'events', 85),
    ('venue', 'Место проведения', 'string', 'events', 86),
    ('organizer', 'Организатор', 'string', 'events', 87),
    ('attendee_count', 'Число участников', 'integer', 'events', 88),
    ('ticket_price', 'Цена билета', 'currency', 'events', 89),
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
    ('channel_url', 'URL канала', 'url', 'media', 103)
ON CONFLICT (field_key) DO NOTHING;

COMMIT;
