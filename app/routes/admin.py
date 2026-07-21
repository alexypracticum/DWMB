from fastapi import APIRouter, Depends, Request, Form, Query, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
import uuid
from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.users import UserAccount
from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.fields import FieldRegistry
from app.models.relations import RelationType
from app.services.auth import require_admin, get_password_hash
from app.services.language import get_language_id

router = APIRouter(prefix="/admin", tags=["admin"])
templates = Jinja2Templates(directory="app/templates")


async def _get_kind_label(db, kind_id, lang="ru"):
    """Get kind label with language fallback: current → 'ru' → kind_code."""
    lang_id = await get_language_id(db, lang)
    ru_lang_id = await get_language_id(db, "ru")
    if not lang_id and not ru_lang_id:
        return None
    or_clauses = []
    if lang_id:
        or_clauses.append(EntityKindLabel.language_id == lang_id)
    if ru_lang_id:
        or_clauses.append(EntityKindLabel.language_id == ru_lang_id)
    result = await db.execute(
        select(EntityKindLabel.label).where(
            EntityKindLabel.kind_id == kind_id,
            or_(*or_clauses)
        ).order_by(
            (EntityKindLabel.language_id == lang_id).desc() if lang_id else True
        ).limit(1)
    )
    return result.scalar_one_or_none()


