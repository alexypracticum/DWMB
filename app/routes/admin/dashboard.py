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
@router.get("/", response_class=HTMLResponse)
async def admin_dashboard(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    entity_count = await db.scalar(select(func.count(Entity.entity_id)).where(Entity.status == "active"))
    kind_count = await db.scalar(select(func.count(EntityKind.kind_id)).where(EntityKind.is_abstract == False))
    user_count = await db.scalar(select(func.count(UserAccount.user_id)))
    template_count = await db.scalar(select(func.count(OntologyTemplate.template_id)))
    relation_count = await db.scalar(select(func.count(RelationType.relation_type_id)))

    # Entities per kind
    kind_stats_result = await db.execute(
        select(EntityKind.kind_code, func.count(Entity.entity_id))
        .join(Entity, Entity.kind_id == EntityKind.kind_id, isouter=True)
        .where(EntityKind.is_abstract == False)
        .group_by(EntityKind.kind_code)
        .order_by(func.count(Entity.entity_id).desc())
    )
    kind_stats = [{"code": code, "count": count} for code, count in kind_stats_result]

    # Recent users
    users_result = await db.execute(select(UserAccount).order_by(UserAccount.created_at.desc()).limit(10))
    users = users_result.scalars().all()

    return templates.TemplateResponse("admin/dashboard.html", {
        "request": request,
        "user": user,
        "entity_count": entity_count,
        "kind_count": kind_count,
        "user_count": user_count,
        "template_count": template_count,
        "relation_count": relation_count,
        "kind_stats": kind_stats,
        "users": users,
    })
