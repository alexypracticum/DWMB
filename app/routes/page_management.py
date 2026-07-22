"""
Page management routes — CRUD for pages via entity kind='page'.
"""
from uuid import UUID, uuid4
from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import json
import hashlib

from app.database import get_db
from app.models.users import UserAccount
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind
from app.models.projections import EntityProjection, ProjectionState, OntologyModel, OntologyTemplate
from app.models.languages import Language
from app.services.auth import require_admin, require_auth

router = APIRouter(prefix="/admin/pages", tags=["admin-pages"])
templates = Jinja2Templates(directory="app/templates")


async def _get_page_kind(db: AsyncSession) -> EntityKind:
    """Get or raise if page kind doesn't exist."""
    result = await db.execute(
        select(EntityKind).where(EntityKind.kind_code == "page")
    )
    kind = result.scalar_one_or_none()
    if not kind:
        raise HTTPException(status_code=500, detail="Entity kind 'page' not found. Run migration 009.")
    return kind


async def _get_page_template(db: AsyncSession, kind: EntityKind) -> OntologyTemplate:
    """Get or raise if page template doesn't exist."""
    result = await db.execute(
        select(OntologyTemplate)
        .where(OntologyTemplate.kind_id == kind.kind_id, OntologyTemplate.is_active == True)
        .limit(1)
    )
    tmpl = result.scalar_one_or_none()
    if not tmpl:
        raise HTTPException(status_code=500, detail="Ontology template for 'page' not found. Run migration 009.")
    return tmpl


async def _get_lang_id(db: AsyncSession, code: str) -> UUID:
    """Get language ID by code."""
    result = await db.execute(select(Language).where(Language.code == code))
    lang = result.scalar_one_or_none()
    if not lang:
        raise HTTPException(status_code=500, detail=f"Language '{code}' not found.")
    return lang.language_id


async def _load_page_data(db: AsyncSession, entity: Entity) -> dict:
    """Load page data from entity projection + state."""
    # Get first projection for this entity
    result = await db.execute(
        select(EntityProjection)
        .where(EntityProjection.entity_id == entity.entity_id)
        .limit(1)
    )
    proj = result.scalar_one_or_none()
    if not proj:
        return {}

    # Get current state
    result = await db.execute(
        select(ProjectionState)
        .where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
        .limit(1)
    )
    state = result.scalar_one_or_none()
    if not state:
        return {}

    return state.state_data or {}


async def _get_primary_label(db: AsyncSession, entity_id: UUID) -> EntityLabel | None:
    """Get primary label for entity."""
    result = await db.execute(
        select(EntityLabel)
        .where(EntityLabel.entity_id == entity_id, EntityLabel.is_primary == True)
        .limit(1)
    )
    return result.scalar_one_or_none()


async def _save_page_data(db: AsyncSession, entity: Entity, data: dict, lang_code: str = "ru"):
    """Save page data to entity projection + state."""
    kind = await _get_page_kind(db)
    tmpl = await _get_page_template(db, kind)
    lang_id = await _get_lang_id(db, lang_code)

    # Get or create current projection
    result = await db.execute(
        select(EntityProjection)
        .where(EntityProjection.entity_id == entity.entity_id)
        .limit(1)
    )
    proj = result.scalar_one_or_none()

    if not proj:
        proj = EntityProjection(
            projection_id=uuid4(),
            entity_id=entity.entity_id,
            model_id=tmpl.model_id,
            template_id=tmpl.template_id,
            projection_code=f"page_{entity.entity_code}",
            projection_name=entity.entity_code,
            confidence=1.0,
            version_id=1,
        )
        db.add(proj)
        await db.flush()

    # Get or create current state
    result = await db.execute(
        select(ProjectionState)
        .where(ProjectionState.projection_id == proj.projection_id, ProjectionState.is_current == True)
        .limit(1)
    )
    state = result.scalar_one_or_none()

    state_data = {
        "content": data.get("content", {}),
        "template_name": data.get("template_name", "default"),
        "meta_title": data.get("meta_title", ""),
        "meta_description": data.get("meta_description", ""),
        "is_published": data.get("is_published", False),
        "sort_order": data.get("sort_order", 0),
    }

    state_hash = hashlib.sha256(
        json.dumps(state_data, sort_keys=True, default=str).encode()
    ).hexdigest()

    if state:
        state.state_data = state_data
        state.state_hash = state_hash
        state.version_id = (state.version_id or 1) + 1
    else:
        state = ProjectionState(
            projection_id=proj.projection_id,
            state_data=state_data,
            state_hash=state_hash,
            is_current=True,
            version_id=1,
        )
        db.add(state)

    # Update label
    label = await _get_primary_label(db, entity.entity_id)
    if label:
        label.label = data.get("title", "")
        label.description = data.get("meta_description", "")
        label.version_id = (label.version_id or 1) + 1
    else:
        label = EntityLabel(
            entity_id=entity.entity_id,
            language_id=lang_id,
            label=data.get("title", ""),
            description=data.get("meta_description", ""),
            is_primary=True,
            owner_id=entity.owner_id,
            version_id=1,
        )
        db.add(label)


