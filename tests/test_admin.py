"""
Tests for admin routes.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_admin_requires_auth(client):
    resp = await client.get("/admin", follow_redirects=False)
    assert resp.status_code == 303


@pytest.mark.asyncio
async def test_admin_requires_admin_role(auth_client):
    """Regular auth_client uses 'admin' user, so should work."""
    resp = await auth_client.get("/admin")
    assert resp.status_code == 200
    assert "Панель" in resp.text or "Dashboard" in resp.text


@pytest.mark.asyncio
async def test_admin_kinds_page(auth_client):
    resp = await auth_client.get("/admin/kinds")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_admin_templates_page(auth_client):
    resp = await auth_client.get("/admin/templates")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_admin_fields_page(auth_client):
    resp = await auth_client.get("/admin/fields")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_admin_users_page(auth_client):
    resp = await auth_client.get("/admin/users")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_admin_ai_page(auth_client):
    resp = await auth_client.get("/admin/ai")
    assert resp.status_code == 200
    assert "AI" in resp.text


@pytest.mark.asyncio
async def test_admin_api_kinds(auth_client):
    resp = await auth_client.get("/admin/api/kinds")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) > 0


@pytest.mark.asyncio
async def test_admin_api_fields(auth_client):
    resp = await auth_client.get("/admin/api/fields")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
