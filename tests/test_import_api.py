"""
Unit tests for import_api helper functions and TMDB service.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession


# ─── _ensure_kind_and_relation ─────────────────────────────────

@pytest.mark.asyncio
async def test_ensure_kind_and_relation_returns_kind_and_rel():
    """_ensure_kind_and_relation returns (kind, rel) when both exist."""
    from app.routes.import_api import _ensure_kind_and_relation

    mock_kind = MagicMock(kind_id=uuid4(), kind_code="character")
    mock_rel = MagicMock(relation_type_id=uuid4(), relation_code="plays")
    mock_inv = MagicMock(relation_type_id=uuid4(), relation_code="played_by")

    db = AsyncMock(spec=AsyncSession)
    db.execute = AsyncMock()
    # kind exists, rel exists, inverse exists
    db.execute.side_effect = [
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_kind)),
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_rel)),
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_inv)),
    ]

    kind, rel = await _ensure_kind_and_relation(db, "character", "plays", "played_by")
    assert kind == mock_kind
    assert rel == mock_rel


@pytest.mark.asyncio
async def test_ensure_kind_and_relation_creates_missing_kind():
    """_ensure_kind_and_relation creates a new EntityKind when missing."""
    from app.routes.import_api import _ensure_kind_and_relation

    mock_parent = MagicMock(kind_id=uuid4())
    mock_kind = MagicMock(kind_id=uuid4(), kind_code="director")
    mock_rel = MagicMock(relation_type_id=uuid4(), relation_code="directed_by")

    db = AsyncMock(spec=AsyncSession)
    db.execute = AsyncMock()
    db.add = MagicMock()
    db.flush = AsyncMock()

    # kind NOT found, parent found, then after flush: kind found, rel found
    call_count = [0]
    async def execute_side_effect(*args, **kwargs):
        call_count[0] += 1
        if call_count[0] == 1:
            # kind not found
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: None))
        elif call_count[0] == 2:
            # parent "entity" found
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_parent))
        elif call_count[0] == 3:
            # after flush, kind found
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_kind))
        else:
            # rel found
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_rel))

    db.execute.side_effect = execute_side_effect

    kind, rel = await _ensure_kind_and_relation(db, "director", "directed_by")
    assert kind.kind_code == "director"
    assert db.add.call_count >= 1


@pytest.mark.asyncio
async def test_ensure_kind_and_relation_creates_missing_rel():
    """_ensure_kind_and_relation creates a new RelationType when missing."""
    from app.routes.import_api import _ensure_kind_and_relation

    mock_kind = MagicMock(kind_id=uuid4(), kind_code="actor")
    mock_rel = MagicMock(relation_type_id=uuid4(), relation_code="acted_in")

    db = AsyncMock(spec=AsyncSession)
    db.execute = AsyncMock()
    db.add = MagicMock()
    db.flush = AsyncMock()

    # kind found, rel NOT found, after flush: rel found
    call_count = [0]
    async def execute_side_effect(*args, **kwargs):
        call_count[0] += 1
        if call_count[0] == 1:
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_kind))
        elif call_count[0] == 2:
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: None))
        else:
            return AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_rel))

    db.execute.side_effect = execute_side_effect

    kind, rel = await _ensure_kind_and_relation(db, "actor", "acted_in")
    assert kind == mock_kind
    assert db.add.call_count >= 1


# ─── _find_or_create_related_entity ────────────────────────────

@pytest.mark.asyncio
async def test_find_or_create_returns_none_when_no_kind():
    """_find_or_create_related_entity returns None if kind/rel not found."""
    from app.routes.import_api import _find_or_create_related_entity

    db = AsyncMock(spec=AsyncSession)
    db.execute = AsyncMock()
    db.execute.return_value = AsyncMock(scalars=lambda: AsyncMock(first=lambda: None))

    result = await _find_or_create_related_entity(
        db, "Test", "123", "nonexistent", "test_rel",
        uuid4(), 1, MagicMock(), MagicMock(),
    )
    assert result is None


@pytest.mark.asyncio
async def test_find_or_create_returns_entity_id_when_existing():
    """_find_or_create_related_entity returns entity_id for existing entity."""
    from app.routes.import_api import _find_or_create_related_entity

    mock_kind = MagicMock(kind_id=uuid4())
    mock_rel_type = MagicMock(relation_type_id=uuid4())
    existing_entity_id = uuid4()
    mock_entity = MagicMock(entity_id=existing_entity_id)
    mock_proj = MagicMock(projection_id=uuid4())

    db = AsyncMock(spec=AsyncSession)
    db.execute = AsyncMock()
    db.flush = AsyncMock()

    # kind, rel_type, existing entity, target proj, existing rel
    results = [
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_kind)),
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_rel_type)),
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_entity)),
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: mock_proj)),
        AsyncMock(scalars=lambda: AsyncMock(first=lambda: None)),  # no existing rel
    ]
    async def side_effect(*a, **kw):
        return results.pop(0)
    db.execute.side_effect = side_effect

    src_proj = MagicMock(projection_id=uuid4())
    result = await _find_or_create_related_entity(
        db, "Keanu Reeves", "12345", "actor", "acted_in",
        uuid4(), 1, src_proj, MagicMock(),
        metadata={"role": "Neo"},
    )
    assert result is not None
    assert result["created"] is False
    assert result["linked"] is True
    assert result["entity_id"] == str(existing_entity_id)


# ─── TMDBService retry logic ───────────────────────────────────

@pytest.mark.asyncio
async def test_tmdb_request_retries_on_429():
    """TMDBService._request retries on 429 rate limit."""
    from app.services.importers.tmdb import TMDBService

    service = TMDBService.__new__(TMDBService)
    service.api_key = "test_key_123"
    service.base_url = "https://api.themoviedb.org/3"
    service.image_base = "https://image.tmdb.org/t/p"
    service._is_v4 = False

    mock_resp_429 = MagicMock(status_code=429, headers={"Retry-After": "0"}, text="rate limited")
    mock_resp_200 = MagicMock(status_code=200)
    mock_resp_200.json.return_value = {"results": []}

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(side_effect=[mock_resp_429, mock_resp_200])
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)

    with patch("app.services.importers.tmdb.httpx.AsyncClient", return_value=mock_client):
        with patch("app.services.importers.tmdb.asyncio.sleep", new_callable=AsyncMock):
            result = await service._request("/search/movie", {"query": "test"})

    assert result == {"results": []}
    assert mock_client.get.call_count == 2


@pytest.mark.asyncio
async def test_tmdb_request_returns_none_on_network_error():
    """TMDBService._request returns None on network errors without retrying."""
    import httpx
    from app.services.importers.tmdb import TMDBService

    service = TMDBService.__new__(TMDBService)
    service.api_key = "test_key_123"
    service.base_url = "https://api.themoviedb.org/3"
    service.image_base = "https://image.tmdb.org/t/p"
    service._is_v4 = False

    mock_client = AsyncMock()
    mock_client.get = AsyncMock(side_effect=httpx.ConnectError("connection refused"))
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)

    with patch("app.services.importers.tmdb.httpx.AsyncClient", return_value=mock_client):
        result = await service._request("/search/movie", {"query": "test"})

    assert result is None


@pytest.mark.asyncio
async def test_tmdb_request_returns_none_on_404():
    """TMDBService._request returns None on 404 without retrying."""
    from app.services.importers.tmdb import TMDBService

    service = TMDBService.__new__(TMDBService)
    service.api_key = "test_key_123"
    service.base_url = "https://api.themoviedb.org/3"
    service.image_base = "https://image.tmdb.org/t/p"
    service._is_v4 = False

    mock_resp = MagicMock(status_code=404, text="not found")
    mock_client = AsyncMock()
    mock_client.get = AsyncMock(return_value=mock_resp)
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)

    with patch("app.services.importers.tmdb.httpx.AsyncClient", return_value=mock_client):
        result = await service._request("/movie/99999999")

    assert result is None
    assert mock_client.get.call_count == 1


@pytest.mark.asyncio
async def test_tmdb_request_returns_none_without_api_key():
    """TMDBService._request returns None when no API key is set."""
    from app.services.importers.tmdb import TMDBService

    service = TMDBService.__new__(TMDBService)
    service.api_key = ""
    service.base_url = "https://api.themoviedb.org/3"
    service.image_base = "https://image.tmdb.org/t/p"
    service._is_v4 = False

    result = await service._request("/search/movie", {"query": "test"})
    assert result is None


# ─── V4 key detection ──────────────────────────────────────────

def test_tmdb_v4_key_detection():
    """TMDBService correctly detects v4 JWT tokens."""
    from app.services.importers.tmdb import TMDBService

    service = TMDBService.__new__(TMDBService)
    # JWT format: header.payload.signature
    service.api_key = "eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjEyMzQ1Njc4OTB9.signature"
    assert service._detect_v4_key() is True

    # Regular API key
    service.api_key = "abc123def456ghi789"
    assert service._detect_v4_key() is False

    # Empty key
    service.api_key = ""
    assert service._detect_v4_key() is False
