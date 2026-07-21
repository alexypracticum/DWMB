"""
Tests for new features: language switcher, set-lang route.
Run inside Docker: docker compose exec app python -m pytest tests/test_new_features.py -v
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest_asyncio.fixture
async def client():
    """Async test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


class TestSetLangRoute:
    """Tests for /set-lang endpoint."""

    @pytest.mark.asyncio
    async def test_set_lang_ru(self, client):
        """Setting language to ru sets cookie and redirects."""
        response = await client.get("/set-lang?lang=ru", follow_redirects=False)
        assert response.status_code == 303
        assert "lang=ru" in str(response.headers.get("set-cookie", ""))

    @pytest.mark.asyncio
    async def test_set_lang_en(self, client):
        """Setting language to en sets cookie and redirects."""
        response = await client.get("/set-lang?lang=en", follow_redirects=False)
        assert response.status_code == 303
        assert "lang=en" in str(response.headers.get("set-cookie", ""))

    @pytest.mark.asyncio
    async def test_set_lang_invalid_falls_back_to_ru(self, client):
        """Invalid language falls back to ru."""
        response = await client.get("/set-lang?lang=xyz", follow_redirects=False)
        assert response.status_code == 303
        assert "lang=ru" in str(response.headers.get("set-cookie", ""))

    @pytest.mark.asyncio
    async def test_set_lang_redirects_to_next(self, client):
        """Language switcher redirects to next URL."""
        response = await client.get("/set-lang?lang=en&next=/entities", follow_redirects=False)
        assert response.status_code == 303
        assert response.headers["location"] == "/entities"

    @pytest.mark.asyncio
    async def test_set_lang_redirects_to_root_by_default(self, client):
        """Language switcher redirects to / by default."""
        response = await client.get("/set-lang?lang=en", follow_redirects=False)
        assert response.status_code == 303
        assert response.headers["location"] == "/"
