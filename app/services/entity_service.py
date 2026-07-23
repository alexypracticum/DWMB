"""
Entity Service — business logic for entity operations.
Extracts logic from routes for better separation of concerns.
"""
import logging
import json
import hashlib
from typing import Optional, List, Dict, Tuple
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel
from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate
from app.models.users import UserAccount
from app.services.language_service import get_language_id, get_lang_ids, entity_label_filter

logger = logging.getLogger(__name__)


class EntityService:
    """Service for entity CRUD operations."""
    
    @staticmethod
    async def get_entity(db: AsyncSession, entity_id: UUID) -> Optional[Dict]:
        """Get entity with all related data."""
        result = await db.execute(
            select(Entity, EntityLabel, EntityKind)
            .join(EntityLabel, EntityLabel.entity_id == Entity.entity_id)
            .join(EntityKind, EntityKind.kind_id == Entity.kind_id)
            .where(Entity.entity_id == entity_id)
        )
        
        row = result.first()
        if not row:
            return None
        
        entity, label, kind = row
        
        # Get all labels
        labels_result = await db.execute(
            select(EntityLabel).where(EntityLabel.entity_id == entity_id)
        )
        labels = labels_result.scalars().all()
        
        return {
            "entity": entity,
            "label": label,
            "kind": kind,
            "labels": labels,
        }
    
    @staticmethod
    async def list_entities(
        db: AsyncSession,
        kind: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        per_page: int = 20,
        lang: str = "ru"
    ) -> Dict:
        """List entities with filtering and pagination."""
        offset = (page - 1) * per_page
        
        lang_id, ru_lang_id = await get_lang_ids(db, lang)
        entity_filter_condition = entity_label_filter(lang_id, ru_lang_id)
        
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
        
        total = await db.scalar(count_query)
        total_pages = max(1, (total + per_page - 1) // per_page)
        
        result = await db.execute(
            query.order_by(EntityLabel.label)
            .offset(offset)
            .limit(per_page)
        )
        
        items = []
        for entity, label, ek in result.unique():
            # Get kind label
            from app.services.language_service import get_kind_label
            kind_label = await get_kind_label(db, ek.kind_id, lang) or ek.kind_code
            
            items.append({
                "entity": entity,
                "label": label,
                "kind": ek,
                "kind_label": kind_label,
            })
        
        return {
            "items": items,
            "total": total,
            "page": page,
            "per_page": per_page,
            "total_pages": total_pages,
        }
    
    @staticmethod
    async def create_entity(
        db: AsyncSession,
        entity_code: str,
        kind_code: str,
        label_ru: str,
        label_en: Optional[str] = None,
        description: Optional[str] = None,
        owner_id: Optional[UUID] = None
    ) -> Dict:
        """Create a new entity."""
        # Get kind
        kind_result = await db.execute(
            select(EntityKind).where(EntityKind.kind_code == kind_code)
        )
        kind = kind_result.scalar_one_or_none()
        if not kind:
            raise ValueError(f"Kind '{kind_code}' not found")
        
        # Create entity
        entity = Entity(
            entity_code=entity_code,
            kind_id=kind.kind_id,
            status="active",
            owner_id=owner_id,
            version_id=1,
        )
        db.add(entity)
        await db.flush()
        
        # Get language IDs
        ru_lang_id = await get_language_id(db, "ru")
        en_lang_id = await get_language_id(db, "en")
        
        # Create Russian label
        ru_label = EntityLabel(
            entity_id=entity.entity_id,
            language_id=ru_lang_id,
            label=label_ru,
            description=description,
            is_primary=True,
            version_id=1,
        )
        db.add(ru_label)
        
        # Create English label if provided
        if label_en and en_lang_id:
            en_label = EntityLabel(
                entity_id=entity.entity_id,
                language_id=en_lang_id,
                label=label_en,
                description=description,
                is_primary=False,
                version_id=1,
            )
            db.add(en_label)
        
        await db.flush()
        
        return {
            "entity": entity,
            "kind": kind,
        }
    
    @staticmethod
    async def update_entity(
        db: AsyncSession,
        entity_id: UUID,
        entity_code: Optional[str] = None,
        kind_code: Optional[str] = None,
        label_ru: Optional[str] = None,
        label_en: Optional[str] = None,
        description: Optional[str] = None,
        status: Optional[str] = None,
    ) -> Optional[Dict]:
        """Update an existing entity."""
        # Get entity
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_id == entity_id)
        )
        entity = entity_result.scalar_one_or_none()
        if not entity:
            return None
        
        # Update entity fields
        if entity_code is not None:
            entity.entity_code = entity_code
        
        if kind_code is not None:
            kind_result = await db.execute(
                select(EntityKind).where(EntityKind.kind_code == kind_code)
            )
            kind = kind_result.scalar_one_or_none()
            if kind:
                entity.kind_id = kind.kind_id
        
        if status is not None:
            entity.status = status
        
        entity.updated_at = datetime.utcnow()
        await db.flush()
        
        # Update labels
        if label_ru is not None:
            ru_lang_id = await get_language_id(db, "ru")
            label_result = await db.execute(
                select(EntityLabel).where(
                    EntityLabel.entity_id == entity_id,
                    EntityLabel.language_id == ru_lang_id
                )
            )
            label = label_result.scalar_one_or_none()
            if label:
                label.label = label_ru
            else:
                label = EntityLabel(
                    entity_id=entity_id,
                    language_id=ru_lang_id,
                    label=label_ru,
                    is_primary=True,
                    version_id=1,
                )
                db.add(label)
        
        if label_en is not None:
            en_lang_id = await get_language_id(db, "en")
            label_result = await db.execute(
                select(EntityLabel).where(
                    EntityLabel.entity_id == entity_id,
                    EntityLabel.language_id == en_lang_id
                )
            )
            label = label_result.scalar_one_or_none()
            if label:
                label.label = label_en
            else:
                label = EntityLabel(
                    entity_id=entity_id,
                    language_id=en_lang_id,
                    label=label_en,
                    is_primary=False,
                    version_id=1,
                )
                db.add(label)
        
        await db.flush()
        
        # Reload with relationships
        kind_result = await db.execute(
            select(EntityKind).where(EntityKind.kind_id == entity.kind_id)
        )
        kind = kind_result.scalar_one_or_none()
        
        labels_result = await db.execute(
            select(EntityLabel).where(EntityLabel.entity_id == entity.entity_id)
        )
        labels = labels_result.scalars().all()
        
        return {
            "entity": entity,
            "kind": kind,
            "labels": labels,
        }
    
    @staticmethod
    async def delete_entity(db: AsyncSession, entity_id: UUID) -> bool:
        """Soft delete an entity."""
        entity_result = await db.execute(
            select(Entity).where(Entity.entity_id == entity_id)
        )
        entity = entity_result.scalar_one_or_none()
        if not entity:
            return False
        
        entity.status = "deleted"
        entity.updated_at = datetime.utcnow()
        await db.flush()
        
        return True
    
    @staticmethod
    async def search_entities(
        db: AsyncSession,
        query: str,
        kind: Optional[str] = None,
        limit: int = 20,
        lang: str = "ru"
    ) -> List[Dict]:
        """Search entities by name."""
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
        
        result = await db.execute(q)
        
        items = []
        for entity, label, ek in result.unique():
            from app.services.language_service import get_kind_label
            kind_label = await get_kind_label(db, ek.kind_id, lang) or ek.kind_code
            
            items.append({
                "entity": entity,
                "label": label,
                "kind": ek,
                "kind_label": kind_label,
            })
        
        return items
