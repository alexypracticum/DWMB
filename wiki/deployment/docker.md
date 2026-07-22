---
type: deployment
title: "Docker Compose"
description: "Оркестрация DWMB через Docker Compose: PostgreSQL, MinIO, приложение, зависимости"
tags: [deployment, docker, compose, orchestration]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 08.03.2026.Пишем БД c ChatGPT.md
  - 18.07.2027.PLAN.md
status: stable
---

# Docker Compose

Оркестрация [[architecture/overview|DWMB]] через Docker Compose.

## Сервисы

```yaml
services:
  # PostgreSQL с расширениями
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: dwmb
      POSTGRES_USER: dwmb
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"

  # MinIO (S3-совместимое хранилище)
  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_PASSWORD}
    volumes:
      - miniodata:/data
    ports:
      - "9000:9000"
      - "9001:9001"

  # Приложение DWMB
  app:
    build: .
    environment:
      DATABASE_URL: postgresql://dwmb:${DB_PASSWORD}@db:5432/dwmb
      S3_ENDPOINT: http://minio:9000
      S3_ACCESS_KEY: ${MINIO_USER}
      S3_SECRET_KEY: ${MINIO_PASSWORD}
    ports:
      - "8000:8000"
    depends_on:
      - db
      - minio

volumes:
  pgdata:
  miniodata:
```

## Расширения PostgreSQL

| Расширение | Назначение |
|-----------|-----------|
| pgvector | Векторный поиск |
| pg_trgm | Триграммный поиск |
| btree_gist | Индексы для EXCLUDE |
| uuid-ossp | Генерация UUID |

## Переменные окружения

См. [[deployment/environment]] для полного списка.

## Запуск

```bash
# Инициализация
cp .env.example .env
# Редактирование .env

# Запуск
docker compose up -d

# Инициализация БД
docker compose exec db psql -U dwmb -d dwmb -f /docker-entrypoint-initdb.d/init.sql

# Просмотр логов
docker compose logs -f app
```

## Тома

| Том | Назначение |
|-----|-----------|
| pgdata | Данные PostgreSQL |
| miniodata | Файлы MinIO |

## Сети

```yaml
networks:
  default:
    driver: bridge
```

Все сервисы в одной сети, доступны по именам сервисов.

## Проблемы

### 1. Нет продакшн-конфигурации

Текущий docker-compose.yml предназначен для разработки.

### 2. Нет healthcheck

Нет проверки работоспособности сервисов.

### 3. Нет автоматических миграций

Миграции запускаются вручную.

### 4. Нет резервного копирования

Нет автоматического бэкапа данных.

## Планы

- Создать docker-compose.prod.yml для продакшна
- Добавить healthcheck
- Автоматические миграции
- Автоматические бэкапы
- Мониторинг

## Связанные страницы

- [[deployment/environment]] — Переменные окружения
- [[architecture/overview]] — Обзор архитектуры
- [[database/media]] — Настройка MinIO
