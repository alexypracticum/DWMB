-- =============================================================================
--  ENTITY KINDS: иерархия типов сущностей (35 типов)
-- =============================================================================

SET search_path TO meta, public;

-- Корневые типы (уровень 0)
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id) VALUES
    ('entity', NULL, 'Root entity type', true, 0, 1);

-- Уровень 1: абстрактные категории
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'physical_object', kind_id, 'Physical objects in space-time', true, 10, 1 FROM entity_kind WHERE kind_code = 'entity';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'information_object', kind_id, 'Information and media objects', true, 20, 1 FROM entity_kind WHERE kind_code = 'entity';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'abstract_concept', kind_id, 'Abstract ideas and concepts', true, 30, 1 FROM entity_kind WHERE kind_code = 'entity';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'process', kind_id, 'Processes and phenomena', true, 40, 1 FROM entity_kind WHERE kind_code = 'entity';

-- Уровень 2: физические объекты
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'living_being', kind_id, 'Living organisms', true, 11, 1 FROM entity_kind WHERE kind_code = 'physical_object';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'inanimate_object', kind_id, 'Non-living objects', true, 15, 1 FROM entity_kind WHERE kind_code = 'physical_object';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'chemical_element', kind_id, 'Chemical element', false, 18, 1 FROM entity_kind WHERE kind_code = 'physical_object';

-- Уровень 2: информационные объекты
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'media', kind_id, 'Media content', true, 21, 1 FROM entity_kind WHERE kind_code = 'information_object';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'document', kind_id, 'Document / text', true, 25, 1 FROM entity_kind WHERE kind_code = 'information_object';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'digital_file', kind_id, 'Digital file', false, 27, 1 FROM entity_kind WHERE kind_code = 'information_object';

-- Уровень 2: абстрактные концепты
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'concept', kind_id, 'Abstract concept / idea', false, 31, 1 FROM entity_kind WHERE kind_code = 'abstract_concept';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'movement', kind_id, 'Cultural / art movement', false, 32, 1 FROM entity_kind WHERE kind_code = 'abstract_concept';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'genre', kind_id, 'Genre / category', false, 33, 1 FROM entity_kind WHERE kind_code = 'abstract_concept';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'period', kind_id, 'Historical period / era', false, 34, 1 FROM entity_kind WHERE kind_code = 'abstract_concept';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'classifier', kind_id, 'Classifier / taxonomy', false, 35, 1 FROM entity_kind WHERE kind_code = 'abstract_concept';

-- Уровень 2: процессы и явления
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'phenomenon', kind_id, 'Natural or social phenomenon', false, 41, 1 FROM entity_kind WHERE kind_code = 'process';

-- Уровень 3: живые существа
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'human', kind_id, 'Human being', false, 12, 1 FROM entity_kind WHERE kind_code = 'living_being';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'animal', kind_id, 'Non-human animal', false, 13, 1 FROM entity_kind WHERE kind_code = 'living_being';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'plant', kind_id, 'Plant organism', false, 14, 1 FROM entity_kind WHERE kind_code = 'living_being';

-- Уровень 3: неживые объекты
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'place', kind_id, 'Geographical place / location', false, 16, 1 FROM entity_kind WHERE kind_code = 'inanimate_object';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'physical_item', kind_id, 'Physical object / item', false, 17, 1 FROM entity_kind WHERE kind_code = 'inanimate_object';

-- Уровень 3: медиа
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'movie', kind_id, 'Film / movie', false, 211, 1 FROM entity_kind WHERE kind_code = 'media';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'song', kind_id, 'Song / music track', false, 212, 1 FROM entity_kind WHERE kind_code = 'media';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'album', kind_id, 'Music album', false, 213, 1 FROM entity_kind WHERE kind_code = 'media';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'photo', kind_id, 'Photograph / image', false, 214, 1 FROM entity_kind WHERE kind_code = 'media';

-- Уровень 3: документы
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'book', kind_id, 'Book', false, 251, 1 FROM entity_kind WHERE kind_code = 'document';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'article', kind_id, 'Article / post', false, 252, 1 FROM entity_kind WHERE kind_code = 'document';

