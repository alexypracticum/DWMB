import json
from fastapi import APIRouter, Depends, Request, Form, Query, HTTPException, UploadFile, File
from fastapi.responses import RedirectResponse, HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_, text
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.entities import Entity, EntityLabel, Context
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
from app.models.relations import SemanticRelation, RelationType
from app.models.users import UserAccount
from app.services.auth import get_current_user, require_auth
from app.services.layout import render_layout, get_state_field

router = APIRouter(tags=["entities"])
templates = Jinja2Templates(directory="app/templates")


@router.get("/", response_class=HTMLResponse)
async def index(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(get_current_user)):
    # Stats
    entity_count = await db.scalar(select(func.count(Entity.entity_id)))
    kind_count = await db.scalar(select(func.count(EntityKind.kind_id)).where(EntityKind.is_abstract == False))
    relation_count = await db.scalar(select(func.count(SemanticRelation.relation_id)))

    # Recent entities
    result = await db.execute(
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", EntityLabel.language == "ru", EntityLabel.is_primary == True)
        .order_by(Entity.updated_at.desc())
        .limit(12)
    )
    recent = []
    for entity, label, ek in result.unique():
        kind_label = await db.execute(
            select(EntityKindLabel.label).where(EntityKindLabel.kind_id == ek.kind_id, EntityKindLabel.language == "ru")
        )
        kl = kind_label.scalar_one_or_none() or ek.kind_code
        recent.append({"entity": entity, "label": label, "kind": ek, "kind_label": kl})

    # Kinds for sidebar
    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()

    return templates.TemplateResponse("index.html", {
        "request": request,
        "user": user,
        "recent": recent,
        "kinds": kinds,
        "entity_count": entity_count,
        "kind_count": kind_count,
        "relation_count": relation_count,
    })


