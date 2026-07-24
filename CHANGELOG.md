## [0.17.0] — 2026-07-23 (обновление)

### Граф связей (D3.js)

- **API**: `GET /api/v1/relations/graph/{entity_id}` — возвращает nodes + edges + relation_types
- **UI**: D3.js force-directed граф на странице сущности (AJAX загрузка)
- **Интерактивность**: zoom/pan, drag, hover подсветка связей, клик → переход на связанную сущность
- **Фильтры**: по типам связи с цветовой привязкой к kind узла

### OMDb / IMDB интеграция

- **Config**: добавлен `OMDB_API_KEY` в settings и .env.example
- **Service**: исправлены `search_imdb()` и `get_imdb_details()` (OMDB_API_KEY вместо TMDB_API_KEY)
- **Import**: `import_imdb_movie()` — импорт фильма как сущность с полными данными
- **API**: 4 эндпоинта: status, search, movie, import (`/api/import/omdb/*`)
- **UI**: модалка поиска/импорта на странице создания сущности (жёлтая кнопка OMDb)

### Исправления

- **CSRF middleware**: проверка form body (url-encoded + multipart) вместо только заголовка
- **crud.py**: добавлен импорт `manager` из websocket service (NameError при создании сущности)

---

## [0.17.0] — 2026-07-23

### Полная локализация и i18n

- **Версия**: обновлена до 0.17.0
- **RU_LABELS/EN_LABELS удалены**: ~50 хардкоженных строк each убраны из `helpers.py`, `get_label()` теперь использует translation cache
- **field_schema i18n**: русские titles в `entity_kind.field_schema.properties` и `ontology_template.schema_definition.properties` заменены на `field_{key}` ключи (13 типов сущностей, 27 шаблонов)
- **Шаблоны переведены**: edit.html + layout_fields.html (109 ключей × 7 языков)
- **/map страница переведена**: 12 ключей × 7 языков
- **Редактор тем переведён**: 28 ключей × 7 языков
- **Темы пресетов мультиязычные**: route резолвит имена из `request.state.t`
- **Dark mode**: toggle доступен для всех (auth + anon через cookie)
- **0 hardcoded Russian** строк в шаблонах (кроме entity data и language names)

### Инфраструктура (Приоритет D)

- **CI/CD**: GitHub Actions workflows (test.yml, deploy.yml, docker-publish.yml)
- **GraphQL subscriptions**: entityChanged, commentChanged, relationChanged через WebSocket
- **WebSocket event bus**: asyncio.Queue для передачи событий от manager к subscriptions
- **JS клиент**: GraphQLSubscriptions class с auto-reconnect

### OMDb кэширование и rate limiting

- **Кэширование**: поиск OMDb — 1 час, детали фильма — 24 часа (Redis/memory fallback)
- **Rate limiting**: 500ms между запросами к OMDb API

### Коммиты

- `ad83ecd` — RU_LABELS/EN_LABELS удалены, версия 0.17.0
- `a1c9098` — field_schema titles заменены на i18n keys
- `172c22c` — edit.html + layout_fields.html переведены

---

## [0.16.0] — 2026-07-23

### Рефакторинг архитектуры
- **UI strings**: миграция из entity-хранилища в dedicated таблицы `meta.ui_string` + `meta.ui_string_translation` (663 ключа × 7 языков = 4639 переводов)
- **Service Layer**: `entity_service.py`, `kind_service.py`, `relation_service.py` — бизнес-логика вынесена из роутов
- **API Versioning**: `/api/v1/` префикс (entities, kinds, relations, search)
- **Type hints**: добавлены в services и API v1 модули
- **Accessibility**: WCAG AA (skip link, ARIA labels, alt texts, focus styles, reduced motion)

