---
type: plugin
title: "AI Plugin"
description: "Интеграция с LLM: OpenAI, Anthropic, Google — профили, анализ, генерация, кеширование"
tags: [plugin, ai, llm, openai, anthropic]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 12.07.2026.ПРОМПТЫ.md
  - 22.07.2026.MIMO.md
  - 19.07.2026.ANALYSIS_REPORT.md
  - 19.07.2026.Ответы_на_вопросы.md
status: stable
---

# AI Plugin

Интеграция с языковыми моделями (LLM) в [[architecture/overview|DWMB]]: профили подключения, анализ сущностей, генерация контента.

## Архитектура

```
┌─────────────────────────────────────────────┐
│              AI Plugin                       │
├─────────────────────────────────────────────┤
│  ai_profile      │  Профили подключения     │
│  ai_analysis     │  Результаты анализа      │
│  ai_cache        │  Кеш результатов         │
├─────────────────────────────────────────────┤
│  Providers:                                  │
│  - OpenAI (GPT-4, GPT-3.5)                 │
│  - Anthropic (Claude)                       │
│  - Google (Gemini)                          │
│  - MiMo (custom)                            │
└─────────────────────────────────────────────┘
```

## Модели данных

### ai_profile

```sql
CREATE TABLE ai_profile (
    profile_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider    TEXT NOT NULL,      -- 'openai', 'anthropic', 'google', 'mimo'
    model       TEXT NOT NULL,      -- 'gpt-4', 'claude-3', etc.
    config      JSONB DEFAULT '{}'::jsonb,
    is_default  BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

### ai_analysis

```sql
CREATE TABLE ai_analysis (
    analysis_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id    UUID NOT NULL,
    profile_id   UUID REFERENCES ai_profile(profile_id),
    prompt       TEXT,
    result       JSONB,
    tokens_used  INTEGER,
    created_at   TIMESTAMPTZ DEFAULT now()
);
```

### ai_cache

```sql
CREATE TABLE ai_cache (
    cache_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id   UUID NOT NULL,
    prompt_hash TEXT NOT NULL,
    result      JSONB,
    expires_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ DEFAULT now()
);
```

## Функции

### 1. Анализ сущностей

AI анализирует сущности и генерирует:
- Описания
- Теги
- Категории
- Связи

### 2. Генерация контента

- Описания для сущностей
- Переводы
- Резюме
- Анализ

### 3. Автоматические переводы

Генерация переводов для:
- UI-строк
- Меток сущностей
- Описаний

### 4. Кеширование

Кеш результатов для:
- Уменьшения стоимости
- Ускорения отклика
- Повторного использования

## Промпты

### Промпт для полного проекта

Используется для генерации архитектуры и кода:

```markdown
DWMB (Dynamic World Meta-Base) v0.9.0

Stack: Python 3.11+, FastAPI, PostgreSQL 16 + pgvector + pg_trgm, MinIO (S3),
Jinja2 + Tailwind CSS + HTMX, Docker Compose.

Philosophy: "Всё как сущность"
...
```

### Промпты для анализа

- Анализ сущности
- Генерация описания
- Определение связей
- Классификация

## Статус реализации

| Функция | Статус |
|---------|--------|
| Профили подключения | Реализовано |
| Анализ сущностей | Реализовано |
| Генерация описаний | Реализовано |
| Автоматические переводы | Реализовано |
| Кеширование | Реализовано |
| MiMo модель | Реализовано |

## Проблемы

### 1. Две страницы для AI

Существует две страницы для управления AI и профилями.

**Решение из Задачи.txt:** объединить в одну страницу — сверху настройка и сохранение профиля, снизу список профилей и управление ими.

### 2. Ограниченная выборка моделей

Нет возможности выбирать из широкого спектра моделей.

### 3. Нет оценки качества

Нет механизма оценки качества ответов AI.

## Планы

- Объединение страниц AI
- Расширение поддержки моделей
- Оценка качества ответов
- Управление токенами и стоимостью
- Batch-обработка

## Связанные страницы

- [[plugins/plugins]] — Обзор плагинов
- [[database/multilingual]] — AI для переводов
- [[database/entity-model]] — Анализ сущностей
- [[api/rest-api]] — API для AI
