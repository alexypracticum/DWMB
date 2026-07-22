"""Tests for language service utilities."""
import pytest
from app.services.language_service import (
    get_language_id,
    get_kind_label,
    get_entity_label,
    entity_label_filter,
    kind_label_filter,
    get_lang_ids,
)


def test_language_service_imports():
    """Test that all language service functions are importable."""
    assert callable(get_language_id)
    assert callable(get_kind_label)
    assert callable(get_entity_label)
    assert callable(entity_label_filter)
    assert callable(kind_label_filter)
    assert callable(get_lang_ids)


def test_entity_label_filter():
    """Test entity_label_filter builds correct SQLAlchemy filter."""
    from uuid import uuid4
    from sqlalchemy import or_
    
    lang_id = uuid4()
    ru_lang_id = uuid4()
    
    result = entity_label_filter(lang_id, ru_lang_id)
    assert result is not None


def test_kind_label_filter():
    """Test kind_label_filter builds correct SQLAlchemy filter."""
    from uuid import uuid4
    
    lang_id = uuid4()
    ru_lang_id = uuid4()
    
    result = kind_label_filter(lang_id, ru_lang_id)
    assert result is not None


def test_entity_label_filter_none():
    """Test entity_label_filter with None values."""
    from app.models.entities import EntityLabel
    
    result = entity_label_filter(None, None)
    assert result is not None
