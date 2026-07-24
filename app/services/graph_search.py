"""
Graph-based search for DWMB.
Find entities by traversing semantic relations.
"""
import logging
from typing import Optional, List, Dict
from uuid import UUID

from sqlalchemy import select, func, or_, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.relations import SemanticRelation, RelationType
from app.models.projections import EntityProjection, ProjectionState
from app.services.language_service import get_kind_label, get_lang

logger = logging.getLogger(__name__)


async def search_by_relation(
    db: AsyncSession,
    entity_id: UUID,
    relation_code: Optional[str] = None,
    target_kind: Optional[str] = None,
    limit: int = 50,
    lang: str = "ru",
) -> List[Dict]:
    """Find entities connected to the given entity via relations.
    
    Args:
        entity_id: Source entity to search from
        relation_code: Filter by specific relation type (e.g., "acted_in", "directed_by")
        target_kind: Filter by target entity kind (e.g., "film", "song")
        limit: Max results
        lang: Language for labels
    
    Returns:
        List of dicts with entity, label, kind, relation info
    """
    # Get all projections for the source entity
    proj_result = await db.execute(
        select(EntityProjection.projection_id)
        .where(EntityProjection.entity_id == entity_id)
    )
    projection_ids = [row[0] for row in proj_result]
    if not projection_ids:
        return []

    # Build query for outgoing relations
    query = (
        select(
            SemanticRelation,
            RelationType,
            Entity,
            EntityLabel,
            EntityKind,
            EntityKindLabel,
        )
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .join(EntityKindLabel, EntityKindLabel.kind_id == EntityKind.kind_id, isouter=True)
        .where(
            SemanticRelation.source_projection_id.in_(projection_ids),
            EntityLabel.is_primary == True,
            Entity.status == "active",
        )
    )

    # Also get incoming relations
    incoming_query = (
        select(
            SemanticRelation,
            RelationType,
            Entity,
            EntityLabel,
            EntityKind,
            EntityKindLabel,
        )
        .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
        .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.source_projection_id)
        .join(Entity, Entity.entity_id == EntityProjection.entity_id)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .join(EntityKindLabel, EntityKindLabel.kind_id == EntityKind.kind_id, isouter=True)
        .where(
            SemanticRelation.target_projection_id.in_(projection_ids),
            EntityLabel.is_primary == True,
            Entity.status == "active",
        )
    )

    # Apply relation type filter
    if relation_code:
        query = query.where(RelationType.relation_code == relation_code)
        incoming_query = incoming_query.where(RelationType.relation_code == relation_code)

    # Apply target kind filter
    if target_kind:
        query = query.where(EntityKind.kind_code == target_kind)
        incoming_query = incoming_query.where(EntityKind.kind_code == target_kind)

    # Execute both queries
    outgoing_result = await db.execute(query.limit(limit))
    incoming_result = await db.execute(incoming_query.limit(limit))

    # Build results — deduplicate by entity_id
    seen = set()
    results = []

    for row in outgoing_result.unique():
        rel, rtype, ent, lbl, ek, ekl = row
        eid = ent.entity_id
        if eid in seen:
            continue
        seen.add(eid)

        results.append({
            "entity": ent,
            "label": lbl,
            "kind": ek,
            "kind_label": ekl.label if ekl else ek.kind_code,
            "relation_code": rtype.relation_code,
            "relation_name": rtype.relation_name,
            "direction": "outgoing",
            "distance": 1,
        })

    for row in incoming_result.unique():
        rel, rtype, ent, lbl, ek, ekl = row
        eid = ent.entity_id
        if eid in seen:
            continue
        seen.add(eid)

        results.append({
            "entity": ent,
            "label": lbl,
            "kind": ek,
            "kind_label": ekl.label if ekl else ek.kind_code,
            "relation_code": rtype.relation_code,
            "relation_name": rtype.relation_name,
            "direction": "incoming",
            "distance": 1,
        })

    return results[:limit]


