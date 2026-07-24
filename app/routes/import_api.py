"""
API endpoints for external source imports (TMDB, etc.).
"""
import logging
from fastapi import APIRouter, Depends, Query, HTTPException, Form
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import require_auth
from app.services.importers.tmdb import tmdb_service
from app.middleware.rate_limit import limiter, get_rate_limit
from app.services.language import get_language_id
from uuid import uuid4

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/import", tags=["import"])


async def _ensure_kind_and_relation(db, kind_code, relation_code, inverse_code=None):
    """Ensure entity kind and relation type exist, creating them if needed. Uses ORM to prevent SQL injection."""
    from app.models.kinds import EntityKind, EntityKindLabel
    from app.models.relations import RelationType

    kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == kind_code))).scalars().first()
    if not kind:
        parent = (await db.execute(select(EntityKind).where(EntityKind.kind_code == "entity"))).scalars().first()
        kind = EntityKind(
            kind_code=kind_code,
            parent_kind_id=parent.kind_id if parent else None,
            description="Auto-created kind",
            is_abstract=False,
            sort_order=999,
            version_id=1,
        )
        db.add(kind)
        await db.flush()
        label_text = kind_code[0].upper() + kind_code[1:] if kind_code else kind_code
        ru_lang_id = await get_language_id(db, "ru")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label=label_text, description="Auto-created"))
        await db.flush()
        logger.info("Auto-created EntityKind '%s' (id=%s)", kind_code, kind.kind_id)

    rel = (await db.execute(select(RelationType).where(RelationType.relation_code == relation_code))).scalars().first()
    if not rel:
        rel = RelationType(
            relation_code=relation_code,
            relation_name=relation_code,
            description="Auto-created",
            directionality="directed",
            version_id=1,
        )
        db.add(rel)
        await db.flush()
        logger.info("Auto-created RelationType '%s' (id=%s)", relation_code, rel.relation_type_id)

    if inverse_code:
        inv = (await db.execute(select(RelationType).where(RelationType.relation_code == inverse_code))).scalars().first()
        if not inv:
            inv = RelationType(
                relation_code=inverse_code,
                relation_name=inverse_code,
                description="Auto-created inverse",
                directionality="directed",
                inverse_type_id=rel.relation_type_id,
                version_id=1,
            )
            db.add(inv)
            await db.flush()
            logger.info("Auto-created inverse RelationType '%s' (id=%s)", inverse_code, inv.relation_type_id)
            rel.inverse_type_id = inv.relation_type_id
            await db.flush()

    return kind, rel


# ─── TMDB Search ──────────────────────────────────────────────

@router.get("/tmdb/status", summary="Проверка настройки TMDB API", description="Возвращает статус подключения к TMDB API")
async def tmdb_status(user: UserAccount = Depends(require_auth)):
    """Check if TMDB API is configured."""
    return {
        "configured": tmdb_service.is_configured,
        "message": "TMDB API настроен" if tmdb_service.is_configured else "TMDB API ключ не задан"
    }


@router.get("/tmdb/search/movie", summary="Поиск фильмов в TMDB", description="Поиск фильмов по названию через The Movie Database API")
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


@router.get("/tmdb/search/person", summary="Поиск людей в TMDB", description="Поиск персон по имени через The Movie Database API")
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

@router.get("/tmdb/movie/{tmdb_id}", summary="Детали фильма из TMDB", description="Получение полной информации о фильме по TMDB ID")
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


