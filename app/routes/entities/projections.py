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
from app.services.language_service import get_language_id, get_kind_label, get_entity_label, entity_label_filter, lang_priority_case, get_lang_ids, get_lang

templates = Jinja2Templates(directory="app/templates")

router = APIRouter(tags=["entities"])
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


@router.post("/entity/{entity_id}/remove-projection")
async def entity_remove_projection(
    entity_id: str,
    projection_id: str = Form(...),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    from uuid import UUID
    from app.models.relations import SemanticRelation

    eid = UUID(entity_id)
    pid = UUID(projection_id)

    proj = await db.get(EntityProjection, pid)
    if not proj or proj.entity_id != eid:
        raise HTTPException(404)

    rels = await db.execute(
        select(SemanticRelation).where(
            (SemanticRelation.source_projection_id == pid) | (SemanticRelation.target_projection_id == pid)
        )
    )
    for rel in rels.scalars().all():
        await db.delete(rel)

    states = await db.execute(
        select(ProjectionState).where(ProjectionState.projection_id == pid)
    )
    for st in states.scalars().all():
        await db.delete(st)

    await db.delete(proj)
    await db.commit()
    return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)


