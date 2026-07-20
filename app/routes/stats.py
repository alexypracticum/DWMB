from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind
from app.models.projections import EntityProjection, ProjectionState
from app.models.relations import SemanticRelation, RelationType
from app.models.users import UserAccount
from app.services.auth import get_current_user
from app.routes.entities import _get_kind_label

router = APIRouter(tags=["stats"])
templates = Jinja2Templates(directory="app/templates")


@router.get("/stats", response_class=HTMLResponse)
async def stats_page(request: Request, db: AsyncSession = Depends(get_db), user: UserAccount = Depends(get_current_user)):
    # Total counts
    total_entities = await db.scalar(select(func.count(Entity.entity_id)).where(Entity.status == "active"))
    total_projections = await db.scalar(select(func.count(EntityProjection.projection_id)))
    total_relations = await db.scalar(select(func.count(SemanticRelation.relation_id)))
    total_kinds = await db.scalar(select(func.count(EntityKind.kind_id)).where(EntityKind.is_abstract == False))

    # Entities per kind (for bar chart)
    kind_stats_result = await db.execute(
        select(EntityKind.kind_code, func.count(Entity.entity_id))
        .join(Entity, Entity.kind_id == EntityKind.kind_id, isouter=True)
        .where(EntityKind.is_abstract == False)
        .group_by(EntityKind.kind_code)
        .order_by(func.count(Entity.entity_id).desc())
    )
    kind_stats = [{"code": code, "count": count} for code, count in kind_stats_result]

    # Relations per type (for pie chart)
    rel_stats_result = await db.execute(
        select(RelationType.relation_name, func.count(SemanticRelation.relation_id))
        .join(SemanticRelation, SemanticRelation.relation_type_id == RelationType.relation_type_id, isouter=True)
        .group_by(RelationType.relation_name)
        .order_by(func.count(SemanticRelation.relation_id).desc())
    )
    rel_stats = [{"name": name, "count": count} for name, count in rel_stats_result]

    # Entities per kind for chart data (with translated labels)
    lang = getattr(request.state, "lang", "ru")
    chart_labels = []
    chart_values = []
    for s in kind_stats:
        kind_result = await db.execute(select(EntityKind).where(EntityKind.kind_code == s["code"]))
        kind = kind_result.scalar_one_or_none()
        if kind:
            label = await _get_kind_label(db, kind.kind_id, lang) or s["code"]
        else:
            label = s["code"]
        chart_labels.append(label)
        chart_values.append(s["count"])

    # Relation chart data
    rel_labels = [s["name"] for s in rel_stats]
    rel_values = [s["count"] for s in rel_stats]

    # Kinds for sidebar
    kinds_result = await db.execute(
        select(EntityKind).where(EntityKind.is_abstract == False).order_by(EntityKind.sort_order)
    )
    kinds = kinds_result.scalars().all()

    return templates.TemplateResponse("stats/index.html", {
        "request": request,
        "user": user,
        "kinds": kinds,
        "total_entities": total_entities,
        "total_projections": total_projections,
        "total_relations": total_relations,
        "total_kinds": total_kinds,
        "kind_stats": kind_stats,
        "rel_stats": rel_stats,
        "chart_labels": chart_labels,
        "chart_values": chart_values,
        "rel_labels": rel_labels,
        "rel_values": rel_values,
    })
