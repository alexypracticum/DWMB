import json
from datetime import datetime, timezone
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
from app.services.layout import render_layout, get_state_field, get_localized_value
from app.services.language_service import get_language_id, get_kind_label, get_kind_labels_batch, get_entity_label, entity_label_filter, lang_priority_case, get_lang_ids, get_lang

templates = Jinja2Templates(directory="app/templates")

router = APIRouter(tags=["entities"])
@router.get("/", response_class=HTMLResponse)
async def index(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(get_current_user)):
    # Stats
    entity_count = await db.scalar(select(func.count(Entity.entity_id)))
    kind_count = await db.scalar(select(func.count(EntityKind.kind_id)).where(EntityKind.is_abstract == False))
    relation_count = await db.scalar(select(func.count(SemanticRelation.relation_id)))

    # Recent entities
    lang = getattr(request.state, "lang", "ru")
    lang_id, ru_lang_id = await get_lang_ids(db, lang)
    entity_filter = entity_label_filter(lang_id, ru_lang_id)
    lang_priority = lang_priority_case(lang_id)
    result = await db.execute(
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", entity_filter)
        .distinct(Entity.entity_id)
        .order_by(Entity.entity_id, lang_priority)
        .limit(12)
    )
    recent = []
    lang = getattr(request.state, "lang", "ru")
    rows = result.unique().all()
    kind_ids = [ek.kind_id for _, _, ek in rows]
    kind_labels = await get_kind_labels_batch(db, kind_ids, lang)
    for entity, label, ek in rows:
        kl = kind_labels.get(ek.kind_id, ek.kind_code)
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
    lang = getattr(request.state, "lang", "ru")
    lang_id, ru_lang_id = await get_lang_ids(db, lang)
    entity_filter = entity_label_filter(lang_id, ru_lang_id)

    query = (
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", entity_filter, EntityLabel.is_primary == True)
    )

    count_query = (
        select(func.count(Entity.entity_id))
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.status == "active", entity_filter, EntityLabel.is_primary == True)
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
    lang = getattr(request.state, "lang", "ru")
    rows = result.unique().all()
    kind_ids = [ek.kind_id for _, _, ek in rows]
    kind_labels = await get_kind_labels_batch(db, kind_ids, lang)
    for entity, label, ek in rows:
        kl = kind_labels.get(ek.kind_id, ek.kind_code)
        # Use image_url directly from entity (fallback to projection state)
        poster = entity.image_url
        if not poster:
            proj_result = await db.execute(
                select(EntityProjection).where(EntityProjection.entity_id == entity.entity_id).limit(1)
            )
            proj = proj_result.scalars().first()
            if proj:
                state_result = await db.execute(
                    select(ProjectionState).where(
                        ProjectionState.projection_id == proj.projection_id,
                        ProjectionState.is_current == True
                    ).limit(1)
                )
                state = state_result.scalars().first()
                if state and state.state_data:
                    poster = state.state_data.get("poster") or state.state_data.get("poster_url") or state.state_data.get("image_url")
        entities.append({"entity": entity, "label": label, "kind": ek, "kind_label": kl, "poster": poster})

    # Kinds for sidebar
    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()

    # Resolve current kind label
    current_kind_label = ""
    if kind:
        lang = getattr(request.state, "lang", "ru")
        lang_id = await get_language_id(db, lang)
        ru_lang_id = await get_language_id(db, "ru")
        or_clauses_ekl = []
        if lang_id:
            or_clauses_ekl.append(EntityKindLabel.language_id == lang_id)
        if ru_lang_id:
            or_clauses_ekl.append(EntityKindLabel.language_id == ru_lang_id)
        ck_result = await db.execute(
            select(EntityKindLabel.label).where(
                EntityKind.kind_code == kind,
                EntityKind.kind_id == EntityKindLabel.kind_id,
                or_(*or_clauses_ekl)
            ).order_by((EntityKindLabel.language_id == lang_id).desc() if lang_id else True).limit(1)
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


async def _get_kinds_with_labels(db, lang="ru"):
    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()
    result = []
    for k in kinds:
        kl = await get_kind_label(db, k.kind_id, lang) or k.kind_code
        result.append({"kind": k, "label": kl})
    return result


@router.get("/entity/create", response_class=HTMLResponse)
async def entity_create_page(
    request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(require_auth),
    kind: str = Query(None), template_ids: str = Query(None), error: str = Query(None),
):
    lang = getattr(request.state, "lang", "ru")
    kinds_with_labels = await _get_kinds_with_labels(db, lang)
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
            lang = getattr(request.state, "lang", "ru")
            for tmpl, model, kind_obj in tmpl_result:
                kc = kind_obj.kind_code
                if kc not in kind_groups:
                    kind_label = await get_kind_label(db, kind_obj.kind_id, lang) or kind_obj.kind_code
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
                                    if isinstance(prop, dict):
                                        all_schema_fields.append({
                                            "key": key,
                                            "label": prop.get("title", key),
                                            "type": prop.get("type", "string"),
                                            "description": prop.get("description", ""),
                                            "required": key in required,
                                            "default": prop.get("default", ""),
                                            "enum": prop.get("enum", []),
                                        })
                                    elif isinstance(prop, str):
                                        all_schema_fields.append({
                                            "key": key,
                                            "label": key.replace("_", " ").title(),
                                            "type": prop,
                                            "description": "",
                                            "required": key in required,
                                            "default": "",
                                            "enum": [],
                                        })
                        # Collect layout blocks
                        _ld = tmpl.layout_definition
                        if isinstance(_ld, str):
                            try: _ld = json.loads(_ld)
                            except (json.JSONDecodeError, ValueError, TypeError): _ld = []
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
    ru_lang_id = await get_language_id(db, "ru")
    ru_label = EntityLabel(
        entity_id=entity_id, language_id=ru_lang_id, label=label_ru,
        description=description_ru, is_primary=True, owner_id=user.user_id, version_id=version_id,
    )
    db.add(ru_label)

    # English label
    if label_en:
        en_lang_id = await get_language_id(db, "en")
        en_label = EntityLabel(
            entity_id=entity_id, language_id=en_lang_id, label=label_en,
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

        # Collect state data from form for this template (multilingual support)
        state_data = {}
        if tmpl.schema_definition and isinstance(tmpl.schema_definition, dict):
            props = tmpl.schema_definition.get("properties", {})
            langs = ["ru", "en", "de", "fr", "es", "zh", "ja"]
            for key in props:
                p = props[key]
                prop_type = p.get("type", "string") if isinstance(p, dict) else "string"
                is_text_field = prop_type in ("string", "textarea")
                
                if is_text_field:
                    # Try multilingual values
                    ml_values = {}
                    for l in langs:
                        ml_key = f"{key}_{l}"
                        ml_val = form.get(ml_key, "")
                        if ml_val:
                            ml_values[l] = ml_val
                    if ml_values:
                        state_data[key] = ml_values
                    else:
                        val = form.get(key, "")
                        if val:
                            state_data[key] = val
                else:
                    val = form.get(key, "")
                    if val:
                        if prop_type == "integer":
                            try: val = int(val)
                            except (json.JSONDecodeError, ValueError, TypeError): pass
                        elif prop_type == "number":
                            try: val = float(val)
                            except (json.JSONDecodeError, ValueError, TypeError): pass
                        elif prop_type == "boolean":
                            val = val.lower() in ("true", "1", "yes")
                        state_data[key] = val

        # Collect layout block data
        _ld = tmpl.layout_definition
        if isinstance(_ld, str):
            try: _ld = _json.loads(_ld)
            except (json.JSONDecodeError, ValueError, TypeError): _ld = []
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

    # Log entity creation
    from app.services.event_log import log_entity_created
    await log_entity_created(db, entity_id, version_id, caused_by=user.username)

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

    # Labels (with language eagerly loaded)
    from sqlalchemy.orm import joinedload
    labels_result = await db.execute(
        select(EntityLabel)
        .options(joinedload(EntityLabel.language))
        .where(EntityLabel.entity_id == eid)
    )
    labels = labels_result.scalars().unique().all()

    # Kind
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == entity.kind_id))
    kind = kind_result.scalar_one_or_none()

    lang = getattr(request.state, "lang", "ru")
    kind_label = None
    if kind:
        kind_label = await get_kind_label(db, kind.kind_id, lang) or kind.kind_code

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
    lang = getattr(request.state, "lang", "ru")
    lang_id, ru_lang_id = await get_lang_ids(db, lang)
    entity_filter = entity_label_filter(lang_id, ru_lang_id)
    source_rels = await db.execute(
        select(SemanticRelation, RelationType, EntityProjection, Entity, EntityLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .where(SemanticRelation.source_projection_id.in_(
            select(EntityProjection.projection_id).where(EntityProjection.entity_id == eid)
        ), entity_filter, EntityLabel.is_primary == True)
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
        ), entity_filter, EntityLabel.is_primary == True)
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
                    if isinstance(prop, dict):
                        t = getattr(request.state, "t", {})
                        trans_key = f"field_{key}"
                        label = t.get(trans_key, prop.get("title", key))
                        schema_fields.append({
                            "key": key,
                            "label": label,
                            "type": prop.get("type", "string"),
                            "description": prop.get("description", ""),
                            "required": key in required,
                        })
                    elif isinstance(prop, str):
                        schema_fields.append({
                            "key": key,
                            "label": key.replace("_", " ").title(),
                            "type": prop,
                            "description": "",
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
                        "role": ((r["relation"].metadata_ or {}) if hasattr(r["relation"], 'metadata_') else {}).get("role", "") if r.get("relation") else "",
                        "image_url": getattr(r["target"], "image_url", None) or "",
                    })
                layout_html = render_layout(layout_blocks, state_data, rels_by_type, str(entity_id), lang, t=getattr(request.state, "t", {}))

    # Get primary label for template
    label = None
    if labels:
        _lang_id = await get_language_id(db, lang)
        label = next((l for l in labels if l.language_id == _lang_id and l.is_primary), labels[0])

    # Extract SEO fields from state_data
    seo_title = state_data.get("meta_title") or state_data.get("title") or (label.label if label else None)
    seo_description = state_data.get("meta_description") or state_data.get("description") or (labels[0].description if labels else None)
    seo_og_image = state_data.get("og_image") or state_data.get("poster") or state_data.get("poster_url")

    # Get comments
    from app.models.comments import Comment
    from app.models.users import UserAccount as UA
    comments_result = await db.execute(
        select(Comment, UA.username)
        .join(UA, Comment.user_id == UA.user_id, isouter=True)
        .where(Comment.entity_id == eid, Comment.parent_id == None)
        .order_by(Comment.created_at.desc())
    )
    comments = []
    for comment, username in comments_result:
        # Get replies
        replies_result = await db.execute(
            select(Comment, UA.username)
            .join(UA, Comment.user_id == UA.user_id, isouter=True)
            .where(Comment.parent_id == comment.comment_id)
            .order_by(Comment.created_at.asc())
        )
        replies = [{"comment": r, "username": u} for r, u in replies_result]
        comments.append({"comment": comment, "username": username, "replies": replies})

    return templates.TemplateResponse("entities/detail.html", {
        "request": request,
        "user": user,
        "entity": entity,
        "labels": labels,
        "label": label,
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
        "seo_title": seo_title,
        "seo_description": seo_description,
        "seo_og_image": seo_og_image,
        "comments": comments,
    })


