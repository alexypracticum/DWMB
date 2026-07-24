"""Admin: Roles & Permissions — CRUD for RBAC roles."""
from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from app.database import get_db
from app.models.rbac import Role, Permission, RolePermission, UserRole
from app.models.users import UserAccount
from app.services.auth import require_admin
from app.services.rbac import require_permission

templates = Jinja2Templates(directory="app/templates")
router = APIRouter(tags=["admin"])


@router.get("/roles", response_class=HTMLResponse)
async def roles_list(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    result = await db.execute(select(Role).order_by(Role.role_name))
    roles = result.scalars().all()

    # Count users per role
    role_user_counts = {}
    for role in roles:
        count = await db.scalar(
            select(func.count(UserRole.user_id)).where(UserRole.role_id == role.role_id)
        )
        role_user_counts[role.role_id] = count or 0

    # Count permissions per role
    role_perm_counts = {}
    for role in roles:
        count = await db.scalar(
            select(func.count(RolePermission.permission_id)).where(RolePermission.role_id == role.role_id)
        )
        role_perm_counts[role.role_id] = count or 0

    return templates.TemplateResponse("admin/roles.html", {
        "request": request, "user": user,
        "roles": roles, "role_user_counts": role_user_counts, "role_perm_counts": role_perm_counts,
    })


@router.get("/roles/create", response_class=HTMLResponse)
async def role_create_form(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    permissions_result = await db.execute(select(Permission).order_by(Permission.permission_code))
    permissions = permissions_result.scalars().all()
    return templates.TemplateResponse("admin/role_edit.html", {
        "request": request, "user": user, "role": None, "permissions": permissions, "role_permissions": set(),
    })


@router.post("/roles/create")
async def role_create(request: Request, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access")),
                       role_code: str = Form(...), role_name: str = Form(...), description: str = Form("")):
    existing = await db.scalar(select(Role).where(Role.role_code == role_code))
    if existing:
        raise HTTPException(400, "Role code already exists")
    role = Role(role_code=role_code, role_name=role_name, description=description)
    db.add(role)
    await db.flush()
    # Handle permission checkboxes
    form = await request.form()
    perm_ids = form.getlist("permissions")
    for pid in perm_ids:
        db.add(RolePermission(role_id=role.role_id, permission_id=UUID(pid)))
    await db.commit()
    return RedirectResponse("/admin/roles", status_code=303)


@router.get("/roles/{role_id}/edit", response_class=HTMLResponse)
async def role_edit_form(request: Request, role_id: UUID, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    role = await db.get(Role, role_id)
    if not role:
        raise HTTPException(404, "Role not found")
    permissions_result = await db.execute(select(Permission).order_by(Permission.permission_code))
    permissions = permissions_result.scalars().all()
    rp_result = await db.execute(select(RolePermission.permission_id).where(RolePermission.role_id == role_id))
    role_permissions = {row[0] for row in rp_result}
    return templates.TemplateResponse("admin/role_edit.html", {
        "request": request, "user": user, "role": role, "permissions": permissions, "role_permissions": role_permissions,
    })


@router.post("/roles/{role_id}/edit")
async def role_edit(request: Request, role_id: UUID, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access")),
                     role_name: str = Form(...), description: str = Form("")):
    role = await db.get(Role, role_id)
    if not role:
        raise HTTPException(404, "Role not found")
    role.role_name = role_name
    role.description = description
    # Update permissions
    await db.execute(RolePermission.__table__.delete().where(RolePermission.role_id == role_id))
    form = await request.form()
    perm_ids = form.getlist("permissions")
    for pid in perm_ids:
        db.add(RolePermission(role_id=role_id, permission_id=UUID(pid)))
    await db.commit()
    return RedirectResponse("/admin/roles", status_code=303)


@router.post("/roles/{role_id}/delete")
async def role_delete(request: Request, role_id: UUID, db: AsyncSession = Depends(get_db), user=Depends(require_permission("admin.access"))):
    role = await db.get(Role, role_id)
    if not role:
        raise HTTPException(404, "Role not found")
    # Check if role is in use
    user_count = await db.scalar(select(func.count(UserRole.user_id)).where(UserRole.role_id == role_id))
    if user_count and user_count > 0:
        raise HTTPException(400, f"Cannot delete role: {user_count} users assigned")
    await db.execute(RolePermission.__table__.delete().where(RolePermission.role_id == role_id))
    await db.delete(role)
    await db.commit()
    return RedirectResponse("/admin/roles", status_code=303)
