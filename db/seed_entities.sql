-- =============================================================================
--  META-SYSTEM: данные сущностей (30 seed-записей для теста)
-- =============================================================================

SET search_path TO meta;

-- Source system and version already in init.sql

-- Entity data
INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, owner_id, version_id) VALUES
-- Movies (2)
('d0000001-0000-0000-0000-000000000001', 'matrix', 'a0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000001-0000-0000-0000-000000000002', 'inception', 'a0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Actors (2)
('d0000002-0000-0000-0000-000000000001', 'keanu-reeves', 'a0000000-0000-0000-0000-000000000002', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000002-0000-0000-0000-000000000002', 'leonardo-dicaprio', 'a0000000-0000-0000-0000-000000000002', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Directors (2)
('d0000003-0000-0000-0000-000000000001', 'wachowskis', 'a0000000-0000-0000-0000-000000000003', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000003-0000-0000-0000-000000000002', 'christopher-nolan', 'a0000000-0000-0000-0000-000000000003', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Songs (2)
('d0000004-0000-0000-0000-000000000001', 'blue-danube', 'a0000000-0000-0000-0000-000000000004', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000004-0000-0000-0000-000000000002', 'bohemian-rhapsody', 'a0000000-0000-0000-0000-000000000004', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Musicians (2)
('d0000005-0000-0000-0000-000000000001', 'johann-strauss', 'a0000000-0000-0000-0000-000000000005', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000005-0000-0000-0000-000000000002', 'freddie-mercury', 'a0000000-0000-0000-0000-000000000005', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Albums (2)
('d0000006-0000-0000-0000-000000000001', 'a-night-at-opera', 'a0000000-0000-0000-0000-000000000006', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000006-0000-0000-0000-000000000002', 'greatest-hits', 'a0000000-0000-0000-0000-000000000006', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Books (2)
('d0000007-0000-0000-0000-000000000001', 'neuromancer', 'a0000000-0000-0000-0000-000000000007', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000007-0000-0000-0000-000000000002', 'dune', 'a0000000-0000-0000-0000-000000000007', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Writers (2)
('d0000008-0000-0000-0000-000000000001', 'william-gibson', 'a0000000-0000-0000-0000-000000000008', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000008-0000-0000-0000-000000000002', 'frank-herbert', 'a0000000-0000-0000-0000-000000000008', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Places (3)
('d0000009-0000-0000-0000-000000000001', 'moscow', 'a0000000-0000-0000-0000-000000000009', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000009-0000-0000-0000-000000000002', 'paris', 'a0000000-0000-0000-0000-000000000009', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000009-0000-0000-0000-000000000003', 'tokyo', 'a0000000-0000-0000-0000-000000000009', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Chemical Elements (3)
('d0000010-0000-0000-0000-000000000001', 'hydrogen', 'a0000000-0000-0000-0000-000000000010', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000010-0000-0000-0000-000000000002', 'oxygen', 'a0000000-0000-0000-0000-000000000010', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000010-0000-0000-0000-000000000003', 'carbon', 'a0000000-0000-0000-0000-000000000010', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Animals (3)
('d0000011-0000-0000-0000-000000000001', 'wolf', 'a0000000-0000-0000-0000-000000000011', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000011-0000-0000-0000-000000000002', 'eagle', 'a0000000-0000-0000-0000-000000000011', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000011-0000-0000-0000-000000000003', 'dolphin', 'a0000000-0000-0000-0000-000000000011', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Concepts (3)
('d0000013-0000-0000-0000-000000000001', 'cyberpunk', 'a0000000-0000-0000-0000-000000000013', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000013-0000-0000-0000-000000000002', 'democracy', 'a0000000-0000-0000-0000-000000000013', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000013-0000-0000-0000-000000000003', 'artificial-intelligence', 'a0000000-0000-0000-0000-000000000013', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Genres (2)
('d0000014-0000-0000-0000-000000000001', 'sci-fi', 'a0000000-0000-0000-0000-000000000014', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000014-0000-0000-0000-000000000002', 'classical', 'a0000000-0000-0000-0000-000000000014', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
-- Organizations (2)
('d0000026-0000-0000-0000-000000000001', 'warner-bros', 'b0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0000026-0000-0000-0000-000000000002', 'paris-opera', 'b0000000-0000-0000-0000-000000000001', 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1);

-- Entity labels (Russian + English for each entity)
INSERT INTO entity_label (entity_id, language, label, description, is_primary, version_id) VALUES
-- Matrix
('d0000001-0000-0000-0000-000000000001', 'ru', 'Матрица', 'Научно-фантастический фильм 1999 года', true, 1),
('d0000001-0000-0000-0000-000000000001', 'en', 'The Matrix', '1999 science fiction film', true, 1),
-- Inception
('d0000001-0000-0000-0000-000000000002', 'ru', 'Начало', 'Фильм Кристофера Нолана 2010 года', true, 1),
('d0000001-0000-0000-0000-000000000002', 'en', 'Inception', '2010 film by Christopher Nolan', true, 1),
-- Keanu Reeves
('d0000002-0000-0000-0000-000000000001', 'ru', 'Киану Ривз', 'Канадский актёр', true, 1),
('d0000002-0000-0000-0000-000000000001', 'en', 'Keanu Reeves', 'Canadian actor', true, 1),
-- Leonardo DiCaprio
('d0000002-0000-0000-0000-000000000002', 'ru', 'Леонардо ДиКаприо', 'Американский актёр', true, 1),
('d0000002-0000-0000-0000-000000000002', 'en', 'Leonardo DiCaprio', 'American actor', true, 1),
-- Wachowskis
('d0000003-0000-0000-0000-000000000001', 'ru', 'Братья Вачовски', 'Американские режиссёры', true, 1),
('d0000003-0000-0000-0000-000000000001', 'en', 'The Wachowskis', 'American directors', true, 1),
-- Christopher Nolan
('d0000003-0000-0000-0000-000000000002', 'ru', 'Кристофер Нолан', 'Британско-американский режиссёр', true, 1),
('d0000003-0000-0000-0000-000000000002', 'en', 'Christopher Nolan', 'British-American director', true, 1),
-- Blue Danube
('d0000004-0000-0000-0000-000000000001', 'ru', 'Голубой Дунай', 'Вальс Иоганна Штрауса', true, 1),
('d0000004-0000-0000-0000-000000000001', 'en', 'The Blue Danube', 'Waltz by Johann Strauss II', true, 1),
-- Bohemian Rhapsody
('d0000004-0000-0000-0000-000000000002', 'ru', 'Богемская рапсодия', 'Песня группы Queen', true, 1),
('d0000004-0000-0000-0000-000000000002', 'en', 'Bohemian Rhapsody', 'Song by Queen', true, 1),
-- Johann Strauss
('d0000005-0000-0000-0000-000000000001', 'ru', 'Иоганн Штраус', 'Австрийский композитор', true, 1),
('d0000005-0000-0000-0000-000000000001', 'en', 'Johann Strauss II', 'Austrian composer', true, 1),
-- Freddie Mercury
('d0000005-0000-0000-0000-000000000002', 'ru', 'Фредди Меркьюри', 'Британский певец', true, 1),
('d0000005-0000-0000-0000-000000000002', 'en', 'Freddie Mercury', 'British singer', true, 1),
-- A Night at the Opera
('d0000006-0000-0000-0000-000000000001', 'ru', 'Ночь в опере', 'Альбом группы Queen', true, 1),
('d0000006-0000-0000-0000-000000000001', 'en', 'A Night at the Opera', 'Album by Queen', true, 1),
-- Greatest Hits
('d0000006-0000-0000-0000-000000000002', 'ru', 'Лучшие хиты', 'Сборник хитов Queen', true, 1),
('d0000006-0000-0000-0000-000000000002', 'en', 'Greatest Hits', 'Queen compilation album', true, 1),
-- Neuromancer
('d0000007-0000-0000-0000-000000000001', 'ru', 'Нейромант', 'Роман Уильяма Гибсона', true, 1),
('d0000007-0000-0000-0000-000000000001', 'en', 'Neuromancer', 'Novel by William Gibson', true, 1),
-- Dune
('d0000007-0000-0000-0000-000000000002', 'ru', 'Дюна', 'Роман Фрэнка Герберта', true, 1),
('d0000007-0000-0000-0000-000000000002', 'en', 'Dune', 'Novel by Frank Herbert', true, 1),
-- William Gibson
('d0000008-0000-0000-0000-000000000001', 'ru', 'Уильям Гибсон', 'Американский писатель', true, 1),
('d0000008-0000-0000-0000-000000000001', 'en', 'William Gibson', 'American writer', true, 1),
-- Frank Herbert
('d0000008-0000-0000-0000-000000000002', 'ru', 'Фрэнк Герберт', 'Американский писатель', true, 1),
('d0000008-0000-0000-0000-000000000002', 'en', 'Frank Herbert', 'American writer', true, 1),
-- Moscow
('d0000009-0000-0000-0000-000000000001', 'ru', 'Москва', 'Столица России', true, 1),
('d0000009-0000-0000-0000-000000000001', 'en', 'Moscow', 'Capital of Russia', true, 1),
-- Paris
('d0000009-0000-0000-0000-000000000002', 'ru', 'Париж', 'Столица Франции', true, 1),
('d0000009-0000-0000-0000-000000000002', 'en', 'Paris', 'Capital of France', true, 1),
-- Tokyo
('d0000009-0000-0000-0000-000000000003', 'ru', 'Токио', 'Столица Японии', true, 1),
('d0000009-0000-0000-0000-000000000003', 'en', 'Tokyo', 'Capital of Japan', true, 1),
-- Hydrogen
('d0000010-0000-0000-0000-000000000001', 'ru', 'Водород', 'Химический элемент 1', true, 1),
('d0000010-0000-0000-0000-000000000001', 'en', 'Hydrogen', 'Chemical element 1', true, 1),
-- Oxygen
('d0000010-0000-0000-0000-000000000002', 'ru', 'Кислород', 'Химический элемент 8', true, 1),
('d0000010-0000-0000-0000-000000000002', 'en', 'Oxygen', 'Chemical element 8', true, 1),
-- Carbon
('d0000010-0000-0000-0000-000000000003', 'ru', 'Углерод', 'Химический элемент 6', true, 1),
('d0000010-0000-0000-0000-000000000003', 'en', 'Carbon', 'Chemical element 6', true, 1),
-- Wolf
('d0000011-0000-0000-0000-000000000001', 'ru', 'Волк', 'Хищное млекопитающее', true, 1),
('d0000011-0000-0000-0000-000000000001', 'en', 'Wolf', 'Predatory mammal', true, 1),
-- Eagle
('d0000011-0000-0000-0000-000000000002', 'ru', 'Орёл', 'Хищная птица', true, 1),
('d0000011-0000-0000-0000-000000000002', 'en', 'Eagle', 'Bird of prey', true, 1),
-- Dolphin
('d0000011-0000-0000-0000-000000000003', 'ru', 'Дельфин', 'Морское млекопитающее', true, 1),
('d0000011-0000-0000-0000-000000000003', 'en', 'Dolphin', 'Marine mammal', true, 1),
-- Cyberpunk
('d0000013-0000-0000-0000-000000000001', 'ru', 'Киберпанк', 'Научно-фантастический жанр', true, 1),
('d0000013-0000-0000-0000-000000000001', 'en', 'Cyberpunk', 'Science fiction genre', true, 1),
-- Democracy
('d0000013-0000-0000-0000-000000000002', 'ru', 'Демократия', 'Форма правления', true, 1),
('d0000013-0000-0000-0000-000000000002', 'en', 'Democracy', 'Form of government', true, 1),
-- AI
('d0000013-0000-0000-0000-000000000003', 'ru', 'Искусственный интеллект', 'Технология ИИ', true, 1),
('d0000013-0000-0000-0000-000000000003', 'en', 'Artificial Intelligence', 'AI technology', true, 1),
-- Sci-fi
('d0000014-0000-0000-0000-000000000001', 'ru', 'Научная фантастика', 'Жанр', true, 1),
('d0000014-0000-0000-0000-000000000001', 'en', 'Science Fiction', 'Genre', true, 1),
-- Classical
('d0000014-0000-0000-0000-000000000002', 'ru', 'Классическая музыка', 'Музыкальный жанр', true, 1),
('d0000014-0000-0000-0000-000000000002', 'en', 'Classical Music', 'Music genre', true, 1),
-- Warner Bros
('d0000026-0000-0000-0000-000000000001', 'ru', 'Уорнер Бразерс', 'Киностудия', true, 1),
('d0000026-0000-0000-0000-000000000001', 'en', 'Warner Bros.', 'Film studio', true, 1),
-- Paris Opera
('d0000026-0000-0000-0000-000000000002', 'ru', 'Парижская опера', 'Оперный театр', true, 1),
('d0000026-0000-0000-0000-000000000002', 'en', 'Paris Opera', 'Opera house', true, 1);

-- Entity projections (basic data for each entity)
INSERT INTO entity_projection (projection_id, entity_id, model_id, projection_code, projection_name, confidence, version_id) VALUES
-- Movies
('e0000001-0000-0000-0000-000000000001', 'd0000001-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'matrix-cinema', 'Cinema Data', 0.95, 1),
('e0000001-0000-0000-0000-000000000002', 'd0000001-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'inception-cinema', 'Cinema Data', 0.95, 1),
-- Actors
('e0000002-0000-0000-0000-000000000001', 'd0000002-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'keanu-reeves-data', 'Actor Data', 0.9, 1),
('e0000002-0000-0000-0000-000000000002', 'd0000002-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'leonardo-dicaprio-data', 'Actor Data', 0.9, 1),
-- Directors
('e0000003-0000-0000-0000-000000000001', 'd0000003-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'wachowskis-cinema', 'Director Data', 0.9, 1),
('e0000003-0000-0000-0000-000000000002', 'd0000003-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='cinema'), 'nolan-cinema', 'Director Data', 0.9, 1),
-- Songs
('e0000004-0000-0000-0000-000000000001', 'd0000004-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'blue-danube-music', 'Music Data', 0.95, 1),
('e0000004-0000-0000-0000-000000000002', 'd0000004-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'bohemian-rhapsody-music', 'Music Data', 0.95, 1),
-- Musicians
('e0000005-0000-0000-0000-000000000001', 'd0000005-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'johann-strauss-music', 'Musician Data', 0.9, 1),
('e0000005-0000-0000-0000-000000000002', 'd0000005-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'freddie-mercury-music', 'Musician Data', 0.9, 1),
-- Albums
('e0000006-0000-0000-0000-000000000001', 'd0000006-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'night-opera-music', 'Album Data', 0.9, 1),
('e0000006-0000-0000-0000-000000000002', 'd0000006-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='music'), 'greatest-hits-music', 'Album Data', 0.9, 1),
-- Books
('e0000007-0000-0000-0000-000000000001', 'd0000007-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'neuromancer-lit', 'Literature Data', 0.95, 1),
('e0000007-0000-0000-0000-000000000002', 'd0000007-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'dune-lit', 'Literature Data', 0.95, 1),
-- Writers
('e0000008-0000-0000-0000-000000000001', 'd0000008-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'gibson-lit', 'Writer Data', 0.9, 1),
('e0000008-0000-0000-0000-000000000002', 'd0000008-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='literature'), 'herbert-lit', 'Writer Data', 0.9, 1),
-- Places
('e0000009-0000-0000-0000-000000000001', 'd0000009-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='geography'), 'moscow-geo', 'Geography Data', 0.95, 1),
('e0000009-0000-0000-0000-000000000002', 'd0000009-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='geography'), 'paris-geo', 'Geography Data', 0.95, 1),
('e0000009-0000-0000-0000-000000000003', 'd0000009-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='geography'), 'tokyo-geo', 'Geography Data', 0.95, 1),
-- Chemical Elements
('e0000010-0000-0000-0000-000000000001', 'd0000010-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='science'), 'hydrogen-sci', 'Science Data', 0.98, 1),
('e0000010-0000-0000-0000-000000000002', 'd0000010-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='science'), 'oxygen-sci', 'Science Data', 0.98, 1),
('e0000010-0000-0000-0000-000000000003', 'd0000010-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='science'), 'carbon-sci', 'Science Data', 0.98, 1),
-- Animals
('e0000011-0000-0000-0000-000000000001', 'd0000011-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'wolf-bio', 'Biology Data', 0.9, 1),
('e0000011-0000-0000-0000-000000000002', 'd0000011-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'eagle-bio', 'Biology Data', 0.9, 1),
('e0000011-0000-0000-0000-000000000003', 'd0000011-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'dolphin-bio', 'Biology Data', 0.9, 1),
-- Concepts
('e0000013-0000-0000-0000-000000000001', 'd0000013-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'cyberpunk-concept', 'Concept Data', 0.85, 1),
('e0000013-0000-0000-0000-000000000002', 'd0000013-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'democracy-concept', 'Concept Data', 0.85, 1),
('e0000013-0000-0000-0000-000000000003', 'd0000013-0000-0000-0000-000000000003', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'ai-concept', 'Concept Data', 0.85, 1),
-- Genres
('e0000014-0000-0000-0000-000000000001', 'd0000014-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'scifi-genre', 'Genre Data', 0.9, 1),
('e0000014-0000-0000-0000-000000000002', 'd0000014-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'classical-genre', 'Genre Data', 0.9, 1),
-- Organizations
('e0000026-0000-0000-0000-000000000001', 'd0000026-0000-0000-0000-000000000001', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'warner-bros-org', 'Organization Data', 0.9, 1),
('e0000026-0000-0000-0000-000000000002', 'd0000026-0000-0000-0000-000000000002', (SELECT model_id FROM ontology_model WHERE model_code='default'), 'paris-opera-org', 'Organization Data', 0.9, 1);

-- Projection states (with JSONB data)
INSERT INTO projection_state (projection_id, state_data, state_hash, is_current, version_id) VALUES
-- Matrix
('e0000001-0000-0000-0000-000000000001', '{"title": "The Matrix", "year": 1999, "runtime": 136, "genre": "Action/Sci-Fi", "rating": 8.7, "budget": 63000000, "revenue": 467200000, "mpaa_rating": "R", "production_companies": ["Warner Bros.", "Village Roadshow Pictures"]}', 'hash1', true, 1),
-- Inception
('e0000001-0000-0000-0000-000000000002', '{"title": "Inception", "year": 2010, "runtime": 148, "genre": "Action/Sci-Fi", "rating": 8.8, "budget": 160000000, "revenue": 839000000, "mpaa_rating": "PG-13", "tagline": "Your mind is the scene of the crime"}', 'hash2', true, 1),
-- Keanu Reeves
('e0000002-0000-0000-0000-000000000001', '{"first_name": "Keanu", "last_name": "Reeves", "birth_date": "1964-09-02", "birth_place": "Beirut, Lebanon", "nationality": "Canadian", "height_cm": 186}', 'hash3', true, 1),
-- Leonardo DiCaprio
('e0000002-0000-0000-0000-000000000002', '{"first_name": "Leonardo", "last_name": "DiCaprio", "birth_date": "1974-11-11", "birth_place": "Los Angeles, USA", "nationality": "American", "height_cm": 183}', 'hash4', true, 1),
-- Wachowskis
('e0000003-0000-0000-0000-000000000001', '{"members": ["Lana Wachowski", "Lily Wachowski"], "nationality": "American", "notable_works": ["The Matrix", "Cloud Atlas"]}', 'hash5', true, 1),
-- Christopher Nolan
('e0000003-0000-0000-0000-000000000002', '{"first_name": "Christopher", "last_name": "Nolan", "birth_date": "1970-07-30", "birth_place": "London, UK", "nationality": "British-American"}', 'hash6', true, 1),
-- Blue Danube
('e0000004-0000-0000-0000-000000000001', '{"title": "The Blue Danube", "composer": "Johann Strauss II", "year": 1867, "op": "Op. 314", "key": "D major"}', 'hash7', true, 1),
-- Bohemian Rhapsody
('e0000004-0000-0000-0000-000000000002', '{"title": "Bohemian Rhapsody", "artist": "Queen", "album": "A Night at the Opera", "year": 1975, "duration": 355, "key": "Bb major"}', 'hash8', true, 1),
-- Johann Strauss
('e0000005-0000-0000-0000-000000000001', '{"first_name": "Johann", "last_name": "Strauss II", "birth_date": "1825-10-25", "death_date": "1899-05-03", "birth_place": "Vienna, Austria", "nickname": "The Waltz King"}', 'hash9', true, 1),
-- Freddie Mercury
('e0000005-0000-0000-0000-000000000002', '{"first_name": "Freddie", "last_name": "Mercury", "birth_date": "1946-09-05", "death_date": "1991-11-24", "birth_place": "Zanzibar", "occupation": "Singer, songwriter"}', 'hash10', true, 1),
-- A Night at the Opera
('e0000006-0000-0000-0000-000000000001', '{"title": "A Night at the Opera", "artist": "Queen", "year": 1975, "genre": "Rock", "tracks": 12, "label": "EMI"}', 'hash11', true, 1),
-- Greatest Hits
('e0000006-0000-0000-0000-000000000002', '{"title": "Greatest Hits", "artist": "Queen", "year": 1981, "genre": "Rock", "tracks": 17, "label": "EMI"}', 'hash12', true, 1),
-- Neuromancer
('e0000007-0000-0000-0000-000000000001', '{"title": "Neuromancer", "author": "William Gibson", "year": 1984, "pages": 271, "publisher": "Ace Books", "genre": "Cyberpunk", "isbn": "978-0-441-56956-4"}', 'hash13', true, 1),
-- Dune
('e0000007-0000-0000-0000-000000000002', '{"title": "Dune", "author": "Frank Herbert", "year": 1965, "pages": 412, "publisher": "Chilton Books", "genre": "Science Fiction", "isbn": "978-0-441-17271-9"}', 'hash14', true, 1),
-- William Gibson
('e0000008-0000-0000-0000-000000000001', '{"first_name": "William", "last_name": "Gibson", "birth_date": "1948-03-17", "birth_place": "Portsmouth, USA", "nationality": "American-Canadian", "occupation": "Writer"}', 'hash15', true, 1),
-- Frank Herbert
('e0000008-0000-0000-0000-000000000002', '{"first_name": "Frank", "last_name": "Herbert", "birth_date": "1920-10-08", "death_date": "1986-02-11", "birth_place": "Tacoma, USA", "occupation": "Writer"}', 'hash16', true, 1),
-- Moscow
('e0000009-0000-0000-0000-000000000001', '{"city": "Moscow", "country": "Russia", "population": 12600000, "latitude": 55.7558, "longitude": 37.6173, "timezone": "UTC+3"}', 'hash17', true, 1),
-- Paris
('e0000009-0000-0000-0000-000000000002', '{"city": "Paris", "country": "France", "population": 2161000, "latitude": 48.8566, "longitude": 2.3522, "timezone": "UTC+1"}', 'hash18', true, 1),
-- Tokyo
('e0000009-0000-0000-0000-000000000003', '{"city": "Tokyo", "country": "Japan", "population": 13960000, "latitude": 35.6762, "longitude": 139.6503, "timezone": "UTC+9"}', 'hash19', true, 1),
-- Hydrogen
('e0000010-0000-0000-0000-000000000001', '{"element": "Hydrogen", "symbol": "H", "atomic_number": 1, "atomic_mass": 1.008, "electron_configuration": "1s1", "melting_point": -259.16, "boiling_point": -252.87}', 'hash20', true, 1),
-- Oxygen
('e0000010-0000-0000-0000-000000000002', '{"element": "Oxygen", "symbol": "O", "atomic_number": 8, "atomic_mass": 15.999, "electron_configuration": "[He] 2s2 2p4", "melting_point": -218.79, "boiling_point": -182.96}', 'hash21', true, 1),
-- Carbon
('e0000010-0000-0000-0000-000000000003', '{"element": "Carbon", "symbol": "C", "atomic_number": 6, "atomic_mass": 12.011, "electron_configuration": "[He] 2s2 2p2", "melting_point": 3550, "boiling_point": 4027}', 'hash22', true, 1),
-- Wolf
('e0000011-0000-0000-0000-000000000001', '{"common_name": "Wolf", "scientific_name": "Canis lupus", "class": "Mammalia", "order": "Carnivora", "family": "Canidae", "habitat": "Forests, tundra"}', 'hash23', true, 1),
-- Eagle
('e0000011-0000-0000-0000-000000000002', '{"common_name": "Eagle", "scientific_name": "Aquila chrysaetos", "class": "Aves", "order": "Accipitriformes", "family": "Accipitridae", "habitat": "Mountains, open areas"}', 'hash24', true, 1),
-- Dolphin
('e0000011-0000-0000-0000-000000000003', '{"common_name": "Bottlenose Dolphin", "scientific_name": "Tursiops truncatus", "class": "Mammalia", "order": "Artiodactyla", "family": "Delphinidae", "habitat": "Oceans worldwide"}', 'hash25', true, 1),
-- Cyberpunk
('e0000013-0000-0000-0000-000000000001', '{"name": "Cyberpunk", "description": "A subgenre of science fiction set in a lawless digital world", "origins": "1980s", "key_works": ["Neuromancer", "Blade Runner"]}', 'hash26', true, 1),
-- Democracy
('e0000013-0000-0000-0000-000000000002', '{"name": "Democracy", "description": "A system of government by the whole population", "origins": "Ancient Greece", "variants": ["Direct", "Representative"]}', 'hash27', true, 1),
-- AI
('e0000013-0000-0000-0000-000000000003', '{"name": "Artificial Intelligence", "description": "Intelligence demonstrated by machines", "subfields": ["Machine Learning", "NLP", "Computer Vision"]}', 'hash28', true, 1),
-- Sci-fi
('e0000014-0000-0000-0000-000000000001', '{"name": "Science Fiction", "description": "Speculative fiction dealing with futuristic concepts", "subgenres": ["Cyberpunk", "Space Opera", "Dystopian"]}', 'hash29', true, 1),
-- Classical
('e0000014-0000-0000-0000-000000000002', '{"name": "Classical Music", "description": "Art music rooted in Western tradition", "periods": ["Baroque", "Classical", "Romantic", "Modern"]}', 'hash30', true, 1),
-- Warner Bros
('e0000026-0000-0000-0000-000000000001', '{"name": "Warner Bros.", "type": "Film studio", "founded": 1923, "founders": ["Harry Warner", "Albert Warner", "Sam Warner", "Jack Warner"], "headquarters": "Burbank, California"}', 'hash31', true, 1),
-- Paris Opera
('e0000026-0000-0000-0000-000000000002', '{"name": "Paris Opera", "type": "Opera house", "founded": 1669, "location": "Paris, France", "notable_architect": "Charles Garnier"}', 'hash32', true, 1);

-- Semantic relations (some basic connections)
INSERT INTO semantic_relation (source_projection_id, relation_type_id, target_projection_id, confidence, version_id) VALUES
-- Matrix acted in by Keanu Reeves
('e0000001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'e0000002-0000-0000-0000-000000000001', 0.99, 1),
-- Inception acted in by Leonardo DiCaprio
('e0000001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'e0000002-0000-0000-0000-000000000002', 0.99, 1),
-- Matrix directed by Wachowskis
('e0000001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='directed_by'), 'e0000003-0000-0000-0000-000000000001', 0.99, 1),
-- Inception directed by Nolan
('e0000001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='directed_by'), 'e0000003-0000-0000-0000-000000000002', 0.99, 1),
-- Bohemian Rhapsody composed by Mercury
('e0000004-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'e0000005-0000-0000-0000-000000000002', 0.98, 1),
-- Blue Danube composed by Strauss
('e0000004-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'e0000005-0000-0000-0000-000000000001', 0.99, 1),
-- Bohemian Rhapsody in Night at Opera album
('e0000004-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='part_of'), 'e0000006-0000-0000-0000-000000000001', 0.99, 1),
-- Neuromancer written by Gibson
('e0000007-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'e0000008-0000-0000-0000-000000000001', 0.99, 1),
-- Dune written by Herbert
('e0000007-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'e0000008-0000-0000-0000-000000000002', 0.99, 1),
-- Matrix is sci-fi
('e0000001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'e0000014-0000-0000-0000-000000000001', 0.95, 1),
-- Inception is sci-fi
('e0000001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'e0000014-0000-0000-0000-000000000001', 0.95, 1),
-- Neuromancer is sci-fi
('e0000007-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'e0000014-0000-0000-0000-000000000001', 0.95, 1),
-- Blue Danube is classical
('e0000004-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'e0000014-0000-0000-0000-000000000002', 0.98, 1),
-- Night at Opera is classical
('e0000006-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'e0000014-0000-0000-0000-000000000002', 0.95, 1),
-- Wolf is canine (similar to dog)
('e0000011-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='related_to'), 'e0000011-0000-0000-0000-000000000003', 0.6, 1),
-- Matrix filmed in Warner Bros
('e0000001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='produced_by'), 'e0000026-0000-0000-0000-000000000001', 0.9, 1),
-- Inception filmed in Warner Bros
('e0000001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='produced_by'), 'e0000026-0000-0000-0000-000000000001', 0.9, 1),
-- Bohemian Rhapsody published by EMI (Greatest Hits)
('e0000004-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='published_by'), 'e0000026-0000-0000-0000-000000000002', 0.85, 1);

-- Menu items
INSERT INTO menu_item (menu_id, menu_code, label, label_en, url, sort_order) VALUES
('f0000001-0000-0000-0000-000000000001', 'main', 'Главная', 'Home', '/', 1),
('f0000002-0000-0000-0000-000000000001', 'main', 'Каталог', 'Catalog', '/entities', 2),
('f0000003-0000-0000-0000-000000000001', 'main', 'Поиск', 'Search', '/search', 3),
('f0000004-0000-0000-0000-000000000001', 'main', 'Карта знаний', 'Knowledge Graph', '/graph', 4),
('f0000005-0000-0000-0000-000000000001', 'main', 'Загрузка файлов', 'File Upload', '/upload', 5),
('f0000006-0000-0000-0000-000000000001', 'main', 'Настройки', 'Settings', '/settings', 6),
('f0000007-0000-0000-0000-000000000001', 'main', 'Справочники', 'Classifiers', '/classifiers', 7);

-- Page registry
INSERT INTO page_registry (page_id, page_code, title, title_en, template_name, content, is_published, sort_order) VALUES
('60000001-0000-0000-0000-000000000001', 'home', 'Главная страница', 'Home Page', 'default', '{"blocks": [{"type": "hero", "title": "META-SYSTEM", "subtitle": "Universal Knowledge Storage"}]}', true, 1),
('60000002-0000-0000-0000-000000000001', 'catalog', 'Каталог сущностей', 'Entity Catalog', 'catalog', '{"pagination": 20, "show_filters": true}', true, 2),
('60000003-0000-0000-0000-000000000001', 'search', 'Поиск', 'Search', 'search', '{"search_types": ["fulltext", "vector", "ai"]}', true, 3);
