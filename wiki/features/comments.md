---
type: feature
title: "Комментарии"
description: "Система комментариев с вложенностью (ответы на ответы), привязка к сущностям"
tags: [features, comments, nesting, discussion]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/routes/comments.py
  - app/models/comments.py
resource: "file://raw/19.07.2026.ANALYSIS_REPORT.md"
status: AI-Generated
---

# Комментарии

Система комментариев с поддержкой **вложенности** (ответы на ответы).

## Модель

```sql
comment:
  comment_id    UUID PK
  entity_id     UUID FK → entity
  user_id       UUID FK → user_account
  parent_id     UUID FK → comment (NULL = верхний уровень)
  content       TEXT NOT NULL
  is_active     BOOLEAN DEFAULT true
  created_at    TIMESTAMPTZ
  updated_at    TIMESTAMPTZ
```

## Функциональность

- **Создание** комментариев к любым сущностям
- **Вложенность** неограниченной глубины (ответы на ответы)
- **Редактирование** своих комментариев
- **Удаление** (soft delete через `is_active`)
- **Отображение** на странице сущности

## Эндпоинты

```
GET  /entity/{id}/comments        → список комментариев
POST /entity/{id}/comments        → создать комментарий
POST /comments/{id}/edit           → редактировать
POST /comments/{id}/delete         → удалить
```

## Разрешения

| Действие | Admin | Editor | Viewer |
|----------|-------|--------|--------|
| Создать | ✅ | ✅ | ✅ |
| Редактировать свои | ✅ | ✅ | ✅ |
| Удалить любой | ✅ | ❌ | ❌ |
| Удалить свой | ✅ | ✅ | ✅ |

## Миграция

`003_comments.sql` — создание таблицы comment.

## Связанные страницы

- [[features/entity-crud]] — CRUD сущностей (комментарии на странице)
- [[features/rbac]] — разрешения

## Источники

- `app/routes/comments.py`
- `app/models/comments.py`
