# Roadmap

## v0.5.2 — Функциональность (выполнено)

### Цель: Расширение функциональности

**Добавлено:**
- [x] Изображение как базовая часть сущности: image_url в таблице entity
- [x] AI Конфигурация: несколько профилей с переключением
- [x] Страница управления плагинами (/admin/plugins)
- [x] Блок "Галерея актёров-персонажей" со спойлером и фото
- [x] Мультиязычность: добавление меток на разных языках (RU, EN, DE, FR, ES, ZH, JA)
- [x] Язык как сущность: EntityKind "language" + 7 языков
- [x] Классификаторы: ISO 639-1, ISO 639-2, ГОСТ 7.75-97

---

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

## v0.6.0 — Мультиязычность (выполнено)

### Цель: Динамическая мультиязычность без ограничения количества языков

**Мультиязычность (приоритет)**
- [x] Замена ENUM language_code на таблицу meta.language (динамический справочник)
- [x] Миграция EntityLabel, EntityKindLabel, FieldRegistryLabel, UserAccount на FK language_id
- [x] Переводы интерфейса на 7 языков (ru, en, de, fr, es, zh, ja)
- [x] Переключатель языков в навигации (7 языков с флагами)
- [x] CRUD для языков в админ-панели (создание, редактирование, удаление)
- [x] Тесты мультиязычности (26 тестов)

**Осталось (v0.6.1)**
- [ ] Автосохранение при переключении языков
- [ ] Отображение данных сущностей на языке пользователя

**Визуализация связей**
- [ ] D3.js или Cytoscape.js граф
- [ ] Граф связей на странице сущности
- [ ] Фильтрация по типам связей

**Дополнительные источники**
- [ ] IMDB через OMDb API
- [ ] Wikipedia API
- [ ] MusicBrainz API

---

## v0.6.1 — Перевод admin panel (выполнено)

### Цель: Перевод интерфейса администратора

**Добавлено:**
- [x] Перевод кнопки "Языки" в admin dashboard
- [x] Перевод блока "Пользователи" (таблица, статусы, действия)
- [x] Новые ключи перевода для admin panel (13 ключей x 7 языков)

---

## v0.9.0 — Полный перевод всех страниц (выполнено)

### Цель: Перевести все захардкоженные русские строки на 7 языков

**Реализовано:**
- [x] Исправлены 3 сломанные страницы (/admin/pages, /stats, /admin/ai)
- [x] Исправлено сохранение переводов в admin/ui-translations (фильтр по языку)
- [x] Создано 114 новых ключей перевода для admin страниц
- [x] Обновлены 11 шаблонов (~116 замен русского текста)
- [x] Исправлено центрирование страницы сущности (max-w-6xl)
- [x] Переведены: entity list, entity detail, admin fields/templates/models/kinds/relation-types/users/plugins/languages/ui-translations

---

## v0.8.0 — Полный переход на БД (выполнено)

### Цель: Завершить переход от i18n.py к БД

**Реализовано:**
- [x] i18n.py заменена на обёртку (обратная совместимость)
- [x] Все импорты обновлены на language.py
- [x] Middleware использует ui_translations.py exclusively
- [x] CRUD для создания/удаления UI-строк
- [x] Экспорт переводов в JSON
- [x] Импорт переводов из JSON
- [x] Тесты обновлены (20 тестов)

---

## v0.7.0 — Мультиязычность через проекции (выполнено)

### Цель: Вынести все элементы интерфейса в сущности с мультиязычными проекциями

**Концепция (философия "Всё как сущность"):**
- Все UI-строки хранятся как сущности (EntityKind "ui_string")
- Каждая строка имеет проекции на разных языках (OntologyModel "language")
- Интерфейс генерируется из сущностей, а не из хардкода

**Реализовано:**
- [x] Создан EntityKind "ui_string" для хранения UI-строк
- [x] Создан OntologyTemplate "ui_translation" с полями key, value
- [x] Мигрированы 269 переводов из i18n.py в сущности
- [x] Middleware обновлён: загрузка переводов из БД с fallback на i18n.py
- [x] Создан CRUD для управления переводами в admin panel
- [x] Тесты обновлены

