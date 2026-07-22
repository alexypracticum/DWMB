"""GraphQL query resolvers."""
import strawberry
from typing import Optional, List
from uuid import UUID
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import OntologyModel, OntologyTemplate, EntityProjection, ProjectionState
from app.models.relations import SemanticRelation, RelationType

from .types import (
    Entity as EntityType,
    EntityKind as EntityKindType,
    EntityLabel as EntityLabelType,
    OntologyModel as OntologyModelType,
    RelationType as RelationTypeType,
    PageInfo,
    EntityConnection,
    Stats,
)


def convert_entity(entity, labels, kind):
    """Convert Entity model to GraphQL type."""
    return EntityType(
        entity_id=str(entity.entity_id),
        entity_code=entity.entity_code,
        status=entity.status.value if hasattr(entity.status, 'value') else entity.status,
        kind=EntityKindType(
            kind_id=str(kind.kind_id),
            kind_code=kind.kind_code,
            description=kind.description,
            is_abstract=kind.is_abstract,
            sort_order=kind.sort_order,
        ) if kind else None,
        labels=[
            EntityLabelType(
                entity_label_id=label.entity_label_id,
                language=label.language.value if hasattr(label.language, 'value') else label.language,
                label=label.label,
                description=label.description,
                is_primary=label.is_primary,
            )
            for label in labels
        ],
        created_at=entity.created_at,
        updated_at=entity.updated_at,
    )


@strawberry.type
class Query:
    @strawberry.field
    async def entities(
        self,
        kind: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        per_page: int = 20,
    ) -> EntityConnection:
        """Get entities with filtering and pagination."""
        async with async_session() as session:
            offset = (page - 1) * per_page
            
            query = (
                select(Entity, EntityLabel, EntityKind)
                .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
                .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
                .where(Entity.status == "active", EntityLabel.is_primary == True)
            )
            
            count_query = (
                select(func.count(Entity.entity_id))
                .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
                .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
                .where(Entity.status == "active", EntityLabel.is_primary == True)
            )
            
            if kind:
                query = query.where(EntityKind.kind_code == kind)
                count_query = count_query.where(EntityKind.kind_code == kind)
            
            if search:
                search_pattern = f"%{search}%"
                query = query.where(EntityLabel.label.ilike(search_pattern))
                count_query = count_query.where(EntityLabel.label.ilike(search_pattern))
            
            total_result = await session.execute(count_query)
            total = total_result.scalar()
            total_pages = max(1, (total + per_page - 1) // per_page)
            
            result = await session.execute(
                query.order_by(EntityLabel.label)
                .offset(offset)
                .limit(per_page)
            )
            
            items = []
            for entity, label, ek in result.unique():
                labels_result = await session.execute(
                    select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id)
                )
                labels = labels_result.scalars().all()
                items.append(convert_entity(entity, labels, ek))
            
            return EntityConnection(
                items=items,
                page_info=PageInfo(
                    total=total,
                    page=page,
                    per_page=per_page,
                    total_pages=total_pages,
                ),
            )
    
    @strawberry.field
    async def entity(self, entity_id: str) -> Optional[EntityType]:
        """Get a single entity by ID."""
        async with async_session() as session:
            result = await session.execute(
                select(Entity, EntityLabel, EntityKind)
                .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
                .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
                .where(Entity.entity_id == UUID(entity_id))
            )
            
            row = result.first()
            if not row:
                return None
            
            entity, label, kind = row
            labels_result = await session.execute(
                select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id)
            )
            labels = labels_result.scalars().all()
            
            return convert_entity(entity, labels, kind)
    
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
    
    @strawberry.field
    async def search(
        self,
        query: str,
        kind: Optional[str] = None,
        limit: int = 20,
    ) -> List[EntityType]:
        """Search entities by name."""
        async with async_session() as session:
            search_pattern = f"%{query}%"
            
            q = (
                select(Entity, EntityLabel, EntityKind)
                .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
                .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
                .where(
                    Entity.status == "active",
                    EntityLabel.is_primary == True,
                    EntityLabel.label.ilike(search_pattern),
                )
                .limit(limit)
            )
            
            if kind:
                q = q.where(EntityKind.kind_code == kind)
            
            result = await session.execute(q)
            
            items = []
            for entity, label, ek in result.unique():
                labels_result = await session.execute(
                    select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id)
                )
                labels = labels_result.scalars().all()
                items.append(convert_entity(entity, labels, ek))
            
            return items
    
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
