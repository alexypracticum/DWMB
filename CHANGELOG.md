# Changelog

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
