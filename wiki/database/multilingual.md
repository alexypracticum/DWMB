---
type: database
title: "Мультиязычность"
description: "Система переводов DWMB: entity_label, UI-строки, 7 языков, архитектура переводов"
tags: [database, multilingual, i18n, translation]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 21.07.2026.MULTILINGUAL_ANALYSIS.md
  - 19.07.2026.Ответы_на_вопросы.md
  - 22.07.2026.MIMO.md
  - 19.07.2026.ANALYSIS_REPORT.md
status: stable
---

# Мультиязычность

Система переводов [[architecture/overview|DWMB]] реализована на двух уровнях: UI-строки интерфейса и данные сущностей.

## Два механизма переводов

### 1. UI-строки (интерфейс)

**Хранение:** `app/services/i18n.py` — централизованные словари `TRANSLATIONS["ru"]` и `TRANSLATIONS["en"]`

**Подстановка:** Middleware `ThemeMiddleware` подставляет `request.state.t` — объект перевода для текущего языка

**Покрытие:** навигация, кнопки, заголовки, метки

**Ограничение:** только ru/en

### 2. Данные сущностей (метки)

**Хранение:** таблица `entity_label`

```sql
CREATE TABLE entity_label (
    label_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id     UUID NOT NULL REFERENCES entity(entity_id),
    language_code TEXT NOT NULL,  -- ENUM: en, ru, de, fr, es, zh, ja
    label         TEXT NOT NULL,
    description   TEXT,
    created_at    TIMESTAMPTZ DEFAULT now()
);
```

**Языки:** ru, en, de, fr, es, zh, ja (7 языков)

**Ограничение:** интерфейс позволяет добавлять только RU и EN поля. Остальные языки (de, fr и др.) недоступны.

### 3. Переводы как сущности

**Статус:** реализовано

269 переводов мигрированы в EntityKind `ui_string`:
- Каждая UI-строка — сущность
- Переводы — проекции в моделях language:ru, language:en и др.
- Управление через интерфейс

## Архитектура переводов

```
┌─────────────────────┐
│     Интерфейс       │
│  request.state.t    │
├─────────────────────┤
│   i18n.py           │
│   TRANSLATIONS[ru]  │
│   TRANSLATIONS[en]  │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   entity_label      │
│   language_code     │
│   label, description│
└─────────────────────┘
```

## Текущие проблемы

### 1. Разделение интерфейса
Нет единого механизма. Два параллельных подхода:
- i18n.py для UI-строк
- entity_label для данных сущностей

### 2. Ограничение языков в UI
Интерфейс позволяет работать только с ru/en. Остальные языки (de, fr, es, zh, ja) доступны в entity_label, но не в UI.

### 3. Отсутствие CRUD для переводов
Нет удобного интерфейса для массового управления переводами.

### 4. Мультиязычность в CMS
Страницы CMS (page_registry) не поддерживают мультиязычность по умолчанию.

## Планы

- Единый интерфейс для управления переводами
- Расширение поддержки языков в UI
- Мультиязычность для CMS-страниц
- Автоматические переводы через AI (см. [[plugins/ai-plugin]])

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[database/entity-model]] — Модель сущностей (entity_label)
- [[database/ontology]] — Онтологические модели
- [[frontend/multilingual-ui]] — Мультиязычный интерфейс
- [[plugins/ai-plugin]] — AI для автоматических переводов
