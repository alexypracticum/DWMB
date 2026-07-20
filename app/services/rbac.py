"""
RBAC service — permission checking and role management.

Provides:
- get_user_permissions(user_id) → set of permission codes
- check_permission(user_id, permission_code) → bool
- require_permission(permission_code) → FastAPI dependency
"""
from functools import lru_cache
from typing import Optional
from uuid import UUID

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.models.rbac import Role, Permission, UserRole, RolePermission
from app.services.auth import get_current_user


async def get_user_permissions(db: AsyncSession, user_id: UUID) -> set[str]:
    """Get all permission codes for a user (including admin bypass)."""
    user = await db.get(UserAccount, user_id)
    if not user:
        return set()

    # Admin has all permissions
    if user.is_admin:
        result = await db.execute(select(Permission.permission_code))
        return set(result.scalars().all())

    result = await db.execute(
        select(Permission.permission_code)
        .join(RolePermission, RolePermission.permission_id == Permission.permission_id)
        .join(Role, Role.role_id == RolePermission.role_id)
        .join(UserRole, UserRole.role_id == Role.role_id)
        .where(UserRole.user_id == user_id)
    )
    return set(result.scalars().all())


async def check_permission(db: AsyncSession, user_id: UUID, permission_code: str) -> bool:
    """Check if a user has a specific permission."""
    permissions = await get_user_permissions(db, user_id)
    return permission_code in permissions


def require_permission(permission_code: str):
    """
    FastAPI dependency that checks if the current user has a permission.

    Usage:
        @router.get("/admin")
        async def admin_page(user=Depends(require_permission("admin.access"))):
            ...
    """
    async def _check(
        user: Optional[UserAccount] = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

        # Admin bypass
        if user.is_admin:
            return user

        has_perm = await check_permission(db, user.user_id, permission_code)
        if not has_perm:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: {permission_code}",
            )
        return user

    return _check
