"""
Unit tests for i18n translation service (v0.8.0).
Tests backward-compatible wrapper and language functions.
"""
from app.services.i18n import get_translation, get_language_id, get_language_code, clear_language_cache
from app.services.language import get_language_id as lang_get_language_id


def test_get_translation_ru():
    """Fallback translation should return Russian."""
    t = get_translation("ru")
    assert t["nav_entities"] == "Сущности"
    assert t["nav_search"] == "Поиск"
    assert t["btn_save"] == "Сохранить"


def test_get_translation_en():
    """Fallback translation should return English."""
    t = get_translation("en")
    assert t["nav_entities"] == "Entities"
    assert t["nav_search"] == "Search"
    assert t["btn_save"] == "Save"


def test_unknown_language_falls_back_to_ru():
    """Unknown language should fall back to Russian."""
    t = get_translation("xyz")
    assert t["nav_entities"] == "Сущности"


def test_language_functions_reexported():
    """Language functions should be re-exported from i18n."""
    assert get_language_id is lang_get_language_id
    assert callable(get_language_code)
    assert callable(clear_language_cache)
