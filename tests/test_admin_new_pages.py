"""Tests for new admin pages: event log, roles, API settings, email, security, backup."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_event_log_page(auth_client: AsyncClient):
    """Test event log page loads."""
    resp = await auth_client.get("/admin/event-log", follow_redirects=False)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_roles_page(auth_client: AsyncClient):
    """Test roles page loads."""
    resp = await auth_client.get("/admin/roles", follow_redirects=False)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_api_settings_page(auth_client: AsyncClient):
    """Test API settings page loads."""
    resp = await auth_client.get("/admin/api-settings", follow_redirects=False)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_email_settings_page(auth_client: AsyncClient):
    """Test email settings page loads."""
    resp = await auth_client.get("/admin/email-settings", follow_redirects=False)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_security_page(auth_client: AsyncClient):
    """Test security settings page loads."""
    resp = await auth_client.get("/admin/security", follow_redirects=False)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_backup_page(auth_client: AsyncClient):
    """Test backup page loads."""
    resp = await auth_client.get("/admin/backup", follow_redirects=False)
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_admin_pages_require_auth(client: AsyncClient):
    """Test admin pages redirect when not authenticated."""
    for path in ["/admin/event-log", "/admin/roles", "/admin/api-settings"]:
        resp = await client.get(path, follow_redirects=False)
        assert resp.status_code in (303, 307, 401), f"{path} should require auth"


def test_admin_routes_exist():
    """Test that admin routes are registered."""
    from app.main import app
    routes = [r.path for r in app.routes if hasattr(r, 'path')]
    assert "/admin/event-log" in routes
    assert "/admin/roles" in routes
    assert "/admin/api-settings" in routes
    assert "/admin/email-settings" in routes
    assert "/admin/security" in routes
    assert "/admin/backup" in routes


def test_admin_submodules_loaded():
    """Test that admin submodules are loaded."""
    from app.routes.admin import router
    route_paths = [r.path for r in router.routes if hasattr(r, 'path')]
    assert any("event-log" in p for p in route_paths)
    assert any("roles" in p for p in route_paths)
    assert any("api-settings" in p for p in route_paths)
    assert any("email-settings" in p for p in route_paths)
    assert any("security" in p for p in route_paths)
    assert any("backup" in p for p in route_paths)
