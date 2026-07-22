---
type: ui
title: "Режимы отображения"
description: "4 режима просмотра списка сущностей: Preview (с постерами), Grid, List, Table"
tags: [ui, display-modes, view, layout]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/templates/entities/list.html
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Режимы отображения

DWMB поддерживает **4 режима** просмотра списка сущностей.

## Режимы

### Preview (с постерами)

Карточки с главным изображением (hero_image), названием и кратким описанием. Идеально для визуальных типов (фильмы, книги, альбомы).

### Grid

Компактная сетка карточек без изображений. Название + тип + основные поля.

### List

Список строк с иконкой типа, названием и мета-данными. Подробный вид.

### Table

Табличный вид с колонками. Подходит для сравнения данных.

## Переключение

Режим выбирается через параметр URL или кнопки в интерфейсе:

```
GET /entities?view=preview
GET /entities?view=grid
GET /entities?view=list
GET /entities?view=table
```

Сохраняется в `localStorage` для персистентности.

## Связанные страницы

- [[features/entity-crud]] — список сущностей
- [[ui/theme-system]] — как тема влияет на отображение

## Источники

- `app/templates/entities/list.html`
