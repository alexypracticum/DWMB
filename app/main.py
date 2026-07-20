import os
import logging
import httpx
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

# Core routes (always loaded)
from app.routes import auth, entities, search, admin, editor_api, profile, comments, export, feeds

# Core middleware
from app.middleware.theme import ThemeMiddleware
from app.middleware.kinds import KindsMiddleware
from app.middleware.rate_limit import limiter, rate_limit_exceeded_handler
from app.config import get_settings

# Cache
from app.services.cache import init_cache, close_cache

# Plugin system
from plugins import load_plugins

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app):
    settings = get_settings()
    redis_url = getattr(settings, "REDIS_URL", "redis://localhost:6379/0")
    await init_cache(redis_url)
    yield
    await close_cache()


app = FastAPI(title="DWMB Meta-System", docs_url="/docs", redoc_url=None, lifespan=lifespan)

# Rate limiter
app.state.limiter = limiter
app.add_exception_handler(429, rate_limit_exceeded_handler)

# ─── Middleware (order matters: outermost first) ───────────────
app.add_middleware(KindsMiddleware)
app.add_middleware(ThemeMiddleware)

# ─── Static files ──────────────────────────────────────────────
app.mount("/static", StaticFiles(directory="app/static"), name="static")

media_dir = os.path.join(os.path.dirname(__file__), "media")
os.makedirs(os.path.join(media_dir, "uploads"), exist_ok=True)


@app.api_route("/media/proxy", methods=["GET"])
async def media_proxy(url: str):
    """Proxy MinIO/external URLs to bypass CORS and Docker-internal hostnames."""
    settings = get_settings()
    target_url = url.replace(f"http://{settings.MINIO_ENDPOINT}", f"http://{settings.MINIO_PUBLIC_ENDPOINT}")
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(target_url, follow_redirects=True)
        content_type = resp.headers.get("content-type", "application/octet-stream")
        return StreamingResponse(
            iter([resp.content]),
            media_type=content_type,
            headers={"Cache-Control": "public, max-age=86400"},
        )


app.mount("/media", StaticFiles(directory=media_dir), name="media")


@app.get("/set-lang")
async def set_language(lang: str = "ru", next: str = "/"):
    """Set language preference via cookie and redirect."""
    from fastapi.responses import RedirectResponse
    if lang not in ("ru", "en"):
        lang = "ru"
    response = RedirectResponse(url=next, status_code=303)
    response.set_cookie("lang", lang, max_age=365 * 24 * 3600)
    return response


# ─── Core routers (always loaded) ─────────────────────────────
app.include_router(auth.router)
app.include_router(entities.router)
app.include_router(search.router)
app.include_router(admin.router)
app.include_router(editor_api.router)
app.include_router(profile.router)
app.include_router(comments.router)
app.include_router(export.router)
app.include_router(feeds.router)

# ─── Plugin routers (loaded dynamically) ──────────────────────
load_plugins(app)

logger.info("DWMB Meta-System started. Core + %d plugins loaded.", len([r for r in app.routes]))
