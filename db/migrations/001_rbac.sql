-- =============================================================================
--  RBAC (Role-Based Access Control)
--  Migration: 001_rbac.sql
-- =============================================================================

-- Role table
CREATE TABLE IF NOT EXISTS meta.role (
    role_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_code       TEXT NOT NULL UNIQUE,
    role_name       TEXT NOT NULL,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Permission table
CREATE TABLE IF NOT EXISTS meta.permission (
    permission_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_code TEXT NOT NULL UNIQUE,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Role ↔ Permission (many-to-many)
CREATE TABLE IF NOT EXISTS meta.role_permission (
    role_id         UUID NOT NULL REFERENCES meta.role(role_id) ON DELETE CASCADE,
    permission_id   UUID NOT NULL REFERENCES meta.permission(permission_id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- User ↔ Role (many-to-many)
CREATE TABLE IF NOT EXISTS meta.user_role (
    user_id         UUID NOT NULL REFERENCES meta.user_account(user_id) ON DELETE CASCADE,
    role_id         UUID NOT NULL REFERENCES meta.role(role_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- =============================================================================
--  DEFAULT ROLES
-- =============================================================================

INSERT INTO meta.role (role_code, role_name, description) VALUES
    ('admin', 'Администратор', 'Полный доступ ко всем функциям'),
    ('editor', 'Редактор', 'Создание и редактирование сущностей'),
    ('viewer', 'Наблюдатель', 'Только просмотр сущностей')
ON CONFLICT (role_code) DO NOTHING;

-- =============================================================================
--  DEFAULT PERMISSIONS
-- =============================================================================

INSERT INTO meta.permission (permission_code, description) VALUES
    ('entity.create', 'Создание сущностей'),
    ('entity.read', 'Просмотр сущностей'),
    ('entity.update', 'Редактирование сущностей'),
    ('entity.delete', 'Удаление сущностей'),
    ('entity.import', 'Импорт сущностей из внешних источников'),
    ('admin.access', 'Доступ к админ-панели'),
    ('admin.kinds', 'Управление типами сущностей'),
    ('admin.templates', 'Управление шаблонами'),
    ('admin.fields', 'Управление реестром полей'),
    ('admin.relations', 'Управление типами связей'),
    ('admin.users', 'Управление пользователями'),
    ('admin.ai', 'Настройка AI'),
    ('plugin.manage', 'Управление плагинами')
ON CONFLICT (permission_code) DO NOTHING;

-- =============================================================================
--  ROLE → PERMISSION MAPPINGS
-- =============================================================================

-- Admin: all permissions
INSERT INTO meta.role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM meta.role r, meta.permission p
WHERE r.role_code = 'admin'
ON CONFLICT DO NOTHING;

-- Editor: entity CRUD + import
INSERT INTO meta.role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM meta.role r, meta.permission p
WHERE r.role_code = 'editor'
  AND p.permission_code IN ('entity.create', 'entity.read', 'entity.update', 'entity.import')
ON CONFLICT DO NOTHING;

-- Viewer: read only
INSERT INTO meta.role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM meta.role r, meta.permission p
WHERE r.role_code = 'viewer'
  AND p.permission_code = 'entity.read'
ON CONFLICT DO NOTHING;

-- =============================================================================
--  ASSIGN ADMIN ROLE TO EXISTING ADMIN USER
-- =============================================================================

INSERT INTO meta.user_role (user_id, role_id)
SELECT ua.user_id, r.role_id
FROM meta.user_account ua, meta.role r
WHERE ua.is_admin = true AND r.role_code = 'admin'
ON CONFLICT DO NOTHING;
