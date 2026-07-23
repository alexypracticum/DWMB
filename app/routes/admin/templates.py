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
@router.get("/templates", response_class=HTMLResponse)
async def admin_templates(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    result = await db.execute(
        select(OntologyTemplate, OntologyModel)
        .join(OntologyModel, OntologyModel.model_id == OntologyTemplate.model_id)
        .order_by(OntologyModel.model_code, OntologyTemplate.template_code)
    )
    templates_list = []
    for tmpl, model in result:
        kind_code = None
        if tmpl.kind_id:
            kr = await db.execute(select(EntityKind.kind_code).where(EntityKind.kind_id == tmpl.kind_id))
            kind_code = kr.scalar_one_or_none()
        templates_list.append({"template": tmpl, "model": model, "kind_code": kind_code})

    models_result = await db.execute(select(OntologyModel).order_by(OntologyModel.model_code))
    models = models_result.scalars().all()

    kinds_result = await db.execute(select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order))
    all_kinds = kinds_result.scalars().all()

    t = getattr(request.state, "t", {})
    return templates.TemplateResponse("admin/templates.html", {
        "request": request,
        "user": user,
        "templates": templates_list,
        "models": models,
        "all_kinds": all_kinds,
        "t": t,
    })


@router.post("/templates/create")
async def admin_template_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    model_id: str = Form(...),
    kind_id: str = Form(""),
    template_code: str = Form(...),
    template_name: str = Form(...),
    description: str = Form(""),
    schema_definition: str = Form("{}"),
):
    import uuid as _uuid
    import json, hashlib
    from app.models.entities import Entity, EntityLabel
    from app.models.kinds import EntityKind

    # Check unique code
    existing = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == template_code))
    if existing.scalar_one_or_none():
        return RedirectResponse(url="/admin/templates?error=exists", status_code=303)

    # Validate JSON
    try:
        schema_json = json.loads(schema_definition) if schema_definition.strip() else {}
    except json.JSONDecodeError:
        return RedirectResponse(url="/admin/templates?error=invalid_json", status_code=303)

    # Get version
    version_result = await db.execute(select(func.max(OntologyTemplate.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    # Default layout with image_data_row as the primary block
    default_layout = [{
        "type": "image_data_row",
        "config": {
            "image_source": "poster",
            "alt_field": "title",
            "fields": []
        }
    }]

    tmpl = OntologyTemplate(
        template_id=_uuid.uuid4(),
        model_id=_uuid.UUID(model_id),
        kind_id=_uuid.UUID(kind_id) if kind_id else None,
        template_code=template_code,
        template_name=template_name,
        description=description,
        schema_definition=schema_json,
        layout_definition=default_layout,
        version_id=version_id,
    )
    db.add(tmpl)
    await db.flush()

    # Create entity for this template
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ontology_template"))
    ont_kind = kind_result.scalar_one_or_none()
    if ont_kind:
        entity_id = _uuid.uuid4()
        entity = Entity(entity_id=entity_id, entity_code=f"onttemplate_{template_code}", kind_id=ont_kind.kind_id, status="active", owner_id=user.user_id, version_id=version_id)
        db.add(entity)
        await db.flush()

        label = EntityLabel(entity_id=entity_id, language_id=await get_language_id(db, "ru"), label=template_name, description=description, is_primary=True, owner_id=user.user_id, version_id=version_id)
        db.add(label)

        # Get template for displaying ontology_template entities
        display_tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == "ontology_template_tpl"))
        display_tmpl = display_tmpl_result.scalar_one_or_none()
        if display_tmpl:
            proj_id = _uuid.uuid4()
            kind_code = ""
            if kind_id:
                k_result = await db.execute(select(EntityKind.kind_code).where(EntityKind.kind_id == _uuid.UUID(kind_id)))
                kind_code = k_result.scalar_one_or_none() or ""
            model_code = ""
            m_result = await db.execute(select(OntologyModel.model_code).where(OntologyModel.model_id == _uuid.UUID(model_id)))
            model_code = m_result.scalar_one_or_none() or ""

            proj = EntityProjection(projection_id=proj_id, entity_id=entity_id, model_id=_uuid.UUID(model_id), template_id=display_tmpl.template_id, projection_code=f"onttmpl_{template_code}", projection_name=template_name, confidence=1.0, version_id=version_id)
            db.add(proj)
            await db.flush()

            state_data = {"template_code": template_code, "template_name": template_name, "description": description, "kind_code": kind_code, "model_code": model_code, "is_active": True}
            state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
            ps = ProjectionState(projection_id=proj_id, state_data=state_data, state_hash=state_hash, is_current=True, version_id=version_id)
            db.add(ps)

    await db.commit()
    return RedirectResponse(url="/admin/templates", status_code=303)


@router.get("/templates/{template_id}/edit", response_class=HTMLResponse)
async def admin_template_edit_page(
    request: Request, template_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))
):
    from uuid import UUID
    import json

    result = await db.execute(
        select(OntologyTemplate, OntologyModel)
        .join(OntologyModel, OntologyModel.model_id == OntologyTemplate.model_id)
        .where(OntologyTemplate.template_id == UUID(template_id))
    )
    row = result.first()
    if not row:
        raise HTTPException(404)
    tmpl, model = row

    models_result = await db.execute(select(OntologyModel).order_by(OntologyModel.model_code))
    models = models_result.scalars().all()

    kinds_result = await db.execute(select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order))
    all_kinds = kinds_result.scalars().all()

    ld = tmpl.layout_definition
    if isinstance(ld, str):
        try: ld = json.loads(ld)
        except (json.JSONDecodeError, ValueError, TypeError): ld = []
    layout_blocks = ld if isinstance(ld, list) else []

    # If template has a kind, use the kind's field_schema as the source of truth
    schema_source = tmpl.schema_definition
    if tmpl.kind_id:
        kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == tmpl.kind_id))
        kind_obj = kind_result.scalar_one_or_none()
        if kind_obj and kind_obj.field_schema:
            fs = kind_obj.field_schema
            if isinstance(fs, dict) and "properties" in fs:
                schema_source = fs

    t = getattr(request.state, "t", {})
    from starlette.responses import HTMLResponse as HResp
    response = HResp(content=None)
    response = templates.TemplateResponse("admin/template_edit.html", {
        "request": request,
        "user": user,
        "template": tmpl,
        "model": model,
        "models": models,
        "all_kinds": all_kinds,
        "schema_json": json.dumps(schema_source, indent=2, ensure_ascii=False) if schema_source else "{}",
        "layout_json": json.dumps(layout_blocks, ensure_ascii=False),
        "layout_blocks_json": json.dumps(layout_blocks, ensure_ascii=False),
        "ui_translations": json.dumps(t, ensure_ascii=False),
    })
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    return response


