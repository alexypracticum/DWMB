"""
Kind Service — business logic for entity kind operations.
"""
import logging
from typing import Optional, List, Dict
from uuid import UUID
from datetime import datetime

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.kinds import EntityKind, EntityKindLabel
from app.services.language_service import get_language_id, get_lang_ids, kind_label_filter

logger = logging.getLogger(__name__)


class KindService:
    """Service for entity kind operations."""
    
    @staticmethod
    async def get_kind(db: AsyncSession, kind_id: UUID) -> Optional[Dict]:
        """Get kind with label."""
        result = await db.execute(
            select(EntityKind).where(EntityKind.kind_id == kind_id)
        )
        kind = result.scalar_one_or_none()
        if not kind:
            return None
        
        # Get label
        label_result = await db.execute(
            select(EntityKindLabel.label)
            .where(EntityKindLabel.kind_id == kind_id)
            .limit(1)
        )
        label = label_result.scalar_one_or_none()
        
        return {
            "kind": kind,
            "label": label or kind.kind_code,
        }
    
    @staticmethod
    async def list_kinds(
        db: AsyncSession,
        include_abstract: bool = False,
        lang: str = "ru"
    ) -> List[Dict]:
        """List all entity kinds."""
        query = select(EntityKind).order_by(EntityKind.sort_order)
        
        if not include_abstract:
            query = query.where(EntityKind.is_abstract == False)
        
        result = await db.execute(query)
        
        kinds = []
        for kind in result.scalars().all():
            # Get label
            from app.services.language_service import get_kind_label
            label = await get_kind_label(db, kind.kind_id, lang) or kind.kind_code
            
            kinds.append({
                "kind": kind,
                "label": label,
            })
        
        return kinds
    
    @staticmethod
    async def create_kind(
        db: AsyncSession,
        kind_code: str,
        description: Optional[str] = None,
        is_abstract: bool = False,
        sort_order: int = 0,
        parent_kind_code: Optional[str] = None,
        label_ru: Optional[str] = None,
        label_en: Optional[str] = None,
    ) -> Dict:
        """Create a new entity kind."""
        # Get parent kind if specified
        parent_kind_id = None
        if parent_kind_code:
            parent_result = await db.execute(
                select(EntityKind).where(EntityKind.kind_code == parent_kind_code)
            )
            parent = parent_result.scalar_one_or_none()
            if parent:
                parent_kind_id = parent.kind_id
        
        # Create kind
        kind = EntityKind(
            kind_code=kind_code,
            description=description,
            is_abstract=is_abstract,
            sort_order=sort_order,
            parent_kind_id=parent_kind_id,
            version_id=1,
        )
        db.add(kind)
        await db.flush()
        
        # Get language IDs
        ru_lang_id = await get_language_id(db, "ru")
        en_lang_id = await get_language_id(db, "en")
        
        # Create Russian label
        if label_ru and ru_lang_id:
            ru_label = EntityKindLabel(
                kind_id=kind.kind_id,
                language_id=ru_lang_id,
                label=label_ru,
                version_id=1,
            )
            db.add(ru_label)
        
        # Create English label
        if label_en and en_lang_id:
            en_label = EntityKindLabel(
                kind_id=kind.kind_id,
                language_id=en_lang_id,
                label=label_en,
                version_id=1,
            )
            db.add(en_label)
        
        await db.flush()
        
        return {
            "kind": kind,
        }
    
    @staticmethod
    async def update_kind(
        db: AsyncSession,
        kind_id: UUID,
        kind_code: Optional[str] = None,
        description: Optional[str] = None,
        is_abstract: Optional[bool] = None,
        sort_order: Optional[int] = None,
        label_ru: Optional[str] = None,
        label_en: Optional[str] = None,
    ) -> Optional[Dict]:
        """Update an entity kind."""
        result = await db.execute(
            select(EntityKind).where(EntityKind.kind_id == kind_id)
        )
        kind = result.scalar_one_or_none()
        if not kind:
            return None
        
        if kind_code is not None:
            kind.kind_code = kind_code
        if description is not None:
            kind.description = description
        if is_abstract is not None:
            kind.is_abstract = is_abstract
        if sort_order is not None:
            kind.sort_order = sort_order
        
        await db.flush()
        
        return {"kind": kind}
    
    @staticmethod
    async def delete_kind(db: AsyncSession, kind_id: UUID) -> bool:
        """Delete an entity kind (only if no entities use it)."""
        # Check if any entities use this kind
        count_result = await db.execute(
            select(func.count(Entity.entity_id)).where(Entity.kind_id == kind_id)
        )
        count = count_result.scalar()
        
        if count > 0:
            raise ValueError(f"Cannot delete kind: {count} entities use it")
        
        # Delete kind
        kind_result = await db.execute(
            select(EntityKind).where(EntityKind.kind_id == kind_id)
        )
        kind = kind_result.scalar_one_or_none()
        if not kind:
            return False
        
        await db.delete(kind)
        await db.flush()
        
        return True
