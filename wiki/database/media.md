---
type: database
title: "Медиа-хранилище"
description: "DAM (Digital Asset Management): media_asset, media_rendition, media_collection, интеграция с MinIO/S3"
tags: [database, media, dam, storage, minio]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 28.06.2026 OpenCode schema_analysis.md
  - 08.03.2026.Пишем БД c ChatGPT.md
  - 19.07.2026.Ответы_на_вопросы.md
status: stable
---

# Медиа-хранилище

Система управления цифровыми активами (DAM) в [[architecture/overview|DWMB]]: загрузка, хранение, рендеринг файлов.

## media_asset

```sql
CREATE TABLE media_asset (
    asset_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID REFERENCES entity(entity_id),
    original_name   TEXT NOT NULL,
    mime_type       TEXT NOT NULL,
    size_bytes      BIGINT NOT NULL,
    storage_backend TEXT NOT NULL,         -- 'local', 's3', 'minio'
    storage_key     TEXT NOT NULL,         -- путь в storage backend
    file_hash       TEXT,                  -- SHA-256
    width           INT,                   -- для изображений
    height          INT,
    duration_secs   NUMERIC,              -- для видео/аудио
    metadata        JSONB,
    created_at      TIMESTAMPTZ DEFAULT now(),
    version_id      BIGINT
);
```

## media_rendition

```sql
CREATE TABLE media_rendition (
    rendition_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id        UUID NOT NULL REFERENCES media_asset(asset_id) ON DELETE CASCADE,
    rendition_type  TEXT NOT NULL,         -- 'thumbnail', 'preview', 'original'
    width           INT,
    height          INT,
    storage_key     TEXT NOT NULL,
    size_bytes      BIGINT
);
```

## media_collection

```sql
CREATE TABLE media_collection (
    collection_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id       UUID REFERENCES entity(entity_id),
    name            TEXT NOT NULL,
    description     TEXT
);

CREATE TABLE media_collection_item (
    collection_id   UUID NOT NULL REFERENCES media_collection(collection_id) ON DELETE CASCADE,
    asset_id        UUID NOT NULL REFERENCES media_asset(asset_id) ON DELETE CASCADE,
    sort_order      INT DEFAULT 0,
    PRIMARY KEY (collection_id, asset_id)
);
```

## Архитектура хранилища

```
┌─────────────────┐     ┌─────────────────┐
│    FastAPI      │────▶│    MinIO (S3)   │
│  app/           │     │  bucket: dwmb   │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   media_asset   │
│   storage_key   │
│   mime_type     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ media_rendition │
│ thumbnail       │
│ preview         │
└─────────────────┘
```

## API для работы с медиа

| Эндпоинт | Метод | Описание |
|-----------|-------|----------|
| `/upload` | POST | Загрузка файла (создаёт entity kind='digital_file') |
| `/media/{asset_id}` | GET | Получение метаданных media asset |
| `/media/{asset_id}/info` | GET | Детальная информация через entity projection |
| `/media/{asset_id}` | DELETE | Удаление media asset и entity |

## Компромисс: media_asset как sidecar

По философии [[philosophy/everything-as-entity|"Всё как сущность"]] media_asset должен быть entity. Однако для производительности (O(1) hash lookup для дедупликации) media_asset остаётся как sidecar-таблица.

**Архитектура компромисса:**

```
┌─────────────────┐     ┌─────────────────┐
│    FastAPI      │────▶│    MinIO (S3)   │
│  app/           │     │  bucket: dwmb   │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│   entity        │────▶│  media_asset    │
│   kind=         │     │  (sidecar)      │
│   digital_file  │     │  file_hash      │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│projection_state │
│ original_name   │
│ mime_type       │
│ size_bytes      │
│ storage_key     │
└─────────────────┘
```

**Преимущества:**
- O(1) lookup по file_hash для дедупликации
- CRUD через entity interface
- metadata хранится в projection_state (JSONB)

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[architecture/data-model]] — Полная схема данных
- [[database/entity-model]] — Модель сущностей (проблема media_asset)
- [[plugins/ai-plugin]] — AI для анализа медиа
- [[deployment/docker]] — Настройка MinIO
