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


