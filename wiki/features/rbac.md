---
type: feature
title: "RBAC"
description: "Role-Based Access Control: 3 роли (admin, editor, viewer), 13 разрешений, JWT аутентификация"
tags: [features, rbac, roles, permissions, auth, jwt]
date_created: 2026-07-22
date_updated: 2026-07-22
sources:
  - app/services/rbac.py
  - app/models/rbac.py
  - plugins/rbac/
resource: "file://raw/19.07.2026.ANALYSIS_REPORT.md"
status: AI-Generated
---

# RBAC (Role-Based Access Control)

Система контроля доступа на основе ролей, реализованная как плагин.

## Роли

| Роль | Описание |
|------|----------|
| `admin` | Полный доступ ко всем функциям |
| `editor` | Создание, редактирование, просмотр |
| `viewer` | Только просмотр |

## Разрешения (13)

| Разрешение | Admin | Editor | Viewer |
|-----------|-------|--------|--------|
| entity:create | ✅ | ✅ | ❌ |
| entity:edit | ✅ | ✅ | ❌ |
| entity:delete | ✅ | ❌ | ❌ |
| entity:view | ✅ | ✅ | ✅ |
| kind:create | ✅ | ❌ | ❌ |
| kind:edit | ✅ | ❌ | ❌ |
| template:create | ✅ | ✅ | ❌ |
| template:edit | ✅ | ✅ | ❌ |
| admin:access | ✅ | ❌ | ❌ |
| user:manage | ✅ | ❌ | ❌ |
| ai:use | ✅ | ✅ | ❌ |
| comment:create | ✅ | ✅ | ✅ |
| comment:delete | ✅ | ❌ | ❌ |

## Аутентификация

### JWT-токены

```python
# Создание токена
access_token = create_access_token(
    data={"sub": user_id, "role": role},
    expires_delta=timedelta(minutes=60)
)

# Проверка токена
payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
```

### Cookie-based

Токен хранится в HTTP-only cookie. Middleware автоматически проверяет токен и подставляет пользователя в `request.state.user`.

## Модели

```sql
role:
  role_id     UUID PK
  role_name   TEXT UNIQUE (admin, editor, viewer)
  description TEXT

permission:
  permission_id   UUID PK
  permission_code TEXT UNIQUE
  description     TEXT

user_role:
  user_id     UUID FK → user_account
  role_id     UUID FK → role
  PRIMARY KEY (user_id, role_id)

role_permission:
  role_id         UUID FK → role
  permission_id   UUID FK → permission
  PRIMARY KEY (role_id, permission_id)
```

## По умолчанию

- `admin` / `admin123` — администратор
- `user` / `user123` — обычный пользователь (viewer)

## Связанные страницы

- [[features/admin-panel]] — доступ только для admin
- [[architecture/overview]] — JWT + passlib

## Источники

- `app/services/rbac.py` — RBAC сервис
- `app/models/rbac.py` — модели
- `plugins/rbac/` — плагин
