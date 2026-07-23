"""
Relation Service — business logic for semantic relation operations.
"""
import logging
from typing import Optional, List, Dict
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.relations import SemanticRelation, RelationType
from app.models.entities import Entity, EntityLabel
from app.models.projections import EntityProjection

logger = logging.getLogger(__name__)


class RelationService:
    """Service for semantic relation operations."""
    
    @staticmethod
    async def get_entity_relations(
        db: AsyncSession,
        entity_id: UUID,
        relation_type_code: Optional[str] = None,
    ) -> Dict:
        """Get all relations for an entity (outgoing and incoming)."""
        # Get all projections for this entity
        proj_result = await db.execute(
            select(EntityProjection.projection_id).where(
                EntityProjection.entity_id == entity_id
            )
        )
        projection_ids = [row[0] for row in proj_result]
        
        if not projection_ids:
            return {"outgoing": [], "incoming": []}
        
        # Get outgoing relations
        outgoing_query = (
            select(SemanticRelation, RelationType, Entity, EntityLabel)
            .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
            .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.target_projection_id)
            .join(Entity, Entity.entity_id == EntityProjection.entity_id)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .where(
                SemanticRelation.source_projection_id.in_(projection_ids),
                EntityLabel.is_primary == True
            )
        )
        
        if relation_type_code:
            outgoing_query = outgoing_query.where(RelationType.relation_code == relation_type_code)
        
        outgoing_result = await db.execute(outgoing_query)
        outgoing = [
            {
                "relation": r,
                "type": t,
                "entity": e,
                "label": l,
            }
            for r, t, e, l in outgoing_result.unique()
        ]
        
        # Get incoming relations
        incoming_query = (
            select(SemanticRelation, RelationType, Entity, EntityLabel)
            .join(RelationType, RelationType.relation_type_id == SemanticRelation.relation_type_id)
            .join(EntityProjection, EntityProjection.projection_id == SemanticRelation.source_projection_id)
            .join(Entity, Entity.entity_id == EntityProjection.entity_id)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .where(
                SemanticRelation.target_projection_id.in_(projection_ids),
                EntityLabel.is_primary == True
            )
        )
        
        if relation_type_code:
            incoming_query = incoming_query.where(RelationType.relation_code == relation_type_code)
        
        incoming_result = await db.execute(incoming_query)
        incoming = [
            {
                "relation": r,
                "type": t,
                "entity": e,
                "label": l,
            }
            for r, t, e, l in incoming_result.unique()
        ]
        
        return {
            "outgoing": outgoing,
            "incoming": incoming,
        }
    
    @staticmethod
    async def create_relation(
        db: AsyncSession,
        source_entity_id: UUID,
        target_entity_id: UUID,
        relation_code: str,
    ) -> Dict:
        """Create a semantic relation between two entities."""
        # Get relation type
        rel_type_result = await db.execute(
            select(RelationType).where(RelationType.relation_code == relation_code)
        )
        rel_type = rel_type_result.scalar_one_or_none()
        if not rel_type:
            raise ValueError(f"Relation type '{relation_code}' not found")
        
        # Get source projection
        source_proj_result = await db.execute(
            select(EntityProjection).where(EntityProjection.entity_id == source_entity_id).limit(1)
        )
        source_proj = source_proj_result.scalar_one_or_none()
        if not source_proj:
            raise ValueError("Source entity must have at least one projection")
        
        # Get target projection
        target_proj_result = await db.execute(
            select(EntityProjection).where(EntityProjection.entity_id == target_entity_id).limit(1)
        )
        target_proj = target_proj_result.scalar_one_or_none()
        if not target_proj:
            raise ValueError("Target entity must have at least one projection")
        
        # Create relation
        relation = SemanticRelation(
            relation_type_id=rel_type.relation_type_id,
            source_projection_id=source_proj.projection_id,
            target_projection_id=target_proj.projection_id,
        )
        db.add(relation)
        await db.flush()
        
        return {"relation": relation, "type": rel_type}
    
    @staticmethod
    async def delete_relation(db: AsyncSession, relation_id: UUID) -> bool:
        """Delete a semantic relation."""
        result = await db.execute(
            select(SemanticRelation).where(SemanticRelation.relation_id == relation_id)
        )
        relation = result.scalar_one_or_none()
        if not relation:
            return False
        
        await db.delete(relation)
        await db.flush()
        
        return True
    
    @staticmethod
    async def list_relation_types(db: AsyncSession) -> List[Dict]:
        """List all relation types."""
        result = await db.execute(
            select(RelationType).order_by(RelationType.relation_name)
        )
        
        return [
            {
                "type": rt,
                "code": rt.relation_code,
                "name": rt.relation_name,
            }
            for rt in result.scalars().all()
        ]
