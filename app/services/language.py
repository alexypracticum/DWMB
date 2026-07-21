"""
Language service — вспомогательные функции для работы с языками.

Заменяет прямые сравнения с ENUM language_code на FK-based запросы.
"""

from typing import Optional
from uuid import UUID
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.languages import Language
from app.models.entities import EntityLabel
from app.models.kinds import EntityKindLabel
from app.models.field_labels import FieldRegistryLabel


# Кэш для быстрого поиска языка по коду
_language_cache: dict[str, UUID] = {}


async def get_language_id(db: AsyncSession, code: str) -> Optional[UUID]:
    """Get language UUID by code (e.g. 'ru', 'en'). Uses cache."""
    if code in _language_cache:
        return _language_cache[code]
    
    result = await db.execute(
        select(Language.language_id).where(Language.code == code)
    )
    lang_id = result.scalar_one_or_none()
    if lang_id:
        _language_cache[code] = lang_id
    return lang_id


async def get_language_code(db: AsyncSession, language_id: UUID) -> Optional[str]:
    """Get language code by UUID."""
    result = await db.execute(
        select(Language.code).where(Language.language_id == language_id)
    )
    return result.scalar_one_or_none()


def clear_language_cache():
    """Clear the language cache (call after language changes)."""
    _language_cache.clear()


def entity_label_filter_by_lang_id(lang_id: UUID, fallback_lang_id: UUID):
    """Return SQLAlchemy filter for entity label with language fallback by ID."""
    return or_(
        EntityLabel.language_id == lang_id,
        EntityLabel.language_id == fallback_lang_id
    )


def kind_label_filter_by_lang_id(lang_id: UUID, fallback_lang_id: UUID):
    """Return SQLAlchemy filter for kind label with language fallback by ID."""
    return or_(
        EntityKindLabel.language_id == lang_id,
        EntityKindLabel.language_id == fallback_lang_id
    )


def field_label_filter_by_lang_id(lang_id: UUID, fallback_lang_id: UUID):
    """Return SQLAlchemy filter for field label with language fallback by ID."""
    return or_(
        FieldRegistryLabel.language_id == lang_id,
        FieldRegistryLabel.language_id == fallback_lang_id
    )
