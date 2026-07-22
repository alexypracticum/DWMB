---
type: database
title: "Версионирование и временны́е данные"
description: "version_registry, event_log, projection_state — временнóе хранение и event sourcing"
tags: [database, temporal, versioning, event-sourcing]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 28.06.2026 OpenCode schema_analysis.md
  - 28.07.2026 OpenCode Полный анализ
status: stable
---

# Версионирование и временны́е данные

Система версионирования [[architecture/overview|DWMB]] обеспечивает полную восстанавливаемость состояния через event sourcing.

## version_registry

Единая точка отсчёта всех изменений. Аудит "из коробки".

```sql
CREATE TABLE version_registry (
    version_id  BIGSERIAL PRIMARY KEY,
    entity_id   UUID NOT NULL,
    change_type TEXT NOT NULL,
    change_data JSONB,
    created_by  UUID,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

### Особенности

- `version_id` — монотонно возрастающий BIGINT
- `entity_id` — какая сущность изменена
- `change_type` — тип изменения (create, update, delete)
- `change_data` — что изменилось

**Примечание:** REFERENCES version_registry(version_id) убрано из других таблиц. version_id — обычный BIGINT, валидность контролируется приложением.

## event_log

Полная восстанавливаемость состояния через event sourcing.

```sql
CREATE TABLE event_log (
    event_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id   UUID NOT NULL,
    event_type  TEXT NOT NULL,
    event_data  JSONB,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

### Типы событий

| Тип | Описание |
|-----|----------|
| entity.created | Сущность создана |
| entity.updated | Сущность обновлена |
| entity.deleted | Сущность удалена |
| projection.created | Проекция создана |
| projection.updated | Проекция обновлена |
| relation.created | Связь создана |
| relation.deleted | Связь удалена |

## projection_state

Данные сущностей хранятся в JSONB с поддержкой временнóго диапазона.

```sql
CREATE TABLE projection_state (
    state_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    projection_id UUID NOT NULL REFERENCES entity_projection(projection_id),
    state_data    JSONB NOT NULL DEFAULT '{}'::jsonb,
    version_id    BIGINT,
    created_at    TIMESTAMPTZ DEFAULT now()
);
```

### Temporal pattern

```sql
CREATE TABLE entity_projection (
    ...
    is_current  BOOLEAN DEFAULT true,
    valid_from  TIMESTAMPTZ DEFAULT now(),
    valid_to    TIMESTAMPTZ,
    ...
);
```

Позволяет хранить исторические данные: какое состояние было актуальным в определённый момент времени.

## EXCLUDE-ограничения

**Статус:** не реализовано

Для предотвращения пересекающихся по времени записей:

```sql
EXCLUDE USING gist (
    entity_id WITH =,
    daterange(valid_from, valid_to) WITH &&
);
```

**Примечание:** btree_gist установлен, но не используется.

## Проблемы

### 1. version_id как FK
Каждая вставка требует INSERT в version_registry → взятие version_id → INSERT в целевую таблицу. При массовом импорте это узкое горлышко.

**Решение:** убрать REFERENCES, сделать version_id обычным BIGINT.

### 2. Отсутствие EXCLUDE-ограничений
Могут появляться пересекающиеся по времени записи для одной сущности.

### 3. Отсутствие provenance
Для импорта книг, фильмов, новостей критически важно знать:
- из какого источника пришла запись
- когда был импорт
- какой был batch

## Связанные страницы

- [[architecture/layers]] — Архитектурные слои (Temporal layer)
- [[architecture/data-model]] — Полная схема данных
- [[database/entity-model]] — Модель сущностей
- [[database/projections]] — Проекции сущностей
