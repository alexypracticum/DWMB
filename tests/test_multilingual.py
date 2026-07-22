"""
Tests for multilingual system (v0.7.0-v0.8.0).
Tests language table, i18n translations, and language switching.
"""
import pytest
import pytest_asyncio
from app.services.language_service import get_lang


# =============================================================================
# Unit Tests: i18n Translation Service (no DB required)
# =============================================================================

def test_get_translation_ru():
    t = get_lang("ru")
    assert t["nav_entities"] == "Сущности"
    assert t["nav_search"] == "Поиск"
    assert t["btn_save"] == "Сохранить"


def test_get_translation_en():
    t = get_lang("en")
    assert t["nav_entities"] == "Entities"
    assert t["nav_search"] == "Search"
    assert t["btn_save"] == "Save"


def test_unknown_language_falls_back_to_ru():
    t = get_lang("xyz")
    assert t["nav_entities"] == "Сущности"


# =============================================================================
# Integration Tests: Language Switching (no DB required)
# =============================================================================

@pytest.mark.asyncio
async def test_set_lang_ru(client):
    resp = await client.get("/set-lang?lang=ru&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=ru" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_en(client):
    resp = await client.get("/set-lang?lang=en&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=en" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_de(client):
    resp = await client.get("/set-lang?lang=de&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=de" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_fr(client):
    resp = await client.get("/set-lang?lang=fr&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=fr" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_es(client):
    resp = await client.get("/set-lang?lang=es&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=es" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_zh(client):
    resp = await client.get("/set-lang?lang=zh&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=zh" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_ja(client):
    resp = await client.get("/set-lang?lang=ja&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=ja" in str(resp.headers.get("set-cookie", ""))


@pytest.mark.asyncio
async def test_set_lang_invalid_falls_back_to_ru(client):
    resp = await client.get("/set-lang?lang=xyz&next=/", follow_redirects=False)
    assert resp.status_code == 303
    assert "lang=ru" in str(resp.headers.get("set-cookie", ""))


# =============================================================================
# Model Tests: Verify FK-based language columns
# =============================================================================

@pytest.mark.asyncio
async def test_entity_label_has_language_id_column(db_session):
    """EntityLabel should have language_id column (not language ENUM column)."""
    from app.models.entities import EntityLabel
    from sqlalchemy import inspect
    mapper = inspect(EntityLabel)
    cols = [c.key for c in mapper.columns]
    rels = [r.key for r in mapper.relationships]
    assert "language_id" in cols, "EntityLabel should have language_id column"
    assert "language" in rels, "EntityLabel should have language relationship"
    assert "language" not in cols, "EntityLabel should NOT have old 'language' ENUM column"


@pytest.mark.asyncio
async def test_user_account_has_language_id_column(db_session):
    """UserAccount should have language_id column."""
    from app.models.users import UserAccount
    from sqlalchemy import inspect
    mapper = inspect(UserAccount)
    cols = [c.key for c in mapper.columns]
    assert "language_id" in cols, "UserAccount should have language_id column"


# =============================================================================
# Unit Tests: UI Translations Service
# =============================================================================

def test_ui_translations_service_importable():
    """ui_translations service should be importable."""
    from app.services.ui_translations import get_ui_translation, get_all_translations, get_translation_dict
    assert callable(get_ui_translation)
    assert callable(get_all_translations)
    assert callable(get_translation_dict)


def test_ui_translations_cache_clear():
    """clear_translations_cache should work without errors."""
    from app.services.ui_translations import clear_translations_cache
    clear_translations_cache()


def test_language_service_importable():
    """language service should be importable."""
    from app.services.language import get_language_id, get_language_code, clear_language_cache
    assert callable(get_language_id)
    assert callable(get_language_code)
    assert callable(clear_language_cache)
