"""
Dynamic JSON editor for entity projection_state.
Generates visual forms from field_registry with drag-and-drop.
"""
from fastapi import APIRouter, Depends, Request, Query
from fastapi.responses import HTMLResponse
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.fields import FieldRegistry
from app.models.field_labels import FieldRegistryLabel
from app.services.auth import get_current_user

router = APIRouter(prefix="/api/editor", tags=["editor"])


@router.get("/fields")
async def get_fields_for_editor(
    category: str = None,
    db: AsyncSession = Depends(get_db),
):
    """Get field_registry entries for the visual editor."""
    query = select(FieldRegistry).where(FieldRegistry.is_active == True)
    if category:
        query = query.where(FieldRegistry.category == category)
    query = query.order_by(FieldRegistry.sort_order)
    
    result = await db.execute(query)
    fields = result.scalars().all()
    
    # Get Russian labels
    fields_data = []
    for f in fields:
        label_result = await db.execute(
            select(FieldRegistryLabel.label)
            .where(
                FieldRegistryLabel.field_id == f.field_id,
                FieldRegistryLabel.language == "ru"
            )
        )
        ru_label = label_result.scalar_one_or_none() or f.field_label
        
        fields_data.append({
            "field_id": str(f.field_id),
            "key": f.field_key,
            "label": ru_label,
            "type": f.field_type,
            "category": f.category,
            "default_value": f.default_value,
            "options": f.options if isinstance(f.options, list) else [],
        })
    
    return {"fields": fields_data}


@router.get("/categories")
async def get_categories(db: AsyncSession = Depends(get_db)):
    """Get unique field categories."""
    result = await db.execute(
        select(FieldRegistry.category).distinct().where(FieldRegistry.is_active == True)
    )
    categories = [row[0] for row in result]
    return {"categories": categories}


@router.get("/search")
async def api_search_entities(
    q: str = Query("", min_length=0),
    kind: str = Query(""),
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
):
    """Search entities by label for inline add popups."""
    if not q or len(q) < 1:
        return {"items": []}
    query = (
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, Entity.entity_id == EntityLabel.entity_id)
        .outerjoin(EntityKind, Entity.kind_id == EntityKind.kind_id)
        .where(EntityLabel.language == "ru", EntityLabel.label.ilike(f"%{q}%"))
    )
    if kind:
        query = query.where(EntityKind.kind_code == kind)
    query = query.order_by(EntityLabel.label).limit(limit)
    result = await db.execute(query)
    items = []
    for ent, label, kind_obj in result:
        items.append({
            "entity_id": str(ent.entity_id),
            "label": label.label or "",
            "kind": kind_obj.kind_code if kind_obj else "",
        })
    return {"items": items}