@router.get("/tmdb/movie/{tmdb_id}/credits", summary="Кредиты фильма из TMDB", description="Получение списка актёров и съёмочной группы фильма")
async def tmdb_get_movie_credits(
    tmdb_id: int,
    user: UserAccount = Depends(require_auth),
):
    """Get movie credits from TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен")

    credits = await tmdb_service.get_movie_credits(tmdb_id)
    return credits


@router.get("/tmdb/person/{tmdb_id}", summary="Детали персоны из TMDB", description="Получение полной информации о персоне по TMDB ID")
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


@router.get("/tmdb/genres", summary="Список жанров TMDB", description="Получение всех жанров фильмов из TMDB")
async def tmdb_get_genres(
    user: UserAccount = Depends(require_auth),
):
    """Get all movie genres from TMDB."""
    if not tmdb_service.is_configured:
        raise HTTPException(400, "TMDB API не настроен")

    genres = await tmdb_service.get_genres()
    return {"genres": genres}


# ─── TMDB Import: Movie Credits ───────────────────────────────

async def _find_or_create_related_entity(
    db, name, tmdb_id, kind_code, rel_type_code,
    owner_id, version_id, src_proj, user,
    extra_state=None, metadata=None,
):
    """Find or create an entity for a TMDB related item and link it via semantic relation.
    Returns dict with keys: created (bool), linked (bool), entity_id (str|None)."""
    import hashlib, json
    from app.models.entities import Entity, EntityLabel
    from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate, OntologyModel
    from app.models.kinds import EntityKind
    from app.models.relations import SemanticRelation, RelationType

    kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == kind_code))).scalars().first()
    rel_type = (await db.execute(select(RelationType).where(RelationType.relation_code == rel_type_code))).scalars().first()
    if not kind or not rel_type or not src_proj:
        return None

    entity_code = f"{kind_code}_{tmdb_id}"
    existing = await db.execute(
        select(Entity).where(Entity.entity_code == entity_code)
    )
    existing_entity = existing.scalars().first()

    is_new = False
    if not existing_entity:
        eid = uuid4()
        # Set image_url from poster if available
        image_url = None
        if extra_state and extra_state.get("poster"):
            image_url = extra_state["poster"]
        entity = Entity(entity_id=eid, entity_code=entity_code, kind_id=kind.kind_id, status="active", image_url=image_url, owner_id=owner_id, version_id=version_id)
        db.add(entity)
        await db.flush()

        ru_lang_id = await get_language_id(db, "ru")
        label = EntityLabel(entity_id=eid, language_id=ru_lang_id, label=name, is_primary=True, owner_id=owner_id, version_id=version_id)
        db.add(label)

        tmpl = (await db.execute(
            select(OntologyTemplate).where(OntologyTemplate.kind_id == kind.kind_id, OntologyTemplate.is_active == True).limit(1)
        )).scalars().first()
        if tmpl:
            proj_id = uuid4()
            p = EntityProjection(projection_id=proj_id, entity_id=eid, model_id=tmpl.model_id, template_id=tmpl.template_id, projection_code=entity_code, projection_name=name, confidence=1.0, version_id=version_id)
            db.add(p)
            await db.flush()
            sd = {}
            if tmdb_id:
                sd["tmdb_id"] = str(tmdb_id)
            if extra_state:
                sd.update(extra_state)
            state_hash = hashlib.sha256(json.dumps(sd, sort_keys=True, default=str).encode()).hexdigest()
            db.add(ProjectionState(projection_id=proj_id, state_data=sd, state_hash=state_hash, is_current=True, version_id=version_id))
            existing_entity = entity
            is_new = True
    else:
        # Existing entity — update image_url and poster if missing
        if extra_state and extra_state.get("poster"):
            # Update image_url on entity
            if not existing_entity.image_url:
                existing_entity.image_url = extra_state["poster"]
            tgt_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == existing_entity.entity_id).limit(1))).scalars().first()
            if tgt_proj:
                st = await db.execute(
                    select(ProjectionState).where(ProjectionState.projection_id == tgt_proj.projection_id, ProjectionState.is_current == True)
                )
                state = st.scalars().first()
                if state and not state.state_data.get("poster"):
                    sd = dict(state.state_data)
                    sd["poster"] = extra_state["poster"]
                    state_hash = hashlib.sha256(json.dumps(sd, sort_keys=True, default=str).encode()).hexdigest()
                    state.state_data = sd
                    state.state_hash = state_hash

    if existing_entity:
        tgt_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == existing_entity.entity_id).limit(1))).scalars().first()
        if src_proj and tgt_proj:
            existing_rel = await db.execute(
                select(SemanticRelation).where(
                    SemanticRelation.source_projection_id == src_proj.projection_id,
                    SemanticRelation.relation_type_id == rel_type.relation_type_id,
                    SemanticRelation.target_projection_id == tgt_proj.projection_id,
                )
            )
            if not existing_rel.scalars().first():
                rel = SemanticRelation(source_projection_id=src_proj.projection_id, relation_type_id=rel_type.relation_type_id, target_projection_id=tgt_proj.projection_id, confidence=1.0, version_id=version_id)
                if metadata:
                    rel.metadata_ = metadata
                db.add(rel)
                # Log relation creation
                from app.services.event_log import log_relation_change
                await log_relation_change(db, None, existing_entity.entity_id, version_id, caused_by=user.username, action="create")
            return {"created": is_new, "linked": True, "entity_id": str(existing_entity.entity_id)}
        return {"created": is_new, "linked": False, "entity_id": str(existing_entity.entity_id)}
    return None


@router.post("/tmdb/import-credits/{entity_id}", summary="Импорт связей из TMDB", description="Импорт актёров, режиссёров, компаний и других связей из TMDB")
async def tmdb_import_credits(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """
    Import TMDB movie details, credits, companies, countries, languages.
    Creates entities for actors, directors, production companies, countries, languages
    and links them via semantic relations.
    """
    from uuid import UUID, uuid4
    import hashlib, json
    from app.models.entities import Entity, EntityLabel
    from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate, OntologyModel
    from app.models.kinds import EntityKind
    from app.models.relations import SemanticRelation, RelationType

    eid = UUID(entity_id)
    logger.info("Starting TMDB credits import for entity %s by user %s", entity_id, user.user_id)

    proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == eid))).scalars().first()
    if not proj:
        raise HTTPException(404, "Сущность не найдена")

    ps = (await db.execute(
        select(ProjectionState).where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
    )).scalars().first()
    if not ps or not ps.state_data:
        raise HTTPException(400, "Нет данных TMDB у сущности")

    tmdb_id_raw = ps.state_data.get("tmdb_id")
    if not tmdb_id_raw:
        raise HTTPException(400, "У сущности нет tmdb_id")
    
    # Handle multilingual tmdb_id (dict or string)
    if isinstance(tmdb_id_raw, dict):
        tmdb_id = tmdb_id_raw.get("ru") or tmdb_id_raw.get("en") or next((v for v in tmdb_id_raw.values() if v), None)
    else:
        tmdb_id = tmdb_id_raw
    
    if not tmdb_id:
        raise HTTPException(400, "tmdb_id пустой")

    credits = await tmdb_service.get_movie_credits(int(tmdb_id))
    if not credits:
        raise HTTPException(400, "Не удалось получить данные из TMDB")

    movie_full = await tmdb_service.get_movie(int(tmdb_id))

    version_result = await db.execute(select(func.max(Entity.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    result = {"actors": {"created": 0, "linked": 0}, "directors": {"created": 0, "linked": 0}, "companies": {"created": 0, "linked": 0}, "countries": {"created": 0, "linked": 0}, "languages": {"created": 0, "linked": 0}}

    src_proj = proj
    actors_created = set()
    directors_created = set()

    # Ensure character kind and relation types exist
    _, plays_rel = await _ensure_kind_and_relation(db, "character", "plays", "played_by")
    _, appears_rel = await _ensure_kind_and_relation(db, "character", "appears_in", "features")

    # Process actors
    for person in credits.get("cast", [])[:15]:
        ptid = person.get("tmdb_id")
        if not ptid:
            continue
        extra = {}
        profile = person.get("profile_path") or person.get("poster")
        if profile and hasattr(tmdb_service, 'image_base'):
            extra["poster"] = f"{tmdb_service.image_base}/w185{profile}" if not str(profile).startswith("http") else profile
        meta = {}
        role = person.get("character", "")
        if role:
            meta["role"] = role
        res = await _find_or_create_related_entity(db, person.get("name", ""), ptid, "actor", "acted_in", user.user_id, version_id, src_proj, user, extra_state=extra, metadata=meta)
        if res:
            if res["created"]:
                result["actors"]["created"] += 1
            if res["linked"]:
                result["actors"]["linked"] += 1

        # Create character entity if role exists
        if role and res and res.get("entity_id"):
            actor_entity_id = res["entity_id"]
            char_kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == "character"))).scalars().first()
            if char_kind:
                char_entity_code = f"character_{tmdb_id}_{ptid}"
                char_existing = (await db.execute(select(Entity).where(Entity.entity_code == char_entity_code))).scalars().first()
                if not char_existing:
                    char_id = uuid4()
                    char_entity = Entity(entity_id=char_id, entity_code=char_entity_code, kind_id=char_kind.kind_id, status="active", owner_id=user.user_id, version_id=version_id)
                    db.add(char_entity)
                    await db.flush()
                    ru_lang_id = await get_language_id(db, "ru")
                    char_label = EntityLabel(entity_id=char_id, language_id=ru_lang_id, label=role, is_primary=True, owner_id=user.user_id, version_id=version_id)
                    db.add(char_label)
                    char_tmpl = (await db.execute(select(OntologyTemplate).where(OntologyTemplate.kind_id == char_kind.kind_id, OntologyTemplate.is_active == True).limit(1))).scalars().first()
                    # Always create a projection, even without a template (use default model)
                    char_tmpl_id = char_tmpl.template_id if char_tmpl else None
                    char_model = char_tmpl.model_id if char_tmpl else (await db.execute(select(OntologyModel).limit(1))).scalars().first()
                    char_model_id = char_model if isinstance(char_model, UUID) else (char_model.model_id if char_model else uuid4())
                    char_proj = EntityProjection(
                        projection_id=uuid4(), entity_id=char_id,
                        model_id=char_model_id,
                        template_id=char_tmpl_id, projection_code=char_entity_code,
                        projection_name=role, confidence=1.0, version_id=version_id
                    )
                    db.add(char_proj)
                    await db.flush()
                    char_state = ProjectionState(
                        projection_id=char_proj.projection_id, state_data={"tmdb_id": str(tmdb_id), "name": role, "character_of": person.get("name", "")},
                        state_hash=hashlib.sha256(json.dumps({"tmdb_id": str(tmdb_id), "name": role}, sort_keys=True, default=str).encode()).hexdigest(),
                        is_current=True, version_id=version_id
                    )
                    db.add(char_state)
                    char_existing = char_entity

                # Link actor -> character (plays)
                if char_existing:
                    actor_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == UUID(actor_entity_id)).limit(1))).scalars().first()
                    char_tgt_proj = (await db.execute(select(EntityProjection).where(EntityProjection.entity_id == char_existing.entity_id).limit(1))).scalars().first()
                    if actor_proj and char_tgt_proj:
                        ex_rel = await db.execute(
                            select(SemanticRelation).where(
                                SemanticRelation.source_projection_id == actor_proj.projection_id,
                                SemanticRelation.relation_type_id == plays_rel.relation_type_id,
                                SemanticRelation.target_projection_id == char_tgt_proj.projection_id,
                            )
                        )
                        if not ex_rel.scalars().first():
                            db.add(SemanticRelation(source_projection_id=actor_proj.projection_id, relation_type_id=plays_rel.relation_type_id, target_projection_id=char_tgt_proj.projection_id, confidence=1.0, version_id=version_id))

                        # Link character -> movie (appears_in)
                        ex_rel2 = await db.execute(
                            select(SemanticRelation).where(
                                SemanticRelation.source_projection_id == char_tgt_proj.projection_id,
                                SemanticRelation.relation_type_id == appears_rel.relation_type_id,
                                SemanticRelation.target_projection_id == src_proj.projection_id,
                            )
                        )
                        if not ex_rel2.scalars().first():
                            db.add(SemanticRelation(source_projection_id=char_tgt_proj.projection_id, relation_type_id=appears_rel.relation_type_id, target_projection_id=src_proj.projection_id, confidence=1.0, version_id=version_id))

    # Process directors
    for person in credits.get("crew", []):
        if person.get("job") != "Director":
            continue
        ptid = person.get("tmdb_id")
        if not ptid:
            continue
        extra = {}
        profile = person.get("profile_path") or person.get("poster")
        if profile and hasattr(tmdb_service, 'image_base'):
            extra["poster"] = f"{tmdb_service.image_base}/w185{profile}" if not str(profile).startswith("http") else profile
        res = await _find_or_create_related_entity(db, person.get("name", ""), ptid, "director", "directed_by", user.user_id, version_id, src_proj, user, extra_state=extra)
        if res:
            if res["created"]:
                result["directors"]["created"] += 1
            if res["linked"]:
                result["directors"]["linked"] += 1

    # Process production companies from movie_full
    if movie_full and "production_companies" in movie_full:
        for company in (movie_full.get("production_companies") or []):
            cid = company.get("tmdb_id") or company.get("id")
            cname = company.get("name", "")
            if cid and cname:
                res = await _find_or_create_related_entity(db, cname, str(cid), "company", "produced_by", user.user_id, version_id, src_proj, user)
                if res:
                    if res["created"]:
                        result["companies"]["created"] += 1
                    if res["linked"]:
                        result["companies"]["linked"] += 1

    # Process production countries
    if movie_full and "production_countries" in movie_full:
        for country in (movie_full.get("production_countries") or []):
            cname = country.get("name", "")
            ccode = country.get("iso_3166_1", "")
            if cname:
                res = await _find_or_create_related_entity(db, cname, ccode, "country", "produced_in", user.user_id, version_id, src_proj, user)
                if res:
                    if res["created"]:
                        result["countries"]["created"] += 1
                    if res["linked"]:
                        result["countries"]["linked"] += 1

    # Process spoken languages
    if movie_full and "spoken_languages" in movie_full:
        for lang in (movie_full.get("spoken_languages") or []):
            lname = lang.get("name", "")
            lcode = lang.get("iso_639_1", "")
            if lname:
                res = await _find_or_create_related_entity(db, lname, lcode, "language", "language_of", user.user_id, version_id, src_proj, user)
                if res:
                    if res["created"]:
                        result["languages"]["created"] += 1
                    if res["linked"]:
                        result["languages"]["linked"] += 1

    await db.commit()

    msg_parts = []
    if result["actors"]["created"]:
        msg_parts.append(f"актёров: {result['actors']['created']}")
    if result["directors"]["created"]:
        msg_parts.append(f"режиссёров: {result['directors']['created']}")
    if result["companies"]["created"]:
        msg_parts.append(f"компаний: {result['companies']['created']}")
    if result["countries"]["created"]:
        msg_parts.append(f"стран: {result['countries']['created']}")
    if result["languages"]["created"]:
        msg_parts.append(f"языков: {result['languages']['created']}")
    msg = f"Создано: {', '.join(msg_parts)}" if msg_parts else "Новых сущностей не создано (все уже существуют)"

    logger.info("TMDB import completed for entity %s: %s", entity_id, msg)
    return {"imported": result, "message": msg}


# ─── OMDb (IMDB) ─────────────────────────────────────────────

@router.get("/omdb/status", summary="Проверка настройки OMDb API")
async def omdb_status(user: UserAccount = Depends(require_auth)):
    """Check if OMDb API is configured."""
    from app.config import get_settings
    configured = bool(get_settings().OMDB_API_KEY)
    return {
        "configured": configured,
        "message": "OMDb API настроен" if configured else "OMDb API ключ не задан (OMDB_API_KEY в .env)"
    }


@router.get("/omdb/search", summary="Поиск фильмов в OMDb (IMDB)")
async def omdb_search(
    q: str = Query(..., min_length=1),
    user: UserAccount = Depends(require_auth),
):
    """Search movies via OMDb API (IMDB data)."""
    from app.services.external_apis import search_imdb
    results = await search_imdb(q)
    return {"results": results, "query": q}


@router.get("/omdb/movie/{imdb_id}", summary="Детали фильма из OMDb")
async def omdb_get_movie(
    imdb_id: str,
    user: UserAccount = Depends(require_auth),
):
    """Get detailed movie info from OMDb by IMDB ID (e.g. tt1375666)."""
    from app.services.external_apis import get_imdb_details
    movie = await get_imdb_details(imdb_id)
    if not movie:
        raise HTTPException(404, "Фильм не найден в OMDb или API ключ не настроен")
    return movie


@router.post("/omdb/import/{imdb_id}", summary="Импорт фильма из OMDb")
async def omdb_import_movie(
    imdb_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Import a movie from OMDb as an entity."""
    from app.services.external_apis import get_imdb_details, import_imdb_movie

    movie = await get_imdb_details(imdb_id)
    if not movie:
        raise HTTPException(404, "Фильм не найден в OMDb или API ключ не настроен")

    result = await import_imdb_movie(db, movie, user.user_id)
    await db.commit()

    if result["status"] == "exists":
        return {"status": "exists", "message": result["message"], "entity_code": result["entity_code"]}

    return {"status": "created", "message": f"Фильм '{movie['title']}' импортирован", "entity_id": result["entity_id"], "entity_code": result["entity_code"]}


