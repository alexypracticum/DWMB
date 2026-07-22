---
type: architecture
title: "Общая схема данных"
description: "Структура базы данных DWMB: 28+ таблиц, 717 строк SQL, полная схема"
tags: [architecture, data-model, schema]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - 19.07.2026.ANALYSIS_REPORT.md
  - 28.06.2026 OpenCode schema_analysis.md
  - 17.07.2026.ПРОМПТ создания БД.md
  - 21.07.2026.База данных.md
status: stable
---

# Общая схема данных

Полная схема базы данных [[architecture/overview|DWMB]]: 28+ таблиц, организованных в [[architecture/layers|10 архитектурных слоёв]].

## Основные таблицы

### Identity

```sql
CREATE TABLE entity (
    entity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_code TEXT NOT NULL UNIQUE,
    kind_id UUID REFERENCES entity_kind(kind_id),
    status TEXT DEFAULT 'draft',
    owner_id UUID REFERENCES user_account(user_id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE entity_kind (
    kind_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind_code TEXT NOT NULL UNIQUE,
    kind_name TEXT NOT NULL,
    description TEXT,
    schema JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Ontology

```sql
CREATE TABLE ontology_model (
    model_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_code TEXT NOT NULL UNIQUE,
    model_name TEXT NOT NULL,
    description TEXT,
    domain TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE ontology_template (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID REFERENCES ontology_model(model_id),
    kind_id UUID REFERENCES entity_kind(kind_id),
    field_schema JSONB NOT NULL DEFAULT '[]'::jsonb,
    version INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE field_registry (
    field_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    field_code TEXT NOT NULL UNIQUE,
    field_name TEXT NOT NULL,
    field_type TEXT NOT NULL,
    validation JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Projection

```sql
CREATE TABLE entity_projection (
    projection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL REFERENCES entity(entity_id),
    model_id UUID NOT NULL REFERENCES ontology_model(model_id),
    template_id UUID REFERENCES ontology_template(template_id),
    context_id UUID REFERENCES context(context_id),
    projection_code TEXT NOT NULL UNIQUE,
    projection_name TEXT,
    confidence NUMERIC(5,4) DEFAULT 1.0,
    valid_from TIMESTAMPTZ DEFAULT now(),
    valid_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    version_id BIGINT NOT NULL
);

CREATE TABLE projection_state (
    state_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    projection_id UUID NOT NULL REFERENCES entity_projection(projection_id),
    state_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    state_hash TEXT,
    embedding vector(384),
    is_current BOOLEAN DEFAULT true,
    valid_from TIMESTAMPTZ DEFAULT now(),
    valid_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    version_id BIGINT NOT NULL
);
```

### Relation

```sql
CREATE TABLE semantic_relation (
    relation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_projection_id UUID NOT NULL REFERENCES entity_projection(projection_id),
    target_projection_id UUID NOT NULL REFERENCES entity_projection(projection_id),
    relation_type_id UUID NOT NULL REFERENCES relation_type(relation_type_id),
    confidence NUMERIC(5,4) DEFAULT 1.0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE relation_type (
    relation_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    relation_code TEXT NOT NULL UNIQUE,
    relation_name TEXT NOT NULL,
    description TEXT,
    is_bidirectional BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Temporal

```sql
CREATE TABLE version_registry (
    version_id BIGSERIAL PRIMARY KEY,
    entity_id UUID NOT NULL,
    change_type TEXT NOT NULL,
    change_data JSONB,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE event_log (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    event_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Media

```sql
CREATE TABLE media_asset (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID REFERENCES entity(entity_id),
    original_name TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    size_bytes BIGINT NOT NULL,
    storage_backend TEXT NOT NULL,
    storage_key TEXT NOT NULL,
    file_hash TEXT,
    width INT,
    height INT,
    duration_secs NUMERIC,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    version_id BIGINT
);

CREATE TABLE media_rendition (
    rendition_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES media_asset(asset_id) ON DELETE CASCADE,
    rendition_type TEXT NOT NULL,
    width INT,
    height INT,
    storage_key TEXT NOT NULL,
    size_bytes BIGINT
);
```

### AI

```sql
CREATE TABLE ai_profile (
    profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT NOT NULL,
    model TEXT NOT NULL,
    config JSONB DEFAULT '{}'::jsonb,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE ai_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL,
    profile_id UUID REFERENCES ai_profile(profile_id),
    prompt TEXT,
    result JSONB,
    tokens_used INTEGER,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Classification

```sql
CREATE TABLE classification_system (
    system_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_code TEXT NOT NULL UNIQUE,
    system_name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE classification_node (
    node_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID NOT NULL REFERENCES classification_system(system_id),
    parent_id UUID REFERENCES classification_node(node_id),
    node_code TEXT NOT NULL,
    node_name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE entity_classification (
    classification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL REFERENCES entity(entity_id),
    node_id UUID NOT NULL REFERENCES classification_node(node_id),
    created_at TIMESTAMPTZ DEFAULT now()
);
```

## Индексы

- GIN-индексы на JSONB-поля
- B-tree индексы на entity_code, kind_id, model_id
- GiST индексы на временнóе поле (btree_gist)
- Full-text search индексы на state_data

## Связанные страницы

- [[architecture/overview]] — Обзор архитектуры
- [[architecture/layers]] — Архитектурные слои
- [[database/entity-model]] — Модель сущностей
- [[database/ontology]] — Онтологические модели
- [[database/temporal]] — Версионирование
- [[database/media]] — Медиа-хранилище
- [[database/entity-model]] — Модель сущностей (классификация)
