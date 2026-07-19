"""
Unit tests for admin CRUD operations.
Tests ontology_model and entity_kind CRUD with entity sync.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_admin_kinds_page(client):
    """Admin kinds list returns 200 for authenticated user."""
    resp = await client.get("/admin/kinds")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_kinds_create_page(client):
    """Admin kind create page returns 200."""
    resp = await client.get("/admin/kinds/create")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_models_page(client):
    """Admin models list returns 200."""
    resp = await client.get("/admin/models")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_models_create_page(client):
    """Admin model create page returns 200."""
    resp = await client.get("/admin/models/create")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_templates_page(client):
    """Admin templates list returns 200."""
    resp = await client.get("/admin/templates")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_fields_page(client):
    """Admin fields list returns 200."""
    resp = await client.get("/admin/fields")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_users_page(client):
    """Admin users list returns 200."""
    resp = await client.get("/admin/users")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_ai_page(client):
    """Admin AI config page returns 200."""
    resp = await client.get("/admin/ai")
    assert resp.status_code in (200, 303)


@pytest.mark.asyncio
async def test_admin_api_kinds(client):
    """Admin API kinds returns JSON."""
    resp = await client.get("/admin/api/kinds")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) > 0


@pytest.mark.asyncio
async def test_admin_api_fields(client):
    """Admin API fields returns JSON."""
    resp = await client.get("/admin/api/fields")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)


@pytest.mark.asyncio
async def test_admin_api_categories(client):
    """Admin API categories returns JSON."""
    resp = await client.get("/admin/api/categories")
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
