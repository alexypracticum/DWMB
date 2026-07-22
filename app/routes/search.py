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
    kind: str = Query(None),
    search_type: str = Query("text"),
    year_from: int = Query(None),
    year_to: int = Query(None),
    rating_min: float = Query(None),
    genre: str = Query(None),
    production_company: str = Query(None),
    country: str = Query(None),
    language: str = Query(None),
    source: str = Query(None),
    date_from: str = Query(None),
    date_to: str = Query(None),
    sort_by: str = Query("relevance"),
    use_ai: bool = Query(False),
):
    results = []
    total_count = 0
    ai_parsed = None

    # AI parsing of natural language query
    if use_ai and q and ai_service.api_key:
        try:
            ai_parsed = await ai_service.parse_entity_text(q, "search_query", db)
            if ai_parsed:
                # Apply AI-parsed filters
                if "kind" in ai_parsed and not kind:
                    kind = ai_parsed["kind"]
                if "year" in ai_parsed and not year_from:
                    year_from = ai_parsed["year"]
                    year_to = ai_parsed["year"]
                if "genre" in ai_parsed and not genre:
                    genre = ai_parsed["genre"]
                if "rating_min" in ai_parsed and not rating_min:
                    rating_min = ai_parsed["rating_min"]
        except Exception:
            pass  # Fall back to regular search

    if q:
        search_pattern = f"%{q}%"
        ru_lang_id = await get_language_id(db, "ru")

        # Base query with labels and kinds
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

        # Text search
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

        # Kind filter
        if kind:
            kind_obj = await db.execute(select(EntityKind).where(EntityKind.kind_code == kind))
            kind_row = kind_obj.scalar_one_or_none()
            if kind_row:
                base_query = base_query.where(Entity.kind_id == kind_row.kind_id)

        # Count
        count_q = select(func.count()).select_from(base_query.subquery())
        count_params = {"q": q} if search_type == "fts" else {}
        total_count = (await db.execute(count_q, count_params)).scalar() or 0

        # Sort
        if sort_by == "name":
            base_query = base_query.order_by(EntityLabel.label)
        elif sort_by == "newest":
            base_query = base_query.order_by(Entity.created_at.desc())
        else:
            base_query = base_query.order_by(Entity.updated_at.desc())

        result = await db.execute(base_query.limit(100), {"q": q} if search_type == "fts" else {})
        seen = set()
        lang = getattr(request.state, "lang", "ru")
        for entity, label, kind in result.unique():
            if entity.entity_id not in seen:
                seen.add(entity.entity_id)
                kl = await get_kind_label(db, kind.kind_id, lang) or kind.kind_code

                # Get state_data for metadata
                state_result = await db.execute(
                    select(ProjectionState)
                    .join(EntityProjection, EntityProjection.projection_id == ProjectionState.projection_id)
                    .where(EntityProjection.entity_id == entity.entity_id, ProjectionState.is_current == True)
                    .limit(1)
                )
                state = state_result.scalar_one_or_none()
                state_data = state.state_data if state else {}

                # Apply filters on state_data
                if year_from and state_data.get("year"):
                    if int(state_data["year"]) < year_from:
                        continue
                if year_to and state_data.get("year"):
                    if int(state_data["year"]) > year_to:
                        continue
                if rating_min is not None and state_data.get("rating"):
                    if float(state_data["rating"]) < rating_min:
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

                # Source filter
                if source and entity.source_id:
                    from app.models.entities import SourceSystem
                    src_result = await db.execute(
                        select(SourceSystem.source_code).where(SourceSystem.source_id == entity.source_id)
                    )
                    src_code = src_result.scalar_one_or_none()
                    if src_code and source.lower() != src_code.lower():
                        continue

                # Date filters
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

    return templates.TemplateResponse("search/results.html", {
        "request": request,
        "user": user,
        "query": q,
        "results": results,
        "total_count": total_count,
        "kinds": kinds,
        "current_kind": kind,
        "search_type": search_type,
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
