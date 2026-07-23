"""Tests for Kind Service."""
import pytest
from app.services.kind_service import KindService


def test_kind_service_exists():
    """Test that KindService exists and has required methods."""
    assert hasattr(KindService, 'get_kind')
    assert hasattr(KindService, 'list_kinds')
    assert hasattr(KindService, 'create_kind')
    assert hasattr(KindService, 'update_kind')
    assert hasattr(KindService, 'delete_kind')


def test_kind_service_methods_are_callable():
    """Test that KindService methods are callable."""
    assert callable(KindService.get_kind)
    assert callable(KindService.list_kinds)
    assert callable(KindService.create_kind)
    assert callable(KindService.update_kind)
    assert callable(KindService.delete_kind)
