"""
API endpoints for external source imports (TMDB, etc.).
"""
from fastapi import APIRouter, Depends, Query, HTTPException, Form
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import require_auth
from app.services.importers.tmdb import tmdb_service

router = APIRouter(prefix="/api/import", tags=["import"])


# ─── TMDB Search ──────────────────────────────────────────────

@router.get("/tmdb/status")
async def tmdb_status(user: UserAccount = Depends(require_auth)):
    """Check if TMDB API is configured."""
    return {
        "configured": tmdb_service.is_configured,
        "message": "TMDB API настроен" if tmdb_service.is_configured else "TMDB API ключ не задан"
    }


@router.get("/tmdb/search/movie")
async def tmdb_search_movie(
    q: str = Query(..., min_length=1),
    page: int = Query(1, ge=1, le=10),
    user: UserAccount = Depends(require_auth),
):
    """Search movies in TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен. Задайте TMDB_API_KEY в .env")

    results = await tmdb_service.search_movies(q, page)
    return {"results": results, "query": q, "page": page}


@router.get("/tmdb/search/person")
async def tmdb_search_person(
    q: str = Query(..., min_length=1),
    page: int = Query(1, ge=1, le=10),
    user: UserAccount = Depends(require_auth),
):
    """Search people in TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен. Задайте TMDB_API_KEY в .env")

    results = await tmdb_service.search_persons(q, page)
    return {"results": results, "query": q, "page": page}


# ─── TMDB Import ──────────────────────────────────────────────

@router.get("/tmdb/movie/{tmdb_id}")
async def tmdb_get_movie(
    tmdb_id: int,
    user: UserAccount = Depends(require_auth),
):
    """Get detailed movie info from TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен")

    movie = await tmdb_service.get_movie(tmdb_id)
    if not movie:
        raise HTTPException(404, "Фильм не найден в TMDB")
    return movie


@router.get("/tmdb/movie/{tmdb_id}/credits")
async def tmdb_get_movie_credits(
    tmdb_id: int,
    user: UserAccount = Depends(require_auth),
):
    """Get movie credits from TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен")

    credits = await tmdb_service.get_movie_credits(tmdb_id)
    return credits


@router.get("/tmdb/person/{tmdb_id}")
async def tmdb_get_person(
    tmdb_id: int,
    user: UserAccount = Depends(require_auth),
):
    """Get detailed person info from TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен")

    person = await tmdb_service.get_person(tmdb_id)
    if not person:
        raise HTTPException(404, "Человек не найден в TMDB")
    return person


@router.get("/tmdb/genres")
async def tmdb_get_genres(
    user: UserAccount = Depends(require_auth),
):
    """Get all movie genres from TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен")

    genres = await tmdb_service.get_genres()
    return {"genres": genres}


# ─── TMDB Import: Movie Credits ───────────────────────────────