@router.get("/entities", response_class=HTMLResponse)
async def list_entities(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(get_current_user),
    kind: str = Query(None),
    page: int = Query(1, ge=1),
    search: str = Query(None),
):
    per_page = 20
    offset = (page - 1) * per_page

    query = (
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", EntityLabel.language == "ru", EntityLabel.is_primary == True)
    )

    count_query = (
        select(func.count(Entity.entity_id))
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", EntityLabel.language == "ru", EntityLabel.is_primary == True)
    )

    if kind:
        kind_obj = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind))
        kind_row = kind_obj.scalar_one_or_none()
        if kind_row:
            query = query.where(Entity.kind_id == kind_row.kind_id)
            count_query = count_query.where(Entity.kind_id == kind_row.kind_id)

    if search:
        search_pattern = f"%{search}%"
        query = query.where(or_(EntityLabel.label.ilike(search_pattern), EntityLabel.description.ilike(search_pattern)))
        count_query = count_query.where(or_(EntityLabel.label.ilike(search_pattern), EntityLabel.description.ilike(search_pattern)))

    total = await db.scalar(count_query)
    total_pages = max(1, (total + per_page - 1) // per_page)

    result = await db.execute(query.order_by(EntityLabel.label).offset(offset).limit(per_page))
    entities = []
    for entity, label, ek in result.unique():
        kind_label_r = await db.execute(
            select(EntityKindLabel.label).where(EntityKindLabel.kind_id == ek.kind_id, EntityKindLabel.language == "ru")
        )
        kl = kind_label_r.scalar_one_or_none() or ek.kind_code
        entities.append({"entity": entity, "label": label, "kind": ek, "kind_label": kl})

    # Kinds for sidebar
    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()

    # Resolve current kind label
    current_kind_label = ""
    if kind:
        ck_result = await db.execute(
            select(EntityKindLabel.label).where(
                EntityKind.kind_code == kind,
                EntityKind.kind_id == EntityKindLabel.kind_id,
                EntityKindLabel.language == "ru"
            )
        )
        current_kind_label = ck_result.scalar_one_or_none() or kind

    return templates.TemplateResponse("entities/list.html", {
        "request": request,
        "user": user,
        "entities": entities,
        "kinds": kinds,
        "current_kind": kind,
        "current_kind_label": current_kind_label,
        "search": search,
        "page": page,
        "total_pages": total_pages,
        "total": total,
    })


async def _get_kinds_with_labels(db):
    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()
    result = []
    for k in kinds:
        kl_result = await db.execute(
            select(EntityKindLabel.label).where(EntityKindLabel.kind_id == k.kind_id, EntityKindLabel.language == "ru")
        )
        kl = kl_result.scalar_one_or_none() or k.kind_code
        result.append({"kind": k, "label": kl})
    return result


@router.get("/entity/create", response_class=HTMLResponse)
async def entity_create_page(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_auth),
    kind: str = Query(None), template_ids: str = Query(None), error: str = Query(None),
):
    kinds_with_labels = await _get_kinds_with_labels(db)
    step = 1
    selected_kind_obj = None
    templates_by_kind = []
    selected_templates = []
    all_schema_fields = []
    all_layout_blocks = []

    if kind:
        step = 2
        kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind))
        selected_kind_obj = kind_result.scalar_one_or_none()

        if selected_kind_obj:
            # Get ALL active templates grouped by kind
            tmpl_result = await db.execute(
                select(OntologyTemplate, OntologyModel, EntityKind)
                .join(OntologyModel, OntologyModel.model_id == OntologyTemplate.model_id)
                .join(EntityKind, EntityKind.kind_id == OntologyTemplate.kind_id)
                .where(OntologyTemplate.is_active == True)
                .order_by(EntityKind.sort_order, OntologyTemplate.template_code)
            )
            kind_groups = {}
            for tmpl, model, kind_obj in tmpl_result:
                kc = kind_obj.kind_code
                if kc not in kind_groups:
                    # Get kind label
                    kl_result = await db.execute(
                        select(EntityKindLabel.label).where(
                            EntityKindLabel.kind_id == kind_obj.kind_id,
                            EntityKindLabel.language == "ru"
                        )
                    )
                    kind_label = kl_result.scalar_one_or_none() or kind_obj.kind_code
                    kind_groups[kc] = {"kind_code": kc, "kind_label": kind_label, "templates": []}
                kind_groups[kc]["templates"].append({
                    "template": tmpl,
                    "model": model,
                })
            templates_by_kind = list(kind_groups.values())

            # If template_ids provided, go to step 3 with merged fields
            if template_ids:
                step = 3
                tids = [t.strip() for t in template_ids.split(",") if t.strip()]
                seen_keys = set()
                for tid in tids:
                    if tid == "none":
                        continue
                    from uuid import UUID
                    t_result = await db.execute(
                        select(OntologyTemplate).where(OntologyTemplate.template_id == UUID(tid))
                    )
                    tmpl = t_result.scalar_one_or_none()
                    if tmpl:
                        selected_templates.append(tmpl)
                        # Collect schema fields (deduplicate by key)
                        if tmpl.schema_definition and isinstance(tmpl.schema_definition, dict):
                            props = tmpl.schema_definition.get("properties", {})
                            required = tmpl.schema_definition.get("required", [])
                            for key, prop in props.items():
                                if key not in seen_keys:
                                    seen_keys.add(key)
                                    all_schema_fields.append({
                                        "key": key,
                                        "label": prop.get("title", key),
                                        "type": prop.get("type", "string"),
                                        "description": prop.get("description", ""),
                                        "required": key in required,
                                        "default": prop.get("default", ""),
                                        "enum": prop.get("enum", []),
                                    })
                        # Collect layout blocks
                        _ld = tmpl.layout_definition
                        if isinstance(_ld, str):
                            try: _ld = json.loads(_ld)
                            except: _ld = []
                        if isinstance(_ld, list):
                            all_layout_blocks.extend(_ld)

    return templates.TemplateResponse("entities/create.html", {
        "request": request,
        "user": user,
        "kinds": kinds_with_labels,
        "step": step,
        "selected_kind": kind,
        "selected_kind_obj": selected_kind_obj,
        "templates_by_kind": templates_by_kind,
        "selected_templates": selected_templates,
        "schema_fields": all_schema_fields,
        "layout_blocks": all_layout_blocks,
        "error": error,
    })