@router.post("/templates/{template_id}/edit")
async def admin_template_edit(
    request: Request,
    template_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    model_id: str = Form(...),
    kind_id: str = Form(""),
    template_code: str = Form(...),
    template_name: str = Form(...),
    description: str = Form(""),
    schema_definition: str = Form("{}"),
    layout_definition: str = Form("[]"),
):
    from uuid import UUID
    import json, hashlib
    from app.models.entities import Entity, EntityLabel

    result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == UUID(template_id)))
    tmpl = result.scalar_one_or_none()
    if not tmpl:
        raise HTTPException(404)

    try:
        schema_json = json.loads(schema_definition) if schema_definition.strip() else {}
    except json.JSONDecodeError:
        return RedirectResponse(url=f"/admin/templates/{template_id}/edit?error=invalid_json", status_code=303)

    try:
        layout_json = json.loads(layout_definition) if layout_definition.strip() else []
    except json.JSONDecodeError:
        layout_json = []

    tmpl.model_id = UUID(model_id)
    tmpl.kind_id = UUID(kind_id) if kind_id else None
    tmpl.template_code = template_code
    tmpl.template_name = template_name
    tmpl.description = description
    tmpl.schema_definition = schema_json
    tmpl.layout_definition = layout_json

    # Sync schema back to the kind's field_schema if kind is assigned
    if tmpl.kind_id:
        kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == tmpl.kind_id))
        kind_obj = kind_result.scalar_one_or_none()
        if kind_obj:
            kind_obj.field_schema = schema_json

    # Sync layout block 'fields' config with schema properties
    layout_json = _sync_layout_fields_from_schema(layout_json, schema_json)
    tmpl.layout_definition = layout_json

    # Sync entity state_data
    entity_result = await db.execute(
        select(Entity).where(Entity.entity_code == f"onttemplate_{template_code}", Entity.status == "active")
    )
    entity = entity_result.scalar_one_or_none()
    if entity:
        # Update label
        ru_lang_id = await get_language_id(db, "ru")
        lbl_result = await db.execute(select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id, EntityLabel.language_id == ru_lang_id))
        lbl = lbl_result.scalar_one_or_none()
        if lbl:
            lbl.label = template_name
            lbl.description = description

        # Update state_data
        proj_result = await db.execute(select(EntityProjection).where(EntityProjection.entity_id == entity.entity_id))
        for proj in proj_result.scalars().all():
            ps_result = await db.execute(select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True))
            ps = ps_result.scalar_one_or_none()
            if ps:
                kind_code = ""
                if tmpl.kind_id:
                    k_result = await db.execute(select(EntityKind.kind_code).where(EntityKind.kind_id == tmpl.kind_id))
                    kind_code = k_result.scalar_one_or_none() or ""
                model_code = ""
                m_result = await db.execute(select(OntologyModel.model_code).where(OntologyModel.model_id == tmpl.model_id))
                model_code = m_result.scalar_one_or_none() or ""

                state_data = {"template_code": template_code, "template_name": template_name, "description": description, "kind_code": kind_code, "model_code": model_code, "is_active": tmpl.is_active}
                ps.state_data = state_data
                ps.state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()

    await db.commit()
    return RedirectResponse(url="/admin/templates", status_code=303)


