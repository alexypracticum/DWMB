# TODO

## Текущий статус: v0.16.0 (рефакторинг завершён)

### Выполнено (v0.16.0) — Рефакторинг архитектуры
- [x] UI strings: миграция в dedicated таблицы (663 ключа x 7 языков)
- [x] Service Layer: entity_service, kind_service, relation_service
- [x] API Versioning: /api/v1/ (entities, kinds, relations, search)
- [x] Type hints для services и API v1
- [x] Accessibility WCAG AA (skip link, ARIA, alt texts, focus styles)
- [x] Исправлен language switching bug (_translations_cache_ttl)
- [x] 169 тестов

### Выполнено (v0.15.0) — RLS, Микросервисы, WebSocket
- [x] RBAC: require_permission("admin.access") во всех admin роутах
- [x] Email: send_verification_email, forgot-password, reset-password
- [x] Redis: init_cache() при старте
- [x] GraphQL mutations: createKind, createEntity, updateEntity, deleteEntity, createRelation
- [x] Геосвязи: entity_geo, /map, Leaflet.js
- [x] Автосохранение языка: /api/set-language
- [x] RLS: 5 политик на entity
- [x] Микросервисы: AI (8001), Search (8002), Media (8003)
- [x] WebSocket: /ws endpoint

### Выполнено (v0.12.0) — GraphQL, Docker, Tests
- [x] GraphQL API (strawberry-graphql, sync engine, psycopg2)
- [x] Docker: multi-stage, non-root, healthcheck, .dockerignore, prod override
- [x] CSRF: cookie + header validation, 27 шаблонов
- [x] 165 тестов

### Выполнено (v0.11.0) — Безопасность и архитектура
- [x] CORS, SSRF, XSS, password validation
- [x] admin.py → 11 модулей, entities.py → 4, layout.py → 4
- [x] theme.py кэширование, kinds.py оптимизация
- [x] Плагины: lifecycle hooks, 7 плагинов
- [x] N+1 batch queries, lazy init

### Выполнено (ранее)
- [x] v0.9.0: Полный перевод всех страниц на 7 языков
- [x] v0.8.0: Переход с i18n.py на БД
- [x] v0.6.0: Мультиязычность (meta.language, 7 языков)
- [x] v0.5.0: Плагины, RBAC, Redis, Rate limiting, Email, Версионирование, Комментарии, WYSIWYG, CLI

---

## Осталось — Приоритет A: Доделать существующее

- [ ] Версия в main.py: "0.8.0" → "0.17.0"
- [ ] RU_LABELS в helpers.py: ~50 хардкоженных русских строк (info_table, image_data_row блоки)
- [ ] wiki/development/roadmap.md: обновить статус v0.9.0 → актуальный
- [ ] wiki/development/improvements.md: Приоритет 1 (RBAC, Email, Redis, GraphQL) — все выполнены

## Осталось — Приоритет B: Визуализация

- [ ] D3.js/Cytoscape.js граф связей на странице сущности
- [ ] Интерактивное исследование графа
- [ ] Фильтрация по типам связей

## Осталось — Приоритет C: Внешние API

- [ ] IMDB через OMDb API (заготовки в external_apis.py)
- [ ] Wikipedia REST API (заготовки в external_apis.py)
- [ ] MusicBrainz API (заготовки в external_apis.py)
- [ ] GraphQL резолверы для внешних API (external.py)

## Осталось — Приоритет D: Промышленная

- [ ] CI/CD (GitHub Actions)
- [ ] Мониторинг (Prometheus/Grafana)
- [ ] GraphQL subscriptions

## Заметки

- Тесты: 169 тестов, запуск через Docker (`docker exec dwmb_app python -m pytest tests/`)
- Баг с языком исправлен: `_translations_cache_ttl` не была объявлена → NameError → except → пустой dict → fallback на русский
- RU_LABELS в helpers.py — вторичная проблема (info_table/image_data_row блоки), основной UI теперь работает
- Микросервисы созданы, но не подключены к основному приложению (проксирование не реализовано)
- CLI утилита (cli.py) существует, но не тестировалась
