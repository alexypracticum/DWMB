---
type: database
title: "Онтологические модели"
description: "ontology_model, ontology_template, field_registry — описание структуры данных в моделях мира"
tags: [database, ontology, template, field]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 17.07.2026.ПРОМПТ создания БД.md
  - 28.06.2026 OpenCode schema_analysis.md
  - 17.05.2026 Ещё одна версия от ChatGPT.md
status: stable
---

# Онтологические модели

Описывают структуру данных в [[philosophy/world-models|моделях мира]]: какие поля доступны для каких типов сущностей.

## ontology_model

```sql
CREATE TABLE ontology_model (
    model_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_code  TEXT NOT NULL UNIQUE,
    model_name  TEXT NOT NULL,
    description TEXT,
    domain      TEXT,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

### Модели по умолчанию (13)

| Код | Домен | Описание |
|-----|-------|----------|
| default | general | Базовая модель для общих данных |
| cinema | art | Кинематограф |
| music | art | Музыка |
| literature | art | Литература |
| science | science | Наука |
| geography | social | География |
| history | social | История |
| technology | digital | Технологии |
| cms | general | CMS для контента |
| storage | general | Хранилище файлов |
| field_model | meta | Модель полей |
| ontology_entity_model | meta | Модель онтологии |
| language | social | Языки |

### Домены моделей

Модели разделены на 4 домена:
- **art** — cinema, music, literature
- **science** — science
- **social** — geography, history, language
- **general** — default, cms, storage
- **meta** — field_model, ontology_entity_model
- **digital** — technology

**Проблема:** домены — искусственное ограничение. Модели не должны быть жёстко привязаны к доменам.

## ontology_template

```sql
CREATE TABLE ontology_template (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES ontology_model(model_id),
    kind_id UUID NOT NULL REFERENCES entity_kind(kind_id),
    template_code TEXT NOT NULL UNIQUE,
    template_name TEXT NOT NULL,
    description TEXT,
    schema_definition JSONB NOT NULL DEFAULT '[]'::jsonb,
    layout_definition JSONB,
    is_active BOOLEAN DEFAULT true,
    constraints_definition JSONB,
    version_id BIGINT,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### schema_definition

JSONB-массив, описывающий доступные поля:

```json
[
  {
    "field_code": "title",
    "field_type": "text",
    "required": true,
    "validation": {"min_length": 1, "max_length": 500}
  },
  {
    "field_code": "year",
    "field_type": "integer",
    "required": false,
    "validation": {"min": 1800, "max": 2100}
  }
]
```

## field_registry

```sql
CREATE TABLE field_registry (
    field_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_code TEXT NOT NULL UNIQUE,
    field_name TEXT NOT NULL,
    field_type TEXT NOT NULL,
    domain TEXT,
    validation JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Типы полей

| Тип | Описание |
|-----|----------|
| text | Текстовые данные |
| integer | Целые числа |
| numeric | Дробные числа |
| boolean | Логические значения |
| date | Даты |
| json | Произвольный JSON |
| uuid | UUID-ссылки |
| enum | Перечисления |

### Домены полей

Поля组织ованы по доменам:
- common, music, cinema, literature, science, people, geography, organization, events, digital, gaming

**Проблема:** домены — искусственное ограничение. Поля должны быть [[philosophy/everything-as-entity|сущностями]] с категоризацией.

## CRUD для ontology_model

**Статус в интерфейсе: не реализован**

- ontology_model хранится в `meta.ontology_model`
- В админке нет страницы для управления моделями
- Модели создаются только через seed
- Связь model → kind происходит через template

**Что нужно:** CRUD-страница: список, создание, редактирование, удаление.

## CRUD для entity_kind

**Статус в интерфейсе: частично**

- Список: `/admin/kinds` — отображает все типы
- Редактирование: `/admin/kinds/{kind_id}/edit` — редактирование + JSON-редактор
- Создание: нет отдельной страницы (только через seed)
- Удаление: нет кнопки (нет POST-эндпоинта)

**Что нужно:** кнопка "Создать тип", кнопка "Удалить тип", валидация уникальности kind_code.

## CRUD для field_registry

**Статус в интерфейсе: реализовано**

- Список: `/admin/fields`
- Создание: `POST /admin/fields/create`
- Редактирование: `POST /admin/fields/{id}/edit`
- Удаление: `POST /admin/fields/{id}/delete`

## Связанные страницы

- [[philosophy/world-models]] — Модели мира
- [[database/entity-model]] — Модель сущностей
- [[database/projections]] — Проекции сущностей
- [[architecture/layers]] — Архитектурные слои (Ontology layer)
- [[architecture/data-model]] — Полная схема данных
