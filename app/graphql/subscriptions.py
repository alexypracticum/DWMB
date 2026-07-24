"""GraphQL subscriptions for real-time updates."""
import asyncio
import strawberry
from typing import AsyncGenerator
from datetime import datetime


# Event bus for passing events from WebSocket manager to subscriptions
_event_queue: asyncio.Queue = asyncio.Queue(maxsize=256)


async def publish_event(event_type: str, data: dict):
    """Publish an event to the subscription bus."""
    event = {
        "type": event_type,
        "data": data,
        "timestamp": datetime.utcnow().isoformat(),
    }
    try:
        _event_queue.put_nowait(event)
    except asyncio.QueueFull:
        # Drop oldest event if queue is full
        try:
            _event_queue.get_nowait()
        except asyncio.QueueEmpty:
            pass
        _event_queue.put_nowait(event)


@strawberry.type
class EntityChanged:
    entity_id: str
    entity_code: str
    action: str  # created, updated, deleted
    timestamp: str


@strawberry.type
class CommentChanged:
    entity_id: str
    comment_id: str
    action: str  # created, deleted
    timestamp: str


@strawberry.type
class RelationChanged:
    entity_id: str
    relation_id: str
    action: str  # created, deleted
    timestamp: str


@strawberry.type
class Subscription:
    @strawberry.subscription
    async def entity_changed(self) -> AsyncGenerator[EntityChanged, None]:
        """Subscribe to entity create/update/delete events."""
        while True:
            event = await _event_queue.get()
            if event["type"] in ("entity_created", "entity_updated", "entity_deleted"):
                data = event["data"]
                action = event["type"].replace("entity_", "")
                yield EntityChanged(
                    entity_id=data.get("entity_id", ""),
                    entity_code=data.get("entity_code", ""),
                    action=action,
                    timestamp=event["timestamp"],
                )

    @strawberry.subscription
    async def comment_changed(self) -> AsyncGenerator[CommentChanged, None]:
        """Subscribe to comment events."""
        while True:
            event = await _event_queue.get()
            if event["type"] in ("comment_added",):
                data = event["data"]
                yield CommentChanged(
                    entity_id=data.get("entity_id", ""),
                    comment_id=data.get("comment_id", ""),
                    action="created",
                    timestamp=event["timestamp"],
                )

    @strawberry.subscription
    async def relation_changed(self) -> AsyncGenerator[RelationChanged, None]:
        """Subscribe to relation events."""
        while True:
            event = await _event_queue.get()
            if event["type"] in ("relation_created", "relation_deleted"):
                data = event["data"]
                action = event["type"].replace("relation_", "")
                yield RelationChanged(
                    entity_id=data.get("entity_id", ""),
                    relation_id=data.get("relation_id", ""),
                    action=action,
                    timestamp=event["timestamp"],
                )
