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
from app.middleware.rate_limit import limiter, get_rate_limit

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
# ThemeMiddleware MUST run before KindsMiddleware to set request.state.lang
app.add_middleware(KindsMiddleware)
app.add_middleware(ThemeMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Static files ─────────────────────────────────────────────
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# ─── Rate limiting ────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(429, get_rate_limit)


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


# ─── Core routers (always loaded) ─────────────────────────────
from app.routes import auth, entities, search, admin, editor_api, profile, comments, export, feeds
app.include_router(auth.router)
app.include_router(entities.router)
app.include_router(search.router)
app.include_router(admin.router)
app.include_router(editor_api.router)
app.include_router(profile.router)
app.include_router(comments.router)
app.include_router(export.router)
app.include_router(feeds.router)


# ─── Media proxy ──────────────────────────────────────────────
@app.get("/media/proxy")
async def media_proxy(url: str = Query(...)):
    """Proxy media files to avoid CORS issues."""
    import httpx
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.get(url, follow_redirects=True)
            content_type = resp.headers.get("content-type", "application/octet-stream")
            return StreamingResponse(
                iter([resp.content]),
                media_type=content_type,
                headers={"Content-Disposition": f"inline; filename={url.split('/')[-1]}"},
            )
    except Exception as e:
        logger.error(f"Media proxy error: {e}")
        return JSONResponse({"error": str(e)}, status_code=502)


# ─── Health check ─────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "version": "0.8.0"}
