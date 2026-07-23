"""
API v1 Search endpoints.
"""
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional, List

from app.database import get_db
from app.models.users import UserAccount
from app.services.auth import get_current_user
from app.services.entity_service import EntityService

router = APIRouter()


class SearchResult(BaseModel):
    entity_id: str
    entity_code: str
    kind_code: str
    kind_label: str
    label: str


class SearchResponse(BaseModel):
    results: List[SearchResult]
    total: int
    query: str


@router.get("/", response_model=SearchResponse)
async def search_entities(
    q: str = Query(..., min_length=1),
    kind: Optional[str] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    lang: str = Query("ru"),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Search entities by name."""
    results = await EntityService.search_entities(
        db, query=q, kind=kind, limit=limit, lang=lang
    )
    
    return SearchResponse(
        results=[
            SearchResult(
                entity_id=str(item["entity"].entity_id),
                entity_code=item["entity"].entity_code,
                kind_code=item["kind"].kind_code,
                kind_label=item["kind_label"],
                label=item["label"].label,
            )
            for item in results
        ],
        total=len(results),
        query=q,
    )
