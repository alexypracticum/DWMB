---
type: api
title: "Маршрутизация"
description: "Структура роутеров FastAPI в DWMB: entities, admin, search, ai, media"
tags: [api, router, fastapi, routing]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 19.07.2026.Ответы_на_вопросы.md
  - 20.07.2026.CMS_ANALYSIS.md
status: stable
---

# Маршрутизация

Структура роутеров FastAPI в [[architecture/overview|DWMB]].

## Текущая структура

```
app/routers/
├── entities.py    — CRUD для сущностей (HTML + JSON)
├── admin.py       — Админ-панель (HTML + JSON API)
├── search.py      — Поиск (только HTML)
├── ai.py          — AI-интеграция (только JSON)
└── media.py       — Медиа-файлы (JSON)
```

## Проблемы

### 1. Смешивание форматов

`entities.py` и `admin.py` смешивают HTML-шаблоны и JSON API:

- Некоторые эндпоинты возвращают HTML
- Другие — JSON
- Нет префикса для идентификации

### 2. Нет явного разделения

Нет префикса `/api/` для JSON API. Все маршруты в одном пространстве имён.

### 3. Дублирование логики

Одна и та же логика может дублироваться в HTML и JSON обработчиках.

## Предлагаемая структура

```
app/routers/
├── api/
│   ├── v1/
│   │   ├── entities.py      — REST API для сущностей
│   │   ├── kinds.py         — REST API для типов
│   │   ├── templates.py     — REST API для шаблонов
│   │   ├── fields.py        — REST API для полей
│   │   ├── ontology.py      — REST API для моделей
│   │   ├── relations.py     — REST API для связей
│   │   ├── media.py         — REST API для медиа
│   │   └── ai.py            — REST API для AI
│   └── openapi.json         — Автогенерация
├── web/
│   ├── entities.py          — HTML-шаблоны сущностей
│   ├── admin.py             — HTML-шаблоны админки
│   ├── search.py            — HTML-шаблоны поиска
│   └── cms.py               — HTML-шаблоны CMS
└── main.py                  — Корневой роутер
```

## Преимущества

- Чёткое разделение API и UI
- Легко добавлять новые версии API (v1, v2)
- Автогенерация документации
- Единая точка входа для клиента

## Маршруты admin

| Префикс | Описание |
|---------|----------|
| `/admin/kinds` | Управление типами сущностей |
| `/admin/templates` | Управление шаблонами |
| `/admin/fields` | Управление полями |
| `/admin/users` | Управление пользователями |
| `/admin/settings` | Настройки системы |

## Middleware

- `ThemeMiddleware` — подстановка перевода `request.state.t`
- `AuthMiddleware` — аутентификация (планируется)
- `CORSMiddleware` — CORS для API

## Связанные страницы

- [[api/rest-api]] — REST API
- [[api/search]] — Поиск
- [[frontend/templates]] — Шаблоны UI
- [[architecture/overview]] — Обзор архитектуры
