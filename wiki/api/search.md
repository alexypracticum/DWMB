---
type: api
title: "Поиск"
description: "Полнотекстовый поиск в DWMB: PostgreSQL FTS, pg_trgm, векторный поиск pgvector"
tags: [api, search, fts, pg_trgm, pgvector]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 19.07.2026.Ответы_на_вопросы.md
  - 28.06.2026 OpenCode schema_analysis.md
status: stable
---

# Поиск

Система поиска в [[architecture/overview|DWMB]]: полнотекстовый поиск, поиск по похожести, векторный поиск.

## Текущая реализация

### Полнотекстовый поиск (FTS)

PostgreSQL full-text search на JSONB-полях `state_data`.

```sql
-- Индекс для полнотекстового поиска
CREATE INDEX idx_projection_state_fts ON projection_state
    USING GIN (to_tsvector('russian', state_data::text));
```

### Поиск по похожести (pg_trgm)

Триграммный поиск для нечёткого сравнения строк.

```sql
-- Индекс для триграммного поиска
CREATE INDEX idx_projection_state_trgm ON projection_state
    USING GIN (state_data::text gin_trgm_ops);
```

### Векторный поиск (pgvector)

Семантический поиск через эмбеддинги.

```sql
-- Хранение эмбеддингов
ALTER TABLE projection_state ADD COLUMN embedding vector(1536);

-- Индекс для векторного поиска
CREATE INDEX idx_projection_state_embedding ON projection_state
    USING ivfflat (embedding vector_cosine_ops);
```

## API поиска

| Эндпоинт | Метод | Описание |
|-----------|-------|----------|
| `/search?q=...` | GET | Полнотекстовый поиск |
| `/search/similar?entity_id=...` | GET | Поиск похожих сущностей |
| `/search/vector?q=...` | GET | Векторный поиск |

## Статус реализации

| Компонент | Статус |
|-----------|--------|
| FTS индексы | Реализованы |
| pg_trgm индексы | Реализованы |
| pgvector | Установлен, индексы созданы |
| HTML-интерфейс поиска | Реализован |
| API поиска | Частично |
| Фильтрация по типам | Реализовано |
| Фильтрация по моделям мира | Реализовано |
| Автодополнение | Не реализовано |

## Проблемы

### 1. Ограниченная навигация

Поиск работает только через HTML. Нет JSON API для поиска.

### 2. Нет фильтрации по связям

Нет возможности искать сущности, связанные с определённой сущностью.

### 3. Ограниченная сортировка

Нет возможности сортировки по релевантности, дате, популярности.

### 4. Нет сохранённых поисков

Нет возможности сохранять поисковые запросы.

## Планы

- JSON API для поиска
- Фильтрация по связям
- Расширенная сортировка
- Сохранённые поиски
- Автодополнение
- Поиск по графу связей

## Связанные страницы

- [[api/rest-api]] — REST API
- [[api/router]] — Маршрутизация
- [[database/projections]] — Проекции (state_data)
- [[architecture/data-model]] — Индексы
