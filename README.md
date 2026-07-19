# DWMB — Dynamic World Meta-Base

Семантическая база знаний с онтологической моделью данных, визуальным редактором связей и AI-интеграцией.

## Архитектура

```
├── app/
│   ├── main.py              # FastAPI приложение
│   ├── config.py             # Настройки (Pydantic)
│   ├── database.py           # Async SQLAlchemy
│   ├── models/               # ORM-модели
│   │   ├── entities.py       # Entity, EntityLabel, MediaAsset
│   │   ├── kinds.py          # EntityKind, EntityKindLabel
│   │   ├── projections.py    # EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
│   │   ├── relations.py      # SemanticRelation, RelationType
│   │   ├── fields.py         # FieldRegistry
│   │   ├── users.py          # UserAccount
│   │   ├── themes.py         # UserTheme
│   │   ├── ai.py             # AiConfig, AiTaskLog, AiSuggestion
│   │   └── pages.py          # PageRegistry
│   ├── routes/               # HTTP-эндпоинты
│   │   ├── entities.py       # CRUD сущностей + загрузка файлов
│   │   ├── admin.py          # Админ-панель
│   │   ├── auth.py           # Авторизация
│   │   ├── search.py         # Поиск
│   │   ├── ai.py             # AI API
│   │   ├── editor_api.py     # API редактора
│   │   ├── profile.py        # Профиль пользователя
│   │   ├── stats.py          # Статистика
│   │   └── theme_editor.py   # Редактор тем
│   ├── services/             # Бизнес-логика
│   │   ├── auth.py           # JWT-авторизация
│   │   ├── storage.py        # MinIO S3
│   │   ├── layout.py         # Рендеринг макетов
│   │   ├── theme.py          # CSS-переменные тем
│   │   └── i18n.py           # Переводы интерфейса
│   ├── middleware/            # Middleware
│   │   ├── theme.py          # Тема + i18n
│   │   └── kinds.py          # Контекст типов
│   ├── templates/            # Jinja2 шаблоны
│   └── static/               # CSS, JS, изображения
├── tests/                    # Unit и интеграционные тесты
├── db/                       # SQL-скрипты миграций
├── docker-compose.yml        # Оркестрация
└── requirements.txt          # Зависимости
```

## Быстрый старт

```bash
docker compose up -d
# Открыть http://localhost:8000
# Логин: admin / admin123
```

## Тесты

```bash
# Unit-тесты ( без БД)
docker compose exec app python -m pytest tests/test_layout.py tests/test_i18n_service.py -v

# Интеграционные ( через curl)
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/entities
```

## Технологии

- **Backend:** Python 3.12, FastAPI, SQLAlchemy async, asyncpg
- **БД:** PostgreSQL 16 + pgvector
- **Хранилище:** MinIO (S3)
- **AI:** OpenAI API (конфигурируется)
- **Frontend:** Jinja2, Tailwind CSS, vanilla JS
- **Тесты:** pytest, pytest-asyncio
