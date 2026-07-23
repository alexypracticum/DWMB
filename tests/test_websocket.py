"""Tests for WebSocket manager."""
import pytest
from app.services.websocket import ConnectionManager, manager


def test_connection_manager_exists():
    """Test that ConnectionManager exists."""
    assert manager is not None
    assert hasattr(manager, 'active_connections')
    assert hasattr(manager, 'all_connections')


def test_connection_manager_methods():
    """Test that ConnectionManager has required methods."""
    assert hasattr(manager, 'connect')
    assert hasattr(manager, 'disconnect')
    assert hasattr(manager, 'broadcast')
    assert hasattr(manager, 'send_to_user')
    assert hasattr(manager, 'notify_entity_created')
    assert hasattr(manager, 'notify_entity_updated')
    assert hasattr(manager, 'notify_entity_deleted')
    assert hasattr(manager, 'notify_comment_added')
    assert hasattr(manager, 'get_connection_count')
    assert hasattr(manager, 'get_user_connection_count')


def test_initial_connection_count():
    """Test initial connection count is zero."""
    assert manager.get_connection_count() == 0