async def search_related_by_text(
    db: AsyncSession,
    query_text: str,
    source_entity_id: Optional[UUID] = None,
    relation_code: Optional[str] = None,
    target_kind: Optional[str] = None,
    limit: int = 50,
    lang: str = "ru",
) -> List[Dict]:
    """Search entities that are related to matching entities.
    
    Two-step search:
    1. Find entities matching the text query
    2. For each, find related entities (optionally filtered by relation/kind)
    
    This enables queries like:
    - "Find all films related to Christopher Nolan" (text finds Nolan → relation finds films)
    - "Find all songs by Queen" (text finds Queen → relation finds songs)
    """
    search_pattern = f"%{query_text}%"
    ru_lang_id = await _get_lang_id(db, lang)

    # Step 1: Find matching entities
    match_query = (
        select(Entity, EntityLabel, EntityKind)
        .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
        .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
        .where(
            Entity.status == "active",
            EntityLabel.language_id == ru_lang_id,
            EntityLabel.is_primary == True,
            or_(
                EntityLabel.label.ilike(search_pattern),
                EntityLabel.description.ilike(search_pattern),
            ),
        )
    )

    if source_entity_id:
        match_query = match_query.where(Entity.entity_id == source_entity_id)

    if target_kind:
        match_query = match_query.where(EntityKind.kind_code == target_kind)

    match_result = await db.execute(match_query.limit(20))
    matching_entities = [(row[0], row[1], row[2]) for row in match_result.unique()]

    if not matching_entities:
        return []

    # Step 2: Find related entities for each match
    all_results = []
    seen = set()

    for entity, label, kind in matching_entities:
        related = await search_by_relation(
            db,
            entity_id=entity.entity_id,
            relation_code=relation_code,
            target_kind=target_kind,
            limit=limit,
            lang=lang,
        )

        for r in related:
            eid = r["entity"].entity_id
            if eid not in seen:
                seen.add(eid)
                r["source_entity"] = entity
                r["source_label"] = label
                r["distance"] = 1
                all_results.append(r)

    return all_results[:limit]


async def get_relation_types_for_entity(db: AsyncSession, entity_id: UUID) -> List[Dict]:
    """Get all relation types available for an entity (outgoing + incoming)."""
    proj_result = await db.execute(
        select(EntityProjection.projection_id)
        .where(EntityProjection.entity_id == entity_id)
    )
    projection_ids = [row[0] for row in proj_result]
    if not projection_ids:
        return []

    # Get outgoing relation types
    outgoing = await db.execute(
        select(RelationType.relation_code, RelationType.relation_name, func.count())
        .join(SemanticRelation, SemanticRelation.relation_type_id == RelationType.relation_type_id)
        .where(SemanticRelation.source_projection_id.in_(projection_ids))
        .group_by(RelationType.relation_code, RelationType.relation_name)
    )

    # Get incoming relation types
    incoming = await db.execute(
        select(RelationType.relation_code, RelationType.relation_name, func.count())
        .join(SemanticRelation, SemanticRelation.relation_type_id == RelationType.relation_type_id)
        .where(SemanticRelation.target_projection_id.in_(projection_ids))
        .group_by(RelationType.relation_code, RelationType.relation_name)
    )

    result = {}
    for code, name, count in outgoing:
        result[code] = {"code": code, "name": name, "outgoing": count, "incoming": 0}
    for code, name, count in incoming:
        if code in result:
            result[code]["incoming"] = count
        else:
            result[code] = {"code": code, "name": name, "outgoing": 0, "incoming": count}

    return sorted(result.values(), key=lambda x: -(x["outgoing"] + x["incoming"]))


async def _get_lang_id(db: AsyncSession, lang_code: str) -> UUID:
    """Get language ID by code."""
    from app.models.languages import Language
    result = await db.execute(
        select(Language.language_id).where(Language.code == lang_code).limit(1)
    )
    lang_id = result.scalar_one_or_none()
    if not lang_id:
        # Fallback to Russian
        result = await db.execute(
            select(Language.language_id).where(Language.code == "ru").limit(1)
        )
        lang_id = result.scalar_one_or_none()
    return lang_id