@router.get("/", response_class=HTMLResponse)
async def list_pages(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """List all page entities."""
    kind = await _get_page_kind(db)
    lang = getattr(request.state, "lang", "ru")

    # Get language_id for current lang
    lang_result = await db.execute(select(Language).where(Language.code == lang))
    lang_obj = lang_result.scalar_one_or_none()
    lang_id = lang_obj.language_id if lang_obj else None

    # Get Russian language_id as fallback
    ru_result = await db.execute(select(Language).where(Language.code == "ru"))
    ru_lang = ru_result.scalar_one_or_none()
    ru_lang_id = ru_lang.language_id if ru_lang else None

    # Build COALESCE-like priority: current lang first, then ru, then any
    from sqlalchemy import case
    label_priority = case(
        (EntityLabel.language_id == lang_id, 0),
        (EntityLabel.language_id == ru_lang_id, 1),
        else_=2,
    )

    # Subquery: for each entity, get the best label per priority
    best_label_sq = (
        select(
            EntityLabel.entity_id,
            EntityLabel.label,
            EntityLabel.language_id,
        )
        .where(
            EntityLabel.entity_id.in_(
                select(Entity.entity_id).where(Entity.kind_id == kind.kind_id)
            )
        )
        .order_by(
            EntityLabel.entity_id,
            label_priority,
        )
        .distinct(EntityLabel.entity_id)
        .subquery()
    )

    result = await db.execute(
        select(Entity, best_label_sq.c.label, best_label_sq.c.language_id)
        .join(best_label_sq, best_label_sq.c.entity_id == Entity.entity_id)
        .where(
            Entity.kind_id == kind.kind_id,
            Entity.status.in_(["active", "deprecated"]),
        )
        .order_by(Entity.created_at.desc())
    )
    rows = result.unique().all()

    pages = []
    for entity, label_text, label_lang_id in rows:
        data = await _load_page_data(db, entity)
        pages.append({
            "page_id": entity.entity_id,
            "page_code": entity.entity_code,
            "title": label_text or entity.entity_code,
            "template_name": data.get("template_name", "default"),
            "is_published": data.get("is_published", False),
            "status": entity.status,
        })

    return templates.TemplateResponse("admin/pages.html", {
        "request": request,
        "user": user,
        "pages": pages,
    })


@router.get("/new", response_class=HTMLResponse)
async def new_page(
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """New page form."""
    return templates.TemplateResponse("admin/page_edit.html", {
        "request": request,
        "user": user,
        "page": None,
    })


@router.post("/create")
async def create_page(
    request: Request,
    page_code: str = Form(...),
    title: str = Form(...),
    is_published: bool = Form(False),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Create a new page entity."""
    kind = await _get_page_kind(db)

    # Check for duplicate page_code
    result = await db.execute(
        select(Entity).where(
            Entity.kind_id == kind.kind_id,
            Entity.entity_code == page_code,
        )
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail=f"Page with code '{page_code}' already exists.")

    entity = Entity(
        entity_id=uuid4(),
        entity_code=page_code,
        kind_id=kind.kind_id,
        status="deprecated" if not is_published else "active",
        owner_id=user.user_id,
        version_id=1,
    )
    db.add(entity)
    await db.flush()

    await _save_page_data(db, entity, {
        "title": title,
        "is_published": is_published,
        "content": {},
    })

    await db.commit()
    return RedirectResponse(url=f"/admin/pages/{entity.entity_id}/edit", status_code=303)


@router.get("/{page_id}/edit", response_class=HTMLResponse)
async def edit_page(
    page_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Edit page form."""
    result = await db.execute(
        select(Entity).where(Entity.entity_id == UUID(page_id))
    )
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404)

    label = await _get_primary_label(db, entity.entity_id)
    data = await _load_page_data(db, entity)

    page = {
        "page_id": entity.entity_id,
        "page_code": entity.entity_code,
        "title": label.label if label else "",
        "template_name": data.get("template_name", "default"),
        "content": data.get("content", {}),
        "meta_title": data.get("meta_title", ""),
        "meta_description": data.get("meta_description", ""),
        "is_published": data.get("is_published", False),
        "sort_order": data.get("sort_order", 0),
    }

    return templates.TemplateResponse("admin/page_edit.html", {
        "request": request,
        "user": user,
        "page": page,
    })


@router.post("/{page_id}/update")
async def update_page(
    page_id: str,
    request: Request,
    page_code: str = Form(...),
    title: str = Form(...),
    content: str = Form("{}"),
    is_published: bool = Form(False),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Update page entity."""
    result = await db.execute(
        select(Entity).where(Entity.entity_id == UUID(page_id))
    )
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404)

    # Update entity code
    entity.entity_code = page_code
    entity.status = "active" if is_published else "deprecated"
    entity.updated_at = datetime.now(timezone.utc)
    entity.version_id = (entity.version_id or 1) + 1

    # Parse content JSON
    try:
        content_data = json.loads(content) if isinstance(content, str) else content
    except json.JSONDecodeError:
        content_data = {}

    await _save_page_data(db, entity, {
        "title": title,
        "content": content_data,
        "is_published": is_published,
    })

    await db.commit()
    return RedirectResponse(url="/admin/pages/", status_code=303)


@router.post("/{page_id}/delete")
async def delete_page(
    page_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_admin),
):
    """Delete page entity (soft delete — set status to 'deleted')."""
    result = await db.execute(
        select(Entity).where(Entity.entity_id == UUID(page_id))
    )
    entity = result.scalar_one_or_none()
    if entity:
        entity.status = "deleted"
        entity.updated_at = datetime.now(timezone.utc)
        entity.version_id = (entity.version_id or 1) + 1
        await db.commit()

    return RedirectResponse(url="/admin/pages/", status_code=303)
