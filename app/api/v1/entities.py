"""
API v1 Entities endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID

from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import get_current_user
from app.services.entity_service import EntityService

router = APIRouter()


# ─── Request/Response Models ──────────────────────────────────

class CreateEntityRequest(BaseModel):
    entity_code: str
    kind_code: str
    label_ru: str
    label_en: Optional[str] = None
    description: Optional[str] = None


class UpdateEntityRequest(BaseModel):
    entity_code: Optional[str] = None
    kind_code: Optional[str] = None
    label_ru: Optional[str] = None
    label_en: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None


class EntityResponse(BaseModel):
    entity_id: str
    entity_code: str
    kind_code: str
    kind_label: str
    labels: List[dict]
    status: str


class EntityListResponse(BaseModel):
    items: List[EntityResponse]
    total: int
    page: int
    per_page: int
    total_pages: int


# ─── Endpoints ────────────────────────────────────────────────

@router.get("/", response_model=EntityListResponse)
async def list_entities(
    kind: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    lang: str = Query("ru"),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """List entities with filtering and pagination."""
    result = await EntityService.list_entities(
        db, kind=kind, search=search, page=page, per_page=per_page, lang=lang
    )
    
    items = []
    for item in result["items"]:
        items.append(EntityResponse(
            entity_id=str(item["entity"].entity_id),
            entity_code=item["entity"].entity_code,
            kind_code=item["kind"].kind_code,
            kind_label=item["kind_label"],
            labels=[{"label": l.label, "language": l.language.value if hasattr(l.language, 'value') else l.language} for l in item.get("labels", [])],
            status=item["entity"].status.value if hasattr(item["entity"].status, 'value') else item["entity"].status,
        ))
    
    return EntityListResponse(
        items=items,
        total=result["total"],
        page=result["page"],
        per_page=result["per_page"],
        total_pages=result["total_pages"],
    )


@router.get("/{entity_id}", response_model=EntityResponse)
async def get_entity(
    entity_id: str,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Get a single entity by ID."""
    result = await EntityService.get_entity(db, UUID(entity_id))
    if not result:
        raise HTTPException(status_code=404, detail="Entity not found")
    
    return EntityResponse(
        entity_id=str(result["entity"].entity_id),
        entity_code=result["entity"].entity_code,
        kind_code=result["kind"].kind_code,
        kind_label=result["label"].label if result["label"] else result["kind"].kind_code,
        labels=[{"label": l.label, "language": l.language.value if hasattr(l.language, 'value') else l.language} for l in result.get("labels", [])],
        status=result["entity"].status.value if hasattr(result["entity"].status, 'value') else result["entity"].status,
    )


@router.post("/", response_model=EntityResponse, status_code=201)
async def create_entity(
    request: CreateEntityRequest,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Create a new entity."""
    try:
        result = await EntityService.create_entity(
            db,
            entity_code=request.entity_code,
            kind_code=request.kind_code,
            label_ru=request.label_ru,
            label_en=request.label_en,
            description=request.description,
            owner_id=user.user_id,
        )
        
        # Reload with labels
        entity_data = await EntityService.get_entity(db, result["entity"].entity_id)
        
        return EntityResponse(
            entity_id=str(entity_data["entity"].entity_id),
            entity_code=entity_data["entity"].entity_code,
            kind_code=entity_data["kind"].kind_code,
            kind_label=entity_data["label"].label if entity_data["label"] else entity_data["kind"].kind_code,
            labels=[{"label": l.label, "language": l.language.value if hasattr(l.language, 'value') else l.language} for l in entity_data.get("labels", [])],
            status="active",
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/{entity_id}", response_model=EntityResponse)
async def update_entity(
    entity_id: str,
    request: UpdateEntityRequest,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Update an existing entity."""
    result = await EntityService.update_entity(
        db,
        entity_id=UUID(entity_id),
        entity_code=request.entity_code,
        kind_code=request.kind_code,
        label_ru=request.label_ru,
        label_en=request.label_en,
        description=request.description,
        status=request.status,
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Entity not found")
    
    return EntityResponse(
        entity_id=str(result["entity"].entity_id),
        entity_code=result["entity"].entity_code,
        kind_code=result["kind"].kind_code if result["kind"] else "unknown",
        kind_label="",
        labels=[{"label": l.label, "language": l.language.value if hasattr(l.language, 'value') else l.language} for l in result.get("labels", [])],
        status=result["entity"].status.value if hasattr(result["entity"].status, 'value') else result["entity"].status,
    )


@router.delete("/{entity_id}")
async def delete_entity(
    entity_id: str,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Delete an entity (soft delete)."""
    result = await EntityService.delete_entity(db, UUID(entity_id))
    if not result:
        raise HTTPException(status_code=404, detail="Entity not found")
    
    return {"success": True, "message": "Entity deleted"}
