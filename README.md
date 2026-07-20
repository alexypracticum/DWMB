# DWMB — Dynamic World Meta-Base

Семантическая база знаний с онтологической моделью данных, визуальным редактором связей и AI-интеграцией.

## Архитектура

```
├── app/
│   ├── main.py              # FastAPI приложение + плагин-система
│   ├── config.py             # Настройки (Pydantic)
│   ├── database.py           # Async SQLAlchemy
│   ├── models/               # ORM-модели
│   │   ├── entities.py       # Entity, EntityLabel, MediaAsset, EventLog
│   │   ├── kinds.py          # EntityKind, EntityKindLabel
│   │   ├── projections.py    # EntityProjection, ProjectionState
│   │   ├── relations.py      # SemanticRelation, RelationType
│   │   ├── fields.py         # FieldRegistry
│   │   ├── users.py          # UserAccount
│   │   ├── themes.py         # UserTheme
│   │   ├── ai.py             # AiConfig, AiTaskLog, AiSuggestion
│   │   ├── pages.py          # PageRegistry, MenuItem
│   │   ├── rbac.py           # Role, Permission, UserRole
│   │   └── comments.py       # Comment
│   ├── routes/               # HTTP-эндпоинты
│   │   ├── entities.py       # CRUD сущностей + история + workflow
│   │   ├── admin.py          # Админ-панель + RBAC API
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
│   │   ├── storage.py        # MinIO S3
│   │   ├── layout.py         # Рендеринг макетов (20 типов блоков)
│   │   ├── theme.py          # CSS-переменные тем
│   │   └── i18n.py           # Переводы интерфейса (ru/en)
│   ├── middleware/            # Middleware
│   │   ├── theme.py          # Тема + i18n
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
├── tests/                    # 35 unit-тестов
├── db/                       # SQL-скрипты + миграции
│   ├── init.sql              # Полная схема БД (28 таблиц)
│   ├── seeds/                # Seed данные (250 сущностей)
│   └── migrations/           # 3 миграции (RBAC, workflow, comments)
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

## Тесты

```bash
# Unit-тесты (без БД)
.venv/bin/python -m pytest tests/ -v

# Проверка через curl
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/
```

## Возможности

### Ядро
- Онтологическая модель: kinds, projections, templates, contexts
- Семантические связи: directed/undirected, inverse, transitive
- JSON Schema для определения полей
- Блочный лайаут (20 типов блоков)
- Мультиязычность (7 языков)
- 25 типов сущностей (movie, actor, book, song, ...)

### Плагины
- AI: эмбеддинги, chat, парсинг текста, гибридный поиск
- TMDB: импорт фильмов, людей, кредитов
- Темы: 9 пресетов, визуальный редактор
- CMS: страницы, иерархические меню
- RBAC: 3 роли, 13 разрешений
- Email: отправка писем через SMTP

### UI/UX
- 4 вида отображения: Превью, Плитки, Список, Таблица
- WYSIWYG редактор (TipTap)
- SEO: meta_title, meta_description, og_image
- Workflow: draft/published/archived
- Комментарии с вложенностью
- Экспорт в Markdown/HTML

### Инфраструктура
- Redis кэширование с in-memory fallback
- Rate limiting (slowapi)
- Аудит-журнал (EventLog)
- Backup через CLI
- RSS/Atom фиды

## Технологии

- **Backend:** Python 3.12, FastAPI, SQLAlchemy async, asyncpg
- **БД:** PostgreSQL 16 + pgvector
- **Хранилище:** MinIO (S3)
- **AI:** OpenAI API (конфигурируется)
- **Кэширование:** Redis (опционально)
- **Frontend:** Jinja2, Tailwind CSS, TipTap, HTMX
- **Тесты:** pytest, pytest-asyncio
- **CLI:** typer
