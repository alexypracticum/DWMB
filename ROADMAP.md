# Roadmap

## v0.17.0 — Язык исправлен, план на следующий этап (текущий)

### Выполнено в v0.16.0 — Рефакторинг архитектуры

- [x] UI strings: миграция из сущностей в dedicated таблицы `meta.ui_string` + `meta.ui_string_translation` (663 ключа x 7 языков = 4639 переводов)
- [x] Service Layer: `entity_service.py`, `kind_service.py`, `relation_service.py`
- [x] API Versioning: префикс `/api/v1/` (entities, kinds, relations, search)
- [x] Type hints: для services + API v1
- [x] Accessibility: WCAG AA (skip link, ARIA labels, alt texts, focus styles, reduced motion)
- [x] Language switching: исправлен `_translations_cache_ttl` (1 строка, критический баг)
- [x] 169 тестов

### Что осталось (v0.17.0)

**Приоритет A — Доделать существующее:**
- [ ] Версия в main.py: обновить "0.8.0" → "0.17.0"
- [ ] RU_LABELS в `app/services/layout/helpers.py` — ~50 хардкоженных русских строк для info_table/image_data_row блоков
- [ ] wiki/development/roadmap.md — обновить статус (сейчас v0.9.0)
- [ ] wiki/development/improvements.md — обновить (Приоритет 1 уже выполнен)
- [ ] Тесты: убедиться что 169 тестов проходят в Docker

**Приоритет B — Визуализация:**
- [ ] D3.js/Cytoscape.js граф связей на странице сущности
- [ ] Фильтрация по типам связей

**Приоритет C — Внешние API:**
- [ ] IMDB через OMDb API (заготовки созданы)
- [ ] Wikipedia REST API (заготовки созданы)
- [ ] MusicBrainz API (заготовки созданы)

**Приоритет D — Промышленная:**
- [ ] CI/CD (GitHub Actions)
- [ ] Мониторинг (Prometheus/Grafana)
- [ ] GraphQL subscriptions

---

## v0.16.0 — Рефакторинг архитектуры (выполнено)

### Цель: Разделение приложения и пользовательских данных, нормализация кода

**Разделение данных:**
- [x] Созданы таблицы `ui_string` и `ui_string_translation` (663 ключа)
- [x] Мигрированы UI-строки из сущностей (4639 переводов)
- [x] Обновлён middleware для работы с новыми таблицами

**Service Layer:**
- [x] Создан `entity_service.py` для CRUD сущностей
- [x] Создан `kind_service.py` для управления типами
- [x] Создан `relation_service.py` для управления связями

**API Versioning:**
- [x] Префикс `/api/v1/` для entities, kinds, relations, search

**Типизация:**
- [x] Type hints для services и API v1

**Accessibility:**
- [x] WCAG AA compliance (skip link, ARIA, alt texts, focus styles)

---

## v0.15.0 — RLS, Микросервисы, WebSocket (выполнено)

- [x] RBAC интеграция (require_permission во всех admin роутах)
- [x] Email service (регистрация, сброс пароля)
- [x] Redis кэширование (init_cache при старте)
- [x] GraphQL mutations (createKind, createEntity, updateEntity, deleteEntity, createRelation)
- [x] Геосвязи (entity_geo, /map, Leaflet.js)
- [x] Автосохранение языка (/api/set-language)
- [x] RLS (5 политик на entity)
- [x] Микросервисы (AI=8001, Search=8002, Media=8003)
- [x] WebSocket (/ws endpoint)

---

## v0.12.0 — GraphQL, Docker, Tests (выполнено)

- [x] GraphQL API (strawberry-graphql, sync engine)
- [x] Docker: multi-stage, non-root, healthcheck, .dockerignore, prod override
- [x] 165 тестов, исправлены импорты
- [x] CSRF: cookie + header validation, 27 шаблонов

---

## v0.11.0 — Безопасность и архитектура (выполнено)

- [x] CORS, SSRF, XSS, password validation, SECRET_KEY warnings
- [x] admin.py → 11 подмодулей, entities.py → 4, layout.py → 4
- [x] theme.py кэширование, kinds.py оптимизация
- [x] Плагины: lifecycle hooks, 7 плагинов
- [x] N+1 batch queries, lazy init

---

## v0.9.0 — Полный перевод всех страниц (выполнено)

- [x] Переведены все страницы на 7 языков

---

## v0.8.0 — Полный переход на БД (выполнено)

- [x] i18n.py заменена на language.py + БД

---

## v0.7.0 — Мультиязычность через проекции (выполнено)

- [x] EntityKind "ui_string" → позже заменены на dedicated таблицы

---

## v0.6.0 — Мультиязычность (выполнено)

- [x] meta.language таблица, 7 языков, переключатель

---

## v0.5.0 — Архитектура плагинов, инфраструктура, UI/UX (выполнено)

- [x] Плагины, RBAC, EventLog, Redis, Rate limiting, Email, Версионирование, Комментарии, WYSIWYG, Экспорт, CLI, RSS

---

## v1.0.0 — Промышленная версия (план)

- [ ] D3.js/Cytoscape.js граф связей
- [ ] GraphQL subscriptions
- [ ] CI/CD (GitHub Actions)
- [ ] Мониторинг (Prometheus/Grafana)
- [ ] Внешние API (IMDB, Wikipedia, MusicBrainz)
