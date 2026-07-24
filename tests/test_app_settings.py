"""Tests for AppSetting model and dark mode toggle."""
import pytest
from httpx import AsyncClient


def test_app_setting_model_exists():
    """Test AppSetting model can be imported."""
    from app.models.app_settings import AppSetting
    assert AppSetting is not None
    assert hasattr(AppSetting, 'setting_id')
    assert hasattr(AppSetting, 'key')
    assert hasattr(AppSetting, 'value')


def test_app_setting_in_models_init():
    """Test AppSetting is exported from models."""
    from app.models import AppSetting
    assert AppSetting is not None


def test_invalidate_theme_cache_exists():
    """Test invalidate_theme_cache function exists."""
    from app.middleware.theme import invalidate_theme_cache
    assert callable(invalidate_theme_cache)


def test_invalidate_theme_cache_works():
    """Test invalidate_theme_cache doesn't raise."""
    from app.middleware.theme import invalidate_theme_cache
    invalidate_theme_cache()
    invalidate_theme_cache("test_user_id")


def test_dark_mode_toggle_route_exists():
    """Test toggle-dark route is registered."""
    from app.main import app
    routes = [r.path for r in app.routes if hasattr(r, 'path')]
    # Profile routes are under /profile prefix
    assert "/profile/toggle-dark" in routes or "toggle-dark" in str(routes)


@pytest.mark.asyncio
async def test_dark_mode_toggle_unauthenticated(client: AsyncClient):
    """Test dark mode toggle works without auth (sets cookie)."""
    resp = await client.post(
        "/profile/toggle-dark",
        headers={"referer": "/"},
        follow_redirects=False,
    )
    # Should redirect and set dark_mode cookie
    assert resp.status_code == 303
    cookies = resp.headers.get_list("set-cookie")
    dark_cookie = [c for c in cookies if "dark_mode" in c]
    assert len(dark_cookie) > 0, "Should set dark_mode cookie"


@pytest.mark.asyncio
async def test_dark_mode_toggle_authenticated(auth_client: AsyncClient):
    """Test dark mode toggle works with auth (switches themes)."""
    resp = await auth_client.post(
        "/profile/toggle-dark",
        headers={"referer": "/"},
        follow_redirects=False,
    )
    assert resp.status_code == 303


@pytest.mark.asyncio
async def test_dark_mode_toggle_redirects_to_referer(auth_client: AsyncClient):
    """Test dark mode toggle redirects to referer."""
    resp = await auth_client.post(
        "/profile/toggle-dark",
        headers={"referer": "/entities"},
        follow_redirects=False,
    )
    assert resp.status_code == 303
    assert resp.headers.get("location") == "/entities"
