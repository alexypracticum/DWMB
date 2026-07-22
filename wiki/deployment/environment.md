---
type: deployment
title: "Переменные окружения"
description: "Конфигурация DWMB через переменные окружения: БД, S3, AI, безопасность"
tags: [deployment, environment, config, variables]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 18.07.2027.PLAN.md
  - 22.07.2026.MIMO.md
status: stable
---

# Переменные окружения

Конфигурация [[architecture/overview|DWMB]] через переменные окружения.

## Основные переменные

### База данных

| Переменная | Описание | Пример |
|-----------|----------|--------|
| DATABASE_URL | URL подключения к PostgreSQL | `postgresql://dwmb:password@localhost:5432/dwmb` |
| DB_HOST | Хост PostgreSQL | `localhost` |
| DB_PORT | Порт PostgreSQL | `5432` |
| DB_NAME | Имя базы данных | `dwmb` |
| DB_USER | Пользователь PostgreSQL | `dwmb` |
| DB_PASSWORD | Пароль PostgreSQL | `secret` |

### S3 / MinIO

| Переменная | Описание | Пример |
|-----------|----------|--------|
| S3_ENDPOINT | URL MinIO | `http://localhost:9000` |
| S3_ACCESS_KEY | Access Key MinIO | `minioadmin` |
| S3_SECRET_KEY | Secret Key MinIO | `minioadmin` |
| S3_BUCKET | Имя бакета | `dwmb` |
| S3_REGION | Регион | `us-east-1` |

### AI

| Переменная | Описание | Пример |
|-----------|----------|--------|
| OPENAI_API_KEY | API Key OpenAI | `sk-...` |
| ANTHROPIC_API_KEY | API Key Anthropic | `sk-ant-...` |
| GOOGLE_API_KEY | API Key Google | `AIza...` |
| AI_DEFAULT_PROVIDER | Провайдер по умолчанию | `openai` |

### Безопасность

| Переменная | Описание | Пример |
|-----------|----------|--------|
| SECRET_KEY | Секретный ключ приложения | `random-secret-key` |
| JWT_SECRET | Секрет для JWT | `jwt-secret` |
| CORS_ORIGINS | Разрешённые origins | `http://localhost:8000` |

### Приложение

| Переменная | Описание | Пример |
|-----------|----------|--------|
| APP_NAME | Название приложения | `DWMB` |
| APP_VERSION | Версия | `0.9.0` |
| DEBUG | Режим отладки | `true` |
| LOG_LEVEL | Уровень логирования | `INFO` |
| DEFAULT_LANGUAGE | Язык по умолчанию | `ru` |

## Пример .env файла

```bash
# База данных
DATABASE_URL=postgresql://dwmb:password@localhost:5432/dwmb
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dwmb
DB_USER=dwmb
DB_PASSWORD=password

# S3 / MinIO
S3_ENDPOINT=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=dwmb

# AI
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key
AI_DEFAULT_PROVIDER=openai

# Безопасность
SECRET_KEY=your-secret-key
JWT_SECRET=your-jwt-secret

# Приложение
APP_NAME=DWMB
DEBUG=true
LOG_LEVEL=INFO
DEFAULT_LANGUAGE=ru
```

## Безопасность

### 1. Не коммитить .env

Добавить `.env` в `.gitignore`.

### 2. Использовать secrets

В продакшене использовать Docker Secrets или Kubernetes Secrets.

### 3. Ротация ключей

Регулярно обновлять API-ключи и пароли.

## Связанные страницы

- [[deployment/docker]] — Docker Compose
- [[architecture/overview]] — Обзор архитектуры
- [[plugins/ai-plugin]] — AI-конфигурация
- [[database/media]] — S3-конфигурация
