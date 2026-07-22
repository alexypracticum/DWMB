---
type: database
title: "Seed-данные"
description: "Начальные данные DWMB: 35 типов сущностей, 250+ записей, 60+ связей, мультиязычные переводы, UI-строки"
tags: [database, seed-data, entity-kind, demo, i18n]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - raw/22.07.2026.MIMO.md
  - db/seeds/
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Seed-данные

Начальный набор данных DWMB, загружаемый при первом запуске системы.

## Структура seed-файлов

```
db/seeds/
├── 01_entity_kinds.sql          # 35 типов сущностей (4-уровневая иерархия)
├── 02_seed_data.py              # 250+ записей + 60+ связей
├── 03_ui_translations.py        # 269 UI-переводов (7 языков)
├── 04_admin_ui_strings.py       # 114 ключей админки
├── 05_field_label_translations.py  # Переводы полей
└── 06_kind_labels_all.py        # Переводы типов сущностей
```

## Типы сущностей (entity_kind)

### 35 определённых типов (4-уровневая иерархия)

| Категория | Типы |
|-----------|------|
| **Медиа** | movie, actor, director, song, musician, album, music_video |
| **Книги** | book, writer |
| **Наука** | chemical_element, phenomenon, physical_item |
| **География** | place (city, country) |
| **Люди** | human, artist, scientist |
| **Цифровые** | digital_file, photo, article, text_block |
| **Организации** | organization, classifier |
| **Концептуальные** | concept, genre, period, movement |
| **UI** | ui_string (для переводов интерфейса) |

### Примеры из 01_entity_kinds.sql

```sql
INSERT INTO entity_kind (kind_id, kind_code, description, is_active) VALUES
(gen_random_uuid(), 'movie', 'Фильм или сериал', true),
(gen_random_uuid(), 'actor', 'Актёр/актриса', true),
(gen_random_uuid(), 'book', 'Книга или публикация', true),
(gen_random_uuid(), 'chemical_element', 'Химический элемент', true),
(gen_random_uuid(), 'city', 'Город', true),
(gen_random_uuid(), 'person', 'Человек (универсальный)', true);
```

## Seed-записи (02_seed_data.py)

**250+ записей** с реальными данными, созданных через Python-скрипт:

### Примеры сущностей

| Тип | Примеры |
|-----|---------|
| movie | Матрица, Inception, Interstellar, Star Wars, Avatar |
| actor | Keanu Reeves, Leonardo DiCaprio, Scarlett Johansson |
| book | Война и мир, Гарри Поттер, Властелин Колец |
| chemical_element | Водород (H), Кислород (O), Углерод (C) |
| city | Москва, Нью-Йорк, Токио, Париж |
| song | Bohemian Rhapsody, Stairway to Heaven, Hotel California |
| musician | Queen, Led Zeppelin, The Beatles |

### Связи (60+)

```
Матрица → directed_by → Кристофер Нолан (нет, это Вачовски!)
Inception → directed_by → Кристофер Нолан
Interstellar → directed_by → Кристофер Нолан
Bohemian Rhapsody → performed_by → Queen
Queen → has_member → Фредди Меркьюри
Война и мир → written_by → Лев Толстой
```

## UI-переводы

### 03_ui_translations.py — 269 сущностей

Каждый перевод — **отдельная сущность** вида `ui_string` с мультиязычными проекциями:

```python
# Пример
{
    "kind": "ui_string",
    "code": "nav.home",
    "projections": {
        "ru": {"label": "Главная"},
        "en": {"label": "Home"},
        "de": {"label": "Startseite"},
        "fr": {"label": "Accueil"},
        "es": {"label": "Inicio"},
        "zh": {"label": "首页"},
        "ja": {"label": "ホーム"}
    }
}
```

### 04_admin_ui_strings.py — 114 ключей

Переводы элементов админ-панели.

### 05_field_label_translations.py

Переводы названий полей: "title" → "Название" (ru), "Titel" (de), "タイトル" (ja).

### 06_kind_labels_all.py

Переводы типов сущностей: "movie" → "Фильм" (ru), "Film" (de), "映画" (ja).

## Загрузка

### Автоматическая (при старте Docker)

```bash
./start.sh
# → docker compose up -d
# → python db/seeds/02_seed_data.py
```

### Ручная

```bash
# 1. Создать типы
psql -U dwmb -d dwmb -f db/seeds/01_entity_kinds.sql

# 2. Загрузить записи
python db/seeds/02_seed_data.py

# 3. Загрузить переводы UI
python db/seeds/03_ui_translations.py
python db/seeds/04_admin_ui_strings.py
python db/seeds/05_field_label_translations.py
python db/seeds/06_kind_labels_all.py
```

## Связанные страницы

- [[database/entity-model]] — куда загружаются данные
- [[database/ontology]] — типы сущностей
- [[database/relations]] — связи между записями
- [[database/multilingual]] — переводы
- [[deployment/docker]] — автоматическая загрузка при старте

## Источники

- `raw/22.07.2026.MIMO.md` — история создания seed-данных
- `db/seeds/` — исходные файлы seed-скриптов
