"""GraphQL mutation resolvers."""
import strawberry
from app.config import get_settings
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import app.models.languages
from typing import Optional, List
from uuid import UUID
from sqlalchemy import select, func
import json

from app.database import async_session
from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import OntologyModel, ProjectionState, EntityProjection
from app.models.relations import SemanticRelation, RelationType
from app.models.users import UserAccount
from app.services.auth import get_password_hash

from .types import (
    Entity as EntityType,
    EntityKind as EntityKindType,
    EntityLabel as EntityLabelType,
    Stats,
)


# ─── Input Types ──────────────────────────────────────────────

@strawberry.input
class CreateEntityInput:
    entity_code: str
    kind_code: str
    label_ru: str
    label_en: Optional[str] = None
    description: Optional[str] = None


@strawberry.input
class UpdateEntityInput:
    entity_id: str
    entity_code: Optional[str] = None
    kind_code: Optional[str] = None
    label_ru: Optional[str] = None
    label_en: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None


@strawberry.input
class CreateKindInput:
    kind_code: str
    description: Optional[str] = None
    is_abstract: bool = False
    sort_order: int = 0
    parent_kind_code: Optional[str] = None
    label_ru: Optional[str] = None
    label_en: Optional[str] = None


@strawberry.input
class CreateRelationInput:
    source_entity_id: str
    target_entity_id: str
    relation_code: str


# ─── Helper Functions ─────────────────────────────────────────

# Create sync engine for mutations
settings = get_settings()
sync_url = settings.DATABASE_URL.replace("+asyncpg", "")
_sync_engine = create_engine(sync_url, echo=False)
_sync_session_maker = sessionmaker(bind=_sync_engine)


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


# ─── Mutations ────────────────────────────────────────────────

