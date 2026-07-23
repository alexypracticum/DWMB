"""
CSRF protection middleware.

Generates and validates CSRF tokens for form submissions.
Tokens are stored in cookies and validated on POST/PUT/DELETE requests.
"""
import secrets
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger(__name__)

CSRF_TOKEN_NAME = "csrf_token"


def generate_csrf_token() -> str:
    """Generate a new CSRF token."""
    return secrets.token_hex(32)


class CSRFMiddleware(BaseHTTPMiddleware):
    """
    CSRF protection middleware.
    
    Validates CSRF token from X-CSRF-Token header on state-changing requests.
    For form submissions, the token must be in the header (JS helper handles this).
    """
    
    SAFE_METHODS = {"GET", "HEAD", "OPTIONS", "TRACE"}
    EXEMPT_PATHS = {"/health", "/api/ai/search", "/api/ai/similar", "/api/editor/search", "/graphql", "/graphql/", "/api/set-language"}
    
    async def dispatch(self, request: Request, call_next):
        # Get or create CSRF token
        cookie_token = request.cookies.get(CSRF_TOKEN_NAME)
        
        # On GET requests, ensure cookie is set
        if request.method in self.SAFE_METHODS:
            if not cookie_token:
                cookie_token = generate_csrf_token()
            
            # Store token in request.state for templates
            request.state.csrf_token = cookie_token
            
            response = await call_next(request)
            
            # Set cookie if not already set
            if not request.cookies.get(CSRF_TOKEN_NAME):
                response.set_cookie(
                    CSRF_TOKEN_NAME,
                    cookie_token,
                    httponly=False,  # JS needs to read it for AJAX
                    secure=False,   # Set to True in production with HTTPS
                    samesite="lax",
                    max_age=86400,  # 24 hours
                )
            
            return response
        
        # Skip CSRF for exempt paths
        if request.url.path in self.EXEMPT_PATHS:
            return await call_next(request)
        
        # Validate on state-changing requests
        if not cookie_token:
            logger.warning("CSRF token missing in cookie for %s %s", request.method, request.url.path)
            return Response(
                content="CSRF token missing",
                status_code=403,
                media_type="text/plain",
            )
        
        # Get token from X-CSRF-Token header (for AJAX requests)
        header_token = request.headers.get("X-CSRF-Token")
        
        # For form submissions, token must be in header (JS adds it automatically)
        # We don't read form body to avoid consuming it for FastAPI
        
        # Validate
        if not header_token or cookie_token != header_token:
            logger.warning("CSRF validation failed for %s %s", request.method, request.url.path)
            return Response(
                content="CSRF token mismatch",
                status_code=403,
                media_type="text/plain",
            )
        
        # Continue with request
        response = await call_next(request)
        return response


def csrf_token_context(request: Request) -> dict:
    """
    Jinja2 context processor that adds csrf_token to all templates.
    """
    token = getattr(request.state, "csrf_token", None)
    if not token:
        token = request.cookies.get(CSRF_TOKEN_NAME, generate_csrf_token())
    return {"csrf_token": token}