### Исправлено
- **Language switching**: исправлен критический баг — переменная `_translations_cache_ttl` использовалась но не была объявлена в `theme.py`. `NameError` ловился `except Exception`, сбрасывал `request.state.t = {}`, fallback загружал русский для ВСЕХ языков. Исправление: добавлена 1 строка `_translations_cache_ttl = 300` (commit 4bd0ed7)

### Тесты
- 169 тестов (Service Layer, API v1, WebSocket, RLS, UI strings, geo, CSRF, security)

---

## [0.15.0] — 2026-07-23

### Добавлено
- **RBAC интеграция**: require_permission("admin.access") во всех admin роутах
- **Email service**: отправка email при регистрации, forgot-password/reset-password endpoints
- **Redis кэширование**: init_cache() при старте приложения
- **GraphQL mutations**: createKind, createEntity, updateEntity, deleteEntity, createRelation
- **Геосвязи**: entity_geo таблица, lat/lng координаты, /map страница с Leaflet.js
- **Внешние API**: Wikipedia, MusicBrainz, IMDB (OMDb) — заготовки созданы, требуют доработки
- **Автосохранение языка**: /api/set-language endpoint для AJAX
- **RLS (Row-Level Security)**: 5 политик на таблице entity
- **Микросервисы**: AI Service (порт 8001), Search Service (порт 8002), Media Service (порт 8003)
- **WebSocket**: /ws endpoint для real-time уведомлений

### Исправлено
- **GraphQL**: исправлены entity/search запросы с sync engine
- **Навигация**: добавлена кнопка "Карта" с переводами на 7 языков
- **Карта**: исправлена загрузка Leaflet.js (добавлен block head в base.html)
- **Тема middleware**: загрузка переводов для неаутентифицированных пользователей

### Улучшения
- **Архитектура**: разделение приложения и пользовательских данных
- **Безопасность**: RLS для multi-user доступа
- **Производительность**: микросервисы для масштабирования

---

## [0.12.0] — 2026-07-22

### Добавлено
- **CSRF защита**: middleware + JS хелпер для форм
- **GraphQL API**: strawberry-graphql с 7 запросами (stats, kinds, models, relationTypes, entities, entity, search)
- **Docker optimization**: multi-stage, non-root user, healthcheck, .dockerignore, resource limits
- **Tests**: 165 тестов (было 125), исправлены устаревшие импорты
- **Documentation**: обновлены ROADMAP, TODO, CHANGELOG

### Исправлено
- **CSRF**: добавлена защита на все POST формы (27 шаблонов)
- **GraphQL**: исправлены синтаксические ошибки в queries.py
- **Docker**: добавлен healthcheck, убран --reload для production

### Улучшения
- **Security**: CORS, SSRF, XSS, CSRF, password validation
- **Architecture**: language_service, split admin/entities/layout
- **Middleware**: caching in theme.py, optimized kinds.py
- **Plugins**: lifecycle hooks, 7 plugins loaded
- **Performance**: batch queries, lazy init

---

## [0.11.0] — 2026-07-22

### Безопасность
- **CORS**: заменён `allow_origins=["*"]` на `settings.CORS_ORIGINS` (только localhost)
- **SSRF**: добавлена валидация URL в media_proxy (блокировка internal IPs, limit 10MB)
- **XSS**: добавлен `html.escape()` в HTML export (title, description, fields)
- **Пароли**: добавлена валидация при регистрации (≥8 символов, заглавная, строчная, цифра)
- **SECRET_KEY**: добавлены предупреждения при default/коротком ключе
- **Роуты**: зарегистрированы import_api и ai роуты

### Архитектура (реструктуризация)
- **language_service.py**: общие утилиты (get_kind_label, entity_label_filter, get_lang_ids)
- **admin.py**: разбит на 11 подмодулей (2391 → 11 файлов)
- **entities.py**: разбит на 4 подмодуля (1721 → 4 файла)
- **layout.py**: разбит на 4 подмодуля (973 → 4 файла)
- **Удалено дублирование**: 3 копии `_get_kind_label`, 11+ копий `or_clauses`
- **Исправлены bare except**: все заменены на конкретные типы исключений
- **Убраны debug print**: из middleware/kinds.py