def _ensure_json_schema(fs):
    """Convert old array-format field_schema to JSON Schema format if needed."""
    if not fs:
        return {"properties": {}, "required": []}
    if isinstance(fs, dict) and "properties" in fs:
        return fs  # Already JSON Schema
    if isinstance(fs, list):
        # Convert old [{key, label, type}] to JSON Schema
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
    """Update image_data_row block config.fields from schema properties using field_order.
    Returns the modified layout_blocks list (same object)."""
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
async def admin_dashboard(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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


@router.get("/kinds", response_class=HTMLResponse)
async def admin_kinds(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    result = await db.execute(
        select(EntityKind).order_by(EntityKind.sort_order)
    )
    kinds = result.scalars().all()

    kind_data = []
    lang = getattr(request.state, "lang", "ru")
    for kind in kinds:
        label = await _get_kind_label(db, kind.kind_id, lang) or kind.kind_code
        fs = kind.field_schema if kind.field_schema else []
        kind_data.append({"kind": kind, "label": label, "field_count": len(fs)})

    return templates.TemplateResponse("admin/kinds.html", {
        "request": request,
        "user": user,
        "kinds": kind_data,
    })


@router.get("/users", response_class=HTMLResponse)
async def admin_users(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    result = await db.execute(select(UserAccount).order_by(UserAccount.created_at.desc()))
    users = result.scalars().all()
    return templates.TemplateResponse("admin/users.html", {
        "request": request,
        "user": user,
        "users": users,
    })


@router.post("/users/{user_id}/toggle-admin")
async def toggle_admin(user_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    from uuid import UUID
    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target = result.scalar_one_or_none()
    if target:
        target.is_admin = not target.is_admin
    return RedirectResponse(url="/admin/users", status_code=303)


@router.post("/users/{user_id}/toggle-active")
async def toggle_active(user_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    from uuid import UUID
    result = await db.execute(select(UserAccount).where(UserAccount.user_id == UUID(user_id)))
    target = result.scalar_one_or_none()
    if target:
        target.is_active = not target.is_active
    return RedirectResponse(url="/admin/users", status_code=303)


# =============================================================================
#  TEMPLATE MANAGEMENT
# =============================================================================

@router.get("/templates", response_class=HTMLResponse)
async def admin_templates(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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

    return templates.TemplateResponse("admin/templates.html", {
        "request": request,
        "user": user,
        "templates": templates_list,
        "models": models,
        "all_kinds": all_kinds,
    })


@router.post("/templates/create")
async def admin_template_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
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
    request: Request, template_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)
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
        except: ld = []
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

    return templates.TemplateResponse("admin/template_edit.html", {
        "request": request,
        "user": user,
        "template": tmpl,
        "model": model,
        "models": models,
        "all_kinds": all_kinds,
        "schema_json": json.dumps(schema_source, indent=2, ensure_ascii=False) if schema_source else "{}",
        "layout_json": json.dumps(layout_blocks, ensure_ascii=False),
        "layout_blocks_json": json.dumps(layout_blocks, ensure_ascii=False),
    })


@router.post("/templates/{template_id}/edit")
async def admin_template_edit(
    request: Request,
    template_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
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
    template_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)
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
    template_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)
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

FIELD_TYPES = [
    ("string", "Строка"), ("integer", "Целое число"), ("number", "Дробное число"),
    ("boolean", "Да/Нет"), ("date", "Дата"), ("datetime", "Дата и время"),
    ("currency", "Деньги"), ("email", "Email"), ("url", "URL"),
    ("textarea", "Текст (многострочный)"), ("select", "Выбор из списка"),
    ("image", "Изображение"), ("video", "Видео"), ("audio", "Аудио"),
    ("file", "Файл"), ("gallery", "Галерея"),
]

# Default categories - used as seed, actual categories stored in DB
DEFAULT_CATEGORIES = [
    ("common", "Общие"), ("cinema", "Кино"), ("music", "Музыка"),
    ("literature", "Литература"), ("science", "Наука"), ("media", "Медиа"),
    ("people", "Люди"), ("geography", "География"), ("organization", "Организации"),
    ("events", "События"), ("digital", "Цифровое"), ("gaming", "Игры"),
]


async def _get_categories(db):
    """Get all categories: distinct from fields + default seed categories."""
    from sqlalchemy import distinct
    result = await db.execute(select(distinct(FieldRegistry.category)).where(FieldRegistry.is_active == True))
    db_cats = [r[0] for r in result.all() if r[0]]
    all_cats = []
    seen = set()
    for ck, cn in DEFAULT_CATEGORIES + [(c, c.title()) for c in db_cats]:
        if ck not in seen:
            seen.add(ck)
            all_cats.append((ck, cn))
    return all_cats


@router.get("/fields", response_class=HTMLResponse)
async def admin_fields(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin),
                       category: str = Query(None)):
    categories = await _get_categories(db)
    query = select(FieldRegistry).order_by(FieldRegistry.category, FieldRegistry.sort_order)
    if category:
        query = query.where(FieldRegistry.category == category)
    result = await db.execute(query)
    fields = result.scalars().all()
    return templates.TemplateResponse("admin/fields.html", {
        "request": request, "user": user, "fields": fields,
        "field_types": FIELD_TYPES, "categories": categories,
        "active_category": category,
    })


@router.post("/fields/create")
async def admin_field_create(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin),
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
    request: Request, field_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin),
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
async def admin_field_delete(field_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    from uuid import UUID
    result = await db.execute(select(FieldRegistry).where(FieldRegistry.field_id == UUID(field_id)))
    field = result.scalar_one_or_none()
    if field:
        await db.delete(field)
        await db.commit()
    return RedirectResponse(url="/admin/fields", status_code=303)


@router.post("/fields/categories/create")
async def admin_category_create(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin),
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
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin),
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

@router.get("/kinds/{kind_id}/edit", response_class=HTMLResponse)
async def admin_kind_edit_page(request: Request, kind_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    from uuid import UUID
    from app.models.kinds import EntityKind, EntityKindLabel
    result = await db.execute(select(EntityKind).where(EntityKind.kind_id == UUID(kind_id)))
    kind = result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/kinds", status_code=303)
    lbl_result = await db.execute(
        select(EntityKindLabel).where(EntityKindLabel.kind_id == kind.kind_id)
    )
    from app.services.language import get_language_code
    labels = {}
    for l in lbl_result.scalars().all():
        code = await get_language_code(db, l.language_id)
        if code:
            labels[code] = l
    import json
    fs = kind.field_schema if kind.field_schema else []
    field_schema_json = json.dumps(_ensure_json_schema(fs), ensure_ascii=False, indent=2)
    return templates.TemplateResponse("admin/kind_edit.html", {
        "request": request, "user": user, "kind": kind, "labels": labels,
        "field_schema_json": field_schema_json,
    })


@router.post("/kinds/{kind_id}/edit")
async def admin_kind_edit_save(
    kind_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
    kind_code: str = Form(""),
    label_ru: str = Form(""),
    label_en: str = Form(""),
    description: str = Form(""),
    is_abstract: bool = Form(False),
    sort_order: int = Form(0),
    field_schema: str = Form("[]"),
):
    from uuid import UUID
    from app.models.kinds import EntityKind, EntityKindLabel
    import json

    result = await db.execute(select(EntityKind).where(EntityKind.kind_id == UUID(kind_id)))
    kind = result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/kinds", status_code=303)

    try:
        fs = json.loads(field_schema) if field_schema.strip() else {}
    except json.JSONDecodeError:
        fs = {}
    # Ensure JSON Schema format
    fs = _ensure_json_schema(fs)

    kind.kind_code = kind_code
    kind.description = description
    kind.is_abstract = is_abstract
    kind.sort_order = sort_order
    kind.field_schema = fs

    # Sync schema to all linked templates
    tmpl_result = await db.execute(
        select(OntologyTemplate).where(OntologyTemplate.kind_id == kind.kind_id)
    )
    for tmpl in tmpl_result.scalars().all():
        tmpl.schema_definition = fs
        _ld = tmpl.layout_definition
        if isinstance(_ld, str):
            try: _ld = json.loads(_ld)
            except: _ld = []
        _ld = _sync_layout_fields_from_schema(_ld, fs)
        tmpl.layout_definition = _ld

    # Update labels
    ru_lang_id = await get_language_id(db, "ru")
    en_lang_id = await get_language_id(db, "en")
    if label_ru:
        if ru_lang_id:
            lbl = (await db.execute(select(EntityKindLabel).where(
                EntityKindLabel.kind_id == kind.kind_id, EntityKindLabel.language_id == ru_lang_id
            ))).scalar_one_or_none()
        else:
            lbl = None
        if lbl:
            lbl.label = label_ru
        else:
            db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label=label_ru))
    if label_en:
        if en_lang_id:
            lbl = (await db.execute(select(EntityKindLabel).where(
                EntityKindLabel.kind_id == kind.kind_id, EntityKindLabel.language_id == en_lang_id
            ))).scalar_one_or_none()
        else:
            lbl = None
        if lbl:
            lbl.label = label_en
        else:
            db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=en_lang_id, label=label_en))

    await db.commit()
    return RedirectResponse(url="/admin/kinds", status_code=303)


