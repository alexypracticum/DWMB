---
type: api
title: "REST API"
description: "RESTful API DWMB: эндпоинты, CRUD для сущностей, разделение HTML/JSON"
tags: [api, rest, crud, endpoints]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 19.07.2026.Ответы_на_вопросы.md
  - 20.07.2026.CMS_ANALYSIS.md
status: stable
---

# REST API

RESTful API [[architecture/overview|DWMB]]: 71 эндпоинт для работы с сущностями, медиа, AI и системой.

## Текущие эндпоинты

### Entity CRUD

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/entity/create` | POST | HTML | Создание сущности |
| `/entity/{id}` | GET | HTML | Просмотр сущности |
| `/entity/{id}/edit` | POST | HTML | Редактирование |
| `/entity/{id}/delete` | POST | HTML | Удаление |

### EntityKind CRUD

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/admin/kinds` | GET | HTML | Список типов |
| `/admin/kinds/{id}/edit` | POST | HTML | Редактирование типа |

### OntologyTemplate CRUD

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/admin/templates` | GET | HTML | Список шаблонов |
| `/admin/templates/create` | POST | HTML | Создание шаблона |
| `/admin/templates/{id}/edit` | POST | HTML | Редактирование |
| `/admin/templates/{id}/delete` | POST | HTML | Удаление |

### FieldRegistry CRUD

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/admin/fields` | GET | HTML | Список полей |
| `/admin/fields/create` | POST | HTML | Создание поля |
| `/admin/fields/{id}/edit` | POST | HTML | Редактирование |
| `/admin/fields/{id}/delete` | POST | HTML | Удаление |

### UserAccount

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/admin/users` | GET | HTML | Список пользователей |
| `/admin/users/{id}/toggle-admin` | POST | HTML | Переключение админа |

### Media

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/upload` | POST | JSON | Загрузка файла |
| `/media/{id}` | GET | JSON | Presigned URL |

### AI

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/ai/analyze` | POST | JSON | Анализ сущности |
| `/ai/profiles` | GET | JSON | Список профилей |

### Search

| Эндпоинт | Метод | Формат | Описание |
|-----------|-------|--------|----------|
| `/search` | GET | HTML | Поиск сущностей |

## Проблемы

### 1. Смешивание HTML и JSON

`entities.py` и `admin.py` смешивают HTML-шаблоны и JSON API. Нет явного разделения на `/api/` и веб-маршруты.

**Решение:** создать отдельный префикс `/api/v1/` для JSON API.

### 2. Отсутствие RESTful API

Нет полноценного REST API для всех сущностей (POST/GET/PUT/DELETE в JSON).

**Текущий статус:**

| Сущность | Create | Read | Update | Delete |
|----------|--------|------|--------|--------|
| Entity | ✅ | ✅ | ✅ | ✅ |
| EntityKind | — | ✅ | ✅ | — |
| OntologyTemplate | ✅ | ✅ | ✅ | ✅ |
| OntologyModel | — | — | — | — |
| FieldRegistry | ✅ | ✅ | ✅ | ✅ |
| UserAccount | — | ✅ | — | — |
| MediaAsset | ✅ | ✅ | — | — |
| SemanticRelation | — | ✅ | — | — |

### 3. Отсутствие OpenAPI/Swagger

Нет документации API.

### 4. Нет аутентификации для API

API не требует аутентификации.

## Планы

- Создать `/api/v1/` префикс для JSON API
- Реализовать RESTful CRUD для OntologyModel
- Добавить документацию OpenAPI
- Реализовать аутентификацию для API
- Добавить пагинацию и фильтрацию

## Связанные страницы

- [[api/router]] — Маршрутизация
- [[api/search]] — Поиск
- [[architecture/overview]] — Обзор архитектуры
- [[database/entity-model]] — Модель сущностей
- [[frontend/templates]] — Шаблоны UI
