---
type: log
title: "Журнал изменений wiki"
description: "Хронология создания и обновления страниц wiki DWMB"
tags: [log, changelog, history]
date_created: 2026-07-22
date_updated: 2026-07-25
status: stable
---

# Журнал изменений wiki

Хронология создания и обновления страниц wiki [[overview|DWMB]].

## 2026-07-25 (обновление v0.18.0)

### Добавлено (9 новых wiki-страниц)
- `features/workflow.md` — 3-state workflow (draft/published/archived), аудит переходов
- `features/wysiwyg.md` — TipTap v2.6.6 rich text редактор, 13 кнопок, CDN
- `features/backup.md` — pg_dump через CLI, экспорт/импорт сущностей, TMDB импорт
- `development/cli.md` — cli.py: status, seed, stats, backup, restore, migrate
- `architecture/caching.md` — Redis + in-memory fallback, KindsMiddleware cache
- `architecture/security.md` — JWT, bcrypt, RBAC, rate limiting, CORS, SSRF, XSS, CSRF
- `api/graphql.md` — GraphQL API: 7 queries + 5 mutations + 3 subscriptions
- `development/improvements.md` — план улучшений (40 пунктов, 6 этапов)

### Добавлено (admin UI)
- `/admin/event-log` — журнал событий с фильтрами
- `/admin/roles` — CRUD ролей и разрешений
- `/admin/api-settings` — настройки API ключей
- `/admin/email-settings` — настройки SMTP
- `/admin/security` — CORS, rate limit, CSRF, SECRET_KEY
- `/admin/backup` — бэкап/восстановление PostgreSQL

### Исправлено
- Dark mode toggle: удалён дублирующийся маршрут, корректное переключение тем
- `development/architecture-analysis.md` — анализ архитектуры и нормы

### Обновлено
- `overview.md` — v0.10.0 → v0.18.0, 165 → 207 тестов, добавлены внешние API и граф
- `index.md` — добавлены ссылки на 9 новых страниц
- `moc.md` — добавлены GraphQL subscriptions, CI/CD, Last.fm, graph

---

## 2026-07-22 (обновление)

### Исправлено
- Media proxy (`/media/proxy`) — исправлен Internal Server Error (минуты работы)
  - Перенесён перед роутерами для корректного матчинга URL
  - Добавлена поддержка MinIO (boto3) и внешних URL (httpx)
  - URL-реврайт `localhost:9000` → `minio:9000` для Docker-окружения

### Добавлено
- `architecture/entity-migration.md` — План миграции таблиц в сущности (42 страница)
- Wiki обновлена: philosophy/everything-as-entity.md, database/entity-model.md, architecture/data-model.md, database/media.md

### Обновлено (фактические данные)
- `overview.md` — Python 3.12, Redis, TipTap, 47 типов, 71 связь, 100+ эндпоинтов
- `database/entity-model.md` — 47 типов сущностей (актуально из БД)
- `database/relations.md` — 71 тип связей (актуально из БД)
- `database/ontology.md` — 13 моделей, исправлены схемы таблиц
- `architecture/data-model.md` — исправлены схемы ontology_model, ontology_template, field_registry
- `index.md` — 42 страницы, DWMB v0.10.0

---

## 2026-07-22

### Создано (раунд 1 — 28 страниц)

#### Философия
- `philosophy/everything-as-entity.md` — Фундаментальный принцип "Всё как сущность"
- `philosophy/world-models.md` — Модели мира и проекции

#### Архитектура
- `architecture/overview.md` — Обзор архитектуры DWMB
- `architecture/layers.md` — 10 архитектурных слоёв БД
- `architecture/data-model.md` — Полная схема данных

#### База данных
- `database/entity-model.md` — Модель сущностей
- `database/ontology.md` — Онтологические модели
- `database/multilingual.md` — Система мультиязычности
- `database/relations.md` — Семантические связи
- `database/temporal.md` — Версионирование
- `database/media.md` — Медиа-хранилище
- `database/projections.md` — Проекции сущностей

#### API
- `api/rest-api.md` — REST API
- `api/router.md` — Маршрутизация
- `api/search.md` — Поиск

