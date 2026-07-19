"""
Unit tests for entity CRUD with multi-projection support.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_entity_create_page(client):
    """Entity create page shows step 1 (kind selection)."""
    resp = await client.get("/entity/create")
    assert resp.status_code == 200
    assert "Выберите тип" in resp.text or "Тип" in resp.text


@pytest.mark.asyncio
async def test_entity_create_step2(client):
    """Entity create step 2 shows all templates grouped by kind."""
    resp = await client.get("/entity/create?kind=movie")
    assert resp.status_code == 200
    # Should show templates from multiple kinds
    assert "template_ids" in resp.text


@pytest.mark.asyncio
async def test_entity_create_step3(client):
    """Entity create step 3 shows merged fields from selected templates."""
    resp = await client.get("/entity/create?kind=movie&template_ids=7784c033-1ca7-4714-95c7-8110d5d5a496")
    assert resp.status_code == 200
    assert "title" in resp.text or "Название" in resp.text


@pytest.mark.asyncio
async def test_entity_detail_page(client):
    """Entity detail page returns 200 for existing entity."""
    resp = await client.get("/entity/d0000001-0000-0000-0000-000000000004")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_entity_detail_404(client):
    """Entity detail returns 404 for nonexistent entity."""
    resp = await client.get("/entity/00000000-0000-0000-0000-000000000000")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_entity_edit_requires_auth(client):
    """Entity edit requires authentication."""
    resp = await client.get("/entity/d0000001-0000-0000-0000-000000000004/edit")
    assert resp.status_code == 303


@pytest.mark.asyncio
async def test_entity_edit_page(auth_client):
    """Entity edit page shows projections section."""
    resp = await auth_client.get("/entity/d0000001-0000-0000-0000-000000000004/edit")
    assert resp.status_code == 200
    assert "Привязанные онтологии" in resp.text or "онтологи" in resp.text.lower()


@pytest.mark.asyncio
async def test_entity_edit_modal(auth_client):
    """Entity edit page has add-projection modal."""
    resp = await auth_client.get("/entity/d0000001-0000-0000-0000-000000000004/edit")
    assert resp.status_code == 200
    assert "addProjectionModal" in resp.text


@pytest.mark.asyncio
async def test_entity_search(client):
    """Search returns 200."""
    resp = await client.get("/search?q=matrix")
    assert resp.status_code == 200
