---
type: database
title: "Модель сущностей"
description: "Сущности (entity) как основа данных DWMB: типы,状态, JSONB-проекции"
tags: [database, entity, model]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 17.07.2026.ПРОМПТ создания БД.md
  - 19.07.2026.Ответы_на_вопросы.md
  - 17.05.2026 Ещё одна версия от ChatGPT.md
status: stable
---

# Модель сущностей

**Entity** — базовая единица данных в [[architecture/overview|DWMB]]. Каждый объект мира (фильм, книга, человек, язык, поле) represented как сущность с UUID-идентификатором.

## Структура entity

```sql
CREATE TABLE entity (
    entity_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_code TEXT NOT NULL UNIQUE,
    kind_id     UUID REFERENCES entity_kind(kind_id),
    status      TEXT DEFAULT 'draft',
    owner_id    UUID REFERENCES user_account(user_id),
    created_at  TIMESTAMPTZ DEFAULT now(),
    updated_at  TIMESTAMPTZ DEFAULT now()
);
```

| Поле | Описание |
|------|----------|
| entity_id | UUID, первичный ключ |
| entity_code | Уникальный код ( slug-like ) |
| kind_id | Тип сущности → entity_kind |
| status | Статус: draft, active, archived, deleted |
| owner_id | Владелец → user_account |
| created_at | Время создания |
| updated_at | Время последнего обновления |

## entity_kind — типы сущностей

```sql
CREATE TABLE entity_kind (
    kind_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind_code   TEXT NOT NULL UNIQUE,
    kind_name   TEXT NOT NULL,
    description TEXT,
    schema      JSONB DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

### Текущие типы (47)

Типы организованы по доменам:

| Домен | Типы |
|-------|------|
| Кино | movie, actor, director, series, character, genre, award |
| Музыка | song, musician, album, band, channel, podcast |
| Литература | book, writer, article |
| Наука | chemical_element, formula, theorem, unit, phenomenon, concept, field |
| Люди | person, human, artist, scientist |
| Места | place, city, country, location |
| Природа | animal, plant, mineral |
| Концепты | event, period, movement, collection, tag, label_entity |
| Цифровые | digital_file, photo, video, audio |
| Организации | organization, company, institution |
| Игры | game, character, platform |
| CMS | page (мигрировано из page_registry) |
| UI | ui_string (мультиязычность) |
| Прочие | classifier, physical_item, currency, software, ontology_model, ontology_template, language, language_entity |

## Соответствие философии "Всё как сущность"

| Элемент | Должен быть сущностью | Статус |
|---------|----------------------|--------|
| Фильм, книга | entity_kind = 'movie'/'book' | Высокое |
| Человек | entity_kind = 'person' | Высокое |
| Язык | entity_kind = 'language' | Не ENUM, а сущность |
| Поле формы | entity_kind = 'field' | Частично |
| Страница сайта | entity_kind = 'page' | Реализовано |
| UI-строка | entity_kind = 'ui_string' | Реализовано (269 переводов) |
| Плагин | entity_kind = 'plugin' | Реализовано |
| Тип сущности | entity_kind = 'kind' | Частично |
| Файл | entity_kind = 'digital_file' | Реализовано |

## Проблемы

### 1. Предопределённые типы
entity_kind жёстко задан в init.sql. Нельзя создать "автомобиль", "здание" без правки init.sql.

**Решение:** CRUD для entity_kind через админ-панель.

### 2. field_registry
Поля привязаны к доменам (common, music, cinema и др.). Должны быть entity_kind = 'field'.

### 3. media_asset (компромисс)
media_asset остаётся как sidecar-таблица для производительности (O(1) hash lookup для дедупликации). CRUD идёт через entity kind='digital_file'. Это компромисс между философией и производительностью.

**Реализовано:**
- Upload создаёт entity kind='digital_file' для ВСЕХ файлов
- CRUD endpoints: GET/DELETE `/media/{asset_id}`
- metadata хранится в projection_state.state_data

### 4. Требования из Задачи.txt

- Выделить страницы сайта как сущности
- Привязать поля к страницам
- Создать типы для меток, типов сущностей, связей, плагинов
- Выполнить переводы через проекции

## Связанные страницы

- [[philosophy/everything-as-entity]] — Философия "Всё как сущность"
- [[architecture/data-model]] — Полная схема данных
- [[database/ontology]] — Онтологические модели
- [[database/projections]] — Проекции сущностей
- [[database/multilingual]] — Мультиязычность
