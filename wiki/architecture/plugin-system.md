---
type: architecture
title: "Система плагинов"
description: "Модульная архитектура плагинов DWMB: 7 плагинов с абстрактным базовым классом PluginBase"
tags: [architecture, plugins, modularity, extensibility]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - raw/22.07.2026.MIMO.md
  - plugins/
resource: "file://raw/22.07.2026.MIMO.md"
status: AI-Generated
---

# Система плагинов

DWMB использует **модульную архитектуру** на основе абстрактного базового класса `PluginBase`. Каждый плагин — отдельный пакет в директории `plugins/`.

## Базовый класс

```python
class PluginBase(ABC):
    name: str
    description: str
    version: str

    @abstractmethod
    def register(self, app: FastAPI) -> None:
        """Регистрация плагина в приложении"""
        pass

    @abstractmethod
    def get_routers(self) -> list:
        """Возвращает список APIRouter"""
        pass

    @abstractmethod
    def get_middleware(self) -> list:
        """Возвращает список middleware"""
        pass
```

## 7 плагинов

### 1. ai — AI-интеграция

| | |
|---|---|
| **Назначение** | Эмбеддинги, чат, парсинг текста, гибридный поиск |
| **Модели** | text-embedding-3-small, gpt-4o-mini |
| **Эндпоинты** | `/api/ai/parse-text`, `/api/ai/suggest-fields/{id}`, `/api/ai/search`, `/api/ai/similar/{id}` |
| **Хранение** | `ai_config`, `ai_config_profile`, `ai_task_log`, `ai_suggestion` |

Подробнее: [[plugins/ai-plugin]]

### 2. tmdb — Импорт из TMDB

| | |
|---|---|
| **Назначение** | Импорт фильмов, людей и кредитов из The Movie Database |
| **API** | TMDB API v3 |
| **Импорт** | Фильмы (movie), люди (person), кредиты (credits) |
| **Эндпоинты** | `/admin/import/tmdb` |

### 3. themes — Визуальные темы

| | |
|---|---|
| **Назначение** | 9 предустановленных тем + визуальный CSS-редактор |
| **Хранение** | `user_theme` (JSONB: colors, fonts) |
| **CSS** | CSS-переменные (primary, secondary, accent, background...) |

Подробнее: [[ui/theme-system]]

### 4. cms — CMS страницы

| | |
|---|---|
| **Назначение** | Управление контентом страниц и иерархическим меню |
| **Модели** | `page_registry`, `menu_item` |
| **Эндпоинты** | `/admin/pages`, `/admin/menu` |

Подробнее: [[frontend/cms]]

### 5. stats — Статистика

| | |
|---|---|
| **Назначение** | Графики и статистика по сущностям |
| **Визуализация** | Chart.js (bar + doughnut) |
| **Эндпоинты** | `/stats` |

### 6. rbac — RBAC (Role-Based Access Control)

| | |
|---|---|
| **Назначение** | Управление ролями и разрешениями |
| **Роли** | admin, editor, viewer |
| **Разрешения** | 13 разрешений (entity:create, entity:edit, entity:delete, admin:access...) |
| **Модели** | `role`, `permission`, `user_role` |

Подробнее: [[features/rbac]]

### 7. email — Email уведомления

| | |
|---|---|
| **Назначение** | Отправка email через SMTP |
| **Движок** | aiosmtplib |
| **Использование** | Уведомления, регистрация |

## Управление плагинами

Админ-панель: `/admin/plugins`

- Список всех плагинов с описанием и версией
- Включение/выключение плагинов
- Просмотр статуса

## Связанные страницы

- [[architecture/overview]] — общая структура
- [[deployment/docker]] — как плагины подключаются
- [[features/admin-panel]] — управление плагинами

## Источники

- `raw/22.07.2026.MIMO.md` — история создания плагинов
- `plugins/` — исходный код плагинов
