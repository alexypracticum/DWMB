---
type: ui
title: "Система тем"
description: "9 предустановленных визуальных тем + визуальный CSS-редактор для настройки цветов, шрифтов и отступов"
tags: [ui, themes, css, design, customization]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/services/theme.py
  - app/routes/theme_editor.py
  - plugins/themes/
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Система тем

DWMB поддерживает **9 предустановленных тем** и **визуальный CSS-редактор** для полной настройки внешнего вида.

## Предустановленные темы

| # | Название | Описание |
|---|----------|----------|
| 1 | Default Light | Светлая тема по умолчанию |
| 2 | Default Dark | Тёмная тема |
| 3 | Ocean | Морская палитра |
| 4 | Forest | Лесная палитра |
| 5 | Sunset | Тёплые тона заката |
| 6 | Nord | Nord цветовая схема |
| 7 | Tokyo Night | Токийская ночь |
| 8 | Dracula | Dracula тема |
| 9 | Custom | Пользовательская тема |

## CSS-переменные

```css
:root {
  --primary: #3b82f6;       /* Основной цвет */
  --secondary: #6366f1;     /* Вторичный */
  --accent: #f59e0b;        /* Акцентный */
  --background: #ffffff;     /* Фон */
  --surface: #f9fafb;       /* Поверхность */
  --text: #111827;           /* Текст основной */
  --text-secondary: #6b7280; /* Текст вторичный */
  --border: #e5e7eb;         /* Рамки */
  --error: #ef4444;          /* Ошибка */
  --success: #10b981;        /* Успех */
}
```

## Визуальный редактор

Доступен по адресу: `/admin/theme-editor`

- Настройка **10 цветов** через color picker
- Настройка **шрифтов** (heading, body, mono) и размеров
- **Превью в реальном времени** изменений
- Сохранение в `user_theme` (JSONB)

## Хранение

```sql
user_theme:
  theme_id    UUID PK
  user_id     UUID FK → user_account
  theme_name  TEXT
  is_dark     BOOLEAN
  is_active   BOOLEAN
  colors      JSONB  -- {primary, secondary, accent, background, ...}
  fonts       JSONB  -- {heading, body, mono, heading_size, body_size}
```

## Переключение

Переключение темы через:
- Админ-панель (`/admin/theme-editor`)
- Настройки пользователя (`/profile`)
- Прямой URL: `/theme/{theme_id}`

## Связанные страницы

- [[ui/localization]] — тема + язык
- [[ui/display-modes]] — как данные отображаются в теме

## Источники

- `app/services/theme.py` — CSS-переменные
- `app/routes/theme_editor.py` — редактор тем
- `plugins/themes/` — плагин тем
