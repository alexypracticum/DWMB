# DWMB — Dynamic World Meta-Base

Семантическая база знаний с онтологической моделью данных, визуальным редактором связей и AI-интеграцией.

Философия: "Всё как Сущность", "Сущность как точка пересечения моделей мира"

## Архитектура

```
├── app/
│   ├── main.py              # FastAPI приложение + плагин-система
│   ├── config.py             # Настройки (Pydantic) + CORS
│   ├── database.py           # Async SQLAlchemy
│   ├── models/               # ORM-модели
│   │   ├── entities.py       # Entity (image_url), EntityLabel, MediaAsset, EventLog
│   │   ├── kinds.py          # EntityKind, EntityKindLabel
│   │   ├── projections.py    # EntityProjection, ProjectionState
│   │   ├── relations.py      # SemanticRelation, RelationType
│   │   ├── fields.py         # FieldRegistry
│   │   ├── users.py          # UserAccount
│   │   ├── themes.py         # UserTheme
│   │   ├── ai.py             # AiConfig, AiConfigProfile, AiTaskLog, AiSuggestion
│   │   ├── rbac.py           # Role, Permission, UserRole
│   │   └── comments.py       # Comment
│   ├── routes/               # HTTP-эндпоинты (разбиты на подмодули)
│   │   ├── entities/         # CRUD сущностей (4 файла: crud, projections, relations, media)
│   │   ├── admin/            # Админ-панель (11 файлов)
│   │   ├── auth.py           # Авторизация + rate limiting
│   │   ├── search.py         # Поиск с фильтрами
│   │   ├── ai.py             # AI API
│   │   ├── editor_api.py     # API редактора
│   │   ├── profile.py        # Профиль пользователя
│   │   ├── stats.py          # Статистика
│   │   ├── theme_editor.py   # Редактор тем
│   │   ├── import_api.py     # TMDB импорт + Swagger
│   │   ├── comments.py       # Комментарии CRUD
│   │   ├── export.py         # Markdown/HTML экспорт
│   │   └── feeds.py          # RSS/Atom фиды
│   ├── services/             # Бизнес-логика
│   │   ├── auth.py           # JWT-авторизация
│   │   ├── rbac.py           # RBAC service
│   │   ├── cache.py          # Redis кэширование
│   │   ├── email.py          # Email service
│   │   ├── event_log.py      # Аудит-журнал
│   │   ├── storage.py        # MinIO S3 (lazy init)
│   │   ├── layout/           # Рендеринг макетов (4 файла: block_types, helpers, block_renderers, renderer)
│   │   ├── theme.py          # CSS-переменные тем
│   │   └── language_service.py # Общие утилиты для языков
│   ├── middleware/            # Middleware
│   │   ├── theme.py          # Тема + i18n + cookie (кэширование)
│   │   ├── kinds.py          # Контекст типов (кэширование)
│   │   └── rate_limit.py     # Rate limiting (slowapi)
│   ├── templates/            # Jinja2 шаблоны
│   └── static/               # CSS, JS (TipTap WYSIWYG)
├── plugins/                  # Плагины
│   ├── ai/                   # AI интеграция
│   ├── tmdb/                 # TMDB импорт
│   ├── themes/               # Визуальные темы
│   ├── cms/                  # CMS страницы
│   ├── stats/                # Статистика
│   ├── rbac/                 # RBAC
│   └── email/                # Email уведомления
├── tests/                    # 20+ unit-тестов
├── db/                       # SQL-скрипты + миграции
│   ├── init.sql              # Полная схема БД (30+ таблиц)
│   ├── seeds/                # Seed данные (250+ сущностей)
│   └── migrations/           # 6 миграций
├── cli.py                    # CLI утилита
├── docker-compose.yml        # Оркестрация (app, db, minio)
└── requirements.txt          # Зависимости
```

## Быстрый старт

```bash
# Запуск
docker compose up -d

# Открыть http://localhost:8000
# Логин: admin / admin123
```

## CLI команды

```bash
python cli.py status    # Проверка системы
python cli.py stats     # Статистика БД
python cli.py backup    # Бэкап в backups/
python cli.py restore   # Восстановление из бэкапа
python cli.py migrate   # Применение миграций
python cli.py seed      # Заполнение seed данными
```