@router.post("/entity/create")
async def entity_create(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
    kind_code: str = Form(...),
    template_ids: list = Form([]),
    entity_code: str = Form(""),
    label_ru: str = Form(...),
    description_ru: str = Form(""),
    label_en: str = Form(""),
):
    from datetime import datetime, timezone
    import uuid as _uuid, json as _json, re as _re

    # Find kind
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind_code))
    kind = kind_result.scalar_one_or_none()
    if not kind:
        raise HTTPException(400, "Invalid kind")

    # Auto-generate entity_code from label_ru if not provided
    if not entity_code:
        import unicodedata
        _CYR_TO_LAT = {
            'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo',
            'ж':'zh','з':'z','и':'i','й':'y','к':'k','л':'l','м':'m',
            'н':'n','о':'o','п':'p','р':'r','с':'s','т':'t','у':'u',
            'ф':'f','х':'kh','ц':'ts','ч':'ch','ш':'sh','щ':'sch',
            'ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya',
        }
        base = label_ru.strip().lower()
        # Transliterate Cyrillic
        result = []
        for ch in base:
            if ch in _CYR_TO_LAT:
                result.append(_CYR_TO_LAT[ch])
            elif ch.isascii() and (ch.isalnum() or ch in ' -_'):
                result.append(ch)
            elif ch in ' -_':
                result.append('-')
        base = ''.join(result)
        base = _re.sub(r'-+', '-', base).strip('-')
        entity_code = base[:80] if base else f"entity-{_uuid.uuid4().hex[:8]}"

    # Ensure unique entity_code
    base_code = entity_code
    counter = 1
    while True:
        existing = await db.execute(select(Entity).where(Entity.entity_code == entity_code))
        if not existing.scalar_one_or_none():
            break
        counter += 1
        entity_code = f"{base_code}-{counter}"

    # Get version
    version_result = await db.execute(select(func.max(Entity.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    # Create entity
    entity_id = _uuid.uuid4()
    entity = Entity(
        entity_id=entity_id, entity_code=entity_code, kind_id=kind.kind_id,
        status="active", owner_id=user.user_id, version_id=version_id,
    )
    db.add(entity)
    await db.flush()

    # Russian label
    ru_label = EntityLabel(
        entity_id=entity_id, language="ru", label=label_ru,
        description=description_ru, is_primary=True, owner_id=user.user_id, version_id=version_id,
    )
    db.add(ru_label)

    # English label
    if label_en:
        en_label = EntityLabel(
            entity_id=entity_id, language="en", label=label_en,
            is_primary=False, version_id=version_id,
        )
        db.add(en_label)

    # Get default context
    ctx_result = await db.execute(select(Context).where(Context.context_code == "default"))
    ctx = ctx_result.scalar_one_or_none()

    # Create projections for each selected template
    form = await request.form()
    for tid in template_ids:
        if not tid:
            continue
        from uuid import UUID
        tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == UUID(tid)))
        tmpl = tmpl_result.scalar_one_or_none()
        if not tmpl:
            continue

        # Create projection
        proj_id = _uuid.uuid4()
        proj = EntityProjection(
            projection_id=proj_id,
            entity_id=entity_id,
            model_id=tmpl.model_id,
            template_id=tmpl.template_id,
            context_id=ctx.context_id if ctx else None,
            projection_code=f"{entity_code}_{tmpl.template_code}",
            projection_name=label_ru,
            confidence=1.0,
            version_id=version_id,
        )
        db.add(proj)
        await db.flush()

        # Collect state data from form for this template
        state_data = {}
        if tmpl.schema_definition and isinstance(tmpl.schema_definition, dict):
            props = tmpl.schema_definition.get("properties", {})
            for key in props:
                val = form.get(key, "")
                if val:
                    prop_type = props[key].get("type", "string")
                    if prop_type == "integer":
                        try: val = int(val)
                        except: pass
                    elif prop_type == "number":
                        try: val = float(val)
                        except: pass
                    elif prop_type == "boolean":
                        val = val.lower() in ("true", "1", "yes")
                    state_data[key] = val

        # Collect layout block data
        _ld = tmpl.layout_definition
        if isinstance(_ld, str):
            try: _ld = _json.loads(_ld)
            except: _ld = []
        if isinstance(_ld, list) and _ld:
            from app.services.layout import BLOCK_TYPES
            for block in _ld:
                btype = block.get("type", "")
                bt = BLOCK_TYPES.get(btype, {})
                config = block.get("config", {})
                for bf in bt.get("config_fields", []):
                    if bf.get("type") == "state_field":
                        state_key = config.get(bf["key"], bf.get("default", ""))
                        form_val = form.get(state_key, "")
                        if form_val:
                            state_data[state_key] = str(form_val)

        # Create state
        import hashlib
        state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
        ps = ProjectionState(
            projection_id=proj_id,
            state_data=state_data,
            state_hash=state_hash,
            is_current=True,
            version_id=version_id,
        )
        db.add(ps)

    await db.commit()
    return RedirectResponse(url=f"/entity/{entity_id}", status_code=303)


@router.get("/entity/{entity_id}", response_class=HTMLResponse)
async def entity_detail(request: Request, entity_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(get_current_user)):
    from uuid import UUID
    import json as _json
    try:
        eid = UUID(entity_id)
    except ValueError:
        raise HTTPException(404)

    entity_result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = entity_result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    # Labels
    labels_result = await db.execute(select(EntityLabel).where(EntityLabel.entity_id == eid))
    labels = labels_result.scalars().all()

    # Kind
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == entity.kind_id))
    kind = kind_result.scalar_one_or_none()

    kind_label = None
    if kind:
        kl_result = await db.execute(
            select(EntityKindLabel.label).where(EntityKindLabel.kind_id == kind.kind_id, EntityKindLabel.language == "ru")
        )
        kind_label = kl_result.scalar_one_or_none() or kind.kind_code

    # Projections with states
    proj_result = await db.execute(
        select(EntityProjection, OntologyModel)
        .join(OntologyModel, OntologyModel.model_id == EntityProjection.model_id)
        .where(EntityProjection.entity_id == eid)
    )
    projections = []
    for proj, model in proj_result:
        state_result = await db.execute(
            select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
        )
        state = state_result.scalar_one_or_none()
        projections.append({"projection": proj, "model": model, "state": state})

    # Relations
    source_rels = await db.execute(
        select(SemanticRelation, RelationType, EntityProjection, Entity, EntityLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .where(SemanticRelation.source_projection_id.in_(
            select(EntityProjection.projection_id).where(EntityProjection.entity_id == eid)
        ), EntityLabel.language == "ru", EntityLabel.is_primary == True)
    )
    outgoing = []
    for rel, rtype, proj, ent, lbl in source_rels.unique():
        outgoing.append({"relation": rel, "type": rtype, "target": ent, "label": lbl})

    target_rels = await db.execute(
        select(SemanticRelation, RelationType, EntityProjection, Entity, EntityLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.source_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .where(SemanticRelation.target_projection_id.in_(
            select(EntityProjection.projection_id).where(EntityProjection.entity_id == eid)
        ), EntityLabel.language == "ru", EntityLabel.is_primary == True)
    )
    incoming = []
    for rel, rtype, proj, ent, lbl in target_rels.unique():
        incoming.append({"relation": rel, "type": rtype, "source": ent, "label": lbl})

    # Get layout from template
    layout_html = ""
    layout_blocks = []
    template_obj = None
    schema_fields = []
    state_data = {}
    if projections:
        proj = projections[0]
        tmpl_result = await db.execute(
            select(OntologyTemplate).where(OntologyTemplate.template_id == proj["projection"].template_id)
        )
        template_obj = tmpl_result.scalar_one_or_none()
        if proj["state"]:
            state_data = proj["state"].state_data or {}
        if template_obj:
            # Extract schema fields (skip URL/media fields for default display)
            _skip_keys = {"poster_url", "images", "video_url", "audio_url", "file_url", "file_title", "uploaded_file_url", "uploaded_file_title"}
            if template_obj.schema_definition and isinstance(template_obj.schema_definition, dict):
                props = template_obj.schema_definition.get("properties", {})
                required = template_obj.schema_definition.get("required", [])
                for key, prop in props.items():
                    if key in _skip_keys:
                        continue
                    schema_fields.append({
                        "key": key,
                        "label": prop.get("title", key),
                        "type": prop.get("type", "string"),
                        "description": prop.get("description", ""),
                        "required": key in required,
                    })
            # Layout rendering - handle invalid JSON gracefully
            if template_obj.layout_definition:
                ld = template_obj.layout_definition
                if isinstance(ld, list):
                    layout_blocks = ld
                elif isinstance(ld, str):
                    try:
                        layout_blocks = _json.loads(ld)
                    except _json.JSONDecodeError:
                        layout_blocks = []
                else:
                    layout_blocks = []
                rels_by_type = {}
                for r in outgoing:
                    rtype_code = r["type"].relation_code
                    if rtype_code not in rels_by_type:
                        rels_by_type[rtype_code] = []
                    rels_by_type[rtype_code].append({
                        "label": r["label"].label,
                        "entity_id": str(r["target"].entity_id),
                    })
                layout_html = render_layout(layout_blocks, state_data, rels_by_type, str(entity_id))

    return templates.TemplateResponse("entities/detail.html", {
        "request": request,
        "user": user,
        "entity": entity,
        "labels": labels,
        "kind": kind,
        "kind_label": kind_label,
        "projections": projections,
        "outgoing_relations": outgoing,
        "incoming_relations": incoming,
        "layout_html": layout_html,
        "layout_blocks": layout_blocks,
        "template_obj": template_obj,
        "schema_fields": schema_fields,
        "state_data": state_data,
    })


@router.get("/entity/{entity_id}/edit", response_class=HTMLResponse)
async def entity_edit_page(request: Request, entity_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_auth)):
    from uuid import UUID
    import json as _json
    try:
        eid = UUID(entity_id)
    except ValueError:
        raise HTTPException(404)

    entity_result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = entity_result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    labels_result = await db.execute(select(EntityLabel).where(EntityLabel.entity_id == eid))
    labels = labels_result.scalars().all()

    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == entity.kind_id))
    kind = kind_result.scalar_one_or_none()

    # Projections with states — merge schema from all projections
    proj_result = await db.execute(
        select(EntityProjection, OntologyModel)
        .join(OntologyModel, OntologyModel.model_id == EntityProjection.model_id)
        .where(EntityProjection.entity_id == eid)
    )
    projections = []
    all_schema_fields = []
    merged_state_data = {}
    seen_keys = set()
    all_layout_blocks = []

    for proj, model in proj_result:
        state_result = await db.execute(
            select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
        )
        state = state_result.scalar_one_or_none()
        projections.append({"projection": proj, "model": model, "state": state})

        # Merge schema fields from each template
        if proj.template_id:
            tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == proj.template_id))
            tmpl = tmpl_result.scalar_one_or_none()
            if tmpl and tmpl.schema_definition and isinstance(tmpl.schema_definition, dict):
                props = tmpl.schema_definition.get("properties", {})
                required = tmpl.schema_definition.get("required", [])
                for key, prop in props.items():
                    if key not in seen_keys:
                        seen_keys.add(key)
                        all_schema_fields.append({
                            "key": key,
                            "label": prop.get("title", key),
                            "type": prop.get("type", "string"),
                            "description": prop.get("description", ""),
                            "required": key in required,
                            "default": prop.get("default", ""),
                            "enum": prop.get("enum", []),
                        })
            # Merge layout blocks
            if tmpl and tmpl.layout_definition:
                _ld = tmpl.layout_definition
                if isinstance(_ld, str):
                    try: _ld = _json.loads(_ld)
                    except: _ld = []
                if isinstance(_ld, list):
                    all_layout_blocks.extend(_ld)

        # Merge state data (later projections override earlier ones for same keys)
        if state and state.state_data:
            merged_state_data.update(state.state_data)

    schema_fields = all_schema_fields
    state_data = merged_state_data
    layout_blocks = all_layout_blocks

    # Get available templates for adding new projections (from ANY kind, grouped by kind)
    avail_result = await db.execute(
        select(OntologyTemplate, OntologyModel, EntityKind)
        .join(OntologyModel, OntologyModel.model_id == OntologyTemplate.model_id)
        .join(EntityKind, EntityKind.kind_id == OntologyTemplate.kind_id)
        .where(OntologyTemplate.is_active == True)
        .order_by(EntityKind.sort_order, OntologyTemplate.template_code)
    )
    avail_by_kind = {}
    for tmpl, model, kind_obj in avail_result:
        # Exclude already linked templates
        already_linked = any(p["projection"].template_id == tmpl.template_id for p in projections)
        if already_linked:
            continue
        kc = kind_obj.kind_code
        if kc not in avail_by_kind:
            kl_result = await db.execute(
                select(EntityKindLabel.label).where(
                    EntityKindLabel.kind_id == kind_obj.kind_id,
                    EntityKindLabel.language == "ru"
                )
            )
            kind_label = kl_result.scalar_one_or_none() or kind_obj.kind_code
            avail_by_kind[kc] = {"kind_code": kc, "kind_label": kind_label, "templates": []}
        avail_by_kind[kc]["templates"].append({
            "template_id": tmpl.template_id,
            "template_name": tmpl.template_name,
            "model_code": model.model_code,
        })
    available_templates = list(avail_by_kind.values())

    # Get relationships
    from app.models.relations import SemanticRelation, RelationType

    # Get all projection IDs for this entity
    proj_ids = [p["projection"].projection_id for p in projections]

    # Outgoing relations
    outgoing = []
    if proj_ids:
        out_result = await db.execute(
            select(SemanticRelation, RelationType, EntityProjection, Entity, EntityLabel)
            .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
            .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
            .join(Entity, Entity.entity_id == EntityProjection.entity_id)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .where(SemanticRelation.source_projection_id.in_(proj_ids), EntityLabel.language == "ru", EntityLabel.is_primary == True)
        )
        for rel, rtype, proj, ent, lbl in out_result.unique():
            outgoing.append({"relation": rel, "type": rtype, "target": ent, "label": lbl})

    # Incoming relations
    incoming = []
    if proj_ids:
        in_result = await db.execute(
            select(SemanticRelation, RelationType, EntityProjection, Entity, EntityLabel)
            .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
            .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.source_projection_id)
            .join(Entity, Entity.entity_id == EntityProjection.entity_id)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .where(SemanticRelation.target_projection_id.in_(proj_ids), EntityLabel.language == "ru", EntityLabel.is_primary == True)
        )
        for rel, rtype, proj, ent, lbl in in_result.unique():
            incoming.append({"relation": rel, "type": rtype, "source": ent, "label": lbl})

    # Get all relation types
    rt_result = await db.execute(select(RelationType).order_by(RelationType.relation_name))
    relation_types = rt_result.scalars().all()

    return templates.TemplateResponse("entities/edit.html", {
        "request": request,
        "user": user,
        "entity": entity,
        "labels": labels,
        "kind": kind,
        "projections": projections,
        "schema_fields": schema_fields,
        "layout_blocks": layout_blocks,
        "state_data": state_data,
        "available_templates": available_templates,
        "outgoing_relations": outgoing,
        "incoming_relations": incoming,
        "relation_types": relation_types,
    })


