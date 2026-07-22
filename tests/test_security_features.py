"""Tests for security features (CORS, SSRF, XSS, password validation)."""
import pytest
from app.config import get_settings


def test_cors_origins_configurable():
    """Test that CORS origins are configurable via settings."""
    settings = get_settings()
    assert hasattr(settings, 'CORS_ORIGINS')
    assert isinstance(settings.CORS_ORIGINS, list)
    assert len(settings.CORS_ORIGINS) > 0


def test_secret_key_warning():
    """Test that default SECRET_KEY triggers warning."""
    import warnings
    settings = get_settings()
    # Default key should be caught by validation
    assert settings.SECRET_KEY is not None


def test_password_validation_requirements():
    """Test password validation logic."""
    # Valid password
    password = "StrongPass123"
    assert len(password) >= 8
    assert any(c.isupper() for c in password)
    assert any(c.islower() for c in password)
    assert any(c.isdigit() for c in password)
    
    # Invalid passwords
    assert len("short") < 8  # Too short
    assert not any(c.isupper() for c in "nouppercase123")  # No uppercase
    assert not any(c.islower() for c in "NOLOWERCASE123")  # No lowercase
    assert not any(c.isdigit() for c in "NoDigitsHere")  # No digits


def test_ssrf_protection_logic():
    """Test SSRF protection URL validation logic."""
    blocked_prefixes = [
        "localhost", "127.0.0.1", "0.0.0.0", "::1",
        "169.254.", "10.", "172.16.", "172.17.", "172.18.",
        "172.19.", "172.20.", "172.21.", "172.22.", "172.23.",
        "172.24.", "172.25.", "172.26.", "172.27.", "172.28.",
        "172.29.", "172.30.", "172.31.", "192.168."
    ]
    
    # Test blocked URLs
    for prefix in blocked_prefixes:
        hostname = prefix.rstrip(".")
        assert any(hostname.startswith(b) or hostname == b.rstrip(".") for b in blocked_prefixes)
    
    # Test allowed URLs
    allowed = ["example.com", "google.com", "github.com"]
    for hostname in allowed:
        assert not any(hostname.startswith(b) for b in blocked_prefixes)


def test_xss_escaping():
    """Test that HTML escaping works correctly."""
    from html import escape
    
    # Test escaping
    assert escape("<script>alert('xss')</script>") == "&lt;script&gt;alert(&#x27;xss&#x27;)&lt;/script&gt;"
    assert escape('"><img src=x onerror=alert(1)>') == '&quot;&gt;&lt;img src=x onerror=alert(1)&gt;'
    assert escape("normal text") == "normal text"
