# Roadmap

## v0.17.0 — Полная локализация и i18n (выполнено)

### Выполнено

- [x] Версия в main.py: обновлена до "0.17.0"
- [x] RU_LABELS/EN_LABELS удалены из helpers.py (~50 строк each)
- [x] `get_label()` теперь использует translation cache вместо hardcoded dicts
- [x] field_schema titles заменены на i18n keys (13 типов сущностей, 27 шаблонов)
- [x] edit.html + layout_fields.html переведены (109 ключей × 7 языков)
- [x] /map страница переведена (12 ключей × 7 языков)
- [x] Редактор тем переведён (28 ключей × 7 языков)
- [x] Темы пресетов мультиязычные (route резолвит имена из request.state.t)
- [x] Dark mode toggle доступен для всех (auth + anon)
- [x] 0 hardcoded Russian строк в шаблонах (кроме entity data и language names)
- [x] 3 коммита за сессию: `ad83ecd`, `a1c9098`, `172c22c`

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

## Следующий этап — Приоритет B: Визуализация

- [ ] D3.js/Cytoscape.js граф связей на странице сущности
- [ ] Интерактивное исследование графа с фильтрацией по типам связей

## Приоритет C: Внешние API

- [ ] IMDB через OMDb API (заготовки созданы)
- [ ] Wikipedia REST API (заготовки созданы)
- [ ] MusicBrainz API (заготовки созданы)

## Приоритет D: Промышленная

- [ ] CI/CD (GitHub Actions)
- [ ] Мониторинг (Prometheus/Grafana)
- [ ] GraphQL subscriptions
