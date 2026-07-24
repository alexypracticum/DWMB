"""Admin: Event Log — audit trail for all entity changes."""
from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models.entities import EventLog, Entity, EntityLabel
from app.services.auth import get_current_user
from app.services.rbac import require_permission
from app.services.language_service import get_lang

templates = Jinja2Templates(directory="app/templates")
router = APIRouter(tags=["admin"])


@router.get("/event-log", response_class=HTMLResponse)
async def event_log_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user=Depends(require_permission("admin.access")),
    event_type: str = Query(None),
    entity_id: str = Query(None),
    caused_by: str = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=10, le=200),
):
    lang = get_lang(request)
    offset = (page - 1) * page_size

    query = select(EventLog).order_by(EventLog.occurred_at.desc())
    count_query = select(func.count(EventLog.event_id))

    if event_type:
        query = query.where(EventLog.event_type == event_type)
        count_query = count_query.where(EventLog.event_type == event_type)
    if entity_id:
        query = query.where(EventLog.entity_id == entity_id)
        count_query = count_query.where(EventLog.entity_id == entity_id)
    if caused_by:
        query = query.where(EventLog.caused_by.ilike(f"%{caused_by}%"))
        count_query = count_query.where(EventLog.caused_by.ilike(f"%{caused_by}%"))

    total = await db.scalar(count_query)
    result = await db.execute(query.offset(offset).limit(page_size))
    events = result.scalars().all()

    # Resolve entity labels for display
    entity_ids = list({e.entity_id for e in events if e.entity_id})
    entity_labels = {}
    if entity_ids:
        labels_result = await db.execute(
            select(EntityLabel.entity_id, EntityLabel.label)
            .where(EntityLabel.entity_id.in_(entity_ids))
            .where(EntityLabel.is_primary == True)
        )
        for row in labels_result:
            entity_labels[row[0]] = row[1]

    total_pages = max(1, (total + page_size - 1) // page_size)

    return templates.TemplateResponse("admin/event_log.html", {
        "request": request,
        "user": user,
        "events": events,
        "entity_labels": entity_labels,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages,
        "event_type_filter": event_type or "",
        "entity_id_filter": entity_id or "",
        "caused_by_filter": caused_by or "",
    })
