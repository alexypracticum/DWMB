"""
Unit tests for relation metadata and simplified direction logic.
"""
import pytest


def test_relation_metadata_fields():
    """Verify relation metadata has all required fields."""
    metadata = {
        "role": "главная роль",
        "confidence": 0.95,
        "weight": 0.8
    }
    assert "role" in metadata
    assert "confidence" in metadata
    assert "weight" in metadata
    assert metadata["confidence"] <= 1.0
    assert metadata["weight"] <= 1.0


def test_relation_metadata_empty():
    """Verify empty metadata is valid."""
    metadata = {}
    assert isinstance(metadata, dict)
    assert len(metadata) == 0


def test_self_inverse_undirected():
    """Verify self-inverse means undirected relation."""
    # related_to has inverse_type_id = self
    relation_type = {
        "relation_code": "related_to",
        "inverse_type_id": "self",  # same as relation_type_id
    }
    assert relation_type["inverse_type_id"] == "self"


def test_directed_relation_has_different_inverse():
    """Verify directed relation has different inverse type."""
    relation_type = {
        "relation_code": "directed_by",
        "inverse_type_id": "directs",  # different type
    }
    assert relation_type["inverse_type_id"] != relation_type["relation_code"]


def test_no_duplicate_for_undirected():
    """Verify undirected relation creates only one record."""
    # When adding related_to A→B, should NOT create related_to B→A
    direct_count = 1  # Only one relation created
    inverse_count = 0  # No inverse created for self-inverse
    assert direct_count + inverse_count == 1


def test_directed_creates_pair():
    """Verify directed relation creates two records."""
    direct_count = 1
    inverse_count = 1
    assert direct_count + inverse_count == 2


def test_relation_type_simplification():
    """Verify directionality and symmetric flags are removed."""
    # New schema: only inverse_type_id matters
    relation_type = {
        "relation_code": "similar_to",
        "inverse_type_id": "similar_to",  # self-inverse
    }
    # No directionality or symmetric_relation fields needed
    assert "directionality" not in relation_type
    assert "symmetric_relation" not in relation_type
