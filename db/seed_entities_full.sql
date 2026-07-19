-- =============================================================================
--  META-SYSTEM: Полный набор seed-данных (200 сущностей, 5 на тип, 40 типов)
--  Дата: 2026-07-18
-- =============================================================================

SET search_path TO meta;

-- =============================================================================
--  1. ENTITY RECORDS (200 записей)
-- =============================================================================

INSERT INTO entity (entity_id, entity_code, kind_id, status, source_id, owner_id, version_id) VALUES
-- ═══════════════════════════════════════════════════════════════
-- 01. movie (5)
-- ═══════════════════════════════════════════════════════════════
('d0100001-0000-0000-0000-000000000001', 'interstellar', (SELECT kind_id FROM entity_kind WHERE kind_code='movie'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0100001-0000-0000-0000-000000000002', 'the-matrix', (SELECT kind_id FROM entity_kind WHERE kind_code='movie'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0100001-0000-0000-0000-000000000003', 'the-godfather', (SELECT kind_id FROM entity_kind WHERE kind_code='movie'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0100001-0000-0000-0000-000000000004', 'the-dark-knight', (SELECT kind_id FROM entity_kind WHERE kind_code='movie'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0100001-0000-0000-0000-000000000005', 'inception', (SELECT kind_id FROM entity_kind WHERE kind_code='movie'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 02. actor (5)
-- ═══════════════════════════════════════════════════════════════
('d0200001-0000-0000-0000-000000000001', 'matthew-mcconaughey', (SELECT kind_id FROM entity_kind WHERE kind_code='actor'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0200001-0000-0000-0000-000000000002', 'keanu-reeves', (SELECT kind_id FROM entity_kind WHERE kind_code='actor'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0200001-0000-0000-0000-000000000003', 'marlon-brando', (SELECT kind_id FROM entity_kind WHERE kind_code='actor'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0200001-0000-0000-0000-000000000004', 'christian-bale', (SELECT kind_id FROM entity_kind WHERE kind_code='actor'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0200001-0000-0000-0000-000000000005', 'leonardo-dicaprio', (SELECT kind_id FROM entity_kind WHERE kind_code='actor'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 03. director (5)
-- ═══════════════════════════════════════════════════════════════
('d0300001-0000-0000-0000-000000000001', 'christopher-nolan', (SELECT kind_id FROM entity_kind WHERE kind_code='director'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0300001-0000-0000-0000-000000000002', 'martin-scorsese', (SELECT kind_id FROM entity_kind WHERE kind_code='director'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0300001-0000-0000-0000-000000000003', 'steven-spielberg', (SELECT kind_id FROM entity_kind WHERE kind_code='director'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0300001-0000-0000-0000-000000000004', 'quentin-tarantino', (SELECT kind_id FROM entity_kind WHERE kind_code='director'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0300001-0000-0000-0000-000000000005', 'david-lynch', (SELECT kind_id FROM entity_kind WHERE kind_code='director'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 04. song (5)
-- ═══════════════════════════════════════════════════════════════
('d0400001-0000-0000-0000-000000000001', 'bohemian-rhapsody', (SELECT kind_id FROM entity_kind WHERE kind_code='song'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0400001-0000-0000-0000-000000000002', 'imagine', (SELECT kind_id FROM entity_kind WHERE kind_code='song'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0400001-0000-0000-0000-000000000003', 'hotel-california', (SELECT kind_id FROM entity_kind WHERE kind_code='song'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0400001-0000-0000-0000-000000000004', 'stairway-to-heaven', (SELECT kind_id FROM entity_kind WHERE kind_code='song'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0400001-0000-0000-0000-000000000005', 'yesterday', (SELECT kind_id FROM entity_kind WHERE kind_code='song'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 05. musician (5)
-- ═══════════════════════════════════════════════════════════════
('d0500001-0000-0000-0000-000000000001', 'freddie-mercury', (SELECT kind_id FROM entity_kind WHERE kind_code='musician'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0500001-0000-0000-0000-000000000002', 'john-lennon', (SELECT kind_id FROM entity_kind WHERE kind_code='musician'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0500001-0000-0000-0000-000000000003', 'eric-clapton', (SELECT kind_id FROM entity_kind WHERE kind_code='musician'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0500001-0000-0000-0000-000000000004', 'jimmy-page', (SELECT kind_id FROM entity_kind WHERE kind_code='musician'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0500001-0000-0000-0000-000000000005', 'robert-plant', (SELECT kind_id FROM entity_kind WHERE kind_code='musician'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 06. album (5)
-- ═══════════════════════════════════════════════════════════════
('d0600001-0000-0000-0000-000000000001', 'a-night-at-the-opera', (SELECT kind_id FROM entity_kind WHERE kind_code='album'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0600001-0000-0000-0000-000000000002', 'abbey-road', (SELECT kind_id FROM entity_kind WHERE kind_code='album'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0600001-0000-0000-0000-000000000003', 'the-dark-side-of-the-moon', (SELECT kind_id FROM entity_kind WHERE kind_code='album'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0600001-0000-0000-0000-000000000004', 'thriller', (SELECT kind_id FROM entity_kind WHERE kind_code='album'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0600001-0000-0000-0000-000000000005', 'back-in-black', (SELECT kind_id FROM entity_kind WHERE kind_code='album'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 07. book (5)
-- ═══════════════════════════════════════════════════════════════
('d0700001-0000-0000-0000-000000000001', 'vojna-i-mir', (SELECT kind_id FROM entity_kind WHERE kind_code='book'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0700001-0000-0000-0000-000000000002', '1984', (SELECT kind_id FROM entity_kind WHERE kind_code='book'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0700001-0000-0000-0000-000000000003', 'master-i-margarita', (SELECT kind_id FROM entity_kind WHERE kind_code='book'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0700001-0000-0000-0000-000000000004', 'prestuplenie-i-nakazanie', (SELECT kind_id FROM entity_kind WHERE kind_code='book'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0700001-0000-0000-0000-000000000005', 'harry-potter', (SELECT kind_id FROM entity_kind WHERE kind_code='book'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 08. writer (5)
-- ═══════════════════════════════════════════════════════════════
('d0800001-0000-0000-0000-000000000001', 'lev-tolstoy', (SELECT kind_id FROM entity_kind WHERE kind_code='writer'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0800001-0000-0000-0000-000000000002', 'george-orwell', (SELECT kind_id FROM entity_kind WHERE kind_code='writer'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0800001-0000-0000-0000-000000000003', 'mikhail-bulgakov', (SELECT kind_id FROM entity_kind WHERE kind_code='writer'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0800001-0000-0000-0000-000000000004', 'fyodor-dostoevsky', (SELECT kind_id FROM entity_kind WHERE kind_code='writer'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0800001-0000-0000-0000-000000000005', 'jk-rowling', (SELECT kind_id FROM entity_kind WHERE kind_code='writer'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 09. place (5)
-- ═══════════════════════════════════════════════════════════════
('d0900001-0000-0000-0000-000000000001', 'moscow', (SELECT kind_id FROM entity_kind WHERE kind_code='place'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0900001-0000-0000-0000-000000000002', 'new-york', (SELECT kind_id FROM entity_kind WHERE kind_code='place'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0900001-0000-0000-0000-000000000003', 'london', (SELECT kind_id FROM entity_kind WHERE kind_code='place'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0900001-0000-0000-0000-000000000004', 'tokyo', (SELECT kind_id FROM entity_kind WHERE kind_code='place'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d0900001-0000-0000-0000-000000000005', 'paris', (SELECT kind_id FROM entity_kind WHERE kind_code='place'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 10. chemical_element (5)
-- ═══════════════════════════════════════════════════════════════
('d1000001-0000-0000-0000-000000000001', 'hydrogen', (SELECT kind_id FROM entity_kind WHERE kind_code='chemical_element'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1000001-0000-0000-0000-000000000002', 'oxygen', (SELECT kind_id FROM entity_kind WHERE kind_code='chemical_element'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1000001-0000-0000-0000-000000000003', 'carbon', (SELECT kind_id FROM entity_kind WHERE kind_code='chemical_element'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1000001-0000-0000-0000-000000000004', 'iron', (SELECT kind_id FROM entity_kind WHERE kind_code='chemical_element'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1000001-0000-0000-0000-000000000005', 'gold', (SELECT kind_id FROM entity_kind WHERE kind_code='chemical_element'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 11. animal (5)
-- ═══════════════════════════════════════════════════════════════
('d1100001-0000-0000-0000-000000000001', 'wolf', (SELECT kind_id FROM entity_kind WHERE kind_code='animal'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1100001-0000-0000-0000-000000000002', 'eagle', (SELECT kind_id FROM entity_kind WHERE kind_code='animal'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1100001-0000-0000-0000-000000000003', 'dolphin', (SELECT kind_id FROM entity_kind WHERE kind_code='animal'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1100001-0000-0000-0000-000000000004', 'lion', (SELECT kind_id FROM entity_kind WHERE kind_code='animal'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1100001-0000-0000-0000-000000000005', 'bear', (SELECT kind_id FROM entity_kind WHERE kind_code='animal'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 12. plant (5)
-- ═══════════════════════════════════════════════════════════════
('d1200001-0000-0000-0000-000000000001', 'oak', (SELECT kind_id FROM entity_kind WHERE kind_code='plant'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1200001-0000-0000-0000-000000000002', 'birch', (SELECT kind_id FROM entity_kind WHERE kind_code='plant'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1200001-0000-0000-0000-000000000003', 'cactus', (SELECT kind_id FROM entity_kind WHERE kind_code='plant'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1200001-0000-0000-0000-000000000004', 'wheat', (SELECT kind_id FROM entity_kind WHERE kind_code='plant'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1200001-0000-0000-0000-000000000005', 'rice', (SELECT kind_id FROM entity_kind WHERE kind_code='plant'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 13. concept (5)
-- ═══════════════════════════════════════════════════════════════
('d1300001-0000-0000-0000-000000000001', 'democracy', (SELECT kind_id FROM entity_kind WHERE kind_code='concept'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1300001-0000-0000-0000-000000000002', 'cyberpunk', (SELECT kind_id FROM entity_kind WHERE kind_code='concept'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1300001-0000-0000-0000-000000000003', 'artificial-intelligence', (SELECT kind_id FROM entity_kind WHERE kind_code='concept'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1300001-0000-0000-0000-000000000004', 'freedom', (SELECT kind_id FROM entity_kind WHERE kind_code='concept'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1300001-0000-0000-0000-000000000005', 'justice', (SELECT kind_id FROM entity_kind WHERE kind_code='concept'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 14. genre (5)
-- ═══════════════════════════════════════════════════════════════
('d1400001-0000-0000-0000-000000000001', 'sci-fi', (SELECT kind_id FROM entity_kind WHERE kind_code='genre'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1400001-0000-0000-0000-000000000002', 'classical-music', (SELECT kind_id FROM entity_kind WHERE kind_code='genre'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1400001-0000-0000-0000-000000000003', 'rock', (SELECT kind_id FROM entity_kind WHERE kind_code='genre'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1400001-0000-0000-0000-000000000004', 'jazz', (SELECT kind_id FROM entity_kind WHERE kind_code='genre'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1400001-0000-0000-0000-000000000005', 'pop', (SELECT kind_id FROM entity_kind WHERE kind_code='genre'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 15. phenomenon (5)
-- ═══════════════════════════════════════════════════════════════
('d1500001-0000-0000-0000-000000000001', 'gravity', (SELECT kind_id FROM entity_kind WHERE kind_code='phenomenon'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1500001-0000-0000-0000-000000000002', 'photosynthesis', (SELECT kind_id FROM entity_kind WHERE kind_code='phenomenon'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1500001-0000-0000-0000-000000000003', 'magnetic-field', (SELECT kind_id FROM entity_kind WHERE kind_code='phenomenon'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1500001-0000-0000-0000-000000000004', 'evolution', (SELECT kind_id FROM entity_kind WHERE kind_code='phenomenon'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1500001-0000-0000-0000-000000000005', 'quantum-superposition', (SELECT kind_id FROM entity_kind WHERE kind_code='phenomenon'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 16. period (5)
-- ═══════════════════════════════════════════════════════════════
('d1600001-0000-0000-0000-000000000001', 'middle-ages', (SELECT kind_id FROM entity_kind WHERE kind_code='period'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1600001-0000-0000-0000-000000000002', 'renaissance', (SELECT kind_id FROM entity_kind WHERE kind_code='period'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1600001-0000-0000-0000-000000000003', 'enlightenment', (SELECT kind_id FROM entity_kind WHERE kind_code='period'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1600001-0000-0000-0000-000000000004', 'industrial-revolution', (SELECT kind_id FROM entity_kind WHERE kind_code='period'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1600001-0000-0000-0000-000000000005', 'digital-era', (SELECT kind_id FROM entity_kind WHERE kind_code='period'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 17. digital_file (5)
-- ═══════════════════════════════════════════════════════════════
('d1700001-0000-0000-0000-000000000001', 'main-py', (SELECT kind_id FROM entity_kind WHERE kind_code='digital_file'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1700001-0000-0000-0000-000000000002', 'init-sql', (SELECT kind_id FROM entity_kind WHERE kind_code='digital_file'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1700001-0000-0000-0000-000000000003', 'readme-md', (SELECT kind_id FROM entity_kind WHERE kind_code='digital_file'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1700001-0000-0000-0000-000000000004', 'config-json', (SELECT kind_id FROM entity_kind WHERE kind_code='digital_file'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1700001-0000-0000-0000-000000000005', 'dockerfile', (SELECT kind_id FROM entity_kind WHERE kind_code='digital_file'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 18. movement (5)
-- ═══════════════════════════════════════════════════════════════
('d1800001-0000-0000-0000-000000000001', 'modernism', (SELECT kind_id FROM entity_kind WHERE kind_code='movement'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1800001-0000-0000-0000-000000000002', 'postmodernism', (SELECT kind_id FROM entity_kind WHERE kind_code='movement'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1800001-0000-0000-0000-000000000003', 'avant-garde', (SELECT kind_id FROM entity_kind WHERE kind_code='movement'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1800001-0000-0000-0000-000000000004', 'romanticism', (SELECT kind_id FROM entity_kind WHERE kind_code='movement'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1800001-0000-0000-0000-000000000005', 'realism', (SELECT kind_id FROM entity_kind WHERE kind_code='movement'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 19. classifier (5)
-- ═══════════════════════════════════════════════════════════════
('d1900001-0000-0000-0000-000000000001', 'dewey-decimal', (SELECT kind_id FROM entity_kind WHERE kind_code='classifier'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1900001-0000-0000-0000-000000000002', 'periodic-table', (SELECT kind_id FROM entity_kind WHERE kind_code='classifier'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1900001-0000-0000-0000-000000000003', 'iso-3166', (SELECT kind_id FROM entity_kind WHERE kind_code='classifier'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1900001-0000-0000-0000-000000000004', 'rfc-2119', (SELECT kind_id FROM entity_kind WHERE kind_code='classifier'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d1900001-0000-0000-0000-000000000005', 'bcp-47', (SELECT kind_id FROM entity_kind WHERE kind_code='classifier'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 20. physical_item (5)
-- ═══════════════════════════════════════════════════════════════
('d2000001-0000-0000-0000-000000000001', 'desk', (SELECT kind_id FROM entity_kind WHERE kind_code='physical_item'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2000001-0000-0000-0000-000000000002', 'chair', (SELECT kind_id FROM entity_kind WHERE kind_code='physical_item'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2000001-0000-0000-0000-000000000003', 'computer', (SELECT kind_id FROM entity_kind WHERE kind_code='physical_item'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2000001-0000-0000-0000-000000000004', 'notebook', (SELECT kind_id FROM entity_kind WHERE kind_code='physical_item'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2000001-0000-0000-0000-000000000005', 'pen', (SELECT kind_id FROM entity_kind WHERE kind_code='physical_item'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 21. photo (5)
-- ═══════════════════════════════════════════════════════════════
('d2100001-0000-0000-0000-000000000001', 'portrait-photo', (SELECT kind_id FROM entity_kind WHERE kind_code='photo'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2100001-0000-0000-0000-000000000002', 'landscape-photo', (SELECT kind_id FROM entity_kind WHERE kind_code='photo'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2100001-0000-0000-0000-000000000003', 'macro-photo', (SELECT kind_id FROM entity_kind WHERE kind_code='photo'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2100001-0000-0000-0000-000000000004', 'night-city', (SELECT kind_id FROM entity_kind WHERE kind_code='photo'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2100001-0000-0000-0000-000000000005', 'mountains', (SELECT kind_id FROM entity_kind WHERE kind_code='photo'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 22. article (5)
-- ═══════════════════════════════════════════════════════════════
('d2200001-0000-0000-0000-000000000001', 'scientific-paper', (SELECT kind_id FROM entity_kind WHERE kind_code='article'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2200001-0000-0000-0000-000000000002', 'news-article', (SELECT kind_id FROM entity_kind WHERE kind_code='article'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2200001-0000-0000-0000-000000000003', 'review-article', (SELECT kind_id FROM entity_kind WHERE kind_code='article'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2200001-0000-0000-0000-000000000004', 'essay', (SELECT kind_id FROM entity_kind WHERE kind_code='article'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2200001-0000-0000-0000-000000000005', 'interview', (SELECT kind_id FROM entity_kind WHERE kind_code='article'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 23. human (5)
-- ═══════════════════════════════════════════════════════════════
('d2300001-0000-0000-0000-000000000001', 'albert-einstein', (SELECT kind_id FROM entity_kind WHERE kind_code='human'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2300001-0000-0000-0000-000000000002', 'marie-curie', (SELECT kind_id FROM entity_kind WHERE kind_code='human'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2300001-0000-0000-0000-000000000003', 'nikola-tesla', (SELECT kind_id FROM entity_kind WHERE kind_code='human'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2300001-0000-0000-0000-000000000004', 'leonardo-da-vinci', (SELECT kind_id FROM entity_kind WHERE kind_code='human'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2300001-0000-0000-0000-000000000005', 'charles-darwin', (SELECT kind_id FROM entity_kind WHERE kind_code='human'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 24. artist (5)
-- ═══════════════════════════════════════════════════════════════
('d2400001-0000-0000-0000-000000000001', 'picasso', (SELECT kind_id FROM entity_kind WHERE kind_code='artist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2400001-0000-0000-0000-000000000002', 'van-gogh', (SELECT kind_id FROM entity_kind WHERE kind_code='artist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2400001-0000-0000-0000-000000000003', 'monet', (SELECT kind_id FROM entity_kind WHERE kind_code='artist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2400001-0000-0000-0000-000000000004', 'dali', (SELECT kind_id FROM entity_kind WHERE kind_code='artist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2400001-0000-0000-0000-000000000005', 'malevich', (SELECT kind_id FROM entity_kind WHERE kind_code='artist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 25. scientist (5)
-- ═══════════════════════════════════════════════════════════════
('d2500001-0000-0000-0000-000000000001', 'isaac-newton', (SELECT kind_id FROM entity_kind WHERE kind_code='scientist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2500001-0000-0000-0000-000000000002', 'richard-feynman', (SELECT kind_id FROM entity_kind WHERE kind_code='scientist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2500001-0000-0000-0000-000000000003', 'stephen-hawking', (SELECT kind_id FROM entity_kind WHERE kind_code='scientist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2500001-0000-0000-0000-000000000004', 'niels-bohr', (SELECT kind_id FROM entity_kind WHERE kind_code='scientist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2500001-0000-0000-0000-000000000005', 'max-planck', (SELECT kind_id FROM entity_kind WHERE kind_code='scientist'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 26. organization (5)
-- ═══════════════════════════════════════════════════════════════
('d2600001-0000-0000-0000-000000000001', 'google', (SELECT kind_id FROM entity_kind WHERE kind_code='organization'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2600001-0000-0000-0000-000000000002', 'apple', (SELECT kind_id FROM entity_kind WHERE kind_code='organization'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2600001-0000-0000-0000-000000000003', 'wikipedia', (SELECT kind_id FROM entity_kind WHERE kind_code='organization'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2600001-0000-0000-0000-000000000004', 'un', (SELECT kind_id FROM entity_kind WHERE kind_code='organization'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2600001-0000-0000-0000-000000000005', 'microsoft', (SELECT kind_id FROM entity_kind WHERE kind_code='organization'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 27. event (5)
-- ═══════════════════════════════════════════════════════════════
('d2700001-0000-0000-0000-000000000001', 'olympics-2024', (SELECT kind_id FROM entity_kind WHERE kind_code='event'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2700001-0000-0000-0000-000000000002', 'cannes-festival', (SELECT kind_id FROM entity_kind WHERE kind_code='event'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2700001-0000-0000-0000-000000000003', 'ces-2025', (SELECT kind_id FROM entity_kind WHERE kind_code='event'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2700001-0000-0000-0000-000000000004', 'wwdc', (SELECT kind_id FROM entity_kind WHERE kind_code='event'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2700001-0000-0000-0000-000000000005', 'world-war-2', (SELECT kind_id FROM entity_kind WHERE kind_code='event'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 28. award (5)
-- ═══════════════════════════════════════════════════════════════
('d2800001-0000-0000-0000-000000000001', 'oscar', (SELECT kind_id FROM entity_kind WHERE kind_code='award'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2800001-0000-0000-0000-000000000002', 'grammy', (SELECT kind_id FROM entity_kind WHERE kind_code='award'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2800001-0000-0000-0000-000000000003', 'nobel-prize', (SELECT kind_id FROM entity_kind WHERE kind_code='award'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2800001-0000-0000-0000-000000000004', 'pulitzer', (SELECT kind_id FROM entity_kind WHERE kind_code='award'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2800001-0000-0000-0000-000000000005', 'tony-award', (SELECT kind_id FROM entity_kind WHERE kind_code='award'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 29. collection (5)
-- ═══════════════════════════════════════════════════════════════
('d2900001-0000-0000-0000-000000000001', 'hermitage', (SELECT kind_id FROM entity_kind WHERE kind_code='collection'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2900001-0000-0000-0000-000000000002', 'louvre', (SELECT kind_id FROM entity_kind WHERE kind_code='collection'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2900001-0000-0000-0000-000000000003', 'met-museum', (SELECT kind_id FROM entity_kind WHERE kind_code='collection'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2900001-0000-0000-0000-000000000004', 'tretyakov-gallery', (SELECT kind_id FROM entity_kind WHERE kind_code='collection'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d2900001-0000-0000-0000-000000000005', 'british-museum', (SELECT kind_id FROM entity_kind WHERE kind_code='collection'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 30. tag (5)
-- ═══════════════════════════════════════════════════════════════
('d3000001-0000-0000-0000-000000000001', 'tag-sci-fi', (SELECT kind_id FROM entity_kind WHERE kind_code='tag'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3000001-0000-0000-0000-000000000002', 'tag-classic', (SELECT kind_id FROM entity_kind WHERE kind_code='tag'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3000001-0000-0000-0000-000000000003', 'tag-bestseller', (SELECT kind_id FROM entity_kind WHERE kind_code='tag'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3000001-0000-0000-0000-000000000004', 'tag-award-winning', (SELECT kind_id FROM entity_kind WHERE kind_code='tag'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3000001-0000-0000-0000-000000000005', 'tag-cult', (SELECT kind_id FROM entity_kind WHERE kind_code='tag'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 31. language_entity (5)
-- ═══════════════════════════════════════════════════════════════
('d3100001-0000-0000-0000-000000000001', 'python-lang', (SELECT kind_id FROM entity_kind WHERE kind_code='language_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3100001-0000-0000-0000-000000000002', 'javascript-lang', (SELECT kind_id FROM entity_kind WHERE kind_code='language_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3100001-0000-0000-0000-000000000003', 'sql-lang', (SELECT kind_id FROM entity_kind WHERE kind_code='language_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3100001-0000-0000-0000-000000000004', 'html-lang', (SELECT kind_id FROM entity_kind WHERE kind_code='language_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3100001-0000-0000-0000-000000000005', 'css-lang', (SELECT kind_id FROM entity_kind WHERE kind_code='language_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 32. currency (5)
-- ═══════════════════════════════════════════════════════════════
('d3200001-0000-0000-0000-000000000001', 'us-dollar', (SELECT kind_id FROM entity_kind WHERE kind_code='currency'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3200001-0000-0000-0000-000000000002', 'euro', (SELECT kind_id FROM entity_kind WHERE kind_code='currency'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3200001-0000-0000-0000-000000000003', 'ruble', (SELECT kind_id FROM entity_kind WHERE kind_code='currency'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3200001-0000-0000-0000-000000000004', 'yen', (SELECT kind_id FROM entity_kind WHERE kind_code='currency'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3200001-0000-0000-0000-000000000005', 'pound-sterling', (SELECT kind_id FROM entity_kind WHERE kind_code='currency'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 33. unit (5)
-- ═══════════════════════════════════════════════════════════════
('d3300001-0000-0000-0000-000000000001', 'meter', (SELECT kind_id FROM entity_kind WHERE kind_code='unit'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3300001-0000-0000-0000-000000000002', 'kilogram', (SELECT kind_id FROM entity_kind WHERE kind_code='unit'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3300001-0000-0000-0000-000000000003', 'second', (SELECT kind_id FROM entity_kind WHERE kind_code='unit'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3300001-0000-0000-0000-000000000004', 'ampere', (SELECT kind_id FROM entity_kind WHERE kind_code='unit'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3300001-0000-0000-0000-000000000005', 'kelvin', (SELECT kind_id FROM entity_kind WHERE kind_code='unit'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 34. formula (5)
-- ═══════════════════════════════════════════════════════════════
('d3400001-0000-0000-0000-000000000001', 'emc2', (SELECT kind_id FROM entity_kind WHERE kind_code='formula'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3400001-0000-0000-0000-000000000002', 'fma', (SELECT kind_id FROM entity_kind WHERE kind_code='formula'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3400001-0000-0000-0000-000000000003', 'pvnrt', (SELECT kind_id FROM entity_kind WHERE kind_code='formula'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3400001-0000-0000-0000-000000000004', 'ehv', (SELECT kind_id FROM entity_kind WHERE kind_code='formula'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3400001-0000-0000-0000-000000000005', 'vir', (SELECT kind_id FROM entity_kind WHERE kind_code='formula'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 35. theorem (5)
-- ═══════════════════════════════════════════════════════════════
('d3500001-0000-0000-0000-000000000001', 'pythagorean-theorem', (SELECT kind_id FROM entity_kind WHERE kind_code='theorem'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3500001-0000-0000-0000-000000000002', 'euler-theorem', (SELECT kind_id FROM entity_kind WHERE kind_code='theorem'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3500001-0000-0000-0000-000000000003', 'godel-theorem', (SELECT kind_id FROM entity_kind WHERE kind_code='theorem'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3500001-0000-0000-0000-000000000004', 'cantor-theorem', (SELECT kind_id FROM entity_kind WHERE kind_code='theorem'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3500001-0000-0000-0000-000000000005', 'bayes-theorem', (SELECT kind_id FROM entity_kind WHERE kind_code='theorem'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 36. software (5)
-- ═══════════════════════════════════════════════════════════════
('d3600001-0000-0000-0000-000000000001', 'python-sw', (SELECT kind_id FROM entity_kind WHERE kind_code='software'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3600001-0000-0000-0000-000000000002', 'postgresql-sw', (SELECT kind_id FROM entity_kind WHERE kind_code='software'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3600001-0000-0000-0000-000000000003', 'docker-sw', (SELECT kind_id FROM entity_kind WHERE kind_code='software'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3600001-0000-0000-0000-000000000004', 'vscode-sw', (SELECT kind_id FROM entity_kind WHERE kind_code='software'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3600001-0000-0000-0000-000000000005', 'git-sw', (SELECT kind_id FROM entity_kind WHERE kind_code='software'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 37. game (5)
-- ═══════════════════════════════════════════════════════════════
('d3700001-0000-0000-0000-000000000001', 'the-witcher', (SELECT kind_id FROM entity_kind WHERE kind_code='game'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3700001-0000-0000-0000-000000000002', 'minecraft', (SELECT kind_id FROM entity_kind WHERE kind_code='game'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3700001-0000-0000-0000-000000000003', 'tetris', (SELECT kind_id FROM entity_kind WHERE kind_code='game'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3700001-0000-0000-0000-000000000004', 'cyberpunk-2077', (SELECT kind_id FROM entity_kind WHERE kind_code='game'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3700001-0000-0000-0000-000000000005', 'half-life', (SELECT kind_id FROM entity_kind WHERE kind_code='game'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 38. podcast (5)
-- ═══════════════════════════════════════════════════════════════
('d3800001-0000-0000-0000-000000000001', 'software-engineering-daily', (SELECT kind_id FROM entity_kind WHERE kind_code='podcast'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3800001-0000-0000-0000-000000000002', 'lex-fridman-podcast', (SELECT kind_id FROM entity_kind WHERE kind_code='podcast'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3800001-0000-0000-0000-000000000003', 'joe-rogan-experience', (SELECT kind_id FROM entity_kind WHERE kind_code='podcast'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3800001-0000-0000-0000-000000000004', 'hardcore-history', (SELECT kind_id FROM entity_kind WHERE kind_code='podcast'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3800001-0000-0000-0000-000000000005', 'freakonomics', (SELECT kind_id FROM entity_kind WHERE kind_code='podcast'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 39. channel (5)
-- ═══════════════════════════════════════════════════════════════
('d3900001-0000-0000-0000-000000000001', 'veritasium', (SELECT kind_id FROM entity_kind WHERE kind_code='channel'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3900001-0000-0000-0000-000000000002', 'numberphile', (SELECT kind_id FROM entity_kind WHERE kind_code='channel'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3900001-0000-0000-0000-000000000003', '3blue1brown', (SELECT kind_id FROM entity_kind WHERE kind_code='channel'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3900001-0000-0000-0000-000000000004', 'kurzgesagt', (SELECT kind_id FROM entity_kind WHERE kind_code='channel'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d3900001-0000-0000-0000-000000000005', 'smartereveryday', (SELECT kind_id FROM entity_kind WHERE kind_code='channel'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),

-- ═══════════════════════════════════════════════════════════════
-- 40. label_entity (5)
-- ═══════════════════════════════════════════════════════════════
('d4000001-0000-0000-0000-000000000001', 'sony-music', (SELECT kind_id FROM entity_kind WHERE kind_code='label_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d4000001-0000-0000-0000-000000000002', 'universal-music', (SELECT kind_id FROM entity_kind WHERE kind_code='label_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d4000001-0000-0000-0000-000000000003', 'warner-music', (SELECT kind_id FROM entity_kind WHERE kind_code='label_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d4000001-0000-0000-0000-000000000004', 'def-jam', (SELECT kind_id FROM entity_kind WHERE kind_code='label_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1),
('d4000001-0000-0000-0000-000000000005', 'sub-pop', (SELECT kind_id FROM entity_kind WHERE kind_code='label_entity'), 'active', (SELECT source_id FROM source_system WHERE source_code='manual'), NULL, 1);
