# Roadmap

## v0.5.1 — Исправления (выполнено)

### Цель: Исправление UI багов

**Исправлено:**
- [x] AI Конфигурация: выравнивание по центру (max-w-3xl mx-auto)
- [x] List view: исправлен overflow за правое меню (overflow-hidden + min-w-0)
- [x] Левое меню: показывает названия вместо кодов (FIX: порядок middleware + шаблон)

---

## v0.5.0 — Архитектура плагинов, инфраструктура, UI/UX (выполнено)

### Фаза 1: Ядро + инфраструктура
- [x] Архитектура плагинов: PluginBase, load_plugins(), 7 плагинов
- [x] RBAC: роли (admin/editor/viewer), 13 разрешений, dependency injection
- [x] EventLog: аудит create/update/delete/relation_change
- [x] SQL-инъекция: ORM вместо raw SQL в TMDB импорте
- [x] Retry/backoff для TMDB API (обработка 429)
- [x] Логирование TMDB запросов и ошибок

### Фаза 2: UI-улучшения
- [x] Вид "Превью" с постерами (3:4 aspect ratio)
- [x] Убран entity_code из grid/list видов
- [x] SEO-поля: meta_title, meta_description, og_image
- [x] Collapsible SEO секция в редакторе

### Фаза 3: Инфраструктура
- [x] Redis кэширование с in-memory fallback
- [x] Rate limiting (slowapi): 200/min default, 10/min auth
- [x] Email service (aiosmtplib): verification, password reset

### Фаза 4: Контент
- [x] Версионирование с UI: страница истории сущности
- [x] Workflow: draft/published/archived состояния
- [x] Комментарии: CRUD, вложенность, ответы

### Фаза 5: Расширения
- [x] WYSIWYG: TipTap редактор с тулбаром
- [x] Экспорт: Markdown и HTML файлы
- [x] API документация: Swagger annotations

### Фаза 6: Опциональное
- [x] CLI утилита: status, stats, backup, restore, migrate
- [x] RSS/Atom фиды: /feed/entities, /feed/pages
- [x] Backup: pg_dump через CLI

---

## v0.6.0 — Следующий этап (планирование)

### Цель: Визуализация, дополнительные источники

**Визуализация связей**
- [ ] D3.js или Cytoscape.js граф
- [ ] Граф связей на странице сущности
- [ ] Фильтрация по типам связей

**Дополнительные источники**
- [ ] IMDB через OMDb API
- [ ] Wikipedia API
- [ ] MusicBrainz API

---

## v1.0.0 — Промышленная версия

### Цель: Микросервисы + GraphQL + RLS

- [ ] Микросервисы (AI, поиск, медиа)
- [ ] GraphQL API
- [ ] Row-Level Security
