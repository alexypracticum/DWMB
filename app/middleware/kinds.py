"""
Middleware that loads entity kinds for the navigation dropdown.
"""
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from sqlalchemy import select, or_

from app.database import async_session
from app.models.kinds import EntityKind, EntityKindLabel


class KindsMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request.state.kinds = []

        try:
            async with async_session() as session:
                result = await session.execute(
                    select(EntityKind)
                    .where(EntityKind.is_abstract == False)
                    .order_by(EntityKind.sort_order)
                )
                kinds = result.scalars().all()

                # Load kind labels with language fallback
                lang = getattr(request.state, "lang", "ru") if hasattr(request.state, "lang") else "ru"
                kinds_with_labels = []
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
                request.state.kinds = kinds_with_labels
        except Exception:
            pass

        response = await call_next(request)
        return response
