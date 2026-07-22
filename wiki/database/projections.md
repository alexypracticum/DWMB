---
type: database
title: "Проекции сущностей"
description: "entity_projection и projection_state — представление сущностей в моделях мира"
tags: [database, projection, entity, state]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 17.07.2026.ПРОМПТ создания БД.md
  - 28.06.2026 OpenCode Полный анализ
status: stable
---

# Проекции сущностей

**Проекция** (entity_projection) — представление [[database/entity-model|сущности]] в конкретной [[philosophy/world-models|модели мира]].

## entity_projection

```sql
CREATE TABLE entity_projection (
    projection_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID NOT NULL REFERENCES entity(entity_id),
    model_id        UUID NOT NULL REFERENCES ontology_model(model_id),
    context_id      UUID REFERENCES context(context_id),
    confidence      NUMERIC(5,4) DEFAULT 1.0,
    is_current      BOOLEAN DEFAULT true,
    valid_from      TIMESTAMPTZ DEFAULT now(),
    valid_to        TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT now()
);
```

### Поля

| Поле | Описание |
|------|----------|
| projection_id | UUID, первичный ключ |
| entity_id | Ссылка на сущность |
| model_id | Ссылка на модель мира |
| context_id | Ссылка на контекст |
| confidence | Достоверность данных (0.0 - 1.0) |
| is_current | Текущая ли проекция |
| valid_from | Начало временнóго диапазона |
| valid_to | Конец временнóго диапазона |

## projection_state

```sql
CREATE TABLE projection_state (
    state_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    projection_id   UUID NOT NULL REFERENCES entity_projection(projection_id),
    state_data      JSONB NOT NULL DEFAULT '{}'::jsonb,
    version_id      BIGINT,
    created_at      TIMESTAMPTZ DEFAULT now()
);
```

### state_data

JSONB-поле, содержащее все данные проекции. Пример:

```json
{
  "title": "Матрица",
  "year": 1999,
  "rating": 8.7,
  "genre": ["sci-fi", "action"],
  "director": "The Wachowskis"
}
```

## Ключевые особенности

### 1. Множественные проекции

Одна сущность может иметь множество проекций:

```
Entity "Матрица"
├── Projection в модели "cinema" (title: "Матрица", year: 1999)
├── Projection в модели "default" (title: "The Matrix")
├── Projection в модели "language:ru" (label: "Матрица")
└── Projection в модели "language:en" (label: "The Matrix")
```

### 2. Версионирование

Через `is_current`, `valid_from`, `valid_to` поддерживается историческое состояние.

### 3. Достоверность

Поле `confidence` позволяет хранить конфликтующие данные с разной степенью достоверности.

## Связи через проекции

[[database/relations|Семантические связи]] идут через проекции:

```sql
CREATE TABLE semantic_relation (
    source_projection_id  UUID REFERENCES entity_projection(projection_id),
    target_projection_id  UUID REFERENCES entity_projection(projection_id),
    ...
);
```

Это корректно: связь реализуется через призму конкретной модели мира.

## Связанные страницы

- [[database/entity-model]] — Модель сущностей
- [[database/ontology]] — Онтологические модели
- [[database/temporal]] — Версионирование
- [[database/relations]] — Семантические связи
- [[philosophy/world-models]] — Модели мира
- [[architecture/layers]] — Архитектурные слои (Projection layer)
