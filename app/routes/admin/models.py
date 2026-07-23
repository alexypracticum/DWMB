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
@router.get("/models", response_class=HTMLResponse)
async def admin_models(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState

    result = await db.execute(select(OntologyModel).order_by(OntologyModel.domain, OntologyModel.model_code))
    models = result.scalars().all()

    model_data = []
    for model in models:
        tmpl_result = await db.execute(
            select(func.count(OntologyTemplate.template_id)).where(OntologyTemplate.model_id == model.model_id)
        )
        template_count = tmpl_result.scalar() or 0
        model_data.append({"model": model, "template_count": template_count})

    return templates.TemplateResponse("admin/models.html", {
        "request": request, "user": user, "models": model_data,
    })


@router.get("/models/create", response_class=HTMLResponse)
async def admin_model_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))):
    return templates.TemplateResponse("admin/model_create.html", {
        "request": request, "user": user,
    })


@router.post("/models/create")
async def admin_model_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    model_code: str = Form(""),
    domain: str = Form(""),
    description: str = Form(""),
):
    from app.models.projections import OntologyModel
    from app.models.entities import Entity, EntityLabel
    from app.models.kinds import EntityKind
    import hashlib, json as _json

    model_code = model_code.strip().lower().replace(" ", "_")
    if not model_code:
        return RedirectResponse(url="/admin/models/create?error=empty_code", status_code=303)

    existing = await db.execute(select(OntologyModel).where(OntologyModel.model_code == model_code))
    if existing.scalar_one_or_none():
        return RedirectResponse(url="/admin/models/create?error=exists", status_code=303)

    version_result = await db.execute(select(func.max(OntologyModel.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    model = OntologyModel(
        model_code=model_code,
        domain=domain,
        description=description,
        version_id=version_id,
    )
    db.add(model)
    await db.flush()

    # Create entity for this model
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ontology_model"))
    kind = kind_result.scalar_one_or_none()
    if kind:
        entity_id = uuid.uuid4()
        entity = Entity(entity_id=entity_id, entity_code=f"ontology_{model_code}", kind_id=kind.kind_id, status="active", owner_id=user.user_id, version_id=version_id)
        db.add(entity)
        await db.flush()

        label = EntityLabel(entity_id=entity_id, language_id=await get_language_id(db, "ru"), label=model_code, description=description, is_primary=True, owner_id=user.user_id, version_id=version_id)
        db.add(label)

        # Get template
        tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == "ontology_model_tpl"))
        tmpl = tmpl_result.scalar_one_or_none()
        if tmpl:
            proj_id = uuid.uuid4()
            proj = EntityProjection(projection_id=proj_id, entity_id=entity_id, model_id=model.model_id, template_id=tmpl.template_id, projection_code=f"ontmodel_{model_code}", projection_name=model_code, confidence=1.0, version_id=version_id)
            db.add(proj)
            await db.flush()

            state_data = {"model_code": model_code, "domain": domain, "description": description, "template_count": 0}
            state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
            ps = ProjectionState(projection_id=proj_id, state_data=state_data, state_hash=state_hash, is_current=True, version_id=version_id)
            db.add(ps)

    await db.commit()
    return RedirectResponse(url=f"/admin/models/{model.model_id}/edit", status_code=303)


@router.get("/models/{model_id}/edit", response_class=HTMLResponse)
async def admin_model_edit_page(
    request: Request, model_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_permission("admin.access"))
):
    from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState

    result = await db.execute(select(OntologyModel).where(OntologyModel.model_id == UUID(model_id)))
    model = result.scalar_one_or_none()
    if not model:
        return RedirectResponse(url="/admin/models", status_code=303)

    tmpl_result = await db.execute(
        select(OntologyTemplate).where(OntologyTemplate.model_id == model.model_id)
    )
    templates_list = tmpl_result.scalars().all()

    return templates.TemplateResponse("admin/model_edit.html", {
        "request": request, "user": user, "model": model, "templates": templates_list,
    })


@router.post("/models/{model_id}/edit")
async def admin_model_edit(
    model_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
    model_code: str = Form(""),
    domain: str = Form(""),
    description: str = Form(""),
):
    from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState
    from app.models.entities import Entity, EntityLabel
    from app.models.kinds import EntityKind
    import hashlib, json as _json

    result = await db.execute(select(OntologyModel).where(OntologyModel.model_id == UUID(model_id)))
    model = result.scalar_one_or_none()
    if not model:
        return RedirectResponse(url="/admin/models", status_code=303)

    # Save old model_code for entity lookup
    old_model_code = model.model_code

    model.model_code = model_code.strip().lower()
    model.domain = domain
    model.description = description

    # Sync entity state_data
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ontology_model"))
    kind = kind_result.scalar_one_or_none()
    if kind:
        # Find entity for this model (using old model_code)
        old_entity_code = f"ontology_{old_model_code}"
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_code == old_entity_code, Entity.kind_id == kind.kind_id, Entity.status == "active")
        )
        entity = entity_result.scalar_one_or_none()
        if entity:
            # Update entity_code if model_code changed
            if old_model_code != model_code:
                entity.entity_code = f"ontology_{model_code}"

            # Update label
            ru_lang_id = await get_language_id(db, "ru")
            lbl_result = await db.execute(select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id, EntityLabel.language_id == ru_lang_id))
            lbl = lbl_result.scalar_one_or_none()
            if lbl:
                lbl.label = model_code
                lbl.description = description

            # Update state_data
            proj_result = await db.execute(select(EntityProjection).where(EntityProjection.entity_id == entity.entity_id))
            for proj in proj_result.scalars().all():
                ps_result = await db.execute(select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True))
                ps = ps_result.scalar_one_or_none()
                if ps:
                    # Count templates
                    tmpl_count_result = await db.execute(select(func.count(OntologyTemplate.template_id)).where(OntologyTemplate.model_id == model.model_id))
                    tmpl_count = tmpl_count_result.scalar() or 0

                    state_data = {"model_code": model_code, "domain": domain, "description": description, "template_count": tmpl_count}
                    ps.state_data = state_data
                    ps.state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()

    await db.commit()
    return RedirectResponse(url="/admin/models", status_code=303)