@router.post("/templates/{template_id}/delete")
async def admin_template_delete(
    template_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))
):
    from uuid import UUID
    from app.models.entities import Entity, EntityLabel

    result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == UUID(template_id)))
    tmpl = result.scalar_one_or_none()
    if tmpl:
        # Delete entity for this template
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_code == f"onttemplate_{tmpl.template_code}")
        )
        for entity in entity_result.scalars().all():
            proj_result = await db.execute(select(EntityProjection).where(EntityProjection.entity_id == entity.entity_id))
            for proj in proj_result.scalars().all():
                ps_result = await db.execute(select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id))
                for ps in ps_result.scalars().all():
                    await db.delete(ps)
                await db.delete(proj)
            lbl_result = await db.execute(select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id))
            for lbl in lbl_result.scalars().all():
                await db.delete(lbl)
            await db.delete(entity)

        await db.delete(tmpl)
        await db.commit()
    return RedirectResponse(url="/admin/templates", status_code=303)


@router.post("/templates/{template_id}/toggle-active")
async def admin_template_toggle_active(
    template_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))
):
    from uuid import UUID
    result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == UUID(template_id)))
    tmpl = result.scalar_one_or_none()
    if tmpl:
        tmpl.is_active = not tmpl.is_active
        await db.commit()
    return RedirectResponse(url="/admin/templates", status_code=303)


# =============================================================================
#  FIELD REGISTRY
# =============================================================================

# Field type keys for translation
FIELD_TYPE_KEYS = [
    "string", "integer", "number", "boolean", "date", "datetime",
    "currency", "email", "url", "textarea", "select",
    "image", "video", "audio", "file", "gallery",
]

# Category keys for translation
CATEGORY_KEYS = [
    "common", "cinema", "music", "literature", "science", "media",
    "people", "geography", "organization", "events", "digital", "gaming",
]


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


