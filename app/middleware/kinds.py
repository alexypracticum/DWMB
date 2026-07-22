"""
Middleware that loads entity kinds for the navigation dropdown.
Uses cache for performance (Redis with in-memory fallback).
"""
from starlette.middleware.base import BaseHTTPMiddleware
import logging
from starlette.requests import Request
from sqlalchemy import select, or_

from app.database import async_session
from app.models.kinds import EntityKind, EntityKindLabel
from app.services.cache import cache_get, cache_set
from app.services.language import get_language_id


logger = logging.getLogger(__name__)

class KindsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request.state.kinds = []

        try:
            lang = getattr(request.state, "lang", "ru") if hasattr(request.state, "lang") else "ru"
            logger.debug('KindsMiddleware: lang=%s', lang)
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

                    lang_id = await get_language_id(session, lang)
                    ru_lang_id = await get_language_id(session, "ru")

                    kinds_with_labels = []
                    cache_data = []
                    for kind in kinds:
                        if lang_id or ru_lang_id:
                            or_clauses = []
                            if lang_id:
                                or_clauses.append(EntityKindLabel.language_id == lang_id)
                            if ru_lang_id:
                                or_clauses.append(EntityKindLabel.language_id == ru_lang_id)
                            label_result = await session.execute(
                                select(EntityKindLabel.label).where(
                                    EntityKindLabel.kind_id == kind.kind_id,
                                    or_(*or_clauses)
                                ).order_by(
                                    (EntityKindLabel.language_id == lang_id).desc() if lang_id else True
                                ).limit(1)
                            )
                        else:
                            label_result = await session.execute(
                                select(EntityKindLabel.label).where(
                                    EntityKindLabel.kind_id == kind.kind_id,
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
                    logger.debug('KindsMiddleware: loaded %d kinds', len(kinds_with_labels))
                    request.state.kinds = kinds_with_labels

                    # Cache for 5 minutes
                    await cache_set(cache_key, cache_data, ttl=300)
        except Exception as e:
            import logging
            logging.getLogger(__name__).error(f'KindsMiddleware error: {e}')
            logger.exception('KindsMiddleware error')

        response = await call_next(request)
        return response
