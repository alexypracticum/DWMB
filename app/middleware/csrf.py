"""
CSRF protection middleware.
"""
import secrets
import re
import logging
from urllib.parse import unquote
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger(__name__)

CSRF_TOKEN_NAME = "csrf_token"


def generate_csrf_token() -> str:
    return secrets.token_hex(32)


def _extract_form_token(body: bytes, content_type: str) -> str | None:
    """Extract csrf_token from form body."""
    body_str = body.decode("utf-8", errors="ignore")

    # URL-encoded
    if "application/x-www-form-urlencoded" in content_type:
        for pair in body_str.split("&"):
            if pair.startswith("csrf_token="):
                return unquote(pair.split("=", 1)[1])

    # Multipart
    if "multipart/form-data" in content_type:
        marker = 'name="csrf_token"'
        idx = body_str.find(marker)
        if idx >= 0:
            rest = body_str[idx + len(marker):]
            header_end = rest.find("\r\n\r\n")
            if header_end >= 0:
                value_start = header_end + 4
                value_end = rest.find("\r\n--", value_start)
                if value_end >= 0:
                    return rest[value_start:value_end].strip()

    # Fallback regex
    m = re.search(r'csrf_token=([a-f0-9]{32,})', body_str)
    if m:
        return m.group(1)

    return None


class CSRFMiddleware(BaseHTTPMiddleware):
    SAFE_METHODS = {"GET", "HEAD", "OPTIONS", "TRACE"}
    EXEMPT_PATHS = {"/health", "/api/ai/search", "/api/ai/similar", "/api/editor/search", "/graphql", "/graphql/", "/api/set-language", "/auth/login", "/auth/register", "/profile", "/profile/update", "/profile/change-password", "/profile/theme", "/profile/toggle-dark"}

    async def dispatch(self, request: Request, call_next):
        cookie_token = request.cookies.get(CSRF_TOKEN_NAME)

        # GET: ensure cookie exists
        if request.method in self.SAFE_METHODS:
            if not cookie_token:
                cookie_token = generate_csrf_token()
            request.state.csrf_token = cookie_token
            response = await call_next(request)
            if not request.cookies.get(CSRF_TOKEN_NAME):
                response.set_cookie(CSRF_TOKEN_NAME, cookie_token, httponly=False, secure=False, samesite="lax", max_age=86400)
            return response

        if request.url.path in self.EXEMPT_PATHS:
            return await call_next(request)

        if not cookie_token:
            return Response("CSRF token missing", status_code=403, media_type="text/plain")

        # 1. Header check
        header_token = request.headers.get("x-csrf-token")
        if header_token and cookie_token == header_token:
            return await call_next(request)

        # 2. Body check — read body OUTSIDE the call_next try/except
        form_token = None
        body = await request.body()
        ct = request.headers.get("content-type", "")
        form_token = _extract_form_token(body, ct)

        if form_token and cookie_token == form_token:
            request._body = body
            return await call_next(request)

        logger.warning("CSRF mismatch %s %s form_len=%d cookie_len=%d",
                       request.method, request.url.path,
                       len(form_token) if form_token else 0,
                       len(cookie_token))
        return Response("CSRF token mismatch", status_code=403, media_type="text/plain")


def csrf_token_context(request: Request) -> dict:
    token = getattr(request.state, "csrf_token", None)
    if not token:
        token = request.cookies.get(CSRF_TOKEN_NAME, generate_csrf_token())
    return {"csrf_token": token}
