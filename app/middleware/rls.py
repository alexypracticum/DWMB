"""
RLS (Row-Level Security) middleware.

Sets the PostgreSQL session variable 'app.current_user_id' for RLS policies.
"""
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from jose import JWTError, jwt
from contextvars import ContextVar

from app.config import get_settings

settings = get_settings()

# Context variable to store current user_id
current_user_id: ContextVar[str | None] = ContextVar('current_user_id', default=None)


def get_current_user_id() -> str | None:
    """Get current user_id from context."""
    return current_user_id.get()


class RLSMiddleware(BaseHTTPMiddleware):
    """
    Middleware that sets current_user_id for RLS policies.
    
    The RLS policies in PostgreSQL use current_setting('app.current_user_id')
    to determine the current user. This middleware extracts the user_id from
    the JWT token and stores it in a context variable.
    """
    
    async def dispatch(self, request: Request, call_next):
        # Extract user_id from JWT token
        user_id = None
        token = request.cookies.get("access_token")
        
        if token:
            try:
                payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
                username = payload.get("sub")
                if username:
                    # Store username for later use
                    user_id = username
            except JWTError:
                pass
        
        # Set context variable
        token = current_user_id.set(user_id)
        try:
            response = await call_next(request)
            return response
        finally:
            current_user_id.reset(token)
