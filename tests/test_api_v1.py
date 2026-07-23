"""Tests for API v1 endpoints."""
import pytest


def test_api_v1_exists():
    """Test that API v1 module exists."""
    from app.api.v1 import router
    assert router is not None


def test_api_v1_entities_exists():
    """Test that API v1 entities module exists."""
    from app.api.v1.entities import router
    assert router is not None


def test_api_v1_kinds_exists():
    """Test that API v1 kinds module exists."""
    from app.api.v1.kinds import router
    assert router is not None


def test_api_v1_relations_exists():
    """Test that API v1 relations module exists."""
    from app.api.v1.relations import router
    assert router is not None


def test_api_v1_search_exists():
    """Test that API v1 search module exists."""
    from app.api.v1.search import router
    assert router is not None
