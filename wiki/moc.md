---
type: reference
title: "Карта связей DWMB Wiki"
description: "Граф знаний проекта DWMB — центральный хаб со связями между всеми страницами wiki"
tags: [moc, navigation, graph]
date_created: 2026-07-22
date_updated: 2026-07-22
status: stable
---

# Карта связей DWMB (Map of Content)

Центральный узел графа знаний проекта DWMB. Каждый раздел — это хаб, связанный с конкретными wiki-страницами.

---

## Философия

Ядро проекта — две фундаментальные идеи:

- **[[philosophy/everything-as-entity|Всё как сущность]]** — любой объект реального или абстрактного мира является сущностью
- **[[philosophy/world-models|Сущность как точка пересечения моделей мира]]** — одна сущность может иметь множество проекций в разных контекстах

Связано с:
- [[database/entity-model]] — как философия реализована в данных
- [[database/ontology]] — как модели мира определяются
- [[database/multilingual]] — язык как ещё одна проекция

---

## Архитектура

Техническая основа DWMB:

- **[[architecture/overview|Системная архитектура]]** — FastAPI + PostgreSQL + Docker Compose
- **[[architecture/layers|Архитектурные слои]]** — 10 слоёв: Identity, Ontology, Projection, Relation, Temporal, Context, Event, Media, AI, Classification
- **[[architecture/plugin-system|Система плагинов]]** — 7 плагинов: ai, tmdb, themes, cms, stats, rbac, email

Связано с:
- [[architecture/data-model]] — полная схема данных
- [[features/admin-panel]] — управление системой

---

## База данных

28+ таблиц в схеме `meta`, организованные по архитектурным слоям:

- **[[architecture/data-model|Обзор схемы]]** — все таблицы, слои, индексы
- **[[database/entity-model|Ядро сущностей]]** — entity, entity_kind
- **[[database/projections|Проекции]]** — entity_projection, projection_state
- **[[database/ontology|Онтологическая система]]** — ontology_model, ontology_template, field_registry
- **[[database/relations|Граф связей]]** — relation_type, semantic_relation
- **[[database/temporal|Временна́я модель]]** — version_registry, event_log
- **[[database/media|Медиа-хранилище]]** — media_asset, rendition, collection
- **[[database/multilingual|Мультиязычность]]** — entity_label, UI-строки
- **[[database/seed-data|Seed-данные]]** — 35 типов, 250+ записей, 60+ связей

Связано с:
- [[philosophy/everything-as-entity]] — философия → схема
- [[plugins/ai-plugin]] — pgvector, эмбеддинги

---

## Фичи

Реализованные возможности приложения:

- **[[features/entity-crud|CRUD сущностей]]** — 3-шаговое создание, редактирование, удаление
- **[[features/visual-editor|Визуальный редактор]]** — 21+ тип блоков, drag-and-drop, layout.py
- **[[api/search|Система поиска]]** — полнотекстовый + векторный + фильтры
- **[[plugins/ai-plugin|AI-интеграция]]** — OpenAI, эмбеддинги, парсинг, гибридный поиск
- **[[features/admin-panel|Админ-панель]]** — типы, шаблоны, пользователи, AI, плагины (21 шаблон)
- **[[features/rbac|RBAC]]** — 3 роли, 13 разрешений, JWT
- **[[features/comments|Комментарии]]** — вложенность, ответы на ответы
- **[[features/export|Экспорт]]** — Markdown/HTML
- **[[features/feeds|Фиды]]** — RSS/Atom

---

## UI/UX

Интерфейс пользователя:

- **[[ui/theme-system|Система тем]]** — 9 тем + визуальный CSS-редактор
- **[[ui/display-modes|Режимы отображения]]** — Preview, Grid, List, Table
- **[[ui/localization|Локализация]]** — 7 языков, 269+ сущностей-переводов
- **[[frontend/templates|Шаблоны]]** — Jinja2 + Tailwind CSS + HTMX
- **[[frontend/cms|CMS]]** — управление контентом страниц
- **[[frontend/multilingual-ui|Мультиязычный UI]]** — интерфейс переводов

---

## API

Серверная часть и интеграции:

- **[[api/rest-api|REST API]]** — эндпоинты, CRUD (71 эндпоинт)
- **[[api/router|Маршрутизация]]** — структура роутеров FastAPI
- **[[api/search|Поиск]]** — PostgreSQL FTS, pg_trgm, pgvector

---

## Плагины

Модульная система расширения:

- **[[plugins/plugins|Обзор плагинов]]** — архитектура, PluginBase
- **[[plugins/ai-plugin|AI Plugin]]** — OpenAI, Anthropic, Google, MiMo

---

## Деплой

Настройка и запуск:

- **[[deployment/docker|Docker Compose]]** — PostgreSQL 16 + pgvector + MinIO + App
- **[[deployment/environment|Переменные окружения]]** — конфигурация БД, S3, AI, безопасности

---

## Разработка

Процессы и стандарты:

- **[[development/roadmap|Дорожная карта]]** — v0.9.0 → v1.0.0
- **[[development/testing|Тестирование]]** — pytest,覆盖率
- **[[development/contributing|Вклад в проект]]** — код-стайл, PR, issues

---

## Граф связей (текстовое представление)

```
                     ┌─────────────────┐
                     │   ФИЛОСОФИЯ     │
                     │  Всё как        │
                     │  сущность       │
                     └────────┬────────┘
                              │
               ┌──────────────┼──────────────┐
               ▼              ▼              ▼
     ┌─────────────┐ ┌──────────────┐ ┌──────────────┐
     │ Точка       │ │ Мульти-      │ │ Онтологии    │
     │ пересечения │ │ язычность    │ │              │
     └──────┬──────┘ └──────┬───────┘ └──────┬───────┘
            │               │                │
            └───────┬───────┘                │
                    ▼                        ▼
           ┌────────────────┐      ┌─────────────────┐
           │  БАЗА ДАННЫХ   │◄────►│  АРХИТЕКТУРА    │
           │  28+ таблиц    │      │  FastAPI+PG     │
           └───────┬────────┘      └────────┬────────┘
                   │                         │
     ┌─────────────┼─────────────────────────┼─────────┐
     ▼             ▼                         ▼         ▼
 ┌────────┐  ┌──────────┐            ┌──────────┐ ┌────────┐
 │Entity  │  │Relations │            │ AI       │ │ UI     │
 │Proje-  │  │Graph     │            │Integra-  │ │ Система│
 │ctions  │  │          │            │ция       │ │        │
 └────────┘  └──────────┘            └──────────┘ └────────┘
     │             │                      │           │
     └─────────────┼──────────────────────┼───────────┘
                   ▼                      ▼
          ┌────────────────┐    ┌──────────────────┐
          │   ФИЧИ         │    │   ДЕПЛОЙ         │
          │ CRUD, Поиск,   │    │ Docker Compose   │
          │ Экспорт, Фиды  │    │ MinIO, pgvector  │
          └────────────────┘    └──────────────────┘
```
