---
title: "Тестирование"
description: "pytest + pytest-asyncio, 18 тестовых файлов, интеграционные и unit-тесты"
date_created: "2026-07-20"
date_updated: "2026-07-22"
sources:
  - "tests/conftest.py"
  - "pytest.ini"
  - "requirements.txt"
status: "active"
okf_version: "0.1"
---

## Стек

- **pytest** >= 8.0.0
- **pytest-asyncio** >= 0.23.0
- Режим: `asyncio_mode = auto`

## Конфигурация

```ini
# pytest.ini
[pytest]
asyncio_mode = auto
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

## Запуск

```bash
docker compose exec app python -m pytest tests/ -v
```

Тесты работают против **реальной PostgreSQL** через Docker. Нет in-memory SQLite.

## Фикстуры (`tests/conftest.py`)

```python
@pytest_asyncio.fixture
async def db_session():
    """Реальная сессия БД, rollback после каждого теста."""
    async with async_session() as session:
        yield session
        await session.rollback()

@pytest_asyncio.fixture
async def client(db_session):
    """Async HTTP client (ASGITransport, без реального HTTP)."""
    app.dependency_overrides[get_db] = _override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

@pytest_asyncio.fixture
async def auth_client(db_session):
    """HTTP client с JWT cookie admin-пользователя."""
    token = create_access_token(data={"sub": "admin"})
    async with AsyncClient(transport=transport, base_url="http://test",
        cookies={"access_token": token}) as ac:
        yield ac
```

## Тестовые файлы (18)

| Файл | Тестов | Что проверяет |
|------|--------|---------------|
| `test_auth.py` | 5 | Страницы логина/регистрации, невалидные credentials, профиль |
| `test_admin.py` | 15 | Все admin-страницы (kinds/templates/fields/users/AI), `_sync_layout_fields_from_schema` |
| `test_admin_crud.py` | 3 | Admin kinds list → 200 |
| `test_entities.py` | 10 | Entity list, detail, edit, create — проверка auth |
| `test_entity_crud.py` | 8 | Entity create/edit страницы, auth requirements |
| `test_import_api.py` | 25 | `_ensure_kind_and_relation`, `_find_or_create_related_entity`, TMDB retry/error |
| `test_security.py` | 8 | Config, .env, .gitignore, отсутствие hardcoded паролей |
| `test_multilingual.py` | 12 | i18n переводы, смена языка, model columns, cache clear |
| `test_new_features.py` | 5 | `/set-lang` route, cookie setting, redirects |
| `test_upload.py` | 3 | Upload требует auth, обработка отсутствия файла |
| `test_i18n.py` | 3 | Неавторизованный пользователь → русский интерфейс |
| `test_i18n_service.py` | 5 | `get_translation`, `get_language_id`, `clear_language_cache` |
| `test_layout.py` | 5 | Рендеринг layout |
| `test_ontology_entities.py` | 4 | Ontology entity |
| `test_ontology_entity_sync.py` | 4 | Ontology entity sync |
| `test_relation_types_crud.py` | 4 | Relation type CRUD |
| `test_relation_metadata.py` | 4 | Relation metadata |
| `test_relationships.py` | 4 | Relationship editor |

**Примеры тестов (реальные):**

```python
# tests/test_admin.py
async def test_admin_kinds_page(auth_client):
    response = await auth_client.get("/admin/kinds")
    assert response.status_code == 200

async def test_sync_layout_fields_from_schema(db_session):
    # Проверяет маппинг JSON schema → layout fields
    ...

# tests/test_auth.py
async def test_login_page(client):
    response = await client.get("/auth/login")
    assert response.status_code == 200

async def test_invalid_credentials(client):
    response = await client.post("/auth/login",
        data={"username": "wrong", "password": "wrong"}, follow_redirects=False)
    assert response.status_code == 303  # redirect back to login

# tests/test_security.py
def test_no_hardcoded_passwords():
    # Проверяет .env.example на наличие CHANGE_ME
    ...
```

## Паттерны

### Интеграционные тесты (HTTP)

```python
async def test_entity_list(auth_client):
    response = await auth_client.get("/entities")
    assert response.status_code == 200
```

### Unit-тесты с моками

```python
from unittest.mock import AsyncMock, patch, MagicMock

@patch("app.services.importers.tmdb.httpx.AsyncClient")
async def test_tmdb_retry(mock_client):
    # Проверяет retry логику TMDB
    ...
```

## Покрытие

Нет настроенного `pytest-cov`. Нет CI/CD конфигурации.

## Известные ограничения

- Нет `pytest-cov` в `requirements.txt`
- Нет `.github/workflows/` конфигурации
- Нет E2E тестов (Playwright и т.д.)
- Тесты требуют запущенных Docker-контейнеров

## Связанные страницы

- [[architecture/overview]] — обзор архитектуры
- [[development/contributing]] — вклад в проект
- [[deployment/docker]] — Docker Compose
