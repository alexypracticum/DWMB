# TODO

## Текущий статус: v0.17.0

### Выполнено (v0.17.0) — Локализация, граф, OMDb

**Локализация:**
- [x] Версия в main.py: обновлена до "0.17.0"
- [x] RU_LABELS/EN_LABELS удалены из helpers.py (~50 строк each)
- [x] `get_label()` теперь использует translation cache вместо hardcoded dicts
- [x] field_schema titles заменены на i18n keys (13 типов сущностей, 27 шаблонов)
- [x] edit.html + layout_fields.html переведены (109 ключей × 7 языков)
- [x] /map страница переведена (12 ключей × 7 языков)
- [x] Редактор тем переведён (28 ключей × 7 языков)
- [x] Темы пресетов мультиязычные
- [x] Dark mode toggle доступен для всех (auth + anon)
- [x] 0 hardcoded Russian строк в шаблонах

**Граф связей (Приоритет B):**
- [x] D3.js force-directed граф на странице сущности
- [x] API endpoint `GET /api/v1/relations/graph/{entity_id}`
- [x] Интерактивность: zoom/pan, drag, hover подсветка, клик → переход
- [x] Фильтрация по типам связей с цветовой привязкой к kind
- [x] AJAX загрузка графа

**OMDb / IMDB (Приоритет C):**
- [x] OMDB_API_KEY добавлен в config.py
- [x] search_imdb() и get_imdb_details() — исправлены
- [x] import_imdb_movie() — импорт фильма как сущность
- [x] REST эндпоинты: status, search, movie, import
- [x] UI модалка поиска/импорта на странице создания

**Исправления:**
- [x] CSRF middleware: проверка form body (url-encoded + multipart)
- [x] Импорт manager в crud.py (WebSocket notifications)

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

## Осталось — Приоритет D: Промышленная

- [ ] CI/CD (GitHub Actions)
- [ ] Мониторинг (Prometheus/Grafana)
- [ ] GraphQL subscriptions

## Заметки

- Тесты: 169+ тестов, запуск через Docker (`docker exec dwmb_app python -m pytest tests/`)
- Микросервисы созданы, но не подключены к основному приложению (проксирование не реализовано)
- CLI утилита (cli.py) существует, но не тестировалась
- OMDb API ключ: бесплатный, получить на https://www.omdbapi.com/apikey.aspx