#### Frontend
- `frontend/templates.md` — Шаблоны UI
- `frontend/multilingual-ui.md` — Мультиязычный интерфейс
- `frontend/cms.md` — CMS

#### Плагины
- `plugins/plugins.md` — Обзор плагинов
- `plugins/ai-plugin.md` — AI Plugin

#### Деплой
- `deployment/docker.md` — Docker Compose
- `deployment/environment.md` — Переменные окружения

#### Разработка
- `development/roadmap.md` — Дорожная карта
- `development/testing.md` — Тестирование
- `development/contributing.md` — Вклад в проект

#### Служебные
- `overview.md` — Обзорный документ
- `index.md` — Оглавление
- `log.md` — Этот журнал

---

### Добавлено из dwwiki (раунд 2 — 12 страниц)

#### Функции (features/)
- `features/entity-crud.md` — CRUD сущностей (3-шаговое создание)
- `features/comments.md` — Комментарии с вложенностью
- `features/visual-editor.md` — Визуальный редактор макетов (21+ блоков)
- `features/rbac.md` — RBAC: роли, разрешения, JWT
- `features/admin-panel.md` — Админ-панель (21 шаблон)
- `features/export.md` — Экспорт в Markdown/HTML
- `features/feeds.md` — RSS/Atom фиды

#### Интерфейс (ui/)
- `ui/display-modes.md` — 4 режима отображения (Preview, Grid, List, Table)
- `ui/theme-system.md` — 9 тем + CSS-редактор
- `ui/localization.md` — Локализация на 7 языков

#### База данных
- `database/seed-data.md` — Начальные данные (35 типов, 250+ записей)

#### Архитектура
- `architecture/plugin-system.md` — Система плагинов (PluginBase)

---

### Источники

Все страницы синтезированы из:

**Исходные данные (23 файла):**
- `19.07.2026.ANALYSIS_REPORT.md` — Основной анализ (v2.0 схема)
- `18.07.2027.PLAN.md` — Финальный план реализации
- `20.07.2026.CMS_ANALYSIS.md` — Анализ UI/CMS
- `21.07.2026.MULTILINGUAL_ANALYSIS.md` — Анализ мультиязычности
- `22.07.2026.MIMO.md` — MiMo модель + полный промпт
- `12.07.2026.ПРОМПТЫ.md` — Промпты для AI
- `17.07.2026.ПРОМПТ создания БД.md` — Промпт создания БД
- `19.07.2026.Ответы_на_вопросы.md` — Ответы на вопросы
- `21.07.2026.База данных.md` — Модульная архитектура
- `28.06.2026 OpenCode schema_analysis.md` — Анализ схемы
- `28.06.2026 OpenCode Полный анализ.md` — Полный анализ
- `08.03.2026.Пишем БД c ChatGPT.md` — Начальная архитектура
- `17.05.2026 Ещё одна версия от ChatGPT.md` — Универсальная классификация
- `Задачи.txt` — Текущие задачи

**Из dwwiki (дополнительные страницы):**
- `features/comments-system.md` — Система комментариев
- `features/visual-editor.md` — Визуальный редактор
- `features/rbac-system.md` — RBAC
- `features/entity-crud.md` — CRUD сущностей
- `features/export-system.md` — Экспорт
- `features/feeds.md` — Фиды
- `features/admin-panel.md` — Админ-панель
- `features/ai-integration.md` — AI-интеграция
- `features/tmdb-import.md` — Импорт TMDB
- `features/search-system.md` — Система поиска
- `ui/display-modes.md` — Режимы отображения
- `ui/theme-system.md` — Система тем
- `ui/localization.md` — Локализация
- `database/seed-data.md` — Seed-данные
- `architecture/plugin-system.md` — Система плагинов

### Паттерны

Следующие паттерны использованы при создании wiki:

- **LLMWikiNG** — OKF v0.1, frontmatter, кросс-ссылки
- **ClaudeBrain** — Типы страниц, workflows, conventions
- **Karpathy LLM Wiki** — Структура, синтез из сырых данных

---

*Следующие изменения будут добавлены в журнал при обновлении страниц.*
