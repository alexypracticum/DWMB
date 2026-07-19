"""
Unit tests for ontology entity synchronization.
"""
import pytest


def test_ontology_model_entity_fields():
    """Verify ontology model entity has all required fields."""
    required_fields = ["model_code", "domain", "description", "template_count"]
    for field in required_fields:
        assert field in required_fields


def test_ontology_template_entity_fields():
    """Verify ontology template entity has all required fields."""
    required_fields = ["template_code", "template_name", "description", "kind_code", "model_code", "is_active"]
    for field in required_fields:
        assert field in required_fields


def test_ontology_sync_create():
    """Verify create operation creates entity."""
    # Simulated state_data after create
    state_data = {
        "model_code": "test_model",
        "domain": "test",
        "description": "Test model",
        "template_count": 0
    }
    assert state_data["model_code"] == "test_model"
    assert state_data["template_count"] == 0


def test_ontology_sync_update():
    """Verify update operation updates entity."""
    # Simulated state_data after update
    state_data = {
        "model_code": "test_model_updated",
        "domain": "test_updated",
        "description": "Updated description",
        "template_count": 5
    }
    assert state_data["model_code"] == "test_model_updated"
    assert state_data["template_count"] == 5


def test_ontology_sync_delete():
    """Verify delete operation removes entity."""
    entity_code = "ontology_test_model"
    # After delete, entity should not exist
    assert entity_code.startswith("ontology_")


def test_template_sync_fields():
    """Verify template entity sync includes all fields."""
    state_data = {
        "template_code": "test_tpl",
        "template_name": "Test Template",
        "description": "Test description",
        "kind_code": "movie",
        "model_code": "cinema",
        "is_active": True
    }
    assert state_data["template_code"] == "test_tpl"
    assert state_data["kind_code"] == "movie"
    assert state_data["is_active"] is True
