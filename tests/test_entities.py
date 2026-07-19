"""
Tests for entity routes.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_index_returns_200(client):
    resp = await client.get("/")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_entities_list_returns_200(client):
    resp = await client.get("/entities")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_entities_by_kind_movie(client):
    resp = await client.get("/entities?kind=movie")
    assert resp.status_code == 200
    assert "movie" in resp.text.lower() or "фильм" in resp.text.lower()


@pytest.mark.asyncio
async def test_entities_by_kind_actor(client):
    resp = await client.get("/entities?kind=actor")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_entities_by_kind_all_major_types(client):
    """All 12 seeded entity types should return 200."""
    for kind in ["movie", "actor", "director", "writer", "musician",
                 "song", "album", "book", "place", "animal",
                 "concept", "genre"]:
        resp = await client.get(f"/entities?kind={kind}")
        assert resp.status_code == 200, f"Kind '{kind}' returned {resp.status_code}"


@pytest.mark.asyncio
async def test_entity_detail_page(client):
    """Matrix entity should return 200 and contain data."""
    resp = await client.get("/entity/d0000001-0000-0000-0000-000000000001")
    assert resp.status_code == 200
    assert "The Matrix" in resp.text


@pytest.mark.asyncio
async def test_entity_detail_has_production_company(client):
    """The image_data_row layout should render production_company."""
    resp = await client.get("/entity/d0000001-0000-0000-0000-000000000001")
    assert resp.status_code == 200
    assert "Кинокомпания" in resp.text


@pytest.mark.asyncio
async def test_entity_detail_404_for_nonexistent(client):
    resp = await client.get("/entity/00000000-0000-0000-0000-000000000000")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_entity_edit_requires_auth(client):
    resp = await client.get("/entity/d0000001-0000-0000-0000-000000000001/edit", follow_redirects=False)
    assert resp.status_code == 303


@pytest.mark.asyncio
async def test_entity_edit_page(auth_client):
    resp = await auth_client.get("/entity/d0000001-0000-0000-0000-000000000001/edit")
    assert resp.status_code == 200
    assert "Редактирование" in resp.text


@pytest.mark.asyncio
async def test_search_returns_200(client):
    resp = await client.get("/search")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_search_with_query(client):
    resp = await client.get("/search?q=matrix")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_stats_page(client):
    resp = await client.get("/stats")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_entity_create_requires_auth(client):
    resp = await client.get("/entity/create", follow_redirects=False)
    assert resp.status_code == 303
