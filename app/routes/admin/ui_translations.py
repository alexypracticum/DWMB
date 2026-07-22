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
from app.services.auth import require_admin, get_password_hash
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
                    ProjectionState.is_current == True,
                    EntityProjection.projection_code.like(f"%_{lang}")
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