-- Уровень 4: люди (профессии)
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'actor', kind_id, 'Actor / performer', false, 121, 1 FROM entity_kind WHERE kind_code = 'human';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'director', kind_id, 'Film / theatre director', false, 122, 1 FROM entity_kind WHERE kind_code = 'human';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'writer', kind_id, 'Writer / author', false, 123, 1 FROM entity_kind WHERE kind_code = 'human';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'musician', kind_id, 'Musician / composer', false, 124, 1 FROM entity_kind WHERE kind_code = 'human';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'scientist', kind_id, 'Scientist / researcher', false, 126, 1 FROM entity_kind WHERE kind_code = 'human';
INSERT INTO entity_kind (kind_code, parent_kind_id, description, is_abstract, sort_order, version_id)
SELECT 'artist', kind_id, 'Visual artist / painter', false, 127, 1 FROM entity_kind WHERE kind_code = 'human';

-- Мультиязычные названия (language_id FK через таблицу language)
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Человек', 'Человек'
FROM entity_kind ek, language l WHERE ek.kind_code = 'human' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Актёр', 'Актёр / исполнитель'
FROM entity_kind ek, language l WHERE ek.kind_code = 'actor' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Режиссёр', 'Режиссёр театра / кино'
FROM entity_kind ek, language l WHERE ek.kind_code = 'director' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Писатель', 'Писатель / автор'
FROM entity_kind ek, language l WHERE ek.kind_code = 'writer' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Музыкант', 'Музыкант / композитор'
FROM entity_kind ek, language l WHERE ek.kind_code = 'musician' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Учёный', 'Учёный / исследователь'
FROM entity_kind ek, language l WHERE ek.kind_code = 'scientist' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Художник', 'Художник / живописец'
FROM entity_kind ek, language l WHERE ek.kind_code = 'artist' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Фильм', 'Художественный фильм'
FROM entity_kind ek, language l WHERE ek.kind_code = 'movie' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Песня', 'Музыкальное произведение'
FROM entity_kind ek, language l WHERE ek.kind_code = 'song' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Альбом', 'Музыкальный альбом'
FROM entity_kind ek, language l WHERE ek.kind_code = 'album' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Книга', 'Книжное издание'
FROM entity_kind ek, language l WHERE ek.kind_code = 'book' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Статья', 'Статья / пост'
FROM entity_kind ek, language l WHERE ek.kind_code = 'article' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Город', 'Город / населённый пункт'
FROM entity_kind ek, language l WHERE ek.kind_code = 'place' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Животное', 'Животное'
FROM entity_kind ek, language l WHERE ek.kind_code = 'animal' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Растение', 'Растение'
FROM entity_kind ek, language l WHERE ek.kind_code = 'plant' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Химический элемент', 'Химический элемент таблицы Менделеева'
FROM entity_kind ek, language l WHERE ek.kind_code = 'chemical_element' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Файл', 'Цифровой файл'
FROM entity_kind ek, language l WHERE ek.kind_code = 'digital_file' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Концепция', 'Абстрактная концепция / идея'
FROM entity_kind ek, language l WHERE ek.kind_code = 'concept' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Движение', 'Культурное / художественное движение'
FROM entity_kind ek, language l WHERE ek.kind_code = 'movement' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Жанр', 'Жанр / категория'
FROM entity_kind ek, language l WHERE ek.kind_code = 'genre' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Эпоха', 'Исторический период / эра'
FROM entity_kind ek, language l WHERE ek.kind_code = 'period' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Классификатор', 'Классификатор / таксономия'
FROM entity_kind ek, language l WHERE ek.kind_code = 'classifier' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Явление', 'Природное или социальное явление'
FROM entity_kind ek, language l WHERE ek.kind_code = 'phenomenon' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Фото', 'Фотография / изображение'
FROM entity_kind ek, language l WHERE ek.kind_code = 'photo' AND l.code = 'ru';
INSERT INTO entity_kind_label (kind_id, language_id, label, description)
SELECT ek.kind_id, l.language_id, 'Объект', 'Физический объект / предмет'
FROM entity_kind ek, language l WHERE ek.kind_code = 'physical_item' AND l.code = 'ru';