---

## v0.11.0 — Безопасность и архитектура (выполнено)

### Цель: Исправление критических проблем безопасности и реструктуризация

**Безопасность:**
- [x] CORS: ограничение доменов (только localhost)
- [x] SSRF: валидация URL в media_proxy
- [x] XSS: html.escape в export
- [x] Валидация паролей при регистрации
- [x] Предупреждения при слабом SECRET_KEY

**Архитектура:**
- [x] Создан language_service.py (общие утилиты)
- [x] Разбит admin.py на 11 подмодулей
- [x] Разбит entities.py на 4 подмодуля
- [x] Разбит layout.py на 4 подмодуля
- [x] Удалено дублирование кода
- [x] Исправлены bare except clauses

**Middleware:**
- [x] Кэширование в theme.py (5 мин TTL)
- [x] Оптимизация kinds.py
- [x] Исправлен rate_limit handler

**Плагины:**
- [x] Интеграция плагин-системы
- [x] Lifecycle hooks (on_startup/on_shutdown)
- [x] Загрузка 7 плагинов

**Производительность:**
- [x] Batch get_kind_labels_batch() для N+1
- [x] Lazy init для StorageService/AIService

---

## v0.12.0 — GraphQL, Docker, Tests (выполнено)

### Цель: Добавление GraphQL API, оптимизация Docker, тесты

**GraphQL API:**
- [x] Установлен strawberry-graphql
- [x] Созданы GraphQL типы (Entity, Kind, Stats, etc.)
- [x] Созданы query резолверы (stats, kinds, models, search)
- [x] Интеграция GraphQL router на /graphql

**Docker:**
- [x] Multi-stage Dockerfile (builder + production)
- [x] Non-root user (dwmb)
- [x] Healthcheck (curl /health)
- [x] .dockerignore (исключены .git, __pycache__, docs)
- [x] Resource limits (cpu, memory)
- [x] docker-compose.prod.yml для production

**Тесты:**
- [x] 165 тестов (было 125)
- [x] Исправлены устаревшие импорты (i18n → language_service)
- [x] Новые тесты: CSRF, language_service, security, plugins

**CSRF:**
- [x] CSRF middleware (cookie + header validation)
- [x] csrf.js хелпер для AJAX
- [x] Обновлены 27 шаблонов с CSRF токенами

---

## v0.16.0 — Рефакторинг архитектуры (план)

### Цель: Разделение приложения и пользовательских данных, нормализация кода

**Разделение данных:**
- [ ] Создать таблицы `ui_string` и `ui_string_translation` для UI-строк
- [ ] Мигрировать UI-строки из сущностей (entity_kind='ui_string')
- [ ] Создать таблицу `app_setting` для настроек приложения
- [ ] Обновить middleware для работы с новыми таблицами

**Service Layer:**
- [ ] Создать `entity_service.py` для CRUD сущностей
- [ ] Создать `projection_service.py` для управления проекциями
- [ ] Создать `relation_service.py` для управления связями
- [ ] Перенести бизнес-логику из роутов в сервисы

**API Versioning:**
- [ ] Добавить префикс `/api/v1/` ко всем эндпоинтам
- [ ] Создать роутеры для v1
- [ ] Обновить клиентов

**Типизация:**
- [ ] Добавить type hints ко всем функциям
- [ ] Создать Pydantic модели для всех сущностей
- [ ] Настроить mypy

**Accessibility:**
- [ ] Добавить alt тексты для изображений
- [ ] Проверить контрастность (WCAG AA)
- [ ] Добавить фокус-индикаторы

---

## v1.0.0 — Промышленная версия

### Цель: Микросервисы + RLS + Граф связей

- [x] Микросервисы (AI, поиск, медиа) — v0.14.0
- [x] Row-Level Security (RLS) — v0.15.0
- [x] WebSocket real-time обновления — v0.15.0
- [x] GraphQL mutations — v0.13.0
- [ ] Внешние API (IMDB, Wikipedia, MusicBrainz) — отложено после рефакторинга
- [x] Геосвязи и карты — v0.13.0
- [ ] D3.js/Cytoscape.js граф связей
- [ ] GraphQL subscriptions
