"""
i18n service — backward-compatible wrapper.

v0.8.0: This module is deprecated. Use ui_translations.py for new code.
Translations are now stored in DB as entities (EntityKind 'ui_string').
This module provides fallback translations for cases where DB is unavailable.
"""

from typing import Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

# Re-export language functions from language.py for backward compatibility
from app.services.language import (
    get_language_id,
    get_language_code,
    clear_language_cache,
)


# Minimal fallback translations (used only when DB is unavailable)
_FALLBACK_TRANSLATIONS = {
    "ru": {
        "nav_entities": "Сущности",
        "nav_search": "Поиск",
        "btn_save": "Сохранить",
        "admin_ui_translations": "UI Переводы",
    },
    "en": {
        "nav_entities": "Entities",
        "nav_search": "Search",
        "btn_save": "Save",
        "admin_ui_translations": "UI Translations",
    },
}


def get_translation(lang: str) -> dict:
    """Get translation dict for a language.
    
    DEPRECATED: Use ui_translations.get_translation_dict() instead.
    This function returns minimal fallback translations only.
    """
    return _FALLBACK_TRANSLATIONS.get(lang, _FALLBACK_TRANSLATIONS.get("ru", {}))
