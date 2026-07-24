"""
Personal dashboard routes: import history, favorites, activity.
"""
from uuid import UUID
from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.models.entities import Entity, EntityLabel, EventLog
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.favorites import UserFavorite
from app.services.auth import require_auth
from app.services.language_service import get_kind_label

router = APIRouter(prefix="/dashboard", tags=["dashboard"])
templates = Jinja2Templates(directory="app/templates")


@router.get("/", response_class=HTMLResponse)
async def dashboard_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Personal dashboard: import history, favorites, stats."""
    lang = getattr(request.state, "lang", "ru")

    # ── Import History (last 20 events) ─────────────────────────
    events_result = await db.execute(
        select(EventLog, Entity, EntityLabel, EntityKind)
        .join(Entity, Entity.entity_id == EventLog.entity_id, isouter=True)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id, isouter=True)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id, isouter=True)
        .where(
            EventLog.caused_by == user.username,
            EventLog.event_type == "create",
            EntityLabel.is_primary == True,
        )
        .order_by(desc(EventLog.occurred_at))
        .limit(20)
    )
    import_history = []
    for event, entity, label, kind in events_result.unique():
        if entity:
            source = event.payload.get("source", "") if event.payload else ""
            import_history.append({
                "event": event,
                "entity": entity,
                "label": label,
                "kind": kind,
                "kind_label": kind.kind_code,
                "source": source,
            })

    # ── Favorites (last 20) ─────────────────────────────────────
    favs_result = await db.execute(
        select(UserFavorite, Entity, EntityLabel, EntityKind)
        .join(Entity, Entity.entity_id == UserFavorite.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(
            UserFavorite.user_id == user.user_id,
            EntityLabel.is_primary == True,
        )
        .order_by(desc(UserFavorite.created_at))
        .limit(20)
    )
    favorites = []
    for fav, entity, label, kind in favs_result.unique():
        favorites.append({
            "favorite": fav,
            "entity": entity,
            "label": label,
            "kind": kind,
            "kind_label": await get_kind_label(db, kind.kind_id, lang) or kind.kind_code,
        })

    # ── Stats ───────────────────────────────────────────────────
    # Total entities created by user
    created_count_result = await db.execute(
        select(func.count()).select_from(Entity).where(Entity.owner_id == user.user_id)
    )
    entities_created = created_count_result.scalar() or 0

    # Total favorites
    fav_count_result = await db.execute(
        select(func.count()).select_from(UserFavorite).where(UserFavorite.user_id == user.user_id)
    )
    total_favorites = fav_count_result.scalar() or 0

    # Total imports (events with source)
    import_count_result = await db.execute(
        select(func.count()).select_from(EventLog).where(
            EventLog.caused_by == user.username,
            EventLog.event_type == "create",
        )
    )
    total_imports = import_count_result.scalar() or 0

    return templates.TemplateResponse("dashboard/index.html", {
        "request": request,
        "user": user,
        "import_history": import_history,
        "favorites": favorites,
        "stats": {
            "entities_created": entities_created,
            "total_favorites": total_favorites,
            "total_imports": total_imports,
        },
    })


@router.post("/favorite/{entity_id}")
async def toggle_favorite(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Toggle favorite status for an entity."""
    eid = UUID(entity_id)

    # Check if already favorited
    existing = await db.execute(
        select(UserFavorite).where(
            UserFavorite.user_id == user.user_id,
            UserFavorite.entity_id == eid,
        )
    )
    fav = existing.scalar_one_or_none()

    if fav:
        await db.delete(fav)
        await db.commit()
        return {"status": "removed", "favorited": False}
    else:
        new_fav = UserFavorite(user_id=user.user_id, entity_id=eid)
        db.add(new_fav)
        await db.commit()
        return {"status": "added", "favorited": True}


@router.get("/favorites/check/{entity_id}")
async def check_favorite(
    entity_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Check if entity is favorited by current user."""
    result = await db.execute(
        select(UserFavorite).where(
            UserFavorite.user_id == user.user_id,
            UserFavorite.entity_id == UUID(entity_id),
        )
    )
    is_fav = result.scalar_one_or_none() is not None
    return {"favorited": is_fav}
