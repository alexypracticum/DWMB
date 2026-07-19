-- =============================================================================
--  META-SYSTEM: Semantic Relations (связи между сущностями)
--  Дата: 2026-07-18
-- =============================================================================

SET search_path TO meta;

INSERT INTO semantic_relation (source_projection_id, relation_type_id, target_projection_id, confidence, version_id) VALUES
-- ═══════════════════════════════════════════════════════════════
-- MOVIE → ACTOR/DIRECTOR
-- ═══════════════════════════════════════════════════════════════
-- Interstellar → McConaughey (acted_in)
('p0100001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'p0200001-0000-0000-0000-000000000001', 0.99, 1),
-- Interstellar → Nolan (directed_by)
('p0100001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='directed_by'), 'p0300001-0000-0000-0000-000000000001', 0.99, 1),
-- The Matrix → Reeves (acted_in)
('p0100001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'p0200001-0000-0000-0000-000000000002', 0.99, 1),
-- The Godfather → Brando (acted_in)
('p0100001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'p0200001-0000-0000-0000-000000000003', 0.99, 1),
-- The Dark Knight → Bale (acted_in)
('p0100001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'p0200001-0000-0000-0000-000000000004', 0.99, 1),
-- The Dark Knight → Nolan (directed_by)
('p0100001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='directed_by'), 'p0300001-0000-0000-0000-000000000001', 0.99, 1),
-- Inception → DiCaprio (acted_in)
('p0100001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='acted_in'), 'p0200001-0000-0000-0000-000000000005', 0.99, 1),
-- Inception → Nolan (directed_by)
('p0100001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='directed_by'), 'p0300001-0000-0000-0000-000000000001', 0.99, 1),

-- ═══════════════════════════════════════════════════════════════
-- MOVIE → GENRE
-- ═══════════════════════════════════════════════════════════════
('p0100001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'p1400001-0000-0000-0000-000000000001', 0.95, 1),
('p0100001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'p1400001-0000-0000-0000-000000000001', 0.95, 1),
('p0100001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'p1400001-0000-0000-0000-000000000001', 0.90, 1),

-- ═══════════════════════════════════════════════════════════════
-- SONG → MUSICIAN/ALBUM
-- ═══════════════════════════════════════════════════════════════
-- Bohemian Rhapsody → Mercury (composed_by)
('p0400001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'p0500001-0000-0000-0000-000000000001', 0.98, 1),
-- Bohemian Rhapsody → Night at Opera (part_of)
('p0400001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='part_of'), 'p0600001-0000-0000-0000-000000000001', 0.99, 1),
-- Imagine → Lennon (composed_by)
('p0400001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'p0500001-0000-0000-0000-000000000002', 0.99, 1),
-- Hotel California → Eagles band (performed_in)
('p0400001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='performed_in'), 'p0600001-0000-0000-0000-000000000002', 0.95, 1),
-- Stairway to Heaven → Page (composed_by)
('p0400001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'p0500001-0000-0000-0000-000000000004', 0.95, 1),
-- Stairway to Heaven → Plant (composed_by)
('p0400001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'p0500001-0000-0000-0000-000000000005', 0.95, 1),
-- Yesterday → Lennon (composed_by)
('p0400001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='composed_by'), 'p0500001-0000-0000-0000-000000000002', 0.98, 1),

-- ═══════════════════════════════════════════════════════════════
-- SONG → GENRE
-- ═══════════════════════════════════════════════════════════════
('p0400001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'p1400001-0000-0000-0000-000000000003', 0.95, 1),
('p0400001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_genre'), 'p1400001-0000-0000-0000-000000000003', 0.95, 1),

-- ═══════════════════════════════════════════════════════════════
-- BOOK → WRITER
-- ═══════════════════════════════════════════════════════════════
('p0700001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'p0800001-0000-0000-0000-000000000001', 0.99, 1),
('p0700001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'p0800001-0000-0000-0000-000000000002', 0.99, 1),
('p0700001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'p0800001-0000-0000-0000-000000000003', 0.99, 1),
('p0700001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'p0800001-0000-0000-0000-000000000004', 0.99, 1),
('p0700001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='wrote'), 'p0800001-0000-0000-0000-000000000005', 0.99, 1),

-- ═══════════════════════════════════════════════════════════════
-- HUMAN → PLACE (born_in)
-- ═══════════════════════════════════════════════════════════════
('p2300001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='born_in'), 'p0900001-0000-0000-0000-000000000005', 0.85, 1), -- Einstein born near Ulm → Paris approximation
('p2300001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='born_in'), 'p0900001-0000-0000-0000-000000000005', 0.80, 1), -- Da Vinci born in Italy → Paris approximation

-- ═══════════════════════════════════════════════════════════════
-- MOVIE → TAG
-- ═══════════════════════════════════════════════════════════════
('p0100001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000001', 0.90, 1), -- Matrix → sci-fi
('p0100001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000002', 0.95, 1), -- Godfather → classic
('p0100001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000005', 0.90, 1), -- Godfather → cult
('p0700001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000002', 0.95, 1), -- 1984 → classic
('p0700001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000003', 0.90, 1), -- Harry Potter → bestseller

-- ═══════════════════════════════════════════════════════════════
-- SCIENTIST → FORMULA/THEOREM
-- ═══════════════════════════════════════════════════════════════
('p3400001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='references'), 'p2300001-0000-0000-0000-000000000001', 0.99, 1), -- E=mc² → Einstein
('p3500001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='references'), 'p2500001-0000-0000-0000-000000000001', 0.95, 1), -- Pythagoras theorem → Newton (influence)

-- ═══════════════════════════════════════════════════════════════
-- SOFTWARE → LANGUAGE
-- ═══════════════════════════════════════════════════════════════
('p3600001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='references'), 'p3100001-0000-0000-0000-000000000001', 0.95, 1), -- Python SW → Python lang

-- ═══════════════════════════════════════════════════════════════
-- GAME → TAG
-- ═══════════════════════════════════════════════════════════════
('p3700001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000002', 0.85, 1), -- Tetris → classic
('p3700001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000005', 0.90, 1), -- Half-Life → cult

-- ═══════════════════════════════════════════════════════════════
-- COLLECTION → PLACE (located_in)
-- ═══════════════════════════════════════════════════════════════
('p2900001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='located_in'), 'p0900001-0000-0000-0000-000000000001', 0.99, 1), -- Hermitage → Moscow approximation
('p2900001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='located_in'), 'p0900001-0000-0000-0000-000000000005', 0.99, 1), -- Louvre → Paris
('p2900001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='located_in'), 'p0900001-0000-0000-0000-000000000002', 0.99, 1), -- Met → New York
('p2900001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='located_in'), 'p0900001-0000-0000-0000-000000000003', 0.99, 1), -- British Museum → London

-- ═══════════════════════════════════════════════════════════════
-- AWARD → MOVIE (won_award)
-- ═══════════════════════════════════════════════════════════════
('p0100001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='won_award'), 'p2800001-0000-0000-0000-000000000001', 0.99, 1), -- Godfather → Oscar

-- ═══════════════════════════════════════════════════════════════
-- PERIOD → CONCEPT (related_to)
-- ═══════════════════════════════════════════════════════════════
('p1600001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p1300001-0000-0000-0000-000000000003', 0.80, 1), -- Digital Era → AI

-- ═══════════════════════════════════════════════════════════════
-- MOVIE → MOVIE (similar_to, sequel_of)
-- ═══════════════════════════════════════════════════════════════
('p0100001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='similar_to'), 'p0100001-0000-0000-0000-000000000005', 0.75, 1), -- Matrix similar to Inception

-- ═══════════════════════════════════════════════════════════════
-- SONG → TAG (covers)
-- ═══════════════════════════════════════════════════════════════
('p0400001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000002', 0.85, 1), -- Imagine → classic

-- ═══════════════════════════════════════════════════════════════
-- PLACE → TAG (located_in for regions)
-- ═══════════════════════════════════════════════════════════════
('p0900001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='similar_to'), 'p0900001-0000-0000-0000-000000000001', 0.60, 1), -- Tokyo similar to Moscow (capitals)

-- ═══════════════════════════════════════════════════════════════
-- ORGANIZATION → PLACE (located_in)
-- ═══════════════════════════════════════════════════════════════
('p2600001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='located_in'), 'p0900001-0000-0000-0000-000000000002', 0.95, 1), -- Google → New York approximation
('p2600001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='located_in'), 'p0900001-0000-0000-0000-000000000002', 0.99, 1), -- UN → New York

-- ═══════════════════════════════════════════════════════════════
-- SCIENTIST → FORMULA (developed)
-- ═══════════════════════════════════════════════════════════════
('p3400001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='references'), 'p2500001-0000-0000-0000-000000000001', 0.99, 1), -- F=ma → Newton
('p3400001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='references'), 'p2500001-0000-0000-0000-000000000001', 0.90, 1), -- V=IR → Newton influence

-- ═══════════════════════════════════════════════════════════════
-- ALBUM → TAG
-- ═══════════════════════════════════════════════════════════════
('p0600001-0000-0000-0000-000000000002', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000002', 0.95, 1), -- Abbey Road → classic
('p0600001-0000-0000-0000-000000000003', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000005', 0.90, 1), -- Dark Side → cult
('p0600001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000004', 0.95, 1), -- Thriller → award-winning
('p0600001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000003', 0.90, 1), -- Thriller → bestseller

-- ═══════════════════════════════════════════════════════════════
-- MOVIE → AWARD (nominated_for)
-- ═══════════════════════════════════════════════════════════════
('p0100001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='nominated_for'), 'p2800001-0000-0000-0000-000000000001', 0.90, 1), -- Interstellar → Oscar
('p0100001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='won_award'), 'p2800001-0000-0000-0000-000000000001', 0.99, 1), -- Dark Knight → Oscar

-- ═══════════════════════════════════════════════════════════════
-- CHANNEL → TAG
-- ═══════════════════════════════════════════════════════════════
('p3900001-0000-0000-0000-000000000001', (SELECT relation_type_id FROM relation_type WHERE relation_code='has_theme'), 'p3000001-0000-0000-0000-000000000001', 0.80, 1), -- Veritasium → sci-fi (science)

-- ═══════════════════════════════════════════════════════════════
-- MOVEMENT → PERIOD (related_to)
-- ═══════════════════════════════════════════════════════════════
('p1800001-0000-0000-0000-000000000004', (SELECT relation_type_id FROM relation_type WHERE relation_code='related_to'), 'p1600001-0000-0000-0000-000000000003', 0.85, 1), -- Romanticism → Enlightenment

-- ═══════════════════════════════════════════════════════════════
-- ARTIST → COLLECTION (part_of)
-- ═══════════════════════════════════════════════════════════════
('p2400001-0000-0000-0000-000000000005', (SELECT relation_type_id FROM relation_type WHERE relation_code='part_of'), 'p2900001-0000-0000-0000-000000000001', 0.85, 1), -- Malevich → Hermitage
