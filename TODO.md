# TODO

## Текущий статус: v0.12.0

### Выполнено (v0.11.0) — Безопасность и архитектура
- [x] CORS: ограничение доменов
- [x] SSRF: валидация URL в media_proxy
- [x] XSS: html.escape в export
- [x] Валидация паролей при регистрации
- [x] language_service.py: общие утилиты
- [x] Разбиение admin.py на 11 подмодулей
- [x] Разбиение entities.py на 4 подмодуля
- [x] Разбиение layout.py на 4 подмодуля
- [x] Кэширование в theme.py
- [x] Интеграция плагин-системы
- [x] Batch get_kind_labels_batch() для N+1
- [x] Lazy init для StorageService/AIService
- [x] Удалён мёртвый код (i18n.py, pages.py)

### Выполнено (v0.6.1) — Перевод admin panel
- [x] Перевод кнопки "Языки" в admin dashboard
- [x] Перевод блока "Пользователи" (таблица, статусы, действия)
- [x] Новые ключи перевода для admin panel (13 ключей x 7 языков)

### Выполнено (v0.6.0) — Мультиязычность
- [x] Замена ENUM language_code на таблицу meta.language
- [x] Миграция ORM моделей на FK language_id
- [x] Переводы интерфейса на 7 языков (ru, en, de, fr, es, zh, ja)
- [x] Переключатель языков в навигации
- [x] CRUD для языков в админ-панели
- [x] Тесты мультиязычности (26 тестов)

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

### Выполнено (v0.12.0) — GraphQL, Docker, Tests
- [x] CSRF защита на формах
- [x] GraphQL API (strawberry-graphql)
- [x] Docker optimization (multi-stage, non-root, healthcheck)
- [x] 165 тестов (было 125)
- [x] Исправлены устаревшие импорты

### Нереализованное (требует внимания)
- [ ] RBAC: require_permission() не используется в роутах
- [ ] Email: send_verification_email/send_password_reset не вызываются
- [ ] Redis: init_cache() не вызывается при старте
- [ ] GraphQL: greenlet ошибки в некоторых запросах

### Приоритет 1: Активация существующего функционала
- [ ] Подключить RBAC require_permission к роутам
- [ ] Подключить Email service к регистрации/сбросу пароля
- [ ] Инициализировать Redis кэш при старте
- [ ] Исправить greenlet ошибки в GraphQL

### Приоритет 2: Новая функциональность
- [ ] D3.js/Cytoscape.js граф связей
- [ ] Внешние API (IMDB, Wikipedia, MusicBrainz)
- [ ] Автосохранение при переключении языков
- [ ] GraphQL mutations (create, update, delete)

### Приоритет 3: Промышленная версия
- [ ] Микросервисы (AI, поиск, медиа)
- [ ] Row-Level Security (RLS)
- [ ] WebSocket real-time обновления
- [ ] Вынести UI-строки в сущности с мультиязычными проекциями
- [ ] Мигрировать переводы из i18n.py в сущности
- [ ] Обновить шаблоны для чтения переводов из сущностей
- [ ] Создать UI для управления переводами

### Приоритет 2: Дополнительно
- [ ] Автосохранение при переключении языков
- [ ] Отображение данных сущностей на языке пользователя

### Приоритет 2: Визуализация
- [ ] D3.js/Cytoscape.js граф связей
- [ ] Интерактивное исследование графа
- [ ] Фильтрация по типам связей

### Приоритет 3: Дополнительные источники
- [ ] IMDB через OMDb API
- [ ] Wikipedia API
- [ ] MusicBrainz API
