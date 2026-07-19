"""
Tests for i18n translation system.
"""
import pytest
import pytest_asyncio


@pytest.mark.asyncio
async def test_default_lang_is_ru(client):
    """Unauthenticated user should get Russian interface."""
    resp = await client.get("/")
    assert resp.status_code == 200
    assert 'lang="ru"' in resp.text


@pytest.mark.asyncio
async def test_translations_ru_nav_elements(client):
    """Russian nav should contain Russian text."""
    resp = await client.get("/")
    assert "Сущности" in resp.text
    assert "Поиск" in resp.text
    assert "Статистика" in resp.text


@pytest.mark.asyncio
async def test_translations_present_in_base(client):
    """Base template should use request.state.t for translations."""
    resp = await client.get("/")
    assert resp.status_code == 200
    # Check that at least some translated strings are present
    assert "DWMB" in resp.text
