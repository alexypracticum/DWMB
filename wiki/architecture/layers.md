---
type: architecture
title: "Архитектурные слои"
description: "10 архитектурных слоёв базы данных DWMB и их взаимодействие"
tags: [architecture, layers, database]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 17.07.2026.ПРОМПТ создания БД.md
  - 28.06.2026 OpenCode Полный анализ и доработанная схема.md
status: stable
---

# Архитектурные слои

База данных [[architecture/overview|DWMB]] организована в 10 архитектурных слоёв, каждый из которых отвечает за свою область ответственности.

## Слои

### 1. Identity (Идентичность)
**Таблицы:** entity, entity_kind

Базовый слой. Хранит уникальные идентификаторы сущностей и их типы.

- `entity` — UUID, entity_code, kind_id, status, owner_id, created_at
- `entity_kind` — типы сущностей (160+ видов)

### 2. Ontology (Онтология)
**Таблицы:** ontology_model, ontology_template, field_registry

Описывает структуру данных в моделях мира.

- `ontology_model` — модели мира (default, cinema, music и др.)
- `ontology_template` — шаблоны полей для конкретных типов сущностей
- `field_registry` — справочник всех полей

### 3. Projection (Проекция)
**Таблицы:** entity_projection, projection_state

Реализует [[philosophy/world-models|концепцию моделей мира]].

- `entity_projection` — связь сущности с моделью мира
- `projection_state` — JSONB с данными

### 4. Relation (Связи)
**Таблицы:** semantic_relation, relation_type

Графовая модель для навигации по связям между сущностями.

- `semantic_relation` — связи между проекциями
- `relation_type` — типы связей (performed_by, directed_by, written_in и др.)

### 5. Temporal (Временны́е)
**Таблицы:** version_registry, event_log

Версионирование и event sourcing.

- `version_registry` — единый центр отсчёта изменений
- `event_log` — полная восстанавливаемость состояния

### 6. Context (Контекст)
**Таблицы:** context

Система отсчёта для изоляции моделей данных.

- multi-tenant сценарии
- экспериментальные модели
- изоляция контекстов истинности

### 7. Event (События)
**Таблицы:** audit_log

Аудит и отслеживание изменений.

### 8. Media (Медиа)
**Таблицы:** media_asset, media_rendition, media_collection, media_collection_item

Управление цифровыми активами (DAM).

- `media_asset` — файлы (оригинал)
- `media_rendition` — рендеринги (thumbnail, preview)
- `media_collection` — коллекции файлов

### 9. AI (Искусственный интеллект)
**Таблицы:** ai_profile, ai_analysis, ai_cache

AI-интеграция и кеширование результатов.

### 10. Classification (Классификация)
**Таблицы:** classification_system, classification_node, entity_classification

Универсальная система классификации.

- `classification_system` — системы классификации ( Dewey, UDC и др.)
- `classification_node` — узлы дерева классификации
- `entity_classification` — привязка сущностей к классификации

## Взаимодействие слоёв

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Identity   │────▶│  Ontology    │────▶│ Projection  │
│  entity     │     │  model       │     │  state      │
│  kind       │     │  template    │     │  JSONB      │
└─────────────┘     │  field       │     └──────┬──────┘
                    └──────────────┘            │
                           │                   │
                           ▼                   ▼
                    ┌──────────────┐     ┌─────────────┐
                    │  Temporal    │     │  Relation   │
                    │  versioning  │     │  graph      │
                    │  event_log   │     │  relations  │
                    └──────────────┘     └─────────────┘
                           │                   │
                           ▼                   ▼
                    ┌──────────────┐     ┌─────────────┐
                    │  Context     │     │  Media      │
                    │  isolation   │     │  assets     │
                    └──────────────┘     └─────────────┘
```

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[architecture/data-model]] — Общая схема данных
- [[database/entity-model]] — Модель сущностей
- [[database/ontology]] — Онтологические модели
- [[database/temporal]] — Версионирование
- [[database/relations]] — Семантические связи