@router.post("/entity/{entity_id}/add-projection")
async def entity_add_projection(
    entity_id: str,
    template_id: str = Form(...),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    from uuid import UUID
    import json as _json, hashlib

    eid = UUID(entity_id)
    tid = UUID(template_id)

    # Verify entity exists
    entity_result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = entity_result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    # Get template
    tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == tid))
    tmpl = tmpl_result.scalar_one_or_none()
    if not tmpl:
        raise HTTPException(400, "Invalid template")

    # Check if already linked
    existing = await db.execute(
        select(EntityProjection).where(
            EntityProjection.entity_id == eid,
            EntityProjection.template_id == tid,
        )
    )
    if existing.scalar_one_or_none():
        return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)

    # Get version
    version_result = await db.execute(select(func.max(Entity.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    # Get default context
    ctx_result = await db.execute(select(Context).where(Context.context_code == "default"))
    ctx = ctx_result.scalar_one_or_none()

    # Create projection
    import uuid
    proj_id = uuid.uuid4()
    proj = EntityProjection(
        projection_id=proj_id,
        entity_id=eid,
        model_id=tmpl.model_id,
        template_id=tmpl.template_id,
        context_id=ctx.context_id if ctx else None,
        projection_code=f"{entity.entity_code}_{tmpl.template_code}",
        projection_name=entity.entity_code,
        confidence=1.0,
        version_id=version_id,
    )
    db.add(proj)
    await db.flush()

    # Create empty state
    state_hash = hashlib.sha256(b"{}").hexdigest()
    ps = ProjectionState(
        projection_id=proj_id,
        state_data={},
        state_hash=state_hash,
        is_current=True,
        version_id=version_id,
    )
    db.add(ps)
    await db.commit()

    return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)


@router.post("/entity/{entity_id}/add-relation")
async def entity_add_relation(
    entity_id: str,
    relation_type_id: str = Form(...),
    target_entity_id: str = Form(...),
    direction: str = Form("outgoing"),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    from uuid import UUID
    from app.models.relations import SemanticRelation, RelationType

    eid = UUID(entity_id)
    target_eid = UUID(target_entity_id)
    rtid = UUID(relation_type_id)

    # Get source entity's first projection
    src_proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == eid).limit(1)
    )
    src_proj = src_proj_result.scalar_one_or_none()
    if not src_proj:
        return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)

    # Get target entity's first projection
    tgt_proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == target_eid).limit(1)
    )
    tgt_proj = tgt_proj_result.scalar_one_or_none()
    if not tgt_proj:
        return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)

    # Get version
    version_result = await db.execute(select(func.max(SemanticRelation.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    # Create relation based on direction
    if direction == "outgoing":
        source_proj_id = src_proj.projection_id
        target_proj_id = tgt_proj.projection_id
    else:
        source_proj_id = tgt_proj.projection_id
        target_proj_id = src_proj.projection_id

    relation = SemanticRelation(
        source_projection_id=source_proj_id,
        relation_type_id=rtid,
        target_projection_id=target_proj_id,
        confidence=1.0,
        version_id=version_id,
    )
    db.add(relation)
    await db.commit()

    return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)


@router.post("/entity/{entity_id}/delete-relation/{relation_id}")
async def entity_delete_relation(
    entity_id: str,
    relation_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    from uuid import UUID
    from app.models.relations import SemanticRelation

    rid = UUID(relation_id)
    result = await db.execute(select(SemanticRelation).where(SemanticRelation.relation_id == rid))
    rel = result.scalar_one_or_none()
    if rel:
        await db.delete(rel)
        await db.commit()

    return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)


@router.post("/entity/{entity_id}/edit")
async def entity_edit(
    request: Request,
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
    label_ru: str = Form(""),
    description_ru: str = Form(""),
    label_en: str = Form(""),
):
    from uuid import UUID
    from datetime import datetime, timezone
    import json as _json, hashlib
    eid = UUID(entity_id)

    # Update Russian label (skip if label_ru is empty — partial update from popup)
    if label_ru:
        result = await db.execute(
            select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.language == "ru")
        )
        ru_label = result.scalar_one_or_none()
        if ru_label:
            ru_label.label = label_ru
            ru_label.description = description_ru

    # Update English label
    result_en = await db.execute(
        select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.language == "en")
    )
    en_label = result_en.scalar_one_or_none()
    if en_label and label_en:
        en_label.label = label_en
    elif not en_label and label_en:
        en_label = EntityLabel(
            entity_id=eid, language="en", label=label_en,
            is_primary=False, version_id=ru_label.version_id if ru_label else 1,
        )
        db.add(en_label)

    # Update state data from form if template exists
    form = await request.form()
    proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == eid)
    )
    for proj in proj_result.scalars().all():
        tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == proj.template_id))
        tmpl = tmpl_result.scalar_one_or_none()
        if tmpl:
            state_result = await db.execute(
                select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
            )
            ps = state_result.scalar_one_or_none()
            if ps:
                state_data = ps.state_data or {}
                # Schema fields
                if tmpl.schema_definition and isinstance(tmpl.schema_definition, dict):
                    props = tmpl.schema_definition.get("properties", {})
                    for key in props:
                        val = form.get(key)
                        if val is not None:
                            prop_type = props[key].get("type", "string")
                            if prop_type == "integer":
                                try: val = int(val)
                                except: pass
                            elif prop_type == "number":
                                try: val = float(val)
                                except: pass
                            elif prop_type == "boolean":
                                val = val.lower() in ("true", "1", "yes")
                            state_data[key] = val
                # Layout block fields — form inputs use state_key as name
                _ld = tmpl.layout_definition
                if isinstance(_ld, str):
                    try: _ld = _json.loads(_ld)
                    except: _ld = []
                if isinstance(_ld, list):
                    from app.services.layout import BLOCK_TYPES
                    for block in _ld:
                        btype = block.get("type", "")
                        bt = BLOCK_TYPES.get(btype, {})
                        config = block.get("config", {})
                        for bf in bt.get("config_fields", []):
                            if bf.get("type") == "state_field":
                                state_key = config.get(bf["key"], bf.get("default", ""))
                                form_val = form.get(state_key)
                                if form_val is not None:
                                    state_data[state_key] = str(form_val)
                ps.state_data = state_data
                ps.state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
                from sqlalchemy.orm.attributes import flag_modified
                flag_modified(ps, "state_data")
                flag_modified(ps, "state_hash")

    # Update entity timestamp
    result_ent = await db.execute(select(Entity).where(Entity.entity_id == eid))
    ent = result_ent.scalar_one_or_none()
    if ent:
        ent.updated_at = datetime.now(timezone.utc)

    return RedirectResponse(url=f"/entity/{entity_id}", status_code=303)


