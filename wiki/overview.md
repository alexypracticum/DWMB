---
type: overview
title: "DWMB — Dynamic World Meta-Base"
description: "Гибридная система для хранения и управления знаниями: Python, FastAPI, PostgreSQL, MinIO"
tags: [overview, project, introduction]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 08.03.2026.Пишем БД c ChatGPT.md
  - 22.07.2026.MIMO.md
  - ROADMAP.md
status: stable
---

# DWMB — Dynamic World Meta-Base

**Гибридная система для хранения и управления знаниями**, объединяющая реляционную и графовую модели данных с поддержкой мультиязычности и онтологической архитектуры.

## Философия

> **"Всё как сущность"** — любые объекты мира являются сущностями с единым идентификатором, типом и связями.

> **"Сущность как точка пересечения моделей мира"** — одна сущность может иметь множество проекций в разных моделях мира.

См. [[philosophy/everything-as-entity]] и [[philosophy/world-models]].

## Стек

| Компонент | Технология |
|-----------|-----------|
| Язык | Python 3.12 |
| Backend | FastAPI + SQLAlchemy async |
| БД | PostgreSQL 16 + pgvector + pg_trgm |
| Хранилище | MinIO (S3) |
| Кэш | Redis |
| Frontend | Jinja2 + Tailwind CSS + TipTap + HTMX |
| Оркестрация | Docker Compose |

## Возможности

- **47 типов** сущностей
- **71 тип** связей
- **28+ таблиц** в 10 архитектурных слоях
- **7 плагинов**: AI, TMDB, Themes, CMS, Stats, RBAC, Email
- **7 языков**: ru, en, de, fr, es, zh, ja
- **100+ эндпоинтов** API
- **20+ тестов**
- **Версионирование** через event sourcing
- **AI-интеграция**: OpenAI, Anthropic, Google, MiMo

## Структура wiki

```
wiki/
├── overview.md              ← Эта страница
├── index.md                 ← Оглавление
├── log.md                   ← Журнал изменений
├── philosophy/
│   ├── everything-as-entity.md
│   └── world-models.md
├── architecture/
│   ├── overview.md
│   ├── layers.md
│   ├── data-model.md
│   ├── entity-migration.md  ← План миграции таблиц
│   └── plugin-system.md
├── database/
│   ├── entity-model.md
│   ├── ontology.md
│   ├── multilingual.md
│   ├── relations.md
│   ├── temporal.md
│   ├── media.md
│   ├── projections.md
│   └── seed-data.md
├── api/
│   ├── rest-api.md
│   ├── router.md
│   └── search.md
├── frontend/
│   ├── templates.md
│   ├── multilingual-ui.md
│   └── cms.md
├── features/
│   ├── entity-crud.md
│   ├── comments.md
│   ├── visual-editor.md
│   ├── rbac.md
│   ├── admin-panel.md
│   ├── export.md
│   └── feeds.md
├── ui/
│   ├── display-modes.md
│   ├── theme-system.md
│   └── localization.md
├── plugins/
│   ├── plugins.md
│   └── ai-plugin.md
├── deployment/
│   ├── docker.md
│   └── environment.md
└── development/
    ├── roadmap.md
    ├── testing.md
    └── contributing.md
```

## Быстрый старт

1. Клонировать репозиторий
2. Запустить `docker compose up -d`
3. Инициализировать БД
4. Открыть `http://localhost:8000`

Подробнее см. [[deployment/docker]].

## Связанные страницы

- [[index]] — Оглавление
- [[architecture/overview]] — Архитектура
- [[philosophy/everything-as-entity]] — Философия
- [[development/roadmap]] — Дорожная карта
