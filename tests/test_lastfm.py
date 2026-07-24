"""
Tests for Last.fm integration.
"""
import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch, MagicMock
from app.services.lastfm import (
    lastfm_status,
    get_user_info,
    get_recent_tracks,
    get_top_tracks,
    get_top_artists,
    get_top_albums,
    get_track_info,
    _parse_track,
    _extract_image,
    _slugify,
)


# ─── Unit Tests: Helpers ────────────────────────────────────────


def test_parse_track_basic():
    raw = {
        "name": "Bohemian Rhapsody",
        "mbid": "abc123",
        "artist": {"#text": "Queen", "mbid": "def456"},
        "album": {"#text": "A Night at the Opera", "mbid": "ghi789"},
        "url": "https://last.fm/music/Queen/_/Bohemian+Rhapsody",
        "date": {"#text": "01 Jan 2024, 12:00"},
        "image": [
            {"#text": "https://example.com/small.jpg", "size": "small"},
            {"#text": "https://example.com/large.jpg", "size": "large"},
        ],
    }
    result = _parse_track(raw)
    assert result["name"] == "Bohemian Rhapsody"
    assert result["mbid"] == "abc123"
    assert result["artist"] == "Queen"
    assert result["artist_mbid"] == "def456"
    assert result["album"] == "A Night at the Opera"
    assert result["album_mbid"] == "ghi789"
    assert result["date"] == "01 Jan 2024, 12:00"


def test_parse_track_minimal():
    raw = {"name": "Test Track"}
    result = _parse_track(raw)
    assert result["name"] == "Test Track"
    assert not result["mbid"]
    assert result["artist"] == ""


def test_extract_image_list():
    images = [
        {"#text": "https://example.com/small.jpg", "size": "small"},
        {"#text": "https://example.com/medium.jpg", "size": "medium"},
        {"#text": "https://example.com/large.jpg", "size": "large"},
    ]
    assert _extract_image(images) == "https://example.com/large.jpg"


def test_extract_image_string():
    assert _extract_image("https://example.com/img.jpg") == "https://example.com/img.jpg"


def test_extract_image_none():
    assert _extract_image(None) is None
    assert _extract_image([]) is None


def test_extract_image_prefers_extralarge():
    images = [
        {"#text": "https://example.com/med.jpg", "size": "medium"},
        {"#text": "https://example.com/xl.jpg", "size": "extralarge"},
    ]
    assert _extract_image(images) == "https://example.com/xl.jpg"


def test_slugify():
    assert _slugify("Queen") == "queen"
    assert _slugify("Bohemian Rhapsody!") == "bohemian_rhapsody"
    assert _slugify("A / B & C") == "a_b_c"
    assert _slugify("a" * 100) == "a" * 50


# ─── Unit Tests: API Functions ──────────────────────────────────


@pytest.mark.asyncio
async def test_lastfm_status_not_configured():
    with patch("app.services.lastfm._get_api_key", return_value=None):
        result = await lastfm_status()
        assert result["configured"] is False
        assert "не задан" in result["message"]


@pytest.mark.asyncio
async def test_lastfm_status_configured():
    with patch("app.services.lastfm._get_api_key", return_value="test_key"):
        result = await lastfm_status()
        assert result["configured"] is True
        assert "настроен" in result["message"]


@pytest.mark.asyncio
async def test_get_user_info_no_api_key():
    with patch("app.services.lastfm._get_api_key", return_value=None):
        result = await get_user_info("testuser")
        assert result is None


@pytest.mark.asyncio
async def test_get_recent_tracks_no_api_key():
    with patch("app.services.lastfm._get_api_key", return_value=None):
        result = await get_recent_tracks("testuser")
        assert result == []


@pytest.mark.asyncio
async def test_get_top_tracks_no_api_key():
    with patch("app.services.lastfm._get_api_key", return_value=None):
        result = await get_top_tracks("testuser")
        assert result == []


# ─── Integration Tests: Mock API ────────────────────────────────


@pytest.mark.asyncio
async def test_get_user_info_success():
    mock_data = {
        "user": {
            "name": "testuser",
            "realname": "Test User",
            "url": "https://last.fm/user/testuser",
            "image": [{"#text": "https://example.com/avatar.jpg", "size": "large"}],
            "playcount": "12345",
            "registered": {"unixtime": "1234567890"},
        }
    }
    with patch("app.services.lastfm._get_api_key", return_value="test_key"), \
         patch("app.services.lastfm._lastfm_request", new_callable=AsyncMock, return_value=mock_data):
        result = await get_user_info("testuser")
        assert result["username"] == "testuser"
        assert result["playcount"] == 12345


@pytest.mark.asyncio
async def test_get_top_tracks_success():
    mock_data = {
        "toptracks": {
            "track": [
                {
                    "name": "Track 1",
                    "mbid": "mbid1",
                    "artist": {"#text": "Artist 1"},
                    "playcount": "100",
                    "url": "https://last.fm/...",
                },
                {
                    "name": "Track 2",
                    "mbid": "mbid2",
                    "artist": {"#text": "Artist 2"},
                    "playcount": "50",
                    "url": "https://last.fm/...",
                },
            ]
        }
    }
    with patch("app.services.lastfm._get_api_key", return_value="test_key"), \
         patch("app.services.lastfm._lastfm_request", new_callable=AsyncMock, return_value=mock_data):
        result = await get_top_tracks("testuser", period="overall", limit=2)
        assert len(result) == 2
        assert result[0]["name"] == "Track 1"
        assert result[0]["rank"] == 1
        assert result[0]["playcount"] == 100
        assert result[1]["rank"] == 2


@pytest.mark.asyncio
async def test_get_top_artists_success():
    mock_data = {
        "topartists": {
            "artist": [
                {"name": "Artist 1", "mbid": "mbid1", "playcount": "200", "url": "...", "image": []},
                {"name": "Artist 2", "mbid": "", "playcount": "100", "url": "...", "image": []},
            ]
        }
    }
    with patch("app.services.lastfm._get_api_key", return_value="test_key"), \
         patch("app.services.lastfm._lastfm_request", new_callable=AsyncMock, return_value=mock_data):
        result = await get_top_artists("testuser")
        assert len(result) == 2
        assert result[0]["name"] == "Artist 1"
        assert result[0]["playcount"] == 200


@pytest.mark.asyncio
async def test_get_recent_tracks_now_playing_filtered():
    mock_data = {
        "recenttracks": {
            "track": [
                {"name": "Track 1", "artist": {"#text": "A"}, "date": {"#text": "01 Jan"}},
                {"name": "Playing", "artist": {"#text": "B"}, "@attr": {"nowplaying": "true"}},
            ]
        }
    }
    with patch("app.services.lastfm._get_api_key", return_value="test_key"), \
         patch("app.services.lastfm._lastfm_request", new_callable=AsyncMock, return_value=mock_data):
        result = await get_recent_tracks("testuser")
        assert len(result) == 1
        assert result[0]["name"] == "Track 1"
