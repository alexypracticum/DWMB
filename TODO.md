# TODO

## Текущий статус: v0.5.0

### Выполнено (v0.5.0)
- [x] Архитектура плагинов: PluginBase, load_plugins(), 7 плагинов (ai, tmdb, themes, cms, stats, rbac, email)
- [x] RBAC: модели Role/Permission, require_permission() dependency, 3 роли, 13 разрешений
- [x] EventLog: аудит create/update/delete/relation_change
- [x] Вид "Превью" с постерами (3:4 aspect ratio)
- [x] Убран entity_code из grid/list видов
- [x] SEO-поля: meta_title, meta_description, og_image
- [x] Redis кэширование с in-memory fallback (5 мин TTL для kinds)
- [x] Rate limiting: 200/min default, 10/min auth (brute-force защита)
- [x] Email service: send_verification_email, send_password_reset_email
- [x] Версионирование: страница /entity/{id}/history с списком событий
- [x] Workflow: draft/published/archived состояния с кнопками переходов
- [x] Комментарии: модель Comment, CRUD, вложенность, ответы
- [x] WYSIWYG: TipTap редактор с тулбаром (bold, italic, headings, lists, links)
- [x] Экспорт: Markdown и HTML файлы для скачивания
- [x] API документация: Swagger annotations для TMDB, comments, export
- [x] CLI утилита: status, seed, stats, backup, restore, migrate
- [x] RSS/Atom фиды: /feed/entities, /feed/pages
- [x] Backup: pg_dump через CLI (timestamped SQL files)

### Выполнено (v0.4.3)
- [x] SQL-инъекция в TMDB импорте (ORM вместо raw SQL)
- [x] Retry/backoff для TMDB API (обработка 429 rate limit)
- [x] Логирование TMDB запросов и ошибок
- [x] 11 новых unit-тестов для TMDB импорта
- [x] i18n: замена хардкода language="ru" на язык пользователя с fallback
- [x] Переведённые названия типов в боковом меню и выпадающем списке
- [x] Автоматическое растягивание страницы создания сущности по ширине
- [x] Выбор вида отображения (плитки/список/таблица)
- [x] Сортировка и масштабирование на странице списка сущностей
- [x] Сохранение предпочтений вида в localStorage

### Выполнено (v0.4.2)
- [x] TMDB API интеграция (фильмы, люди, кредиты, жанры)
- [x] Импорт фильмов: название, год, постер, бюджет, сборы
- [x] Импорт людей: имя, фото (profile_path)
- [x] Автосоздание связей: directed_by, acted_in, produced_by, produced_in, language_of
- [x] Импорт компаний, стран, языков как сущностей
- [x] Поиск с фильтрами (production_company, country, genre, language)
- [x] Теги-ссылки (жанры, компании) без пилюль
- [x] dropdown выбора типов связей в редакторе блоков
- [x] Роль персонажа (character) в metadata_ в acted_in
- [x] Отображение Имя (Роль) в агрегированных связях
- [x] Блок лайаута actor_character_row (актёр → персонаж)
- [x] Автосоздание EntityKind "character" и RelationTypes "plays"/"appears_in"
- [x] Создание entity персонажа + связи (actor → character → movie)
- [x] Блокировка ошибок prop-as-string (4 места)
- [x] Кнопка "Отвязать" для онтологий в редакторе сущности
- [x] Unit-тесты: 23 тестов (layout + import_api)
- [x] Исправление бага с raw SQL text() в async session
- [x] Исправление model_id vs UUID issue

### Приоритет 1: Визуализация (v0.6.0)
- [ ] D3.js/Cytoscape.js граф связей
- [ ] Интерактивное исследование графа
- [ ] Фильтрация по типам связей

### Приоритет 2: Дополнительные источники
- [ ] IMDB через OMDb API
- [ ] Wikipedia API
- [ ] MusicBrainz API

### Приоритет 3: Тестирование
- [ ] Интеграционные тесты API (в контейнере)
- [ ] End-to-end тесты