@router.post("/api/entity/{entity_id}/field")
async def api_update_entity_field(
    entity_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Update a single field in entity's state_data (for inline popup saves)."""
    from uuid import UUID
    from datetime import datetime, timezone
    import json as _json, hashlib
    eid = UUID(entity_id)
    body = await request.json()
    field_key = body.get("key", "")
    field_value = body.get("value", "")
    if not field_key:
        return {"ok": False, "error": "missing key"}

    proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == eid)
    )
    for proj in proj_result.scalars().all():
        if not proj.template_id:
            continue
        tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.template_id == proj.template_id))
        tmpl = tmpl_result.scalar_one_or_none()
        if not tmpl:
            continue
        state_result = await db.execute(
            select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
        )
        ps = state_result.scalar_one_or_none()
        if ps:
            state_data = ps.state_data or {}
            state_data[field_key] = field_value
            ps.state_data = state_data
            ps.state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
            from sqlalchemy.orm.attributes import flag_modified
            flag_modified(ps, "state_data")
            flag_modified(ps, "state_hash")

    # Update entity timestamp
    result_ent = await db.execute(select(Entity).where(Entity.entity_id == eid))
    ent = result_ent.scalar_one_or_none()
    if ent:
        ent.updated_at = datetime.now(timezone.utc)

    await db.commit()
    return {"ok": True, "value": field_value}


