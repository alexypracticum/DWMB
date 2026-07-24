"""
API v1 Relations endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from collections import defaultdict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.users import UserAccount
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.relations import SemanticRelation, RelationType
from app.models.projections import EntityProjection
from app.services.auth import get_current_user
from app.services.relation_service import RelationService

router = APIRouter()


class CreateRelationRequest(BaseModel):
    """Запрос на создание связи между сущностями."""
    source_entity_id: str
    target_entity_id: str
    relation_code: str


class RelationTypeResponse(BaseModel):
    """Модель типа связи."""
    type_id: str
    code: str
    name: str


@router.get("/types", response_model=List[RelationTypeResponse], summary="Типы связей", tags=["relations"])
async def list_relation_types(
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Получить список всех доступных типов семантических связей."""
    types = await RelationService.list_relation_types(db)

    return [
        RelationTypeResponse(
            type_id=str(t["type"].relation_type_id),
            code=t["code"],
            name=t["name"],
        )
        for t in types
    ]


@router.get("/graph/{entity_id}", summary="Граф связей сущности", tags=["relations"])
async def get_entity_graph(
    entity_id: str,
    depth: int = Query(1, ge=1, le=2, description="Глубина обхода (1-2 уровня)"),
    limit: int = Query(50, ge=10, le=200, description="Максимум узлов"),
    db: AsyncSession = Depends(get_db),
):
    """Получить данные графа (узлы + рёбра) для сущности и её соседей.
    Используется D3.js force-directed графом на странице сущности."""
    eid = UUID(entity_id)

    # 1. Get center entity
    entity_result = await db.execute(
        select(Entity, EntityKind)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(Entity.entity_id == eid)
    )
    entity_row = entity_result.first()
    if not entity_row:
        raise HTTPException(status_code=404, detail="Entity not found")

    entity, kind = entity_row

    # 2. Get center entity label
    label_result = await db.execute(
        select(EntityLabel)
        .where(EntityLabel.entity_id == eid, EntityLabel.is_primary == True)
        .limit(1)
    )
    center_label = label_result.scalar_one_or_none()
    center_label_text = center_label.label if center_label else entity.entity_code

    # 3. Get kind label for center
    kind_label_result = await db.execute(
        select(EntityKindLabel.label)
        .where(EntityKindLabel.kind_id == kind.kind_id)
        .limit(1)
    )
    center_kind_label = kind_label_result.scalar_one_or_none() or kind.kind_code

    # 4. Get all projections for center entity
    proj_result = await db.execute(
        select(EntityProjection.projection_id)
        .where(EntityProjection.entity_id == eid)
    )
    projection_ids = [row[0] for row in proj_result]

    if not projection_ids:
        return {"nodes": [], "edges": [], "relation_types": []}

    # 5. Get outgoing relations
    outgoing_result = await db.execute(
        select(SemanticRelation, RelationType, Entity, EntityLabel, EntityKind, EntityKindLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .join(EntityKindLabel, EntityKindLabel.kind_id == EntityKind.kind_id, isouter=True)
        .where(
            SemanticRelation.source_projection_id.in_(projection_ids),
            EntityLabel.is_primary == True,
        )
    )

    # 6. Get incoming relations
    incoming_result = await db.execute(
        select(SemanticRelation, RelationType, Entity, EntityLabel, EntityKind, EntityKindLabel)
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.source_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .join(EntityKindLabel, EntityKindLabel.kind_id == EntityKind.kind_id, isouter=True)
        .where(
            SemanticRelation.target_projection_id.in_(projection_ids),
            EntityLabel.is_primary == True,
        )
    )

    # 7. Build nodes and edges
    nodes_map = {}
    edges = []
    rt_counts = defaultdict(int)

    # Add center node
    nodes_map[str(eid)] = {
        "id": str(eid),
        "code": entity.entity_code,
        "label": center_label_text,
        "kind": kind.kind_code,
        "kind_label": center_kind_label,
        "image_url": entity.image_url or "",
        "is_center": True,
    }

    def _add_related(row):
        rel, rtype, ent, lbl, ek, ekl = row
        eid_str = str(ent.entity_id)
        rt_code = rtype.relation_code
        rt_counts[rt_code] += 1

        if eid_str not in nodes_map:
            nodes_map[eid_str] = {
                "id": eid_str,
                "code": ent.entity_code,
                "label": lbl.label,
                "kind": ek.kind_code,
                "kind_label": ekl.label if ekl else ek.kind_code,
                "image_url": ent.image_url or "",
                "is_center": False,
            }

        edges.append({
            "source": str(rel.source_projection_id),
            "target": str(rel.target_projection_id),
            "relation_type": rt_code,
            "relation_name": rtype.relation_name,
            "weight": float(rel.weight) if rel.weight else 1.0,
        })

    for row in outgoing_result.unique():
        _add_related(row)
    for row in incoming_result.unique():
        _add_related(row)

    # 8. Map projection IDs to entity IDs for edges
    proj_to_entity = {}
    all_entity_ids = list(nodes_map.keys())
    if all_entity_ids:
        proj_map_result = await db.execute(
            select(EntityProjection.projection_id, EntityProjection.entity_id)
            .where(EntityProjection.entity_id.in_([UUID(x) for x in all_entity_ids]))
        )
        for pid, eid_val in proj_map_result:
            proj_to_entity[str(pid)] = str(eid_val)

    # Rewrite edges to use entity IDs
    final_edges = []
    seen_edges = set()
    for edge in edges:
        src = proj_to_entity.get(edge["source"], edge["source"])
        tgt = proj_to_entity.get(edge["target"], edge["target"])
        edge_key = (src, tgt, edge["relation_type"])
        if src != tgt and edge_key not in seen_edges:
            seen_edges.add(edge_key)
            final_edges.append({
                "source": src,
                "target": tgt,
                "relation_type": edge["relation_type"],
                "relation_name": edge["relation_name"],
                "weight": edge["weight"],
            })

    # 9. Build relation_types summary
    relation_types = [
        {"code": code, "name": code, "count": count}
        for code, count in sorted(rt_counts.items(), key=lambda x: -x[1])
    ]

    # Get actual relation names
    if relation_types:
        rt_result = await db.execute(
            select(RelationType.relation_code, RelationType.relation_name)
        )
        rt_names = {row[0]: row[1] for row in rt_result}
        for rt in relation_types:
            rt["name"] = rt_names.get(rt["code"], rt["code"])

    nodes = list(nodes_map.values())[:limit]

    return {
        "nodes": nodes,
        "edges": final_edges,
        "relation_types": relation_types,
    }


@router.get("/entity/{entity_id}", summary="Связи сущности", tags=["relations"])
async def get_entity_relations(
    entity_id: str,
    relation_type: Optional[str] = Query(None, description="Фильтр по коду типа связи"),
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Получить все входящие и исходящие связи для сущности."""
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


@router.post("/", status_code=201, summary="Создать связь", tags=["relations"])
async def create_relation(
    request: CreateRelationRequest,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Создать семантическую связь между двумя сущностями."""
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


@router.delete("/{relation_id}", summary="Удалить связь", tags=["relations"])
async def delete_relation(
    relation_id: str,
    db=Depends(get_db),
    user: UserAccount = Depends(get_current_user),
):
    """Удалить семантическую связь по UUID."""
    result = await RelationService.delete_relation(db, UUID(relation_id))
    if not result:
        raise HTTPException(status_code=404, detail="Relation not found")

    return {"success": True, "message": "Relation deleted"}
