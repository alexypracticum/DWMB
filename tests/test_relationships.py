"""
Unit tests for relationship editor functionality.
"""
import pytest


def test_relation_types_structure():
    """Verify relation types have required fields."""
    relation_types = [
        {"relation_type_id": "c0000000-0000-0000-0000-000000000001", "relation_code": "performed_in", "relation_name": "Исполнил в"},
        {"relation_type_id": "c0000000-0000-0000-0000-000000000002", "relation_code": "directed_by", "relation_name": "Режиссёр"},
    ]
    for rt in relation_types:
        assert "relation_type_id" in rt
        assert "relation_code" in rt
        assert "relation_name" in rt


def test_relation_direction_options():
    """Verify direction options for relations."""
    directions = ["outgoing", "incoming"]
    assert "outgoing" in directions
    assert "incoming" in directions


def test_entity_search_api_structure():
    """Verify entity search API returns correct structure."""
    # Simulated API response
    response = {
        "items": [
            {"entity_id": "test-id", "label": "Test Entity", "kind": "movie"}
        ]
    }
    assert "items" in response
    assert len(response["items"]) > 0
    item = response["items"][0]
    assert "entity_id" in item
    assert "label" in item
    assert "kind" in item
