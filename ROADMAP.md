# Roadmap

## v0.18.0 — Внешние API, граф, подписки, CI/CD (выполнено)

### Внешние API

- [x] Last.fm интеграция (12 API эндпоинтов, виджет "Часто слушаю", кросс-референс с MusicBrainz)
- [x] Wikipedia API (поиск, импорт описаний, кэш 1ч, rate limit 500ms)
- [x] MusicBrainz API (поиск, детали, импорт, кэш 1ч, rate limit 1sec)
- [x] OMDb кэширование (поиск 1ч, детали 24ч) + rate limiting (500ms)

### Граф связей

- [x] Поиск по графу: расширенный поиск с учётом связей (`/api/v1/search/graph`)
- [x] Экспорт графа: скачивание как PNG/SVG/JSON
- [x] Тёмная тема для графа (адаптация D3.js под dark mode)

### GraphQL

- [x] Subscriptions: entityChanged, commentChanged, relationChanged через WebSocket
- [x] JS клиент: GraphQLSubscriptions class с auto-reconnect

### Инфраструктура

- [x] CI/CD: GitHub Actions (test.yml, deploy.yml, docker-publish.yml)
- [x] Toast-уведомления (window.showToast) при изменениях через subscriptions
- [x] Email подтверждение при регистрации
- [x] CRUD пользователей (создание, редактирование, удаление, роли)

### Исправления

- [x] CSRF: form body validation (url-encoded + multipart)
- [x] manager import в crud.py (NameError при создании сущности)

### Тесты

- [x] 207 тестовых функций (37 файлов)

---

## v0.17.0 — Локализация, граф, OMDb, инфраструктура (выполнено)

### Локализация и i18n

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

### Граф связей (Приоритет B)

- [x] D3.js force-directed граф на странице сущности
- [x] API endpoint `GET /api/v1/relations/graph/{entity_id}`
- [x] Интерактивность: zoom/pan, drag, hover подсветка, клик → переход
- [x] Фильтрация по типам связей с цветовой привязкой к kind
- [x] AJAX загрузка графа (асинхронно)

### OMDb / IMDB (Приоритет C)

- [x] `OMDB_API_KEY` добавлен в config.py и .env.example
- [x] `search_imdb()` и `get_imdb_details()` — исправлены на OMDB_API_KEY
- [x] `import_imdb_movie()` — импорт фильма как сущность с данными
- [x] REST эндпоинты: status, search, movie, import
- [x] UI модалка поиска/импорта на странице создания сущности
- [x] Кэширование OMDb: поиск 1 час, детали 24 часа (Redis/memory)
- [x] Rate limiting OMDb: 500ms между запросами

### Инфраструктура (Приоритет D)

- [x] CI/CD: GitHub Actions (test.yml, deploy.yml, docker-publish.yml)
- [x] GraphQL subscriptions: entityChanged, commentChanged, relationChanged
- [x] WebSocket event bus для subscriptions
- [x] JS клиент GraphQL subscriptions с auto-reconnect

### Исправления

- [x] CSRF middleware: проверка form body (url-encoded + multipart)
- [x] Импорт `manager` в crud.py (WebSocket notifications)
- [x] Исправлен label priority в info_table (config label > get_label)

---

## v0.16.0 — Рефакторинг архитектуры (выполнено)

- [x] UI strings: миграция в dedicated таблицы (663 ключа x 7 языков)
- [x] Service Layer: entity_service, kind_service, relation_service
- [x] API Versioning: /api/v1/
- [x] Type hints для services и API v1
- [x] Accessibility WCAG AA
- [x] Исправлен language switching bug

---

## v0.15.0 — RLS, Микросервисы, WebSocket (выполнено)

- [x] RBAC, Email, Redis, GraphQL mutations, Геосвязи, RLS, WebSocket

---

## v0.12.0 — GraphQL, Docker, Tests (выполнено)

- [x] GraphQL API, Docker, CSRF, 165 тестов

---

## v0.11.0 — Безопасность и архитектура (выполнено)

- [x] CORS, SSRF, XSS, реструктуризация, плагины, оптимизация

---

## Дальнейшие улучшения

### Функциональные

- [x] Wikipedia API: поиск и импорт описаний
- [x] MusicBrainz API: поиск музыкальных данных (кэш + rate limit)
- [x] Last.fm интеграция: импорт истории прослушиваний, виджет "Часто слушаю" + кросс-референс MusicBrainz
- [x] Поиск по графу: расширенный поиск с учётом связей (режим "Поиск по графу" в UI + API /api/v1/search/graph)
- [x] Экспорт графа: скачивание как PNG/SVG/JSON

### Технические

- [x] Тесты покрытие: добавлены тесты для графа (12), OMDb, Wikipedia, MusicBrainz
- [x] API документация: OpenAPI аннотации, теги, Swagger UI (/api/docs), ReDoc (/api/redoc)

### UI/UX

- [x] Личный кабинет: профиль, история импортов, избранное (/dashboard/)
- [x] Email подтверждение: верификация при регистрации, повторная отправка, статус в профиле
- [x] CRUD пользователей: создание, редактирование, удаление, ролевая модель (admin/editor/viewer)
- [x] Уведомления в UI: toast-уведомления (window.showToast)
- [x] Тёмная тема для графа: адаптация под dark mode

### Продакшен (отложить)

- [ ] Мониторинг (Prometheus/Grafana)
