"""
EventLog service — audit trail for entity changes.

Writes entries to the event_log table for create, update, delete,
merge, split, state_transition, and relation_change events.
"""
import logging
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.entities import EventLog

logger = logging.getLogger(__name__)


async def log_event(
    db: AsyncSession,
    event_type: str,
    entity_id: Optional[UUID] = None,
    projection_id: Optional[UUID] = None,
    relation_id: Optional[UUID] = None,
    asset_id: Optional[UUID] = None,
    payload: Optional[dict] = None,
    caused_by: Optional[str] = None,
    version_id: int = 1,
) -> None:
    """
    Write an audit event to the event_log table.

    Args:
        db: Database session
        event_type: One of 'create', 'update', 'delete', 'merge', 'split',
                    'state_transition', 'relation_change'
        entity_id: ID of the affected entity
        projection_id: ID of the affected projection
        relation_id: ID of the affected relation
        asset_id: ID of the affected media asset
        payload: Additional event data as JSON
        caused_by: Description of what caused this event
        version_id: Version ID for this event
    """
    try:
        event = EventLog(
            event_type=event_type,
            entity_id=entity_id,
            projection_id=projection_id,
            relation_id=relation_id,
            asset_id=asset_id,
            payload=payload or {},
            caused_by=caused_by,
            version_id=version_id,
        )
        db.add(event)
        await db.flush()
        logger.debug("Event logged: %s for entity %s", event_type, entity_id)
    except Exception as e:
        # Don't let event logging fail the main operation
        logger.error("Failed to log event %s: %s", event_type, e)


async def log_entity_created(db: AsyncSession, entity_id: UUID, version_id: int, caused_by: str = None) -> None:
    """Log entity creation."""
    await log_event(db, "create", entity_id=entity_id, caused_by=caused_by, version_id=version_id)


async def log_entity_updated(db: AsyncSession, entity_id: UUID, version_id: int, caused_by: str = None, changes: dict = None) -> None:
    """Log entity update."""
    await log_event(db, "update", entity_id=entity_id, payload=changes or {}, caused_by=caused_by, version_id=version_id)


async def log_entity_deleted(db: AsyncSession, entity_id: UUID, version_id: int, caused_by: str = None) -> None:
    """Log entity deletion."""
    await log_event(db, "delete", entity_id=entity_id, caused_by=caused_by, version_id=version_id)


async def log_state_transition(db: AsyncSession, entity_id: UUID, projection_id: UUID, version_id: int, caused_by: str = None, old_state: dict = None, new_state: dict = None) -> None:
    """Log projection state change."""
    payload = {}
    if old_state:
        payload["old"] = old_state
    if new_state:
        payload["new"] = new_state
    await log_event(db, "state_transition", entity_id=entity_id, projection_id=projection_id, payload=payload, caused_by=caused_by, version_id=version_id)


async def log_relation_change(db: AsyncSession, relation_id: UUID, entity_id: UUID, version_id: int, caused_by: str = None, action: str = None) -> None:
    """Log relation creation/modification/deletion."""
    await log_event(db, "relation_change", entity_id=entity_id, relation_id=relation_id, payload={"action": action}, caused_by=caused_by, version_id=version_id)


async def get_entity_history(db: AsyncSession, entity_id: UUID, limit: int = 50) -> list:
    """Get event history for an entity, newest first."""
    from sqlalchemy import select
    result = await db.execute(
        select(EventLog)
        .where(EventLog.entity_id == entity_id)
        .order_by(EventLog.occurred_at.desc())
        .limit(limit)
    )
    return result.scalars().all()
