"""GraphQL query resolvers."""
import strawberry
from typing import Optional, List
from sqlalchemy import select, func

from app.database import async_session
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import OntologyModel
from app.models.relations import SemanticRelation, RelationType

from .types import (
    EntityKind as EntityKindType,
    OntologyModel as OntologyModelType,
    RelationType as RelationTypeType,
    Stats,
)


@strawberry.type
class Query:
    @strawberry.field
    async def stats(self) -> Stats:
        """Get database statistics."""
        async with async_session() as session:
            entity_count_result = await session.execute(select(func.count(Entity.entity_id)))
            entity_count = entity_count_result.scalar()
            
            kind_count_result = await session.execute(
                select(func.count(EntityKind.kind_id)).where(EntityKind.is_abstract == False)
            )
            kind_count = kind_count_result.scalar()
            
            relation_count_result = await session.execute(select(func.count(SemanticRelation.relation_id)))
            relation_count = relation_count_result.scalar()
            
            model_count_result = await session.execute(select(func.count(OntologyModel.model_id)))
            model_count = model_count_result.scalar()
            
            return Stats(
                entity_count=entity_count or 0,
                kind_count=kind_count or 0,
                relation_count=relation_count or 0,
                model_count=model_count or 0,
            )
    
    @strawberry.field
    async def kinds(self) -> List[EntityKindType]:
        """Get all entity kinds."""
        async with async_session() as session:
            result = await session.execute(
                select(EntityKind)
                .where(EntityKind.is_abstract == False)
                .order_by(EntityKind.sort_order)
            )
            
            kinds = []
            for kind in result.scalars().all():
                label_result = await session.execute(
                    select(EntityKindLabel.label)
                    .where(EntityKindLabel.kind_id == kind.kind_id)
                    .limit(1)
                )
                label = label_result.scalar_one_or_none()
                
                kinds.append(EntityKindType(
                    kind_id=str(kind.kind_id),
                    kind_code=kind.kind_code,
                    description=kind.description,
                    is_abstract=kind.is_abstract,
                    sort_order=kind.sort_order,
                    label=label or kind.kind_code,
                ))
            
            return kinds
    
    @strawberry.field
    async def models(self) -> List[OntologyModelType]:
        """Get all ontology models."""
        async with async_session() as session:
            result = await session.execute(select(OntologyModel))
            return [
                OntologyModelType(
                    model_id=str(m.model_id),
                    model_code=m.model_code,
                    domain=m.domain,
                    description=m.description,
                )
                for m in result.scalars().all()
            ]
    
    @strawberry.field
    async def relation_types(self) -> List[RelationTypeType]:
        """Get all relation types."""
        async with async_session() as session:
            result = await session.execute(select(RelationType))
            return [
                RelationTypeType(
                    relation_type_id=str(rt.relation_type_id),
                    relation_code=rt.relation_code,
                    relation_name=rt.relation_name,
                    directionality=rt.directionality.value if hasattr(rt.directionality, 'value') else rt.directionality,
                )
                for rt in result.scalars().all()
            ]
