---
type: feature
title: "Экспорт"
description: "Экспорт данных сущностей в форматы Markdown и HTML"
tags: [features, export, markdown, html]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/routes/export.py
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Экспорт

DWMB поддерживает экспорт данных сущностей в **Markdown** и **HTML**.

## Эндпоинты

```
GET /entity/{id}/export/markdown   → экспорт в Markdown
GET /entity/{id}/export/html       → экспорт в HTML
```

## Формат Markdown

```markdown
# Матрица (The Matrix)

**Тип:** Фильм
**Код:** matrix
**Статус:** active

## Данные

| Поле | Значение |
|------|----------|
| Название | Матрица |
| Год | 1999 |
| Рейтинг | 8.7 |
| Режиссёр | Вачовски |

## Связи

- directed_by → Кристофер Нолан
- acted_in → Keanu Reeves (роль: Neo)

## Комментарии

(нет комментариев)
```

## Формат HTML

Полноценная HTML-страница с CSS-стилями, пригодная для публикации.

## Связанные страницы

- [[features/entity-crud]] — данные для экспорта

## Источники

- `app/routes/export.py`