@router.get("/kinds/create", response_class=HTMLResponse)
async def admin_kind_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    return templates.TemplateResponse("admin/kind_create.html", {
        "request": request, "user": user,
    })


@router.post("/kinds/create")
async def admin_kind_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
    kind_code: str = Form(""),
    label_ru: str = Form(""),
    label_en: str = Form(""),
    description: str = Form(""),
    is_abstract: bool = Form(False),
    sort_order: int = Form(0),
    field_schema: str = Form("{}"),
):
    from app.models.kinds import EntityKind, EntityKindLabel
    import json

    # Validate kind_code
    kind_code = kind_code.strip().lower().replace(" ", "_")
    if not kind_code:
        return RedirectResponse(url="/admin/kinds/create?error=empty_code", status_code=303)

    # Check unique
    existing = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind_code))
    if existing.scalar_one_or_none():
        return RedirectResponse(url="/admin/kinds/create?error=exists", status_code=303)

    # Parse schema
    try:
        fs = json.loads(field_schema) if field_schema.strip() else {}
    except json.JSONDecodeError:
        fs = {}
    fs = _ensure_json_schema(fs)

    # Get version
    version_result = await db.execute(select(func.max(EntityKind.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    kind = EntityKind(
        kind_code=kind_code,
        description=description,
        is_abstract=is_abstract,
        sort_order=sort_order,
        field_schema=fs,
        version_id=version_id,
    )
    db.add(kind)
    await db.flush()

    # Add labels
    if label_ru:
        ru_lang_id = await get_language_id(db, "ru")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label=label_ru))
    if label_en:
        en_lang_id = await get_language_id(db, "en")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=en_lang_id, label=label_en))

    await db.commit()
    return RedirectResponse(url=f"/admin/kinds/{kind.kind_id}/edit", status_code=303)


@router.post("/kinds/{kind_id}/delete")
async def admin_kind_delete(
    kind_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    from app.models.kinds import EntityKind, EntityKindLabel
    from app.models.projections import OntologyTemplate

    result = await db.execute(select(EntityKind).where(EntityKind.kind_id == UUID(kind_id)))
    kind = result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/kinds", status_code=303)

    # Unlink templates from this kind
    tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.kind_id == kind.kind_id))
    for tmpl in tmpl_result.scalars().all():
        tmpl.kind_id = None

    # Delete labels
    lbl_result = await db.execute(select(EntityKindLabel).where(EntityKindLabel.kind_id == kind.kind_id))
    for lbl in lbl_result.scalars().all():
        await db.delete(lbl)

    # Delete kind
    await db.delete(kind)
    await db.commit()
    return RedirectResponse(url="/admin/kinds", status_code=303)


# =============================================================================
#  ONTOLOGY MODEL CRUD
# =============================================================================

@router.get("/models", response_class=HTMLResponse)
async def admin_models(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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
async def admin_model_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    return templates.TemplateResponse("admin/model_create.html", {
        "request": request, "user": user,
    })


@router.post("/models/create")
async def admin_model_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
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
    request: Request, model_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)
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
    user: UserAccount = Depends(require_admin),
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
    user: UserAccount = Depends(require_admin),
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
        label = await _get_kind_label(db, k.kind_id, lang) or k.kind_code
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
    user: UserAccount = Depends(require_admin),
):
    """Create a new field in field_registry."""
    from app.models.fields import FieldRegistry
    from app.models.field_labels import FieldRegistryLabel
    import uuid

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


