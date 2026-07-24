from uuid import UUID
from typing import Optional
from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_, text, case
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import ProjectionState, EntityProjection
from app.models.users import UserAccount
from app.models.relations import RelationType, SemanticRelation
from app.services.auth import get_current_user
from app.services.ai import ai_service
from app.services.language_service import get_language_id, get_kind_label, get_lang

router = APIRouter(tags=["search"])
templates = Jinja2Templates(directory="app/templates")



@router.get("/search", response_class=HTMLResponse)
async def search_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(get_current_user),
    q: str = Query(""),
    kind: Optional[str] = Query(None),
    search_type: str = Query("text"),
    search_mode: str = Query("text"),
    relation_code: Optional[str] = Query(None),
    year_from: Optional[str] = Query(None),
    year_to: Optional[str] = Query(None),
    rating_min: Optional[str] = Query(None),
    genre: Optional[str] = Query(None),
    production_company: Optional[str] = Query(None),
    country: Optional[str] = Query(None),
    language: Optional[str] = Query(None),
    source: Optional[str] = Query(None),
    date_from: Optional[str] = Query(None),
    date_to: Optional[str] = Query(None),
    sort_by: str = Query("relevance"),
    use_ai: bool = Query(False),
):
    results = []
    graph_results = []
    total_count = 0
    ai_parsed = None
    graph_relation_types = []

    # Convert string params to int/float (form sends empty strings)
    year_from_int = int(year_from) if year_from else None
    year_to_int = int(year_to) if year_to else None
    rating_min_val = float(rating_min) if rating_min else None

    # AI parsing of natural language query
    if use_ai and q and ai_service.api_key:
        try:
            ai_parsed = await ai_service.parse_entity_text(q, "search_query", db)
            if ai_parsed:
                if "kind" in ai_parsed and not kind:
                    kind = ai_parsed["kind"]
                if "year" in ai_parsed and not year_from_int:
                    year_from_int = ai_parsed["year"]
                    year_to_int = ai_parsed["year"]
                if "genre" in ai_parsed and not genre:
                    genre = ai_parsed["genre"]
                if "rating_min" in ai_parsed and not rating_min_val:
                    rating_min_val = ai_parsed["rating_min"]
        except Exception:
            pass

    lang = getattr(request.state, "lang", "ru")

    if search_mode == "graph" and q:
        # ── Graph Search Mode ──────────────────────────────────
        from app.services.graph_search import search_related_by_text, get_relation_types_for_entity

        graph_results = await search_related_by_text(
            db,
            query_text=q,
            relation_code=relation_code,
            target_kind=kind,
            limit=100,
            lang=lang,
        )
        total_count = len(graph_results)

    elif q:
        # ── Text Search Mode ───────────────────────────────────
        search_pattern = f"%{q}%"
        ru_lang_id = await get_language_id(db, "ru")

        base_query = (
            select(Entity, EntityLabel, EntityKind)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
            .where(
                Entity.status == "active",
                EntityLabel.language_id == ru_lang_id,
                EntityLabel.is_primary == True,
            )
        )

        if search_type == "fts":
            base_query = base_query.where(
                or_(
                    text("to_tsvector('russian', coalesce(entity_label.label, '') || ' ' || coalesce(entity_label.description, '') || ' ' || coalesce(entity_label.content, '')) @@ plainto_tsquery('russian', :q)"),
                    Entity.entity_code.ilike(search_pattern),
                )
            )
        else:
            base_query = base_query.where(
                or_(
                    EntityLabel.label.ilike(search_pattern),
                    EntityLabel.description.ilike(search_pattern),
                    EntityLabel.content.ilike(search_pattern),
                    Entity.entity_code.ilike(search_pattern),
                )
            )

        if kind:
            kind_obj = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind))
            kind_row = kind_obj.scalar_one_or_none()
            if kind_row:
                base_query = base_query.where(Entity.kind_id == kind_row.kind_id)

        count_q = select(func.count()).select_from(base_query.subquery())
        count_params = {"q": q} if search_type == "fts" else {}
        total_count = (await db.execute(count_q, count_params)).scalar() or 0

        if sort_by == "name":
            base_query = base_query.order_by(EntityLabel.label)
        elif sort_by == "newest":
            base_query = base_query.order_by(Entity.created_at.desc())
        else:
            base_query = base_query.order_by(Entity.updated_at.desc())

        result = await db.execute(base_query.limit(100), {"q": q} if search_type == "fts" else {})
        seen = set()
        for entity, label, kind in result.unique():
            if entity.entity_id not in seen:
                seen.add(entity.entity_id)
                kl = await get_kind_label(db, kind.kind_id, lang) or kind.kind_code

                state_result = await db.execute(
                    select(ProjectionState)
                    .join(EntityProjection, EntityProjection.projection_id == ProjectionState.projection_id)
                    .where(EntityProjection.entity_id == entity.entity_id, ProjectionState.is_current == True)
                    .limit(1)
                )
                state = state_result.scalar_one_or_none()
                state_data = state.state_data if state else {}

                if year_from_int and state_data.get("year"):
                    if int(state_data["year"]) < year_from_int:
                        continue
                if year_to_int and state_data.get("year"):
                    if int(state_data["year"]) > year_to_int:
                        continue
                if rating_min_val is not None and state_data.get("rating"):
                    if float(state_data["rating"]) < rating_min_val:
                        continue
                if genre and state_data.get("genre"):
                    if genre.lower() not in str(state_data["genre"]).lower():
                        continue
                if production_company and state_data.get("production_company"):
                    if production_company.lower() not in str(state_data["production_company"]).lower():
                        continue
                if country and state_data.get("country"):
                    if country.lower() not in str(state_data["country"]).lower():
                        continue
                if language and state_data.get("language"):
                    if language.lower() not in str(state_data["language"]).lower():
                        continue

                if source and entity.source_id:
                    from app.models.entities import SourceSystem
                    src_result = await db.execute(
                        select(SourceSystem.source_code).where(SourceSystem.source_id == entity.source_id)
                    )
                    src_code = src_result.scalar_one_or_none()
                    if src_code and source.lower() != src_code.lower():
                        continue

                if date_from and entity.created_at:
                    from datetime import datetime
                    try:
                        df = datetime.fromisoformat(date_from)
                        if entity.created_at < df:
                            continue
                    except ValueError:
                        pass
                if date_to and entity.created_at:
                    from datetime import datetime
                    try:
                        dt = datetime.fromisoformat(date_to)
                        if entity.created_at > dt:
                            continue
                    except ValueError:
                        pass

                results.append({
                    "entity": entity,
                    "label": label,
                    "kind": kind,
                    "kind_label": kl,
                    "state_data": state_data,
                })

    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()

    # Get relation types for graph mode filter
    if search_mode == "graph":
        from app.models.relations import RelationType
        rt_result = await db.execute(
            select(RelationType.relation_code, RelationType.relation_name, func.count(SemanticRelation.relation_id))
            .join(SemanticRelation, SemanticRelation.relation_type_id == RelationType.relation_type_id)
            .group_by(RelationType.relation_code, RelationType.relation_name)
            .order_by(func.count(SemanticRelation.relation_id).desc())
        )
        graph_relation_types = [
            {"code": code, "name": name, "count": count}
            for code, name, count in rt_result
        ]

    return templates.TemplateResponse("search/results.html", {
        "request": request,
        "user": user,
        "query": q,
        "results": results,
        "graph_results": graph_results,
        "total_count": total_count,
        "kinds": kinds,
        "current_kind": kind,
        "search_type": search_type,
        "search_mode": search_mode,
        "current_relation": relation_code,
        "graph_relation_types": graph_relation_types,
        "year_from": year_from,
        "year_to": year_to,
        "rating_min": rating_min,
        "genre": genre,
        "production_company": production_company,
        "country": country,
        "language": language,
        "source": source,
        "date_from": date_from,
        "date_to": date_to,
        "sort_by": sort_by,
        "use_ai": use_ai,
        "ai_parsed": ai_parsed,
    })
