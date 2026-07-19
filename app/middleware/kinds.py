"""
Middleware that loads entity kinds for the navigation dropdown.
"""
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from sqlalchemy import select

from app.database import async_session
from app.models.kinds import EntityKind


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
                request.state.kinds = result.scalars().all()
        except Exception:
            pass

        response = await call_next(request)
        return response
