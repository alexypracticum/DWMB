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
@router.get("/relation-types", response_class=HTMLResponse)
async def admin_relation_types(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.relations import RelationType, SemanticRelation

    result = await db.execute(select(RelationType).order_by(RelationType.relation_code))
    types = result.scalars().all()

    type_data = []
    for rt in types:
        # Get inverse code
        inverse_code = None
        if rt.inverse_type_id:
            inv_result = await db.execute(select(RelationType.relation_code).where(RelationType.relation_type_id == rt.inverse_type_id))
            inverse_code = inv_result.scalar_one_or_none()

        # Count relations of this type
        count_result = await db.execute(select(func.count(SemanticRelation.relation_id)).where(SemanticRelation.relation_type_id == rt.relation_type_id))
        relation_count = count_result.scalar() or 0

        type_data.append({"rt": rt, "inverse_code": inverse_code, "relation_count": relation_count})

    t = getattr(request.state, "t", {})
    return templates.TemplateResponse("admin/relation_types.html", {
        "request": request, "user": user, "relation_types": type_data, "t": t,
    })


@router.get("/relation-types/create", response_class=HTMLResponse)
async def admin_relation_type_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.relations import RelationType
    result = await db.execute(select(RelationType).order_by(RelationType.relation_code))
    all_types = result.scalars().all()
    return templates.TemplateResponse("admin/relation_type_edit.html", {
        "request": request, "user": user, "rt": None, "all_types": all_types,
    })


@router.post("/relation-types/create")
async def admin_relation_type_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    relation_code: str = Form(""),
    relation_name: str = Form(""),
    description: str = Form(""),
    inverse_type_id: str = Form(""),
    transitive_relation: bool = Form(False),
):
    from app.models.relations import RelationType

    relation_code = relation_code.strip().lower().replace(" ", "_")
    if not relation_code or not relation_name:
        return RedirectResponse(url="/admin/relation-types/create?error=empty", status_code=303)

    existing = await db.execute(select(RelationType).where(RelationType.relation_code == relation_code))
    if existing.scalar_one_or_none():
        return RedirectResponse(url="/admin/relation-types/create?error=exists", status_code=303)

    version_result = await db.execute(select(func.max(RelationType.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    rt = RelationType(
        relation_code=relation_code,
        relation_name=relation_name,
        description=description,
        directionality='directed',  # Default, will be deprecated
        inverse_type_id=UUID(inverse_type_id) if inverse_type_id else None,
        symmetric_relation=False,  # Deprecated, kept for DB compatibility
        transitive_relation=transitive_relation,
        version_id=version_id,
    )
    db.add(rt)
    await db.flush()

    # Link inverse if specified
    if inverse_type_id:
        inv_result = await db.execute(select(RelationType).where(RelationType.relation_type_id == UUID(inverse_type_id)))
        inv = inv_result.scalar_one_or_none()
        if inv and not inv.inverse_type_id:
            inv.inverse_type_id = rt.relation_type_id

    await db.commit()
    return RedirectResponse(url="/admin/relation-types", status_code=303)


@router.get("/relation-types/{rt_id}/edit", response_class=HTMLResponse)
async def admin_relation_type_edit_page(rt_id: str, request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.relations import RelationType
    result = await db.execute(select(RelationType).where(RelationType.relation_type_id == UUID(rt_id)))
    rt = result.scalar_one_or_none()
    if not rt:
        return RedirectResponse(url="/admin/relation-types", status_code=303)

    all_result = await db.execute(select(RelationType).order_by(RelationType.relation_code))
    all_types = all_result.scalars().all()

    return templates.TemplateResponse("admin/relation_type_edit.html", {
        "request": request, "user": user, "rt": rt, "all_types": all_types,
    })


@router.post("/relation-types/{rt_id}/edit")
async def admin_relation_type_edit(
    rt_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    relation_code: str = Form(""),
    relation_name: str = Form(""),
    description: str = Form(""),
    inverse_type_id: str = Form(""),
    transitive_relation: bool = Form(False),
):
    from app.models.relations import RelationType

    result = await db.execute(select(RelationType).where(RelationType.relation_type_id == UUID(rt_id)))
    rt = result.scalar_one_or_none()
    if not rt:
        return RedirectResponse(url="/admin/relation-types", status_code=303)

    # Unlink old inverse
    if rt.inverse_type_id:
        old_inv_result = await db.execute(select(RelationType).where(RelationType.relation_type_id == rt.inverse_type_id))
        old_inv = old_inv_result.scalar_one_or_none()
        if old_inv and old_inv.inverse_type_id == rt.relation_type_id:
            old_inv.inverse_type_id = None

    rt.relation_code = relation_code.strip().lower()
    rt.relation_name = relation_name
    rt.description = description
    rt.transitive_relation = transitive_relation
    rt.inverse_type_id = UUID(inverse_type_id) if inverse_type_id else None

    # Link new inverse
    if inverse_type_id:
        inv_result = await db.execute(select(RelationType).where(RelationType.relation_type_id == UUID(inverse_type_id)))
        inv = inv_result.scalar_one_or_none()
        if inv:
            inv.inverse_type_id = rt.relation_type_id

    await db.commit()
    return RedirectResponse(url="/admin/relation-types", status_code=303)


@router.post("/relation-types/{rt_id}/delete")
async def admin_relation_type_delete(rt_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.relations import RelationType, SemanticRelation

    result = await db.execute(select(RelationType).where(RelationType.relation_type_id == UUID(rt_id)))
    rt = result.scalar_one_or_none()
    if not rt:
        return RedirectResponse(url="/admin/relation-types", status_code=303)

    # Unlink inverse
    if rt.inverse_type_id:
        inv_result = await db.execute(select(RelationType).where(RelationType.relation_type_id == rt.inverse_type_id))
        inv = inv_result.scalar_one_or_none()
        if inv and inv.inverse_type_id == rt.relation_type_id:
            inv.inverse_type_id = None

    # Delete relations of this type
    rel_result = await db.execute(select(SemanticRelation).where(SemanticRelation.relation_type_id == rt.relation_type_id))
    for rel in rel_result.scalars().all():
        await db.delete(rel)

    await db.delete(rt)
    await db.commit()
    return RedirectResponse(url="/admin/relation-types", status_code=303)


# =============================================================================
# LANGUAGES
# =============================================================================

