"""
Tests for graph export and D3.js graph functionality.
"""
import pytest
import json
from unittest.mock import AsyncMock, patch, MagicMock
from app.services.external_apis import (
    search_imdb,
    get_imdb_details,
    search_wikipedia,
    get_wikipedia_page,
    search_musicbrainz,
    get_musicbrainz_details,
    _check_rate_limit,
)
from app.services.cache import cache_delete_pattern


# ─── Rate Limiter Tests ────────────────────────────────────────


def test_rate_limit_first_call():
    """First call should always succeed."""
    from app.services.external_apis import _api_rate_limits
    _api_rate_limits.clear()
    assert _check_rate_limit("test_api", min_interval=0) is True


def test_rate_limit_blocks_quick_successive():
    """Second call within interval should be blocked."""
    from app.services.external_apis import _api_rate_limits
    _api_rate_limits.clear()
    assert _check_rate_limit("test_api", min_interval=10.0) is True  # 10 sec interval
    assert _check_rate_limit("test_api", min_interval=10.0) is False  # Too soon


def test_rate_limit_different_apis_independent():
    """Different APIs have independent rate limits."""
    from app.services.external_apis import _api_rate_limits
    _api_rate_limits.clear()
    assert _check_rate_limit("api_a", min_interval=10.0) is True
    assert _check_rate_limit("api_b", min_interval=10.0) is True


# ─── OMDb Tests ────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_search_imdb_no_key():
    """Should return empty list when no API key configured."""
    with patch("app.config.get_settings") as mock_settings:
        mock_settings.return_value = MagicMock(OMDB_API_KEY="")
        result = await search_imdb("Inception")
        assert result == []


@pytest.mark.asyncio
async def test_get_imdb_details_no_key():
    """Should return None when no API key configured."""
    with patch("app.config.get_settings") as mock_settings:
        mock_settings.return_value = MagicMock(OMDB_API_KEY="")
        result = await get_imdb_details("tt1375666")
        assert result is None


@pytest.mark.asyncio
async def test_search_imdb_success():
    """Should parse search results correctly."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "Response": "True",
        "Search": [
            {"Title": "Inception", "Year": "2010", "imdbID": "tt1375666", "Poster": "http://img.jpg", "Type": "movie"},
            {"Title": "Inception", "Year": "1984", "imdbID": "tt0084987", "Poster": "N/A", "Type": "movie"},
        ],
    }

    with patch("app.config.get_settings") as mock_settings, \
         patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_settings.return_value = MagicMock(OMDB_API_KEY="test_key")
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await search_imdb("Inception")
        assert len(result) == 2
        assert result[0]["title"] == "Inception"
        assert result[0]["imdb_id"] == "tt1375666"


@pytest.mark.asyncio
async def test_get_imdb_details_success():
    """Should parse movie details correctly."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "Response": "True",
        "Title": "Inception",
        "Year": "2010",
        "imdbID": "tt1375666",
        "Poster": "http://img.jpg",
        "Plot": "A mind-bending thriller",
        "Director": "Christopher Nolan",
        "Actors": "Leonardo DiCaprio",
        "Genre": "Sci-Fi, Thriller",
        "imdbRating": "8.8",
        "Runtime": "148 min",
    }

    with patch("app.config.get_settings") as mock_settings, \
         patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_settings.return_value = MagicMock(OMDB_API_KEY="test_key")
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await get_imdb_details("tt1375666")
        assert result is not None
        assert result["title"] == "Inception"
        assert result["rating"] == "8.8"
        assert result["director"] == "Christopher Nolan"


# ─── Wikipedia Tests ────────────────────────────────────────────


@pytest.mark.asyncio
async def test_search_wikipedia_success():
    """Should parse Wikipedia opensearch results."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = [
        "Python",
        ["Python (programming language)", "Python (genus)"],
        ["High-level programming language", "Genus of snakes"],
        ["https://en.wikipedia.org/wiki/Python_(programming_language)", "https://en.wikipedia.org/wiki/Python_(genus)"],
    ]

    with patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await search_wikipedia("Python", "en")
        assert len(result) == 2
        assert result[0]["title"] == "Python (programming language)"


@pytest.mark.asyncio
async def test_get_wikipedia_page_success():
    """Should parse Wikipedia page summary."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "title": "Python",
        "extract": "Python is a high-level programming language.",
        "content_urls": {"desktop": {"page": "https://en.wikipedia.org/wiki/Python"}},
        "thumbnail": {"source": "https://upload.wikimedia.org/thumb/python.png"},
        "description": "Programming language",
    }

    with patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await get_wikipedia_page("Python", "en")
        assert result is not None
        assert result["title"] == "Python"
        assert "high-level" in result["extract"]


# ─── MusicBrainz Tests ─────────────────────────────────────────


@pytest.mark.asyncio
async def test_search_musicbrainz_success():
    """Should parse MusicBrainz search results."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "recordings": [
            {
                "id": "mbid-123",
                "title": "Bohemian Rhapsody",
                "artist-credit": [{"name": "Queen"}],
                "first-release-date": "1975-10-31",
            }
        ]
    }

    with patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await search_musicbrainz("Bohemian Rhapsody", "recording")
        assert len(result) == 1
        assert result[0]["title"] == "Bohemian Rhapsody"
        assert result[0]["artist"] == "Queen"
        assert result[0]["year"] == "1975"


@pytest.mark.asyncio
async def test_get_musicbrainz_details_recording():
    """Should parse MusicBrainz recording details."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "id": "mbid-123",
        "title": "Bohemian Rhapsody",
        "artist-credit": [{"name": "Queen"}],
        "first-release-date": "1975-10-31",
        "length": 354000,
    }

    with patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await get_musicbrainz_details("mbid-123", "recording")
        assert result is not None
        assert result["title"] == "Bohemian Rhapsody"
        assert result["duration"] == "5:54"


@pytest.mark.asyncio
async def test_get_musicbrainz_details_artist():
    """Should parse MusicBrainz artist details."""
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "id": "mbid-456",
        "name": "Queen",
        "type": "Group",
        "country": "GB",
        "life-span": {"begin": "1970", "end": None},
    }

    with patch("app.services.external_apis.httpx.AsyncClient") as mock_client:
        mock_client.return_value.__aenter__ = AsyncMock(return_value=MagicMock(get=AsyncMock(return_value=mock_response)))
        mock_client.return_value.__aexit__ = AsyncMock(return_value=False)

        await cache_delete_pattern("*")
        result = await get_musicbrainz_details("mbid-456", "artist")
        assert result is not None
        assert result["title"] == "Queen"
        assert result["type"] == "Group"
        assert result["country"] == "GB"
