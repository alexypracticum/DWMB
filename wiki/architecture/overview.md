---
type: architecture
title: "Обзор архитектуры DWMB"
description: "Системное описание Dynamic World Meta-Base — гибридной системы для хранения и управления знаниями"
tags: [architecture, overview, stack]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 18.07.2027.PLAN.md
  - 08.03.2026.Пишем БД c ChatGPT.md
  - 22.07.2026.MIMO.md
status: stable
---

# Обзор архитектуры DWMB

**DWMB (Dynamic World Meta-Base)** — гибридная система для хранения и управления знаниями, объединяющая реляционную и графовую модели данных с поддержкой мультиязычности и [[philosophy/everything-as-entity|философии "Всё как сущность"]].

## Стек технологий

| Компонент | Технология |
|-----------|-----------|
| Язык | Python 3.11+ |
| Backend | FastAPI |
| БД | PostgreSQL 16 + pgvector + pg_trgm |
| Хранилище | MinIO (S3-совместимое) |
| Frontend | Jinja2 + Tailwind CSS + HTMX |
| Оркестрация | Docker Compose |
| Миграции | Alembic |
| Версионирование | PostgreSQL versioning pattern |

## Ключевые особенности

### Гибридная модель данных
- **Реляционная**: PostgreSQL для структурированных данных
- **Графовая**: semantic_relation для навигации по связям
- **Векторовая**: pgvector для семантического поиска

### Онтологическая архитектура
- [[philosophy/world-models|Модели мира]] (ontology_model) для разделения контекстов
- [[database/projections|Проекции]] (entity_projection) для представления сущностей
- [[database/ontology|Шаблоны]] (ontology_template) для описания структуры

### Версионирование
- version_registry как единая точка отсчёта
- projection_state с поддержкой временных периодов
- event_log для event sourcing

### Мультиязычность
- 7 языков: ru, en, de, fr, es, zh, ja
- [[database/multilingual|EntityLabel]] для данных сущностей
- UI-строки как сущности EntityKind 'ui_string'

## Архитектурные слои

См. [[architecture/layers]] для детального описания 10 архитектурных слоёв.

```
┌─────────────────────────────────────────────┐
│          Плагины (AI, TMDB, CMS и др.)      │
├─────────────────────────────────────────────┤
│  Frontend (Jinja2 + Tailwind + HTMX)        │
├─────────────────────────────────────────────┤
│  API (FastAPI)                               │
├─────────────────────────────────────────────┤
│  Сервисы (EntityService, AI, Media, Auth)    │
├─────────────────────────────────────────────┤
│  PostgreSQL + pgvector + pg_trgm             │
│  ┌─────┬──────────┬───────────┬──────────┐  │
│  │ DML │ Version  │ Event Log │ Search   │  │
│  └─────┴──────────┴───────────┴──────────┘  │
└─────────────────────────────────────────────┘
```

## Общая схема данных

- 28+ таблиц
- 10 архитектурных слоёв
- 160+ типов сущностей (entity_kind)
- 717 строк SQL в meta_system_schema.sql

Детали см. в [[architecture/data-model]].

## Ключевые файлы проекта

| Файл | Назначение |
|------|-----------|
| `meta_system_schema.sql` | Полная схема БД (717 строк) |
| `seed_data.sql` | Начальные данные |
| `init.sql` | Инициализация (DML-операции) |
| `app/services/entity.py` | CRUD для сущностей |
| `app/services/ontology.py` | Работа с проекциями |
| `app/services/ai.py` | AI-интеграция |
| `app/services/media.py` | Хранилище файлов (MinIO) |
| `app/routers/entities.py` | API/HTML роуты сущностей |
| `app/templates/` | Шаблоны UI |

## Текущая версия

**v0.9.0** (по состоянию на июль 2026)

## Связанные страницы

- [[architecture/layers]] — Архитектурные слои
- [[architecture/data-model]] — Общая схема данных
- [[philosophy/everything-as-entity]] — Философия проекта
- [[database/entity-model]] — Модель сущностей
- [[development/roadmap]] — Дорожная карта