@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_entity(self, input: CreateEntityInput) -> EntityType:
        """Create a new entity."""
        session = _sync_session_maker()
        try:
            # Get kind
            kind_result = session.execute(
                select(EntityKind).where(EntityKind.kind_code == input.kind_code)
            )
            kind = kind_result.scalar_one_or_none()
            if not kind:
                raise ValueError(f"Kind '{input.kind_code}' not found")
            
            # Create entity
            entity = Entity(
                entity_code=input.entity_code,
                kind_id=kind.kind_id,
                status="active",
                version_id=1,
            )
            session.add(entity)
            session.flush()
            
            # Get language IDs
            ru_lang_result = session.execute(
                select(app.models.languages.Language.language_id).where(app.models.languages.Language.code == "ru")
            )
            ru_lang_id = ru_lang_result.scalar_one_or_none()
            
            en_lang_result = session.execute(
                select(app.models.languages.Language.language_id).where(app.models.languages.Language.code == "en")
            )
            en_lang_id = en_lang_result.scalar_one_or_none()
            
            # Create Russian label
            ru_label = EntityLabel(
                entity_id=entity.entity_id,
                language_id=ru_lang_id,
                label=input.label_ru,
                description=input.description,
                is_primary=True,
                version_id=1,
            )
            session.add(ru_label)
            
            # Create English label if provided
            if input.label_en and en_lang_id:
                en_label = EntityLabel(
                    entity_id=entity.entity_id,
                    language_id=en_lang_id,
                    label=input.label_en,
                    description=input.description,
                    is_primary=False,
                    version_id=1,
                )
                session.add(en_label)
            
            session.commit()
            
            # Reload with relationships
            labels_result = session.execute(
                select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id)
            )
            labels = labels_result.scalars().all()
            
            return convert_entity(entity, labels, kind)
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    @strawberry.mutation
    async def update_entity(self, input: UpdateEntityInput) -> Optional[EntityType]:
        """Update an existing entity."""
        session = _sync_session_maker()
        try:
            # Get entity
            entity_result = session.execute(
                select(Entity).where(Entity.entity_id == UUID(input.entity_id))
            )
            entity = entity_result.scalar_one_or_none()
            if not entity:
                return None
            
            # Update entity fields
            if input.entity_code is not None:
                entity.entity_code = input.entity_code
            
            if input.kind_code is not None:
                kind_result = session.execute(
                    select(EntityKind).where(EntityKind.kind_code == input.kind_code)
                )
                kind = kind_result.scalar_one_or_none()
                if kind:
                    entity.kind_id = kind.kind_id
            
            if input.status is not None:
                entity.status = input.status
            
            session.flush()
            
            # Update labels
            if input.label_ru is not None:
                ru_lang_result = session.execute(
                    select(app.models.languages.Language.language_id).where(app.models.languages.Language.code == "ru")
                )
                ru_lang_id = ru_lang_result.scalar_one_or_none()
                
                label_result = session.execute(
                    select(EntityLabel).where(
                        EntityLabel.entity_id == entity.entity_id,
                        EntityLabel.language_id == ru_lang_id
                    )
                )
                label = label_result.scalar_one_or_none()
                if label:
                    label.label = input.label_ru
                else:
                    label = EntityLabel(
                        entity_id=entity.entity_id,
                        language_id=ru_lang_id,
                        label=input.label_ru,
                        is_primary=True,
                        version_id=1,
                    )
                    session.add(label)
            
            if input.label_en is not None:
                en_lang_result = session.execute(
                    select(app.models.languages.Language.language_id).where(app.models.languages.Language.code == "en")
                )
                en_lang_id = en_lang_result.scalar_one_or_none()
                
                label_result = session.execute(
                    select(EntityLabel).where(
                        EntityLabel.entity_id == entity.entity_id,
                        EntityLabel.language_id == en_lang_id
                    )
                )
                label = label_result.scalar_one_or_none()
                if label:
                    label.label = input.label_en
                else:
                    label = EntityLabel(
                        entity_id=entity.entity_id,
                        language_id=en_lang_id,
                        label=input.label_en,
                        is_primary=False,
                        version_id=1,
                    )
                    session.add(label)
            
            session.commit()
            
            # Reload with relationships
            kind_result = session.execute(
                select(EntityKind).where(EntityKind.kind_id == entity.kind_id)
            )
            kind = kind_result.scalar_one_or_none()
            
            labels_result = session.execute(
                select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id)
            )
            labels = labels_result.scalars().all()
            
            return convert_entity(entity, labels, kind)
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    @strawberry.mutation
    async def delete_entity(self, entity_id: str) -> bool:
        """Soft delete an entity (set status to 'deleted')."""
        session = _sync_session_maker()
        try:
            entity_result = session.execute(
                select(Entity).where(Entity.entity_id == UUID(entity_id))
            )
            entity = entity_result.scalar_one_or_none()
            if not entity:
                return False
            
            entity.status = "deleted"
            session.commit()
            return True
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    @strawberry.mutation
    async def create_kind(self, input: CreateKindInput) -> EntityKindType:
        """Create a new entity kind."""
        session = _sync_session_maker()
        try:
            # Get parent kind if specified
            parent_kind_id = None
            if input.parent_kind_code:
                parent_result = session.execute(
                    select(EntityKind).where(EntityKind.kind_code == input.parent_kind_code)
                )
                parent = parent_result.scalar_one_or_none()
                if parent:
                    parent_kind_id = parent.kind_id
            
            # Create kind
            kind = EntityKind(
                kind_code=input.kind_code,
                description=input.description,
                is_abstract=input.is_abstract,
                sort_order=input.sort_order,
                parent_kind_id=parent_kind_id,
                version_id=1,
            )
            session.add(kind)
            session.flush()
            
            # Get language IDs
            ru_lang_result = session.execute(
                select(app.models.languages.Language.language_id).where(app.models.languages.Language.code == "ru")
            )
            ru_lang_id = ru_lang_result.scalar_one_or_none()
            
            en_lang_result = session.execute(
                select(app.models.languages.Language.language_id).where(app.models.languages.Language.code == "en")
            )
            en_lang_id = en_lang_result.scalar_one_or_none()
            
            # Create Russian label
            if input.label_ru and ru_lang_id:
                ru_label = EntityKindLabel(
                    kind_id=kind.kind_id,
                    language_id=ru_lang_id,
                    label=input.label_ru,
                    version_id=1,
                )
                session.add(ru_label)
            
            # Create English label
            if input.label_en and en_lang_id:
                en_label = EntityKindLabel(
                    kind_id=kind.kind_id,
                    language_id=en_lang_id,
                    label=input.label_en,
                    version_id=1,
                )
                session.add(en_label)
            
            session.commit()
            
            # Get label for response
            label_result = session.execute(
                select(EntityKindLabel.label)
                .where(EntityKindLabel.kind_id == kind.kind_id)
                .limit(1)
            )
            label = label_result.scalar_one_or_none()
            
            return EntityKindType(
                kind_id=str(kind.kind_id),
                kind_code=kind.kind_code,
                description=kind.description,
                is_abstract=kind.is_abstract,
                sort_order=kind.sort_order,
                label=label or kind.kind_code,
            )
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    @strawberry.mutation
    async def create_relation(self, input: CreateRelationInput) -> bool:
        """Create a semantic relation between two entities."""
        session = _sync_session_maker()
        try:
            # Get source entity
            source_result = session.execute(
                select(Entity).where(Entity.entity_id == UUID(input.source_entity_id))
            )
            source = source_result.scalar_one_or_none()
            if not source:
                raise ValueError(f"Source entity not found")
            
            # Get target entity
            target_result = session.execute(
                select(Entity).where(Entity.entity_id == UUID(input.target_entity_id))
            )
            target = target_result.scalar_one_or_none()
            if not target:
                raise ValueError(f"Target entity not found")
            
            # Get relation type
            rel_type_result = session.execute(
                select(RelationType).where(RelationType.relation_code == input.relation_code)
            )
            rel_type = rel_type_result.scalar_one_or_none()
            if not rel_type:
                raise ValueError(f"Relation type '{input.relation_code}' not found")
            
            # Get source projection (first projection of source entity)
            source_proj_result = session.execute(
                select(EntityProjection).where(EntityProjection.entity_id == source.entity_id).limit(1)
            )
            source_proj = source_proj_result.scalar_one_or_none()
            
            # Get target projection (first projection of target entity)
            target_proj_result = session.execute(
                select(EntityProjection).where(EntityProjection.entity_id == target.entity_id).limit(1)
            )
            target_proj = target_proj_result.scalar_one_or_none()
            
            if not source_proj or not target_proj:
                raise ValueError("Both entities must have at least one projection")
            
            # Create relation
            relation = SemanticRelation(
                relation_type_id=rel_type.relation_type_id,
                source_projection_id=source_proj.projection_id,
                target_projection_id=target_proj.projection_id,
            )
            session.add(relation)
            session.commit()
            
            return True
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