### Middleware
- **theme.py**: добавлено кэширование (user, lang, translations, theme — 5 мин TTL)
- **kinds.py**: оптимизирован с language_service
- **rate_limit.py**: исправлен handler (get_rate_limit → rate_limit_exceeded_handler)

### Плагины
- **Интеграция**: добавлен `load_plugins(app)` в main.py
- **Lifecycle hooks**: добавлены `on_startup()` / `on_shutdown()` в PluginBase
- **Загружены**: 7 плагинов (ai, cms, email, rbac, stats, themes, tmdb)

### Производительность
- **N+1 queries**: добавлена `get_kind_labels_batch()` для batch-получения labels
- **Lazy init**: StorageService и AIService инициализируются при первом обращении

### Удалён мёртвый код
- `app/services/i18n.py` (DEPRECATED)
- `app/models/pages.py` (пустой)

---

# Changelog

## [0.10.0] — 2026-07-22

### Философия "Всё как сущность"
- **page_registry → entity**: CMS страницы мигрированы в entity kind='page'
- **media_asset → entity CRUD**: загрузка файлов создаёт entity kind='digital_file'
- **MenuItem**: удалён мёртвый код (не использовался ни в одном маршруте)

### Миграции
- Migration 009: page_registry → entity (entity_kind='page', ontology_model='cms')
- Migration 010: entity_kind='digital_file', ontology_model='storage'

### API
- `GET /media/{asset_id}` — метаданные media asset
- `GET /media/{asset_id}/info` — детальная информация через entity projection
- `DELETE /media/{asset_id}` — удаление media asset и entity
- Upload создаёт entity kind='digital_file' для ВСЕХ файлов (не только изображений)

### Исправлено
- Удалён баг: `EntityProjection.is_current` не существует в БД (убран из кода)
- Обновлена схема entity_projection в wiki (убран is_current)
- Media proxy (`/media/proxy`) — исправлен Internal Server Error (минуты работы)
  - Перенесён перед роутерами для корректного матчинга URL
  - Добавлена поддержка MinIO (boto3) и внешних URL (httpx)
- Template editor: исправлен JS-синтаксис (отсутствующий `+`, несовпадающие кавычки в alert), блоки теперь рендерятся

### Wiki
- Обновлён статус философии "Всё как сущность"
- Добавлен раздел "Компромисс: media_asset как sidecar" в database/media.md
- Исправлено количество entity_kind (40+ вместо 160+)

---

## [0.9.0] — 2026-07-21

### Исправлено
- 3 сломанные страницы: /admin/pages, /stats, /admin/ai (зарегистрированы роутеры, восстановлен шаблон)
- Сохранение переводов в admin/ui-translations (добавлен фильтр по языку)
- Центрирование страницы сущности (max-w-6xl)

### Добавлено
- 114 новых ключей перевода для admin страниц (ru/en)
- Переведены 11 шаблонов (~116 замен русского текста на {{ request.state.t.key }})
- Seed-скрипт 04_admin_ui_strings.py для создания ключей

### Переведены страницы
- Entity list: поиск, сортировка, виды, таблица
- Entity detail: хлебные крошки, кнопки, секции, комментарии
- Admin: fields, templates, models, kinds, relation-types, users, plugins, languages, ui-translations

---

## [0.8.0] — 2026-07-21

### Добавлено
- CRUD для создания новых UI-строк в admin panel
- CRUD для удаления UI-строк
- Экспорт переводов в JSON (/admin/ui-translations/export)
- Импорт переводов из JSON (/admin/ui-translations/import)
- Кнопки экспорта/импорта в шаблоне UI переводов

### Изменено
- i18n.py заменена на обёртку (обратная совместимость)
- Все импорты обновлены: language.py вместо i18n.py
- Middleware theme.py: загрузка из БД exclusively
- Тесты обновлены (20 тестов)