@router.put("/api/fields/{field_id}")
async def api_update_field(
    field_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Update a field in field_registry."""
    from app.models.fields import FieldRegistry
    from app.models.field_labels import FieldRegistryLabel
    from uuid import UUID

    body = await request.json()

    result = await db.execute(
        select(FieldRegistry).where(FieldRegistry.field_id == UUID(field_id))
    )
    field = result.scalar_one_or_none()
    if not field:
        return {"ok": False, "error": "Field not found"}

    if "key" in body:
        field.field_key = body["key"]
    if "label" in body:
        field.field_label = body["label"]
    if "type" in body:
        field.field_type = body["type"]
    if "category" in body:
        field.category = body["category"]
    if "default_value" in body:
        field.default_value = body["default_value"]
    if "sort_order" in body:
        field.sort_order = body["sort_order"]
    if "is_active" in body:
        field.is_active = body["is_active"]

    # Update Russian label
    if "label" in body:
        ru_lang_id = await get_language_id(db, "ru")
        label_result = await db.execute(
            select(FieldRegistryLabel).where(
                FieldRegistryLabel.field_id == UUID(field_id),
                FieldRegistryLabel.language_id == ru_lang_id
            )
        )
        label = label_result.scalar_one_or_none()
        if label:
            label.label = body["label"]
        else:
            db.add(FieldRegistryLabel(
                field_id=UUID(field_id),
                language_id=ru_lang_id,
                label=body["label"],
            ))

    await db.commit()
    return {"ok": True}


@router.delete("/api/fields/{field_id}")
async def api_delete_field(
    field_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Delete a field from field_registry."""
    from app.models.fields import FieldRegistry
    from uuid import UUID

    result = await db.execute(
        select(FieldRegistry).where(FieldRegistry.field_id == UUID(field_id))
    )
    field = result.scalar_one_or_none()
    if not field:
        return {"ok": False, "error": "Field not found"}

    await db.delete(field)
    await db.commit()
    return {"ok": True}


@router.post("/api/templates/{template_id}/schema")
async def api_save_template_schema(
    template_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Save schema_definition and layout_definition for a template.
    Also syncs back to the linked EntityKind if present."""
    from app.models.projections import OntologyTemplate
    from app.models.kinds import EntityKind
    from uuid import UUID
    import json

    body = await request.json()

    result = await db.execute(
        select(OntologyTemplate).where(OntologyTemplate.template_id == UUID(template_id))
    )
    template = result.scalar_one_or_none()
    if not template:
        return {"ok": False, "error": "Template not found"}

    if "schema_definition" in body:
        schema_json = body["schema_definition"]
        template.schema_definition = schema_json
        # Sync back to linked kind
        if template.kind_id:
            kind_result = await db.execute(
                select(EntityKind).where(EntityKind.kind_id == template.kind_id)
            )
            kind_obj = kind_result.scalar_one_or_none()
            if kind_obj:
                kind_obj.field_schema = schema_json
                # Also update layout blocks in the template to match schema order
                _ld = template.layout_definition
                if isinstance(_ld, str):
                    try: _ld = json.loads(_ld)
                    except: _ld = []
                _ld = _sync_layout_fields_from_schema(_ld, schema_json)
                template.layout_definition = _ld

    if "layout_definition" in body:
        template.layout_definition = body["layout_definition"]

    await db.commit()
    return {"ok": True}


# =============================================================================
#  AI CONFIGURATION
# =============================================================================

@router.get("/ai", response_class=HTMLResponse)
async def admin_ai_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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
    user: UserAccount = Depends(require_admin),
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
async def admin_ai_profiles(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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
    user: UserAccount = Depends(require_admin),
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
async def admin_plugins_page(request: Request, user: UserAccount = Depends(require_admin)):
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
    user: UserAccount = Depends(require_admin),
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


@router.get("/plugins", response_class=HTMLResponse)
async def admin_plugins_page(request: Request, user: UserAccount = Depends(require_admin)):
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


@router.post("/ai/profiles/{profile_id}/delete")
async def admin_ai_profile_delete(
    profile_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    from app.models.ai import AiConfigProfile
    profile = await db.get(AiConfigProfile, UUID(profile_id))
    if profile:
        await db.delete(profile)
        await db.commit()
    return RedirectResponse(url="/admin/ai/profiles", status_code=303)


@router.get("/plugins", response_class=HTMLResponse)
async def admin_plugins_page(request: Request, user: UserAccount = Depends(require_admin)):
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

@router.get("/relation-types", response_class=HTMLResponse)
async def admin_relation_types(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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

    return templates.TemplateResponse("admin/relation_types.html", {
        "request": request, "user": user, "relation_types": type_data,
    })


@router.get("/relation-types/create", response_class=HTMLResponse)
async def admin_relation_type_create_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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
    user: UserAccount = Depends(require_admin),
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
async def admin_relation_type_edit_page(rt_id: str, request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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
    user: UserAccount = Depends(require_admin),
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
async def admin_relation_type_delete(rt_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
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

@router.get("/languages", response_class=HTMLResponse)
async def admin_languages(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_admin)):
    from app.models.languages import Language
    result = await db.execute(select(Language).order_by(Language.sort_order))
    languages = result.scalars().all()
    return templates.TemplateResponse("admin/languages.html", {
        "request": request,
        "user": user,
        "languages": languages,
    })


@router.get("/languages/create", response_class=HTMLResponse)
async def admin_language_create_page(request: Request, user: UserAccount = Depends(require_admin)):
    return templates.TemplateResponse("admin/language_edit.html", {
        "request": request,
        "user": user,
        "language": None,
    })


@router.post("/languages/create")
async def admin_language_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
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
    user: UserAccount = Depends(require_admin),
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
    user: UserAccount = Depends(require_admin),
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
    user: UserAccount = Depends(require_admin),
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

@router.get("/ui-translations", response_class=HTMLResponse)
async def admin_ui_translations(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
    lang: str = Query("ru"),
    search: str = Query(""),
):
    from app.models.languages import Language
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState, OntologyModel
    from app.services.ui_translations import clear_translations_cache
    
    # Get all languages
    lang_result = await db.execute(select(Language).order_by(Language.sort_order))
    languages = lang_result.scalars().all()
    
    # Get ui_string kind
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
    kind = kind_result.scalar_one_or_none()
    if not kind:
        return templates.TemplateResponse("admin/ui_translations.html", {
            "request": request, "user": user, "translations": [],
            "languages": languages, "current_lang": lang, "search": search,
            "error": "EntityKind 'ui_string' not found. Run migration 008.",
        })
    
    # Get language model
    model_result = await db.execute(select(OntologyModel).where(OntologyModel.model_code == "language"))
    model = model_result.scalar_one_or_none()
    
    # Get current language ID
    lang_obj_result = await db.execute(select(Language).where(Language.code == lang))
    lang_obj = lang_obj_result.scalar_one_or_none()
    
    # Get all ui_string entities
    entities_result = await db.execute(
        select(Entity).where(Entity.kind_id == kind.kind_id, Entity.status == "active")
        .order_by(Entity.entity_code)
    )
    entities = entities_result.scalars().all()
    
    # For each entity, get the translation for current language
    translations = []
    for entity in entities:
        # Get projection for current language
        value = ""
        if model and lang_obj:
            proj_result = await db.execute(
                select(ProjectionState.state_data)
                .join(EntityProjection)
                .where(
                    EntityProjection.entity_id == entity.entity_id,
                    EntityProjection.model_id == model.model_id,
                    ProjectionState.is_current == True
                )
            )
            for state_data in proj_result.scalars().all():
                if state_data and state_data.get("key") == entity.entity_code:
                    value = state_data.get("value", "")
                    break
        
        # Apply search filter
        if search and search.lower() not in entity.entity_code.lower() and search.lower() not in value.lower():
            continue
        
        translations.append({
            "key": entity.entity_code,
            "value": value,
            "entity_id": entity.entity_id,
        })
    
    return templates.TemplateResponse("admin/ui_translations.html", {
        "request": request,
        "user": user,
        "translations": translations,
        "languages": languages,
        "current_lang": lang,
        "search": search,
    })


@router.post("/ui-translations/update")
async def admin_ui_translation_update(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    from app.models.languages import Language
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
    from app.models.entities import Context
    from app.services.ui_translations import clear_translations_cache
    import hashlib, json, uuid
    
    form = await request.form()
    key = form.get("key", "")
    lang_code = form.get("lang", "ru")
    value = form.get("value", "")
    
    if not key:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Get required IDs
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
    kind = kind_result.scalar_one_or_none()
    model_result = await db.execute(select(OntologyModel).where(OntologyModel.model_code == "language"))
    model = model_result.scalar_one_or_none()
    template_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == "ui_translation"))
    template = template_result.scalar_one_or_none()
    lang_result = await db.execute(select(Language).where(Language.code == lang_code))
    lang_obj = lang_result.scalar_one_or_none()
    ctx_result = await db.execute(select(Context).where(Context.context_code == "default"))
    ctx = ctx_result.scalar_one_or_none()
    
    if not all([kind, model, template, lang_obj, ctx]):
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Find or create entity
    entity_result = await db.execute(
        select(Entity).where(Entity.entity_code == key, Entity.kind_id == kind.kind_id)
    )
    entity = entity_result.scalar_one_or_none()
    
    if not entity:
        # Create new entity
        entity = Entity(
            entity_id=uuid.uuid4(),
            entity_code=key,
            kind_id=kind.kind_id,
            status="active",
            version_id=1,
        )
        db.add(entity)
        await db.flush()
        
        # Create Russian label
        ru_lang_result = await db.execute(select(Language).where(Language.code == "ru"))
        ru_lang = ru_lang_result.scalar_one_or_none()
        if ru_lang:
            label = EntityLabel(
                entity_id=entity.entity_id,
                language_id=ru_lang.language_id,
                label=value if lang_code == "ru" else key,
                is_primary=True,
                version_id=1,
            )
            db.add(label)
    
    # Find or update projection for this language
    proj_result = await db.execute(
        select(EntityProjection, ProjectionState)
        .join(ProjectionState, ProjectionState.projection_id == EntityProjection.projection_id)
        .where(
            EntityProjection.entity_id == entity.entity_id,
            EntityProjection.model_id == model.model_id,
            ProjectionState.is_current == True
        )
    )
    
    found = False
    for proj, ps in proj_result:
        # Check if this projection is for the correct language
        if proj.projection_code and proj.projection_code.endswith(f"_{lang_code}"):
            if ps.state_data and ps.state_data.get("key") == key:
                # Update existing projection
                ps.state_data = {"key": key, "value": value}
                ps.state_hash = hashlib.sha256(json.dumps({"key": key, "value": value}, sort_keys=True).encode()).hexdigest()
                from sqlalchemy.orm.attributes import flag_modified
                flag_modified(ps, "state_data")
                flag_modified(ps, "state_hash")
                found = True
                break
    
    if not found:
        # Create new projection
        proj_id = uuid.uuid4()
        proj = EntityProjection(
            projection_id=proj_id,
            entity_id=entity.entity_id,
            model_id=model.model_id,
            template_id=template.template_id,
            context_id=ctx.context_id,
            projection_code=f"{key}_{lang_code}",
            projection_name=f"{key} ({lang_code})",
            confidence=1.0,
            version_id=1,
        )
        db.add(proj)
        await db.flush()
        
        state_data = {"key": key, "value": value}
        state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True).encode()).hexdigest()
        ps = ProjectionState(
            projection_id=proj_id,
            state_data=state_data,
            state_hash=state_hash,
            is_current=True,
            version_id=1,
        )
        db.add(ps)
    
    await db.commit()
    clear_translations_cache()
    
    return RedirectResponse(url=f"/admin/ui-translations?lang={lang_code}", status_code=303)


@router.post("/ui-translations/create")
async def admin_ui_translation_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    from app.models.languages import Language
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
    from app.models.entities import Context
    from app.services.ui_translations import clear_translations_cache
    import hashlib, json, uuid
    
    form = await request.form()
    key = form.get("key", "").strip()
    lang_code = form.get("lang", "ru")
    value = form.get("value", "")
    
    if not key:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Sanitize key (lowercase, underscores only)
    import re
    key = re.sub(r'[^a-z0-9_]', '_', key.lower())
    key = re.sub(r'_+', '_', key).strip('_')
    
    if not key:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Get required IDs
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
    kind = kind_result.scalar_one_or_none()
    model_result = await db.execute(select(OntologyModel).where(OntologyModel.model_code == "language"))
    model = model_result.scalar_one_or_none()
    template_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == "ui_translation"))
    template = template_result.scalar_one_or_none()
    lang_result = await db.execute(select(Language).where(Language.code == lang_code))
    lang_obj = lang_result.scalar_one_or_none()
    ctx_result = await db.execute(select(Context).where(Context.context_code == "default"))
    ctx = ctx_result.scalar_one_or_none()
    
    if not all([kind, model, template, lang_obj, ctx]):
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Check if key already exists
    existing_result = await db.execute(
        select(Entity).where(Entity.entity_code == key, Entity.kind_id == kind.kind_id)
    )
    if existing_result.scalar_one_or_none():
        return RedirectResponse(url=f"/admin/ui-translations?lang={lang_code}", status_code=303)
    
    # Create entity
    entity = Entity(
        entity_id=uuid.uuid4(),
        entity_code=key,
        kind_id=kind.kind_id,
        status="active",
        version_id=1,
    )
    db.add(entity)
    await db.flush()
    
    # Create Russian label (primary)
    ru_lang_result = await db.execute(select(Language).where(Language.code == "ru"))
    ru_lang = ru_lang_result.scalar_one_or_none()
    if ru_lang:
        label = EntityLabel(
            entity_id=entity.entity_id,
            language_id=ru_lang.language_id,
            label=value if lang_code == "ru" else key,
            is_primary=True,
            version_id=1,
        )
        db.add(label)
    
    # Create projection for this language
    proj_id = uuid.uuid4()
    proj = EntityProjection(
        projection_id=proj_id,
        entity_id=entity.entity_id,
        model_id=model.model_id,
        template_id=template.template_id,
        context_id=ctx.context_id,
        projection_code=f"{key}_{lang_code}",
        projection_name=f"{key} ({lang_code})",
        confidence=1.0,
        version_id=1,
    )
    db.add(proj)
    await db.flush()
    
    state_data = {"key": key, "value": value}
    state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True).encode()).hexdigest()
    ps = ProjectionState(
        projection_id=proj_id,
        state_data=state_data,
        state_hash=state_hash,
        is_current=True,
        version_id=1,
    )
    db.add(ps)
    
    await db.commit()
    clear_translations_cache()
    
    return RedirectResponse(url=f"/admin/ui-translations?lang={lang_code}", status_code=303)


@router.post("/ui-translations/delete")
async def admin_ui_translation_delete(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    from app.models.languages import Language
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState
    from app.services.ui_translations import clear_translations_cache
    
    form = await request.form()
    key = form.get("key", "")
    lang_code = form.get("lang", "ru")
    
    if not key:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Get ui_string kind
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
    kind = kind_result.scalar_one_or_none()
    if not kind:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Find entity
    entity_result = await db.execute(
        select(Entity).where(Entity.entity_code == key, Entity.kind_id == kind.kind_id)
    )
    entity = entity_result.scalar_one_or_none()
    if not entity:
        return RedirectResponse(url=f"/admin/ui-translations?lang={lang_code}", status_code=303)
    
    # Delete all projections and states for this entity
    proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == entity.entity_id)
    )
    for proj in proj_result.scalars().all():
        state_result = await db.execute(
            select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id)
        )
        for state in state_result.scalars().all():
            await db.delete(state)
        await db.delete(proj)
    
    # Delete entity
    await db.delete(entity)
    await db.commit()
    clear_translations_cache()
    
    return RedirectResponse(url=f"/admin/ui-translations?lang={lang_code}", status_code=303)


@router.get("/ui-translations/export")
async def admin_ui_translation_export(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
    lang: str = Query("all"),
):
    from fastapi.responses import JSONResponse
    from app.models.languages import Language
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState, OntologyModel
    
    # Get ui_string kind
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
    kind = kind_result.scalar_one_or_none()
    if not kind:
        return JSONResponse({"error": "ui_string kind not found"}, status_code=404)
    
    # Get language model
    model_result = await db.execute(select(OntologyModel).where(OntologyModel.model_code == "language"))
    model = model_result.scalar_one_or_none()
    
    # Get all languages
    lang_result = await db.execute(select(Language).order_by(Language.sort_order))
    languages = lang_result.scalars().all()
    
    # Get all ui_string entities
    entities_result = await db.execute(
        select(Entity).where(Entity.kind_id == kind.kind_id, Entity.status == "active")
        .order_by(Entity.entity_code)
    )
    entities = entities_result.scalars().all()
    
    # Build export data
    export_data = {
        "version": "1.0",
        "languages": [l.code for l in languages],
        "translations": {}
    }
    
    for entity in entities:
        key = entity.entity_code
        export_data["translations"][key] = {}
        
        if model:
            proj_result = await db.execute(
                select(ProjectionState.state_data)
                .join(EntityProjection)
                .where(
                    EntityProjection.entity_id == entity.entity_id,
                    EntityProjection.model_id == model.model_id,
                    ProjectionState.is_current == True
                )
            )
            for state_data in proj_result.scalars().all():
                if state_data and "key" in state_data and "value" in state_data:
                    # Determine language from projection_code suffix
                    proj_code = state_data.get("key", "")
                    # Try to find matching language
                    for l in languages:
                        if state_data.get("key") == key:
                            # This is a translation for some language
                            # We need to check which language this projection is for
                            pass
    
    # Simpler approach: just export all translations by language
    export_data = {
        "version": "1.0",
        "languages": [l.code for l in languages],
        "translations": {}
    }
    
    for entity in entities:
        key = entity.entity_code
        export_data["translations"][key] = {}
        
        if model:
            proj_result = await db.execute(
                select(EntityProjection, ProjectionState.state_data)
                .join(ProjectionState, ProjectionState.projection_id == EntityProjection.projection_id)
                .where(
                    EntityProjection.entity_id == entity.entity_id,
                    EntityProjection.model_id == model.model_id,
                    ProjectionState.is_current == True
                )
            )
            for proj, state_data in proj_result:
                if state_data and "key" in state_data and "value" in state_data:
                    # Extract language from projection_code (format: key_langcode)
                    proj_code = proj.projection_code or ""
                    for l in languages:
                        if proj_code.endswith(f"_{l.code}"):
                            export_data["translations"][key][l.code] = state_data["value"]
                            break
    
    return JSONResponse(export_data)


@router.post("/ui-translations/import")
async def admin_ui_translation_import(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    from fastapi.responses import JSONResponse
    from app.models.languages import Language
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
    from app.models.entities import Context
    from app.services.ui_translations import clear_translations_cache
    import hashlib, json, uuid
    
    try:
        body = await request.json()
    except Exception:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    translations = body.get("translations", {})
    if not translations:
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Get required IDs
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == "ui_string"))
    kind = kind_result.scalar_one_or_none()
    model_result = await db.execute(select(OntologyModel).where(OntologyModel.model_code == "language"))
    model = model_result.scalar_one_or_none()
    template_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_code == "ui_translation"))
    template = template_result.scalar_one_or_none()
    ctx_result = await db.execute(select(Context).where(Context.context_code == "default"))
    ctx = ctx_result.scalar_one_or_none()
    
    if not all([kind, model, template, ctx]):
        return RedirectResponse(url="/admin/ui-translations", status_code=303)
    
    # Get all languages
    lang_result = await db.execute(select(Language))
    languages = {l.code: l for l in lang_result.scalars().all()}
    
    imported = 0
    for key, lang_values in translations.items():
        if not isinstance(lang_values, dict):
            continue
        
        # Find or create entity
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_code == key, Entity.kind_id == kind.kind_id)
        )
        entity = entity_result.scalar_one_or_none()
        
        if not entity:
            entity = Entity(
                entity_id=uuid.uuid4(),
                entity_code=key,
                kind_id=kind.kind_id,
                status="active",
                version_id=1,
            )
            db.add(entity)
            await db.flush()
        
        # Create/update projections for each language
        for lang_code, value in lang_values.items():
            if lang_code not in languages or not value:
                continue
            
            lang_obj = languages[lang_code]
            
            # Check if projection exists
            existing_proj = await db.execute(
                select(EntityProjection)
                .where(
                    EntityProjection.entity_id == entity.entity_id,
                    EntityProjection.model_id == model.model_id,
                )
            )
            found = False
            for proj in existing_proj.scalars().all():
                state_result = await db.execute(
                    select(ProjectionState)
                    .where(
                        ProjectionState.projection_id == proj.projection_id,
                        ProjectionState.is_current == True
                    )
                )
                ps = state_result.scalar_one_or_none()
                if ps and ps.state_data and ps.state_data.get("key") == key:
                    # Check if this is for the right language
                    if proj.projection_code and proj.projection_code.endswith(f"_{lang_code}"):
                        ps.state_data = {"key": key, "value": value}
                        ps.state_hash = hashlib.sha256(json.dumps({"key": key, "value": value}, sort_keys=True).encode()).hexdigest()
                        from sqlalchemy.orm.attributes import flag_modified
                        flag_modified(ps, "state_data")
                        flag_modified(ps, "state_hash")
                        found = True
                        break
            
            if not found:
                proj_id = uuid.uuid4()
                proj = EntityProjection(
                    projection_id=proj_id,
                    entity_id=entity.entity_id,
                    model_id=model.model_id,
                    template_id=template.template_id,
                    context_id=ctx.context_id,
                    projection_code=f"{key}_{lang_code}",
                    projection_name=f"{key} ({lang_code})",
                    confidence=1.0,
                    version_id=1,
                )
                db.add(proj)
                await db.flush()
                
                state_data = {"key": key, "value": value}
                state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True).encode()).hexdigest()
                ps = ProjectionState(
                    projection_id=proj_id,
                    state_data=state_data,
                    state_hash=state_hash,
                    is_current=True,
                    version_id=1,
                )
                db.add(ps)
        
        imported += 1
    
    await db.commit()
    clear_translations_cache()
    
    return RedirectResponse(url="/admin/ui-translations", status_code=303)
