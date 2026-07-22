---
type: database
title: "Семантические связи"
description: "Графовая модель связей между сущностями: semantic_relation, relation_type, графовые операции"
tags: [database, relations, graph, semantic]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 17.07.2026.ПРОМПТ создания БД.md
  - 28.06.2026 OpenCode Полный анализ
status: stable
---

# Семантические связи

Графовая модель для навигации по связям между сущностями в [[architecture/overview|DWMB]].

## semantic_relation

```sql
CREATE TABLE semantic_relation (
    relation_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_projection_id  UUID NOT NULL REFERENCES entity_projection(projection_id),
    target_projection_id  UUID NOT NULL REFERENCES entity_projection(projection_id),
    relation_type_id      UUID NOT NULL REFERENCES relation_type(relation_type_id),
    confidence            NUMERIC(5,4) DEFAULT 1.0,
    metadata              JSONB DEFAULT '{}'::jsonb,
    created_at            TIMESTAMPTZ DEFAULT now()
);
```

### Ключевые особенности

- Связи идут через **проекции**, а не напрямую через сущности
- Связь всегда реализуется через призму конкретной [[philosophy/world-models|модели мира]]
- `confidence` определяет достоверность связи
- `metadata` хранит дополнительную информацию

## relation_type

```sql
CREATE TABLE relation_type (
    relation_type_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    relation_code     TEXT NOT NULL UNIQUE,
    relation_name     TEXT NOT NULL,
    description       TEXT,
    is_bidirectional  BOOLEAN DEFAULT false,
    created_at        TIMESTAMPTZ DEFAULT now()
);
```

### Типы связей

| Код | Описание | Направление |
|-----|----------|-------------|
| performed_by | Исполнено | directed |
| directed_by | Снял | directed |
| written_by | Написал | directed |
| composed_by | Композитор | directed |
| part_of | Часть | directed |
| related_to | Связано | bidirectional |
| same_as | То же самое | bidirectional |
| located_in | Находится в | directed |
| born_in | Родился в | directed |
| member_of | Член | directed |

## Графовые операции

### Поиск соседей

Все песни указанного исполнителя:

```sql
SELECT e.*
FROM semantic_relation sr
JOIN entity_projection ep ON sr.target_projection_id = ep.projection_id
JOIN entity e ON ep.entity_id = e.entity_id
WHERE sr.source_projection_id = (
    SELECT projection_id FROM entity_projection
    WHERE entity_id = :artist_id AND model_code = 'music'
)
AND sr.relation_type_id = (
    SELECT relation_type_id FROM relation_type
    WHERE relation_code = 'performed_by'
);
```

### Поиск пути

Кто написал музыку к фильму, который снял режиссёр:

```sql
WITH RECURSIVE path AS (
    SELECT source_projection_id, target_projection_id, 1 AS depth,
           ARRAY[source_projection_id, target_projection_id] AS visited
    FROM semantic_relation WHERE source_projection_id = :start_id
    UNION ALL
    SELECT sr.source_projection_id, sr.target_projection_id, p.depth + 1,
           p.visited || sr.target_projection_id
    FROM semantic_relation sr
    JOIN path p ON sr.source_projection_id = p.target_projection_id
    WHERE p.depth < 5 AND sr.target_projection_id <> ALL(p.visited)
)
SELECT * FROM path WHERE target_projection_id = :end_id;
```

### Графовое исследование

Интерактивное исследование связей (D3.js / Cytoscape.js):

**Статус:** не реализовано
- Связи отображаются списком на странице сущности
- Нет графового представления
- Нет визуализации графа
- Нет фильтрации по типам связей

## Проблемы

### 1. Связи только через проекции
Нет уровня entity-level relations. Связи всегда привязаны к конкретной модели мира.

### 2. Отсутствие визуализации
Нет графового интерфейса для навигации по связям.

### 3. Производительность
Рекурсивные запросы (CTE) могут быть медленными при большом количестве связей.

## Связанные страницы

- [[philosophy/world-models]] — Модели мира
- [[database/entity-model]] — Модель сущностей
- [[database/projections]] — Проекции сущностей
- [[architecture/layers]] — Архитектурные слои (Relation layer)
- [[api/rest-api]] — API для работы со связями
