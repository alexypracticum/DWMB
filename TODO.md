# TODO

## Текущий статус: v0.5.1

### Выполнено (v0.5.1)
- [x] AI Конфигурация: выравнивание по центру
- [x] List view: исправлен overflow за правое меню
- [x] Левое меню: показывает названия вместо кодов (FIX: порядок middleware + шаблон)

### Выполнено (v0.5.0)
- [x] Архитектура плагинов: PluginBase, load_plugins(), 7 плагинов
- [x] RBAC: модели Role/Permission, require_permission() dependency, 3 роли, 13 разрешений
- [x] EventLog: аудит create/update/delete/relation_change
- [x] Вид "Превью" с постерами (3:4 aspect ratio)
- [x] Убран entity_code из grid/list видов
- [x] SEO-поля: meta_title, meta_description, og_image
- [x] Redis кэширование с in-memory fallback (5 мин TTL для kinds)
- [x] Rate limiting: 200/min default, 10/min auth (brute-force защита)
- [x] Email service: send_verification_email, send_password_reset_email
- [x] Версионирование: страница /entity/{id}/history с событиями
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

### Приоритет 1: Визуализация (v0.6.0)
- [ ] D3.js/Cytoscape.js граф связей
- [ ] Интерактивное исследование графа
- [ ] Фильтрация по типам связей

### Приоритет 2: Дополнительные источники
- [ ] IMDB через OMDb API
- [ ] Wikipedia API
- [ ] MusicBrainz API
