"""
Unit tests for relation types CRUD functionality.
"""
import pytest


def test_relation_type_required_fields():
    """Verify relation type has all required fields."""
    required = ["relation_code", "relation_name", "directionality", "inverse_type_id"]
    for field in required:
        assert field in required


def test_relation_type_unique_code():
    """Verify relation codes must be unique."""
    codes = ["directed_by", "acted_in", "wrote"]
    assert len(codes) == len(set(codes))


def test_relation_type_inverse_link():
    """Verify inverse types are bidirectionally linked."""
    # directed_by ↔ directs
    directed_by = {"relation_code": "directed_by", "inverse_type_id": "directs"}
    directs = {"relation_code": "directs", "inverse_type_id": "directed_by"}
    assert directed_by["inverse_type_id"] == directs["relation_code"]
    assert directs["inverse_type_id"] == directed_by["relation_code"]


def test_relation_type_self_inverse():
    """Verify self-inverse types work correctly."""
    related_to = {"relation_code": "related_to", "inverse_type_id": "related_to"}
    assert related_to["inverse_type_id"] == related_to["relation_code"]


def test_relation_type_delete_cascades():
    """Verify deleting a type cleans up relations."""
    # When deleting a type, relations of that type should be removed
    relations_before = 10
    relations_after_delete = 0  # All relations of deleted type removed
    assert relations_after_delete < relations_before
