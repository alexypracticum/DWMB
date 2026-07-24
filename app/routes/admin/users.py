import json
from fastapi import APIRouter, Depends, Request, Form, Query, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.users import UserAccount
from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState
from app.models.fields import FieldRegistry
from app.models.relations import RelationType
from app.services.auth import require_admin
from app.services.auth import get_password_hash
from app.services.rbac import require_permission
from app.services.language_service import get_language_id, get_kind_label, get_lang
from app.services.layout import get_label

templates = Jinja2Templates(directory="app/templates")

router = APIRouter(tags=["admin"])

def _ensure_json_schema(fs):
    """Convert old array-format field_schema to JSON Schema format if needed."""
    if not fs:
        return {"properties": {}, "required": []}
    if isinstance(fs, dict) and "properties" in fs:
        return fs
    if isinstance(fs, list):
        props = {}
        required = []
        for f in fs:
            if isinstance(f, dict) and "key" in f:
                key = f["key"]
                prop = {"type": f.get("type", "string"), "title": f.get("label", key)}
                if f.get("required"):
                    required.append(key)
                props[key] = prop
        return {"properties": props, "required": []}
    return {"properties": {}, "required": []}


def _sync_layout_fields_from_schema(layout_blocks, schema_json):
    """Update image_data_row block config.fields from schema properties."""
    SKIP_KEYS = {"poster", "poster_url", "description", "content"}
    if not isinstance(layout_blocks, list) or not isinstance(schema_json, dict):
        return layout_blocks
    props = schema_json.get("properties", {})
    field_order = schema_json.get("field_order", [])
    ordered_keys = field_order if field_order else list(props.keys())
    for block in layout_blocks:
        if block.get("type") == "image_data_row" and "config" in block:
            new_fields = []
            for key in ordered_keys:
                if key in props and key not in SKIP_KEYS:
                    prop = props[key]
                    if isinstance(prop, dict):
                        new_fields.append({"key": key, "label": get_label(key), "type": prop.get("type", "string")})
                    elif isinstance(prop, str):
                        new_fields.append({"key": key, "label": key.replace("_", " ").title(), "type": prop})
            block["config"]["fields"] = new_fields
    return layout_blocks
