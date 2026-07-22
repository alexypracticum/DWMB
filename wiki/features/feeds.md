---
type: feature
title: "Фиды"
description: "RSS и Atom фиды для отслеживания обновлений сущностей и страниц"
tags: [features, rss, atom, feeds]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/routes/feeds.py
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Фиды

DWMB предоставляет **RSS** и **Atom** фиды для отслеживания обновлений.

## Эндпоинты

```
GET /feed/entities     → RSS/Atom фид последних сущностей
GET /feed/pages        → RSS/Atom фид последних страниц
```

## Формат

Каждый элемент фида содержит:
- Заголовок (название сущности)
- Ссылку на страницу
- Дату обновления
- Краткое описание

## Использование

Подключите фид в любом RSS-ридере для отслеживания обновлений DWMB.

## Связанные страницы

- [[features/entity-crud]] — сущности в фиде

## Источники

- `app/routes/feeds.py`
