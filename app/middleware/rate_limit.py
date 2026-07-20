"""
Rate limiting middleware using slowapi.

Provides:
- IP-based rate limiting for API endpoints
- Stricter limits for auth endpoints (brute-force protection)
- Configurable limits per endpoint group
"""
import logging
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)

# Create limiter instance
limiter = Limiter(key_func=get_remote_address)


def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """Custom handler for rate limit exceeded."""
    logger.warning("Rate limit exceeded for %s: %s", request.client.host, exc.detail)
    return JSONResponse(
        status_code=429,
        content={
            "detail": "Too many requests. Please try again later.",
            "retry_after": exc.detail,
        },
    )


# Rate limit configurations
RATE_LIMITS = {
    "default": "200/minute",
    "api": "100/minute",
    "search": "60/minute",
    "auth": "10/minute",
    "import": "20/minute",
    "upload": "30/minute",
}


def get_rate_limit(endpoint_group: str = "default") -> str:
    """Get rate limit string for an endpoint group."""
    return RATE_LIMITS.get(endpoint_group, RATE_LIMITS["default"])
