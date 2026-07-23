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
@router.get("/ai", response_class=HTMLResponse)
async def admin_ai_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.ai import AiConfig as AiConfigModel, AiTaskLog as AiTaskLogModel

    result = await db.execute(select(AiConfigModel).where(AiConfigModel.is_active == True).limit(1))
    config = result.scalar_one_or_none()

    logs_result = await db.execute(
        select(AiTaskLogModel).order_by(AiTaskLogModel.created_at.desc()).limit(20)
    )
    logs = logs_result.scalars().all()

    return templates.TemplateResponse("admin/ai.html", {
        "request": request, "user": user, "config": config, "logs": logs,
    })


@router.post("/ai/save")
async def admin_ai_save(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.ai import AiConfig as AiConfigModel
    from app.services.ai import ai_service

    form = await request.form()
    provider = form.get("provider", "openai")
    model_embedding = form.get("model_embedding", "text-embedding-3-small")
    model_chat = form.get("model_chat", "gpt-4o-mini")
    api_base_url = form.get("api_base_url", "https://api.openai.com/v1")
    api_key = form.get("api_key", "")
    max_tokens = int(form.get("max_tokens", 4096) or 4096)

    result = await db.execute(select(AiConfigModel).where(AiConfigModel.is_active == True).limit(1))
    config = result.scalar_one_or_none()
    if not config:
        config = AiConfigModel(is_active=True)
        db.add(config)

    config.provider = provider
    config.model_embedding = model_embedding
    config.model_chat = model_chat
    config.api_base_url = api_base_url
    config.max_tokens = max_tokens
    if api_key:
        config.api_key_enc = ai_service.encrypt_api_key(api_key)
    config.is_active = True

    await db.commit()
    return RedirectResponse(url="/admin/ai", status_code=303)


@router.get("/ai/profiles", response_class=HTMLResponse)
async def admin_ai_profiles(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.ai import AiConfigProfile
    result = await db.execute(select(AiConfigProfile).order_by(AiConfigProfile.created_at.desc()))
    profiles = result.scalars().all()
    return templates.TemplateResponse("admin/ai_profiles.html", {
        "request": request, "user": user, "profiles": profiles,
    })


@router.post("/ai/profiles/create")
async def admin_ai_profile_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.ai import AiConfigProfile
    form = await request.form()
    profile = AiConfigProfile(
        profile_name=form.get("profile_name", "New Profile"),
        provider=form.get("provider", "openai"),
        model_embedding=form.get("model_embedding", "text-embedding-3-small"),
        model_chat=form.get("model_chat", "gpt-4o-mini"),
        api_base_url=form.get("api_base_url", "https://api.openai.com/v1"),
        max_tokens=int(form.get("max_tokens", 4096) or 4096),
    )
    db.add(profile)
    await db.commit()
    return RedirectResponse(url="/admin/ai/profiles", status_code=303)


@router.get("/plugins", response_class=HTMLResponse)
async def admin_plugins_page(request: Request, user: UserAccount = Depends(require_permission("admin.access"))):
    from plugins import get_plugins
    plugins_list = []
    for p in get_plugins():
        plugins_list.append({
            "name": p.name,
            "description": p.description,
            "version": p.version,
            "status": "active",
        })
    return templates.TemplateResponse("admin/plugins.html", {
        "request": request, "user": user, "plugins": plugins_list,
    })


@router.post("/ai/profiles/{profile_id}/activate")
async def admin_ai_profile_activate(
    profile_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.ai import AiConfigProfile, AiConfig
    # Deactivate all profiles
    result = await db.execute(select(AiConfigProfile))
    for p in result.scalars().all():
        p.is_active = False
    # Activate selected profile
    profile = await db.get(AiConfigProfile, UUID(profile_id))
    if profile:
        profile.is_active = True
        # Update main AI config
        ai_result = await db.execute(select(AiConfig).where(AiConfig.is_active == True).limit(1))
        config = ai_result.scalar_one_or_none()
        if config:
            config.provider = profile.provider
            config.model_embedding = profile.model_embedding
            config.model_chat = profile.model_chat
            config.api_base_url = profile.api_base_url
            config.max_tokens = profile.max_tokens
            if profile.api_key_enc:
                config.api_key_enc = profile.api_key_enc
    await db.commit()
    return RedirectResponse(url="/admin/ai/profiles", status_code=303)


@router.post("/ai/profiles/{profile_id}/delete")
async def admin_ai_profile_delete(
    profile_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.ai import AiConfigProfile
    profile = await db.get(AiConfigProfile, UUID(profile_id))
    if profile:
        await db.delete(profile)
        await db.commit()
    return RedirectResponse(url="/admin/ai/profiles", status_code=303)


@router.get("/plugins", response_class=HTMLResponse)
async def admin_plugins_page(request: Request, user: UserAccount = Depends(require_permission("admin.access"))):
    from plugins import get_plugins
    plugins_list = []
    for p in get_plugins():
        plugins_list.append({
            "name": p.name,
            "description": p.description,
            "version": p.version,
            "status": "active",
        })
    return templates.TemplateResponse("admin/plugins.html", {
        "request": request, "user": user, "plugins": plugins_list,
    })


# =============================================================================
#  RELATION TYPES CRUD
# =============================================================================

