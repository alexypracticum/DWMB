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
                        new_fields.append({"key": key, "label": prop.get("title", key), "type": prop.get("type", "string")})
                    elif isinstance(prop, str):
                        new_fields.append({"key": key, "label": key.replace("_", " ").title(), "type": prop})
            block["config"]["fields"] = new_fields
    return layout_blocks
@router.get("/languages", response_class=HTMLResponse)
async def admin_languages(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.languages import Language
    result = await db.execute(select(Language).order_by(Language.sort_order))
    languages = result.scalars().all()
    return templates.TemplateResponse("admin/languages.html", {
        "request": request,
        "user": user,
        "languages": languages,
    })


@router.get("/languages/create", response_class=HTMLResponse)
async def admin_language_create_page(request: Request, user: UserAccount = Depends(require_permission("admin.access"))):
    return templates.TemplateResponse("admin/language_edit.html", {
        "request": request,
        "user": user,
        "language": None,
    })


@router.post("/languages/create")
async def admin_language_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    code: str = Form(...),
    name: str = Form(...),
    native_name: str = Form(""),
    sort_order: int = Form(0),
):
    from app.models.languages import Language
    from app.services.language import clear_language_cache

    lang = Language(
        code=code.strip().lower(),
        name=name,
        native_name=native_name or None,
        sort_order=sort_order,
    )
    db.add(lang)
    await db.commit()
    clear_language_cache()
    return RedirectResponse(url="/admin/languages", status_code=303)


@router.get("/languages/{lang_id}/edit", response_class=HTMLResponse)
async def admin_language_edit_page(
    request: Request,
    lang_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.languages import Language
    result = await db.execute(select(Language).where(Language.language_id == UUID(lang_id)))
    language = result.scalar_one_or_none()
    if not language:
        return RedirectResponse(url="/admin/languages", status_code=303)
    return templates.TemplateResponse("admin/language_edit.html", {
        "request": request,
        "user": user,
        "language": language,
    })


@router.post("/languages/{lang_id}/edit")
async def admin_language_edit(
    request: Request,
    lang_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    code: str = Form(...),
    name: str = Form(...),
    native_name: str = Form(""),
    sort_order: int = Form(0),
    is_active: bool = Form(True),
):
    from app.models.languages import Language
    from app.services.language import clear_language_cache

    result = await db.execute(select(Language).where(Language.language_id == UUID(lang_id)))
    language = result.scalar_one_or_none()
    if not language:
        return RedirectResponse(url="/admin/languages", status_code=303)

    language.code = code.strip().lower()
    language.name = name
    language.native_name = native_name or None
    language.sort_order = sort_order
    language.is_active = is_active
    await db.commit()
    clear_language_cache()
    return RedirectResponse(url="/admin/languages", status_code=303)


@router.post("/languages/{lang_id}/delete")
async def admin_language_delete(
    lang_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.languages import Language
    from app.services.language import clear_language_cache

    result = await db.execute(select(Language).where(Language.language_id == UUID(lang_id)))
    language = result.scalar_one_or_none()
    if language:
        await db.delete(language)
        await db.commit()
        clear_language_cache()
    return RedirectResponse(url="/admin/languages", status_code=303)


# =============================================================================
# UI TRANSLATIONS
# =============================================================================