---

## [0.7.0] — 2026-07-21

### Добавлено
- EntityKind "ui_string" для хранения UI-строк как сущностей
- OntologyTemplate "ui_translation" с полями key, value (multilingual)
- Миграция 008: создание ui_string сущностей и шаблона
- Seed-скрипт 03_ui_translations.py: миграция 269 переводов из i18n.py в сущности
- Сервис ui_translations.py: чтение переводов из БД с кэшированием
- CRUD для управления UI переводами в admin panel (/admin/ui-translations)
- Шаблон ui_translations.html с табами языков и inline-редактированием
- 269 UI-строк с мультиязычными проекциями (7 языков x 269 ключей)

### Изменено
- Middleware theme.py: загрузка переводов из БД с fallback на i18n.py
- Admin dashboard: добавлена ссылка "UI Переводы"

---

## [0.6.1] — 2026-07-21

### Добавлено
- Перевод кнопки "Языки" в admin dashboard на 7 языков
- Перевод блока "Пользователи" (таблица: Имя, Email, Роль, Статус, Действия)
- Перевод статусов пользователей (активен/заблокирован)
- Перевод кнопок действий (Снять admin/Сделать admin, Заблокировать/Разблокировать)
- 13 новых ключей перевода x 7 языков в i18n.py

---

## [0.6.0] — 2026-07-21

### Добавлено
- Таблица meta.language — динамический справочник языков (замена ENUM language_code)
- Переводы интерфейса на 7 языков: русский, английский, немецкий, французский, испанский, китайский, японский
- Переключатель языков в навигации с флагами (7 языков)
- CRUD для языков в админ-панели (список, создание, редактирование, удаление)
- Миграция 007: замена ENUM language_code на FK language_id в EntityLabel, EntityKindLabel, FieldRegistryLabel, UserAccount
- ORM модель Language для работы со справочником языков
- Сервис language.py с кэшированием и вспомогательными функциями
- 21 тест мультиязычности (переводы, переключение, модели)

### Изменено
- EntityLabel.language → EntityLabel.language_id (UUID FK → language table)
- EntityKindLabel.language → EntityKindLabel.language_id (UUID FK → language table)
- FieldRegistryLabel.language → FieldRegistryLabel.language_id (UUID FK → language table)
- UserAccount.language_preference → UserAccount.language_id (UUID FK → language table)
- Middleware theme.py: получение языка через FK language_id
- Middleware kinds.py: запросы с использованием language_id
- Все маршруты (entities, admin, search, editor_api, import_api, profile) обновлены для работы с FK
- set-lang route: поддержка всех 7 языков

### Исправлено
- Тест test_i18n_service.py: обновлён для поддержки новых языков

---

## [0.5.2] — 2026-07-20

### Добавлено
- Изображение как базовая часть сущности: image_url в таблице entity
- AI Конфигурация: несколько профилей с переключением (AiConfigProfile)
- Страница управления плагинами (/admin/plugins)
- Блок "Галерея актёров-персонажей" со спойлером и фото
- Мультиязычность: добавление меток на разных языках (RU, EN, DE, FR, ES, ZH, JA)
- Язык как сущность: EntityKind "language" + 7 языков (ru, en, de, fr, es, zh, ja)
- Классификаторы: ISO 639-1, ISO 639-2, ГОСТ 7.75-97
- 3 новых SQL-миграции (entity_image, ai_profiles, languages)

### Исправлено
- Ошибка сохранения сущности (UnboundLocalError в entity_detail)
- Блок "Галерея актёров" не отображал фото (добавлен image_url в relations)
- Добавлены ссылки на профили AI и плагины в админке

---

## [0.5.1] — 2026-07-20

