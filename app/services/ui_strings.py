"""
UI Strings service — works with ui_string and ui_string_translation tables.
Replaces the entity-based UI translation system.
"""
import logging
from typing import Optional, Dict
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)


async def get_ui_string(db: AsyncSession, key: str, lang_code: str = "ru") -> Optional[str]:
    """Get a UI string value by key and language."""
    from app.models.languages import Language
    
    # Get language_id
    lang_result = await db.execute(
        select(Language.language_id).where(Language.code == lang_code)
    )
    lang_id = lang_result.scalar_one_or_none()
    
    if not lang_id:
        return None
    
    # Get string_id from key
    string_result = await db.execute(
        select(text("string_id")).where(text('"key"') == key)
    )
    string_id = string_result.scalar_one_or_none()
    
    if not string_id:
        return None
    
    # Get translation
    translation_result = await db.execute(
        select(text("value")).where(
            text("string_id") == string_id,
            text("language_id") == lang_id
        )
    )
    return translation_result.scalar_one_or_none()


async def get_ui_strings_dict(db: AsyncSession, lang_code: str = "ru") -> Dict[str, str]:
    """Get all UI strings for a language as a dictionary."""
    from app.models.languages import Language
    
    # Get language_id
    lang_result = await db.execute(
        select(Language.language_id).where(Language.code == lang_code)
    )
    lang_id = lang_result.scalar_one_or_none()
    
    if not lang_id:
        return {}
    
    # Get all translations for this language
    result = await db.execute(
        text("""
            SELECT us.key, ust.value
            FROM meta.ui_string us
            JOIN meta.ui_string_translation ust ON us.string_id = ust.string_id
            WHERE ust.language_id = :lang_id
        """),
        {"lang_id": lang_id}
    )
    
    return {row[0]: row[1] for row in result}


async def get_all_ui_strings_dict(db: AsyncSession, lang_code: str = "ru") -> Dict[str, str]:
    """Get all UI strings with fallback to Russian."""
    # Get requested language
    result = await get_ui_strings_dict(db, lang_code)
    
    # If not Russian, also get Russian as fallback
    if lang_code != "ru":
        ru_result = await get_ui_strings_dict(db, "ru")
        # Merge: requested language overrides Russian
        result = {**ru_result, **result}
    
    return result


def clear_ui_strings_cache():
    """Clear the UI strings cache."""
    # Placeholder for future caching implementation
    pass
