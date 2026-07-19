"""
Unit tests for import_api helper functions.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch, call
from uuid import uuid4

from sqlalchemy.ext.asyncio import AsyncSession


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