### Исправлено
- AI Конфигурация: выравнивание по центру (max-w-3xl mx-auto)
- List view: исправлен overflow за правое меню (overflow-hidden + min-w-0)
- Левое меню: показывает названия вместо кодов (FIX: порядок middleware Theme→Kinds + шаблон request.state.kinds)

---

## [0.5.0] — 2026-07-20

### Добавлено
- Архитектура плагинов: PluginBase, load_plugins(), 7 плагинов
- RBAC: роли (admin/editor/viewer), 13 разрешений, require_permission()
- EventLog: аудит-журнал create/update/delete/relation_change
- Вид "Превью" с постерами (3:4 aspect ratio) на странице списка
- SEO-поля: meta_title, meta_description, og_image для сущностей
- Redis кэширование с in-memory fallback (5 мин TTL для kinds)
- Rate limiting: slowapi middleware (200/min, 10/min auth)
- Email service: aiosmtplib, отправка писем (verification, password reset)
- Версионирование: страница /entity/{id}/history с событиями
- Workflow: draft/published/archived состояния с кнопками переходов
- Комментарии: модель Comment, CRUD, вложенность, ответы
- WYSIWYG: TipTap редактор с тулбаром (bold, italic, headings, lists, links)
- Экспорт: скачивание Markdown и HTML файлов
- API документация: Swagger annotations для всех endpoints
- CLI утилита: status, seed, stats, backup, restore, migrate
- RSS/Atom фиды: /feed/entities, /feed/pages
- Backup: pg_dump через CLI (timestamped SQL files)
- 3 новых SQL-миграции (RBAC, workflow, comments)

### Исправлено
- SQL-инъекция в TMDB импорте (ORM вместо raw SQL)
- Rate limit (429) обработка с retry/backoff для TMDB API
- Deprecated on_event → lifespan context manager
- i18n: 19 хардкодов language="ru" заменены на request.state.lang

### Улучшено
- Боковое меню и выпадающий список показывают переведённые названия типов
- Страница создания сущности растягивается по ширине экрана
- Grid/list/table виды с сохранением в localStorage

---

## [0.4.3] — 2026-07-20

### Исправлено
- SQL-инъекция в TMDB импорте (ORM вместо raw SQL)
- Обработка rate limit (429) с retry/backoff для TMDB API
- Логирование TMDB запросов и ошибок

### Добавлено
- Выбор вида отображения (плитки/список/таблица) на страницах списка, поиска и главной
- Сортировка и масштабирование на странице списка сущностей
- Сохранение предпочтений вида в localStorage
- 11 новых unit-тестов для TMDB импорта

### Улучшено
- i18n: названия типов сущностей отображаются на языке пользователя
- Страница создания сущности растягивается по ширине экрана
- Боковое меню и выпадающий список показывают переведённые названия типов

---

## [0.4.1] — 2026-07-19

### Добавлено
- Метаданные связей: role, confidence, weight в UI и API
- CRUD для RelationType через UI (список, создание, редактирование, удаление)
- Кнопка "Связи" в админ-панели
- Тесты: 54 unit-теста

### Улучшено
- Упрощение модели связей: убраны directionality и symmetric_relation
- Ненаправленные связи через inverse_type_id = self (без дублей)
- Направленные связи всегда создают пару (прямая + обратная)

---

## [0.4.0] — 2026-07-19

### Добавлено
- Редактор связей в UI
- Безопасность для GitHub (.env, .gitignore, env_file)
- Конвертация онтологий в сущности

---

## [0.3.0] — 2026-07-19

### Добавлено
- CRUD для OntologyModel и EntityKind
- Мультиязычные переводы (ru/en)
- Поддержка нескольких проекций

---

## [0.2.0] — 2026-07-19

### Добавлено
- i18n система
- AI-страница конфигурации
- Тестовая инфраструктура

---

## [0.1.0] — 2026-07-17

### Начальный релиз
- Базовый CRUD сущностей
- Система типов с JSON Schema
- Авторизация, админ-панель, поиск
