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
@router.post("/entity/{entity_id}/add-relation")
async def entity_add_relation(
    entity_id: str,
    relation_type_id: str = Form(...),
    target_entity_id: str = Form(...),
    role: str = Form(""),
    confidence: float = Form(1.0),
    weight: float = Form(1.0),
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

    # Get relation type and its inverse
    rt_result = await db.execute(select(RelationType).where(RelationType.relation_type_id == rtid))
    rt = rt_result.scalar_one_or_none()
    inverse_rtid = rt.inverse_type_id if rt else None

    # Build metadata
    import json
    metadata = {}
    if role and role.strip():
        metadata["role"] = role.strip()
    if confidence != 1.0:
        metadata["confidence"] = confidence
    if weight != 1.0:
        metadata["weight"] = weight

    # Create direct relation (source → target)
    relation = SemanticRelation(
        source_projection_id=src_proj.projection_id,
        relation_type_id=rtid,
        target_projection_id=tgt_proj.projection_id,
        confidence=confidence,
        weight=weight,
        metadata_=metadata,
        version_id=version_id,
    )
    db.add(relation)

    # Create inverse relation (target → source) automatically
    # Skip if self-inverse (undirected relation)
    if inverse_rtid and inverse_rtid != rtid:
        inverse_relation = SemanticRelation(
            source_projection_id=tgt_proj.projection_id,
            relation_type_id=inverse_rtid,
            target_projection_id=src_proj.projection_id,
            confidence=confidence,
            weight=weight,
            metadata_=metadata,
            version_id=version_id,
        )
        db.add(inverse_relation)

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
    from app.models.relations import SemanticRelation, RelationType

    rid = UUID(relation_id)
    result = await db.execute(select(SemanticRelation).where(SemanticRelation.relation_id == rid))
    rel = result.scalar_one_or_none()
    if rel:
        # Find and delete the inverse relation (skip if self-inverse)
        rt_result = await db.execute(select(RelationType).where(RelationType.relation_type_id == rel.relation_type_id))
        rt = rt_result.scalar_one_or_none()
        if rt and rt.inverse_type_id and rt.inverse_type_id != rel.relation_type_id:
            # Find inverse: source=this.target, target=this.source, type=inverse_type
            inverse_result = await db.execute(
                select(SemanticRelation).where(
                    SemanticRelation.source_projection_id == rel.target_projection_id,
                    SemanticRelation.target_projection_id == rel.source_projection_id,
                    SemanticRelation.relation_type_id == rt.inverse_type_id,
                )
            )
            inverse_rel = inverse_result.scalar_one_or_none()
            if inverse_rel:
                await db.delete(inverse_rel)

        await db.delete(rel)
        await db.commit()

    return RedirectResponse(url=f"/entity/{entity_id}/edit", status_code=303)


