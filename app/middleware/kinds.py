"""
Middleware that loads entity kinds for the navigation dropdown.
Uses cache for performance (Redis with in-memory fallback).
"""
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from sqlalchemy import select, or_

from app.database import async_session
from app.models.kinds import EntityKind, EntityKindLabel
from app.services.cache import cache_get, cache_set


class KindsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request.state.kinds = []

        try:
            lang = getattr(request.state, "lang", "ru") if hasattr(request.state, "lang") else "ru"
            cache_key = f"kinds:{lang}"

            # Try cache first
            cached = await cache_get(cache_key)
            if cached is not None:
                # Reconstruct kind objects from cached data
                from app.models.kinds import EntityKind as EK
                kinds_with_labels = []
                for item in cached:
                    kind = EK()
                    kind.kind_id = item["kind_id"]
                    kind.kind_code = item["kind_code"]
                    kind.sort_order = item["sort_order"]
                    kind._display_label = item["label"]
                    kinds_with_labels.append(kind)
                request.state.kinds = kinds_with_labels
            else:
                async with async_session() as session:
                    result = await session.execute(
                        select(EntityKind)
                        .where(EntityKind.is_abstract == False)
                        .order_by(EntityKind.sort_order)
                    )
                    kinds = result.scalars().all()

                    kinds_with_labels = []
                    cache_data = []
                    for kind in kinds:
                        label_result = await session.execute(
                            select(EntityKindLabel.label).where(
                                EntityKindLabel.kind_id == kind.kind_id,
                                or_(EntityKindLabel.language == lang, EntityKindLabel.language == "ru")
                            ).order_by(
                                (EntityKindLabel.language == lang).desc()
                            ).limit(1)
                        )
                        label = label_result.scalar_one_or_none() or kind.kind_code
                        kind._display_label = label
                        kinds_with_labels.append(kind)
                        cache_data.append({
                            "kind_id": str(kind.kind_id),
                            "kind_code": kind.kind_code,
                            "sort_order": kind.sort_order,
                            "label": label,
                        })
                    request.state.kinds = kinds_with_labels

                    # Cache for 5 minutes
                    await cache_set(cache_key, cache_data, ttl=300)
        except Exception:
            pass

        response = await call_next(request)
        return response
