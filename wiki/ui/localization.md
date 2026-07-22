---
type: ui
title: "Локализация"
description: "Интерфейс на 7 языках: 269+ UI-сущностей-переводов с мультиязычными проекциями, переключение через cookie"
tags: [ui, localization, i18n, languages, translations]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/services/ui_translations.py
  - app/services/language.py
  - db/seeds/03_ui_translations.py
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Локализация интерфейса

DWMB интерфейс переведён на **7 языков** через систему UI-сущностей.

## Поддерживаемые языки

| Код | Язык | Флаг |
|-----|------|------|
| ru | Русский | 🇷🇺 |
| en | English | 🇬🇧 |
| de | Deutsch | 🇩🇪 |
| fr | Français | 🇫🇷 |
| es | Español | 🇪🇸 |
| zh | 中文 | 🇨🇳 |
| ja | 日本語 | 🇯🇵 |

## Архитектура переводов (v0.8.0+)

### UI-строки как сущности

Каждая строка интерфейса — отдельная **сущность** с entity_kind = "ui_string":

```
Сущность "ui_string" (code: "nav.home")
  ├── ru projection: {label: "Главная"}
  ├── en projection: {label: "Home"}
  ├── de projection: {label: "Startseite"}
  ├── fr projection: {label: "Accueil"}
  ├── es projection: {label: "Inicio"}
  ├── zh projection: {label: "首页"}
  └── ja projection: {label: "ホーム"}
```

### Покрытие

- **269+ UI-строк** (навигация, кнопки, заголовки, сообщения)
- **114 ключей** админки
- **Переводы полей** (field_registry_label)
- **Переводы типов** (entity_kind_label)

## Как работает переключение

1. Пользователь нажимает флаг языка в шапке
2. Сохраняется cookie `language=de`
3. Middleware подхватывает язык
4. Jinja2 шаблоны получают `request.state.t`
5. Страница отображается на выбранном языке

## Управление переводами

Админ-панель: `/admin/ui-translations`

- CRUD для всех UI-строк
- Экспорт/импорт в JSON
- Группировка по страницам
- Поиск по ключу

## Связанные страницы

- [[database/multilingual]] — данные + интерфейс
- [[features/admin-panel]] — управление переводами

## Источники

- `app/services/ui_translations.py`
- `app/services/language.py`
- `db/seeds/03_ui_translations.py`
