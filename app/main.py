"""
DWMB — Dynamic World Meta-Base
Main FastAPI application with plugin system.
"""
import os
import logging
from fastapi import FastAPI, Request, Query
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse, HTMLResponse, JSONResponse, StreamingResponse
from starlette.middleware.cors import CORSMiddleware
from jose import JWTError, jwt

from app.config import get_settings
from app.database import async_session
from app.middleware.theme import ThemeMiddleware
from app.middleware.kinds import KindsMiddleware
from app.middleware.rate_limit import limiter, rate_limit_exceeded_handler
from app.middleware.csrf import CSRFMiddleware, csrf_token_context
from app.middleware.rls import RLSMiddleware

settings = get_settings()

# ─── Logging ──────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("dwmb")

# ─── App ──────────────────────────────────────────────────────
app = FastAPI(
    title="DWMB — Dynamic World Meta-Base",
    description="Семантическая база знаний с онтологической моделью данных",
    version="0.8.0",
)

# ─── Middleware (order matters: last added = first executed) ───
# CSRFMiddleware must be outermost for form validation
app.add_middleware(CSRFMiddleware)
# RLSMiddleware sets PostgreSQL session variable for RLS
app.add_middleware(RLSMiddleware)
# ThemeMiddleware MUST run before KindsMiddleware to set request.state.lang
app.add_middleware(KindsMiddleware)
app.add_middleware(ThemeMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# ─── Static files ─────────────────────────────────────────────
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# ─── Rate limiting ────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(429, rate_limit_exceeded_handler)


# ─── Language switch ──────────────────────────────────────────
@app.get("/set-lang")
async def set_language(request: Request, lang: str = "ru", next: str = "/"):
    """Set language preference via cookie AND user profile."""
    from sqlalchemy import select
    from app.models.languages import Language
    from app.models.users import UserAccount
    from app.services.language import clear_language_cache
    
    valid_langs = ("ru", "en", "de", "fr", "es", "zh", "ja")
    if lang not in valid_langs:
        lang = "ru"
    
    response = RedirectResponse(url=next, status_code=303)
    response.set_cookie("lang", lang, max_age=365 * 24 * 3600)
    
    # Save to user profile if logged in
    token = request.cookies.get("access_token")
    if token:
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            username = payload.get("sub")
            if username:
                async with async_session() as session:
                    # Get user
                    result = await session.execute(
                        select(UserAccount).where(UserAccount.username == username)
                    )
                    user = result.scalar_one_or_none()
                    if user:
                        # Get language_id
                        lang_result = await session.execute(
                            select(Language.language_id).where(Language.code == lang)
                        )
                        lang_id = lang_result.scalar_one_or_none()
                        if lang_id:
                            user.language_id = lang_id
                            await session.commit()
                            clear_language_cache()
        except JWTError:
            pass
    
    return response


# ─── Media proxy (before routers to avoid /media/{asset_id} conflict) ──
@app.get("/media/proxy")
async def media_proxy(url: str = Query(...)):
    """Proxy media files to avoid CORS issues. SSRF-protected."""
    import httpx
    import re
    from urllib.parse import urlparse
    
    # SSRF protection: validate URL
    try:
        parsed = urlparse(url)
        if parsed.scheme not in ("http", "https"):
            return JSONResponse({"error": "Invalid URL scheme"}, status_code=400)
        
        # Block internal/private IPs
        hostname = parsed.hostname or ""
        blocked = ["localhost", "127.0.0.1", "0.0.0.0", "::1", "169.254.", "10.", "172.16.", "172.17.", "172.18.", "172.19.", "172.20.", "172.21.", "172.22.", "172.23.", "172.24.", "172.25.", "172.26.", "172.27.", "172.28.", "172.29.", "172.30.", "172.31.", "192.168."]
        for b in blocked:
            if hostname.startswith(b) or hostname == b.rstrip("."):
                return JSONResponse({"error": "Internal URLs not allowed"}, status_code=400)
    except Exception:
        return JSONResponse({"error": "Invalid URL"}, status_code=400)
    
    try:
        # Check if it's a MinIO URL (contains /entities/)
        match = re.search(r'/entities/([^/]+)/([^?]+)', url)
        if match:
            # MinIO file — use boto3 directly
            from app.services.storage import storage_service
            storage_key = f"entities/{match.group(1)}/{match.group(2)}"
            data = storage_service.get_file(storage_key)
            if not data:
                return JSONResponse({"error": "File not found"}, status_code=404)
            ext = match.group(2).split('.')[-1].lower()
            mime_map = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "gif": "image/gif", "webp": "image/webp", "svg": "image/svg+xml", "mp4": "video/mp4", "mp3": "audio/mpeg"}
            content_type = mime_map.get(ext, "application/octet-stream")
            return StreamingResponse(
                iter([data]),
                media_type=content_type,
                headers={"Content-Disposition": f"inline; filename={match.group(2)}"},
            )
        else:
            # External URL — proxy with httpx (timeout + size limit)
            async with httpx.AsyncClient(timeout=10.0, follow_redirects=False) as client:
                resp = await client.get(url)
                # Limit response size to 10MB
                if len(resp.content) > 10 * 1024 * 1024:
                    return JSONResponse({"error": "File too large"}, status_code=413)
                content_type = resp.headers.get("content-type", "application/octet-stream")
                return StreamingResponse(
                    iter([resp.content]),
                    media_type=content_type,
                    headers={"Content-Disposition": f"inline; filename={url.split('/')[-1].split('?')[0]}"},
                )
    except Exception as e:
        logger.error(f"Media proxy error: {e}")
        return JSONResponse({"error": "Proxy error"}, status_code=502)


# ─── Core routers (always loaded) ─────────────────────────────
from app.routes import auth, entities, search, editor_api, profile, comments, export, feeds
from plugins import load_plugins
from app.graphql.schema import graphql_router
app.include_router(auth.router)
app.include_router(entities.router)
app.include_router(search.router)
from app.routes.admin import router as admin_router
from app.routes.api_language import router as api_language_router
app.include_router(admin_router)
app.include_router(api_language_router)
app.include_router(editor_api.router)
app.include_router(profile.router)
app.include_router(comments.router)
app.include_router(export.router)
app.include_router(feeds.router)



# ─── Plugins (loaded after core routers) ──────────────────────
load_plugins(app)

# ─── Template context processor ───────────────────────────────
from fastapi.templating import Jinja2Templates
templates = Jinja2Templates(directory="app/templates")
templates.env.globals["csrf_token_context"] = csrf_token_context

# ─── GraphQL ──────────────────────────────────────────────────
app.include_router(graphql_router, prefix="/graphql")

# ─── Health check ─────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "version": "0.8.0"}


# ─── Startup/Shutdown events ──────────────────────────────────
from plugins import startup_plugins, shutdown_plugins

@app.on_event("startup")
async def on_startup():
    # Initialize Redis cache
    from app.services.cache import init_cache
    await init_cache(settings.REDIS_URL)
    logger.info("Redis cache initialized")
    
    await startup_plugins()

@app.on_event("shutdown")
async def on_shutdown():
    await shutdown_plugins()