@router.get("/entity/{entity_id}/history", response_class=HTMLResponse)
async def entity_history(request: Request, entity_id: str, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(get_current_user)):
    from uuid import UUID
    from app.services.event_log import get_entity_history
    eid = UUID(entity_id)

    entity_result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = entity_result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    # Get kind label
    kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_id == entity.kind_id))
    kind = kind_result.scalar_one_or_none()
    lang = getattr(request.state, "lang", "ru")
    kind_label = await get_kind_label(db, kind.kind_id, lang) if kind else None

    # Get entity label
    label_result = await db.execute(
        select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.is_primary == True).limit(1)
    )
    label = label_result.scalars().first()

    # Get history
    events = await get_entity_history(db, eid)

    # Event type labels
    event_labels = {
        "create": "Создание",
        "update": "Обновление",
        "delete": "Удаление",
        "merge": "Слияние",
        "split": "Разделение",
        "state_transition": "Изменение состояния",
        "relation_change": "Изменение связи",
    }

    return templates.TemplateResponse("entities/history.html", {
        "request": request,
        "user": user,
        "entity": entity,
        "label": label,
        "kind": kind,
        "kind_label": kind_label,
        "events": events,
        "event_labels": event_labels,
    })


@router.post("/entity/{entity_id}/workflow")
async def entity_workflow(
    entity_id: str,
    state: str = Form(...),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Change entity workflow state (draft/published/archived)."""
    from uuid import UUID
    from datetime import datetime, timezone
    eid = UUID(entity_id)

    if state not in ("draft", "published", "archived"):
        raise HTTPException(400, "Invalid workflow state")

    result = await db.execute(select(Entity).where(Entity.entity_id == eid))
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(404)

    old_state = entity.workflow_state or "published"
    entity.workflow_state = state
    entity.updated_at = datetime.now(timezone.utc)

    # Log workflow change
    from app.services.event_log import log_state_transition
    await log_state_transition(db, eid, None, version_id=entity.version_id, caused_by=user.username, old_state={"workflow_state": old_state}, new_state={"workflow_state": state})

    await db.commit()
    return RedirectResponse(url=f"/entity/{entity_id}", status_code=303)


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

    from sqlalchemy.orm import joinedload
    labels_result = await db.execute(
        select(EntityLabel)
        .options(joinedload(EntityLabel.language))
        .where(EntityLabel.entity_id == eid)
    )
    labels = labels_result.scalars().unique().all()

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
                        if isinstance(prop, dict):
                            all_schema_fields.append({
                                "key": key,
                                "label": prop.get("title", key),
                                "type": prop.get("type", "string"),
                                "description": prop.get("description", ""),
                                "required": key in required,
                                "default": prop.get("default", ""),
                                "enum": prop.get("enum", []),
                            })
                        elif isinstance(prop, str):
                            all_schema_fields.append({
                                "key": key,
                                "label": key.replace("_", " ").title(),
                                "type": prop,
                                "description": "",
                                "required": key in required,
                                "default": "",
                                "enum": [],
                            })
            # Merge layout blocks
            if tmpl and tmpl.layout_definition:
                _ld = tmpl.layout_definition
                if isinstance(_ld, str):
                    try: _ld = _json.loads(_ld)
                    except (json.JSONDecodeError, ValueError, TypeError): _ld = []
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
            lang = getattr(request.state, "lang", "ru")
            kind_label = await get_kind_label(db, kind_obj.kind_id, lang) or kind_obj.kind_code
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
    lang = getattr(request.state, "lang", "ru")
    lang_id, ru_lang_id = await get_lang_ids(db, lang)
    entity_filter = entity_label_filter(lang_id, ru_lang_id)

    # Outgoing relations
    outgoing = []
    if proj_ids:
        out_result = await db.execute(
            select(SemanticRelation, RelationType, EntityProjection, Entity, EntityLabel)
            .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
            .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
            .join(Entity, Entity.entity_id == EntityProjection.entity_id)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .where(SemanticRelation.source_projection_id.in_(proj_ids), entity_filter, EntityLabel.is_primary == True)
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
            .where(SemanticRelation.target_projection_id.in_(proj_ids), entity_filter, EntityLabel.is_primary == True)
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
    ru_lang_id = await get_language_id(db, "ru")
    en_lang_id = await get_language_id(db, "en")
    if label_ru:
        result = await db.execute(
            select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.language_id == ru_lang_id)
        )
        ru_label = result.scalar_one_or_none()
        if ru_label:
            ru_label.label = label_ru
            ru_label.description = description_ru

    # Update English label
    result_en = await db.execute(
        select(EntityLabel).where(EntityLabel.entity_id == eid, EntityLabel.language_id == en_lang_id)
    )
    en_label = result_en.scalar_one_or_none()
    if en_label and label_en:
        en_label.label = label_en
    elif not en_label and label_en:
        en_label = EntityLabel(
            entity_id=eid, language_id=en_lang_id, label=label_en,
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
                # Schema fields (multilingual support)
                if tmpl.schema_definition and isinstance(tmpl.schema_definition, dict):
                    props = tmpl.schema_definition.get("properties", {})
                    langs = ["ru", "en", "de", "fr", "es", "zh", "ja"]
                    for key in props:
                        p = props[key]
                        prop_type = p.get("type", "string") if isinstance(p, dict) else "string"
                        
                        # Check if this is a multilingual text field
                        # Skip multilingual for unique identifier fields
                        non_ml_keys = {"imdb_id", "tmdb_id", "poster", "poster_url", "image_url", "video_url", "audio_url", "file_url", "file_title", "uploaded_file_url", "uploaded_file_title"}
                        is_text_field = prop_type in ("string", "textarea") and key not in non_ml_keys
                        
                        if is_text_field:
                            # Try to get multilingual values
                            ml_values = {}
                            for l in langs:
                                ml_key = f"{key}_{l}"
                                ml_val = form.get(ml_key)
                                if ml_val is not None:
                                    ml_values[l] = ml_val
                            
                            if ml_values:
                                # Multilingual field
                                state_data[key] = ml_values
                            else:
                                # Fallback to simple value
                                val = form.get(key)
                                if val is not None:
                                    state_data[key] = val
                        else:
                            # Non-text field (integer, number, boolean)
                            val = form.get(key)
                            if val is not None:
                                if prop_type == "integer":
                                    try: val = int(val)
                                    except (json.JSONDecodeError, ValueError, TypeError): pass
                                elif prop_type == "number":
                                    try: val = float(val)
                                    except (json.JSONDecodeError, ValueError, TypeError): pass
                                elif prop_type == "boolean":
                                    val = val.lower() in ("true", "1", "yes")
                                state_data[key] = val
                # Layout block fields — form inputs use state_key as name
                _ld = tmpl.layout_definition
                if isinstance(_ld, str):
                    try: _ld = _json.loads(_ld)
                    except (json.JSONDecodeError, ValueError, TypeError): _ld = []
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
                # SEO fields
                for seo_key in ("meta_title", "meta_description", "og_image"):
                    seo_val = form.get(seo_key)
                    if seo_val is not None:
                        state_data[seo_key] = str(seo_val) if seo_val else ""
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

    # Log entity update
    from app.services.event_log import log_entity_updated
    await log_entity_updated(db, eid, version_id=1, caused_by=user.username, changes={field_key: field_value})

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
        # Log entity deletion
        from app.services.event_log import log_entity_deleted
        await log_entity_deleted(db, eid, version_id=entity.version_id, caused_by=user.username)
    return RedirectResponse(url="/entities", status_code=303)


BLOCKED_EXTENSIONS = {
    ".exe", ".bat", ".cmd", ".com", ".scr", ".pif", ".msi", ".ps1",
    ".vbs", ".vbe", ".js", ".jse", ".ws", ".wsf", ".wsc",
    ".sh", ".bash", ".csh", ".ksh", ".py", ".pl", ".rb",
    ".dll", ".so", ".dylib", ".app", ".apk", ".deb", ".rpm",
    ".jar", ".class", ".war", ".ear",
}


