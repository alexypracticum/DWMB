"""
API v1 Search endpoints.
"""
from uuid import UUID
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


class GraphSearchResult(BaseModel):
    entity_id: str
    entity_code: str
    kind_code: str
    kind_label: str
    label: str
    relation_code: str
    relation_name: str
    direction: str
    source_entity_id: Optional[str] = None
    source_label: Optional[str] = None


class GraphSearchResponse(BaseModel):
    results: List[GraphSearchResult]
    total: int
    query: str
    relation_types: List[dict]


@router.get("/", response_model=SearchResponse, summary="Поиск сущностей", tags=["search"])
async def search_entities(
    q: str = Query(..., min_length=1, description="Поисковый запрос"),
    kind: Optional[str] = Query(None, description="Фильтр по типу сущности"),
    limit: int = Query(20, ge=1, le=100, description="Максимум результатов"),
    lang: str = Query("ru", description="Язык меток"),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Полнотекстовый поиск сущностей по названию, описанию и коду."""
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


@router.get("/graph", response_model=GraphSearchResponse, summary="Поиск по графу связей", tags=["search"])
async def search_graph(
    q: str = Query(None, description="Текстовый запрос для поиска исходных сущностей"),
    entity_id: Optional[str] = Query(None, description="UUID исходной сущности для обхода связей"),
    relation_code: Optional[str] = Query(None, description="Фильтр по коду типа связи (acted_in, directed_by...)"),
    target_kind: Optional[str] = Query(None, description="Фильтр по типу связанной сущности (film, song...)"),
    limit: int = Query(50, ge=1, le=200, description="Максимум результатов"),
    lang: str = Query("ru", description="Язык меток"),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Поиск по графу связей: найти сущности через обход семантических связей.

    Два режима:
    1. По entity_id: найти все связанные сущности
    2. По тексту: найти сущности по запросу, затем их связи

    Примеры:
    - `?entity_id=...&relation_code=acted_in` — фильмы где снимался актёр
    - `?q=Nolan&target_kind=film` — все фильмы связанные с Ноланом
    - `?q=Queen&relation_code=performed_by` — песни исполненные Queen
    """
    from app.services.graph_search import search_by_relation, search_related_by_text, get_relation_types_for_entity

    if entity_id:
        # Mode 1: Traverse from specific entity
        results = await search_by_relation(
            db,
            entity_id=UUID(entity_id),
            relation_code=relation_code,
            target_kind=target_kind,
            limit=limit,
            lang=lang,
        )
        # Get available relation types for this entity
        relation_types = await get_relation_types_for_entity(db, UUID(entity_id))
    elif q:
        # Mode 2: Text search + relation traversal
        results = await search_related_by_text(
            db,
            query_text=q,
            relation_code=relation_code,
            target_kind=target_kind,
            limit=limit,
            lang=lang,
        )
        relation_types = []
    else:
        return GraphSearchResponse(results=[], total=0, query="", relation_types=[])

    return GraphSearchResponse(
        results=[
            GraphSearchResult(
                entity_id=str(r["entity"].entity_id),
                entity_code=r["entity"].entity_code,
                kind_code=r["kind"].kind_code,
                kind_label=r["kind_label"],
                label=r["label"].label,
                relation_code=r["relation_code"],
                relation_name=r["relation_name"],
                direction=r["direction"],
                source_entity_id=str(r["source_entity"].entity_id) if r.get("source_entity") else None,
                source_label=r["source_label"].label if r.get("source_label") else None,
            )
            for r in results
        ],
        total=len(results),
        query=q or "",
        relation_types=relation_types,
    )
