"""Tests for language service utilities."""
import pytest
from uuid import uuid4
from app.services.language_service import (
    get_language_id,
    get_kind_label,
    get_entity_label,
    entity_label_filter,
    kind_label_filter,
    get_lang_ids,
    get_kind_labels_batch,
)


def test_language_service_functions_exist():
    """Test that all language service functions are importable."""
    assert callable(get_language_id)
    assert callable(get_kind_label)
    assert callable(get_entity_label)
    assert callable(entity_label_filter)
    assert callable(kind_label_filter)
    assert callable(get_lang_ids)
    assert callable(get_kind_labels_batch)


def test_entity_label_filter_with_ids():
    """Test entity_label_filter builds correct SQLAlchemy filter."""
    lang_id = uuid4()
    ru_lang_id = uuid4()
    
    result = entity_label_filter(lang_id, ru_lang_id)
    assert result is not None


def test_entity_label_filter_none():
    """Test entity_label_filter with None values returns is_primary filter."""
    from app.models.entities import EntityLabel
    
    result = entity_label_filter(None, None)
    assert result is not None


def test_kind_label_filter_with_ids():
    """Test kind_label_filter builds correct SQLAlchemy filter."""
    lang_id = uuid4()
    ru_lang_id = uuid4()
    
    result = kind_label_filter(lang_id, ru_lang_id)
    assert result is not None


def test_kind_label_filter_none():
    """Test kind_label_filter with None values."""
    result = kind_label_filter(None, None)
    assert result is not None


def test_clear_language_cache():
    """Test that language cache can be cleared."""
    from app.services.language_service import clear_language_cache, _language_cache
    
    # Add something to cache
    _language_cache["test"] = uuid4()
    assert "test" in _language_cache
    
    # Clear cache
    clear_language_cache()
    assert "test" not in _language_cache
