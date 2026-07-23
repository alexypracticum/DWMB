---
type: development
title: "Дорожная карта"
description: "Планы развития DWMB: текущий статус v0.16.0"
tags: [development, roadmap, plans, future]
date_created: 2026-07-22
date_updated: 2026-07-23
sources:
  - ROADMAP.md
  - CHANGELOG.md
status: stable
---

# Дорожная карта

Планы развития [[architecture/overview|DWMB]]: текущий статус и ближайшие приоритеты.

## Текущая версия

**v0.16.0** (июль 2026)

- Базовая архитектура работает
- 28+ таблиц в БД
- 7 плагинов
- 7 языков (полностью рабочих)
- 40+ типов сущностей
- 663 UI-строки в dedicated таблицах
- 169 тестов
- GraphQL API (10 queries + 5 mutations + 3 geo)
- Микросервисы (AI, Search, Media)
- RLS на entity
- WebSocket
- Service Layer (entity, kind, relation)
- API v1 с versioning
- WCAG AA accessibility

## Приоритет A: Доделать существующее

| Задача | Статус | Описание |
|--------|--------|----------|
| Версия main.py | Нужно обновить | "0.8.0" → "0.17.0" |
| RU_LABELS helpers.py | Не начато | ~50 хардкоженных строк для info_table/image_data_row |

## Приоритет B: Визуализация

| Задача | Статус | Описание |
|--------|--------|----------|
| Граф связей | Не начато | D3.js/Cytoscape.js на странице сущности |
| Фильтрация графа | Не начато | По типам связей |

## Приоритет C: Внешние API

| Задача | Статус | Описание |
|--------|--------|----------|
| IMDB (OMDb) | Заготовки | external_apis.py создан |
| Wikipedia | Заготовки | REST API, User-Agent |
| MusicBrainz | Заготовки | User-Agent header |

## Приоритет D: Промышленная

| Задача | Статус | Описание |
|--------|--------|----------|
| CI/CD | Не начато | GitHub Actions |
| Мониторинг | Не начато | Prometheus/Grafana |
| GraphQL subscriptions | Не начато | Real-time через GraphQL |

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[philosophy/everything-as-entity]] — Философия проекта
- [[development/testing]] — Тестирование
- [[development/contributing]] — Вклад в проект