@router.post("/tmdb/import-credits/{entity_id}")
async def tmdb_import_credits(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """
    Import TMDB credits for a movie entity.
    Creates actor/director entities and relationships.
    """
    from uuid import UUID, uuid4
    import hashlib, json
    from app.models.entities import Entity, EntityLabel
    from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate, OntologyModel
    from app.models.kinds import EntityKind, EntityKindLabel
    from app.models.relations import SemanticRelation, RelationType
    from app.models.projections import OntologyTemplate, OntologyModel

    eid = UUID(entity_id)

    # Get entity's projection to find tmdb_id
    proj_result = await db.execute(
        select(EntityProjection).where(EntityProjection.entity_id == eid)
    )
    proj = proj_result.scalar_one_or_none()
    if not proj:
        raise HTTPException(404, "Сущность не найдена")

    # Get state_data to find tmdb_id
    ps_result = await db.execute(
        select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
    )
    ps = ps_result.scalar_one_or_none()
    if not ps or not ps.state_data:
        raise HTTPException(400, "Нет данных TMDB у сущности")

    tmdb_id = ps.state_data.get("tmdb_id")
    if not tmdb_id:
        raise HTTPException(400, "У сущности нет tmdb_id")

    # Fetch credits from TMDB
    credits = await tmdb_service.get_movie_credits(int(tmdb_id))
    if not credits:
        raise HTTPException(400, "Не удалось получить данные из TMDB")

    # Get kinds and relation types
    actor_kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == "actor"))).scalar_one_or_none()
    director_kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == "director"))).scalar_one_or_none()
    acted_in_type = (await db.execute(select(RelationType).where(RelationType.relation_code == "acted_in"))).scalar_one_or_none()
    directed_by_type = (await db.execute(select(RelationType).where(RelationType.relation_code == "directed_by"))).scalar_one_or_none()

    version_result = await db.execute(select(func.max(Entity.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    imported = {"actors": 0, "directors": 0}

    # Process actors
    for person in credits.get("cast", [])[:15]:
        person_tmdb_id = person.get("tmdb_id")
        if not person_tmdb_id:
            continue

        # Check if person already exists
        existing = await db.execute(
            select(Entity).join(EntityProjection).join(ProjectionState)
            .where(ProjectionState.state_data["tmdb_id"].as_string() == str(person_tmdb_id))
        )
        existing_entity = existing.scalar_one_or_none()

        if not existing_entity and actor_kind:
            # Create new actor entity
            entity_id = uuid4()
            entity = Entity(entity_id=entity_id, entity_code=f"actor_{person_tmdb_id}", kind_id=actor_kind.kind_id, status="active", owner_id=user.user_id, version_id=version_id)
            db.add(entity)
            await db.flush()

            label = EntityLabel(entity_id=entity_id, language="ru", label=person.get("name", ""), is_primary=True, owner_id=user.user_id, version_id=version_id)
            db.add(label)

            # Create projection with state
            tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.kind_id == actor_kind.kind_id, OntologyTemplate.is_active == True).limit(1))
            tmpl = tmpl_result.scalar_one_or_none()
            if tmpl:
                proj_id = uuid4()
                p = EntityProjection(projection_id=proj_id, entity_id=entity_id, model_id=tmpl.model_id, template_id=tmpl.template_id, projection_code=f"actor_{person_tmdb_id}", projection_name=person.get("name", ""), confidence=1.0, version_id=version_id)
                db.add(p)
                await db.flush()

                state_data = {"tmdb_id": person_tmdb_id, "name": person.get("name", "")}
                state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
                ps_state = ProjectionState(projection_id=proj_id, state_data=state_data, state_hash=state_hash, is_current=True, version_id=version_id)
                db.add(ps_state)
                existing_entity = entity
                imported["actors"] += 1

        # Create relationship
        if existing_entity and acted_in_type:
            src_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == eid).limit(1))).scalar_one_or_none()
            tgt_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == existing_entity.entity_id).limit(1))).scalar_one_or_none()
            if src_proj and tgt_proj:
                # Check if relationship already exists
                existing_rel = await db.execute(
                    select(SemanticRelation).where(
                        SemanticRelation.source_projection_id == src_proj.projection_id,
                        SemanticRelation.relation_type_id == acted_in_type.relation_type_id,
                        SemanticRelation.target_projection_id == tgt_proj.projection_id,
                    )
                )
                if not existing_rel.scalar_one_or_none():
                    rel = SemanticRelation(source_projection_id=src_proj.projection_id, relation_type_id=acted_in_type.relation_type_id, target_projection_id=tgt_proj.projection_id, confidence=1.0, version_id=version_id)
                    db.add(rel)

    # Process directors
    for person in credits.get("crew", []):
        if person.get("job") != "Director":
            continue
        person_tmdb_id = person.get("tmdb_id")
        if not person_tmdb_id:
            continue

        existing = await db.execute(
            select(Entity).join(EntityProjection).join(ProjectionState)
            .where(ProjectionState.state_data["tmdb_id"].as_string() == str(person_tmdb_id))
        )
        existing_entity = existing.scalar_one_or_none()

        if not existing_entity and director_kind:
            entity_id = uuid4()
            entity = Entity(entity_id=entity_id, entity_code=f"director_{person_tmdb_id}", kind_id=director_kind.kind_id, status="active", owner_id=user.user_id, version_id=version_id)
            db.add(entity)
            await db.flush()

            label = EntityLabel(entity_id=entity_id, language="ru", label=person.get("name", ""), is_primary=True, owner_id=user.user_id, version_id=version_id)
            db.add(label)

            tmpl_result = await db.execute(select(OntologyTemplate).where(OntologyTemplate.kind_id == director_kind.kind_id, OntologyTemplate.is_active == True).limit(1))
            tmpl = tmpl_result.scalar_one_or_none()
            if tmpl:
                proj_id = uuid4()
                p = EntityProjection(projection_id=proj_id, entity_id=entity_id, model_id=tmpl.model_id, template_id=tmpl.template_id, projection_code=f"director_{person_tmdb_id}", projection_name=person.get("name", ""), confidence=1.0, version_id=version_id)
                db.add(p)
                await db.flush()

                state_data = {"tmdb_id": person_tmdb_id, "name": person.get("name", "")}
                state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()
                ps_state = ProjectionState(projection_id=proj_id, state_data=state_data, state_hash=state_hash, is_current=True, version_id=version_id)
                db.add(ps_state)
                existing_entity = entity
                imported["directors"] += 1

        if existing_entity and directed_by_type:
            src_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == eid).limit(1))).scalar_one_or_none()
            tgt_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == existing_entity.entity_id).limit(1))).scalar_one_or_none()
            if src_proj and tgt_proj:
                existing_rel = await db.execute(
                    select(SemanticRelation).where(
                        SemanticRelation.source_projection_id == src_proj.projection_id,
                        SemanticRelation.relation_type_id == directed_by_type.relation_type_id,
                        SemanticRelation.target_projection_id == tgt_proj.projection_id,
                    )
                )
                if not existing_rel.scalar_one_or_none():
                    rel = SemanticRelation(source_projection_id=src_proj.projection_id, relation_type_id=directed_by_type.relation_type_id, target_projection_id=tgt_proj.projection_id, confidence=1.0, version_id=version_id)
                    db.add(rel)

    await db.commit()
    return {"imported": imported, "message": f"Импортировано: {imported['actors']} актёров, {imported['directors']} режиссёров"}
