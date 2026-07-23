"""
API v1 Relations endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID

from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import get_current_user
from app.services.relation_service import RelationService

router = APIRouter()


class CreateRelationRequest(BaseModel):
    source_entity_id: str
    target_entity_id: str
    relation_code: str


class RelationTypeResponse(BaseModel):
    type_id: str
    code: str
    name: str


@router.get("/types", response_model=List[RelationTypeResponse])
async def list_relation_types(
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """List all relation types."""
    types = await RelationService.list_relation_types(db)
    
    return [
        RelationTypeResponse(
            type_id=str(t["type"].relation_type_id),
            code=t["code"],
            name=t["name"],
        )
        for t in types
    ]


@router.get("/entity/{entity_id}")
async def get_entity_relations(
    entity_id: str,
    relation_type: Optional[str] = Query(None),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Get all relations for an entity."""
    result = await RelationService.get_entity_relations(
        db, UUID(entity_id), relation_type_code=relation_type
    )
    
    return {
        "outgoing": [
            {
                "relation_id": str(r["relation"].relation_id),
                "type_code": r["type"].relation_code,
                "type_name": r["type"].relation_name,
                "entity_id": str(r["entity"].entity_id),
                "entity_code": r["entity"].entity_code,
                "label": r["label"].label,
            }
            for r in result["outgoing"]
        ],
        "incoming": [
            {
                "relation_id": str(r["relation"].relation_id),
                "type_code": r["type"].relation_code,
                "type_name": r["type"].relation_name,
                "entity_id": str(r["entity"].entity_id),
                "entity_code": r["entity"].entity_code,
                "label": r["label"].label,
            }
            for r in result["incoming"]
        ],
    }


@router.post("/", status_code=201)
async def create_relation(
    request: CreateRelationRequest,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Create a semantic relation between two entities."""
    try:
        result = await RelationService.create_relation(
            db,
            source_entity_id=UUID(request.source_entity_id),
            target_entity_id=UUID(request.target_entity_id),
            relation_code=request.relation_code,
        )
        
        return {
            "success": True,
            "relation_id": str(result["relation"].relation_id),
            "type_code": result["type"].relation_code,
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{relation_id}")
async def delete_relation(
    relation_id: str,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Delete a semantic relation."""
    result = await RelationService.delete_relation(db, UUID(relation_id))
    if not result:
        raise HTTPException(status_code=404, detail="Relation not found")
    
    return {"success": True, "message": "Relation deleted"}
