"""Tests for external API integrations (OMDb)."""
import pytest


def test_search_imdb_function_exists():
    """Test that search_imdb function exists."""
    from app.services.external_apis import search_imdb
    assert callable(search_imdb)


def test_get_imdb_details_function_exists():
    """Test that get_imdb_details function exists."""
    from app.services.external_apis import get_imdb_details
    assert callable(get_imdb_details)


def test_import_imdb_movie_function_exists():
    """Test that import_imdb_movie function exists."""
    from app.services.external_apis import import_imdb_movie
    assert callable(import_imdb_movie)


def test_omdb_search_endpoint_exists():
    """Test that OMDb search endpoint is registered."""
    from app.routes.import_api import router
    routes = [r.path for r in router.routes]
    assert "/omdb/search" in routes


def test_omdb_movie_endpoint_exists():
    """Test that OMDb movie endpoint is registered."""
    from app.routes.import_api import router
    routes = [r.path for r in router.routes]
    assert "/omdb/movie/{imdb_id}" in routes


def test_omdb_import_endpoint_exists():
    """Test that OMDb import endpoint is registered."""
    from app.routes.import_api import router
    routes = [r.path for r in router.routes]
    assert "/omdb/import/{imdb_id}" in routes


def test_omdb_status_endpoint_exists():
    """Test that OMDb status endpoint is registered."""
    from app.routes.import_api import router
    routes = [r.path for r in router.routes]
    assert "/omdb/status" in routes


def test_config_has_omdb_key():
    """Test that OMDB_API_KEY is in settings."""
    from app.config import Settings
    assert hasattr(Settings, 'OMDB_API_KEY')
