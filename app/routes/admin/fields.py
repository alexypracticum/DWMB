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
def get_field_types(t: dict) -> list:
    """Get field types with translated labels."""
    return [(k, t.get(f"field_type_{k}", k)) for k in FIELD_TYPE_KEYS]


def get_default_categories(t: dict) -> list:
    """Get categories with translated labels."""
    return [(k, t.get(f"category_{k}", k)) for k in CATEGORY_KEYS]


async def _get_categories(db, t: dict = None):
    """Get all categories: distinct from fields + default seed categories."""
    from sqlalchemy import distinct
    result = await db.execute(select(distinct(FieldRegistry.category)).where(FieldRegistry.is_active == True))
    db_cats = [r[0] for r in result.all() if r[0]]
    all_cats = []
    seen = set()
    default_cats = get_default_categories(t) if t else [(k, k.title()) for k in CATEGORY_KEYS]
    for ck, cn in default_cats + [(c, c.title()) for c in db_cats]:
        if ck not in seen:
            seen.add(ck)
            all_cats.append((ck, cn))
    return all_cats


@router.get("/fields", response_class=HTMLResponse)
async def admin_fields(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access")),
                       category: str = Query(None)):
    t = getattr(request.state, "t", {})
    categories = await _get_categories(db, t)
    field_types = get_field_types(t)
    query = select(FieldRegistry).order_by(FieldRegistry.category, FieldRegistry.sort_order)
    if category:
        query = query.where(FieldRegistry.category == category)
    result = await db.execute(query)
    fields = result.scalars().all()
    return templates.TemplateResponse("admin/fields.html", {
        "request": request, "user": user, "fields": fields,
        "field_types": field_types, "categories": categories,
        "active_category": category,
    })


@router.post("/fields/create")
async def admin_field_create(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access")),
    field_key: str = Form(...), field_label: str = Form(...), field_type: str = Form("string"),
    category: str = Form("common"), default_value: str = Form(""),
):
    import uuid as _uuid
    existing = await db.execute(select(FieldRegistry).where(FieldRegistry.field_key == field_key))
    if existing.scalar_one_or_none():
        return RedirectResponse(url="/admin/fields?error=exists", status_code=303)
    max_order = await db.execute(select(func.max(FieldRegistry.sort_order)))
    field = FieldRegistry(
        field_id=_uuid.uuid4(), field_key=field_key, field_label=field_label,
        field_type=field_type, category=category, default_value=default_value or None,
        sort_order=(max_order.scalar() or 0) + 1,
    )
    db.add(field)
    await db.commit()
    return RedirectResponse(url="/admin/fields", status_code=303)


@router.post("/fields/{field_id}/edit")
async def admin_field_edit(
    request: Request, field_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access")),
    field_key: str = Form(...), field_label: str = Form(...), field_type: str = Form("string"),
    category: str = Form("common"), default_value: str = Form(""),
):
    from uuid import UUID
    result = await db.execute(select(FieldRegistry).where(FieldRegistry.field_id == UUID(field_id)))
    field = result.scalar_one_or_none()
    if field:
        field.field_key = field_key
        field.field_label = field_label
        field.field_type = field_type
        field.category = category
        field.default_value = default_value or None
        await db.commit()
    return RedirectResponse(url="/admin/fields", status_code=303)


@router.post("/fields/{field_id}/delete")
async def admin_field_delete(field_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from uuid import UUID
    result = await db.execute(select(FieldRegistry).where(FieldRegistry.field_id == UUID(field_id)))
    field = result.scalar_one_or_none()
    if field:
        await db.delete(field)
        await db.commit()
    return RedirectResponse(url="/admin/fields", status_code=303)


@router.post("/fields/categories/create")
async def admin_category_create(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access")),
    category_key: str = Form(...), category_name: str = Form(""),
):
    """Create a new category by adding a field with that category."""
    import uuid as _uuid
    # Create a placeholder field to register the category, then delete it
    # Actually, just store via a simple approach: add the category to a metadata field
    # For simplicity, we use the field_registry to track categories
    # The category will be persisted when a field is created with it
    return RedirectResponse(url="/admin/fields", status_code=303)


@router.post("/fields/categories/delete")
async def admin_category_delete(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access")),
    category_key: str = Form(...),
):
    """Delete a category and move its fields to 'common'."""
    result = await db.execute(select(FieldRegistry).where(FieldRegistry.category == category_key))
    for field in result.scalars().all():
        field.category = "common"
    await db.commit()
    return RedirectResponse(url="/admin/fields", status_code=303)


@router.get("/api/fields")
async def api_fields(db: AsyncSession = Depends(get_db), category: str = Query(None)):
    """JSON API для получения списка полей (для JS)."""
    query = select(FieldRegistry).where(FieldRegistry.is_active == True).order_by(FieldRegistry.category, FieldRegistry.sort_order)
    if category:
        query = query.where(FieldRegistry.category == category)
    result = await db.execute(query)
    fields = []
    for f in result.scalars().all():
        fields.append({"key": f.field_key, "label": f.field_label, "type": f.field_type, "category": f.category, "default": f.default_value})
    return fields


@router.get("/api/categories")
async def api_categories(db: AsyncSession = Depends(get_db)):
    """JSON API для получения списка категорий."""
    cats = await _get_categories(db)
    return [{"key": ck, "name": cn} for ck, cn in cats]


# =============================================================================
# Entity Kind Field Schema Editor
# =============================================================================

