"""Tests for Relation Service."""
import pytest
from app.services.relation_service import RelationService


def test_relation_service_exists():
    """Test that RelationService exists and has required methods."""
    assert hasattr(RelationService, 'get_entity_relations')
    assert hasattr(RelationService, 'create_relation')
    assert hasattr(RelationService, 'delete_relation')
    assert hasattr(RelationService, 'list_relation_types')


def test_relation_service_methods_are_callable():
    """Test that RelationService methods are callable."""
    assert callable(RelationService.get_entity_relations)
    assert callable(RelationService.create_relation)
    assert callable(RelationService.delete_relation)
    assert callable(RelationService.list_relation_types)
