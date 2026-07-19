"""
Shared test fixtures for DWMB project.
Uses the app's own async engine against the real PostgreSQL in Docker.
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db, async_session
from app.main import app
from app.services.auth import create_access_token


@pytest_asyncio.fixture
async def db_session():
    """Real DB session from the app's engine, rolled back after each test."""
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db_session):
    """Async HTTP client wired to a real DB session."""
    async def _override():
        yield db_session

    app.dependency_overrides[get_db] = _override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_client(db_session):
    """Async HTTP client with admin auth cookie."""
    async def _override():
        yield db_session

    app.dependency_overrides[get_db] = _override
    token = create_access_token(data={"sub": "admin"})
    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport,
        base_url="http://test",
        cookies={"access_token": token},
    ) as ac:
        yield ac
    app.dependency_overrides.clear()
