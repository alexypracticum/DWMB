"""
Tests for admin routes.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_admin_requires_auth(client):
    resp = await client.get("/admin", follow_redirects=False)
    assert resp.status_code in (303, 307)


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


def test_sync_layout_fields_from_schema():
    """Verify _sync_layout_fields_from_schema preserves field_order and skips poster/description/content."""
    from app.routes.admin import _sync_layout_fields_from_schema

    schema = {
        "properties": {
            "title": {"title": "Название", "type": "string"},
            "year": {"title": "Год", "type": "integer"},
            "rating": {"title": "Рейтинг", "type": "float"},
            "poster": {"title": "Постер", "type": "string"},
            "description": {"title": "Описание", "type": "string"},
            "content": {"title": "Контент", "type": "string"},
            "genre": {"title": "Жанр", "type": "string"},
        },
        "field_order": ["genre", "year", "title", "rating"],
    }
    layout = [
        {"type": "image_data_row", "config": {"fields": []}},
        {"type": "some_other_block", "config": {}},
    ]
    _sync_layout_fields_from_schema(layout, schema)
    result_fields = layout[0]["config"]["fields"]
    keys = [f["key"] for f in result_fields]
    # field_order preserved
    assert keys == ["genre", "year", "title", "rating"], f"Expected ordered keys, got {keys}"
    # poster, description, content skipped
    assert "poster" not in keys
    assert "description" not in keys
    assert "content" not in keys
    # Labels and types from props
    genre_field = next(f for f in result_fields if f["key"] == "genre")
    assert genre_field["label"] == "Жанр"
    assert genre_field["type"] == "string"


def test_sync_layout_fields_empty_schema():
    """Verify _sync_layout_fields_from_schema handles empty schema gracefully."""
    from app.routes.admin import _sync_layout_fields_from_schema

    layout = [{"type": "image_data_row", "config": {"fields": [{"key": "old"}]}}]
    result = _sync_layout_fields_from_schema(layout, None)
    assert result is layout  # same object returned
    assert result[0]["config"]["fields"] == [{"key": "old"}]  # unchanged


def test_sync_layout_fields_fallback_to_object_keys():
    """When field_order is empty, fall back to Object.keys(props) order."""
    from app.routes.admin import _sync_layout_fields_from_schema

    schema = {
        "properties": {
            "a": {"title": "A"},
            "b": {"title": "B"},
            "c": {"title": "C"},
        },
        "field_order": [],
    }
    layout = [{"type": "image_data_row", "config": {"fields": []}}]
    _sync_layout_fields_from_schema(layout, schema)
    keys = [f["key"] for f in layout[0]["config"]["fields"]]
    # Object.keys order in Python 3.7+ preserves insertion order
    assert keys == ["a", "b", "c"], f"Expected ['a','b','c'], got {keys}"
