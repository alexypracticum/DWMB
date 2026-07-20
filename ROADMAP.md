# Roadmap

## v0.5.0 — Текущий релиз (выполнено)

### Цель: Архитектура плагинов, инфраструктура, UI/UX

**Фаза 1: Ядро + инфраструктура**
- [x] Архитектура плагинов: PluginBase, load_plugins(), 7 плагинов
- [x] RBAC: роли (admin/editor/viewer), 13 разрешений, dependency injection
- [x] EventLog: аудит create/update/delete/relation_change
- [x] SQL-инъекция: ORM вместо raw SQL в TMDB импорте
- [x] Retry/backoff для TMDB API (обработка 429)
- [x] Логирование TMDB запросов и ошибок

**Фаза 2: UI-улучшения**
- [x] Вид "Превью" с постерами (3:4 aspect ratio)
- [x] Убран entity_code из grid/list видов
- [x] Исправлен list view overflow
- [x] SEO-поля: meta_title, meta_description, og_image
- [x] Collapsible SEO секция в редакторе

**Фаза 3: Инфраструктура**
- [x] Redis кэширование с in-memory fallback
- [x] Rate limiting (slowapi): 200/min default, 10/min auth
- [x] Email service (aiosmtplib): verification, password reset

**Фаза 4: Контент**
- [x] Версионирование с UI: страница истории сущности
- [x] Workflow: draft/published/archived состояния
- [x] Комментарии: CRUD, вложенность, ответы

**Фаза 5: Расширения**
- [x] WYSIWYG: TipTap редактор с тулбаром
- [x] Экспорт: Markdown и HTML файлы
- [x] API документация: Swagger annotations

**Фаза 6: Опциональное**
- [x] CLI утилита: status, stats, backup, restore, migrate
- [x] RSS/Atom фиды: /feed/entities, /feed/pages
- [x] Backup: pg_dump через CLI

---

## v0.4.3 — Безопасность TMDB, i18n, UI (выполнено)

### Цель: Безопасность TMDB, i18n, UI улучшения

**Выполнено:**
- [x] SQL-инъекция в TMDB импорте (ORM вместо raw SQL)
- [x] Retry/backoff для TMDB API (обработка 429 rate limit)
- [x] Логирование TMDB запросов и ошибок
- [x] 11 новых unit-тестов для TMDB импорта
- [x] i18n: замена хардкода language="ru" на язык пользователя с fallback
- [x] Переведённые названия типов в боковом меню и выпадающем списке
- [x] Автоматическое растягивание страницы создания сущности по ширине
- [x] Выбор вида отображения (плитки/список/таблица)
- [x] Сортировка и масштабирование на странице списка
- [x] Сохранение предпочтений вида в localStorage

---

## v0.4.2 — ТМВВ импорт, блоки лайаута, персонажи (выполнено)

**Выполнено:**
- [x] TMDB API интеграция (фильмы, люди, жанры, кредиты)
- [x] Импорт фильмов: название, год, постер, сборы
- [x] Импорт людей: имя, фото, фильмография
- [x] Автосоздание связей: directed_by, acted_in, produced_by, produced_in, language_of
- [x] Импорт компаний, стран, языков как сущностей
- [x] Роль персонажа (character) в metadata_ SemanticRelation
- [x] Поиск с фильтрами (производственная компания, страна, жанр, язык)
- [x] Теги-ссылки без пилюлей (жанры, компании)
- [x] dropdown типов связей в редакторе блоков (relation_type_select)
- [x] Новый блок лайаута: actor_character_row (актёр → персонаж)
- [x] Автосоздание EntityKind "character" и RelationTypes "plays"/"appears_in"
- [x] Создание entity персонажа и двойные связи (actor→character→movie) при импорте
- [x] Исправление 4+ багов с prop-as-string в схеме онтологии
- [x] Кнопка "Отвязать" для привязанных онтологий/проекций
- [x] Тесты: 23 unit-тестов для layout + import_api

---

## v0.6.0 — Следующий этап (планирование)

### Цель: Визуализация, дополнительные источники, тестирование

**Визуализация связей**
- [ ] D3.js или Cytoscape.js граф
- [ ] Граф связей на странице сущности
- [ ] Фильтрация по типам связей
- [ ] Интерактивное исследование

**Дополнительные источники**
- [ ] IMDB через OMDb API
- [ ] Wikipedia API (автозаполнение полей по URL)
- [ ] MusicBrainz API (исполнители, альбомы, треки)

**Тестирование**
- [ ] Интеграционные тесты API (в контейнере)
- [ ] End-to-end тесты

---

## v1.0.0 — Промышленная версия

### Цель: Микросервисы + GraphQL + RLS

- [ ] Микросервисы (AI, поиск, медиа)
- [ ] GraphQL API
- [ ] Row-Level Security
- [ ] Нагрузочное тестирование
