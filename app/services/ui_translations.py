"""
UI Translations service — чтение переводов интерфейса из БД.

v0.8.0: Translations stored as entities (EntityKind "ui_string")
with multilingual projections in language models.
"""

from typing import Optional
from uuid import UUID
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.entities import Entity, EntityLabel
from app.models.kinds import EntityKind
from app.models.projections import EntityProjection, ProjectionState, OntologyModel
from app.models.languages import Language


# Кэш для переводов: {lang_code: {key: value}}
_translations_cache: dict[str, dict[str, str]] = {}

# Кэш ID сущностей: {key: entity_id}
_entity_cache: dict[str, UUID] = {}

# Кэш ID моделей и шаблонов
_model_id: Optional[UUID] = None
_kind_id: Optional[UUID] = None


async def _ensure_ids(db: AsyncSession) -> tuple[Optional[UUID], Optional[UUID]]:
    """Get or cache model_id and kind_id for ui_string."""
    global _model_id, _kind_id
    
    if _model_id and _kind_id:
        return _model_id, _kind_id
    
    model_result = await db.execute(
        select(OntologyModel.model_id).where(OntologyModel.model_code == "language")
    )
    _model_id = model_result.scalar_one_or_none()
    
    kind_result = await db.execute(
        select(EntityKind.kind_id).where(EntityKind.kind_code == "ui_string")
    )
    _kind_id = kind_result.scalar_one_or_none()
    
    return _model_id, _kind_id


async def get_ui_translation(db: AsyncSession, key: str, lang_code: str = "ru") -> str:
    """Get a single UI translation by key and language code.
    
    Fallback chain: requested lang → ru → key itself
    """
    # Try cache first
    if lang_code in _translations_cache and key in _translations_cache[lang_code]:
        return _translations_cache[lang_code][key]
    
    # Try to load from DB
    model_id, kind_id = await _ensure_ids(db)
    if not model_id or not kind_id:
        return key
    
    # Find entity by code
    entity_result = await db.execute(
        select(Entity).where(
            Entity.entity_code == key,
            Entity.kind_id == kind_id,
            Entity.status == "active"
        )
    )
    entity = entity_result.scalar_one_or_none()
    if not entity:
        return key
    
    # Find projection for requested language (check projection_code suffix)
    proj_result = await db.execute(
        select(EntityProjection, ProjectionState.state_data)
        .join(ProjectionState, ProjectionState.projection_id == EntityProjection.projection_id)
        .where(
            EntityProjection.entity_id == entity.entity_id,
            EntityProjection.model_id == model_id,
            ProjectionState.is_current == True
        )
    )
    
    value = None
    for proj, state_data in proj_result:
        # Check if this projection is for the requested language
        if proj.projection_code and proj.projection_code.endswith(f"_{lang_code}"):
            if state_data and state_data.get("key") == key:
                value = state_data.get("value")
                break
    
    if value:
        # Cache it
        if lang_code not in _translations_cache:
            _translations_cache[lang_code] = {}
        _translations_cache[lang_code][key] = value
        return value
    
    # Fallback to Russian
    if lang_code != "ru":
        return await get_ui_translation(db, key, "ru")
    
    return key


async def get_all_translations(db: AsyncSession, lang_code: str = "ru") -> dict[str, str]:
    """Get all UI translations for a language.
    
    Returns: {key: value} dict
    """
    # Try cache first
    if lang_code in _translations_cache:
        return _translations_cache[lang_code]
    
    model_id, kind_id = await _ensure_ids(db)
    if not model_id or not kind_id:
        return {}
    
    # Get all ui_string entities with their projections for THIS language
    # Filter by projection_code suffix to get only translations for the requested language
    result = await db.execute(
        select(Entity, ProjectionState.state_data, EntityProjection.projection_code)
        .join(EntityProjection, EntityProjection.entity_id == Entity.entity_id)
        .join(ProjectionState, ProjectionState.projection_id == EntityProjection.projection_id)
        .where(
            Entity.kind_id == kind_id,
            Entity.status == "active",
            EntityProjection.model_id == model_id,
            ProjectionState.is_current == True,
            EntityProjection.projection_code.like(f"%_{lang_code}")
        )
    )
    
    translations = {}
    for entity, state_data, proj_code in result:
        if state_data and "key" in state_data and "value" in state_data:
            translations[state_data["key"]] = state_data["value"]
    
    # Cache it
    _translations_cache[lang_code] = translations
    return translations


async def get_translation_dict(db: AsyncSession, lang_code: str = "ru") -> dict:
    """Get translation dict compatible with old i18n.get_translation() interface.
    
    Returns dict with all translation keys for the given language.
    Falls back to Russian for missing keys.
    """
    # Get requested language translations
    lang_translations = await get_all_translations(db, lang_code)
    
    # Get Russian translations as fallback
    if lang_code != "ru":
        ru_translations = await get_all_translations(db, "ru")
        # Merge: requested lang overrides Russian
        result = {**ru_translations, **lang_translations}
    else:
        result = lang_translations
    
    return result


def clear_translations_cache():
    """Clear all translation caches."""
    global _translations_cache, _entity_cache, _model_id, _kind_id
    _translations_cache.clear()
    _entity_cache.clear()
    _model_id = None
    _kind_id = None