@router.post("/entity/{entity_id}/delete")
async def entity_delete(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    from uuid import UUID
    eid = UUID(entity_id)
    result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = result.scalar_one_or_none()
    if entity:
        entity.status = "deleted"
    return RedirectResponse(url="/entities", status_code=303)


BLOCKED_EXTENSIONS = {
    ".exe", ".bat", ".cmd", ".com", ".scr", ".pif", ".msi", ".ps1",
    ".vbs", ".vbe", ".js", ".jse", ".ws", ".wsf", ".wsc",
    ".sh", ".bash", ".csh", ".ksh", ".py", ".pl", ".rb",
    ".dll", ".so", ".dylib", ".app", ".apk", ".deb", ".rpm",
    ".jar", ".class", ".war", ".ear",
}


@router.post("/upload")
async def upload_file(
    request: Request,
    user: UserAccount = Depends(require_auth),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    import os, hashlib as _hl
    from uuid import uuid4
    from app.services.storage import storage_service
    from app.models.entities import MediaAsset

    filename = file.filename or "file"
    ext = os.path.splitext(filename)[1].lower()

    if ext in BLOCKED_EXTENSIONS:
        return JSONResponse(
            {"error": f"Загрузка файлов типа {ext} запрещена"},
            status_code=400,
        )

    # Read content and compute hash BEFORE upload (for dedup check)
    content = await file.read()
    file_hash = _hl.sha256(content).hexdigest()

    # Check for duplicate by hash
    existing = await db.execute(
        select(MediaAsset).where(MediaAsset.file_hash == file_hash)
    )
    existing_asset = existing.scalar_one_or_none()
    if existing_asset:
        # Duplicate found — return existing URL without re-uploading
        url = storage_service.get_presigned_url(existing_asset.storage_key)
        return JSONResponse({
            "url": url,
            "filename": existing_asset.original_name,
            "size": existing_asset.size_bytes,
            "storage_key": existing_asset.storage_key,
            "entity_id": str(existing_asset.entity_id),
            "duplicate": True,
        })

    # No duplicate — upload to MinIO (reset file position after hash read)
    entity_id = uuid4()
    await file.seek(0)
    result = await storage_service.upload_file(file, entity_id)

    url = storage_service.get_presigned_url(result["key"])
    is_image = ext in (".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg")

    # For image uploads, create Entity first (required for MediaAsset FK)
    if is_image:
        photo_kind = await db.execute(
            select(EntityKind).where(EntityKind.kind_code == "photo")
        )
        photo_kind_obj = photo_kind.scalar_one_or_none()
        if photo_kind_obj:
            entity = Entity(
                entity_id=entity_id,
                entity_code=f"upload-{entity_id.hex[:12]}",
                kind_id=photo_kind_obj.kind_id,
                status="active",
                owner_id=user.user_id,
                version_id=1,
            )
            db.add(entity)
            await db.flush()

            label = EntityLabel(
                entity_id=entity_id,
                language="ru",
                label=os.path.splitext(filename)[0].replace("_", " ").replace("-", " "),
                is_primary=True,
                owner_id=user.user_id,
                version_id=1,
            )
            db.add(label)

            # Create projection with state containing the image URL
            from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate
            import json as _json, hashlib

            tmpl_result = await db.execute(
                select(OntologyTemplate)
                .join(EntityKind, EntityKind.kind_id == OntologyTemplate.kind_id)
                .where(EntityKind.kind_code == "photo", OntologyTemplate.is_active == True)
                .limit(1)
            )
            tmpl = tmpl_result.scalar_one_or_none()
            if tmpl:
                proj_id = uuid4()
                proj = EntityProjection(
                    projection_id=proj_id,
                    entity_id=entity_id,
                    model_id=tmpl.model_id,
                    template_id=tmpl.template_id,
                    projection_code=f"upload_{entity_id.hex[:12]}",
                    projection_name=os.path.splitext(filename)[0],
                    confidence=1.0,
                    version_id=1,
                )
                db.add(proj)
                await db.flush()

                state_data = {"poster": url, "title": os.path.splitext(filename)[0].replace("_", " ").replace("-", " ")}
                state_hash = hashlib.sha256(_json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
                ps = ProjectionState(
                    projection_id=proj_id,
                    state_data=state_data,
                    state_hash=state_hash,
                    is_current=True,
                    version_id=1,
                )
                db.add(ps)

    # Create MediaAsset record (after Entity so FK is satisfied)
    from app.models.entities import MediaAsset
    media_asset = MediaAsset(
        entity_id=entity_id,
        original_name=filename,
        mime_type=file.content_type or "application/octet-stream",
        size_bytes=result["size"],
        file_hash=result["hash"],
        storage_key=result["key"],
        version_id=1,
    )
    db.add(media_asset)

    await db.commit()

    return JSONResponse({
        "url": url,
        "filename": filename,
        "size": result["size"],
        "storage_key": result["key"],
        "entity_id": str(entity_id) if is_image else None,
    })
