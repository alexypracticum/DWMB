"""
Shared test fixtures for DWMB project.
Uses the app's own async engine against the real PostgreSQL in Docker.
"""
import os
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

# Set test database URL BEFORE any app imports
os.environ["TEST_DATABASE_URL"] = "postgresql+asyncpg://dwmb:dwmb_secret_2026@localhost:5432/dwmb"

from app.config import get_settings
from app.database import get_db
from app.main import app
from app.services.auth import create_access_token

settings = get_settings()

# Create test engine
test_db_url = os.getenv("TEST_DATABASE_URL", settings.DATABASE_URL)
test_engine = create_async_engine(test_db_url, echo=False)
TestSessionLocal = async_sessionmaker(bind=test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest_asyncio.fixture
async def db_session():
    """Real DB session from test engine, rolled back after each test."""
    async with TestSessionLocal() as session:
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
