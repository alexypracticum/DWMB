from fastapi import Request
"""
Language service — общие утилиты для работы с языками.

Централизует:
- Получение language_id по коду
- Построение фильтров с fallback по языку
- Получение label сущностей/типов
"""
from typing import Optional
from uuid import UUID
from sqlalchemy import select, or_, case
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.languages import Language
from app.models.entities import EntityLabel
from app.models.kinds import EntityKind, EntityKindLabel


# ─── Language ID cache ────────────────────────────────────────
_language_cache: dict[str, UUID] = {}


async def get_language_id(db: AsyncSession, code: str) -> Optional[UUID]:
    """Get language UUID by code (e.g. 'ru', 'en'). Uses in-memory cache."""
    if code in _language_cache:
        return _language_cache[code]
    result = await db.execute(
        select(Language.language_id).where(Language.code == code)
    )
    lang_id = result.scalar_one_or_none()
    if lang_id:
        _language_cache[code] = lang_id
    return lang_id


def clear_language_cache():
    """Clear the language cache (call after language changes)."""
    _language_cache.clear()


# ─── Request helpers ──────────────────────────────────────────
def get_lang(request: Request) -> str:
    """Get current language from request state with fallback."""
    return getattr(request.state, "lang", "ru")


# ─── Filter builders ─────────────────────────────────────────
def entity_label_filter(lang_id: Optional[UUID], ru_lang_id: Optional[UUID]):
    """Build or_clauses for entity label language fallback."""
    clauses = []
    if lang_id:
        clauses.append(EntityLabel.language_id == lang_id)
    if ru_lang_id:
        clauses.append(EntityLabel.language_id == ru_lang_id)
    if clauses:
        return or_(*clauses)
    return EntityLabel.is_primary == True


def kind_label_filter(lang_id: Optional[UUID], ru_lang_id: Optional[UUID]):
    """Build or_clauses for kind label language fallback."""
    clauses = []
    if lang_id:
        clauses.append(EntityKindLabel.language_id == lang_id)
    if ru_lang_id:
        clauses.append(EntityKindLabel.language_id == ru_lang_id)
    if clauses:
        return or_(*clauses)
    return EntityKindLabel.language_id.isnot(None)


def lang_priority_case(lang_id: Optional[UUID]):
    """Build SQLAlchemy case for ordering by language priority."""
    if lang_id:
        return case(
            (EntityLabel.language_id == lang_id, 0),
            else_=1
        )
    return case((EntityLabel.is_primary == True, 0), else_=1)


# ─── Label getters ────────────────────────────────────────────
async def get_kind_label(db: AsyncSession, kind_id: UUID, lang: str = "ru") -> Optional[str]:
    """
    Get kind label with language fallback: current → 'ru' → kind_code.
    Replaces 3 duplicate _get_kind_label implementations.
    """
    lang_id = await get_language_id(db, lang)
    ru_lang_id = await get_language_id(db, "ru")
    
    if not lang_id and not ru_lang_id:
        # Ultimate fallback: get kind_code
        result = await db.execute(
            select(EntityKind.kind_code).where(EntityKind.kind_id == kind_id)
        )
        return result.scalar_one_or_none()
    
    result = await db.execute(
        select(EntityKindLabel.label).where(
            EntityKindLabel.kind_id == kind_id,
            kind_label_filter(lang_id, ru_lang_id)
        ).order_by(
            (EntityKindLabel.language_id == lang_id).desc() if lang_id else True
        ).limit(1)
    )
    label = result.scalar_one_or_none()
    if label:
        return label
    
    # Fallback to kind_code
    result = await db.execute(
        select(EntityKind.kind_code).where(EntityKind.kind_id == kind_id)
    )
    return result.scalar_one_or_none()


async def get_entity_label(db: AsyncSession, entity_id: UUID, lang: str = "ru") -> Optional[str]:
    """Get entity display label with language fallback."""
    lang_id = await get_language_id(db, lang)
    ru_lang_id = await get_language_id(db, "ru")
    
    result = await db.execute(
        select(EntityLabel.label).where(
            EntityLabel.entity_id == entity_id,
            entity_label_filter(lang_id, ru_lang_id)
        ).order_by(
            (EntityLabel.language_id == lang_id).desc() if lang_id else True
        ).limit(1)
    )
    return result.scalar_one_or_none()


async def get_lang_ids(db: AsyncSession, lang: str = "ru"):
    """Get both lang_id and ru_lang_id in one call."""
    lang_id = await get_language_id(db, lang)
    ru_lang_id = await get_language_id(db, "ru")
    return lang_id, ru_lang_id


# ─── Batch operations ──────────────────────────────────────────
async def get_kind_labels_batch(db: AsyncSession, kind_ids: list[UUID], lang: str = "ru") -> dict[UUID, str]:
    """
    Get kind labels for multiple kinds in one query.
    Returns dict mapping kind_id -> label.
    Replaces N+1 query pattern: for kind in kinds: await get_kind_label(db, kind.kind_id, lang)
    """
    if not kind_ids:
        return {}
    
    lang_id = await get_language_id(db, lang)
    ru_lang_id = await get_language_id(db, "ru")
    
    if not lang_id and not ru_lang_id:
        # Fallback to kind_code
        result = await db.execute(
            select(EntityKind.kind_id, EntityKind.kind_code).where(EntityKind.kind_id.in_(kind_ids))
        )
        return {row[0]: row[1] for row in result.all()}
    
    # Get all labels for these kinds in one query
    result = await db.execute(
        select(EntityKindLabel.kind_id, EntityKindLabel.label, EntityKindLabel.language_id).where(
            EntityKindLabel.kind_id.in_(kind_ids),
            kind_label_filter(lang_id, ru_lang_id)
        )
    )
    
    # Build dict with language priority
    labels: dict[UUID, tuple[str, int]] = {}  # kind_id -> (label, priority)
    for kind_id, label, lid in result.all():
        priority = 0 if (lang_id and lid == lang_id) else 1
        if kind_id not in labels or priority < labels[kind_id][1]:
            labels[kind_id] = (label, priority)
    
    # Fallback to kind_code for missing labels
    if len(labels) < len(kind_ids):
        missing = set(kind_ids) - set(labels.keys())
        result = await db.execute(
            select(EntityKind.kind_id, EntityKind.kind_code).where(EntityKind.kind_id.in_(missing))
        )
        for kind_id, code in result.all():
            labels[kind_id] = (code, 2)
    
    return {kid: label for kid, (label, _) in labels.items()}