# ─── Wikipedia ────────────────────────────────────────────────

@router.get("/wikipedia/search", summary="Поиск в Wikipedia")
async def wikipedia_search(
    q: str = Query(..., min_length=1),
    lang: str = Query("ru", regex="^(ru|en|de|fr|es|zh|ja)$"),
    user: UserAccount = Depends(require_auth),
):
    """Search Wikipedia articles."""
    from app.services.external_apis import search_wikipedia
    results = await search_wikipedia(q, lang)
    return {"results": results, "query": q, "lang": lang}


@router.get("/wikipedia/page/{title}", summary="Страница Wikipedia")
async def wikipedia_get_page(
    title: str,
    lang: str = Query("ru", regex="^(ru|en|de|fr|es|zh|ja)$"),
    user: UserAccount = Depends(require_auth),
):
    """Get Wikipedia page summary."""
    from app.services.external_apis import get_wikipedia_page
    page = await get_wikipedia_page(title, lang)
    if not page:
        raise HTTPException(404, "Страница не найдена в Wikipedia")
    return page


@router.post("/wikipedia/import/{title}", summary="Импорт статьи из Wikipedia")
async def wikipedia_import_page(
    title: str,
    lang: str = Query("ru", regex="^(ru|en|de|fr|es|zh|ja)$"),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Import a Wikipedia article as an entity."""
    from app.services.external_apis import get_wikipedia_page, import_wikipedia_page

    page = await get_wikipedia_page(title, lang)
    if not page:
        raise HTTPException(404, "Страница не найдена в Wikipedia")

    result = await import_wikipedia_page(db, page, user.user_id, lang)
    await db.commit()

    if result["status"] == "exists":
        return {"status": "exists", "message": result["message"], "entity_code": result["entity_code"]}

    return {"status": "created", "message": f"Статья '{title}' импортирована", "entity_id": result["entity_id"], "entity_code": result["entity_code"]}


# ─── MusicBrainz ──────────────────────────────────────────────

@router.get("/musicbrainz/search", summary="Поиск в MusicBrainz")
async def musicbrainz_search(
    q: str = Query(..., min_length=1),
    type: str = Query("recording", regex="^(recording|artist|release-group)$"),
    user: UserAccount = Depends(require_auth),
):
    """Search MusicBrainz (recordings, artists, release groups)."""
    from app.services.external_apis import search_musicbrainz
    results = await search_musicbrainz(q, type)
    return {"results": results, "query": q, "type": type}


@router.get("/musicbrainz/{entity_type}/{mb_id}", summary="Детали MusicBrainz")
async def musicbrainz_get_details(
    entity_type: str,
    mb_id: str,
    user: UserAccount = Depends(require_auth),
):
    """Get MusicBrainz entity details."""
    from app.services.external_apis import get_musicbrainz_details
    details = await get_musicbrainz_details(mb_id, entity_type)
    if not details:
        raise HTTPException(404, "Не найдено в MusicBrainz")
    return details


@router.post("/musicbrainz/import/{entity_type}/{mb_id}", summary="Импорт из MusicBrainz")
async def musicbrainz_import(
    entity_type: str,
    mb_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Import MusicBrainz entity as database entity."""
    from app.services.external_apis import get_musicbrainz_details, import_musicbrainz_entity

    details = await get_musicbrainz_details(mb_id, entity_type)
    if not details:
        raise HTTPException(404, "Не найдено в MusicBrainz")

    result = await import_musicbrainz_entity(db, details, user.user_id, entity_type)
    await db.commit()

    if result["status"] == "exists":
        return {"status": "exists", "message": result["message"], "entity_code": result["entity_code"]}

    return {"status": "created", "message": f"'{details['title']}' импортирован", "entity_id": result["entity_id"], "entity_code": result["entity_code"]}
