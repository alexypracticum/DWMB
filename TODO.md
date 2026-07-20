# TODO

## Текущий статус: v0.5.2

### Выполнено (v0.5.2)
- [x] Изображение как базовая часть сущности: image_url в таблице entity
- [x] AI Конфигурация: несколько профилей с переключением (AiConfigProfile)
- [x] Страница управления плагинами (/admin/plugins)
- [x] Блок "Галерея актёров-персонажей" со спойлером и фото
- [x] Мультиязычность: добавление меток на разных языках (RU, EN, DE, FR, ES, ZH, JA)
- [x] Язык как сущность: EntityKind "language" + 7 языков
- [x] Классификаторы: ISO 639-1, ISO 639-2, ГОСТ 7.75-97
- [x] Исправлена ошибка сохранения сущности (UnboundLocalError)
- [x] Добавлены ссылки на профили и плагины в админке

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

### Приоритет 1: Мультиязычность (v0.6.0)
- [ ] Полная мультиязычная система для всех текстовых полей
- [ ] Автосохранение при переключении языков
- [ ] Отображение данных на языке пользователя

### Приоритет 2: Визуализация
- [ ] D3.js/Cytoscape.js граф связей
- [ ] Интерактивное исследование графа
- [ ] Фильтрация по типам связей

### Приоритет 3: Дополнительные источники
- [ ] IMDB через OMDb API
- [ ] Wikipedia API
- [ ] MusicBrainz API
