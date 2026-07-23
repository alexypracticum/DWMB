"""Tests for Entity Service."""
import pytest
from uuid import uuid4
from app.services.entity_service import EntityService


def test_entity_service_exists():
    """Test that EntityService exists and has required methods."""
    assert hasattr(EntityService, 'get_entity')
    assert hasattr(EntityService, 'list_entities')
    assert hasattr(EntityService, 'create_entity')
    assert hasattr(EntityService, 'update_entity')
    assert hasattr(EntityService, 'delete_entity')
    assert hasattr(EntityService, 'search_entities')


def test_entity_service_methods_are_callable():
    """Test that EntityService methods are callable."""
    assert callable(EntityService.get_entity)
    assert callable(EntityService.list_entities)
    assert callable(EntityService.create_entity)
    assert callable(EntityService.update_entity)
    assert callable(EntityService.delete_entity)
    assert callable(EntityService.search_entities)