@router.post("/models/{model_id}/delete")
async def admin_model_delete(
    model_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState
    from app.models.entities import Entity, EntityLabel
    from app.models.kinds import EntityKind

    result = await db.execute(select(OntologyModel).where(OntologyModel.model_id == UUID(model_id)))
    model = result.scalar_one_or_none()
    if not model:
        return RedirectResponse(url="/admin/models", status_code=303)

    # Unlink templates
    tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.model_id == model.model_id))
    for tmpl in tmpl_result.scalars().all():
        tmpl.model_id = None

    # Delete entity for this model
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ontology_model"))
    kind = kind_result.scalar_one_or_none()
    if kind:
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_code == f"ontology_{model.model_code}", Entity.kind_id == kind.kind_id)
        )
        for entity in entity_result.scalars().all():
            # Delete projections and states
            proj_result = await db.execute(select(EntityProjection).where(EntityProjection.entity_id == entity.entity_id))
            for proj in proj_result.scalars().all():
                ps_result = await db.execute(select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id))
                for ps in ps_result.scalars().all():
                    await db.delete(ps)
                await db.delete(proj)
            # Delete labels
            lbl_result = await db.execute(select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id))
            for lbl in lbl_result.scalars().all():
                await db.delete(lbl)
            await db.delete(entity)

    await db.delete(model)
    await db.commit()
    return RedirectResponse(url="/admin/models", status_code=303)


@router.get("/api/kinds")
async def api_kinds(db: AsyncSession = Depends(get_db), lang: str = Query("ru")):
    """JSON API для получения списка типов сущностей с field_schema."""
    from app.models.kinds import EntityKind, EntityKindLabel
    result = await db.execute(select(EntityKind).order_by(EntityKind.sort_order))
    kinds = result.scalars().all()
    out = []
    for k in kinds:
        label = await get_kind_label(db, k.kind_id, lang) or k.kind_code
        out.append({
            "kind_id": str(k.kind_id),
            "kind_code": k.kind_code,
            "label": label,
            "field_schema": _ensure_json_schema(k.field_schema),
        })
    return out


@router.get("/api/relation-types")
async def api_relation_types(db: AsyncSession = Depends(get_db)):
    """JSON API для получения списка типов связей."""
    from app.models.relations import RelationType
    result = await db.execute(select(RelationType).order_by(RelationType.relation_code))
    types = result.scalars().all()
    return [{"relation_type_id": str(rt.relation_type_id), "relation_code": rt.relation_code, "relation_name": rt.relation_name} for rt in types]


@router.get("/api/fields")
async def api_fields(
    category: str = None,
    db: AsyncSession = Depends(get_db),
):
    """JSON API для получения списка полей field_registry."""
    from app.models.fields import FieldRegistry
    from app.models.field_labels import FieldRegistryLabel

    query = select(FieldRegistry).where(FieldRegistry.is_active == True)
    if category:
        query = query.where(FieldRegistry.category == category)
    query = query.order_by(FieldRegistry.sort_order)

    result = await db.execute(query)
    fields = result.scalars().all()

    fields_data = []
    ru_lang_id = await get_language_id(db, "ru")
    for f in fields:
        label_result = await db.execute(
            select(FieldRegistryLabel.label)
            .where(
                FieldRegistryLabel.field_id == f.field_id,
                FieldRegistryLabel.language_id == ru_lang_id
            )
        )
        ru_label = label_result.scalar_one_or_none() or f.field_label

        fields_data.append({
            "field_id": str(f.field_id),
            "key": f.field_key,
            "label": ru_label,
            "type": f.field_type,
            "category": f.category,
            "default_value": f.default_value,
            "options": f.options if isinstance(f.options, list) else [],
        })

    return fields_data


@router.post("/api/fields")
async def api_create_field(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_permission("admin.access")),
):
    """Create a new field in field_registry."""
    from app.models.fields import FieldRegistry
    from app.models.field_labels import FieldRegistryLabel
    
    body = await request.json()

    field = FieldRegistry(
        field_id=uuid.uuid4(),
        field_key=body.get("key", ""),
        field_label=body.get("label", ""),
        field_type=body.get("type", "string"),
        category=body.get("category", "common"),
        default_value=body.get("default_value", ""),
        sort_order=body.get("sort_order", 0),
        is_active=True,
    )
    db.add(field)
    await db.flush()

    # Add Russian label
    if body.get("label"):
        ru_lang_id = await get_language_id(db, "ru")
        label = FieldRegistryLabel(
            field_id=field.field_id,
            language_id=ru_lang_id,
            label=body["label"],
            description=body.get("description", ""),
        )
        db.add(label)

    await db.commit()
    return {"ok": True, "field_id": str(field.field_id)}


