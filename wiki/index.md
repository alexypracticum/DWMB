---
type: index
title: "Оглавление wiki DWMB"
description: "Индекс всех страниц wiki проекта Dynamic World Meta-Base"
tags: [index, navigation]
date_created: 2026-07-22
date_updated: 2026-07-22
status: stable
---

# Оглавление wiki DWMB

Полный индекс всех страниц wiki [[overview|Dynamic World Meta-Base]].

## Философия

| Страница                            | Описание                                    |
| ----------------------------------- | ------------------------------------------- |
| [[philosophy/everything-as-entity]] | Фундаментальный принцип "Всё как сущность"  |
| [[philosophy/world-models]]         | Сущность как точка пересечения моделей мира |

## Архитектура

| Страница | Описание |
|----------|----------|
| [[architecture/overview]] | Обзор архитектуры DWMB |
| [[architecture/layers]] | 10 архитектурных слоёв БД |
| [[architecture/data-model]] | Полная схема данных (28+ таблиц) |
| [[architecture/entity-migration]] | План миграции таблиц в сущности |
| [[architecture/plugin-system]] | Система плагинов (PluginBase) |
| [[architecture/caching]] | Кэширование: Redis + in-memory fallback |
| [[architecture/security]] | Безопасность: JWT, bcrypt, RBAC, rate limiting |

## База данных

| Страница | Описание |
|----------|----------|
| [[database/entity-model]] | Модель сущностей (entity, entity_kind) |
| [[database/ontology]] | Онтологические модели (ontology_model, template, field) |
| [[database/multilingual]] | Система мультиязычности (entity_label, UI-строки) |
| [[database/relations]] | Семантические связи (semantic_relation, relation_type) |
| [[database/temporal]] | Версионирование и временны́е данные |
| [[database/media]] | Медиа-хранилище (media_asset, rendition, collection) |
| [[database/projections]] | Проекции сущностей (entity_projection, projection_state) |
| [[database/seed-data]] | Начальные данные (35 типов, 250+ записей) |

## API

| Страница | Описание |
|----------|----------|
| [[api/rest-api]] | REST API: эндпоинты, CRUD |
| [[api/router]] | Маршрутизация FastAPI |
| [[api/search]] | Полнотекстовый и векторный поиск |
| [[api/graphql]] | GraphQL API: queries, mutations, subscriptions |
| [[api/graphql]] | GraphQL API (strawberry-graphql) |

## Frontend

| Страница | Описание |
|----------|----------|
| [[frontend/templates]] | Шаблоны UI (Jinja2 + Tailwind + HTMX) |
| [[frontend/multilingual-ui]] | Мультиязычный интерфейс |
| [[frontend/cms]] | CMS — управление контентом |

## Функции

| Страница | Описание |
|----------|----------|
| [[features/entity-crud]] | CRUD сущностей (3-шаговое создание) |
| [[features/comments]] | Комментарии с вложенностью |
| [[features/visual-editor]] | Визуальный редактор макетов (21+ блоков) |
| [[features/rbac]] | RBAC: роли, разрешения, JWT |
| [[features/admin-panel]] | Админ-панель (21 шаблон) |
| [[features/export]] | Экспорт в Markdown/HTML |
| [[features/feeds]] | RSS/Atom фиды |
| [[features/workflow]] | Workflow: draft/published/archived, аудит переходов |
| [[features/wysiwyg]] | WYSIWYG редактор (TipTap v2.6.6) |
| [[features/backup]] | Бэкапы: pg_dump, экспорт/импорт сущностей |

## Интерфейс

| Страница | Описание |
|----------|----------|
| [[ui/display-modes]] | 4 режима отображения (Preview, Grid, List, Table) |
| [[ui/theme-system]] | 9 тем + CSS-редактор |
| [[ui/localization]] | Локализация на 7 языков |

## Плагины

| Страница | Описание |
|----------|----------|
| [[plugins/plugins]] | Обзор плагинов (7 плагинов) |
| [[plugins/ai-plugin]] | AI Plugin: интеграция с LLM |

## Деплой

| Страница | Описание |
|----------|----------|
| [[deployment/docker]] | Docker Compose: оркестрация |
| [[deployment/environment]] | Переменные окружения |

## Разработка

| Страница | Описание |
|----------|----------|
| [[development/roadmap]] | Дорожная карта проекта |
| [[development/testing]] | Тестирование |
| [[development/contributing]] | Руководство по вкладу |
| [[development/cli]] | CLI утилита: status, seed, stats, backup, restore, migrate |
| [[development/improvements]] | План улучшений |
| [[development/architecture-analysis]] | Анализ архитектуры и рефакторинг |

## Навигация

| Страница | Описание |
|----------|----------|
| [[moc]] | Карта связей (Map of Content) |
| [[log]] | Журнал изменений wiki |

---

**Всего страниц:** 51  
**Обновлено:** 2026-07-25  
**Проект:** DWMB v0.18.0
