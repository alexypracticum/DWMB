"""Tests for batch operations (get_kind_labels_batch)."""
import pytest
from uuid import uuid4
from app.services.language_service import get_kind_labels_batch


def test_batch_function_exists():
    """Test that get_kind_labels_batch function exists."""
    assert callable(get_kind_labels_batch)


def test_batch_empty_list():
    """Test batch function with empty list returns empty dict."""
    import asyncio
    
    async def test():
        from app.database import async_session
        async with async_session() as db:
            result = await get_kind_labels_batch(db, [])
            assert result == {}
    
    asyncio.run(test())


def test_batch_nonexistent_ids():
    """Test batch function with nonexistent IDs returns empty dict."""
    import asyncio
    
    async def test():
        from app.database import async_session
        async with async_session() as db:
            fake_ids = [uuid4(), uuid4()]
            result = await get_kind_labels_batch(db, fake_ids)
            assert result == {}
    
    asyncio.run(test())