@router.get("/users", response_class=HTMLResponse)
async def admin_users(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    result = await db.execute(select(UserAccount).order_by(UserAccount.created_at.desc()))
    users = result.scalars().all()
    return templates.TemplateResponse("admin/users.html", {
        "request": request,
        "user": user,
        "users": users,
    })


@router.post("/users/{user_id}/toggle-admin")
async def toggle_admin(user_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from uuid import UUID
    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target = result.scalar_one_or_none()
    if target:
        target.is_admin = not target.is_admin
    return RedirectResponse(url="/admin/users", status_code=303)


@router.post("/users/{user_id}/toggle-active")
async def toggle_active(user_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from uuid import UUID
    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target = result.scalar_one_or_none()
    if target:
        target.is_active = not target.is_active
    return RedirectResponse(url="/admin/users", status_code=303)


@router.post("/users/{user_id}/verify")
async def verify_user(user_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    """Manually verify a user's email (admin action when SMTP is not configured)."""
    from uuid import UUID
    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target = result.scalar_one_or_none()
    if target:
        target.email_verified = True
        target.verification_token = None
        await db.commit()
    return RedirectResponse(url="/admin/users", status_code=303)


# ─── CREATE ────────────────────────────────────────────────────

@router.get("/users/create", response_class=HTMLResponse)
async def admin_user_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    """Show create user form."""
    from app.models.rbac import Role
    roles_result = await db.execute(select(Role).order_by(Role.role_name))
    roles = roles_result.scalars().all()
    return templates.TemplateResponse("admin/user_edit.html", {
        "request": request,
        "user": user,
        "target_user": None,
        "roles": roles,
        "error": None,
    })


@router.post("/users/create")
async def admin_user_create(
    request: Request,
    username: str = Form(...),
    email: str = Form(""),
    password: str = Form(...),
    display_name: str = Form(""),
    is_admin: bool = Form(False),
    role_id: str = Form(None),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    """Create a new user."""
    from app.models.rbac import Role, UserRole

    # Validate username
    if len(username) < 3:
        roles_result = await db.execute(select(Role).order_by(Role.role_name))
        roles = roles_result.scalars().all()
        return templates.TemplateResponse("admin/user_edit.html", {
            "request": request, "user": user, "target_user": None, "roles": roles,
            "error": "Имя пользователя должно содержать минимум 3 символа",
        })

    # Check unique username
    existing = await db.execute(select(UserAccount).where(UserAccount.username == username))
    if existing.scalar_one_or_none():
        roles_result = await db.execute(select(Role).order_by(Role.role_name))
        roles = roles_result.scalars().all()
        return templates.TemplateResponse("admin/user_edit.html", {
            "request": request, "user": user, "target_user": None, "roles": roles,
            "error": "Пользователь с таким именем уже существует",
        })

    # Validate password
    if len(password) < 8:
        roles_result = await db.execute(select(Role).order_by(Role.role_name))
        roles = roles_result.scalars().all()
        return templates.TemplateResponse("admin/user_edit.html", {
            "request": request, "user": user, "target_user": None, "roles": roles,
            "error": "Пароль должен содержать минимум 8 символов",
        })

    new_user = UserAccount(
        username=username,
        email=email or None,
        password_hash=get_password_hash(password),
        display_name=display_name or username,
        is_admin=is_admin,
    )
    db.add(new_user)
    await db.flush()

    # Assign role
    if role_id:
        role = await db.execute(select(Role).where(Role.role_id == UUID(role_id)))
        role_obj = role.scalar_one_or_none()
        if role_obj:
            db.add(UserRole(user_id=new_user.user_id, role_id=role_obj.role_id))

    await db.commit()
    return RedirectResponse(url="/admin/users", status_code=303)


# ─── EDIT ──────────────────────────────────────────────────────

@router.get("/users/{user_id}/edit", response_class=HTMLResponse)
async def admin_user_edit_page(user_id: str, request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    """Show edit user form."""
    from app.models.rbac import Role, UserRole

    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target_user = result.scalar_one_or_none()
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)

    roles_result = await db.execute(select(Role).order_by(Role.role_name))
    roles = roles_result.scalars().all()

    # Get current role
    current_role_result = await db.execute(
        select(Role.role_id)
        .join(UserRole, UserRole.role_id == Role.role_id)
        .where(UserRole.user_id == target_user.user_id)
        .limit(1)
    )
    current_role_id = current_role_result.scalar_one_or_none()

    return templates.TemplateResponse("admin/user_edit.html", {
        "request": request,
        "user": user,
        "target_user": target_user,
        "roles": roles,
        "current_role_id": current_role_id,
        "error": None,
    })


@router.post("/users/{user_id}/edit")
async def admin_user_edit(
    user_id: str,
    request: Request,
    email: str = Form(""),
    display_name: str = Form(""),
    password: str = Form(""),
    is_admin: bool = Form(False),
    is_active: bool = Form(True),
    role_id: str = Form(None),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    """Update an existing user."""
    from app.models.rbac import Role, UserRole

    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target_user = result.scalar_one_or_none()
    if not target_user:
        return RedirectResponse(url="/admin/users", status_code=303)

    target_user.email = email or None
    target_user.display_name = display_name or target_user.username
    target_user.is_admin = is_admin
    target_user.is_active = is_active

    if password:
        if len(password) < 8:
            roles_result = await db.execute(select(Role).order_by(Role.role_name))
            roles = roles_result.scalars().all()
            return templates.TemplateResponse("admin/user_edit.html", {
                "request": request, "user": user, "target_user": target_user, "roles": roles,
                "error": "Пароль должен содержать минимум 8 символов",
            })
        target_user.password_hash = get_password_hash(password)

    # Update role
    if role_id:
        # Remove existing roles
        await db.execute(
            UserRole.__table__.delete().where(UserRole.user_id == target_user.user_id)
        )
        # Add new role
        role = await db.execute(select(Role).where(Role.role_id == UUID(role_id)))
        role_obj = role.scalar_one_or_none()
        if role_obj:
            db.add(UserRole(user_id=target_user.user_id, role_id=role_obj.role_id))

    await db.commit()
    return RedirectResponse(url="/admin/users", status_code=303)


# ─── DELETE ────────────────────────────────────────────────────

@router.post("/users/{user_id}/delete")
async def admin_user_delete(user_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    """Delete a user (cannot delete self)."""
    target_id = UUID(user_id)

    # Prevent self-deletion
    if target_id == user.user_id:
        return RedirectResponse(url="/admin/users", status_code=303)

    result = await db.execute(select(UserAccount).where(UserAccount.user_id == target_id))
    target = result.scalar_one_or_none()
    if target:
        # Remove user roles first
        from app.models.rbac import UserRole
        await db.execute(UserRole.__table__.delete().where(UserRole.user_id == target_id))
        await db.delete(target)
        await db.commit()

    return RedirectResponse(url="/admin/users", status_code=303)


# =============================================================================
#  TEMPLATE MANAGEMENT
# =============================================================================

