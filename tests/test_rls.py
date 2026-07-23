"""Tests for RLS middleware."""
import pytest
from app.middleware.rls import RLSMiddleware, get_current_user_id, current_user_id


def test_rls_middleware_exists():
    """Test that RLSMiddleware exists."""
    assert RLSMiddleware is not None


def test_get_current_user_id():
    """Test get_current_user_id function."""
    assert callable(get_current_user_id)
    # Initially should be None
    assert get_current_user_id() is None


def test_current_user_id_context_var():
    """Test current_user_id context variable."""
    from contextvars import ContextVar
    assert isinstance(current_user_id, ContextVar)
