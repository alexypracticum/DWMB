---
type: development
title: "Вклад в проект"
description: "Руководство по внесению вклада в DWMB: код-стайл, PR, issues, архитектурные решения"
tags: [development, contributing, guidelines, pr]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 18.07.2027.PLAN.md
  - 22.07.2026.MIMO.md
status: stable
---

# Вклад в проект

Руководство по внесению вклада в [[architecture/overview|DWMB]].

## Код-стайл

### Python

- Следовать PEP 8
- Использовать type hints
- Docstrings для всех публичных функций
- Форматирование: black
- Линтинг: ruff

### SQL

- Имена таблиц: snake_case
- Имена колонок: snake_case
- UUID для первичных ключей
- TIMESTAMPTZ для дат

### HTML/JS

- Jinja2 шаблоны
- Tailwind CSS классы
- HTMX для интерактивности

## Ветвление

```
main — стабильная версия
├── develop — разработка
│   ├── feature/xxx — новые фичи
│   ├── fix/xxx — исправления
│   └── refactor/xxx — рефакторинг
└── release/xxx — релизы
```

## Pull Request

### 1. Fork и clone

```bash
git clone https://github.com/your-username/DWMB.git
cd DWMB
git remote add upstream https://github.com/original/DWMB.git
```

### 2. Создание ветки

```bash
git checkout -b feature/my-feature develop
```

### 3. Изменения

- Следовать код-стайлу
- Добавлять тесты
- Обновлять документацию

### 4. Коммиты

```bash
git commit -m "feat: add entity CRUD API"
git commit -m "fix: resolve pagination issue"
git commit -m "docs: update API documentation"
```

### 5. Push и PR

```bash
git push origin feature/my-feature
```

Создать PR в `develop`分支.

## Формат коммитов

| Префикс | Описание |
|---------|----------|
| feat: | Новая фича |
| fix: | Исправление бага |
| docs: | Документация |
| style: | Форматирование |
| refactor: | Рефакторинг |
| test: | Тесты |
| chore: | Сборка/инструменты |

## Issues

### Баги

```markdown
**Описание:** Краткое описание бага

**Шаги для воспроизведения:**
1. Открыть ...
2. Нажать ...
3. Увидеть ошибку

**Ожидаемое поведение:** ...

**Фактическое поведение:** ...
```

### Новые фичи

```markdown
**Описание:** Краткое описание фичи

**Мотивация:** Зачем нужна эта фича

**Реализация:** Как предлагаете реализовать
```

## Архитектурные решения

Для крупных изменений создавать ADR (Architecture Decision Record):

```markdown
# ADR-001: Название решения

## Статус
Принято / Отклонено / Заменено

## Контекст
Описание проблемы

## Решение
Описание решения

## Последствия
Положительные и отрицательные
```

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[development/roadmap]] — Дорожная карта
- [[development/testing]] — Тестирование
- [[deployment/docker]] — Настройка окружения
