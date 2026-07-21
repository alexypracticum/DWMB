# Changelog

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
