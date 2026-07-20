"""
Cache service — Redis with in-memory fallback.

Provides:
- get/set/delete with TTL
- Decorator for caching function results
- Auto-fallback to in-memory dict if Redis unavailable
"""
import json
import logging
import hashlib
from typing import Optional, Any
from functools import wraps

logger = logging.getLogger(__name__)

# In-memory fallback cache
_memory_cache: dict[str, tuple[Any, float]] = {}
_memory_max_size = 1000

_redis_client = None
_redis_available = False


async def init_cache(redis_url: str = "redis://localhost:6379/0") -> None:
    """Initialize Redis connection. Falls back to memory if unavailable."""
    global _redis_client, _redis_available
    try:
        import redis.asyncio as aioredis
        _redis_client = aioredis.from_url(redis_url, decode_responses=True)
        await _redis_client.ping()
        _redis_available = True
        logger.info("Redis cache connected: %s", redis_url)
    except Exception as e:
        _redis_available = False
        logger.warning("Redis unavailable, using in-memory cache: %s", e)


async def close_cache() -> None:
    """Close Redis connection."""
    global _redis_client, _redis_available
    if _redis_client:
        try:
            await _redis_client.close()
        except Exception:
            pass
    _redis_available = False


async def cache_get(key: str) -> Optional[Any]:
    """Get value from cache."""
    if _redis_available and _redis_client:
        try:
            val = await _redis_client.get(key)
            if val is not None:
                return json.loads(val)
        except Exception as e:
            logger.warning("Redis get error: %s", e)
    else:
        import time
        entry = _memory_cache.get(key)
        if entry:
            value, expires = entry
            if expires > time.time():
                return value
            del _memory_cache[key]
    return None


async def cache_set(key: str, value: Any, ttl: int = 300) -> None:
    """Set value in cache with TTL in seconds."""
    if _redis_available and _redis_client:
        try:
            await _redis_client.setex(key, ttl, json.dumps(value, default=str))
        except Exception as e:
            logger.warning("Redis set error: %s", e)
    else:
        import time
        if len(_memory_cache) >= _memory_max_size:
            # Evict oldest entries
            oldest_keys = sorted(_memory_cache.keys(), key=lambda k: _memory_cache[k][1])[:100]
            for k in oldest_keys:
                del _memory_cache[k]
        _memory_cache[key] = (value, time.time() + ttl)


async def cache_delete(key: str) -> None:
    """Delete value from cache."""
    if _redis_available and _redis_client:
        try:
            await _redis_client.delete(key)
        except Exception as e:
            logger.warning("Redis delete error: %s", e)
    else:
        _memory_cache.pop(key, None)


async def cache_delete_pattern(pattern: str) -> None:
    """Delete all keys matching pattern."""
    if _redis_available and _redis_client:
        try:
            keys = []
            async for key in _redis_client.scan_iter(match=pattern):
                keys.append(key)
            if keys:
                await _redis_client.delete(*keys)
        except Exception as e:
            logger.warning("Redis delete pattern error: %s", e)
    else:
        import fnmatch
        keys_to_delete = [k for k in _memory_cache if fnmatch.fnmatch(k, pattern)]
        for k in keys_to_delete:
            del _memory_cache[k]


def cache_key(*args, **kwargs) -> str:
    """Generate a cache key from arguments."""
    raw = json.dumps({"args": args, "kwargs": kwargs}, sort_keys=True, default=str)
    return hashlib.md5(raw.encode()).hexdigest()


def cached(ttl: int = 300, prefix: str = ""):
    """
    Decorator to cache function results.

    Usage:
        @cached(ttl=60, prefix="kinds")
        async def get_kinds():
            ...
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            key = f"{prefix}:{cache_key(*args, **kwargs)}" if prefix else f"fn:{func.__name__}:{cache_key(*args, **kwargs)}"
            result = await cache_get(key)
            if result is not None:
                return result
            result = await func(*args, **kwargs)
            if result is not None:
                await cache_set(key, result, ttl=ttl)
            return result
        return wrapper
    return decorator
