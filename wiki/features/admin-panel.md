---
type: feature
title: "Админ-панель"
description: "Управление типами сущностей, шаблонами, полями, пользователями, AI, плагинами, языками, UI-переводами и типами связей"
tags: [features, admin, management, dashboard]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/routes/admin.py
  - app/templates/admin/
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Админ-панель

Централизованная панель управления DWMB с 21 шаблоном и полным CRUD для всех системных объектов.

## Разделы админки

| Раздел | URL | Описание |
|--------|-----|----------|
| Дашборд | `/admin` | Обзор: количество сущностей, типов, записей |
| Типы сущностей | `/admin/kinds` | CRUD для entity_kind + JSON-редактор схемы |
| Шаблоны | `/admin/templates` | CRUD для ontology_template + визуальный редактор макетов |
| Поля | `/admin/fields` | CRUD для field_registry |
| Пользователи | `/admin/users` | Список пользователей, включение/выключение admin |
| AI | `/admin/ai` | Конфигурация AI, профили, логи, предложения |
| Плагины | `/admin/plugins` | Управление плагинами (включение/выключение) |
| Языки | `/admin/languages` | CRUD для языков |
| UI-переводы | `/admin/ui-translations` | Управление переводами интерфейса |
| Типы связей | `/admin/relation-types` | CRUD для relation_type |
| Страницы | `/admin/pages` | CMS страницы |
| Тема | `/admin/theme-editor` | Визуальный CSS-редактор |
| Статистика | `/stats` | Графики (Chart.js) |

## Управление типами сущностей

```
GET  /admin/kinds              → список
POST /admin/kinds/{id}/edit    → редактирование
```

Включает JSON-редактор `schema_definition` для определения полей типа.

## Управление шаблонами

```
GET  /admin/templates          → список
POST /admin/templates/create   → создание
POST /admin/templates/{id}/edit → редактирование
POST /admin/templates/{id}/delete → удаление
```

**Визуальный редактор макетов** для настройки layout_blocks.

Подробнее: [[features/visual-editor]]

## Управление AI

- Конфигурация провайдера (OpenAI)
- Профили (несколько конфигураций с переключением)
- Лог AI-задач (стоимость, токены, статус)
- AI-предложения (принятие/отклонение)

Подробнее: [[plugins/ai-plugin]]

## Управление переводами

- CRUD для UI-строк (269+ ключей)
- Экспорт/импорт в JSON
- Группировка по страницам
- 7 языков

Подробнее: [[ui/localization]]

## Управление темами

- 9 предустановленных тем
- Визуальный CSS-редактор
- Настройка цветов, шрифтов, отступов

Подробнее: [[ui/theme-system]]

## Связанные страницы

- [[features/rbac]] — кто имеет доступ к админке
- [[plugins/plugins]] — управление плагинами
- [[database/ontology]] — типы и шаблоны

## Источники

- `app/routes/admin.py` — маршруты
- `app/templates/admin/` — 21 шаблон
