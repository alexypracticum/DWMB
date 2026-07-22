---
type: feature
title: "CRUD сущностей"
description: "3-шаговое создание сущностей (выбор типа → шаблон → форма), редактирование, удаление, история изменений"
tags: [features, crud, entity, creation, editing]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - raw/22.07.2026.MIMO.md
  - app/routes/entities.py
  - app/templates/entities/
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# CRUD сущностей

DWMB предоставляет **3-шаговый процесс создания** сущностей и полный CRUD через веб-интерфейс.

## Создание сущности (3 шага)

### Шаг 1: Выбор типа

Сетка карточек с типами сущностей: фильм, актёр, книга, город, химический элемент и т.д.

```
GET /entity/create → выбор kind_id
```

### Шаг 2: Выбор шаблона

Показываются все **активные шаблоны** для выбранного типа. Если шаблон имеет макет — отмечен бейджем "N блоков макета".

```
GET /entity/create?kind=<kind_id> → выбор template_id
```

Можно создать сущность **без шаблона** (ввести код вручную).

### Шаг 3: Динамическая форма

**Основные поля** (всегда):
- Код сущности (entity_code)
- Название RU
- Название EN
- Описание

**Поля из schema_definition шаблона** генерируются автоматически:
- `text` → текстовое поле
- `number` → числовое поле
- `boolean` → чекбокс
- `select` → выпадающий список (enum)
- `textarea` → многострочное поле

```
POST /entity/create → сохранение entity + entity_projection + projection_state
```

## Чтение сущности

### Детальная страница

```
GET /entity/{entity_id}
```

Отображает:
- Основную информацию (код, тип, статус)
- Данные из projection_state (рендеринг по макету шаблона)
- Метки на разных языках
- Связи (исходящие и входящие)
- Медиа-файлы
- Историю изменений

### Список сущностей

```
GET /entities?kind=<kind_id>&search=<query>&page=<n>
```

4 режима отображения: Preview (с постерами), Grid, List, Table.

Подробнее: [[ui/display-modes]]

## Редактирование

```
GET /entity/{entity_id}/edit → форма редактирования
POST /entity/{entity_id}/edit → сохранение изменений
```

Если сущность имеет шаблон — форма показывает поля из schema с текущими значениями. При сохранении обновляются и labels, и state_data.

## Удаление

```
POST /entity/{entity_id}/delete
```

**Soft delete:** статус меняется на `deleted`, данные не удаляются физически.

## История изменений

```
GET /entity/{entity_id}/history
```

Показывает все изменения: кто, когда, что изменил. Данные из `event_log`.

## Загрузка файлов

```
POST /upload → сохранение файла, возврат URL
```

Файлы сохраняются в MinIO через `storage.py`. Медиа привязываются к сущностям через `media_asset`.

## Связанные страницы

- [[database/entity-model]] — куда сохраняются данные
- [[features/visual-editor]] — layout_blocks шаблонов
- [[database/seed-data]] — начальные данные
- [[ui/display-modes]] — 4 варианта просмотра

## Источники

- `raw/22.07.2026.MIMO.md` — история создания CRUD
- `app/routes/entities.py` — маршруты
- `app/templates/entities/` — шаблоны
