---
type: development
title: "Тестирование"
description: "Подходы к тестированию DWMB: unit-тесты, интеграционные тесты, E2E, покрытие"
tags: [development, testing, pytest, coverage]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 18.07.2027.PLAN.md
status: stable
---

# Тестирование

Подходы к тестированию [[architecture/overview|DWMB]].

## Типы тестов

### 1. Unit-тесты

Тестирование отдельных функций и классов.

```python
# tests/test_entity_service.py
def test_create_entity():
    service = EntityService(db)
    entity = service.create(kind_code="movie", entity_code="matrix")
    assert entity.entity_code == "matrix"
    assert entity.kind_id is not None
```

### 2. Интеграционные тесты

Тестирование взаимодействия с БД и внешними сервисами.

```python
# tests/test_api.py
def test_entity_api(client):
    response = client.post("/api/v1/entities", json={
        "kind_code": "movie",
        "entity_code": "matrix"
    })
    assert response.status_code == 201
    assert response.json()["entity_code"] == "matrix"
```

### 3. E2E тесты

Тестирование полного пользовательского сценария.

```python
# tests/test_e2e.py
def test_create_and_view_entity(client, browser):
    # Создание сущности
    browser.fill("entity_code", "matrix")
    browser.click("submit")
    
    # Просмотр сущности
    assert browser.url.contains("/entity/")
    assert browser.locator("h1").text_contains("Matrix")
```

## Структура тестов

```
tests/
├── conftest.py           — Фикстуры
├── test_entity_service.py — Unit-тесты сервиса
├── test_api.py           — Интеграционные тесты API
├── test_database.py      — Тесты БД
└── test_e2e.py           — E2E тесты
```

## Покрытие

| Компонент | Покрытие | Приоритет |
|-----------|----------|-----------|
| EntityService | 80% | Высокий |
| API endpoints | 70% | Высокий |
| Database operations | 60% | Средний |
| Frontend | 30% | Низкий |
| Plugins | 50% | Средний |

## Запуск тестов

```bash
# Все тесты
pytest

# С покрытием
pytest --cov=app --cov-report=html

# Только unit-тесты
pytest -m "not integration"

# Только интеграционные
pytest -m integration
```

## CI/CD

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: "3.11"
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest --cov=app
```

## Проблемы

### 1. Нет тестов

Текущий проект не имеет тестов.

### 2. Нет CI/CD

Нет автоматического запуска тестов.

### 3. Нет E2E тестов

Нет тестирования пользовательских сценариев.

## Планы

- Написать unit-тесты для EntityService
- Написать интеграционные тесты для API
- Настроить CI/CD
- Добавить E2E тесты
- Достичь покрытия 70%

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[development/roadmap]] — Дорожная карта
- [[development/contributing]] — Вклад в проект
- [[deployment/docker]] — Настройка окружения