## API

- Swagger UI: http://localhost:8000/docs
- RSS Feed: http://localhost:8000/feed/entities
- TMDB Import: http://localhost:8000/api/import/tmdb/search/movie?q=inception

## Языковой переключатель

В верхнем меню доступен переключатель языков (RU/EN). Язык сохраняется в cookie и применяется ко всем страницам.

## Тесты

```bash
# Unit-тесты (в Docker)
docker compose exec app python -m pytest tests/ -v

# Проверка через curl
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/
```

## Возможности

- **47 типов** сущностей
- **71 тип** связей
- **28+ таблиц** в 10 архитектурных слоях
- **7 плагинов**: AI, TMDB, Themes, CMS, Stats, RBAC, Email
- **7 языков**: ru, en, de, fr, es, zh, ja
- **140+ эндпоинтов** API (REST + GraphQL)
- **207 тестов** (37 файлов)
- **Версионирование** через event sourcing
- **AI-интеграция**: OpenAI, Anthropic, Google, MiMo
- **GraphQL API**: 7 queries + 5 mutations + 3 subscriptions
- **CSRF защита** на всех формах
- **Внешние API**: Last.fm, Wikipedia, MusicBrainz, OMDb (кэш + rate limit)
- **Граф связей**: D3.js визуализация, поиск по графу, экспорт PNG/SVG/JSON
- **CI/CD**: GitHub Actions (test, deploy, docker-publish)

### Ядро
- Онтологическая модель: kinds, projections, templates, contexts
- Семантические связи: directed/undirected, inverse, transitive
- JSON Schema для определения полей
- Блочный лайаут (21 тип блоков, включая галерею актёров)
- Мультиязычность (7 языков: ru, en, de, fr, es, zh, ja)
- 25+ типов сущностей (movie, actor, language, classifier, ...)
- Изображение как базовая часть сущности (image_url)

### Плагины
- AI: эмбеддинги, chat, парсинг текста, гибридный поиск
- AI profiles: несколько профилей с переключением
- TMDB: импорт фильмов, людей, кредитов
- Темы: 9 пресетов, визуальный редактор
- CMS: страницы, иерархические меню
- RBAC: 3 роли, 13 разрешений
- Email: отправка писем через SMTP

### Админ-панель
- Журнал событий (аудит-журнал с фильтрами)
- Управление ролями и разрешениями (CRUD)
- Настройки API ключей (OMDB, Last.fm, TMDB, AI)
- Настройки email (SMTP)
- Настройки безопасности (CORS, rate limit, CSRF, SECRET_KEY)
- Бэкап/восстановление PostgreSQL

### UI/UX
- 4 вида отображения: Превью, Плитки, Список, Таблица
- WYSIWYG редактор (TipTap)
- SEO: meta_title, meta_description, og_image
- Workflow: draft/published/archived
- Комментарии с вложенностью
- Экспорт в Markdown/HTML
- Управление плагинами (/admin/plugins)
- Toast-уведомления (window.showToast)
- Тёмная тема (включая для графа)
- Виджет "Часто слушаю" (Last.fm) на странице профиля

### Инфраструктура
- Redis кэширование с in-memory fallback
- Rate limiting (slowapi)
- Аудит-журнал (EventLog)
- Backup через CLI
- RSS/Atom фиды
- Языковые сущности (ISO 639-1, ISO 639-2, ГОСТ 7.75-97)
- CI/CD: GitHub Actions (test.yml, deploy.yml, docker-publish.yml)
- WebSocket: real-time уведомления
- GraphQL subscriptions: entityChanged, commentChanged, relationChanged

## Технологии

- **Backend:** Python 3.12, FastAPI, SQLAlchemy async, asyncpg
- **БД:** PostgreSQL 16 + pgvector
- **Хранилище:** MinIO (S3)
- **AI:** OpenAI API (конфигурируется)
- **Кэширование:** Redis (опционально)
- **Frontend:** Jinja2, Tailwind CSS, TipTap, HTMX
- **Тесты:** pytest, pytest-asyncio
- **CLI:** typer
