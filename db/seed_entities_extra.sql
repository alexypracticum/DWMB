-- =============================================================================
--  Дополнительные сущности для тестирования (3-5 на тип)
-- =============================================================================

SET search_path TO meta;

-- =========================================================================
-- 1. Additional Movies (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000001-0000-0000-0000-000000000003', 'interstellar', 'a0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000001-0000-0000-0000-000000000004', 'fight-club', 'a0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000001-0000-0000-0000-000000000005', 'blade-runner-2049', 'a0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000001-0000-0000-0000-000000000003', 'ru', 'Интерстеллар', 'Фильм Кристофера Нолана 2014 года о космическом путешествии', true, 1),
('d0000001-0000-0000-0000-000000000003', 'en', 'Interstellar', '2014 sci-fi film by Christopher Nolan about space travel', true, 1),
('d0000001-0000-0000-0000-000000000004', 'ru', 'Бойцовский клуб', 'Фильм Дэвида Финчера 1999 года', true, 1),
('d0000001-0000-0000-0000-000000000004', 'en', 'Fight Club', '1999 film by David Fincher', true, 1),
('d0000001-0000-0000-0000-000000000005', 'ru', 'Бегущий по лезвию 2049', 'Фильм Дени Вильнёва 2017 года', true, 1),
('d0000001-0000-0000-0000-000000000005', 'en', 'Blade Runner 2049', '2017 film by Denis Villeneuve', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000001-0000-0000-0000-000000000003', 'd0000001-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'interstellar-cinema', 'Cinema Data', 0.95, 1),
('f0000001-0000-0000-0000-000000000004', 'd0000001-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'fight-club-cinema', 'Cinema Data', 0.95, 1),
('f0000001-0000-0000-0000-000000000005', 'd0000001-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'bladerunner2049-cinema', 'Cinema Data', 0.95, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000001-0000-0000-0000-000000000003', '{"year": 2014, "rating": 8.6, "genre": "Sci-Fi, Drama", "director": "Christopher Nolan", "duration": "169 мин", "poster": "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"}'::jsonb, 'hash_i1', true, 1),
('f0000001-0000-0000-0000-000000000004', '{"year": 1999, "rating": 8.8, "genre": "Drama, Thriller", "director": "David Fincher", "duration": "139 мин", "poster": "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QI4S2t0POO5.jpg"}'::jsonb, 'hash_i2', true, 1),
('f0000001-0000-0000-0000-000000000005', '{"year": 2017, "rating": 8.0, "genre": "Sci-Fi, Thriller", "director": "Denis Villeneuve", "duration": "164 мин", "poster": "https://image.tmdb.org/t/p/w500/gajva2L0rPYkEWjzgFlBXCAVBE5.jpg"}'::jsonb, 'hash_i3', true, 1);

-- =========================================================================
-- 2. Additional Actors (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000002-0000-0000-0000-000000000003', 'matt-damon', 'a0000000-0000-0000-0000-000000000002', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000002-0000-0000-0000-000000000004', 'scarlett-johansson', 'a0000000-0000-0000-0000-000000000002', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000002-0000-0000-0000-000000000005', 'ryan-gosling', 'a0000000-0000-0000-0000-000000000002', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000002-0000-0000-0000-000000000003', 'ru', 'Мэтт Деймон', 'Американский актёр, сценарист и продюсер', true, 1),
('d0000002-0000-0000-0000-000000000003', 'en', 'Matt Damon', 'American actor, screenwriter and producer', true, 1),
('d0000002-0000-0000-0000-000000000004', 'ru', 'Скарлетт Йоханссон', 'Американская актриса и певица', true, 1),
('d0000002-0000-0000-0000-000000000004', 'en', 'Scarlett Johansson', 'American actress and singer', true, 1),
('d0000002-0000-0000-0000-000000000005', 'ru', 'Райан Гослинг', 'Канадский актёр и музыкант', true, 1),
('d0000002-0000-0000-0000-000000000005', 'en', 'Ryan Gosling', 'Canadian actor and musician', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000002-0000-0000-0000-000000000003', 'd0000002-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'matt-damon-data', 'Actor Data', 0.9, 1),
('f0000002-0000-0000-0000-000000000004', 'd0000002-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'scarlett-johansson-data', 'Actor Data', 0.9, 1),
('f0000002-0000-0000-0000-000000000005', 'd0000002-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'ryan-gosling-data', 'Actor Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000002-0000-0000-0000-000000000003', '{"first_name": "Matt", "last_name": "Damon", "birth_year": 1970, "birthplace": "Кембридж, Массачусетс", "poster": "https://image.tmdb.org/t/p/w186/elSlNgV8xVifsbHpFsqrPGxJToZ.jpg"}'::jsonb, 'hash_a1', true, 1),
('f0000002-0000-0000-0000-000000000004', '{"first_name": "Scarlett", "last_name": "Johansson", "birth_year": 1984, "birthplace": "Нью-Йорк, США", "poster": "https://image.tmdb.org/t/p/w186/y3dKXy5LMhLlJpLmPQNyDlKdOkr.jpg"}'::jsonb, 'hash_a2', true, 1),
('f0000002-0000-0000-0000-000000000005', '{"first_name": "Ryan", "last_name": "Gosling", "birth_year": 1980, "birthplace": "Лондон, Онтарио", "poster": "https://image.tmdb.org/t/p/w186/l4wHk6a2v89Ehv1pMv3Rvh9c9w5.jpg"}'::jsonb, 'hash_a3', true, 1);

-- =========================================================================
-- 3. Additional Directors (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000003-0000-0000-0000-000000000003', 'david-fincher', 'a0000000-0000-0000-0000-000000000003', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000003-0000-0000-0000-000000000004', 'denis-villeneuve', 'a0000000-0000-0000-0000-000000000003', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000003-0000-0000-0000-000000000005', 'ridley-scott', 'a0000000-0000-0000-0000-000000000003', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000003-0000-0000-0000-000000000003', 'ru', 'Дэвид Финчер', 'Американский режиссёр и продюсер', true, 1),
('d0000003-0000-0000-0000-000000000003', 'en', 'David Fincher', 'American film director and producer', true, 1),
('d0000003-0000-0000-0000-000000000004', 'ru', 'Дени Вильнёв', 'Канадский режиссёр', true, 1),
('d0000003-0000-0000-0000-000000000004', 'en', 'Denis Villeneuve', 'Canadian film director', true, 1),
('d0000003-0000-0000-0000-000000000005', 'ru', 'Ридли Скотт', 'Британский режиссёр и продюсер', true, 1),
('d0000003-0000-0000-0000-000000000005', 'en', 'Ridley Scott', 'British film director and producer', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000003-0000-0000-0000-000000000003', 'd0000003-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'fincher-cinema', 'Director Data', 0.9, 1),
('f0000003-0000-0000-0000-000000000004', 'd0000003-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'villeneuve-cinema', 'Director Data', 0.9, 1),
('f0000003-0000-0000-0000-000000000005', 'd0000003-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'scott-cinema', 'Director Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000003-0000-0000-0000-000000000003', '{"first_name": "David", "last_name": "Fincher", "birth_year": 1962, "birthplace": "Денвер, Колорадо", "notable_works": "Социальная сеть, Игра в имитацию", "poster": "https://image.tmdb.org/t/p/w186/3o6TjuWZEOwUDIX1GNVnpHDi42r.jpg"}'::jsonb, 'hash_d1', true, 1),
('f0000003-0000-0000-0000-000000000004', '{"first_name": "Denis", "last_name": "Villeneuve", "birth_year": 1967, "birthplace": "Квебек, Канада", "notable_works": "Дюна, Пленники", "poster": "https://image.tmdb.org/t/p/w186/gXjWLd2VjV0v0Bk5b6k6T9gP0Dq.jpg"}'::jsonb, 'hash_d2', true, 1),
('f0000003-0000-0000-0000-000000000005', '{"first_name": "Ridley", "last_name": "Scott", "birth_year": 1937, "birthplace": "Саут-Шилдс, Англия", "notable_works": "Чужой, Бегущий по лезвию", "poster": "https://image.tmdb.org/t/p/w186/4bpcE8xqIh4pMSx0rQxYp4R5FmH.jpg"}'::jsonb, 'hash_d3', true, 1);

-- =========================================================================
-- 4. Additional Songs (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000004-0000-0000-0000-000000000003', 'stairway-to-heaven', 'a0000000-0000-0000-0000-000000000004', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000004-0000-0000-0000-000000000004', 'hotel-california', 'a0000000-0000-0000-0000-000000000004', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000004-0000-0000-0000-000000000005', 'imagine', 'a0000000-0000-0000-0000-000000000004', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000004-0000-0000-0000-000000000003', 'ru', 'Лестница в небо', 'Композиция Led Zeppelin', true, 1),
('d0000004-0000-0000-0000-000000000003', 'en', 'Stairway to Heaven', 'Song by Led Zeppelin', true, 1),
('d0000004-0000-0000-0000-000000000004', 'ru', 'Отель «Калифорния»', 'Композиция Eagles', true, 1),
('d0000004-0000-0000-0000-000000000004', 'en', 'Hotel California', 'Song by Eagles', true, 1),
('d0000004-0000-0000-0000-000000000005', 'ru', 'Представь', 'Композиция Джона Леннона', true, 1),
('d0000004-0000-0000-0000-000000000005', 'en', 'Imagine', 'Song by John Lennon', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000004-0000-0000-0000-000000000003', 'd0000004-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'stairway-music', 'Music Data', 0.95, 1),
('f0000004-0000-0000-0000-000000000004', 'd0000004-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'hotel-california-music', 'Music Data', 0.95, 1),
('f0000004-0000-0000-0000-000000000005', 'd0000004-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'imagine-music', 'Music Data', 0.95, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000004-0000-0000-0000-000000000003', '{"title": "Stairway to Heaven", "artist": "Led Zeppelin", "year": 1971, "album": "Led Zeppelin IV", "duration": "8:02", "genre": "Rock"}'::jsonb, 'hash_s1', true, 1),
('f0000004-0000-0000-0000-000000000004', '{"title": "Hotel California", "artist": "Eagles", "year": 1977, "album": "Hotel California", "duration": "6:30", "genre": "Rock"}'::jsonb, 'hash_s2', true, 1),
('f0000004-0000-0000-0000-000000000005', '{"title": "Imagine", "artist": "John Lennon", "year": 1971, "album": "Imagine", "duration": "3:07", "genre": "Pop, Rock"}'::jsonb, 'hash_s3', true, 1);

-- =========================================================================
-- 5. Additional Musicians (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000005-0000-0000-0000-000000000003', 'john-lennon', 'a0000000-0000-0000-0000-000000000005', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000005-0000-0000-0000-000000000004', 'jimi-hendrix', 'a0000000-0000-0000-0000-000000000005', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000005-0000-0000-0000-000000000005', 'elvis-presley', 'a0000000-0000-0000-0000-000000000005', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000005-0000-0000-0000-000000000003', 'ru', 'Джон Леннон', 'Британский музыкант, участник The Beatles', true, 1),
('d0000005-0000-0000-0000-000000000003', 'en', 'John Lennon', 'British musician, member of The Beatles', true, 1),
('d0000005-0000-0000-0000-000000000004', 'ru', 'Джими Хендрикс', 'Американский гитарист и певец', true, 1),
('d0000005-0000-0000-0000-000000000004', 'en', 'Jimi Hendrix', 'American guitarist and singer', true, 1),
('d0000005-0000-0000-0000-000000000005', 'ru', 'Элвис Пресли', 'Американский певец, «Король рок-н-ролла»', true, 1),
('d0000005-0000-0000-0000-000000000005', 'en', 'Elvis Presley', 'American singer, King of Rock and Roll', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000005-0000-0000-0000-000000000003', 'd0000005-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'lennon-music', 'Musician Data', 0.9, 1),
('f0000005-0000-0000-0000-000000000004', 'd0000005-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'hendrix-music', 'Musician Data', 0.9, 1),
('f0000005-0000-0000-0000-000000000005', 'd0000005-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'presley-music', 'Musician Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000005-0000-0000-0000-000000000003', '{"first_name": "John", "last_name": "Lennon", "birth_year": 1940, "death_year": 1980, "birthplace": "Ливерпуль, Англия", "poster": "https://image.tmdb.org/t/p/w186/xFJlZVFOeUptftr9JZgKKsMGnGw.jpg"}'::jsonb, 'hash_m1', true, 1),
('f0000005-0000-0000-0000-000000000004', '{"first_name": "Jimi", "last_name": "Hendrix", "birth_year": 1942, "death_year": 1970, "birthplace": "Сиэтл, Вашингтон", "poster": "https://image.tmdb.org/t/p/w186/kkDPnGnMzB3e9D0kP7JUaEVp1gn.jpg"}'::jsonb, 'hash_m2', true, 1),
('f0000005-0000-0000-0000-000000000005', '{"first_name": "Elvis", "last_name": "Presley", "birth_year": 1935, "death_year": 1977, "birthplace": "Тупело, Миссисипи", "poster": "https://image.tmdb.org/t/p/w186/jRJVLKwh1v5OJx1yVc8x8IcI3bZ.jpg"}'::jsonb, 'hash_m3', true, 1);

-- =========================================================================
-- 6. Additional Books (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000007-0000-0000-0000-000000000003', '1984', 'a0000000-0000-0000-0000-000000000007', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000007-0000-0000-0000-000000000004', 'fahrenheit-451', 'a0000000-0000-0000-0000-000000000007', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000007-0000-0000-0000-000000000005', 'brave-new-world', 'a0000000-0000-0000-0000-000000000007', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000007-0000-0000-0000-000000000003', 'ru', '1984', 'Антиутопический роман Джорджа Оруэлла', true, 1),
('d0000007-0000-0000-0000-000000000003', 'en', 'Nineteen Eighty-Four', 'Dystopian novel by George Orwell', true, 1),
('d0000007-0000-0000-0000-000000000004', 'ru', '451 градус по Фаренгейту', 'Антиутопический роман Рея Брэдбери', true, 1),
('d0000007-0000-0000-0000-000000000004', 'en', 'Fahrenheit 451', 'Dystopian novel by Ray Bradbury', true, 1),
('d0000007-0000-0000-0000-000000000005', 'ru', 'Дивный новый мир', 'Антиутопический роман Олдоса Хаксли', true, 1),
('d0000007-0000-0000-0000-000000000005', 'en', 'Brave New World', 'Dystopian novel by Aldous Huxley', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000007-0000-0000-0000-000000000003', 'd0000007-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='literature'), '1984-lit', 'Literature Data', 0.95, 1),
('f0000007-0000-0000-0000-000000000004', 'd0000007-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'fahrenheit-lit', 'Literature Data', 0.95, 1),
('f0000007-0000-0000-0000-000000000005', 'd0000007-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'brave-new-world-lit', 'Literature Data', 0.95, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000007-0000-0000-0000-000000000003', '{"title": "1984", "author": "George Orwell", "year": 1949, "pages": 328, "genre": "Антиутопия", "poster": "https://covers.openlibrary.org/b/id/8575391-L.jpg"}'::jsonb, 'hash_b1', true, 1),
('f0000007-0000-0000-0000-000000000004', '{"title": "Fahrenheit 451", "author": "Ray Bradbury", "year": 1953, "pages": 194, "genre": "Антиутопия", "poster": "https://covers.openlibrary.org/b/id/11153207-L.jpg"}'::jsonb, 'hash_b2', true, 1),
('f0000007-0000-0000-0000-000000000005', '{"title": "Brave New World", "author": "Aldous Huxley", "year": 1932, "pages": 311, "genre": "Антиутопия", "poster": "https://covers.openlibrary.org/b/id/8102119-L.jpg"}'::jsonb, 'hash_b3', true, 1);

-- =========================================================================
-- 7. Additional Writers (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000008-0000-0000-0000-000000000003', 'george-orwell', 'a0000000-0000-0000-0000-000000000008', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000008-0000-0000-0000-000000000004', 'ray-bradbury', 'a0000000-0000-0000-0000-000000000008', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000008-0000-0000-0000-000000000005', 'aldous-huxley', 'a0000000-0000-0000-0000-000000000008', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000008-0000-0000-0000-000000000003', 'ru', 'Джордж Оруэлл', 'Английский писатель и публицист', true, 1),
('d0000008-0000-0000-0000-000000000003', 'en', 'George Orwell', 'English novelist and essayist', true, 1),
('d0000008-0000-0000-0000-000000000004', 'ru', 'Рэй Брэдбери', 'Американский писатель-фантаст', true, 1),
('d0000008-0000-0000-0000-000000000004', 'en', 'Ray Bradbury', 'American science fiction author', true, 1),
('d0000008-0000-0000-0000-000000000005', 'ru', 'Олдос Хаксли', 'Английский писатель и философ', true, 1),
('d0000008-0000-0000-0000-000000000005', 'en', 'Aldous Huxley', 'English writer and philosopher', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000008-0000-0000-0000-000000000003', 'd0000008-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'orwell-lit', 'Writer Data', 0.9, 1),
('f0000008-0000-0000-0000-000000000004', 'd0000008-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'bradbury-lit', 'Writer Data', 0.9, 1),
('f0000008-0000-0000-0000-000000000005', 'd0000008-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'huxley-lit', 'Writer Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000008-0000-0000-0000-000000000003', '{"first_name": "George", "last_name": "Orwell", "birth_year": 1903, "death_year": 1950, "birthplace": "Мотихари, Индия", "notable_works": "1984, скотный двор", "poster": "https://image.tmdb.org/t/p/w186/7eyEsh1zSzsAR6ajqIrc6PXQ1pI.jpg"}'::jsonb, 'hash_w1', true, 1),
('f0000008-0000-0000-0000-000000000004', '{"first_name": "Ray", "last_name": "Bradbury", "birth_year": 1920, "death_year": 2012, "birthplace": "Уокиган, Иллинойс", "notable_works": "451 градус по Фаренгейту, Вино из одуванчиков", "poster": "https://image.tmdb.org/t/p/w186/yFCxw6yMmMCmrxvX0F3b3e3nO8e.jpg"}'::jsonb, 'hash_w2', true, 1),
('f0000008-0000-0000-0000-000000000005', '{"first_name": "Aldous", "last_name": "Huxley", "birth_year": 1894, "death_year": 1963, "birthplace": "Годалминг, Англия", "notable_works": "Дивный новый мир, О дивный новый мир", "poster": "https://image.tmdb.org/t/p/w186/4JfgNMore4R3DaU30U4CpMvMfJq.jpg"}'::jsonb, 'hash_w3', true, 1);

-- =========================================================================
-- 8. Additional Places (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000009-0000-0000-0000-000000000004', 'london', 'a0000000-0000-0000-0000-000000000009', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000009-0000-0000-0000-000000000005', 'new-york', 'a0000000-0000-0000-0000-000000000009', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000009-0000-0000-0000-000000000006', 'rome', 'a0000000-0000-0000-0000-000000000009', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000009-0000-0000-0000-000000000004', 'ru', 'Лондон', 'Столица Великобритании', true, 1),
('d0000009-0000-0000-0000-000000000004', 'en', 'London', 'Capital of the United Kingdom', true, 1),
('d0000009-0000-0000-0000-000000000005', 'ru', 'Нью-Йорк', 'Крупнейший город США', true, 1),
('d0000009-0000-0000-0000-000000000005', 'en', 'New York', 'Largest city in the United States', true, 1),
('d0000009-0000-0000-0000-000000000006', 'ru', 'Рим', 'Столица Италии', true, 1),
('d0000009-0000-0000-0000-000000000006', 'en', 'Rome', 'Capital of Italy', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000009-0000-0000-0000-000000000004', 'd0000009-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='geography'), 'london-geo', 'Location Data', 0.9, 1),
('f0000009-0000-0000-0000-000000000005', 'd0000009-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='geography'), 'newyork-geo', 'Location Data', 0.9, 1),
('f0000009-0000-0000-0000-000000000006', 'd0000009-0000-0000-0000-000000000006', (SELECT model_id FROM ontology_model WHERE model_code='geography'), 'rome-geo', 'Location Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000009-0000-0000-0000-000000000004', '{"city": "London", "country": "United Kingdom", "population": "8.9 млн", "area": "1572 км²", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/London_Skyline_%28125508654%29.jpeg/1280px-London_Skyline_%28125508654%29.jpeg"}'::jsonb, 'hash_p1', true, 1),
('f0000009-0000-0000-0000-000000000005', '{"city": "New York", "country": "USA", "population": "8.3 млн", "area": "783.8 км²", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/New_york_times_square-terabass.jpg/1280px-New_york_times_square-terabass.jpg"}'::jsonb, 'hash_p2', true, 1),
('f0000009-0000-0000-0000-000000000006', '{"city": "Rome", "country": "Italy", "population": "2.8 млн", "area": "1285 км²", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Colosseo_2020.jpg/1280px-Colosseo_2020.jpg"}'::jsonb, 'hash_p3', true, 1);

-- =========================================================================
-- 9. Additional Chemical Elements (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000010-0000-0000-0000-000000000004', 'iron', 'a0000000-0000-0000-0000-000000000010', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000010-0000-0000-0000-000000000005', 'gold', 'a0000000-0000-0000-0000-000000000010', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000010-0000-0000-0000-000000000006', 'silver', 'a0000000-0000-0000-0000-000000000010', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000010-0000-0000-0000-000000000004', 'ru', 'Железо', 'Химический элемент группы железа', true, 1),
('d0000010-0000-0000-0000-000000000004', 'en', 'Iron', 'Chemical element of the iron group', true, 1),
('d0000010-0000-0000-0000-000000000005', 'ru', 'Золото', 'Химический элемент золотой группы', true, 1),
('d0000010-0000-0000-0000-000000000005', 'en', 'Gold', 'Chemical element of the gold group', true, 1),
('d0000010-0000-0000-0000-000000000006', 'ru', 'Серебро', 'Химический элемент серебряной группы', true, 1),
('d0000010-0000-0000-0000-000000000006', 'en', 'Silver', 'Chemical element of the silver group', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000010-0000-0000-0000-000000000004', 'd0000010-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='science'), 'iron-sci', 'Science Data', 0.95, 1),
('f0000010-0000-0000-0000-000000000005', 'd0000010-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='science'), 'gold-sci', 'Science Data', 0.95, 1),
('f0000010-0000-0000-0000-000000000006', 'd0000010-0000-0000-0000-000000000006', (SELECT model_id FROM ontology_model WHERE model_code='science'), 'silver-sci', 'Science Data', 0.95, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000010-0000-0000-0000-000000000004', '{"symbol": "Fe", "atomic_number": 26, "atomic_mass": 55.845, "category": "Переходный металл", "electron_config": "[Ar] 3d6 4s2"}'::jsonb, 'hash_e1', true, 1),
('f0000010-0000-0000-0000-000000000005', '{"symbol": "Au", "atomic_number": 79, "atomic_mass": 196.967, "category": "Переходный металл", "electron_config": "[Xe] 4f14 5d10 6s1"}'::jsonb, 'hash_e2', true, 1),
('f0000010-0000-0000-0000-000000000006', '{"symbol": "Ag", "atomic_number": 47, "atomic_mass": 107.868, "category": "Переходный металл", "electron_config": "[Kr] 4d10 5s1"}'::jsonb, 'hash_e3', true, 1);

-- =========================================================================
-- 10. Additional Animals (3)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000011-0000-0000-0000-000000000004', 'tiger', 'a0000000-0000-0000-0000-000000000011', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000011-0000-0000-0000-000000000005', 'elephant', 'a0000000-0000-0000-0000-000000000011', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000011-0000-0000-0000-000000000006', 'penguin', 'a0000000-0000-0000-0000-000000000011', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000011-0000-0000-0000-000000000004', 'ru', 'Тигр', 'Крупнейший дикий кот', true, 1),
('d0000011-0000-0000-0000-000000000004', 'en', 'Tiger', 'Largest wild cat', true, 1),
('d0000011-0000-0000-0000-000000000005', 'ru', 'Слон', 'Крупнейшее наземное животное', true, 1),
('d0000011-0000-0000-0000-000000000005', 'en', 'Elephant', 'Largest land animal', true, 1),
('d0000011-0000-0000-0000-000000000006', 'ru', 'Пингвин', 'Нелетающая морская птица', true, 1),
('d0000011-0000-0000-0000-000000000006', 'en', 'Penguin', 'Flightless sea bird', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000011-0000-0000-0000-000000000004', 'd0000011-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'tiger-bio', 'Biology Data', 0.9, 1),
('f0000011-0000-0000-0000-000000000005', 'd0000011-0000-0000-0000-000000000005', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'elephant-bio', 'Biology Data', 0.9, 1),
('f0000011-0000-0000-0000-000000000006', 'd0000011-0000-0000-0000-000000000006', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'penguin-bio', 'Biology Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000011-0000-0000-0000-000000000004', '{"class": "Mammalia", "order": "Carnivora", "family": "Felidae", "habitat": "Тропические леса", "conservation": "Endangered", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/1200px-Cat03.jpg"}'::jsonb, 'hash_an1', true, 1),
('f0000011-0000-0000-0000-000000000005', '{"class": "Mammalia", "order": "Proboscidea", "family": "Elephantidae", "habitat": "Саванны, леса", "conservation": "Endangered", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/African_Bush_Elephant.jpg/1200px-African_Bush_Elephant.jpg"}'::jsonb, 'hash_an2', true, 1),
('f0000011-0000-0000-0000-000000000006', '{"class": "Aves", "order": "Sphenisciformes", "family": "Spheniscidae", "habitat": "Антарктика", "conservation": "Various", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Emperor_Penguins_at_Snow_Hill_Island.jpg/1200px-Emperor_Penguins_at_Snow_Hill_Island.jpg"}'::jsonb, 'hash_an3', true, 1);

-- =========================================================================
-- 11. Additional Organizations (2)
-- =========================================================================
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, version_id) VALUES
('d0000026-0000-0000-0000-000000000003', 'disney', 'b0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1),
('d0000026-0000-0000-0000-000000000004', 'apple-inc', 'b0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), 1);

INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
('d0000026-0000-0000-0000-000000000003', 'ru', 'Уолт Дисней', 'Американская медиакорпорация', true, 1),
('d0000026-0000-0000-0000-000000000003', 'en', 'The Walt Disney Company', 'American mass media corporation', true, 1),
('d0000026-0000-0000-0000-000000000004', 'ru', 'Эппл', 'Американская технологическая компания', true, 1),
('d0000026-0000-0000-0000-000000000004', 'en', 'Apple Inc.', 'American technology company', true, 1);

INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
('f0000026-0000-0000-0000-000000000003', 'd0000026-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'disney-org', 'Organization Data', 0.9, 1),
('f0000026-0000-0000-0000-000000000004', 'd0000026-0000-0000-0000-000000000004', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'apple-org', 'Organization Data', 0.9, 1);

INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
('f0000026-0000-0000-0000-000000000003', '{"name": "The Walt Disney Company", "founded": 1923, "headquarters": "Бербанк, Калифорния", "industry": "Медиа, развлечения", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Disney_Plus_logo.svg/1200px-Disney_Plus_logo.svg.png"}'::jsonb, 'hash_o1', true, 1),
('f0000026-0000-0000-0000-000000000004', '{"name": "Apple Inc.", "founded": 1976, "headquarters": "Купертино, Калифорния", "industry": "Технологии", "poster": "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1200px-Apple_logo_black.svg.png"}'::jsonb, 'hash_o2', true, 1);
