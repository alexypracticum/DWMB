---
type: frontend
title: "CMS — Управление контентом"
description: "Система управления контентом DWMB: page_registry, модульная архитектура, страницы как сущности"
tags: [frontend, cms, pages, content]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 20.07.2026.CMS_ANALYSIS.md
  - 19.07.2026.Ответы_на_вопросы.md
  - 21.07.2026.База данных.md
  - 19.07.2026.ANALYSIS_REPORT.md
status: stable
---

# CMS — Управление контентом

Система управления контентом [[architecture/overview|DWMB]]: страницы, шаблоны, навигация.

## Текущая реализация

### page_registry

```sql
CREATE TABLE page_registry (
    page_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    page_slug   TEXT NOT NULL UNIQUE,
    page_title  TEXT NOT NULL,
    page_type   TEXT NOT NULL,  -- 'static', 'dynamic', 'list'
    template    TEXT,
    is_active   BOOLEAN DEFAULT true,
    sort_order  INT DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

### Типы страниц

| Тип | Описание |
|-----|----------|
| static | Статические страницы (about, contacts) |
| dynamic | Динамические страницы (entity detail) |
| list | Списочные страницы (каталоги) |

## Проблемы

### 1. page_registry ≠ сущность

По философии [[philosophy/everything-as-entity|"Всё как сущность"]] страницы должны быть сущностями с типом `page`.

**Текущее состояние:** page_registry — отдельная таблица, не entity.

### 2. Нет мультиязычности

Страницы не поддерживают переводы по умолчанию.

### 3. Ограниченная гибкость

Нет возможности создавать произвольные типы страниц.

### 4. Нет привязки к полям

Нет связи между страницами и полями (field_registry).

## Требования из Задачи.txt

1. Страницы сайта как сущности
2. Привязка полей к страницам
3. Группировка полей по страницам в интерфейсе переводов
4. Гибкий интерфейс с настройкой страницы сущностей

## Планы

### Этап 1: Приведение к философии

- Преобразовать page_registry в entity с kind_id = 'page'
- Создать тип `page` в entity_kind
- Мигрировать данные

### Этап 2: Мультиязычность

- Добавить поддержку переводов для страниц
- Интеграция с entity_label

### Этап 3: Привязка полей

- Связать страницы с полями (field_registry)
- Группировка полей по страницам

### Этап 4: Гибкий интерфейс

- Настройка страницы сущностей
- Редактируемые поля для заполнения
- Форма создания с отображаемой структурой

## Модульная архитектура CMS

```
┌─────────────────────────────────────────────┐
│              CMS Module                      │
├─────────────────────────────────────────────┤
│  page_registry  │  Страницы                 │
│  page_template  │  Шаблоны страниц          │
│  page_block     │  Блоки контента           │
│  page_menu      │  Меню навигации           │
├─────────────────────────────────────────────┤
│  Entity Service  │  CRUD для сущностей      │
│  Label Service   │  Переводы                │
│  Media Service   │  Файлы                   │
└─────────────────────────────────────────────┘
```

## Связанные страницы

- [[philosophy/everything-as-entity]] — Философия "Всё как сущность"
- [[database/entity-model]] — Модель сущностей
- [[frontend/templates]] — Шаблоны UI
- [[frontend/multilingual-ui]] — Мультиязычный интерфейс
- [[api/rest-api]] — API для CMS
