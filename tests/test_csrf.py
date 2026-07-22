"""Tests for CSRF protection middleware."""
import pytest
from app.middleware.csrf import CSRFMiddleware, generate_csrf_token, csrf_token_context


def test_generate_csrf_token():
    """Test that CSRF token generation produces valid tokens."""
    token1 = generate_csrf_token()
    token2 = generate_csrf_token()
    
    assert len(token1) == 64  # 32 bytes hex
    assert len(token2) == 64
    assert token1 != token2  # Tokens should be unique


def test_csrf_middleware_class():
    """Test CSRFMiddleware class exists and has correct attributes."""
    assert hasattr(CSRFMiddleware, 'SAFE_METHODS')
    assert 'GET' in CSRFMiddleware.SAFE_METHODS
    assert 'POST' not in CSRFMiddleware.SAFE_METHODS
    assert hasattr(CSRFMiddleware, 'EXEMPT_PATHS')
    assert '/health' in CSRFMiddleware.EXEMPT_PATHS
